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
- `status` = "stopped"

**Why SessionStart sets status="stopped"**: Most Claude sessions start by awaiting the user's first prompt. Setting status to "stopped" at SessionStart correctly reflects this typical state.

**Known Edge Case**: When passing an initial prompt to the `claude` command (e.g., `claude "explain this code"`), Claude immediately begins processing without awaiting input. In this case, status will briefly show "stopped" until the first Stop hook fires. This is a rare use case and the brief incorrect state is acceptable. A future refinement could detect the presence of an initial prompt argument, but this adds complexity for minimal benefit.

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

## Hook Implementation Details

### Pane Targeting with $TMUX_PANE

All hooks use `tmux set-option -pt "$TMUX_PANE"` to ensure metadata is set on the **pane where Claude is running**, not the currently focused pane.

- **`-p`**: Explicitly declares this is a pane option (not window/session/server)
- **`-t "$TMUX_PANE"`**: Targets the specific pane where the hook process executes

The `$TMUX_PANE` environment variable contains the pane ID (e.g., `%26`) where the hook process is running, guaranteeing correct pane targeting even when the user switches focus during Claude's execution.

**Why this matters**: Without `$TMUX_PANE` targeting, if you switch focus from the Claude pane to another pane before a hook fires, the metadata would be set on the wrong pane. This causes metadata cross-contamination where multiple panes incorrectly show the same Claude session information.

**Example of the problem**:
- Start Claude in pane %26
- Switch focus to pane %39
- Claude finishes and Stop hook fires
- Without `$TMUX_PANE`: metadata incorrectly set on %39 (currently focused)
- With `$TMUX_PANE`: metadata correctly set on %26 (where Claude runs)

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
