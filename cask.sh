#!/usr/bin/env bash

# Exit if Homebrew is not installed.
[[ ! "$(type -P brew)" ]] && echo "Homebrew is not installed." && return 1

# Ensure the cask keg and recipe are installed.
brew tap caskroom/cask
brew install brew-cask

# Exit if, for some reason, cask is not installed.
[[ ! "$(brew ls --versions brew-cask)" ]] && echo "Brew-cask failed to install." && return 1

# Apps
apps=(
	arq
	asepsis
	atom
	beardedspice
	bettertouchtool
	bitbar
	fantastical
	firefox
	flash
	flux
	google-chrome
	kaleidoscope
	keepingyouawake
	moom
	packer
	things
	transmission
	transmit
	vagrant
	virtualbox
	vlc
)

# Install apps to /Applications
# Default is: /Users/$user/Applications
brew cask install --appdir="/Applications" ${apps[@]}

# Setup Atom.io plugins (apm should be installed with atom)
[[ ! "$(type -P apm)" ]] && echo "Atom Package Manager failed to install." && return 1

# Atom packages
atom_pkgs=(
	codebug
	dash
	editorconfig
	minimap
	term2
	graphite-ui
)

apm install ${atom_pkgs[@]}
