# Fresh Start - Project Cleanup

Reset all B-Stock projects to a clean state by checking out main branch, pulling latest changes, and identifying any impediments.

For each project (accounts-portal, cs-portal, seller-portal, home-portal, fe-core, bstock-eslint-config, fe-scripts):

1. Load the project's CLAUDE.md file to understand project-specific context
2. Check current git status including:
   - Current branch
   - Uncommitted changes (staged and unstaged)
   - Untracked files
3. Attempt to checkout main branch and pull latest changes
4. Report any impediments found:
   - Uncommitted changes that would be lost
   - Untracked files that might conflict
   - Merge conflicts or other git issues
   - Permission or connectivity issues

If impediments are found, list them clearly and ask for guidance before proceeding with cleanup.

This command ensures a clean slate before starting new development work.
