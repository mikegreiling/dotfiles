#!/usr/bin/env bash
# gitlab-ci-poll.sh — Poll a GitLab CI pipeline or job until it reaches a
# terminal state, then print a summary.
#
# Designed to run as a Claude Code BACKGROUND task:
#   Bash(run_in_background: true) → the harness wakes the session when this
#   process exits. No MCP, no polling-agent, zero context burned while waiting.
#
# Talks to gitlab.bstock.io via the `glab` CLI, which must already be
# authenticated (`glab auth status`). Because a background task is not subject
# to the 120s foreground tool timeout, the loop sleeps the full interval
# directly — no sleep-chaining hacks.
#
# Usage:
#   gitlab-ci-poll.sh --project <id|path> --pipeline <id>
#   gitlab-ci-poll.sh --project <id|path> --job <id>
#   gitlab-ci-poll.sh --project <id|path> --ref <branch>   # latest pipeline on ref
#   gitlab-ci-poll.sh --project <id|path> --mr <iid>       # latest pipeline for an MR
#
# Options:
#   --interval <sec>   poll interval (default 30)
#   --timeout <sec>    give up after this long (default 3600)
#   --host <host>      GitLab host (default gitlab.bstock.io)
#   --no-logs          on failure, do NOT tail failed-job logs
#   --log-lines <n>    lines of each failed job's log to tail (default 40)
#   --success-grep <re> on success, grep the job/pipeline trace(s) for extended
#                      regex <re> (case-insensitive) and print matching lines in
#                      the summary — e.g. capture a published version string
#   -h, --help         show this help
#
# Exit codes: 0 success/skipped/manual · 1 failed · 2 canceled · 124 timeout
#             · 3 usage/auth error
set -uo pipefail

HOST="gitlab.bstock.io"
INTERVAL=30
TIMEOUT=3600
LOG_LINES=40
TAIL_LOGS=1
SUCCESS_GREP=""
PROJECT="" PIPELINE="" JOB="" REF="" MR=""

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
die()   { echo "ERROR: $*" >&2; exit 3; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)   PROJECT="$2"; shift 2;;
    --pipeline)  PIPELINE="$2"; shift 2;;
    --job)       JOB="$2"; shift 2;;
    --ref)       REF="$2"; shift 2;;
    --mr)        MR="$2"; shift 2;;
    --interval)  INTERVAL="$2"; shift 2;;
    --timeout)   TIMEOUT="$2"; shift 2;;
    --host)      HOST="$2"; shift 2;;
    --no-logs)   TAIL_LOGS=0; shift;;
    --log-lines) LOG_LINES="$2"; shift 2;;
    --success-grep) SUCCESS_GREP="$2"; shift 2;;
    -h|--help)   usage 0;;
    *)           die "unknown argument: $1";;
  esac
done

[[ -n "$PROJECT" ]] || die "--project is required"
command -v glab >/dev/null 2>&1 || die "glab not found on PATH"

# URL-encode the project path (numeric IDs pass through unchanged).
PROJ_ENC="${PROJECT//\//%2F}"

api() { glab api --hostname "$HOST" "$@"; }

# jq-style field pluck via python3 (jq may not be installed; python3 always is).
pluck() { python3 -c 'import sys,json
d=json.load(sys.stdin)
for k in sys.argv[1:]:
    d = d.get(k, "") if isinstance(d, dict) else ""
print(d if d is not None else "")' "$@"; }

ACTIVE_RE='^(created|waiting_for_resource|preparing|pending|running|scheduled)$'

# Resolve --ref / --mr down to a concrete pipeline id before the loop.
resolve_pipeline() {
  local json
  if [[ -n "$REF" ]]; then
    local ref_enc="${REF//\//%2F}"
    json="$(api "projects/$PROJ_ENC/pipelines?ref=$ref_enc&per_page=1" 2>/dev/null)" \
      || die "failed to query pipelines for ref '$REF' (check glab auth / project)"
  elif [[ -n "$MR" ]]; then
    json="$(api "projects/$PROJ_ENC/merge_requests/$MR/pipelines?per_page=1" 2>/dev/null)" \
      || die "failed to query pipelines for MR !$MR"
  else
    return 0
  fi
  PIPELINE="$(printf '%s' "$json" | python3 -c 'import sys,json
a=json.load(sys.stdin)
print(a[0]["id"] if a else "")')"
  [[ -n "$PIPELINE" ]] || die "no pipeline found for ${REF:+ref $REF}${MR:+MR !$MR}"
}

# Fetch the target object once; echo "<status>\t<web_url>".
fetch() {
  local json
  if [[ -n "$JOB" ]]; then
    json="$(api "projects/$PROJ_ENC/jobs/$JOB" 2>/dev/null)" || return 1
  else
    json="$(api "projects/$PROJ_ENC/pipelines/$PIPELINE" 2>/dev/null)" || return 1
  fi
  printf '%s\t%s' \
    "$(printf '%s' "$json" | pluck status)" \
    "$(printf '%s' "$json" | pluck web_url)"
}

dump_failed_logs() {
  [[ "$TAIL_LOGS" -eq 1 ]] || return 0
  if [[ -n "$JOB" ]]; then
    echo
    echo "──── last ${LOG_LINES} lines of job $JOB ────"
    api "projects/$PROJ_ENC/jobs/$JOB/trace" 2>/dev/null | tail -n "$LOG_LINES"
    return 0
  fi
  local jobs failed
  jobs="$(api "projects/$PROJ_ENC/pipelines/$PIPELINE/jobs?per_page=100" 2>/dev/null)" || return 0
  failed="$(printf '%s' "$jobs" | python3 -c 'import sys,json
for j in json.load(sys.stdin):
    if j.get("status")=="failed":
        print(f'\''{j["id"]}\t{j["stage"]}\t{j["name"]}'\'')')"
  [[ -n "$failed" ]] || return 0
  echo
  echo "Failed jobs:"
  while IFS=$'\t' read -r jid stage name; do
    [[ -n "$jid" ]] || continue
    echo "  • [$stage] $name (job $jid)"
  done <<< "$failed"
  while IFS=$'\t' read -r jid stage name; do
    [[ -n "$jid" ]] || continue
    echo
    echo "──── last ${LOG_LINES} lines of [$stage] $name (job $jid) ────"
    api "projects/$PROJ_ENC/jobs/$jid/trace" 2>/dev/null | tail -n "$LOG_LINES"
  done <<< "$failed"
}

# On success, grep the trace(s) for a caller-supplied pattern and print matches.
# For a single --job, greps that job's trace; for a pipeline, greps every job's
# trace. Matching is case-insensitive extended regex.
dump_success_grep() {
  [[ -n "$SUCCESS_GREP" ]] || return 0
  echo
  echo "──── lines matching /$SUCCESS_GREP/ ────"
  local found=0
  grep_trace() {
    local jid="$1" out
    out="$(api "projects/$PROJ_ENC/jobs/$jid/trace" 2>/dev/null | grep -iE "$SUCCESS_GREP")"
    [[ -n "$out" ]] && { printf '%s\n' "$out"; found=1; }
  }
  if [[ -n "$JOB" ]]; then
    grep_trace "$JOB"
  else
    local ids
    ids="$(api "projects/$PROJ_ENC/pipelines/$PIPELINE/jobs?per_page=100" 2>/dev/null \
      | python3 -c 'import sys,json
for j in json.load(sys.stdin):
    print(j["id"])')"
    while read -r jid; do
      [[ -n "$jid" ]] || continue
      grep_trace "$jid"
    done <<< "$ids"
  fi
  (( found )) || echo "(no matching lines)"
}

main() {
  resolve_pipeline
  local label
  if [[ -n "$JOB" ]]; then label="job $JOB"; else label="pipeline $PIPELINE"; fi
  echo "[$(date '+%H:%M:%S')] polling $label on $HOST (project $PROJECT, interval ${INTERVAL}s, timeout ${TIMEOUT}s)"

  local start status web_url now elapsed result out
  start=$(date +%s)
  while :; do
    out="$(fetch)" || out=""
    status="${out%%$'\t'*}"
    if [[ "$out" == *$'\t'* ]]; then web_url="${out#*$'\t'}"; else web_url=""; fi
    now=$(date +%s); elapsed=$((now - start))

    if [[ -z "$status" ]]; then
      echo "[$(date '+%H:%M:%S')] (no status — transient API error, retrying)"
    elif [[ "$status" =~ $ACTIVE_RE ]]; then
      echo "[$(date '+%H:%M:%S')] $status (${elapsed}s elapsed)"
    else
      result="$status"; break
    fi

    if (( elapsed >= TIMEOUT )); then
      echo "[$(date '+%H:%M:%S')] TIMEOUT after ${elapsed}s (last status: ${status:-unknown})"
      exit 124
    fi
    sleep "$INTERVAL"
  done

  echo
  echo "[$(date '+%H:%M:%S')] $label finished: ${result} (after ${elapsed}s)"
  [[ -n "${web_url:-}" ]] && echo "URL: $web_url"

  case "$result" in
    failed)   dump_failed_logs; exit 1;;
    canceled) exit 2;;
    *)        dump_success_grep; exit 0;;   # success, skipped, manual
  esac
}

main
