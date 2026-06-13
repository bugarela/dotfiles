//! Drives the existing `note-taker` CLI as a subprocess.
//!
//! The CLI prints status lines and then `[HH:MM:SS] text` transcript lines to
//! stdout (flushed). We stream those to the UI as events, learn the output file
//! path from its `Saving transcript to:` line, and stop it with SIGINT so it
//! flushes ffmpeg and writes the final transcript (see note-taker/default.nix).

use std::process::Stdio;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use serde::Serialize;
use tauri::{AppHandle, Emitter};
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::{Child, Command};

#[derive(Default)]
pub struct Recorder {
    pub child: Mutex<Option<Child>>,
    pub out_path: Mutex<Option<String>>,
}

#[derive(Clone, Serialize)]
struct TranscriptLine {
    ts: String,
    text: String,
}

#[derive(Clone, Serialize)]
struct RecorderStatus {
    message: String,
}

#[derive(Clone, Serialize)]
pub struct RecordingState {
    pub recording: bool,
    pub out_path: Option<String>,
}

fn emit_recording_state(app: &AppHandle, recording: bool, out_path: Option<String>) {
    let _ = app.emit("recording-state", RecordingState { recording, out_path });
}

pub async fn start(app: AppHandle, rec: Arc<Recorder>) -> Result<(), String> {
    if rec.child.lock().unwrap().is_some() {
        return Err("already recording".into());
    }

    // `note-taker` is resolved on the inherited session PATH (never hardcoded).
    let mut child = Command::new("note-taker")
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| format!("failed to start note-taker: {e}"))?;

    let stdout = child.stdout.take().ok_or("note-taker produced no stdout")?;

    *rec.child.lock().unwrap() = Some(child);
    *rec.out_path.lock().unwrap() = None;
    crate::state::write_state(true, None);
    emit_recording_state(&app, true, None);

    let app2 = app.clone();
    let rec2 = rec.clone();
    tokio::spawn(async move {
        let mut lines = BufReader::new(stdout).lines();
        while let Ok(Some(line)) = lines.next_line().await {
            if let Some(path) = line.strip_prefix("Saving transcript to: ") {
                let path = path.trim().to_string();
                *rec2.out_path.lock().unwrap() = Some(path.clone());
                crate::state::write_state(true, Some(path.clone()));
                emit_recording_state(&app2, true, Some(path));
                continue;
            }
            // Transcript lines look like `[HH:MM:SS] some words`.
            if line.starts_with('[') {
                if let Some(end) = line.find(']') {
                    let ts = line[1..end].to_string();
                    let text = line[end + 1..].trim().to_string();
                    if !text.is_empty() {
                        let _ = app2.emit("transcript-line", TranscriptLine { ts, text });
                        continue;
                    }
                }
            }
            // Everything else (model loading, capturing, saved-to) is status.
            let _ = app2.emit("recorder-status", RecorderStatus { message: line });
        }
    });

    Ok(())
}

pub async fn stop(rec: Arc<Recorder>) -> Result<Option<String>, String> {
    let child = rec.child.lock().unwrap().take();
    let out = rec.out_path.lock().unwrap().clone();
    crate::state::write_state(false, out.clone());

    if let Some(mut child) = child {
        if let Some(pid) = child.id() {
            let _ = nix::sys::signal::kill(
                nix::unistd::Pid::from_raw(pid as i32),
                nix::sys::signal::Signal::SIGINT,
            );
        }
        // Give it up to 6s to flush ffmpeg + write the transcript, then force it.
        if tokio::time::timeout(Duration::from_secs(6), child.wait())
            .await
            .is_err()
        {
            let _ = child.kill().await;
        }
    }
    Ok(out)
}

/// Synchronous best-effort stop for app shutdown — SIGINT and let it flush on
/// its own (tokio Child does not kill-on-drop, so the process survives to finish).
pub fn force_stop(rec: &Recorder) {
    if let Some(child) = rec.child.lock().unwrap().take() {
        if let Some(pid) = child.id() {
            let _ = nix::sys::signal::kill(
                nix::unistd::Pid::from_raw(pid as i32),
                nix::sys::signal::Signal::SIGINT,
            );
        }
    }
    crate::state::write_state(false, None);
}

pub fn is_recording(rec: &Recorder) -> bool {
    rec.child.lock().unwrap().is_some()
}
