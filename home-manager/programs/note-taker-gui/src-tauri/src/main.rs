// note-taker-gui — a cute front-end for the note-taker transcription CLI.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod camera;
mod notes;
mod recorder;
mod state;
mod summarize;
mod todo;

use std::sync::Arc;

use recorder::Recorder;
use tauri::Manager;

#[tauri::command]
async fn start_recording(
    app: tauri::AppHandle,
    state: tauri::State<'_, Arc<Recorder>>,
) -> Result<(), String> {
    recorder::start(app, state.inner().clone()).await
}

#[tauri::command]
async fn stop_recording(
    state: tauri::State<'_, Arc<Recorder>>,
) -> Result<Option<String>, String> {
    recorder::stop(state.inner().clone()).await
}

fn main() {
    tauri::Builder::default()
        .manage(Arc::new(Recorder::default()))
        .invoke_handler(tauri::generate_handler![
            start_recording,
            stop_recording,
            summarize::summarize,
            todo::append_todo,
            todo::save_summary,
            todo::save_note_edits,
            todo::open_in_emacs,
            todo::reload_from_md,
            notes::list_notes,
            notes::load_note,
        ])
        .setup(|app| {
            state::write_state(false, None);
            camera::spawn_camera_watcher(app.handle().clone());
            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("error while building note-taker-gui")
        .run(|app_handle, event| {
            if let tauri::RunEvent::ExitRequested { .. } = event {
                let rec = app_handle.state::<Arc<Recorder>>();
                recorder::force_stop(&rec);
            }
        });
}
