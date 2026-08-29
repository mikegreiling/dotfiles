from __future__ import annotations

import base64
import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODIFIER = ROOT / "home/private_dot_docker/modify_private_config.json"
MIGRATION = ROOT / "home/.chezmoiscripts/macos/run_onchange_after_1-migrate-docker-credentials.sh"
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


class DockerCredentialMigrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.config = self.root / "config.json"
        self.helper = self.root / "docker-credential-osxkeychain"
        self.helper_log = self.root / "helper.log"
        self.helper.write_text(
            """#!/bin/bash
set -euo pipefail
payload=$(cat)
if [[ ${FAKE_HELPER_FAIL:-0} == 1 ]]; then
  exit 42
fi
printf '%s' "$payload" | jq -e '
  (.ServerURL | type) == "string" and (.ServerURL | length) > 0 and
  (.Username | type) == "string" and (.Username | length) > 0 and
  (.Secret | type) == "string" and (.Secret | length) > 0
' >/dev/null
printf 'stored\\n' >> "$FAKE_HELPER_LOG"
"""
        )
        self.helper.chmod(0o700)

    def tearDown(self):
        self.temporary.cleanup()

    def write_config(self, value: object) -> bytes:
        raw = (json.dumps(value, indent=2) + "\n").encode()
        self.config.write_bytes(raw)
        self.config.chmod(0o644)
        return raw

    def run_migration(self, *, fail_store: bool = False):
        env = {
            **os.environ,
            "DOCKER_CONFIG_FILE": str(self.config),
            "DOCKER_CREDENTIAL_HELPER": str(self.helper),
            "FAKE_HELPER_LOG": str(self.helper_log),
            "FAKE_HELPER_FAIL": "1" if fail_store else "0",
        }
        return subprocess.run(
            ["/bin/bash", str(MIGRATION)],
            capture_output=True,
            text=True,
            env=env,
            check=False,
        )

    def test_migrates_all_auths_preserves_unknown_fields_and_is_idempotent(self):
        secrets = ("fixture-secret-a", "fixture-secret-b:with-colon")
        self.write_config(
            {
                "auths": {
                    "one.example": {"auth": encoded_auth("alice", secrets[0]), "email": "kept"},
                    "two.example": {"auth": encoded_auth("bob", secrets[1])},
                    "identity.example": {"identitytoken": "preserved-token"},
                },
                "plugins": {"unknown": {"enabled": True}},
                "currentContext": "colima",
                "credsStore": "osxkeychain",
            }
        )

        first = self.run_migration()
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertTrue(all(secret not in first.stdout + first.stderr for secret in secrets))
        migrated = json.loads(self.config.read_text())
        self.assertNotIn("auth", migrated["auths"]["one.example"])
        self.assertNotIn("auth", migrated["auths"]["two.example"])
        self.assertEqual(migrated["auths"]["one.example"]["email"], "kept")
        self.assertEqual(migrated["auths"]["identity.example"]["identitytoken"], "preserved-token")
        self.assertEqual(migrated["plugins"], {"unknown": {"enabled": True}})
        self.assertEqual(stat.S_IMODE(self.config.stat().st_mode), 0o600)
        helper_calls = self.helper_log.read_text().splitlines()
        self.assertEqual(len(helper_calls), 2)

        second = self.run_migration()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(self.helper_log.read_text().splitlines(), helper_calls)

    def test_malformed_json_does_not_change_file_or_call_helper(self):
        marker = "fixture-secret-must-not-print"
        original = f'{{"auths":{{"registry":{{"auth":"{marker}"}}}}'.encode()
        self.config.write_bytes(original)

        result = self.run_migration()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.config.read_bytes(), original)
        self.assertFalse(self.helper_log.exists())
        self.assertNotIn(marker, result.stdout + result.stderr)

    def test_malformed_base64_does_not_change_file_or_call_helper(self):
        original = self.write_config({"auths": {"registry": {"auth": "not%%base64"}}})

        result = self.run_migration()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.config.read_bytes(), original)
        self.assertFalse(self.helper_log.exists())
        self.assertNotIn("not%%base64", result.stdout + result.stderr)

    def test_late_malformed_auth_prevents_any_keychain_writes(self):
        original = self.write_config(
            {
                "auths": {
                    "valid.example": {"auth": encoded_auth("alice", "fixture-secret")},
                    "broken.example": {"auth": "not%%base64"},
                }
            }
        )

        result = self.run_migration()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.config.read_bytes(), original)
        self.assertFalse(self.helper_log.exists())
        self.assertNotIn("fixture-secret", result.stdout + result.stderr)

    def test_store_failure_does_not_delete_any_inline_auth(self):
        secret = "fixture-secret-must-remain"
        original = self.write_config(
            {"auths": {"registry": {"auth": encoded_auth("alice", secret)}}, "unknown": True}
        )

        result = self.run_migration(fail_store=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.config.read_bytes(), original)
        self.assertNotIn(secret, result.stdout + result.stderr)
        self.assertIn("Docker config was not changed", result.stderr)


class DockerMigrationOrderingTests(unittest.TestCase):
    def test_helper_is_installed_before_migration_script_runs(self):
        self.assertIn('brew "docker-credential-helper"', INSTALLER.read_text())
        self.assertLess(INSTALLER.name, MIGRATION.name)

    def test_scripts_are_valid_bash(self):
        for script in (MODIFIER, MIGRATION, INSTALLER):
            result = subprocess.run(
                ["/bin/bash", "-n", str(script)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
