# Claude Code Hook Design for Tmux Integration

## Metadata User Options

Claude Code sessions store tmux pane user options under the `@meta.claude.*` namespace:

### Session Tracking
- `@meta.claude.session_id` - The Claude session UUID
- `@meta.claude.session_id_set_on` - Which hook last set/updated the session_id
- `@meta.claude.session_dir` - Project directory where session was started (set ONLY in SessionStart)

### State Management
- `@meta.claude.status` - Current session status: "running" | "stopped"

### Debug Tracking
- `@meta.claude.latest_hook_event` - Most recent hook that fired (e.g., "Stop", "Notification-permission_prompt")
- `@meta.claude.latest_hook_time` - Unix timestamp of most recent hook

## Hook Behavior

### Operational Hooks (State-Changing)

#### SessionStart
**Sets:** session_id, session_id_set_on, session_dir, status, latest_hook_event, latest_hook_time

- `session_id` = current session UUID
- `session_id_set_on` = "SessionStart"
- `session_dir` = `cwd` from hook payload **← ONLY PLACE THIS IS SET**
- `status` = "stopped"
- `latest_hook_event` = "SessionStart"
- `latest_hook_time` = unix timestamp

**Why SessionStart sets status="stopped"**: Most Claude sessions start awaiting the user's first prompt.

**Why session_dir is set ONLY here**: We want the original project directory, not the current working directory which may change during the session (e.g., via `cd` commands).

**Known Edge Case**: When passing an initial prompt to `claude` (e.g., `claude "explain this code"`), Claude immediately processes without awaiting input. Status will briefly show "stopped" until UserPromptSubmit fires.

#### Stop
**Sets:** session_id, session_id_set_on, status, latest_hook_event, latest_hook_time

- `session_id` = current session UUID
- `session_id_set_on` = "Stop"
- `status` = "stopped"
- `latest_hook_event` = "Stop"
- `latest_hook_time` = unix timestamp

**Why Stop sets session_id**: When resuming with `claude --resume`, SessionStart receives an INCORRECT session_id. Stop corrects this.

**Waiting State**: Stop indicates Claude finished responding and is awaiting user input.

#### UserPromptSubmit
**Sets:** session_id, session_id_set_on, status, latest_hook_event, latest_hook_time

- `session_id` = current session UUID
- `session_id_set_on` = "UserPromptSubmit"
- `status` = "running" **← State Recovery**
- `latest_hook_event` = "UserPromptSubmit"
- `latest_hook_time` = unix timestamp

**State Recovery**: This hook recovers from any "waiting" states (permission_prompt, elicitation_dialog, idle_prompt).

#### SessionEnd
**Sets:** session_id, session_id_set_on, latest_hook_event, latest_hook_time
**Removes:** status

- `session_id` = current session UUID (final fail-safe)
- `session_id_set_on` = "SessionEnd"
- Removes `status`
- `latest_hook_event` = "SessionEnd"
- `latest_hook_time` = unix timestamp

**Why SessionEnd SETS session_id**: Final fail-safe for `claude --resume` followed by immediate exit.

#### PostToolUse
**Sets:** status, latest_hook_event, latest_hook_time

- `status` = "running" **← State Recovery**
- `latest_hook_event` = "PostToolUse"
- `latest_hook_time` = unix timestamp

**State Recovery**: This hook recovers from "waiting" states triggered by Notification hook (permission_prompt, etc).

#### Notification (with notification_type parsing)
**Sets:** Conditional on notification_type

**Parsing Logic:**
1. Extract `notification_type` from JSON payload
2. If type is `permission_prompt`, `elicitation_dialog`, or `idle_prompt`:
   - Set `status` = "stopped" (waiting for user)
   - Set `latest_hook_event` = "Notification-<type>" (e.g., "Notification-permission_prompt")
3. For all other types (e.g., `auth_success`):
   - Only set `latest_hook_event` = "Notification-<type>"
   - Do NOT change status

**Waiting States:**
- `permission_prompt` - Waiting for tool approval
- `elicitation_dialog` - Waiting for MCP tool input
- `idle_prompt` - User away for 60+ seconds

**Informational Types:**
- `auth_success` - Authentication succeeded (no waiting)
- Others - Various notifications (no status change)

### Debug-Only Hooks (No State Change)

#### PreToolUse
**Sets:** latest_hook_event, latest_hook_time

- `latest_hook_event` = "PreToolUse"
- `latest_hook_time` = unix timestamp

**Why NO status change**: PreToolUse fires for ALL tools, including whitelisted ones that execute automatically. Only Notification (permission_prompt) indicates actual waiting.

#### SubagentStop
**Sets:** session_id, session_id_set_on, latest_hook_event, latest_hook_time

- `session_id` = current session UUID
- `session_id_set_on` = "SubagentStop"
- `latest_hook_event` = "SubagentStop"
- `latest_hook_time` = unix timestamp

**Why NO status change**: When a subagent (Task tool) completes, the main agent continues processing its response. User is NOT waiting.

#### PreCompact
**Sets:** latest_hook_event, latest_hook_time

- `latest_hook_event` = "PreCompact"
- `latest_hook_time` = unix timestamp

**Purpose**: Tracks conversation compaction events (auto or manual `/compact`).

## Hook Implementation Details

### Pane Targeting with $TMUX_PANE

All hooks use `tmux set-option -pt "$TMUX_PANE"` to ensure metadata is set on the **pane where Claude is running**.

- **`-p`**: Pane option (not window/session/server)
- **`-t "$TMUX_PANE"`**: Targets the specific pane where hook executes

**Why this matters**: Without `$TMUX_PANE`, switching focus before a hook fires would set metadata on the wrong pane.

## Tmux Display Logic

### Pane Status Display
Shows session_id (truncated to 8 chars) with status icon:

- `[▶]` - status="running" (Claude actively processing)
- `[⏸]` - status="stopped" (Awaiting user input OR approval OR idle)
- `[■]` - session_id exists but status does NOT (clean exit)
- `[?]` - status has unrecognized value (error state)
- No icon - No Claude session ever ran in this pane

**Unified "Stopped" State**: The pause icon `[⏸]` indicates ANY waiting state:
- Waiting for user prompt (Stop)
- Waiting for tool approval (Notification-permission_prompt)
- Waiting for MCP input (Notification-elicitation_dialog)
- User idle for 60+ seconds (Notification-idle_prompt)

### Window Name Display
Shows pause icon if ANY pane in window has stopped Claude session:

- `(⏸)` - At least one pane has status="stopped"
- No icon - All panes running, exited, or no sessions

## Session Directory Management

### Path Encoding in ~/.claude/projects

Claude encodes project directories with special characters replaced by `-`:

**Encoding Rules:**
- Alphanumeric characters preserved: `a-zA-Z0-9` → same
- All other characters → `-`

**Examples:**
- `/Users/mike/Projects/bstock-projects` → `-Users-mike-Projects-bstock-projects`
- `/Users/mike/.claude/agents` → `-Users-mike--claude-agents`
- `$!@#%^&*()--helloworld!+5_4<>x?.foo` → `-------------helloworld--5-4--x--foo`

### Path Decoding Algorithm (Greedy Pattern Matching)

The `cld` script uses a sophisticated decoder to reverse the lossy encoding:

**Algorithm:**
1. Start at root directory `/`
2. For each subdirectory level:
   - List all subdirectories (including hidden)
   - Match encoded string against each subdirectory name
   - Select longest matching prefix
   - Advance to that subdirectory
3. Continue until entire encoded string consumed

**Matching Logic:**
- Alphanumeric in encoded MUST match alphanumeric in directory exactly
- Dashes in encoded CAN match any non-alphanumeric in directory
- Longest match wins (greedy)

**Example:**
```
Encoded: -------------helloworld--5-4--x--foo
Directory: $!@#%^&*()--helloworld!+5_4<>x?.foo

Match:
  "-------------" matches "$!@#%^&*()--" (13 dashes → 11 special chars + 2 dashes)
  "helloworld" matches "helloworld" exactly
  "--" matches "!+" (2 dashes → 2 special chars)
  "5" matches "5" exactly
  "-" matches "_" (1 dash → 1 special char)
  "4" matches "4" exactly
  "--" matches "<>" (2 dashes → 2 special chars)
  "x" matches "x" exactly
  "--" matches "?." (2 dashes → 2 special chars)
  "foo" matches "foo" exactly
  → SUCCESS!
```

**Optimization**: Before attempting decode, check if current directory matches the encoded form.

### Directory Validation

The `cld` script validates session directories:

1. **Primary**: Use `@meta.claude.session_dir` from tmux metadata (if available)
2. **Fallback**: Decode path from transcript location
3. **Validation**: Cross-check metadata vs decoded path
4. **Mismatch**: Warn user, prompt to proceed with transcript path

## User Interruption Limitation

**Known issue**: Stop hook does NOT fire when users interrupt Claude (Ctrl+C):
- `status` remains "running" until SessionEnd
- SessionEnd cleans up by removing status
- Acceptable since SessionEnd preserves session_id

## cld Script Integration

The `cld` wrapper script provides directory-aware session resumption:

### Features
- `-y` / `--yes`: Auto-accept directory change and resume
- `-n` / `--no`: Auto-deny directory change, use current directory
- Interactive prompts with combined directory + resume questions
- Automatic directory switching before resuming sessions
- Path validation and mismatch detection

### Examples
```bash
# Auto-accept directory change
cld resume -y 23e30f82

# Auto-deny directory change
cld resume -n 23e30f82

# Interactive (default)
cld resume 23e30f82
# → "Resume session 23e30f82 from /path/to/project? [Yn]"
```
