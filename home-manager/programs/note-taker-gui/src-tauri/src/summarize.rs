//! Runs `claude -p` over the raw transcript to produce a title, a Slack-ready
//! summary, and a list of action items.

use std::process::Stdio;

use serde::{Deserialize, Serialize};
use tokio::io::AsyncWriteExt;
use tokio::process::Command;

#[derive(Serialize, Deserialize, Clone)]
pub struct Summary {
    pub title: String,
    pub slack_summary: String,
    pub action_items: Vec<String>,
}

const PROMPT: &str = r#"You are given the raw transcript of a meeting or voice note on stdin.
Produce a concise summary intended to be pasted directly into Slack.

Reply with ONLY a single JSON object (no markdown fences, no prose before or after) with exactly these keys:
- "title": a short, descriptive title for the note (max ~8 words, no trailing punctuation).
- "slack_summary": the summary formatted in Slack mrkdwn. Use *single asterisks* for bold (NOT **double**), use "•" for bullet points, and "\n" for line breaks. Keep it tight: a one-line context sentence followed by a few bullets of key points and decisions. Do NOT include the action items here.
- "action_items": an array of strings, one per concrete action item / TODO mentioned or implied. Each string is a single imperative task with no leading bullet or checkbox. Use an empty array if there are none.

Return strictly valid JSON."#;

/// Pull the first balanced-looking JSON object out of claude's stdout, tolerating
/// ```json fences or stray prose.
fn extract_json(raw: &str) -> Option<String> {
    let start = raw.find('{')?;
    let end = raw.rfind('}')?;
    if end > start {
        Some(raw[start..=end].to_string())
    } else {
        None
    }
}

#[tauri::command]
pub async fn summarize(out_path: String) -> Result<Summary, String> {
    let notes = tokio::fs::read_to_string(&out_path)
        .await
        .map_err(|e| format!("cannot read transcript {out_path}: {e}"))?;
    if notes.trim().is_empty() {
        return Err("the transcript is empty — nothing to summarize yet".into());
    }

    // `claude` is resolved on the inherited session PATH (auth comes from the
    // session env / ~/.claude, same as an interactive shell).
    let mut child = Command::new("claude")
        .arg("-p")
        .arg(PROMPT)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("failed to launch claude: {e}"))?;

    {
        let mut stdin = child.stdin.take().ok_or("claude has no stdin")?;
        stdin
            .write_all(notes.as_bytes())
            .await
            .map_err(|e| format!("failed to send notes to claude: {e}"))?;
        // stdin dropped here -> EOF, claude starts working.
    }

    let output = child
        .wait_with_output()
        .await
        .map_err(|e| format!("claude did not complete: {e}"))?;

    if !output.status.success() {
        return Err(format!(
            "claude exited with an error: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }

    let raw = String::from_utf8_lossy(&output.stdout);
    let json =
        extract_json(&raw).ok_or_else(|| format!("could not find JSON in claude output:\n{raw}"))?;
    serde_json::from_str::<Summary>(&json)
        .map_err(|e| format!("claude returned JSON we could not parse ({e}):\n{json}"))
}
