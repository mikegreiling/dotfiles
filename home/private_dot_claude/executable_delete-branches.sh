#!/bin/bash

# delete-branches.sh - Safely delete git branches with logging
# Usage: delete-branches.sh branch1 [branch2 ...]

LOGFILE="$HOME/.claude/logs/clean-branch-log.txt"
REPO_PATH=$(pwd)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Ensure log directory exists
mkdir -p "$(dirname "$LOGFILE")"

# Validate we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: delete-branches.sh branch1 [branch2 ...]"
    exit 1
fi

echo "=== Branch Deletion Session ==="
echo "Repository: $REPO_PATH"
echo "Timestamp: $TIMESTAMP"
echo "Log file: $LOGFILE"
echo ""

# Log session header
cat >> "$LOGFILE" << EOF
=== Branch Deletion Session ===
Repository: $REPO_PATH
Timestamp: $TIMESTAMP
EOF

deleted_count=0
failed_count=0

for branch in "$@"; do
    # Get SHA before deletion
    sha=$(git rev-parse "$branch" 2>/dev/null)
    
    if [ -z "$sha" ]; then
        echo "⚠️  Branch '$branch' not found"
        echo "ERROR: Branch '$branch' not found" >> "$LOGFILE"
        ((failed_count++))
        continue
    fi
    
    # Attempt deletion
    if git branch -D "$branch" >/dev/null 2>&1; then
        echo "✅ Deleted: $branch (${sha:0:8})"
        echo "DELETED: $branch $sha" >> "$LOGFILE"
        ((deleted_count++))
    else
        echo "❌ Failed to delete: $branch"
        echo "FAILED: $branch $sha" >> "$LOGFILE"
        ((failed_count++))
    fi
done

# Log session footer
echo "" >> "$LOGFILE"
echo "Session complete: $deleted_count deleted, $failed_count failed" >> "$LOGFILE"
echo "=================================" >> "$LOGFILE"
echo "" >> "$LOGFILE"

echo ""
echo "Summary: $deleted_count branches deleted, $failed_count failed"
echo "Recovery log: $LOGFILE"