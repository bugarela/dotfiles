//! Listing and loading saved notes for the sidebar.
//!
//! A "note" is a raw transcript `~/notes/meetings/<stem>.txt`. Its structured
//! summary (if it has been summarized) lives in a sidecar `<stem>.summary.json`
//! so the UI can reload the title, Slack summary, and action items with full
//! fidelity. See `todo::save_summary`.

use std::fs;
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::summarize::Summary;

#[derive(Serialize)]
pub struct NoteMeta {
    pub path: String,
    pub title: String,
    pub date_label: String,
    pub time_label: String,
    pub has_summary: bool,
}

#[derive(Serialize)]
pub struct NoteContent {
    pub raw: String,
    pub summary: Option<Summary>,
}

pub fn meetings_dir() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/tmp"))
        .join("notes/meetings")
}

/// `<stem>.summary.json` next to a `<stem>.txt`.
pub fn summary_sidecar(txt_path: &Path) -> PathBuf {
    txt_path.with_extension("summary.json")
}

/// `<stem>.md` next to a `<stem>.txt`.
pub fn markdown_sibling(txt_path: &Path) -> PathBuf {
    txt_path.with_extension("md")
}

fn read_summary(txt_path: &Path) -> Option<Summary> {
    let sidecar = summary_sidecar(txt_path);
    let data = fs::read_to_string(&sidecar).ok()?;
    serde_json::from_str::<Summary>(&data).ok()
}

/// Friendly labels + a fallback title from the transcript stem `YYYY-MM-DD_HHMMSS`.
fn labels_from_stem(stem: &str) -> (String, String) {
    let (date_part, time_part) = stem.split_once('_').unwrap_or((stem, ""));

    let date_label = chrono::NaiveDate::parse_from_str(date_part, "%Y-%m-%d")
        .map(|d| d.format("%b %d, %Y").to_string())
        .unwrap_or_else(|_| date_part.to_string());

    let time_label = chrono::NaiveTime::parse_from_str(time_part, "%H%M%S")
        .map(|t| t.format("%H:%M").to_string())
        .unwrap_or_else(|_| time_part.to_string());

    (date_label, time_label)
}

/// First handful of words of the transcript, stripped of the `[HH:MM:SS]` prefix.
fn preview_title(raw: &str) -> Option<String> {
    for line in raw.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let text = match (line.starts_with('['), line.find(']')) {
            (true, Some(end)) => line[end + 1..].trim(),
            _ => line,
        };
        if text.is_empty() {
            continue;
        }
        let words: Vec<&str> = text.split_whitespace().take(7).collect();
        if words.is_empty() {
            continue;
        }
        let mut t = words.join(" ");
        if text.split_whitespace().count() > 7 {
            t.push('…');
        }
        return Some(t);
    }
    None
}

#[tauri::command]
pub fn list_notes() -> Result<Vec<NoteMeta>, String> {
    let dir = meetings_dir();
    let mut stems: Vec<(String, PathBuf)> = Vec::new();

    if let Ok(entries) = fs::read_dir(&dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) == Some("txt") {
                if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                    stems.push((stem.to_string(), path));
                }
            }
        }
    }

    // Newest first — stems sort chronologically (YYYY-MM-DD_HHMMSS).
    stems.sort_by(|a, b| b.0.cmp(&a.0));

    let notes = stems
        .into_iter()
        .map(|(stem, path)| {
            let (date_label, time_label) = labels_from_stem(&stem);
            let summary = read_summary(&path);
            let has_summary = summary.is_some();
            let title = summary
                .map(|s| s.title)
                .or_else(|| fs::read_to_string(&path).ok().and_then(|r| preview_title(&r)))
                .unwrap_or_else(|| "Untitled note".to_string());
            NoteMeta {
                path: path.to_string_lossy().to_string(),
                title,
                date_label,
                time_label,
                has_summary,
            }
        })
        .collect();

    Ok(notes)
}

#[tauri::command]
pub fn load_note(path: String) -> Result<NoteContent, String> {
    let p = PathBuf::from(&path);
    let raw = fs::read_to_string(&p).map_err(|e| format!("cannot read note: {e}"))?;
    let summary = read_summary(&p);
    Ok(NoteContent { raw, summary })
}
