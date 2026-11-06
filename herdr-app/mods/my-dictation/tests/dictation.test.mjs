import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { selectedTerminal, plainTranscript } from "../routing.js";

const originalPane = { pane: "pane-a", terminal: "term-a", title: "Example terminal" };

test("destination is the original terminal, including a shell or editor", () => {
  assert.deepEqual(selectedTerminal({ terminal: "term-a", pane: "pane-a" }, [originalPane]),
    { address: "term-a", label: "Example terminal" });
  assert.equal(selectedTerminal({ pane: "pane-a", terminal: null }, [originalPane]).address, "term-a");
});

test("shown replacement wins; no terminal never guesses an agent", () => {
  assert.equal(selectedTerminal({ terminal: "term-a", shown: "term-b", pane: "pane-a" }, [originalPane]).address, "term-b");
  assert.equal(selectedTerminal({ terminal: null, pane: null, agent: "other-agent" }, []), null);
});

test("transcript cannot inject newline, Enter, or other control characters", () => {
  assert.equal(plainTranscript("  hello\r\nworld\t\u001b\u0000!  "), "hello world !");
  assert.equal(plainTranscript("Olá, café!"), "Olá, café!");
});

// Host mocks: no real microphone, clipboard, terminal input, or agent calls.
let selection;
let commands;
let clipboard;
let tasks;
const store = new Map();
const element = new Proxy({}, { get() { return () => element; } });
globalThis.__voiceTestHost = {
  View: class {}, div: () => element, h_flex: () => element, v_flex: () => element,
  exec: async (_program, args) => ({ code: 0, stdout: JSON.stringify(
    args.includes("status") ? { state: "ready", text: "Testing, testing." } : { state: "ready" }), stderr: "" }),
  home: () => "/example", focused: () => selection, panes: () => [originalPane],
  theme: () => ({}), shared: key => store.get(key), setShared: (key, value) => store.set(key, value),
  nextCommand: () => new Promise(() => {}), run: command => commands.push(command),
};
const original = readFileSync(new URL("../main.js", import.meta.url), "utf8");
const source = original
  .replace(/^import .* from "(?:gpui-kit|gpui-base|herdr)";$/gm,
    line => line.replace(/^import (.*) from .*;$/, "const $1 = globalThis.__voiceTestHost;"))
  .replace('"./routing.js"', JSON.stringify(new URL("../routing.js", import.meta.url).href));
const { default: Dictation } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);
delete globalThis.__voiceTestHost;

const context = {
  timer: { every() {} }, spawn: task => tasks.push(task), notify() {},
  write_to_clipboard: text => clipboard.push(text),
};

function setup(autoPaste = true) {
  store.clear(); commands = []; clipboard = []; tasks = [];
  selection = { terminal: "term-a", pane: "pane-a" };
  const view = new Dictation();
  view.init({}, context);
  tasks = []; // Never run the infinite command listener in tests.
  view.session = { id: "example-session", target: "term-a", label: "Example", autoPaste };
  view.state = "ready";
  store.set("dictation.session", view.session);
  store.set("dictation.draft", { session: view.session.id, text: "Testing, testing." });
  return view;
}

test("paste uses native terminal input, never hc send or Enter", () => {
  const view = setup();
  view.paste(context);
  assert.deepEqual(clipboard, ["Testing, testing."]);
  assert.deepEqual(commands, ["terminal.paste"]);
  assert.equal(store.get("dictation.session").autoPaste, false);
  assert.equal(view.state, "pasting");
  view.paste(context);
  assert.equal(commands.length, 1);
  assert.doesNotMatch(original, /\bhc\b\s*\(|--if|TextareaState|bind_keys/);
});

test("switching tabs keeps the transcript, without typing or stealing focus", () => {
  const view = setup();
  selection = { terminal: "term-b" };
  view.paste(context);
  assert.deepEqual(commands, []);
  assert.deepEqual(clipboard, []);
  assert.match(view.error, /Return to the original terminal/);
  assert.equal(store.get("dictation.draft").text, "Testing, testing.");
  selection = { terminal: "term-a" };
  view.paste(context);
  assert.deepEqual(commands, ["terminal.paste"]);
});

test("a completed new recording is pasted automatically, without a draft editor", async () => {
  const view = setup();
  view.state = "transcribing";
  view.poll(context);
  await tasks.shift()(context);
  assert.deepEqual(commands, ["terminal.paste"]);
  await tasks.shift()(context); // Discard private backend data after paste.
  assert.equal(view.state, "idle");
  assert.equal(store.get("dictation.draft"), null);
});

test("old drafts and interrupted deliveries are not automatically replayed", async () => {
  for (const autoPaste of [false, undefined]) {
    const view = setup(autoPaste);
    if (autoPaste === undefined) delete view.session.autoPaste;
    view.state = "loading";
    view.poll(context);
    await tasks.shift()(context);
    assert.deepEqual(commands, []);
    assert.equal(view.state, "ready");
    assert.equal(store.get("dictation.draft").text, "Testing, testing.");
  }
});
