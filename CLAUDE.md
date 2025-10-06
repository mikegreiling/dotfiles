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

### 5. Claude's File Editing Workflow

**CRITICAL**: When Claude needs to edit dotfiles managed by chezmoi, follow this exact workflow:

1. **Edit files in the home directory FIRST** (e.g., `~/.config/tmux/tmux.conf`, NOT `~/.local/share/chezmoi/home/private_dot_config/tmux/tmux.conf`)
2. **Use `chezmoi add` to sync changes** to the dotfiles repository
3. **Commit the changes** to git if requested

**NEVER**:
- ❌ Edit files directly in `~/.local/share/chezmoi/home/`
- ❌ Use `chezmoi apply` to copy chezmoi repo changes to home directory
- ❌ Skip the `chezmoi add` step after editing home directory files

**Example Workflow**:
```bash
# ✅ CORRECT: Edit home directory, then sync to dotfiles repo
Edit(~/.config/tmux/tmux.conf)           # Edit the actual file
chezmoi add ~/.config/tmux/tmux.conf     # Sync to dotfiles repo
cd ~/.local/share/chezmoi && git add . && git commit -m "Update tmux config"

# ❌ WRONG: Editing dotfiles repo directly
Edit(~/.local/share/chezmoi/home/private_dot_config/tmux/tmux.conf)  # NO!
chezmoi apply  # NO! This overwrites home directory
```

**Rationale**: The user prefers to maintain the home directory as the source of truth, with the dotfiles repository being a version-controlled copy. This workflow ensures that changes are made where they will take effect immediately, then synchronized to version control.

### 6. Status Checking Protocol

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

## Repository Structure and Configuration

### Directory Organization

The dotfiles repository follows chezmoi's structured approach with specific naming conventions:

- **Root directory**: `/Users/mike/.local/share/chezmoi` (aliased to `~/Projects/dotfiles`)
- **Target directory**: Configured via `.chezmoiroot` to use the `home/` subdirectory as the source root
- **All managed files**: Located under `home/` and mapped to corresponding locations in `~`

### File Naming Conventions

Chezmoi uses special prefixes and attributes to control file handling:

#### Dotfile Prefixes
- `dot_` → `.` (dotfiles): `dot_zshrc` becomes `~/.zshrc`
- `private_` → retains file permissions: `private_dot_ssh/` ensures `~/.ssh/` maintains proper permissions
- `executable_` → adds execute permission: `executable_script.sh` becomes executable
- `empty_` → creates empty files: `empty_dot_hushlogin` creates `~/.hushlogin`

#### Template Files
- `.tmpl` suffix → processed as Go templates with access to configuration data
- Examples: `private_dot_ssh/private_config.tmpl`, `.chezmoi.toml.tmpl`

#### Encrypted Files
- `.age` suffix → encrypted using age encryption with configured keys
- Examples: `encrypted_private_id_rsa.age`, `encrypted_private_pubring.kbx.age`

#### Symbolic Links
- `symlink_` prefix → creates symbolic links
- Example: `symlink_dotfiles.tmpl` creates symlink to dotfiles repo

### Encryption Configuration

**Encryption Method**: Age encryption (configured in `.chezmoi.toml.tmpl`)
- **Identity file**: `~/.config/chezmoi/key.txt` (decrypted from `key.txt.age`)
- **Recipient**: `age1j78rq7y3x5hx3x7lra4p44jkfzsme3v3vnhj6t9cpf8dywwwaeksqfgtx4`
- **Encrypted files**: SSH keys, GPG keys, private configuration files
- **Key management**: Passphrase-protected master key, automatically decrypted on first run

### Scripts and Automation

#### `.chezmoiscripts/` Directory
Contains installation and configuration scripts that run automatically:

**Execution Order**: Scripts run based on naming conventions:
- `run_once_before_*` → Run once before other operations
- `run_onchange_after_*` → Run when files change, after applying changes
- `run_once_after_*` → Run once after other operations, typically for final setup

**Current Scripts**:
- `run_once_before_decrypt-private-key.sh.tmpl` → Decrypts age key for secrets access
- `run_onchange_after_1-install-command-line-tools.sh` → Homebrew packages and CLI tools
- `run_onchange_after_2-install-macos-apps.sh` → macOS applications and fonts via Homebrew Cask
- `run_onchange_after_3-set-macos-system-prefs.sh.tmpl` → System preferences and defaults
- `run_onchange_after_4-set-hostname.sh.tmpl` → Computer name and hostname configuration
- `run_once_after_9_initial-setup.sh` → Final setup tasks and manual checklist generation

#### `.chezmoihooks/` Directory
Contains hooks that run during chezmoi operations:

- `pre-source-state.sh` → Runs before every chezmoi command to ensure prerequisites
  - Installs Homebrew if missing
  - Installs Xcode Command Line Tools if missing
  - Critical for ensuring chezmoi can function properly

### External Dependencies

**`.chezmoiexternal.toml`**: Manages external files and archives
- **Zsh plugin**: per-directory-history from oh-my-zsh repository
- **tmux plugin manager**: TPM archive for tmux plugin management
- **Auto-downloaded**: Files refreshed based on URL changes or explicit refresh

### Template Data and Configuration

**`.chezmoi.toml.tmpl`**: Dynamic configuration template
- **Interactive setup**: Prompts for user information on first run
- **Machine-specific data**: Username, full name, email, computer name, hostname  
- **Template variables**: Available in all `.tmpl` files throughout the repository
- **OS detection**: Handles macOS-specific configurations and paths

### Ignore Patterns

**`.chezmoiignore`**: Controls which files are applied on different systems
- **Platform-specific**: Excludes macOS scripts and directories on non-Darwin systems
- **Security**: Prevents sensitive files from being applied directly
- **Examples**: `key.txt.age`, `Library/` (macOS-only), private exports

### Key Organizational Patterns

#### Project-Specific Configurations
- `private_Projects/bstock-projects/` → Work-related configurations and Claude context
- `private_dot_claude/` → User-space Claude Code configurations and scripts

#### Application Configurations
- `private_dot_config/` → XDG Base Directory compliant configurations
- `private_dot_gnupg/` → GPG configuration and encrypted keyrings
- `private_dot_ssh/` → SSH client configuration and encrypted keys
- `private_Library/Application Support/` → macOS application support files

#### Development Tools
- Git configuration with templates for machine-specific values
- Shell configurations (zsh, bash) with modular sourcing
- Terminal emulator themes and configurations
- Development tool configuration (tmux, vim, lsd, etc.)

### Security Considerations

- **Encrypted secrets**: All private keys, GPG data, and sensitive configs use age encryption
- **Proper permissions**: `private_` prefix ensures secure file permissions are maintained
- **Key derivation**: Master passphrase protects all encrypted content
- **Ignore patterns**: Sensitive files excluded from direct application

## Remember

- **Home directory first**: Your local changes are usually what you want to keep
- **Status before action**: Always check `chezmoi status` before making changes  
- **Add, don't apply**: Default to `chezmoi add` rather than `chezmoi apply`
- **Documentation first**: Always consult Context7 documentation before proceeding
- **Understand the structure**: Respect the naming conventions and organizational patterns
- **Test encryption**: Ensure you can decrypt secrets before making changes to encrypted files
- **Script dependencies**: Remember that hooks ensure prerequisites are met before operations