# /clean-branches

Intelligently identifies and cleans up stale local git branches by analyzing merge status, activity patterns, and GitLab correlation using parallel branch analysis agents.

## Usage

```bash
/clean-branches [project-directory]
```

**Arguments:**
- `project-directory` (optional): Path to git repository to analyze. If not provided, uses current working directory.

**Examples:**
```bash
/clean-branches                                       # Analyze branches in current directory
/clean-branches ~/Projects/bstock-projects/cs-portal  # Analyze specific project
/clean-branches .                                     # Explicit current directory
```

## Strategy

### 1. Environment Validation
- Verify target directory is a valid git repository
- Fail fast if no git repository detected (never guess or assume)
- Check for required tools (analysis script, agents)

### 2. Repository Preparation  
- Fetch latest changes from origin with prune
- Discover all local branches
- Identify currently checked out branch

### 3. Complete Branch Analysis (Phase 1)
- **PARALLEL EXECUTION**: Use multiple git-branch-cleanup agent calls in a SINGLE MESSAGE for all non-default branches
- **EXCLUDE DEFAULT BRANCHES**: NEVER analyze main/master branches - they are protected and never deleted
- Provide each parallel agent with only one branch to analyze
- This agent will gather comprehensive analysis including:
  - Merge evidence and GitLab MR correlation
  - Activity patterns and staleness indicators  
  - Risk assessment and safety factors
- Categorize branches: SAFE-DELETE, PROBABLE-DELETE, MANUAL-REVIEW
- **CRITICAL**: Complete analysis of ALL non-default branches before proceeding to Phase 2
- **PARALLEL TOOL CALLS**: Execute all branch analyses using multiple tool calls within a single Claude response message
- Do NOT delete any branches during this phase

### 4. Execute Deletions (Phase 2)
- **SAFE-DELETE branches**: Delete using `~/.claude/scripts/delete-branches.sh branch1 branch2 ...`
- Pass ALL SAFE-DELETE branches to the script in a single command
- **Current Branch Handling**: Special logic for currently checked out branch
  - Verify clean working directory or handle uncommitted changes
  - Switch to main/master before deletion
  - Warn if switching would lose uncommitted work

### 5. Comprehensive Report (Phase 3)
- Present detailed multi-line format for ALL analyzed branches
- Use key:value format with clear sections for each category
- Include specific analysis for remaining MANUAL-REVIEW branches
- Use text output only - NEVER use bash commands for report generation

## Safety Features

### Pre-Execution Validation
- ✅ Require explicit git repository (no guessing)
- ✅ Verify clean working directory for current branch deletion
- ✅ Check for uncommitted changes that could be lost
- ✅ Validate required tools are available

### During Execution
- ✅ Log all deleted branch SHAs for recovery
- ✅ Conservative decision making with clear evidence requirements
- ✅ Special handling for protected branches (main/master)
- ✅ Graceful handling of current branch deletion

### Recovery Support
- ✅ Generate recovery commands for all deleted branches
- ✅ Store recovery log with timestamps and reasoning
- ✅ Provide immediate recovery instructions if needed

## Implementation

### Critical Requirements
- **Phase Separation**: Complete ALL non-default branch analysis before ANY deletions
- **Parallel Analysis**: Use multiple Task tool calls in a single message for true parallel execution
- **Single Deletion Command**: Use `~/.claude/scripts/delete-branches.sh` for all deletions
- **NO BASH FOR REPORTS**: NEVER use bash commands, multi-line scripts, or command output for report generation. The final report must be pure text output from Claude, not bash-generated content that gets truncated.
- **Avoid Complex Grep**: Use simple `git branch` and filter branches programmatically in analysis logic rather than using grep with regex alternation patterns that trigger manual approval
- **Comprehensive Detail**: Every non-default branch must be listed with full analysis
- **Default Branch Exclusion**: NEVER analyze or attempt to delete main/master branches
- **Terminology**: Use "SAFE-DELETE" not "AUTO-DELETE"
- **Working Directory Management**: Bash `cd` commands persist between tool calls - avoid redundant directory changes

### CRITICAL: Report Generation Rules
- ❌ FORBIDDEN: Multi-line bash scripts for formatting or generating reports
- ❌ FORBIDDEN: Using bash command output as the primary report (user cannot see truncated output)
- ❌ FORBIDDEN: Complex bash functions or heredocs for report generation
- ✅ REQUIRED: Pure text output from Claude with all branch details
- ✅ REQUIRED: Multi-line key:value format for readability

### Working Directory Management

**CRITICAL REMINDER**: Bash tool calls maintain working directory state between commands. The `cd` command persists across separate Bash invocations.

**Anti-Pattern to Avoid**:
```bash
# First command (changes to project directory)
cd project-name && git fetch --prune

# Second command (fails - already in project-name!)  
cd project-name && git branch --list
# Error: no such file or directory: project-name
```

**Two Solution Strategies**:

**Strategy A - Absolute Paths** (Recommended for multi-project workflows):
```bash
cd /full/path/to/project && git fetch --prune
cd /full/path/to/project && git branch --list
```

**Strategy B - Directory Awareness** (Recommended for single-project cleanup):
```bash
# Initial directory change
cd project-name && git fetch --prune

# Subsequent commands work in established directory
git branch --list && git branch --show-current
```

**Implementation Guidance**:
- Use `pwd` to verify current working directory when uncertain
- Avoid repeating `cd PROJECT_NAME` commands in sequence
- Consider absolute paths when working across multiple repositories

### Tools Used
This command leverages:
- **Analysis Script**: `~/.claude/scripts/analyze-git-branch.sh` for comprehensive branch data
- **Cleanup Agent**: `git-branch-cleanup` for parallel analysis and intelligent categorization
- **Deletion Script**: `~/.claude/scripts/delete-branches.sh` for safe branch deletion with logging
- **GitLab MCP Tools**: For merge request correlation and verification
- **Project Context**: Reads CLAUDE.md for project-specific configuration

## Output Format

```
🧹 GIT BRANCH CLEANUP REPORT

📊 ANALYSIS SUMMARY:
• Repository: /path/to/project
• Branches analyzed: 25  
• Safe-deleted: 8 branches
• Manual review required: 17 branches

### ✅ SAFE-DELETE Branches (8 deleted)

**mg-old-feature**
- Category: SAFE-DELETE (HIGH confidence)
- Merge Status: MERGED
- GitLab MR: !567
- Last Activity: 2025-07-15 (30 days ago)
- Action: ✅ DELETED
- Reasoning: Clear merge evidence, MR merged successfully

**mg-SPR-1234-fix**
- Category: SAFE-DELETE (HIGH confidence)
- Merge Status: MERGED
- GitLab MR: !456
- Last Activity: 2025-06-01 (60 days ago)
- Action: ✅ DELETED
- Reasoning: Feature complete, remote branch deleted

### ⏳ MANUAL-REVIEW Required (17 remaining branches)

**mg-current-work**
- Category: MANUAL-REVIEW
- Status: Recent activity, unclear merge status - requires investigation

🛡️ RECOVERY INFORMATION:
- Recovery Log: ~/.claude/logs/clean-branch-log.txt
- All deleted branch SHAs preserved for emergency restoration
- Use format: git checkout -b branch-name-recovery <SHA>
```

## Error Handling

### Validation Failures
- **Not a git repository**: Clear error message, exit immediately
- **No project directory specified + CWD not git**: Explicit failure with usage instructions
- **Uncommitted changes on current branch**: Warn and provide options
- **Missing required tools**: Check for script and agent availability

### Runtime Issues
- **Git command failures**: Graceful degradation with clear error messages
- **Agent execution problems**: Fallback to basic analysis where possible
- **Network connectivity issues**: Continue with offline-only analysis
- **Permission issues**: Clear instructions for resolution

### Recovery Scenarios
- **Accidental deletion**: Immediate recovery commands provided
- **Incomplete cleanup**: Resume capability with state preservation
- **Analysis errors**: Detailed logs for troubleshooting

Remember: This is a powerful tool that permanently deletes branches. The implementation prioritizes safety, transparency, and recoverability while providing efficient cleanup of stale branches.