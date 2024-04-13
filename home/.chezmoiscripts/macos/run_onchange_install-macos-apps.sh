#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v -p 'Enter password for %p:'

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Update homebrew and install required packages
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
cask "kaleidoscope"
cask "keepingyouawake"
cask "little-snitch"
cask "meetingbar"
cask "slack"
cask "vlc"
cask "visual-studio-code"
cask "xbar"
cask "zoom"
BREWS

# Save the list of installed packages to a Brewfile for inspection
brew bundle dump --file=${HOME}/Downloads/Brewfile-$(hostname) --force
