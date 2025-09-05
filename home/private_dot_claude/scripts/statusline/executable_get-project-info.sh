#!/bin/bash

# Project Info Extraction Script for ccstatusline
# Reads JSON from stdin and extracts project name (or empty if none)  
# Usage: echo '{"workspace":{"current_dir":"/path/to/dir"}}' | ./get-project-info.sh

json_input=$(cat)
current_dir=$(echo "$json_input" | jq -r '.workspace.current_dir')

# Check if jq extraction succeeded
if [[ "$current_dir" == "null" ]]; then
    echo ""
    exit 0
fi

# Extract project logic from original statusline-script.sh
get_project_name() {
    local home_dir="$HOME"
    local bstock_projects="$home_dir/Projects/bstock-projects"
    local projects_dir="$home_dir/Projects"
    
    # Check if exactly in bstock-projects root
    if [[ "$current_dir" == "$bstock_projects" ]]; then
        echo ""  # No project name for root
    # Check if in bstock-projects subdirectory
    elif [[ "$current_dir" == "$bstock_projects"/* ]]; then
        # Extract project name (next subdirectory after bstock-projects)
        local relative_path="${current_dir#$bstock_projects/}"
        if [[ "$relative_path" != "$current_dir" && "$relative_path" != "" ]]; then
            local project_name=$(echo "$relative_path" | cut -d'/' -f1)
            echo "$project_name"
        else
            echo ""
        fi
    # Check if in other Projects subdirectory
    elif [[ "$current_dir" == "$projects_dir"/* ]]; then
        local relative_path="${current_dir#$projects_dir/}"
        if [[ "$relative_path" != "$current_dir" && "$relative_path" != "" ]]; then
            local first_dir=$(echo "$relative_path" | cut -d'/' -f1)
            if [[ "$first_dir" != "bstock-projects" ]]; then
                echo "$first_dir"
            else
                echo ""
            fi
        else
            echo ""
        fi
    else
        echo ""
    fi
}

project_name=$(get_project_name)
echo "$project_name"