#!/bin/bash

# Model Name Formatting Script for ccstatusline
# Reads JSON from stdin and outputs formatted model name
# Usage: echo '{"model":{"display_name":"..."}}' | ./get-model-name.sh

json_input=$(cat)
model_name=$(echo "$json_input" | jq -r '.model.display_name')

# Check if jq extraction succeeded
if [[ "$model_name" == "null" ]]; then
    echo ""
    exit 0
fi

# Format the model name for more concise display
case "$model_name" in
    "Sonnet 4 (with 1M token context)")
        echo "Sonnet 4 (1M)"
        ;;
    "Claude 3.5 Sonnet"*)
        echo "Claude 3.5 Sonnet"
        ;;
    "Claude 3 Opus"*)
        echo "Claude 3 Opus" 
        ;;
    "Claude 3 Haiku"*)
        echo "Claude 3 Haiku"
        ;;
    *)
        # Default: use original name for unknown models
        echo "$model_name"
        ;;
esac