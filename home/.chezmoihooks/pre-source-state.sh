#!/bin/sh

# This is where we install things that are required for our chezmoi scripts to
# run e.g. our password manager or other dependencies that must exist before
# chezmoi compiles templates.

# This script is run before every single command so it must be fast

set -e

has_xcode_clt() {
  xcode-select -p 1>/dev/null
}

has_1password() {
  type op >/dev/null 2>&1
}

has_homebrew() {
  type brew >/dev/null 2>&1
}

# Exit immediately if xcode, op and brew are already in $PATH
has_xcode_clt && has_homebrew && has_1password && exit

case "$(uname -s)" in
Darwin)
  if ! has_xcode_clt; then
    xcode-select --install

    # For some reason the above install command doesn't always work, so if it's
    # not installed, we'll just prompt the user to install it manually and exit
    if ! has_xcode_clt; then
      echo "Please install Xcode Command Line Tools and run this script again"
      exit 1
    fi
  fi

  if ! has_homebrew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if ! has_1password; then
    brew install --cask 1password 1password-cli
  fi

  ;;
*)
  echo "Unsupported OS"
  exit 1
  ;;
esac
