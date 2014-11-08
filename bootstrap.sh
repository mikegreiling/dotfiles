#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

function doIt() {
	rsync --exclude ".git/" --exclude ".DS_Store" --exclude "bootstrap.sh" \
		--exclude "brew.sh" --exclude "cask.sh" --exclude "init/" --exclude "osx.sh" \
		--exclude "README.md" --exclude "LICENSE-MIT.txt" -avh --no-perms . ~;
	source ~/.bash_profile;

	# If running OSX install homebrew, cask, and system tweaks
	if [[ "$(uname)" == "Darwin" ]]; then
		chflags hidden ~/bin
		source brew.sh
		source cask.sh
		source osx.sh
	fi;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
