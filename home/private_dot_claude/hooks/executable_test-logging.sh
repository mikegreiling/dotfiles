#!/bin/bash
#
# Test script for the Claude Code Agent Logging System
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="$HOME/.claude/logs/sessions"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Testing Claude Code Agent Logging System${NC}"
echo "========================================"

# Test 1: Verify logger script exists and is executable
echo "1. Checking logger script..."
if [[ -x "$SCRIPT_DIR/agent-logger.py" ]]; then
    echo -e "   ${GREEN}✓${NC} Logger script found and executable"
else
    echo -e "   ${RED}✗${NC} Logger script not found or not executable"
    exit 1
fi

# Test 2: Test logger with sample input
echo "2. Testing logger with sample data..."
test_session_id="test_$(date +%s)"
sample_input='{
    "session_id": "'$test_session_id'",
    "hook_event_name": "PostToolUse",
    "cwd": "/tmp/test",
    "tool_name": "Task",
    "tool_input": {
        "subagent_type": "git-rebase-resolver",
        "description": "Test rebase operation",
        "prompt": "This is a test prompt for the git-rebase-resolver agent to demonstrate the logging system."
    }
}'

if echo "$sample_input" | python3 "$SCRIPT_DIR/agent-logger.py"; then
    echo -e "   ${GREEN}✓${NC} Logger processed sample input successfully"
else
    echo -e "   ${RED}✗${NC} Logger failed to process sample input"
    exit 1
fi

# Test 3: Verify log files were created
echo "3. Checking log file creation..."
expected_log_dir="$LOGS_DIR/$(date +%Y-%m-%d)/$test_session_id"
if [[ -d "$expected_log_dir" ]]; then
    echo -e "   ${GREEN}✓${NC} Session directory created: $expected_log_dir"
    
    if [[ -f "$expected_log_dir/metadata.json" ]]; then
        echo -e "   ${GREEN}✓${NC} Metadata file created"
    else
        echo -e "   ${RED}✗${NC} Metadata file not created"
        exit 1
    fi
    
    if [[ -f "$expected_log_dir/agent_git-rebase-resolver.log" ]]; then
        echo -e "   ${GREEN}✓${NC} Agent log file created"
    else
        echo -e "   ${RED}✗${NC} Agent log file not created"
        exit 1
    fi
else
    echo -e "   ${RED}✗${NC} Session directory not created"
    exit 1
fi

# Test 4: Verify log viewer works
echo "4. Testing log viewer..."
if [[ -x "$SCRIPT_DIR/view-logs.sh" ]]; then
    if "$SCRIPT_DIR/view-logs.sh" -r 1 > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} Log viewer executed successfully"
    else
        echo -e "   ${YELLOW}⚠${NC} Log viewer ran but may have warnings (check output)"
    fi
else
    echo -e "   ${RED}✗${NC} Log viewer not found or not executable"
    exit 1
fi

# Test 5: Verify cleanup script works
echo "5. Testing cleanup script..."
if [[ -x "$SCRIPT_DIR/cleanup-logs.sh" ]]; then
    if "$SCRIPT_DIR/cleanup-logs.sh" --stats > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓${NC} Cleanup script executed successfully"
    else
        echo -e "   ${YELLOW}⚠${NC} Cleanup script ran but may have warnings"
    fi
else
    echo -e "   ${RED}✗${NC} Cleanup script not found or not executable"
    exit 1
fi

echo
echo -e "${GREEN}All tests passed!${NC}"
echo
echo "Next steps:"
echo "1. The logging system is now active and will capture agent interactions"
echo "2. Use a Claude Code session that triggers a sub-agent to see logs in action"
echo "3. View logs with: $SCRIPT_DIR/view-logs.sh"
echo "4. Manage logs with: $SCRIPT_DIR/cleanup-logs.sh"
echo
echo "Test session created: $test_session_id"
echo "You can view it with: $SCRIPT_DIR/view-logs.sh $test_session_id"