#!/usr/bin/env bash

echo ""
echo "-----------------------------------------------------------"
echo "  Installing command-line tools..."
echo "-----------------------------------------------------------"
echo ""

# Ask for the administrator password upfront
sudo -v -p 'Enter password for %p:'

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Ensure we run our installs with XDG configured
export XDG_CONFIG_HOME="$HOME/.config"

# Update homebrew and install required packages
HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_AUTO_UPDATE_SECS=3600 \
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

# Install zsh and some zsh plugins
brew "powerlevel10k"
brew "zsh"
brew "zsh-autosuggestions"
brew "zsh-history-substring-search"
brew "zsh-syntax-highlighting"

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
brew "lsd"
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
	echo ""
	echo "Adding ${BREW_PREFIX}/bin/bash to /etc/shells..."
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
fi;

# Add brew-installed zsh to the list of allowable shells
if ! fgrep -q "${BREW_PREFIX}/bin/zsh" /etc/shells; then
	echo ""
	echo "Adding ${BREW_PREFIX}/bin/zsh to /etc/shells..."
  echo "${BREW_PREFIX}/bin/zsh" | sudo tee -a /etc/shells;
fi;

# Change shell to brew-installed zsh
if [[ "$SHELL" != "${BREW_PREFIX}/bin/zsh" ]]; then
	echo ""
	echo "Changing default shell to zsh..."
	chsh -s "${BREW_PREFIX}/bin/zsh";
fi

# Save the list of installed packages to a Brewfile for inspection
brew bundle dump --file=${HOME}/Downloads/Brewfile-$(hostname) --force
