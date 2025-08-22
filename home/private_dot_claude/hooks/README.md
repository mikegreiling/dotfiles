# Claude Code Agent Debugging System

This directory contains a comprehensive logging system for debugging Claude Code sub-agents and their interactions. The system captures the complete flow of agent communications, tool calls, and responses to provide deep visibility into how sub-agents operate.

## System Overview

This logging system addresses a critical debugging need: when Claude Code orchestrates sub-agents (like `git-rebase-resolver`), the sub-agent's internal operations are not visible in the main session. This system uses Claude Code's hooks feature to capture all agent interactions and organize them into readable, session-based logs.

### How It Works

1. **Hooks Configuration**: Claude Code settings.json includes hooks that trigger on various events
2. **Session Tracking**: Each Claude session gets a unique ID and date-based directory
3. **Agent Hierarchy**: Logs distinguish between main agent actions and sub-agent operations
4. **Tool Call Capture**: Complete tool inputs, outputs, and sub-agent prompts are logged
5. **Thread Safety**: File locking ensures multiple concurrent Claude instances don't conflict

## Quick Start

### View Recent Activity
```bash
# Show overview of recent sessions
~/.claude/hooks/view-logs.sh

# View logs from a specific session
~/.claude/hooks/view-logs.sh session_abc123

# Filter by agent type (e.g., git-rebase-resolver)
~/.claude/hooks/view-logs.sh -a git-rebase-resolver

# Follow a session in real-time
~/.claude/hooks/view-logs.sh -f session_abc123
```

### Manage Log Files
```bash
# Show disk usage statistics
~/.claude/hooks/cleanup-logs.sh --stats

# Clean up old logs (dry run first)
~/.claude/hooks/cleanup-logs.sh -n
~/.claude/hooks/cleanup-logs.sh
```

### Test the System
```bash
# Verify everything is working
~/.claude/hooks/test-logging.sh
```

## File Components

### `agent-logger.py` (Core Logging Engine)
Python script that processes hook events and creates structured logs.

**Key Features:**
- Session-based organization with unique IDs
- Agent hierarchy tracking (main → sub-agent)
- Complete tool call and response capture
- Thread-safe file operations with locking
- Automatic log rotation for large files
- Robust error handling that never blocks Claude

**Hook Events It Handles:**
- `PreToolUse`: Captures tool calls before execution (including sub-agent prompts)
- `PostToolUse`: Captures tool outputs after completion
- `SubagentStop`: Records when sub-agents finish their work
- `UserPromptSubmit`: Logs initial user requests
- `Stop`: Records main agent completion

### `view-logs.sh` (Log Viewer)
Interactive script for browsing and analyzing logs with syntax highlighting and filtering.

**Usage Examples:**
```bash
# Show recent sessions overview
./view-logs.sh

# View specific session
./view-logs.sh session_abc123

# Filter by agent type
./view-logs.sh -a git-rebase-resolver

# Follow session in real-time
./view-logs.sh -f session_abc123

# Show Task tool usage in last 10 sessions
./view-logs.sh -T Task -r 10

# List all available sessions
./view-logs.sh -l

# Show session metadata
./view-logs.sh -m session_abc123

# Verbose output with raw input data
./view-logs.sh -v session_abc123
```

### `cleanup-logs.sh` (Maintenance)
Automated log maintenance with archiving, compression, and disk space management.

**Usage Examples:**
```bash
# Run with default settings (7 day retention)
./cleanup-logs.sh

# Dry run to see what would be cleaned
./cleanup-logs.sh -n

# Keep logs for 14 days instead of 7
./cleanup-logs.sh -r 14

# Show current disk usage statistics
./cleanup-logs.sh --stats

# Force cleanup without confirmation
./cleanup-logs.sh -f

# Custom size limits
./cleanup-logs.sh -s 100 -t 2  # 100MB per file, 2GB total
```

### `test-logging.sh` (System Verification)
Test script that verifies all components are working correctly.

**What It Tests:**
- Logger script execution and permissions
- Log file creation and structure
- Metadata generation
- Log viewer functionality  
- Cleanup script operation

## Log Directory Structure

```
~/.claude/logs/sessions/
├── 2025-08-21/                   # Date-based organization
│   ├── session_abc123/           # Unique session directory
│   │   ├── main.log             # Primary agent actions and tool calls
│   │   ├── agent_git-rebase-resolver.log  # Sub-agent specific operations
│   │   ├── metadata.json        # Session metadata (agents used, tools called, timing)
│   │   └── errors.log           # Error log (created only if errors occur)
│   └── session_def456/
│       ├── main.log
│       ├── agent_general-purpose.log
│       └── metadata.json
└── archive/                      # Compressed old sessions (managed by cleanup)
    ├── 2025-08-20_session_old1.tar.gz
    └── 2025-08-19_session_old2.tar.gz
```

## Configuration Details

### Hooks Configuration in `~/.claude/settings.json`

The system relies on five hook types configured in your Claude Code settings:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Task",           // Captures sub-agent invocations
        "hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/agent-logger.py"}]
      },
      {
        "matcher": ".*",             // Captures all other tool calls
        "hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/agent-logger.py"}]
      }
    ],
    "PostToolUse": [               // Captures tool outputs
      {
        "matcher": "Task",
        "hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/agent-logger.py"}]
      }
    ],
    "SubagentStop": [              // Records sub-agent completion
      {
        "matcher": ".*",
        "hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/agent-logger.py"}]
      }
    ],
    "UserPromptSubmit": [          // Logs user inputs
      {
        "matcher": ".*",
        "hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/agent-logger.py"}]
      }
    ],
    "Stop": [                      // Records session completion
      {
        "matcher": ".*",
        "hooks": [{"type": "command", "command": "python3 ~/.claude/hooks/agent-logger.py"}]
      }
    ]
  }
}
```

### Environment Variables

**For cleanup script behavior:**
- `CLAUDE_LOG_RETENTION_DAYS`: Days to keep logs (default: 7)
- `CLAUDE_LOG_MAX_SIZE_MB`: Max size per log file in MB (default: 50)
- `CLAUDE_LOG_MAX_TOTAL_SIZE_GB`: Max total size in GB (default: 1)
- `CLAUDE_LOG_COMPRESS_AFTER_DAYS`: Compress logs after N days (default: 2)

**For enhanced logging:**
- `CLAUDE_DEBUG_VERBOSE`: Include raw hook input data in logs (useful for debugging the logging system itself)

## Understanding Log Entries

### Example Log Entry Structure

```
================================================================================
TIMESTAMP: 2025-08-21 17:53:33.118-0500
HOOK_TYPE: PreToolUse
SESSION_ID: session_abc123
WORKING_DIR: /path/to/working/directory
TOOL: Task
SUB_AGENT: git-rebase-resolver
TASK_DESC: Rebase feature branch onto main
AGENT_PROMPT:
----------------------------------------
You are asked to rebase the feature branch 'feature/new-component' 
onto the latest main branch. The working directory is /path/to/repo.
Please handle any conflicts that arise during the rebase process.
----------------------------------------
```

### What Each Field Means

- **TIMESTAMP**: When the hook was triggered (with timezone)
- **HOOK_TYPE**: Which event triggered this log entry
- **SESSION_ID**: Unique identifier for this Claude session
- **WORKING_DIR**: Directory where Claude is operating
- **TOOL**: Which tool was called (Task indicates sub-agent usage)
- **SUB_AGENT**: Type of sub-agent being invoked
- **TASK_DESC**: Brief description of the task
- **AGENT_PROMPT**: Complete prompt sent to the sub-agent

### Log File Types

- **`main.log`**: All primary agent actions and non-Task tool calls
- **`agent_[type].log`**: Specific to sub-agent type (e.g., `agent_git-rebase-resolver.log`)
- **`metadata.json`**: Session summary with agents used, tools called, timing
- **`errors.log`**: Only created if the logging system itself encounters errors

## Typical Debugging Workflow

### 1. Identify the Session
```bash
# Find recent sessions that used a specific agent
~/.claude/hooks/view-logs.sh -a git-rebase-resolver -r 10
```

### 2. Examine Agent Communication
```bash
# View the complete session to see main → sub-agent flow
~/.claude/hooks/view-logs.sh session_abc123
```

### 3. Focus on Specific Issues
```bash
# Filter for Tool calls to see sub-agent invocations
~/.claude/hooks/view-logs.sh -T Task session_abc123

# Follow a live session if debugging in real-time
~/.claude/hooks/view-logs.sh -f session_abc123
```

### 4. Analyze Agent Behavior
Look for these key elements in the logs:
- **Sub-agent prompts**: What instructions were given?
- **Tool sequences**: What tools did the agent use and in what order?
- **Error patterns**: Did the agent encounter specific failures repeatedly?
- **Context passing**: How much context was passed between main and sub-agent?

## Troubleshooting the Logging System

### Problem: Logs Not Appearing
**Symptoms**: No log files created despite using sub-agents
**Solutions**:
1. Check hooks configuration: `cat ~/.claude/settings.json | jq .hooks`
2. Verify logger permissions: `ls -la ~/.claude/hooks/agent-logger.py`
3. Test manually: `~/.claude/hooks/test-logging.sh`

### Problem: Permission Errors
**Symptoms**: Hook execution fails or logs can't be written
**Solutions**:
```bash
chmod +x ~/.claude/hooks/*.sh ~/.claude/hooks/*.py
mkdir -p ~/.claude/logs/sessions
```

### Problem: Large Log Files
**Symptoms**: Disk space issues or slow log viewing
**Solutions**:
```bash
# Check current usage
~/.claude/hooks/cleanup-logs.sh --stats

# Clean up old logs
~/.claude/hooks/cleanup-logs.sh

# Adjust retention settings
~/.claude/hooks/cleanup-logs.sh -r 3  # Keep only 3 days
```

### Problem: Concurrent Session Issues
**Symptoms**: Garbled logs or missing entries when running multiple Claude instances
**Solutions**: The system uses file locking, but check:
```bash
# Look for lock conflicts in error logs
find ~/.claude/logs -name "errors.log" -exec cat {} \;
```

### Problem: Missing Agent-Specific Logs
**Symptoms**: Only main.log exists, no agent_[type].log files
**Cause**: This indicates the Task tool isn't being properly captured or sub-agents aren't being used
**Solutions**:
1. Verify you're actually triggering sub-agents (check if Task tool appears in main.log)
2. Check PreToolUse hooks are configured for Task matcher

## Maintenance Best Practices

### Regular Cleanup
```bash
# Add to crontab for automated daily cleanup at 2 AM
0 2 * * * ~/.claude/hooks/cleanup-logs.sh -f

# Or run weekly with longer retention
0 2 * * 0 ~/.claude/hooks/cleanup-logs.sh -r 14 -f
```

### Monitoring Disk Usage
```bash
# Check usage weekly
~/.claude/hooks/cleanup-logs.sh --stats

# Set up alerts if usage exceeds limits
# (integrate with your monitoring system as needed)
```

### Log Rotation Strategy
The system automatically:
1. Rotates individual log files when they exceed size limits
2. Compresses logs after the configured age
3. Archives entire sessions after retention period
4. Removes archives when total size limits are exceeded

## Integration with Your Workflow

### Chezmoi Integration
When making changes to the hooks system, commit them to your dotfiles:

```bash
chezmoi add ~/.claude/hooks/
chezmoi add ~/.claude/settings.json
chezmoi commit -m "Update Claude Code agent debugging system"
chezmoi push
```

### Git Integration
The logs can help debug git-related agent operations:
```bash
# Find sessions where git operations failed
~/.claude/hooks/view-logs.sh -T Bash | grep -i "git\|error"

# Review git-rebase-resolver sessions
~/.claude/hooks/view-logs.sh -a git-rebase-resolver
```

### Development Workflow Integration
- Review logs after complex agent operations to understand decision-making
- Use real-time following during development of new agents
- Archive successful session logs as examples for future reference
- Analyze failed sessions to improve agent prompts and error handling

## Understanding Agent Communication Flow

When you trigger a sub-agent like `git-rebase-resolver`, this is what gets logged:

1. **UserPromptSubmit**: Your initial request
2. **PreToolUse (Task)**: Claude deciding to use a sub-agent, including the complete prompt
3. **PostToolUse (Task)**: Sub-agent's response and any outputs
4. **PreToolUse (other tools)**: Individual tools the sub-agent uses (Bash, Edit, etc.)
5. **PostToolUse (other tools)**: Results of those tool calls
6. **SubagentStop**: Sub-agent completing its work
7. **Stop**: Main agent finishing the overall task

This creates a complete audit trail of the entire operation, allowing you to see not just what happened, but why each decision was made and how information flowed between agents.