# Add homebrew shell environment (this must be done early or auto-complete will bug out)
[ -s "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# * ~/.path can be used to extend `$PATH`.
[ -r ".path" ] && [ -f ".path" ] && source ".path";

# Load the shell dotfiles:
source .config/bash_prompt;
source .config/exports;
source .config/aliases;
source .config/functions;

# * ~/.extra can be used for other settings you don’t want to commit.
[ -r ".extra" ] && [ -f ".extra" ] && source ".extra";

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Append to the Bash history file, rather than overwriting it
shopt -s histappend;

# Autocorrect typos in path names when using `cd`
shopt -s cdspell;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for many Bash commands
if which brew &> /dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
	# Ensure existing Homebrew v1 completions continue to work
	export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d";
	source "$(brew --prefix)/etc/profile.d/bash_completion.sh";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type __git_complete &> /dev/null; then
	__git_complete g __git_main;
elif type _git &> /dev/null; then
	complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

# ASDF stuff
[ -s "/opt/homebrew/opt/asdf/libexec/asdf.sh" ] && \. "/opt/homebrew/opt/asdf/libexec/asdf.sh"  # This loads asdf
[ -s "/opt/homebrew/opt/asdf/etc/bash_completion.d/asdf.bash" ] && \. "/opt/homebrew/opt/asdf/etc/bash_completion.d/asdf.bash"  # This loads asdf bash_completion
