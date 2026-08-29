from __future__ import annotations

import base64
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODIFIER = ROOT / "home/private_dot_docker/modify_private_config.json"
INSTALLER = ROOT / "home/.chezmoiscripts/macos/run_onchange_after_1-install-command-line-tools.sh"


def encoded_auth(username: str, secret: str) -> str:
    return base64.b64encode(f"{username}:{secret}".encode()).decode()


class DockerConfigModifierTests(unittest.TestCase):
    def run_modifier(self, value: str, *, env: dict[str, str] | None = None):
        return subprocess.run(
            ["/bin/bash", str(MODIFIER)],
            input=value,
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )

    def test_preserves_unknown_fields_and_credentials(self):
        source = {
            "auths": {"registry.example": {"auth": encoded_auth("alice", "fixture-secret")}},
            "plugins": {"debug": {"enabled": True}},
            "futureField": [1, 2, 3],
            "currentContext": "desktop-linux",
        }
        result = self.run_modifier(json.dumps(source))

        self.assertEqual(result.returncode, 0, result.stderr)
        output = json.loads(result.stdout)
        self.assertEqual(output["auths"], source["auths"])
        self.assertEqual(output["plugins"], source["plugins"])
        self.assertEqual(output["futureField"], source["futureField"])
        self.assertEqual(output["currentContext"], "colima")
        self.assertEqual(output["credsStore"], "osxkeychain")

    def test_semantically_desired_input_is_byte_for_byte_unchanged(self):
        source = '{\n  "unknown": true,\n  "currentContext": "colima",\n  "credsStore": "osxkeychain"\n}\n'
        result = self.run_modifier(source)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, source)

    def test_empty_input_becomes_minimal_valid_config(self):
        result = self.run_modifier("")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(result.stdout),
            {"currentContext": "colima", "credsStore": "osxkeychain"},
        )

    def test_malformed_json_fails_without_outputting_input(self):
        marker = "fixture-secret-must-not-print"
        result = self.run_modifier(f'{{"broken":"{marker}"')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertNotIn(marker, result.stderr)

    def test_missing_jq_fails_loudly(self):
        with tempfile.TemporaryDirectory() as empty_path:
            env = {**os.environ, "PATH": empty_path}
            result = self.run_modifier("{}", env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("jq is required", result.stderr)


class DockerConfigurationTests(unittest.TestCase):
    def test_credential_helper_is_installed(self):
        self.assertIn('brew "docker-credential-helper"', INSTALLER.read_text())

    def test_scripts_are_valid_bash(self):
        for script in (MODIFIER, INSTALLER):
            result = subprocess.run(
                ["/bin/bash", "-n", str(script)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
