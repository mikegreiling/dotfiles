#!/bin/bash

# Claude Code Transcript Parser
# 
# PURPOSE:
# Extracts user prompts from Claude Code transcript JSONL files to find JIRA ticket
# references for statusline display. Focuses on actual user-authored content rather
# than tool outputs or system messages.
#
# TRANSCRIPT SCHEMA NOTES:
# Claude Code transcripts are JSONL files where each line is a JSON object.
# User messages have the structure:
#   {
#     "type": "user",
#     "message": {
#       "role": "user", 
#       "content": <STRING_OR_ARRAY>
#     }
#   }
#
# CONTENT FORMAT VARIATIONS:
# 1. Simple string format: "content": "user message text here"
# 2. Array format: "content": [{"type": "text", "text": "user message text"}]
#    - Array may contain multiple objects with different types
#    - We only extract objects where type === "text"
#
# FILTERING LOGIC:
# - Skip empty/whitespace-only content
# - Skip tool results (patterns like "tool_result", "tool_use_result") 
# - Skip system messages ("[Request interrupted", "Caveat: The messages below")
# - Skip command outputs ("<local-command", "<command-", "(no content)")
#
# OUTPUT FORMAT:
# - Individual user messages with timestamps and extracted JIRA patterns
# - Frequency-ranked summary of all JIRA patterns found
# - Git branch comparison for fallback JIRA detection

transcript_file="$1"

if [[ ! -f "$transcript_file" ]]; then
    echo "Usage: $0 <transcript_file>"
    echo "Example: $0 /Users/mike/.claude/projects/project-dir/session-uuid.jsonl"
    exit 1
fi

echo "=== CLAUDE CODE TRANSCRIPT PARSER ==="
echo "File: $transcript_file"
echo "Parsing user prompts..."
echo "======================================="

# Counter for meaningful user messages found
counter=0

# Parse each line as JSON and extract user messages
while IFS= read -r line; do
    # Skip empty lines (common in JSONL files)
    [[ -z "$line" ]] && continue
    
    # Check if this line represents a user message
    # Uses jq to safely parse JSON and filter for type === "user"
    if echo "$line" | jq -e 'select(.type == "user")' >/dev/null 2>&1; then
        
        # Extract text content - handle both string and array content formats
        all_text=""
        
        # CASE 1: Simple string format
        # Example: "content": "user message text"
        if echo "$line" | jq -e '.message.content | type == "string"' >/dev/null 2>&1; then
            all_text=$(echo "$line" | jq -r '.message.content' 2>/dev/null)
            
        # CASE 2: Complex array format  
        # Example: "content": [{"type": "text", "text": "user message"}, {...}]
        elif echo "$line" | jq -e '.message.content | type == "array"' >/dev/null 2>&1; then
            # Extract all text-type objects and join with spaces
            all_text=$(echo "$line" | jq -r '
                .message.content[]? 
                | select(.type == "text") 
                | .text
            ' 2>/dev/null | tr '\n' ' ')
        fi
        
        # FILTERING: Skip meaningless content
        
        # Skip if no text content or only whitespace
        if [[ -z "$all_text" ]] || [[ "$all_text" =~ ^\s*$ ]]; then
            continue
        fi
        
        # Skip tool results and system messages using regex patterns
        # Patterns explained:
        # - ^[\<\[]?tool_(use_)?result: Tool execution results
        # - ^\[Request\ interrupted: User interruption messages  
        # - ^Caveat:.*local\ commands: Local command output warnings
        # - ^\<(local-command|command-): Command execution metadata
        # - ^\(no\ content\)$: Empty command outputs
        if [[ "$all_text" =~ ^[\<\[]?tool_(use_)?result|^\[Request\ interrupted|^Caveat:.*local\ commands|^\<(local-command|command-).*\>|^\(no\ content\)$ ]]; then
            continue
        fi
        
        # This is a meaningful user message - process it
        counter=$((counter + 1))
        
        # Extract timestamp for context
        timestamp=$(echo "$line" | jq -r '.timestamp // "no-timestamp"')
        
        echo "--- USER MESSAGE #$counter ---"
        echo "Timestamp: $timestamp"
        echo "Content:"
        echo "$all_text"
        echo ""
        
        # Search for JIRA patterns in the extracted text
        # JIRA pattern: PROJECT-NUMBER where PROJECT is 2-4 letters from B-Stock teams
        # Examples: SPR-1234, MULA-567, TBD-89, ZRO-4321, WRH-999, GLOB-123, BUGS-456
        echo "JIRA patterns found:"
        jira_patterns=$(echo "$all_text" | grep -oE "(SPR|MULA|TBD|ZRO|WRH|GLOB|BUGS)-[0-9]{1,5}" | sort -u)
        if [[ -n "$jira_patterns" ]]; then
            echo "$jira_patterns" | while read -r pattern; do
                echo "  -> $pattern"
            done
        else
            echo "  (none)"
        fi
        
        echo "======================================="
        echo ""
    fi
done < "$transcript_file"

echo "=== SUMMARY ==="
echo "Total meaningful user messages found: $counter"

# FREQUENCY ANALYSIS: Count occurrences of each JIRA pattern
echo ""
echo "All JIRA patterns in user messages (ranked by frequency):"

# Collect all text content from user messages for frequency analysis
all_jira_patterns=""
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | jq -e 'select(.type == "user")' >/dev/null 2>&1; then
        text_content=""
        
        # Handle both content format types (same logic as above)
        if echo "$line" | jq -e '.message.content | type == "string"' >/dev/null 2>&1; then
            text_content=$(echo "$line" | jq -r '.message.content' 2>/dev/null)
        elif echo "$line" | jq -e '.message.content | type == "array"' >/dev/null 2>&1; then
            text_content=$(echo "$line" | jq -r '
                .message.content[]? 
                | select(.type == "text") 
                | .text
            ' 2>/dev/null | tr '\n' ' ')
        fi
        
        # Apply same filtering as above
        if [[ -n "$text_content" ]] && ! [[ "$text_content" =~ ^[\<\[]?tool_(use_)?result|^\[Request\ interrupted|^Caveat:.*local\ commands|^\<(local-command|command-).*\>|^\(no\ content\)$ ]]; then
            all_jira_patterns+="$text_content "
        fi
    fi
done < "$transcript_file"

# Generate frequency report: count | pattern, sorted by count descending
if [[ -n "$all_jira_patterns" ]]; then
    echo "$all_jira_patterns" | grep -oE "(SPR|MULA|TBD|ZRO|WRH|GLOB|BUGS)-[0-9]{1,5}" | sort | uniq -c | sort -nr
else
    echo "  (no JIRA patterns found in user messages)"
fi

echo ""
echo "=== GIT BRANCH FALLBACK ==="
# Git branch analysis for comparison/fallback
# Useful when user prompts don't contain JIRA patterns but branch name does

# Extract git branch from any line in the transcript (they should be consistent)
if jq -r '.gitBranch // "no-branch"' < "$transcript_file" | head -1 | grep -v "no-branch" >/dev/null; then
    git_branch=$(jq -r '.gitBranch // "no-branch"' < "$transcript_file" | head -1)
    echo "Git branch from transcript: $git_branch"
    
    # Extract JIRA pattern from git branch name
    branch_jira=$(echo "$git_branch" | grep -oE "(SPR|MULA|TBD|ZRO|WRH|GLOB|BUGS)-[0-9]{1,5}" | head -1)
    if [[ -n "$branch_jira" ]]; then
        echo "JIRA ticket from git branch: $branch_jira"
        echo "  -> Use this as fallback if no user message patterns found"
    else
        echo "No JIRA pattern found in git branch"
    fi
else
    echo "No git branch found in transcript"
fi

echo ""
echo "=== USAGE NOTES FOR STATUSLINE INTEGRATION ==="
echo "Priority order for JIRA detection:"
echo "1. Most frequent JIRA pattern from user messages (if any found)"
echo "2. Most recent JIRA pattern from user messages (if tied frequency)" 
echo "3. JIRA pattern from git branch (if no user message patterns)"
echo "4. Empty/no JIRA ticket found"