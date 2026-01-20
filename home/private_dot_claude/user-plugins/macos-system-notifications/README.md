# macOS System Notifications Plugin for Claude Code

Shows macOS system notifications for Claude Code events with auto-dismiss functionality and click-to-activate support.

## Features

- **Visual notifications** for Claude Code events (idle prompts, stop events, permission requests)
- **Auto-dismiss** when you switch to or interact with the Claude pane (tmux only)
- **Click-to-activate** terminal window detection (works with Ghostty, iTerm2, kitty, Terminal.app, Warp)
- **Sound notifications** using macOS system sounds
- **Session grouping** - notifications are grouped by Claude session ID
- **Graceful degradation** - works outside tmux (without auto-dismiss feature)

## Dependencies

### Required: terminal-notifier

This plugin requires [terminal-notifier](https://github.com/julienXX/terminal-notifier) to send macOS notifications.

**Installation via Homebrew:**
```bash
brew install terminal-notifier
```

**Links:**
- [GitHub Repository](https://github.com/julienXX/terminal-notifier)
- [Homebrew Formula](https://formulae.brew.sh/formula/terminal-notifier)

If terminal-notifier is not installed, the plugin will display a warning at session start and gracefully disable notifications.

## Configuration

### Making Notifications Persistent (Optional)

By default, terminal-notifier shows **banner** notifications that disappear after a few seconds. To make notifications stay on screen until dismissed:

1. Open **System Settings** → **Notifications**
2. Find **"terminal-notifier"** in the app list (you may need to send a test notification first)
3. Change the alert style from **"Banners"** to **"Alerts"**

**Important Limitation:** This setting applies to **ALL** terminal-notifier notifications system-wide, not just Claude Code notifications. This is a reasonable compromise for most use cases, but be aware if you use terminal-notifier for other purposes.

## How It Works

### Events Handled

The plugin hooks into these Claude Code events:

| Event | Notification Message | Auto-Dismiss Trigger |
|-------|---------------------|---------------------|
| `Stop` | "Session stopped" | Pane focus, user input |
| `Notification` (idle_prompt) | "Session idle - awaiting input" | Pane focus, user input |
| `Notification` (permission_prompt) | "Input requested" | Pane focus, user input |
| `Notification` (elicitation_dialog) | "Input requested" | Pane focus, user input |

### Auto-Dismiss Feature

When running in tmux, the plugin:

1. **SessionStart hook**: Sets a global tmux hook on `after-select-pane` that checks if the focused pane has Claude metadata
2. **Pane focus**: When you switch to a pane with an active Claude session, notifications for that session are dismissed
3. **User input**: When you submit a prompt, notifications are dismissed via the `UserPromptSubmit` hook in the companion `tmux-session-metadata` plugin

### Terminal Detection

The plugin detects your terminal emulator and uses it for the click-to-activate feature:

```bash
# Clicking a notification activates the terminal window
terminal-notifier ... -execute "osascript -e 'tell application \"Ghostty\" to activate'"
```

Supported terminals: Ghostty, iTerm2, kitty, Terminal.app, Warp

## Implementation Decisions

### Why terminal-notifier?

We chose `terminal-notifier` over alternatives like `alerter` for these reasons:

**terminal-notifier:**
- ✅ Available via Homebrew (easy installation)
- ✅ Well-maintained and widely used
- ✅ Supports grouping (`-group`) and programmatic dismissal (`-remove`)
- ✅ Supports click-to-activate (`-execute`)
- ✅ Can use custom icons (`-appIcon`)
- ✅ System Settings integration for persistent notifications

**alerter (considered but rejected):**
- ❌ Not available in Homebrew
- ❌ Requires manual download from GitHub releases
- ❌ Poor installation experience for end users
- ✅ Has some additional features (buttons, dropdowns) we don't need

While `alerter` has native support for persistent notifications, the manual installation process made it less suitable for a publicly distributed plugin. The System Settings workaround for `terminal-notifier` is acceptable.

### Plugin Structure

```
macos-system-notifications/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── hooks/
│   └── hooks.json               # Hook event definitions
├── scripts/
│   ├── session-start-hook.sh    # Checks deps, sets up tmux hook
│   ├── dismiss-hook.sh          # Dismisses notifications
│   └── notification-hook.sh     # Shows notifications
└── README.md                    # This file
```

All hook commands reference scripts using `${CLAUDE_PLUGIN_ROOT}/scripts/` for installation-location independence.

## Companion Plugin

This plugin works best alongside [tmux-session-metadata](../tmux-session-metadata) which:
- Tracks Claude session state in tmux pane variables
- Dismisses notifications on user input via `UserPromptSubmit` hook
- Provides session metadata for other integrations

## Limitations

1. **Auto-dismiss requires tmux** - Outside tmux, notifications work but won't auto-dismiss on pane focus
2. **System Settings applies globally** - Persistent notification setting affects all terminal-notifier usage
3. **macOS only** - This plugin is specific to macOS and will not work on other operating systems
4. **Terminal detection best-effort** - If your terminal isn't detected, click-to-activate won't work (but notifications still appear)

## Troubleshooting

### No notifications appearing

1. Check if terminal-notifier is installed: `command -v terminal-notifier`
2. Check if Focus mode is enabled (blocks notifications)
3. Check System Settings → Notifications → terminal-notifier (must be enabled)

### Notifications don't dismiss automatically

1. Ensure you're running inside tmux
2. Check that `tmux-session-metadata` plugin is loaded
3. Verify the tmux hook is set: `tmux show-hooks -g | grep after-select-pane`

### Notifications disappear too quickly

Follow the "Making Notifications Persistent" instructions above to change from Banners to Alerts.

## License

[Specify your license here]

## Contributing

[Add contribution guidelines if making this public]
