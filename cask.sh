#!/usr/bin/env bash

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && echo "Homebrew is not installed." && return 1

# Ensure the cask keg and recipe are installed.
if [[ ! "$(brew ls --versions brew-cask)" ]]; then
	brew tap caskroom/cask
	brew install brew-cask
fi

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

brew cask install arq
brew cask install asepsis
brew cask install beardedspice
brew cask install bettertouchtool
brew cask install bitbar
brew cask install fantastical
brew cask install firefox
brew cask install google-chrome
brew cask install kaleidoscope
brew cask install keepingyouawake
brew cask install packer
brew cask install things
brew cask install transmission
brew cask install transmit
brew cask install vagrant
brew cask install virtualbox
brew cask install visual-studio-code
brew cask install vlc

# Remove outdated versions from the cellar.
brew cask cleanup
