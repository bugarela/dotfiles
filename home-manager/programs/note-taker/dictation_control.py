"""Short-lived CLI control bridge for Herdr's non-interactive exec API.

A private runtime directory holds each session's state and control message.
Only the detached worker owns the backend process; callers never signal PIDs.
"""
import argparse
import json
import os
from pathlib import Path
import re
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import uuid

ACTIVE = {"loading", "recording", "transcribing", "cancelling"}


def runtime_root():
    root = Path(os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir())) / f"note-taker-dictation-{os.getuid()}"
    root.mkdir(mode=0o700, exist_ok=True)
    if root.is_symlink() or root.stat().st_uid != os.getuid():
        raise RuntimeError("Unsafe dictation runtime directory")
    root.chmod(0o700)
    return root


def session_dir(session):
    if not re.fullmatch(r"[a-f0-9]{32}", session or ""):
        raise ValueError("Invalid dictation session")
    path = runtime_root() / session
    if not path.is_dir() or path.is_symlink():
        raise ValueError("Dictation session no longer exists")
    return path


def write_json(path, data):
    temporary = path.with_name(path.name + "." + uuid.uuid4().hex + ".tmp")
    temporary.write_text(json.dumps(data), encoding="utf-8")
    temporary.replace(path)


def read_state(path):
    state = json.loads((path / "state.json").read_text(encoding="utf-8"))
    if state["state"] in ACTIVE and time.time() - (path / "state.json").stat().st_mtime > 30:
        return {"state": "error", "error": "Dictation worker stopped responding"}
    return state


def start(backend):
    root = runtime_root()
    # Clean abandoned, day-old sessions (including drafts); active workers update
    # state every two seconds and have a separate maximum lifetime.
    for old in root.iterdir():
        if old.is_dir() and not old.is_symlink() and time.time() - old.stat().st_mtime > 86400:
            shutil.rmtree(old)
    session = uuid.uuid4().hex
    path = root / session
    path.mkdir(mode=0o700)
    write_json(path / "state.json", {"state": "loading"})
    (path / "lease").touch()
    with (path / "worker.log").open("w") as log:
        subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve())]
            + (["--backend", backend] if backend else [])
            + ["worker", "--session", session],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=log,
            start_new_session=True, close_fds=True,
        )
    return {"session": session, "state": "loading"}


def worker(path, backend):
    state = {"state": "loading"}
    cancelled = False
    cancel_started = None
    interrupted = False
    stopped = False
    pending = b""
    transcript = None
    process = None
    started = time.monotonic()
    heartbeat = started

    def cancel(_signal, _frame):
        nonlocal interrupted
        interrupted = True

    signal.signal(signal.SIGTERM, cancel)
    signal.signal(signal.SIGINT, cancel)
    with (path / "backend.log").open("w+") as errors:
        try:
            process = subprocess.Popen(
                [sys.executable, backend] if backend else ["note-taker", "--dictate"],
                stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=errors,
            )
            while True:
                control = path / "control.json"
                action = json.loads(control.read_text())["action"] if control.exists() else None
                expired = time.time() - (path / "lease").stat().st_mtime > 20
                if (interrupted or action == "cancel" or expired) and not cancelled:
                    cancelled = True
                    cancel_started = time.monotonic()
                    state = {"state": "cancelling"}
                    if process.poll() is None:
                        process.terminate()
                elif action == "stop" and not stopped and not cancelled:
                    if state["state"] != "recording":
                        raise RuntimeError("Cannot stop before recording starts")
                    process.stdin.write(b"stop\n")
                    process.stdin.flush()
                    stopped = True
                    state = {"state": "transcribing"}
                if cancelled and time.monotonic() - cancel_started > 8:
                    break
                if time.monotonic() - started > 1800:
                    raise RuntimeError("Dictation exceeded its maximum lifetime")
                if select.select([process.stdout], [], [], 0.1)[0]:
                    chunk = os.read(process.stdout.fileno(), 65536)
                    pending += chunk
                    while b"\n" in pending:
                        line, pending = pending.split(b"\n", 1)
                        event = json.loads(line)
                        if not cancelled:
                            if event["event"] == "text":
                                transcript = event["text"]
                            else:
                                state = {"state": event["event"]}
                            write_json(path / "state.json", state)
                    if not chunk:
                        break
                if time.monotonic() - heartbeat > 2:
                    write_json(path / "state.json", state)
                    heartbeat = time.monotonic()
            code = None if cancelled else process.wait(timeout=10)
            if cancelled:
                state = {"state": "cancelled"}
            elif code != 0:
                errors.seek(0)
                raise RuntimeError(errors.read()[-3000:] or f"Backend exited {code}")
            elif transcript is None:
                raise RuntimeError("Backend returned no transcription")
            else:
                state = {"state": "ready", "text": transcript}
        except Exception as error:
            state = {"state": "error", "error": str(error)}
        finally:
            if process is not None:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=8)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                process.stdin.close()
                process.stdout.close()
            write_json(path / "state.json", state)


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--backend", help="Optional Python backend script; default: note-taker --dictate")
    parser.add_argument("action", choices=["start", "status", "stop", "cancel", "discard", "worker"])
    parser.add_argument("--session")
    args = parser.parse_args()
    try:
        if args.action == "start":
            result = start(args.backend)
        else:
            path = session_dir(args.session)
            if args.action == "worker":
                worker(path, args.backend)
                return 0
            state = read_state(path)
            if args.action == "status" and state["state"] in ACTIVE:
                (path / "lease").touch()
            if args.action in {"stop", "cancel"}:
                if state["state"] in ACTIVE:
                    if args.action == "stop" and state["state"] != "recording":
                        raise RuntimeError("Wait until recording starts before stopping")
                    write_json(path / "control.json", {"action": args.action})
            elif args.action == "discard":
                if state["state"] in ACTIVE:
                    raise RuntimeError("Cancel capture before discarding its session")
                shutil.rmtree(path)
            result = state
        print(json.dumps(result), flush=True)
        return 0
    except Exception as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
