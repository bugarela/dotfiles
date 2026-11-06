"""Test startup eligibility without launching a real Zellij session."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

TEMPLATE = Path(__file__).with_name("zellij-auto-start.fish").read_text()


class ZellijAutostartTests(unittest.TestCase):
    def startup(self, overrides=None, attach="false", auto_exit="false"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fake = root / "zellij"
            fake.write_text(
                "#!/bin/sh\n"
                "printf '%s\\n' 'if not set -q ZELLIJ' "
                "'echo START:$ZELLIJ_AUTO_ATTACH:$ZELLIJ_AUTO_EXIT' 'end'\n"
            )
            fake.chmod(0o700)
            script = root / "startup.fish"
            script.write_text(TEMPLATE.replace("@zellij@", str(fake))
                              .replace("@autoAttach@", attach).replace("@autoExit@", auto_exit))
            environment = {key: value for key, value in os.environ.items()
                           if key not in {"HC_TERMINAL_ID", "TERM_PROGRAM", "ZELLIJ",
                                          "ZELLIJ_AUTO_ATTACH", "ZELLIJ_AUTO_EXIT"}}
            environment.update(HOME=directory, TERM="xterm-256color")
            environment.update(overrides or {})
            result = subprocess.run(["fish", "--no-config", "--command", f"source {script}"],
                                    env=environment, capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout.strip()

    def test_regular_terminal_still_starts_zellij(self):
        self.assertEqual(self.startup({"TERM_PROGRAM": "ghostty"}), "START:false:false")

    def test_unidentified_regular_terminal_still_starts(self):
        self.assertEqual(self.startup(), "START:false:false")

    def test_herdr_program_does_not_start_zellij(self):
        self.assertEqual(self.startup({"TERM_PROGRAM": "herdr"}), "")

    def test_core_terminal_does_not_start_even_with_inherited_program(self):
        self.assertEqual(self.startup({"HC_TERMINAL_ID": "example-terminal", "TERM_PROGRAM": "ghostty"}), "")

    def test_empty_core_marker_does_not_disable_other_terminals(self):
        self.assertEqual(self.startup({"HC_TERMINAL_ID": ""}), "START:false:false")

    def test_dumb_terminal_does_not_start(self):
        self.assertEqual(self.startup({"TERM": "dumb"}), "")

    def test_existing_zellij_is_not_nested(self):
        self.assertEqual(self.startup({"ZELLIJ": "0"}), "")

    def test_attach_and_exit_preferences_are_preserved(self):
        self.assertEqual(self.startup(attach="true", auto_exit="true"), "START:true:true")


if __name__ == "__main__":
    unittest.main()
