#!/usr/bin/env bash

echo "Installation completed! Almost done..."
echo ""

echo "Adding a checklist to the Desktop for some manual steps to be performed after installation."

cat <<EOF > ~/Desktop/Post-Installation-Checklist.txt
Post-Installation Checklist
===========================
- [ ] Configure TouchID and Apple Watch unlock
- [ ] Setup 1Password and 1Password Safari Extension
- [ ] Sign into iCloud
- [ ] Sign into Gmail
- [ ] Configure Time Machine
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
EOF

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
