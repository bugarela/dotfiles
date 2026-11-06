import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { exec, home, focused, panes, theme, shared, setShared, nextCommand, run } from "herdr";
import { selectedTerminal, plainTranscript } from "./routing.js";

const ACTIVE = ["loading", "recording", "transcribing", "cancelling"];
const bridge = () => `${home()}/dotfiles/home-manager/programs/note-taker/dictation_control.py`;

async function control(action, session) {
  const result = await exec("python3", [bridge(), action, ...(session ? ["--session", session] : [])]);
  if (result.code !== 0) throw new Error(result.stderr.trim() || "Dictation control failed");
  return JSON.parse(result.stdout);
}

export default class Dictation extends View {
  init(_props, cx) {
    this.session = shared("dictation.session") ?? null;
    this.state = this.session ? "loading" : "idle";
    this.error = "";
    this.busy = false;
    this.polling = false;
    cx.timer.every(1000, cx => this.poll(cx));
    if (this.session) this.poll(cx);
    cx.spawn(async cx => {
      for (;;) {
        const command = await nextCommand();
        if (command === "toggle") this.toggle(cx);
        if (command === "cancel") this.cancel(cx);
        cx.notify();
      }
    });
  }

  poll(cx) {
    if (!this.session || this.polling || this.state === "ready" || this.state === "error") return;
    const id = this.session.id;
    this.polling = true;
    cx.spawn(async cx => {
      try {
        const state = await control("status", id);
        if (this.session?.id !== id) return;
        this.state = state.state;
        if (state.state === "ready") {
          // Preserve edits to a draft left by the old UI, but never auto-paste
          // an old draft or replay a delivery interrupted by a mod reload.
          const saved = shared("dictation.draft");
          const text = saved?.session === id ? saved.text : state.text;
          setShared("dictation.draft", { session: id, text });
          if (!plainTranscript(text)) await this.clear();
          else if (this.session.autoPaste === true) this.paste(cx);
        } else if (state.state === "error") this.error = state.error;
        else if (state.state === "cancelled") await this.clear();
      } catch (error) {
        this.state = "error";
        this.error = String(error);
      } finally {
        this.polling = false;
        cx.notify();
      }
    });
  }

  toggle(cx) {
    if (this.busy) return;
    if (this.state === "ready") {
      this.paste(cx);
      return;
    }
    if (this.state === "error") return;
    if (this.session && this.state !== "recording") return;
    const destination = selectedTerminal(focused(), panes());
    if (!this.session && !destination) {
      this.error = "Select the terminal input you want to dictate into, then press F8.";
      this.state = "error";
      cx.notify();
      return;
    }
    this.busy = true;
    cx.spawn(async cx => {
      try {
        if (this.session) {
          await control("stop", this.session.id);
          this.state = "transcribing";
        } else {
          this.state = "loading";
          cx.notify();
          const result = await control("start");
          this.session = { id: result.session, target: destination.address,
            label: destination.label, autoPaste: true };
          setShared("dictation.session", this.session);
          setShared("dictation.draft", null);
          this.error = "";
        }
      } catch (error) {
        this.error = String(error);
        this.state = "error";
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  paste(cx) {
    if (this.busy || this.state !== "ready") return;
    const destination = selectedTerminal(focused(), panes());
    if (!this.session?.target || destination?.address !== this.session.target) {
      this.error = this.session?.target
        ? "Return to the original terminal, then press F8 to paste. Nothing has been typed."
        : "This old draft has no destination. Copy it below, then discard and start F8 in a terminal.";
      cx.notify();
      return;
    }
    const saved = shared("dictation.draft");
    const text = saved?.session === this.session.id ? plainTranscript(saved.text) : "";
    if (!text) return;
    // Consume automatic delivery BEFORE queuing native paste. A reload must
    // never type the same text twice. No hc send, agent statuses, or Enter.
    this.session = { ...this.session, autoPaste: false };
    setShared("dictation.session", this.session);
    this.busy = true;
    try {
      cx.write_to_clipboard(text);
      run("terminal.paste");
      this.state = "pasting";
      cx.spawn(async cx => {
        await this.clear();
        this.busy = false;
        cx.notify();
      });
    } catch (error) {
      this.busy = false;
      this.error = `Paste not confirmed; transcript kept below. Check the terminal before retrying: ${error}`;
    }
    cx.notify();
  }

  async clear() {
    if (this.session) {
      try { await control("discard", this.session.id); } catch (_) { /* Already expired. */ }
    }
    this.session = null;
    this.state = "idle";
    this.error = "";
    setShared("dictation.session", null);
    setShared("dictation.draft", null);
  }

  cancel(cx) {
    if (this.busy) return;
    this.busy = true;
    cx.spawn(async cx => {
      try {
        if (this.session) {
          const state = await control("cancel", this.session.id);
          if (ACTIVE.includes(state.state)) this.state = "cancelling";
          else await this.clear();
        } else await this.clear();
      } catch (error) {
        await this.clear();
        this.error = `Cancellation not confirmed; any live capture expires after 20s without this controller. ${error}`;
        this.state = "error";
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  async close() {
    if (this.session && ACTIVE.includes(this.state)) await control("cancel", this.session.id);
  }

  render() {
    const t = theme();
    if (this.state === "idle") return div().w(0).h(0);
    const button = (id, text, action) => div().id(id).px(8).py(4).rounded(4)
      .bg(t.raised).text_color(t.foreground).hover(s => s.bg(t.hover))
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .on_click((_event, cx) => action(cx)).child(text);
    const label = {
      loading: "Loading Whisper… wait before speaking",
      recording: "● Recording · F8 to stop",
      transcribing: "Transcribing… text will be pasted, not submitted",
      cancelling: "Cancelling…",
      pasting: "Pasting into terminal…",
      ready: "Transcript kept · F8 to paste into the original input",
      error: "Dictation needs attention",
    }[this.state] ?? this.state;
    const saved = shared("dictation.draft");
    return v_flex().max_w(520).p(8).gap(6).text_size(12).text_color(t.foreground)
      .child(h_flex().items_center().gap(8)
        .child(div().text_color(this.state === "recording" ? t.blocked : t.foreground).child(label))
        .child(button("voice-cancel", ACTIVE.includes(this.state) ? "Cancel · ⇧F8" : "Discard", cx => this.cancel(cx))))
      .when(Boolean(this.error), el => el.child(div().text_color(t.blocked).child(this.error)))
      .when(this.state === "ready" && saved?.session === this.session?.id, el => el
        .child(div().text_color(t.muted).child(saved.text))
        .child(button("voice-copy", "Copy transcript", cx => cx.write_to_clipboard(plainTranscript(saved.text)))));
  }
}
