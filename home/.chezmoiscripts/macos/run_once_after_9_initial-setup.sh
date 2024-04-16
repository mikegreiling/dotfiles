#!/usr/bin/env bash

echo ""
echo "-----------------------------------------------------------"
echo "  Installation completed! Almost done..."
echo "-----------------------------------------------------------"
echo ""

# TODO:
# - consider adopting mysides to manage Finder sidebar shortcuts
#   see https://macowners.club/posts/sane-defaults-for-macos/
#
# - consider adopting dockutil or custom script to manage the Dock icons
#   see https://github.com/keith/dotfiles/blob/d1c41406d1/osx/defaults.sh#L121-L133
#   see https://github.com/pmmmwh/dotfiles/blob/8593ff78f9/_lib/%40macos/dock.zsh#L4-L20
#
# - consider whether time machine can be enabled programatically
#   see https://git.herrbischoff.com/awesome-macos-command-line/about/#time-machine
#
# - consider enabling remote login by default
#   sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
#
# - enable some security settings by default
#   see https://git.herrbischoff.com/awesome-macos-command-line/about/#security

echo "Adding a checklist to the Desktop for some manual steps to be performed post-installation..."
echo ""

cat <<EOF > ~/Desktop/Post-Installation-Checklist.txt
Post-Installation Checklist
===========================
- [ ] Configure TouchID and Apple Watch unlock
- [ ] Setup 1Password and 1Password Safari Extension
- [ ] Sign into iCloud
- [ ] Sign into Gmail
- [ ] Configure Time Machine
- [ ] Enable FileVault
- [ ] Enable Firewall
- [ ] Register the following applications:
  - [ ] CleanShot X
  - [ ] Kaleidoscope
  - [ ] Little Snitch
  - [ ] Multitouch
- [ ] Sign in to the following apps:
  - [ ] Slack
  - [ ] Zoom
- [ ] Sign into the App Store and download the following apps:
  - [ ] Calcbot
  - [ ] DaisyDisk
  - [ ] The Unarchiver
  - [ ] Things 3
- [ ] Add preferred applications to the Dock
- [ ] Configure Finder sidebar
EOF

# https://git.herrbischoff.com/awesome-macos-command-line/about/#set-wallpaper
read -p "Would you like to set the Desktop wallpaper? [y/N] " -n 1;
echo "";
if [[ $REPLY =~ ^[Yy]$ ]]; then
  wallpaper="$HOME/.config/wallpapers/timelapse-stars-jakub-novacek-landscape.jpg"
  osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$wallpaper\""
fi;

read -p "Would you like to remove everything from the Dock? [y/N] " -n 1;
echo "";
if [[ $REPLY =~ ^[Yy]$ ]]; then
  defaults write com.apple.dock persistent-apps -array
  killall Dock
fi;

echo "Remember, some apps and settings will require a restart to take effect."
echo "If any issues were encountered during installation, be sure to update"
echo "the dotfiles to correct them for next time."
echo ""

# Reminder: this script is only ever run once upon initial setup.
# To clear the state of run_once_ scripts and re-run this script, run:
# $ chezmoi state delete-bucket --bucket=scriptState
#
# To clear the state of run_onchange_ scripts, run:
# $ chezmoi state delete-bucket --bucket=entryState
