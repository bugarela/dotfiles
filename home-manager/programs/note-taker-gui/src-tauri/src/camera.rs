//! Background watcher: polls whether any /dev/video* device is in use (the same
//! `fuser /dev/video*` idiom the lock script uses). On the off->on edge, if we
//! are not already recording, fire a notification with a one-click "Start" action.

use std::sync::Arc;
use std::time::Duration;

use serde::Serialize;
use tauri::{AppHandle, Emitter, Manager};

use crate::recorder::Recorder;

#[derive(Clone, Serialize)]
struct CameraState {
    in_use: bool,
}

fn video_devices() -> Vec<std::path::PathBuf> {
    let mut devices = Vec::new();
    if let Ok(entries) = std::fs::read_dir("/dev") {
        for entry in entries.flatten() {
            if entry.file_name().to_string_lossy().starts_with("video") {
                devices.push(entry.path());
            }
        }
    }
    devices
}

fn camera_in_use() -> bool {
    let devices = video_devices();
    if devices.is_empty() {
        return false;
    }
    std::process::Command::new("fuser")
        .args(devices.iter().map(|p| p.as_os_str()))
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

fn notify_and_maybe_start(app: AppHandle) {
    tauri::async_runtime::spawn(async move {
        // notify-send with an action waits and prints the action key on stdout
        // when the user clicks it (dunst supports this).
        let output = tokio::process::Command::new("notify-send")
            .args([
                "-u",
                "critical",
                "-i",
                "camera-web",
                "-A",
                "start=Start transcribing",
                "Camera is on",
                "You're on camera but not recording. Start the note-taker?",
            ])
            .output()
            .await;

        if let Ok(output) = output {
            if String::from_utf8_lossy(&output.stdout).trim() == "start" {
                let rec = app.state::<Arc<Recorder>>().inner().clone();
                if !crate::recorder::is_recording(&rec) {
                    let _ = crate::recorder::start(app.clone(), rec).await;
                }
            }
        }
    });
}

pub fn spawn_camera_watcher(app: AppHandle) {
    tauri::async_runtime::spawn(async move {
        let mut prev = false;
        loop {
            let in_use = camera_in_use();
            if in_use != prev {
                let _ = app.emit("camera-state", CameraState { in_use });
                // off -> on, and not already recording -> nudge.
                if in_use {
                    let rec = app.state::<Arc<Recorder>>().inner().clone();
                    if !crate::recorder::is_recording(&rec) {
                        notify_and_maybe_start(app.clone());
                    }
                }
            }
            prev = in_use;
            tokio::time::sleep(Duration::from_secs(5)).await;
        }
    });
}
