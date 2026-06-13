//! Writes into the org world: per-item TODOs and the full summary section both
//! land in today's org-roam daily note (~/MEGA/org/roam/daily/YYYY-MM-DD.org),
//! and the summary is also saved as a Markdown file next to the raw transcript.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

const ALLOWED_TAGS: [&str; 4] = ["today", "next", "soon", "someday"];

fn daily_path() -> PathBuf {
    let date = chrono::Local::now().format("%Y-%m-%d").to_string();
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("/tmp"))
        .join("MEGA/org/roam/daily")
        .join(format!("{date}.org"))
}

/// Create the daily note with a proper org-roam header if it does not exist yet.
fn ensure_daily(path: &Path) -> std::io::Result<()> {
    if path.exists() {
        return Ok(());
    }
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let id = uuid::Uuid::new_v4();
    let title = chrono::Local::now().format("%Y-%m-%d").to_string();
    let header = format!(":PROPERTIES:\n:ID:       {id}\n:END:\n#+title: {title}\n");
    fs::write(path, header)
}

fn append(path: &Path, content: &str) -> std::io::Result<()> {
    let mut f = fs::OpenOptions::new().append(true).open(path)?;
    f.write_all(content.as_bytes())
}

#[tauri::command]
pub fn append_todo(item: String, tag: String) -> Result<(), String> {
    if !ALLOWED_TAGS.contains(&tag.as_str()) {
        return Err(format!("unknown tag: {tag}"));
    }
    let path = daily_path();
    ensure_daily(&path).map_err(|e| format!("cannot create daily note: {e}"))?;
    let line = format!("* TODO {} :{}:\n", item.trim(), tag);
    append(&path, &line).map_err(|e| format!("cannot write to daily note: {e}"))
}

/// Write the structured sidecar JSON (so the UI can reload the note with full
/// fidelity) and the human-readable Markdown sibling. Returns the .md path.
fn write_summary_artifacts(
    txt_path: &Path,
    summary: &crate::summarize::Summary,
) -> Result<PathBuf, String> {
    let sidecar = crate::notes::summary_sidecar(txt_path);
    if let Some(parent) = sidecar.parent() {
        fs::create_dir_all(parent).map_err(|e| e.to_string())?;
    }
    fs::write(
        &sidecar,
        serde_json::to_string_pretty(summary).map_err(|e| e.to_string())?,
    )
    .map_err(|e| format!("cannot write summary sidecar: {e}"))?;

    let md_path = crate::notes::markdown_sibling(txt_path);
    let mut md = format!("# {}\n\n{}\n", summary.title, summary.slack_summary.trim_end());
    if !summary.action_items.is_empty() {
        md.push_str("\n## Action items\n");
        for it in &summary.action_items {
            md.push_str(&format!("- [ ] {}\n", it.trim()));
        }
    }
    fs::write(&md_path, &md).map_err(|e| format!("cannot write summary file: {e}"))?;
    Ok(md_path)
}

/// First summarization: write the sidecar + Markdown AND append a section to
/// today's org daily note.
#[tauri::command]
pub fn save_summary(
    out_path: String,
    title: String,
    slack_summary: String,
    action_items: Vec<String>,
) -> Result<String, String> {
    let txt_path = PathBuf::from(&out_path);
    let summary = crate::summarize::Summary {
        title,
        slack_summary,
        action_items,
    };
    let md_path = write_summary_artifacts(&txt_path, &summary)?;

    // Append a section to today's org daily note.
    let daily = daily_path();
    ensure_daily(&daily).map_err(|e| format!("cannot create daily note: {e}"))?;
    let mut section = format!("\n* {}\n", summary.title.trim());
    for line in summary.slack_summary.lines() {
        section.push_str(line);
        section.push('\n');
    }
    if !summary.action_items.is_empty() {
        section.push_str("\n** Action items\n");
        for it in &summary.action_items {
            section.push_str(&format!("- {}\n", it.trim()));
        }
    }
    append(&daily, &section).map_err(|e| format!("cannot append to daily note: {e}"))?;

    Ok(md_path.to_string_lossy().to_string())
}

/// Inline edit: rewrite the sidecar + Markdown only. Does NOT touch the org
/// daily note (that section was already appended on the first summarize).
#[tauri::command]
pub fn save_note_edits(
    out_path: String,
    title: String,
    slack_summary: String,
    action_items: Vec<String>,
) -> Result<String, String> {
    let txt_path = PathBuf::from(&out_path);
    let summary = crate::summarize::Summary {
        title,
        slack_summary,
        action_items,
    };
    let md_path = write_summary_artifacts(&txt_path, &summary)?;
    Ok(md_path.to_string_lossy().to_string())
}

/// Parse our Markdown layout (`# Title`, body, `## Action items` with `- [ ]`
/// bullets) back into a structured Summary.
fn parse_md(md: &str) -> crate::summarize::Summary {
    let mut title = String::new();
    let mut summary_lines: Vec<&str> = Vec::new();
    let mut action_items: Vec<String> = Vec::new();
    let mut in_actions = false;

    for line in md.lines() {
        let trimmed = line.trim_end();
        if title.is_empty() && trimmed.starts_with("# ") {
            title = trimmed[2..].trim().to_string();
            continue;
        }
        if trimmed.trim_start().to_lowercase().starts_with("## action item") {
            in_actions = true;
            continue;
        }
        if in_actions {
            let item = trimmed
                .trim_start()
                .trim_start_matches("- [ ] ")
                .trim_start_matches("- [x] ")
                .trim_start_matches("- [X] ")
                .trim_start_matches("- ")
                .trim_start_matches("* ")
                .trim();
            if !item.is_empty() {
                action_items.push(item.to_string());
            }
        } else {
            summary_lines.push(line);
        }
    }

    crate::summarize::Summary {
        title,
        slack_summary: summary_lines.join("\n").trim().to_string(),
        action_items,
    }
}

/// Re-read the note's `.md` (e.g. after editing it in Emacs), rewrite the
/// sidecar JSON so the in-app view matches, and return the parsed summary.
#[tauri::command]
pub fn reload_from_md(out_path: String) -> Result<crate::summarize::Summary, String> {
    let txt_path = PathBuf::from(&out_path);
    let md_path = crate::notes::markdown_sibling(&txt_path);
    let md = fs::read_to_string(&md_path)
        .map_err(|e| format!("no markdown to reload ({}): {e}", md_path.display()))?;
    let summary = parse_md(&md);
    let sidecar = crate::notes::summary_sidecar(&txt_path);
    fs::write(
        &sidecar,
        serde_json::to_string_pretty(&summary).map_err(|e| e.to_string())?,
    )
    .map_err(|e| format!("cannot write sidecar: {e}"))?;
    Ok(summary)
}

/// Open the note's Markdown summary in the running Emacs via emacsclient.
#[tauri::command]
pub fn open_in_emacs(out_path: String) -> Result<(), String> {
    let txt_path = PathBuf::from(&out_path);
    let md_path = crate::notes::markdown_sibling(&txt_path);
    if !md_path.exists() {
        return Err("No summary file yet — summarize or save first.".into());
    }
    // -n: return immediately (don't block on the frame); -a emacs: start Emacs
    // if no server is running. emacsclient is resolved on the session PATH.
    std::process::Command::new("emacsclient")
        .args(["-n", "-a", "emacs"])
        .arg(&md_path)
        .spawn()
        .map_err(|e| format!("failed to launch emacsclient: {e}"))?;
    Ok(())
}
