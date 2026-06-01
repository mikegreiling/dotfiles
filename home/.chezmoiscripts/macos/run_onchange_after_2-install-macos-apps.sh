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

# Pin CleanShot X to v4.7.6 — the newest version Homebrew packaged in the 4.7.x
# line. My license is valid through 4.7.7, and CleanShot's own license-gated
# in-app updater makes that final hop; pinning only keeps a fresh machine from
# installing the *latest* build, which is past my license.
#
# Two Homebrew constraints force this shape:
#   1. Homebrew no longer installs casks by URL or file path ("casks must live
#      in a tap"), so the old `cask "https://.../cleanshot.rb"` pin stopped working.
#   2. Homebrew's own archived 4.7.6 cask no longer parses on current Homebrew
#      (it used `depends_on macos: :mojave`, since removed), so we can't drop it
#      in verbatim either.
# So we stage a minimal cask carrying Homebrew's official 4.7.6 values (url +
# sha256, verified to match the live dmg) in a tiny local tap. `auto_updates true`
# is what keeps `brew upgrade` / `brew bundle` from ever bumping it past my license.
# To bump the pin: change version + sha256 from
#   curl -sL "https://updates.getcleanshot.com/v3/CleanShot-X-<ver>.dmg" | shasum -a 256
PINNED_TAP="$(brew --repository)/Library/Taps/mike/homebrew-pinned"
mkdir -p "${PINNED_TAP}/Casks"
cat > "${PINNED_TAP}/Casks/cleanshot.rb" <<'RUBY'
cask "cleanshot" do
  version "4.7.6"
  sha256 "677178b8060c5e3d579d5a534792c2b9649c835b1d07aa307f18a28a73307b55"

  url "https://updates.getcleanshot.com/v3/CleanShot-X-#{version}.dmg"
  name "CleanShot"
  desc "Screen capturing tool"
  homepage "https://getcleanshot.com/"

  auto_updates true

  app "CleanShot X.app"

  uninstall quit: "pl.maketheweb.cleanshotx"
end
RUBY

# Update homebrew and install required packages
HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_AUTO_UPDATE_SECS=3600 \
brew bundle install \
	--quiet \
	--file=/dev/stdin <<BREWS
tap "homebrew/bundle"

# Install some fonts
cask "font-atkinson-hyperlegible"
cask "font-droid-sans-mono-nerd-font"
cask "font-hack-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "font-meslo-lg-nerd-font"
cask "font-sauce-code-pro-nerd-font" # source code pro
cask "font-sf-pro"
cask "font-sf-mono"

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
cask "obsidian"
cask "slack"
cask "transmission"
cask "vlc"
cask "visual-studio-code"
cask "xbar"
cask "zoom"

# Install some command-line tools that interface with macOS
brew "pinentry-mac"
cask "gcloud-cli" # Google Cloud SDK (gcloud/gsutil/bq); formerly the "google-cloud-sdk" cask. Used by the gws Workspace CLI's `auth setup`.

# Pin CleanShot X to a license-compatible version (staged in the mike/pinned tap above)
cask "mike/pinned/cleanshot"
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
