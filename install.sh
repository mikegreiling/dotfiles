#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

# git pull origin main;

function doBootstrap() {
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude "/*.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . ~;
	source ~/.bash_profile;
}

function doInstall() {
	source brew.sh
	source macos.sh
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doBootstrap;
	[[ "$(uname)" == "Darwin" ]] && doInstall;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doBootstrap;

		if [[ "$(uname)" == "Darwin" ]]; then
			read -p "Would you like to install homebrew, cask, and macOS system tweaks? (y/n) " -n 1;
			echo "";
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				doInstall;
			fi;
		fi;
	fi;
fi;

unset doBootstrap;
unset doInstall;
