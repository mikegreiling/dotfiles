#!/bin/sh

# This is where we install things that are required for our chezmoi scripts to
# run e.g. our password manager or other dependencies that must exist before
# chezmoi compiles templates.

# This script is run before every command so it must run and exit quickly

set -e

is_macos() {
  [ $(uname -s) = 'Darwin' ]
}

has_homebrew() {
  type brew >/dev/null 2>&1
}

has_xcode_clt() {
  xcode-select -p 1>/dev/null
}

# Exit immediately if we are not on macOS
is_macos || exit

if ! has_homebrew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ $? -ne 0 ]; then
    echo "Error: Failed to install Homebrew."
    exit 1
  fi

  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Installing Homebrew should automatically install Xcode Command Line Tools, but
# we'll check just in case because the user can cancel the installation
if ! has_xcode_clt; then
  xcode-select --install

  if [ $? -ne 0 ]; then
    echo "Error: Failed to install Xcode Command Line Tools."
    exit 1
  fi

  # For some reason the above install command doesn't always work, so if it's
  # still not installed, we'll prompt the user to install it manually and exit
  if ! has_xcode_clt; then
    echo "Error: This command cannot be run without Xcode Command Line Tools."
    echo "Please install Xcode CLT manually and re-run this script"
    exit 1
  fi
fi
