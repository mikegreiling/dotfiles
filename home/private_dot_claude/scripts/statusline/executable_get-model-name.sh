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
    "Sonnet 4.5 (with 1M token context)")
        echo "Sonnet 4.5 (1M)"
        ;;
    "Sonnet 4 (with 1M token context)")
        echo "Sonnet 4 (1M)"
        ;;
    "Claude 3.5 Sonnet"*)
        echo "Sonnet 3.5"
        ;;
    "Claude 3 Opus"*)
        echo "Opus 3"
        ;;
    "Claude 3 Haiku"*)
        echo "Haiku 3"
        ;;
    *)
        # Default: use original name for unknown models
        echo "$model_name"
        ;;
esac