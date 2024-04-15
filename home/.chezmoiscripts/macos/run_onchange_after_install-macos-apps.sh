#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v -p 'Enter password for %p:'

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Update homebrew and install required packages
HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_AUTO_UPDATE_SECS=3600 \
brew bundle install \
	--quiet \
	--no-lock \
	--file=/dev/stdin <<BREWS
tap "homebrew/bundle"
tap "homebrew/cask-fonts"
tap "homebrew/cask-versions"

# Install some macOS apps and tools
cask "1password"
cask "1password-cli"
cask "firefox"
cask "google-chrome"
cask "kaleidoscope"
cask "keepingyouawake"
cask "little-snitch"
cask "meetingbar"
cask "multitouch"
cask "slack"
cask "vlc"
cask "visual-studio-code"
cask "xbar"
cask "zoom"

# Pin CleanShot X to v4.5.1 as that is the latest version my license supports
cask "https://raw.githubusercontent.com/Homebrew/homebrew-cask/cfa5ab5a9291d080b8c82fd06d28f27b665bf136/Casks/cleanshot.rb"
BREWS

# Save the list of installed packages to a Brewfile for inspection
brew bundle dump --file=${HOME}/Downloads/Brewfile-$(hostname) --force

echo ""
echo "Setting some apps to launch automatically at login"
osascript >/dev/null <<EOD
tell application "System Events"
	make login item at end with properties {path:"/Applications/1Password.app"}
	make login item at end with properties {path:"/Applications/CleanShot X.app"}
	make login item at end with properties {path:"/Applications/KeepingYouAwake.app"}
	make login item at end with properties {path:"/Applications/Little Snitch.app"}
	make login item at end with properties {path:"/Applications/MeetingBar.app"}
	make login item at end with properties {path:"/Applications/Multitouch.app"}
	make login item at end with properties {path:"/Applications/xbar.app"}
end tell
EOD
