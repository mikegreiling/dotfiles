#!/usr/bin/env bash

# Install Homebrew and ensure it is up-to-date.
if [[ ! "$(type -P brew)" ]]; then
	true | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update
brew upgrade --all

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
  chsh -s /usr/local/bin/bash;
fi;

# Install more recent versions of some macOS tools.
brew install vim --with-override-system-vi
brew install grep
brew install openssh
brew install screen

# Install other useful binaries.
brew install ack
brew install dnsmasq
brew install exiv2
brew install faac
brew install ffmpeg
brew install git
brew install git-lfs
brew install gnupg
brew install httpie
brew install hub
brew install imagemagick --with-webp
brew install lua
brew install mcrypt
brew install node
brew install p7zip
brew install pigz
brew install pkg-config
brew install pv
brew install rbenv
brew install rename
brew install rlwrap
brew install siege
brew install sqlite
brew install tree
brew install wget --with-iri
brew install yarn
brew install zopfli

# Install cask-managed apps.
brew tap caskroom/cask
brew install brew-cask

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

brew cask install arq
brew cask install asepsis
brew cask install beardedspice
brew cask install bettertouchtool
brew cask install bitbar
brew cask install docker
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
brew cleanup
