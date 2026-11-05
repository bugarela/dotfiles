import { View, div } from "gpui-kit";
import { h_flex, v_flex, TextareaState, Textarea } from "gpui-base";
import { exec, hc, home, focused, agents, theme, shared, setShared, nextCommand } from "herdr";

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
    this.input = TextareaState.new({ placeholder: "Review and edit your transcription", rows: 4 });
    this.input.on("change", (_event, cx) => {
      if (this.session) setShared("dictation.draft", { session: this.session.id, text: this.input.value() });
      cx.notify();
    });
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
          const saved = shared("dictation.draft");
          this.input.set_value(saved?.session === id ? saved.text : state.text);
          setShared("dictation.draft", { session: id, text: this.input.value() });
          if (this.input.value().trim()) this.input.focus();
          else this.error = "No speech detected. Discard to record again.";
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
    if (this.state === "ready" || this.state === "error") {
      this.error = "Send or discard the existing draft before recording again.";
      cx.notify();
      return;
    }
    if (this.session && this.state !== "recording") return;
    const focus = focused();
    // Only an actual focused agent can be the destination. Never fall back to
    // a different agent, or risk executing spoken text in an ordinary shell.
    const target = agents().find(agent => agent.address === focus?.terminal);
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
          this.session = {
            id: result.session,
            target: target?.address ?? null,
            label: target ? `${target.space_name} / ${target.tab_name} · ${target.program.name}` : "No agent selected",
          };
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

  async clear() {
    if (this.session) {
      try { await control("discard", this.session.id); } catch (_) { /* Already expired. */ }
    }
    this.session = null;
    this.state = "idle";
    this.error = "";
    this.input.set_value("");
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
        // Runtime sessions vanish on reboot. Don't trap the user in a stale
        // session forever; a still-live worker loses its lease within 20s.
        await this.clear();
        this.error = `Cancellation not confirmed; any live capture expires after 20s without this controller. ${error}`;
        this.state = "error";
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  send(cx) {
    if (this.busy || this.state !== "ready" || !this.input.value().trim()) return;
    const target = agents().find(agent => agent.address === this.session?.target);
    if (!target) {
      this.error = "The original agent is no longer available. Your draft is kept here.";
      cx.notify();
      return;
    }
    this.busy = true;
    const text = this.input.value();
    cx.spawn(async cx => {
      try {
        // Conditional send refuses working/blocked agents, never forces a dialog,
        // and intentionally submits only after this explicit button press.
        const result = await hc(["send", "--if", "idle", "--json", "--", target.address, text]);
        if (result.code !== 0) throw new Error(result.stderr.trim() || result.stdout.trim());
        const receipt = JSON.parse(result.stdout);
        if (!Number.isInteger(receipt.turn)) throw new Error("Agent did not confirm submission");
        await this.clear();
      } catch (error) {
        this.error = `Send not confirmed; draft kept. Check the agent before retrying: ${error}`;
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  async close() {
    if (this.session && ACTIVE.includes(this.state)) {
      await control("cancel", this.session.id);
    }
    this.input.release();
    // If the app crashes, loss of the status heartbeat cancels capture in 20s.
  }

  render() {
    const t = theme();
    const button = (id, text, action) => div().id(id).px(10).py(6).rounded(4)
      .bg(t.raised).text_color(t.foreground).hover(s => s.bg(t.hover))
      .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
      .on_click((_event, cx) => action(cx)).child(text);
    if (this.state === "idle") {
      // Keep the controller alive for F8; the compact trigger lives in my-tabs.
      return div().w(0).h(0);
    }
    const label = {
      loading: "Loading Whisper… wait before speaking",
      recording: "● Recording · F8 to stop",
      transcribing: "Transcribing…",
      cancelling: "Cancelling…",
      ready: "Review voice draft · sending presses Enter",
      error: "Dictation needs attention",
    }[this.state] ?? this.state;
    return v_flex().w(520).p(10).gap(8).text_size(13).text_color(t.foreground)
      .child(h_flex().items_center().justify_between().gap(8)
        .child(div().text_color(this.state === "recording" ? t.blocked : t.foreground).child(label))
        .child(button("voice-cancel", this.state === "ready" || this.state === "error" ? "Discard" : "Cancel · ⇧F8", cx => this.cancel(cx))))
      .child(div().text_size(12).text_color(t.muted).child(this.session?.label ?? "Microphone only · local transcription"))
      .when(this.state === "ready", el => el
        .child(div().id("voice-input").h(140).p(8).bg(t.input).rounded(4)
          .on_mouse_down("left", (_event, cx) => cx.stop_propagation())
          .child(Textarea.new(this.input).size_full().text_color(t.foreground)))
        .when(Boolean(this.session?.target), el => el.child(button("voice-send", this.busy ? "Working…" : "Send to original agent", cx => this.send(cx)))))
      .when(Boolean(this.error), el => el.child(div().text_size(12).text_color(t.blocked).child(this.error)));
  }
}
