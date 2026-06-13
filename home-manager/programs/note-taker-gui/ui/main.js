const { invoke } = window.__TAURI__.core;
const { listen } = window.__TAURI__.event;
const { getCurrentWindow } = window.__TAURI__.window;

const RECORDING_VIEW = "__recording__";

const els = {
  recordBtn: document.getElementById("record-btn"),
  recordLabel: document.getElementById("record-label"),
  notesList: document.getElementById("notes-list"),
  mainHeader: document.getElementById("main-header"),
  noteTitle: document.getElementById("note-title"),
  noteMeta: document.getElementById("note-meta"),
  summarizeBtn: document.getElementById("summarize-btn"),
  mainBody: document.getElementById("main-body"),
  cameraPill: document.getElementById("camera-pill"),
  hideBtn: document.getElementById("hide-btn"),
  toast: document.getElementById("toast"),
};

const state = {
  notes: [],
  activeNotePath: null, // real path, RECORDING_VIEW, or null
  recording: false,
  saving: false,
  recordingPath: null,
  editing: false,
  currentMeta: null,
  currentContent: null,
};

// ---------- helpers ----------
function toast(msg) {
  els.toast.textContent = msg;
  els.toast.classList.add("show");
  clearTimeout(toast._t);
  toast._t = setTimeout(() => els.toast.classList.remove("show"), 2400);
}

function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[c]));
}

// Slack mrkdwn -> HTML: *bold*, _italic_, ~strike~, `code`, <url|label>, line breaks.
function renderMrkdwn(text) {
  let h = escapeHtml(text || "");
  h = h.replace(/&lt;(https?:\/\/[^|&]+)\|([^&]+)&gt;/g, '<a href="$1">$2</a>');
  h = h.replace(/&lt;(https?:\/\/[^&]+)&gt;/g, '<a href="$1">$1</a>');
  h = h.replace(/`([^`]+)`/g, "<code>$1</code>");
  h = h.replace(/\*([^*\n]+)\*/g, "<strong>$1</strong>");
  h = h.replace(/_([^_\n]+)_/g, "<em>$1</em>");
  h = h.replace(/~([^~\n]+)~/g, "<del>$1</del>");
  h = h.replace(/\n/g, "<br>");
  return h;
}

function hasSummaryContent(s) {
  return !!s && ((s.slack_summary && s.slack_summary.trim()) || (s.action_items && s.action_items.length));
}

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text != null) node.textContent = text;
  return node;
}

function parseTranscriptInto(container, raw) {
  const lines = (raw || "").split("\n");
  let any = false;
  for (const line of lines) {
    const t = line.trim();
    if (!t) continue;
    any = true;
    const p = el("p", "line");
    const m = t.match(/^\[(\d{2}:\d{2}:\d{2})\]\s*(.*)$/);
    if (m) {
      p.appendChild(el("span", "ts", m[1]));
      p.appendChild(document.createTextNode(m[2]));
    } else {
      p.appendChild(document.createTextNode(t));
    }
    container.appendChild(p);
  }
  if (!any) container.appendChild(el("p", "empty-hint", "No transcript yet."));
}

// ---------- record button ----------
function setRecordButton(mode) {
  els.recordBtn.classList.toggle("recording", mode === "recording");
  els.recordBtn.classList.toggle("saving", mode === "saving");
  els.recordLabel.textContent =
    mode === "recording" ? "Stop recording" :
    mode === "saving" ? "Saving…" :
    "Start recording";
}

// ---------- notes list ----------
async function refreshNotes() {
  try {
    state.notes = await invoke("list_notes");
  } catch (err) {
    toast(String(err));
    state.notes = [];
  }
  renderNotesList();
}

function renderNotesList() {
  els.notesList.innerHTML = "";

  if (state.recording) {
    const item = el("button", "note-item recording-item");
    if (state.activeNotePath === RECORDING_VIEW) item.classList.add("active");
    item.appendChild(el("span", "ni-title", "Recording…"));
    const meta = el("div", "ni-meta");
    meta.appendChild(el("span", "ni-dot"));
    meta.appendChild(el("span", null, "in progress"));
    item.appendChild(meta);
    item.addEventListener("click", showRecordingView);
    els.notesList.appendChild(item);
  }

  if (state.notes.length === 0 && !state.recording) {
    els.notesList.appendChild(el("div", "notes-empty", "No notes yet."));
    return;
  }

  for (const note of state.notes) {
    const item = el("button", "note-item");
    if (note.path === state.activeNotePath) item.classList.add("active");
    item.appendChild(el("span", "ni-title", note.title));
    const meta = el("div", "ni-meta");
    if (note.has_summary) meta.appendChild(el("span", "ni-dot"));
    meta.appendChild(el("span", null, `${note.date_label} · ${note.time_label}`));
    item.appendChild(meta);
    item.addEventListener("click", () => selectNote(note.path));
    els.notesList.appendChild(item);
  }
}

// ---------- views ----------
function showEmpty() {
  state.activeNotePath = null;
  state.editing = false;
  els.mainHeader.classList.add("hidden");
  els.mainBody.innerHTML = "";
  const wrap = el("div", "empty-state");
  const card = el("div", "empty-card");
  card.appendChild(el("h2", null, "Nothing open yet"));
  const p = el("p");
  p.innerHTML = "Pick a note from the left, or press <strong>Start recording</strong> to capture a new one.";
  card.appendChild(p);
  wrap.appendChild(card);
  els.mainBody.appendChild(wrap);
}

function showRecordingView() {
  state.activeNotePath = RECORDING_VIEW;
  state.editing = false;
  renderNotesList();
  els.mainHeader.classList.remove("hidden");
  els.noteTitle.textContent = "Recording…";
  els.noteMeta.textContent = "live";
  els.summarizeBtn.classList.remove("hidden");
  els.summarizeBtn.disabled = true;
  els.mainBody.innerHTML = "";
  els.mainBody.appendChild(el("div", "transcript-head", "Live transcript"));
  const t = el("div", "transcript");
  t.id = "live-transcript";
  t.appendChild(el("p", "empty-hint", "Listening…"));
  els.mainBody.appendChild(t);
}

function appendLiveLine(ts, text, isSys) {
  const container = document.getElementById("live-transcript");
  if (!container) return;
  const hint = container.querySelector(".empty-hint");
  if (hint) hint.remove();
  const p = el("p", "line" + (isSys ? " sys" : ""));
  if (ts) p.appendChild(el("span", "ts", ts));
  p.appendChild(document.createTextNode(text));
  container.appendChild(p);
  els.mainBody.scrollTop = els.mainBody.scrollHeight;
}

async function selectNote(path) {
  state.activeNotePath = path;
  state.editing = false;
  renderNotesList();
  let content;
  try {
    content = await invoke("load_note", { path });
  } catch (err) {
    toast(String(err));
    return;
  }
  const meta = state.notes.find((n) => n.path === path);
  renderNoteView(meta, content);
}

function renderNoteView(meta, content) {
  state.currentMeta = meta;
  state.currentContent = content;
  els.mainHeader.classList.remove("hidden");

  const title =
    (content.summary && content.summary.title && content.summary.title.trim()) ||
    (meta && meta.title) ||
    "Note";
  els.noteTitle.textContent = state.editing ? "Editing note" : title;
  els.noteMeta.textContent = meta ? `${meta.date_label} · ${meta.time_label}` : "";

  els.summarizeBtn.classList.toggle("hidden", state.editing);
  els.summarizeBtn.disabled = false;
  els.summarizeBtn.textContent = hasSummaryContent(content.summary) ? "Re-summarize" : "Summarize";

  els.mainBody.innerHTML = "";
  if (state.editing) {
    els.mainBody.appendChild(buildEditForm(content, meta));
  } else if (hasSummaryContent(content.summary)) {
    els.mainBody.appendChild(buildSummaryBlock(content.summary));
  }
  els.mainBody.appendChild(el("div", "transcript-head", "Transcript"));
  const t = el("div", "transcript");
  parseTranscriptInto(t, content.raw);
  els.mainBody.appendChild(t);
}

function buildSummaryBlock(summary) {
  const block = el("div", "summary-block");

  const head = el("div", "sb-head");
  head.appendChild(el("h3", null, "Summary"));
  const btns = el("div", "sb-btns");

  const editBtn = el("button", "copy-btn", "Edit");
  editBtn.addEventListener("click", () => {
    state.editing = true;
    renderNoteView(state.currentMeta, state.currentContent);
  });
  btns.appendChild(editBtn);

  const copyBtn = el("button", "copy-btn", "Copy for Slack");
  copyBtn.addEventListener("click", () =>
    copyForSlack(summary.slack_summary || "", renderMrkdwn(summary.slack_summary || ""))
  );
  btns.appendChild(copyBtn);

  const emacsBtn = el("button", "copy-btn", "Send to emacs");
  emacsBtn.addEventListener("click", async () => {
    try {
      await invoke("open_in_emacs", { outPath: state.activeNotePath });
      toast("Opened in Emacs");
    } catch (err) {
      toast(String(err));
    }
  });
  btns.appendChild(emacsBtn);

  const reloadBtn = el("button", "copy-btn", "Reload from md");
  reloadBtn.addEventListener("click", async () => {
    try {
      await invoke("reload_from_md", { outPath: state.activeNotePath });
      await refreshNotes();
      await selectNote(state.activeNotePath);
      toast("Reloaded from markdown");
    } catch (err) {
      toast(String(err));
    }
  });
  btns.appendChild(reloadBtn);

  head.appendChild(btns);
  block.appendChild(head);

  const body = el("div", "slack-summary");
  body.innerHTML = renderMrkdwn(summary.slack_summary || "");
  block.appendChild(body);

  block.appendChild(el("div", "ai-heading", "Action items"));
  const list = el("ul", "action-items");
  const items = summary.action_items || [];
  if (items.length === 0) {
    list.appendChild(el("li", "notes-empty", "No action items."));
  }
  for (const item of items) list.appendChild(buildActionItem(item));
  block.appendChild(list);

  return block;
}

function buildEditForm(content, meta) {
  const s = content.summary || { title: "", slack_summary: "", action_items: [] };
  const form = el("div", "edit-form");

  form.appendChild(el("label", "edit-label", "Title"));
  const titleInput = el("input", "edit-input");
  titleInput.value = (s.title && s.title.trim()) || (meta && meta.title) || "";
  form.appendChild(titleInput);

  form.appendChild(el("label", "edit-label", "Summary (Slack mrkdwn)"));
  const summaryArea = el("textarea", "edit-textarea");
  summaryArea.value = s.slack_summary || "";
  form.appendChild(summaryArea);

  form.appendChild(el("label", "edit-label", "Action items"));
  const itemsWrap = el("div", "edit-items");
  const addItemRow = (value) => {
    const row = el("div", "edit-item-row");
    const inp = el("input", "edit-input");
    inp.value = value || "";
    const rm = el("button", "ghost-btn small", "Remove");
    rm.addEventListener("click", () => row.remove());
    row.appendChild(inp);
    row.appendChild(rm);
    itemsWrap.appendChild(row);
  };
  (s.action_items || []).forEach(addItemRow);
  form.appendChild(itemsWrap);
  const addBtn = el("button", "ghost-btn small", "+ Add item");
  addBtn.addEventListener("click", () => addItemRow(""));
  form.appendChild(addBtn);

  const actions = el("div", "edit-actions");
  const saveBtn = el("button", "summarize-btn", "Save");
  const cancelBtn = el("button", "ghost-btn", "Cancel");
  actions.appendChild(saveBtn);
  actions.appendChild(cancelBtn);
  form.appendChild(actions);

  cancelBtn.addEventListener("click", () => {
    state.editing = false;
    renderNoteView(state.currentMeta, state.currentContent);
  });
  saveBtn.addEventListener("click", async () => {
    const title = titleInput.value.trim() || "Untitled note";
    const slackSummary = summaryArea.value;
    const actionItems = Array.from(itemsWrap.querySelectorAll("input"))
      .map((i) => i.value.trim())
      .filter(Boolean);
    saveBtn.disabled = true;
    saveBtn.textContent = "Saving…";
    try {
      await invoke("save_note_edits", {
        outPath: state.activeNotePath,
        title,
        slackSummary,
        actionItems,
      });
      state.editing = false;
      await refreshNotes();
      await selectNote(state.activeNotePath);
      toast("Saved");
    } catch (err) {
      saveBtn.disabled = false;
      saveBtn.textContent = "Save";
      toast(String(err));
    }
  });

  return form;
}

function buildActionItem(text) {
  const li = el("li", "action-item");
  const label = el("div", "ai-text");
  label.appendChild(document.createTextNode(text));
  li.appendChild(label);

  const row = el("div", "tag-row");
  for (const tag of ["today", "next", "soon", "someday"]) {
    const btn = el("button", "tag-btn", `:${tag}:`);
    btn.dataset.tag = tag;
    btn.addEventListener("click", async () => {
      try {
        await invoke("append_todo", { item: text, tag });
        li.classList.add("filed");
        label.innerHTML = "";
        label.appendChild(el("span", "ai-check"));
        label.appendChild(document.createTextNode(text));
        row.querySelectorAll(".tag-btn").forEach((b) => (b.disabled = true));
        toast(`Filed as :${tag}:`);
      } catch (err) {
        toast(String(err));
      }
    });
    row.appendChild(btn);
  }
  li.appendChild(row);
  return li;
}

async function copyForSlack(plain, html) {
  // Copy rich HTML so Slack renders *bold*/_italic_ as actual formatting — its
  // composer no longer auto-converts mrkdwn on paste. Plain text is the fallback.
  try {
    if (navigator.clipboard && window.ClipboardItem) {
      await navigator.clipboard.write([
        new ClipboardItem({
          "text/html": new Blob([html], { type: "text/html" }),
          "text/plain": new Blob([plain], { type: "text/plain" }),
        }),
      ]);
      toast("Copied for Slack");
      return;
    }
  } catch {
    /* fall through to the execCommand path below */
  }
  // Fallback: select a hidden rich element and copy (carries text/html too).
  const div = document.createElement("div");
  div.contentEditable = "true";
  div.innerHTML = html;
  div.style.position = "fixed";
  div.style.left = "-9999px";
  document.body.appendChild(div);
  const range = document.createRange();
  range.selectNodeContents(div);
  const sel = window.getSelection();
  sel.removeAllRanges();
  sel.addRange(range);
  let ok = false;
  try {
    ok = document.execCommand("copy");
  } catch {
    /* ignore */
  }
  sel.removeAllRanges();
  div.remove();
  toast(ok ? "Copied for Slack" : "Copy failed");
}

// ---------- backend events ----------
listen("transcript-line", (e) => {
  if (state.recording && state.activeNotePath === RECORDING_VIEW) {
    appendLiveLine(`${e.payload.ts}`, e.payload.text, false);
  }
});
listen("recorder-status", (e) => {
  if (state.recording && state.activeNotePath === RECORDING_VIEW) {
    appendLiveLine("", e.payload.message, true);
  }
});
listen("recording-state", (e) => {
  if (e.payload.out_path) state.recordingPath = e.payload.out_path;
  state.recording = e.payload.recording;
});
listen("camera-state", (e) => {
  els.cameraPill.classList.toggle("pill-hidden", !e.payload.in_use);
});

// ---------- record toggle ----------
els.recordBtn.addEventListener("click", async () => {
  if (state.saving) return;
  try {
    if (state.recording) {
      state.saving = true;
      setRecordButton("saving");
      const out = await invoke("stop_recording");
      state.saving = false;
      state.recording = false;
      state.recordingPath = null;
      setRecordButton("idle");
      await refreshNotes();
      if (out) {
        await selectNote(out);
      } else {
        renderNotesList();
      }
      toast("Saved");
    } else {
      await invoke("start_recording");
      state.recording = true;
      setRecordButton("recording");
      showRecordingView();
    }
  } catch (err) {
    state.saving = false;
    state.recording = false;
    setRecordButton("idle");
    toast(String(err));
  }
});

// ---------- summarize ----------
els.summarizeBtn.addEventListener("click", async () => {
  const path = state.activeNotePath;
  if (!path || path === RECORDING_VIEW) return;
  els.summarizeBtn.disabled = true;
  const prevText = els.summarizeBtn.textContent;
  els.summarizeBtn.textContent = "Summarizing…";
  try {
    const summary = await invoke("summarize", { outPath: path });
    try {
      await invoke("save_summary", {
        outPath: path,
        title: summary.title,
        slackSummary: summary.slack_summary,
        actionItems: summary.action_items,
      });
    } catch (err) {
      toast(String(err));
    }
    await refreshNotes();
    await selectNote(path);
    toast("Summarized and added to daily note");
  } catch (err) {
    els.summarizeBtn.textContent = prevText;
    els.summarizeBtn.disabled = false;
    toast(String(err));
  }
});

// ---------- hide to scratchpad ----------
els.hideBtn.addEventListener("click", () => getCurrentWindow().hide());

// ---------- init ----------
showEmpty();
refreshNotes();
