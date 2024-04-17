![](assets/dotfiles-icon-80x80.png)

# Mike Greiling's Dotfiles

A set of config files and itempotent scripts used to automate and synchronize my system environment across multiple machines.

## About

This repository contains the personal dotfiles of Mike Greiling. Originally forked from <https://mths.be/dotfiles>, it has subsequently been almost entirely rewritten and adapted to utilize [chezmoi](https://github.com/twpayne/chezmoi) (ʃeɪmwɑː | shay-mwah) for easy installation, maintenance, and synchronization. The aim is to make my preferred system configuration portable across workstations and operating systems in a deterministic way. All scripts are meant to be idempotent.

Anyone is free to use any or all of this repository for their own purposes, however I do not recommend using it verbatim. This script will prompt you for a decryption key (which you do not have) in order to enable it to install my private SSH and GPG keys.

## Installation

```bash
# if chezmoi is not installed already
BINDIR=/tmp/bin sh -c "$(curl -fsLS get.chezmoi.io)" -- init --use-builtin-git on --apply mikegreiling

# if chezmoi is installed (e.g. via a package manager like homebrew)
chezmoi init mikegreiling
```

The `--use-builtin-git on` is necessary if Xcode is not currently installed. On macOS, the `git` command is stubbed with a prompt to install Xcode, so chezmoi does not detect when it is actually unavailable.

You will be prompted to supply the decryption key to install SSH and GPG keys, followed by your full name and email address which will allow git to be configured properly, further followed by an option to override the computer and hostname settings. Once all of that information is collected, it will install the dotfiles and run setup scripts.

```bash
export PATH="/usr/local/bin:$PATH"
```

### Additional System Setup Instructions

Once chezmoi has run, a checklist with further manual steps will be placed on the Desktop.

It contains a list of items which cannot be done programatically (yet) like entering license keys, signing in to apps, and populating the dock.

## Bash Prompt Reference

Included is a prompt which was borrowed from [Nicolas Gallagher](https://github.com/necolas/dotfiles/).  Here is his descroption:

> ### Custom bash prompt
>
> I use a custom bash prompt based on the [Solarized](https://ethanschoonover.com/solarized/) color palette and influenced by @gf3's and @cowboy's custom prompts.
>
> When your current working directory is a Git repository, the prompt will display the checked-out branch's name (and failing that, the commit SHA that HEAD is pointing to). The state of the working tree is reflected in the following way:
>
> Sym | Key
> ----|---------------------------------
> `+` | Uncommitted changes in the index
> `!` | Unstaged changes
> `?` | Untracked files
> `$` | Stashed files
>
> Further details are in the `bash_prompt` file.

## Author

| [![twitter/mikegreiling](http://gravatar.com/avatar/33f90637d77f8d4da67faafd3af6597e?s=70)](http://twitter.com/mikegreiling "Follow @mikegreiling on Twitter") |
|---|
| [Mike Greiling](https://pixelcog.com/) |

## Thanks to…

* [Mathias Bynens](https://mathiasbynens.be/) and the original [dotfiles repository](https://github.com/mathiasbynens/dotfiles) I based mine off of
* [Tom Payne](https://github.com/twpayne) the creator of [chezmoi](https://www.chezmoi.io) and his own [dotfiles repository](https://github.com/twpayne/dotfiles) which I referenced extensively
* Katrin Leinweber's [dotfiles repository](https://gitlab.com/katrinleinweber/dotfiles)
* Paul Irish's [dotfiles repository](https://github.com/paulirish/dotfiles)
* [Matthew Mueller](https://github.com/MatthewMueller) and his "[Hacker's Guide to Setting Up Your Mac](https://web.archive.org/web/20160119134924/http://lapwinglabs.com/blog/hacker-guide-to-setting-up-your-mac)" article which inspired me to research this
