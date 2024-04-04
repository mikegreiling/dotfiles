# Mike Greiling's Dotfiles

An itempotent set of scripts and config files to automate and synchronize my system environment across multiple machines.

## About

This is a very basic dotfile repository forked from <https://mths.be/dotfiles>. I have modified the settings to my liking, enhanced the installation process, and added cask to automate macOS Application installation.

## Installation

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

### Using Git and the install script

You can clone the repository wherever you want. The bootstrapper script will pull in the latest version and copy the files to your home folder.

```bash
git clone https://github.com/mikegreiling/dotfiles.git && cd dotfiles && source install.sh
```

To update, `cd` into your local `dotfiles` repository and then:

```bash
source install.sh
```

### Git-free install

To install these dotfiles without Git:

```bash
cd; curl -#L https://github.com/mikegreiling/dotfiles/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,*.sh,LICENSE-MIT.txt}
```

To update later on, just run that command again.

### Specify the `$PATH`

If `~/.path` exists, it will be sourced along with the other files, before any feature testing (such as [detecting which version of `ls` is being used](https://github.com/mathiasbynens/dotfiles/blob/aff769fd75225d8f2e481185a71d5e05b76002dc/.aliases#L21-26)) takes place.

Here’s an example `~/.path` file that adds `/usr/local/bin` to the `$PATH`:

```bash
export PATH="/usr/local/bin:$PATH"
```

### Add custom commands without creating a new fork

If `~/.extra` exists, it will be sourced along with the other files. You can use this to add a few custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.
You could also use `~/.extra` to override settings, functions and aliases from my dotfiles repository. It’s probably better to [fork this repository](https://github.com/mathiasbynens/dotfiles/fork) instead, though.

My `~/.extra` looks something like this:

```bash
# Git credentials
# Not under version control to prevent people from
# accidentally committing with your details
GIT_AUTHOR_NAME="Mike Greiling"
GIT_AUTHOR_EMAIL="mike@pixelcog.com"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
# Set the credentials (modifies ~/.gitconfig)
git config --global user.name "$GIT_AUTHOR_NAME"
git config --global user.email "$GIT_AUTHOR_EMAIL"
```

### Sensible macOS defaults

When setting up a new Mac, you may want to set some sensible macOS defaults:

```bash
./macos.sh
```

### Install Homebrew formulae

When setting up a new Mac, you may want to install some common [Homebrew](https://brew.sh/) formulae (after installing Homebrew, of course):

```bash
./brew.sh
```

Some of the functionality of these dotfiles depends on formulae installed by `brew.sh`. If you don’t plan to run `brew.sh`, you should look carefully through the script and manually install any particularly important ones. A good example is Bash/Git completion: the dotfiles use a special version from Homebrew.

## Additional System Setup Instructions

Once this is all in place, there are a few other items which must be done manually (included here for my own reference).

1. Go to System Settings ➜ General and:
  - Check "Ask to keep changes when closing documents"
  - Uncheck "Close windows when quitting an app"  
    _*I have not yet learned how to do this programmatically_
2. [Generate your ssh key](https://help.github.com/articles/generating-ssh-keys/) and install it on GitHub.
3. Enter any license keys necessary for installed apps (Things, Kaleidoscope, Transmit, et al)

## Prompt Reference

Included is a prompt which I shamelessly stole from [Nicolas Gallagher](https://github.com/necolas/dotfiles/).  Here is his descroption:

> ### Custom bash prompt
>
> I use a custom bash prompt based on the Solarized color palette and influenced by @gf3's and @cowboy's custom prompts.
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
>
> Screenshot:
>
> ![](http://i.imgur.com/DSJ1G.png)
>


## Author

| [![twitter/mikegreiling](http://gravatar.com/avatar/33f90637d77f8d4da67faafd3af6597e?s=70)](http://twitter.com/mikegreiling "Follow @mikegreiling on Twitter") |
|---|
| [Mike Greiling](https://pixelcog.com/) |

Original by [Mathias Bynens](https://mathiasbynens.be/)

## Thanks to…

* [Mathias Bynens](https://mathiasbynens.be/) and the original [dotfiles repository](https://github.com/mathiasbynens/dotfiles)
* [Nicolas Gallagher](http://nicolasgallagher.com/) and his [dotfiles repository](https://github.com/necolas/dotfiles)
* [Ben Alman](http://benalman.com/) and his [dotfiles repository](https://github.com/cowboy/dotfiles)
* [Matthew Mueller](https://github.com/MatthewMueller) and his "[Hacker's Guide to Setting Up Your Mac](https://web.archive.org/web/20160119134924/http://lapwinglabs.com/blog/hacker-guide-to-setting-up-your-mac)" article which inspired me to research this
* [Brandon Brown](https://brandonb.io/) and his [osx-for-hackers.sh](https://gist.github.com/brandonb927/3195465) gistfile
