#!/bin/bash

# Model Name Formatting Script for ccstatusline
# Reads JSON from stdin and outputs formatted model name with context window size
# Usage: echo '{"model":{"display_name":"Opus"},"context_window":{"context_window_size":200000}}' | ./get-model-name.sh

json_input=$(cat)

# model field can be an object {id, display_name} or a plain string
model_raw=$(echo "$json_input" | jq -r '.model')
if echo "$model_raw" | jq -e 'type == "object"' >/dev/null 2>&1; then
    model_name=$(echo "$model_raw" | jq -r '.display_name')
else
    model_name="$model_raw"
fi

if [[ -z "$model_name" || "$model_name" == "null" ]]; then
    echo ""
    exit 0
fi

# Append context window size when provided
context_size=$(echo "$json_input" | jq -r '.context_window.context_window_size // empty')
if [[ -n "$context_size" && "$context_size" != "null" ]]; then
    if (( context_size >= 1000000 )); then
        size_label="$(( context_size / 1000000 ))M"
    elif (( context_size >= 1000 )); then
        size_label="$(( context_size / 1000 ))K"
    else
        size_label="$context_size"
    fi
    echo "$model_name ($size_label)"
else
    echo "$model_name"
fi
