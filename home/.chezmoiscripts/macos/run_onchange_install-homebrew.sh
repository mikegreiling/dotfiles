#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v -p 'Enter password for %p:'

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Homebrew and ensure it is up-to-date.
if [[ ! "$(type -P brew)" ]]; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

brew update
brew upgrade

brew bundle install \
	--quiet \
	--no-lock \
	--file=/dev/stdin <<BREWS
tap "homebrew/bundle"
tap "homebrew/cask-fonts"
tap "homebrew/cask-versions"

# Install essentials
brew "coreutils"
brew "moreutils"
brew "findutils"
brew "wget"
brew "gnupg"

# Install modern version of bash
brew "bash"
brew "bash-completion@2"

# Install some useful command-line utilities
brew "ack"
brew "age"
brew "asdf"
brew "bat"
brew "chezmoi"
brew "dnsmasq"
brew "faac"
brew "ffmpeg"
brew "fzf"
brew "git"
brew "git-lfs"
brew "git-absorb"
brew "gitlab-ci-local"
brew "glab"
brew "grep"
brew "gs"
brew "httpie"
brew "jq"
brew "lazydocker"
brew "lefthook"
brew "lftp"
brew "lua"
brew "mcrypt"
brew "p7zip"
brew "pigz"
brew "pv"
brew "ripgrep"
brew "sd"
brew "shfmt"
brew "siege"
brew "sqlite"
brew "tree"
brew "tealdeer"
brew "ugrep"
brew "vbindiff"
brew "vim"
brew "xh"
brew "zopfli"

# Install some macOS apps and tools
cask "1password"
cask "1password-cli"
cask "kaleidoscope"
cask "keepingyouawake"
cask "little-snitch"
cask "meetingbar"
cask "slack"
cask "vlc"
cask "xbar"
cask "zoom"
BREWS

# Save the list of installed packages to a Brewfile for inspection
brew bundle dump --file=${HOME}/Downloads/Brewfile-$(hostname) --force

# TODO: remove this bit once we switch to zsh
BREW_PREFIX=$(brew --prefix)

# Switch to using brew-installed bash as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;
