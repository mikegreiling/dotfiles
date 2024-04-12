#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v -p 'Enter password for %p:'

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Update homebrew and install required packages
brew update
brew upgrade
brew bundle install \
	--quiet \
	--no-lock \
	--file=/dev/stdin <<BREWS
tap "homebrew/bundle"

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
BREWS

BREW_PREFIX=$(brew --prefix)

# Add brew-installed bash to the list of allowable shells
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
	echo "Adding ${BREW_PREFIX}/bin/bash to /etc/shells"
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
fi;

# Change shell to brew-installed bash
# TODO: remove this bit if/when we switch to zsh
if [[ "$SHELL" != "${BREW_PREFIX}/bin/bash" ]]; then
	chsh -s "${BREW_PREFIX}/bin/bash";
fi

# Save the list of installed packages to a Brewfile for inspection
brew bundle dump --file=${HOME}/Downloads/Brewfile-$(hostname) --force
