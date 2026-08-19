---
name: Dotfiles Workflow
description: This skill should be used when the user asks to "update dotfiles", "commit to dotfiles", "add to chezmoi", "update bash config", "update zsh config", "update shell config", "update brew packages", "commit Claude config changes", "commit MCP config", "update Claude slash commands", or mentions "chezmoi" in the context of making configuration changes. Load this skill whenever modifying any file managed by chezmoi.
version: 0.1.0
---

# Dotfiles Workflow

This skill provides guidance for safely managing dotfiles and configuration files using chezmoi.

## The Cardinal Rule

**DO NOT EDIT CHEZMOI FILES DIRECTLY.** The source of truth is always the live file in the home directory (`~`), not the chezmoi repository copy.

Always follow this workflow:
1. **Edit the live file** in `~/.config/`, `~/.claude/`, `~/.bashrc`, etc.
2. **Test and validate** the changes work as intended
3. **Run `chezmoi add <file>`** to sync the validated change into the dotfiles repo
4. **Commit the change** to git in the dotfiles repo

## Before Using Any chezmoi Command

Read `~/.local/share/chezmoi/CLAUDE.md` for comprehensive guidelines. This is **mandatory** before executing any chezmoi command.

## Safety Rules

- **NEVER use `--force`** with `chezmoi apply`. This overwrites live files with potentially older dotfiles versions and destroys unsynced changes.
- **Always run `chezmoi status` first** before any apply operation to identify what would be overwritten.
- If `chezmoi apply` would interact with the user or block execution, stop and report the issue rather than using `--force`.

## What Gets Committed to Dotfiles

Any changes to the following should be committed to the dotfiles repo via chezmoi:

- `bash` or `zsh` config files
- macOS applications managed by `brew`
- Claude slash commands (`~/.claude/commands/`)
- Claude memory files (`~/.claude/CLAUDE.md`, `~/.claude/skills/`, etc.)
- MCP config files
- Any other user-level configuration files managed by chezmoi

Whenever making changes to these files, prompt the user to commit the changes to the dotfiles repository.

## Dotfiles Repository Location

- **Live location**: `~/.local/share/chezmoi`
- **Alias**: `~/Projects/dotfiles`
- Managed by chezmoi; do not edit files here directly

## Committing Changes

After running `chezmoi add <file>`:

```bash
cd ~/.local/share/chezmoi
git add -A
git commit -m "Descriptive message about what changed"
```

Follow the chezmoi repository's own git workflow for pushing changes.
