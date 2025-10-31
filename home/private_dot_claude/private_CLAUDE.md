# Claude Code Hook Design for Tmux Integration

## Metadata User Options

Claude Code sessions store three tmux pane user options under the `@meta.claude.*` namespace:

- `@meta.claude.session_id` - The Claude session UUID
- `@meta.claude.session_id_set_on` - Which hook last set/updated the session_id
- `@meta.claude.status` - Current session status: "running" | "stopped"

## Hook Behavior

### SessionStart
Sets all three values:
- `session_id` = current session UUID
- `session_id_set_on` = "SessionStart"
- `status` = "running"

### Stop
Sets all three values:
- `session_id` = current session UUID
- `session_id_set_on` = "Stop"
- `status` = "stopped"

**Why Stop sets session_id**: When resuming sessions with `claude --resume`, the SessionStart hook receives an INCORRECT session_id. The Stop hook corrects this by setting the actual session_id when Claude finishes its response.

### UserPromptSubmit
Sets all three values:
- `session_id` = current session UUID
- `session_id_set_on` = "UserPromptSubmit"
- `status` = "running"

### SessionEnd
Sets session_id and session_id_set_on, removes status:
- `session_id` = current session UUID (SETS it, final fail-safe)
- `session_id_set_on` = "SessionEnd" (indicates clean exit)
- Removes `status` (clears running state)

**Why SessionEnd SETS session_id**:
1. Final fail-safe to capture the correct session UUID
2. Critical for `claude --resume` followed by immediate exit (SessionEnd is the only opportunity to set session_id correctly)
3. The `session_id_set_on` value distinguishes between:
   - **Clean exit**: `session_id_set_on="SessionEnd"` (session terminated normally)
   - **Interrupted exit**: `session_id_set_on="Stop"` or other (session crashed/interrupted)

## Tmux Display Logic

### Pane Status Display
Shows session_id (truncated to 8 chars) with status icon:
- `[▶]` - status="running" (Claude actively processing)
- `[⏸]` - status="stopped" (Claude awaiting user input)
- `[■]` - session_id exists but status does NOT (clean exit, no active session)
- `[?]` - status has unrecognized value (error state)
- No icon - session_id doesn't exist (no Claude session ever ran in this pane)

### Window Name Display
Shows pause icon if ANY pane in window has stopped Claude session:
- `(⏸)` - At least one pane has status="stopped"
- No icon - All panes are running, cleanly exited, or no sessions

## User Interruption Limitation

**Known issue**: The Stop hook does NOT fire when users interrupt Claude mid-execution (e.g., Ctrl+C). In this case:
- `status` remains "running" until SessionEnd fires
- SessionEnd eventually cleans up by removing status and setting session_id_set_on="SessionEnd"
- This is acceptable since SessionEnd provides eventual cleanup and preserves session_id
