#!/usr/bin/env bash

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Homebrew and ensure it is up-to-date.
if [[ ! "$(type -P brew)" ]]; then
	true | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew update
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;

# Install `wget` with IRI support.
brew install wget --with-iri

# Install GnuPG to enable PGP-signing commits.
brew install gnupg

# Install more recent versions of some macOS tools.
brew install vim --with-override-system-vi
brew install grep
brew install screen

# Brew's openssh formula no longer supports the keychain patch
# https://archive.md/hSB6d
# brew install openssh

# Install other useful binaries.
brew install ack
brew install asdf
brew install chromedriver
brew install dnsmasq
brew install faac
brew install ffmpeg
brew install git
brew install git-lfs
brew install gs
brew install httpie
brew install imagemagick --with-webp
brew install lua
brew install lynx
brew install mcrypt
brew install p7zip
brew install pigz
brew install pv
brew install rename
brew install rlwrap
brew install siege
brew install ssh-copy-id
brew install sqlite
brew install tree
brew install vbindiff
brew install zopfli

# # Install cask-managed apps.
# brew tap caskroom/cask
# brew install cask

# export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# # brew install --cask arq
# # brew install --cask asepsis
# # brew install --cask beardedspice
# # brew install --cask bettertouchtool
# brew install --cask xbar
# # brew install --cask dash
# brew install --cask docker
# # brew install --cask fantastical
# # brew install --cask firefox
# # brew install --cask google-chrome
# # brew install --cask google-cloud-sdk
# brew install --cask kaleidoscope
# # brew install --cask kap
# brew install --cask keepingyouawake
# # brew install --cask transmission
# brew install --cask transmit
# # brew install --cask vagrant
# # brew install --cask virtualbox
# brew install --cask visual-studio-code
# brew install --cask vlc
# # brew install --cask vmware-fusion

# # Install App Store managed apps
# brew install mas

# # mas install 443987910 # 1Password
# # mas install 420212497 # Byword
# mas install 931657367 # Calcbot
# mas install 411643860 # DaisyDisk
# # mas install 890031187 # Marked 2
# # mas install 409203825 # Numbers
# # mas install 409201541 # Pages
# # mas install 407963104 # Pixelmator
# # mas install 880001334 # Reeder
# mas install 425424353 # The Unarchiver
# mas install 904280696 # Things3
# # mas install 557168941 # Tweetbot
# mas install 497799835 # Xcode

# # Remove outdated versions from the cellar.
# brew cask cleanup

brew cleanup
