//! The polybar contract: a tiny JSON file that reflects whether we are recording.
//! polybar's `custom/script` module reads `.recording` from here every couple of seconds.

use serde::Serialize;
use std::fs;
use std::path::PathBuf;

#[derive(Serialize)]
struct PolybarState {
    recording: bool,
    out_path: Option<String>,
}

pub fn state_path() -> PathBuf {
    let dir = dirs::cache_dir()
        .unwrap_or_else(|| PathBuf::from("/tmp"))
        .join("note-taker-gui");
    let _ = fs::create_dir_all(&dir);
    dir.join("state.json")
}

pub fn write_state(recording: bool, out_path: Option<String>) {
    let st = PolybarState { recording, out_path };
    if let Ok(s) = serde_json::to_string(&st) {
        let _ = fs::write(state_path(), s);
    }
}
