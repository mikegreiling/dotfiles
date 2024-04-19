#!/usr/bin/env bash

echo ""
echo "-----------------------------------------------------------"
echo "  Installing macOS apps..."
echo "-----------------------------------------------------------"
echo ""

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

# Install some fonts
cask "font-droid-sans-mono-nerd-font"
cask "font-hack-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-sauce-code-pro-nerd-font" # source code pro

# Install some macOS apps and tools
cask "1password"
cask "1password-cli"
cask "betterdisplay"
cask "firefox"
cask "google-chrome"
cask "kaleidoscope"
cask "keepingyouawake"
cask "little-snitch"
cask "meetingbar"
cask "multitouch"
cask "slack"
cask "transmission"
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
echo "Setting some apps to launch automatically at login..."
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

echo ""
echo "Configuring some app-specific settings..."

###############################################################################
# Google Chrome & Google Chrome Canary                                        #
###############################################################################

# Disable the all too sensitive backswipe on trackpads
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

# Disable the all too sensitive backswipe on Magic Mouse
defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

# Use the system-native print preview dialog
defaults write com.google.Chrome DisablePrintPreview -bool true
defaults write com.google.Chrome.canary DisablePrintPreview -bool true

# Expand the print dialog by default
defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

###############################################################################
# Transmission.app                                                            #
###############################################################################

# Use `~/Documents/Torrents` to store incomplete downloads
defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
defaults write org.m0k.transmission IncompleteDownloadFolder -string "${HOME}/Documents/Torrents"

# Use `~/Downloads` to store completed downloads
defaults write org.m0k.transmission DownloadLocationConstant -bool true

# Don’t prompt for confirmation before downloading
defaults write org.m0k.transmission DownloadAsk -bool false
defaults write org.m0k.transmission MagnetOpenAsk -bool false

# Don’t prompt for confirmation before removing non-downloading active transfers
defaults write org.m0k.transmission CheckRemoveDownloading -bool true

# Trash original torrent files
defaults write org.m0k.transmission DeleteOriginalTorrent -bool true

# Hide the donate message
defaults write org.m0k.transmission WarningDonate -bool false
# Hide the legal disclaimer
defaults write org.m0k.transmission WarningLegal -bool false

# IP block list.
# Source: https://giuliomac.wordpress.com/2014/02/19/best-blocklist-for-transmission/
defaults write org.m0k.transmission BlocklistNew -bool true
defaults write org.m0k.transmission BlocklistURL -string "http://john.bitsurge.net/public/biglist.p2p.gz"
defaults write org.m0k.transmission BlocklistAutoUpdate -bool true

# Randomize port on launch
defaults write org.m0k.transmission RandomPort -bool true

###############################################################################
# Other apps                                                                  #
###############################################################################

# KeepingYouAwake.app - Prevent ugly highlight color when clicking
defaults write info.marcel-dierkes.KeepingYouAwake info.marcel-dierkes.KeepingYouAwake.MenuBarIconHighlightDisabled -bool YES

# VSCode - Disable press-and-hold for keys in favor of key repeat (allows VSCodeVim plugin to work properly)
# see: https://github.com/VSCodeVim/Vim?tab=readme-ov-file#mac
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false              # For VS Code
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false      # For VS Code Insider
defaults write com.vscodium ApplePressAndHoldEnabled -bool false                      # For VS Codium
defaults write com.microsoft.VSCodeExploration ApplePressAndHoldEnabled -bool false   # For VS Codium Exploration users
