from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
APP_INSTALLER = ROOT / "home/.chezmoiscripts/macos/run_onchange_after_2-install-macos-apps.sh"
POST_INSTALL = ROOT / "home/.chezmoiscripts/macos/run_once_after_9_initial-setup.sh"


class FluidVoiceMacOSSetupTests(unittest.TestCase):
    def test_preference_is_applied_after_install_and_before_first_launch_instruction(self):
        installer = APP_INSTALLER.read_text()
        checklist = POST_INSTALL.read_text()

        cask = 'cask "fluidvoice"'
        preference = "defaults write com.FluidApp.app LocalAPIEnabled -bool true"
        self.assertIn(cask, installer)
        self.assertIn(preference, installer)
        self.assertLess(installer.index(cask), installer.index(preference))
        self.assertIn("Launch FluidVoice, then run \\`fluidvoice-dictionary-sync\\`", checklist)

    def test_preference_is_verified_without_setting_a_custom_port(self):
        installer = APP_INSTALLER.read_text()

        self.assertIn("defaults read com.FluidApp.app LocalAPIEnabled", installer)
        self.assertNotIn("defaults write com.FluidApp.app LocalAPIPort", installer)

    def test_modified_setup_scripts_remain_valid_bash(self):
        for script in (APP_INSTALLER, POST_INSTALL):
            result = subprocess.run(
                ["bash", "-n", script],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
