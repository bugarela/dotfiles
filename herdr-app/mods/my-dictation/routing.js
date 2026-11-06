// Dictation is typing, not an agent message: shells and editors are valid too.
export function selectedTerminal(context, paneList) {
  if (!context) return null;
  const pane = paneList.find(item => item.pane === context.pane);
  const address = context.shown ?? context.terminal ?? pane?.terminal;
  return address ? { address, label: pane?.title || "Original terminal" } : null;
}

// Never turn a dictated newline/control character into a terminal keystroke.
export function plainTranscript(text) {
  return text.replace(/[\u0000-\u001f\u007f-\u009f]/g, " ").replace(/\s+/g, " ").trim();
}
