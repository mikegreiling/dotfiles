#!/bin/bash

# Path Formatting Script for ccstatusline
# Reads JSON from stdin and outputs formatted path
# Usage: echo '{"workspace":{"current_dir":"/path/to/dir"}}' | ./format-path.sh

json_input=$(cat)
current_dir=$(echo "$json_input" | jq -r '.workspace.current_dir')

# Check if jq extraction succeeded
if [[ "$current_dir" == "null" ]]; then
    exit 0
fi

# Extract path formatting logic from original statusline-script.sh
format_path() {
    local home_dir="$HOME"
    local bstock_projects="$home_dir/Projects/bstock-projects"
    local projects_dir="$home_dir/Projects"
    
    # Check if exactly in bstock-projects root
    if [[ "$current_dir" == "$bstock_projects" ]]; then
        echo "~/Projects/bstock-projects"
    # Check if in bstock-projects subdirectory
    elif [[ "$current_dir" == "$bstock_projects"/* ]]; then
        # Extract project name and path within project
        local relative_path="${current_dir#$bstock_projects/}"
        if [[ "$relative_path" != "$current_dir" && "$relative_path" != "" ]]; then
            local project_name=$(echo "$relative_path" | cut -d'/' -f1)
            local project_path="${relative_path#$project_name}"
            project_path="${project_path#/}"  # Remove leading slash
            echo "$project_path"
        else
            echo "~/Projects/bstock-projects"
        fi
    # Check if in other Projects subdirectory
    elif [[ "$current_dir" == "$projects_dir"/* ]]; then
        local relative_path="${current_dir#$projects_dir/}"
        if [[ "$relative_path" != "$current_dir" && "$relative_path" != "" ]]; then
            local first_dir=$(echo "$relative_path" | cut -d'/' -f1)
            if [[ "$first_dir" != "bstock-projects" ]]; then
                local project_name="$first_dir"
                local project_path="${relative_path#$project_name}"
                project_path="${project_path#/}"  # Remove leading slash
                echo "$project_path"
            else
                echo "${current_dir/#$home_dir/~}"
            fi
        else
            echo "~/Projects"
        fi
    # Check if in home directory (fix path normalization)
    elif [[ "$current_dir" == "$home_dir"/* ]]; then
        echo "${current_dir/#$home_dir/~}"
    elif [[ "$current_dir" == "$home_dir" ]]; then
        # Exactly in home directory
        echo "~"
    else
        # Outside home directory
        echo "$current_dir"
    fi
}

formatted_path=$(format_path)
if [[ -n "$formatted_path" ]]; then
    echo "$formatted_path"
fi