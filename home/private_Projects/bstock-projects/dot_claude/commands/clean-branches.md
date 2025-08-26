# /clean-branches

Identifies and cleans up stale local git branches across B-Stock projects by correlating with GitLab merge requests, Jira tickets, and branch activity patterns.

## Usage

Run from any B-Stock project directory:
- **Single project**: Analyzes current project only
- **All projects**: Analyzes all git repos in bstock-projects/

## Strategy

1. **Auto-Delete** (no user prompt):
   - GitLab MR merged + SHA match + remote branch deleted + >7 days old
   - Branch >6 months behind main + no commits in 3+ months + no associated MR
   
2. **Probable Deletion Candidates** (batch confirmation):
   - GitLab MR closed/merged but recent or SHA mismatch
   - Associated Jira ticket closed but branch activity unclear
   
3. **Review Required** (individual assessment):
   - Recent activity but significantly behind main  
   - No clear MR or Jira association
   - Unusual patterns requiring context

## Implementation

Use the Task tool to efficiently research branches in parallel across all target projects, then consolidate findings into actionable categories with detailed reporting.

---

You are helping a professional software engineer clean up stale local git branches across B-Stock projects. This requires careful analysis to avoid deleting important work while efficiently removing branches that have been merged or are no longer needed.

**IMPORTANT**: You MUST use the TodoWrite tool to track your progress through this multi-step process.

## Step 1: Project Discovery and Branch Analysis

First, determine the scope:
- If we're in a B-Stock project directory, ask if user wants to analyze just this project or all B-Stock projects
- If analyzing all projects, discover all git repositories in `/Users/mike/Projects/bstock-projects/`

For each target project, use the Task tool to research branches in parallel:

### Task Parameters for Branch Research:
```
subagent_type: general-purpose
description: Analyze branches for [project-name]
prompt: Research all local branches in this git project for cleanup analysis.

Tasks to complete:
1. **Identify all local branches** (excluding main/master)
2. **Get branch metadata**: last commit date, SHA, commits behind main, commit count
3. **GitLab MR correlation**: 
   - Use GitLab MCP tools to find MRs by author (mike.greiling) 
   - Match source_branch names with local branches
   - Get diff_refs.head_sha, state (merged/closed), merged_at dates
   - Verify remote branch deletion status with git ls-remote
4. **Jira ticket analysis**:
   - Extract ticket IDs from branch names (e.g., SPR-1234 from mg-SPR-1234-description)
   - Check ticket status using Atlassian MCP tools if ticket ID found
5. **Staleness assessment**:
   - Calculate days since last commit
   - Calculate commits behind main branch
   - Identify obviously stale branches (>6 months old, >100 commits behind, no activity)

Return structured data:
- branches_for_auto_deletion: [list with SHA, reason, MR links]
- branches_needing_confirmation: [list with analysis and recommendation]
- branches_needing_review: [list with context for manual decision]
- project_summary: brief overview of findings

Context: This is for cleaning up local branches safely. The user is 'Mike Greiling' (GitLab username: mike.greiling, ID: 421). Focus on providing confident recommendations based on concrete evidence.
```

## Step 2: Consolidate Research Results

After all Task agents complete their research, consolidate the results:

1. **Auto-Deletion Candidates**: Branches with definitive evidence they're safe to delete
2. **Probable Deletions**: Branches likely safe to delete but needing confirmation  
3. **Manual Review**: Branches requiring individual assessment with context

## Step 3: Present Findings and Execute Cleanup

### Auto-Delete Report
Show branches that will be automatically deleted:
```
📋 AUTO-DELETE (X branches)
─────────────────────────────
✅ project-name/branch-name
   SHA: abc123def... 
   Reason: Merged via project!1234 on 2025-07-15, remote deleted
   
✅ project-name/stale-branch  
   SHA: def456abc...
   Reason: >6 months old, 200 commits behind, no activity since 2024-12-01
```

### Probable Deletions (get user confirmation)
Present batch confirmation for likely candidates:
```
⚠️  PROBABLE DELETIONS (Y branches) - Confirm batch delete? [y/N]
─────────────────────────────────────────────────────────────────
• project-name/feature-branch (SHA: ghi789...)
  Analysis: MR closed but recent activity, might have local changes
  
• project-name/experiment-branch (SHA: jkl012...)  
  Analysis: Associated Jira ticket SPR-1234 is Done, but branch very recent
```

### Manual Review Required  
Present individual branches needing decisions:
```
❓ MANUAL REVIEW (Z branches)
────────────────────────────
🤔 project-name/complex-feature (SHA: mno345...)
   Last commit: 3 days ago | 45 commits behind main | No associated MR found
   Recent commits: "WIP: refactor authentication", "fix tests", "add validation"
   Recommendation: Active work, consider rebasing
   Actions: [Delete] [Keep] [Rebase onto main]

🤔 project-name/old-experiment (SHA: pqr678...)  
   Last commit: 2 months ago | 120 commits behind main | No MR/Jira links
   Recent commits: "trying new approach", "temp fix", "debugging"  
   Recommendation: Likely experimental, probably safe to delete
   Actions: [Delete] [Keep] [Archive as patch]
```

## Step 4: Execute Approved Deletions

For each deletion category:
1. **Auto-deletions**: Delete immediately, log results
2. **Confirmed batch deletions**: Delete after user confirms  
3. **Individual deletions**: Delete after user approves each one
4. **Rebase operations**: Offer to rebase kept branches onto latest main

## Step 5: Generate Final Report

Provide a comprehensive summary:
```
🧹 BRANCH CLEANUP REPORT
═══════════════════════

📊 SUMMARY:
• Projects analyzed: X
• Total branches found: Y  
• Auto-deleted: Z branches
• User-deleted: A branches
• Kept for review: B branches
• Rebased: C branches

📋 DELETED BRANCHES:
[Detailed list with SHAs and reasons]

🔄 RECOMMENDED NEXT STEPS:
[Suggestions for remaining branches, rebase recommendations, etc.]
```

## Error Handling

- Handle missing GitLab/Jira MCP tools gracefully
- Warn if git commands fail (permissions, corrupted repos, etc.)  
- Skip projects that aren't git repositories
- Provide fallback analysis if API tools aren't available

## Safety Measures

- Never delete main/master branches
- Always show SHA before deletion for recovery purposes
- Require explicit user confirmation for uncertain cases
- Log all deletions for potential recovery
- Warn about uncommitted changes before deletion

Remember: This tool should save time while being extremely safe. When in doubt, ask the user rather than making assumptions.