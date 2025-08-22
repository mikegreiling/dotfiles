#!/bin/bash
#
# Claude Code Agent Log Cleanup Script
# 
# This script manages log files by archiving old sessions, compressing large files,
# and maintaining disk space limits for the logging system.
#

set -euo pipefail

LOGS_DIR="$HOME/.claude/logs/sessions"
ARCHIVE_DIR="$HOME/.claude/logs/archive"
SCRIPT_NAME="$(basename "$0")"

# Configuration - can be overridden by environment variables
RETENTION_DAYS=${CLAUDE_LOG_RETENTION_DAYS:-7}
MAX_LOG_SIZE_MB=${CLAUDE_LOG_MAX_SIZE_MB:-50}
MAX_TOTAL_SIZE_GB=${CLAUDE_LOG_MAX_TOTAL_SIZE_GB:-1}
COMPRESS_AFTER_DAYS=${CLAUDE_LOG_COMPRESS_AFTER_DAYS:-2}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options]

Manage Claude Code agent debugging logs by archiving, compressing, and cleaning up old files.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run          Show what would be done without making changes
    -f, --force            Force cleanup without interactive confirmation
    -r, --retention DAYS   Set retention period in days (default: $RETENTION_DAYS)
    -s, --max-size MB      Maximum size per log file in MB (default: $MAX_LOG_SIZE_MB)
    -t, --total-size GB    Maximum total size for all logs in GB (default: $MAX_TOTAL_SIZE_GB)
    -c, --compress DAYS    Compress logs older than N days (default: $COMPRESS_AFTER_DAYS)
    --stats                Show disk usage statistics only

ENVIRONMENT VARIABLES:
    CLAUDE_LOG_RETENTION_DAYS       Retention period in days
    CLAUDE_LOG_MAX_SIZE_MB         Maximum size per log file in MB
    CLAUDE_LOG_MAX_TOTAL_SIZE_GB   Maximum total size for all logs in GB
    CLAUDE_LOG_COMPRESS_AFTER_DAYS Compress logs older than N days

EXAMPLES:
    $SCRIPT_NAME                    # Run with default settings
    $SCRIPT_NAME -n                 # Dry run to see what would be cleaned
    $SCRIPT_NAME -r 14             # Keep logs for 14 days instead of $RETENTION_DAYS
    $SCRIPT_NAME --stats           # Show current disk usage statistics
EOF
}

# Show disk usage statistics
show_stats() {
    if [[ ! -d "$LOGS_DIR" ]]; then
        log_info "No logs directory found at $LOGS_DIR"
        return 0
    fi
    
    echo -e "${BLUE}Claude Code Agent Log Statistics${NC}"
    echo "================================="
    
    # Total size
    local total_size
    total_size=$(du -sh "$LOGS_DIR" 2>/dev/null | cut -f1 || echo "0B")
    echo "Total size: $total_size"
    
    # Number of sessions
    local session_count
    session_count=$(find "$LOGS_DIR" -name "metadata.json" -type f | wc -l | tr -d ' ')
    echo "Total sessions: $session_count"
    
    # Age distribution
    echo
    echo "Age distribution:"
    for days in 1 2 7 14 30; do
        local count
        count=$(find "$LOGS_DIR" -name "*.log" -type f -mtime "-${days}" | wc -l | tr -d ' ')
        printf "  Last %2d days: %d files\n" "$days" "$count"
    done
    
    # Largest sessions
    echo
    echo "Largest sessions:"
    find "$LOGS_DIR" -maxdepth 2 -mindepth 2 -type d -exec du -sh {} \; 2>/dev/null | \
        sort -hr | head -5 | while read -r size session_path; do
        local session_id
        session_id="$(basename "$session_path")"
        printf "  %8s: %s\n" "$size" "$session_id"
    done
    
    # Archive statistics if archive exists
    if [[ -d "$ARCHIVE_DIR" ]]; then
        echo
        local archive_size
        archive_size=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1 || echo "0B")
        local archive_count
        archive_count=$(find "$ARCHIVE_DIR" -name "*.tar.gz" -type f | wc -l | tr -d ' ')
        echo "Archive size: $archive_size ($archive_count compressed sessions)"
    fi
}

# Compress old log files
compress_old_logs() {
    local compress_days="$1"
    local dry_run="$2"
    
    log_info "Compressing logs older than $compress_days days..."
    
    local compressed_count=0
    find "$LOGS_DIR" -name "*.log" -type f -mtime "+$compress_days" -size "+1024c" | while read -r log_file; do
        if [[ "$dry_run" = true ]]; then
            log_info "[DRY RUN] Would compress: $log_file"
        else
            if gzip "$log_file" 2>/dev/null; then
                log_info "Compressed: $log_file"
                ((compressed_count++))
            else
                log_warn "Failed to compress: $log_file"
            fi
        fi
    done
    
    if [[ "$compressed_count" -gt 0 ]]; then
        log_success "Compressed $compressed_count log files"
    fi
}

# Archive old sessions
archive_old_sessions() {
    local retention_days="$1"
    local dry_run="$2"
    
    log_info "Archiving sessions older than $retention_days days..."
    
    mkdir -p "$ARCHIVE_DIR"
    
    local archived_count=0
    find "$LOGS_DIR" -maxdepth 2 -mindepth 2 -type d -mtime "+$retention_days" | while read -r session_dir; do
        local session_id
        session_id="$(basename "$session_dir")"
        local date_dir
        date_dir="$(basename "$(dirname "$session_dir")")"
        local archive_name="${date_dir}_${session_id}.tar.gz"
        local archive_path="$ARCHIVE_DIR/$archive_name"
        
        if [[ "$dry_run" = true ]]; then
            log_info "[DRY RUN] Would archive: $session_dir -> $archive_path"
        else
            if (cd "$(dirname "$session_dir")" && tar -czf "$archive_path" "$(basename "$session_dir")" 2>/dev/null); then
                rm -rf "$session_dir"
                log_info "Archived: $session_id -> $archive_name"
                ((archived_count++))
            else
                log_warn "Failed to archive: $session_dir"
            fi
        fi
    done
    
    if [[ "$archived_count" -gt 0 ]]; then
        log_success "Archived $archived_count sessions"
    fi
}

# Clean up empty directories
cleanup_empty_dirs() {
    local dry_run="$1"
    
    find "$LOGS_DIR" -type d -empty | while read -r empty_dir; do
        if [[ "$empty_dir" != "$LOGS_DIR" ]]; then
            if [[ "$dry_run" = true ]]; then
                log_info "[DRY RUN] Would remove empty directory: $empty_dir"
            else
                rmdir "$empty_dir" 2>/dev/null || true
                log_info "Removed empty directory: $empty_dir"
            fi
        fi
    done
}

# Enforce size limits
enforce_size_limits() {
    local max_size_mb="$1"
    local max_total_gb="$2"
    local dry_run="$3"
    
    # Check individual file sizes
    local oversized_count=0
    find "$LOGS_DIR" -name "*.log" -type f -size "+${max_size_mb}M" | while read -r large_file; do
        local file_size
        file_size=$(du -h "$large_file" | cut -f1)
        
        if [[ "$dry_run" = true ]]; then
            log_warn "[DRY RUN] Would truncate oversized file: $large_file ($file_size)"
        else
            # Keep last 1000 lines of oversized files
            local temp_file
            temp_file=$(mktemp)
            tail -n 1000 "$large_file" > "$temp_file" && mv "$temp_file" "$large_file"
            log_warn "Truncated oversized file: $large_file (was $file_size)"
            ((oversized_count++))
        fi
    done
    
    # Check total size
    local total_size_bytes
    total_size_bytes=$(du -sb "$LOGS_DIR" 2>/dev/null | cut -f1 || echo "0")
    local max_total_bytes=$((max_total_gb * 1024 * 1024 * 1024))
    
    if [[ "$total_size_bytes" -gt "$max_total_bytes" ]]; then
        local total_size_gb=$((total_size_bytes / 1024 / 1024 / 1024))
        log_warn "Total size (${total_size_gb}GB) exceeds limit (${max_total_gb}GB)"
        
        # Remove oldest sessions until under limit
        find "$LOGS_DIR" -maxdepth 2 -mindepth 2 -type d -exec stat -f "%m %N" {} \; 2>/dev/null | \
            sort -n | while read -r mtime session_dir; do
            
            current_size=$(du -sb "$LOGS_DIR" 2>/dev/null | cut -f1 || echo "0")
            if [[ "$current_size" -le "$max_total_bytes" ]]; then
                break
            fi
            
            local session_id
            session_id="$(basename "$session_dir")"
            
            if [[ "$dry_run" = true ]]; then
                log_warn "[DRY RUN] Would remove session to free space: $session_id"
            else
                rm -rf "$session_dir"
                log_warn "Removed session to free space: $session_id"
            fi
        done
    fi
}

# Main cleanup function
cleanup_logs() {
    local retention_days="$1"
    local max_size_mb="$2"
    local max_total_gb="$3"
    local compress_days="$4"
    local dry_run="$5"
    local force="$6"
    
    if [[ ! -d "$LOGS_DIR" ]]; then
        log_info "No logs directory found at $LOGS_DIR - nothing to clean"
        return 0
    fi
    
    if [[ "$force" = false && "$dry_run" = false ]]; then
        echo -e "${YELLOW}This will clean up Claude Code agent logs with the following settings:${NC}"
        echo "  Retention period: $retention_days days"
        echo "  Max file size: ${max_size_mb}MB"
        echo "  Max total size: ${max_total_gb}GB"
        echo "  Compress after: $compress_days days"
        echo
        read -p "Continue? [y/N] " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Cleanup cancelled"
            return 0
        fi
    fi
    
    log_info "Starting cleanup of Claude Code agent logs..."
    echo "Settings:"
    echo "  Logs directory: $LOGS_DIR"
    echo "  Retention: $retention_days days"
    echo "  Max file size: ${max_size_mb}MB"
    echo "  Max total size: ${max_total_gb}GB"
    echo "  Compress after: $compress_days days"
    echo "  Dry run: $dry_run"
    echo
    
    # Step 1: Compress old logs
    compress_old_logs "$compress_days" "$dry_run"
    
    # Step 2: Archive old sessions
    archive_old_sessions "$retention_days" "$dry_run"
    
    # Step 3: Enforce size limits
    enforce_size_limits "$max_size_mb" "$max_total_gb" "$dry_run"
    
    # Step 4: Clean up empty directories
    cleanup_empty_dirs "$dry_run"
    
    if [[ "$dry_run" = false ]]; then
        log_success "Cleanup completed"
    else
        log_info "Dry run completed - no changes made"
    fi
    
    echo
    show_stats
}

# Parse command line arguments
DRY_RUN=false
FORCE=false
SHOW_STATS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -r|--retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -s|--max-size)
            MAX_LOG_SIZE_MB="$2"
            shift 2
            ;;
        -t|--total-size)
            MAX_TOTAL_SIZE_GB="$2"
            shift 2
            ;;
        -c|--compress)
            COMPRESS_AFTER_DAYS="$2"
            shift 2
            ;;
        --stats)
            SHOW_STATS_ONLY=true
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            log_error "Unexpected argument: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate numeric arguments
if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]] || [[ "$RETENTION_DAYS" -lt 1 ]]; then
    log_error "Retention days must be a positive integer"
    exit 1
fi

if ! [[ "$MAX_LOG_SIZE_MB" =~ ^[0-9]+$ ]] || [[ "$MAX_LOG_SIZE_MB" -lt 1 ]]; then
    log_error "Max log size must be a positive integer (MB)"
    exit 1
fi

if ! [[ "$MAX_TOTAL_SIZE_GB" =~ ^[0-9]+$ ]] || [[ "$MAX_TOTAL_SIZE_GB" -lt 1 ]]; then
    log_error "Max total size must be a positive integer (GB)"
    exit 1
fi

if ! [[ "$COMPRESS_AFTER_DAYS" =~ ^[0-9]+$ ]] || [[ "$COMPRESS_AFTER_DAYS" -lt 1 ]]; then
    log_error "Compress after days must be a positive integer"
    exit 1
fi

# Main execution
if [[ "$SHOW_STATS_ONLY" = true ]]; then
    show_stats
else
    cleanup_logs "$RETENTION_DAYS" "$MAX_LOG_SIZE_MB" "$MAX_TOTAL_SIZE_GB" "$COMPRESS_AFTER_DAYS" "$DRY_RUN" "$FORCE"
fi