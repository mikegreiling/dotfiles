# Chezmoi Dotfiles Management Guidelines

This repository (`~/.local/share/chezmoi`, aliased to `~/Projects/dotfiles`) contains my dotfiles managed by [chezmoi](https://chezmoi.io). This file establishes critical safety guidelines for Claude Code when interacting with chezmoi.

## Repository Structure

- **Location**: `~/.local/share/chezmoi` (aliased to `~/Projects/dotfiles`)
- **Purpose**: Version control for user preferences, shell configuration, scripts, and system settings
- **Management**: Uses chezmoi to maintain dotfiles across machines while handling machine-specific differences

## Critical Safety Rules

### 1. Always Consult Documentation First

**MANDATORY**: Before executing ANY chezmoi command, Claude MUST use the Context7 MCP service to look up chezmoi documentation to ensure proper command syntax and understanding of use cases.

### 2. Home Directory is Source of Truth

**FUNDAMENTAL PRINCIPLE**: In most cases, files in the home directory (`~`) are MORE CURRENT than their counterparts in the dotfiles repository.

Common scenario:
- `chezmoi status` shows `~/.claude/CLAUDE.md` differs from `~/.local/share/chezmoi/home/private_dot_claude/private_CLAUDE.md`
- Running `chezmoi apply` would OVERWRITE the home directory file with the (likely older) dotfiles version
- This is ALMOST NEVER what we want

### 3. Strict `chezmoi apply` Restrictions

**NEVER** run `chezmoi apply` unless:
1. Explicitly instructed by the user to do so
2. After running `chezmoi status` to identify what would be overwritten
3. After confirming with the user that overwriting local changes is desired

Even when instructed to run `chezmoi apply`:
1. **ALWAYS** run `chezmoi status` first
2. **ALWAYS** review what files would be overwritten
3. **ALWAYS** confirm with the user before proceeding

### 4. Preferred Workflow: Use `chezmoi add`

**DEFAULT APPROACH**: When files differ between home directory and dotfiles repo:

1. Use `chezmoi add <file>` to update the dotfiles repo with the current home directory version
2. This preserves your latest changes and updates the version-controlled copy
3. Then commit the changes to git

Example:
```bash
# Safe workflow
chezmoi status                    # See what differs
chezmoi add ~/.claude/CLAUDE.md   # Update dotfiles repo with home version
git add .                         # Stage changes
git commit -m "Update CLAUDE.md"  # Commit
git push                          # Push to remote
```

### 5. Status Checking Protocol

Before ANY chezmoi operation that could modify files:
1. Run `chezmoi status` to see current state
2. Identify files that would be modified
3. Determine if local changes would be lost
4. Choose appropriate action (`chezmoi add` vs `chezmoi apply`)

## Command Reference

### Safe Commands (read-only)
- `chezmoi status` - Check current state
- `chezmoi diff` - See differences
- `chezmoi doctor` - Check for issues
- `chezmoi managed` - List managed files

### Commands Requiring Caution
- `chezmoi add <file>` - **Preferred**: Updates dotfiles repo with home directory version
- `chezmoi apply` - **Dangerous**: Overwrites home directory with dotfiles repo version
- `chezmoi edit <file>` - Edit in source directory
- `chezmoi update` - Pull from remote and apply (combines git pull + chezmoi apply)

## Typical Workflows

### Adding New Files
```bash
chezmoi add ~/.newconfig           # Add file to chezmoi management
chezmoi cd && git add . && git commit -m "Add newconfig"
```

### Updating Existing Files
```bash
chezmoi status                     # Check what's changed
chezmoi add ~/.changedfile         # Update dotfiles repo with home version
chezmoi cd && git add . && git commit -m "Update changedfile"
```

### Syncing Across Machines (CAREFUL)
```bash
chezmoi status                     # Check local state first
# Review output carefully
chezmoi update                     # Only if you want to overwrite local changes
```

## Emergency Recovery

If `chezmoi apply` accidentally overwrites important local changes:
1. Check git history: `chezmoi cd && git log --oneline`
2. Files might be recoverable from previous commits
3. Use `git checkout HEAD~1 -- filename` to restore previous versions

## Remember

- **Home directory first**: Your local changes are usually what you want to keep
- **Status before action**: Always check `chezmoi status` before making changes  
- **Add, don't apply**: Default to `chezmoi add` rather than `chezmoi apply`
- **Documentation first**: Always consult Context7 documentation before proceeding