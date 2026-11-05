"""Bridge integration tests with a fake backend (never opens a microphone)."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

CONTROL = Path(__file__).with_name("dictation_control.py")


class ControlTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.environment = {**os.environ, "XDG_RUNTIME_DIR": str(self.root)}
        self.backend = self.root / "fake_backend.py"
        self.backend.write_text(
            "import json, sys\n"
            "print(json.dumps({'event':'recording'}), flush=True)\n"
            "if sys.stdin.readline().strip() == 'stop':\n"
            "    print(json.dumps({'event':'transcribing'}), flush=True)\n"
            "    print(json.dumps({'event':'text','text':'Please explain this.'}), flush=True)\n"
        )
        self.session = None

    def call(self, action, session=None):
        command = [sys.executable, str(CONTROL), "--backend", str(self.backend), action]
        if session:
            command += ["--session", session]
        result = subprocess.run(command, env=self.environment, text=True,
                                capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def wait(self, wanted, touch=True):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if touch:
                state = self.call("status", self.session)
            else:
                state = json.loads((self.path / "state.json").read_text())
            if state["state"] == wanted:
                return state
            time.sleep(0.05)
        self.fail(f"Expected {wanted}, got {state}")

    def start(self):
        self.session = self.call("start")["session"]
        self.path = self.root / f"note-taker-dictation-{os.getuid()}" / self.session
        self.wait("recording")

    def tearDown(self):
        if self.session and self.path.exists():
            self.call("cancel", self.session)
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                state = self.call("status", self.session)
                if state["state"] not in {"loading", "recording", "transcribing", "cancelling"}:
                    break
                time.sleep(0.05)
            self.call("discard", self.session)
        self.temporary.cleanup()

    def test_start_stop_review_and_discard(self):
        self.start()
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o700)
        self.assertEqual((self.path / "state.json").stat().st_mode & 0o777, 0o600)
        self.call("stop", self.session)
        state = self.wait("ready")
        self.assertEqual(state["text"], "Please explain this.")
        self.call("discard", self.session)
        self.assertFalse(self.path.exists())
        self.session = None

    def test_cancel_never_returns_transcript(self):
        self.start()
        self.call("cancel", self.session)
        self.assertNotIn("text", self.wait("cancelled"))

    def test_lost_ui_lease_cancels_capture(self):
        self.start()
        expired = time.time() - 60
        os.utime(self.path / "lease", (expired, expired))
        self.assertNotIn("text", self.wait("cancelled", touch=False))

    def test_path_traversal_session_is_rejected(self):
        result = subprocess.run(
            [sys.executable, str(CONTROL), "status", "--session", "../../outside"],
            env=self.environment, capture_output=True, text=True, timeout=5,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Invalid dictation session", result.stderr)

    def test_backend_failure_is_reported(self):
        self.backend.write_text("import sys\nprint('fake microphone failure', file=sys.stderr)\nsys.exit(1)\n")
        self.session = self.call("start")["session"]
        self.path = self.root / f"note-taker-dictation-{os.getuid()}" / self.session
        state = self.wait("error")
        self.assertIn("fake microphone failure", state["error"])


if __name__ == "__main__":
    unittest.main()
