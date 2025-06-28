# Claude Code User Memory

## GPG Signing Configuration

Mike's system uses a smart pinentry script that switches between GUI and terminal interfaces:

- **Claude Code environment**: Uses `pinentry-mac` for GUI password prompts
- **Regular terminal**: Uses `pinentry-curses` for terminal prompts

### Common GPG Signing Errors

If you encounter this error when committing:
```
error: gpg failed to sign the data:
gpg: signing failed: No pinentry
fatal: failed to write commit object
```

This means `pinentry-mac` is not installed. Install it with:
```bash
brew install pinentry-mac
```

The smart pinentry script is located at `~/.local/bin/gpg-pinentry-smart` and is managed via chezmoi dotfiles.