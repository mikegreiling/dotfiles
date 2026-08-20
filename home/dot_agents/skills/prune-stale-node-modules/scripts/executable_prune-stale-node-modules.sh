#!/usr/bin/env bash
#
# prune-stale-node-modules.sh
#
# Reclaim disk space by deleting the top-level node_modules directory from git
# worktrees (primary clones and linked worktrees) that have shown no activity
# for N days.
#
# Safety model:
#   * Only ever removes a directory literally named "node_modules" that sits at
#     the top level of a git worktree which also has a package.json.
#   * Never follows symlinks; a symlinked node_modules is reported, not touched.
#   * Never touches nested node_modules (they are removed with their parent, or
#     left entirely alone).
#   * If activity cannot be determined at all, the worktree is treated as ACTIVE
#     and left alone (fail safe).
#   * --dry-run reports exactly what would be removed and removes nothing.
#
# macOS/BSD compatible: BSD find/stat/du, bash 3.2, no GNU-only flags.

set -euo pipefail

DAYS=28
ROOT="/Volumes/Workspace"
DRY_RUN=0
LINKED_ONLY=0
MAX_DEPTH=4          # worktree depth relative to --root
STATUS_FILE_CAP=300  # max files inspected from `git status` per worktree

PROG="$(basename "$0")"

usage() {
  cat <<EOF
Usage: $PROG [--days N] [--root PATH] [--dry-run] [--linked-only] [--max-depth N]

  --days N        Inactivity cutoff in days (default: $DAYS).
  --root PATH     Directory tree to scan (default: $ROOT).
  --dry-run       Report what would be deleted; delete nothing.
  --linked-only   Only consider linked worktrees; skip each repo's primary checkout.
  --max-depth N   How deep below --root to look for worktrees (default: $MAX_DEPTH).
  -h, --help      Show this help.
EOF
}

die() { echo "$PROG: $*" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --days)        [ $# -ge 2 ] || die "--days requires a value"; DAYS="$2"; shift 2 ;;
    --days=*)      DAYS="${1#*=}"; shift ;;
    --root)        [ $# -ge 2 ] || die "--root requires a value"; ROOT="$2"; shift 2 ;;
    --root=*)      ROOT="${1#*=}"; shift ;;
    --max-depth)   [ $# -ge 2 ] || die "--max-depth requires a value"; MAX_DEPTH="$2"; shift 2 ;;
    --max-depth=*) MAX_DEPTH="${1#*=}"; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    --linked-only) LINKED_ONLY=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             usage >&2; die "unknown option: $1" ;;
  esac
done

case "$DAYS" in ''|*[!0-9]*) die "--days must be a non-negative integer (got: $DAYS)" ;; esac
case "$MAX_DEPTH" in ''|*[!0-9]*) die "--max-depth must be a positive integer (got: $MAX_DEPTH)" ;; esac
[ "$MAX_DEPTH" -ge 1 ] || die "--max-depth must be >= 1"
[ -d "$ROOT" ] || die "--root is not a directory: $ROOT"

command -v git >/dev/null 2>&1 || die "git not found on PATH"

# Critical: without this, `git status` refreshes and REWRITES each index, which
# would bump every worktree's index mtime to "now" and make the whole tree look
# active on the next run. (Equivalent to `git --no-optional-locks`, but ignored
# rather than fatal on git < 2.18.)
export GIT_OPTIONAL_LOCKS=0

# Normalize ROOT to an absolute, symlink-free path without trailing slash.
ROOT="$(cd "$ROOT" && pwd -P)"

TMPDIR_RUN="$(mktemp -d "${TMPDIR:-/tmp}/prune-node-modules.XXXXXX")"
cleanup() { rm -rf "$TMPDIR_RUN"; }
trap cleanup EXIT

DELETED="$TMPDIR_RUN/deleted.tsv"     # kb \t age_days \t path
SKIPPED="$TMPDIR_RUN/skipped.tsv"     # age_days \t path
ANOMALY="$TMPDIR_RUN/anomalies.txt"
: >"$DELETED"; : >"$SKIPPED"; : >"$ANOMALY"

NOW="$(date +%s)"
CUTOFF_SECS=$(( DAYS * 86400 ))

human_kb() {
  awk -v k="$1" 'BEGIN{
    if (k >= 1048576)   printf "%.1f GB", k/1048576;
    else if (k >= 1024) printf "%.1f MB", k/1024;
    else                printf "%d KB", k;
  }'
}

note_anomaly() { printf '%s\n' "$*" >>"$ANOMALY"; }

# BEST is the running "newest activity" epoch for the worktree under inspection.
BEST=0
bump_best() {
  case "${1:-}" in ''|*[!0-9]*) return 0 ;; esac
  if [ "$1" -gt "$BEST" ]; then BEST="$1"; fi
}

STATPATHS="$TMPDIR_RUN/statpaths"

# last_activity <worktree> -> prints an epoch, or nothing if every signal failed.
last_activity() {
  local w="$1" t idx line path newest

  BEST=0

  # (a) commit time of HEAD (absent on an unborn branch or a broken repo)
  t="$(git -C "$w" log -1 --format=%ct 2>/dev/null || true)"
  bump_best "$t"

  # (b) mtime of the index (captures staging activity without new commits)
  idx="$(git -C "$w" rev-parse --git-path index 2>/dev/null || true)"
  if [ -n "$idx" ]; then
    case "$idx" in /*) ;; *) idx="$w/$idx" ;; esac
    if [ -f "$idx" ]; then
      t="$(stat -f '%m' "$idx" 2>/dev/null || true)"
      bump_best "$t"
    fi
  fi

  # (c) newest mtime among modified/untracked paths (captures unstaged edits).
  #     Paths are batched through a single stat(1) call for speed.
  #     node_modules itself is excluded: when a repo does not gitignore it, git
  #     reports it as untracked and its install-time mtime would make every such
  #     worktree look permanently active.
  : >"$STATPATHS"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    path="${line:3}"                                          # strip "XY "
    case "$path" in *" -> "*) path="${path##* -> }" ;; esac    # renames
    case "$path" in \"*\") path="${path%\"}"; path="${path#\"}" ;; esac
    [ -n "$path" ] || continue
    case "$path" in node_modules|node_modules/|node_modules/*) continue ;; esac
    case "$path" in /*) ;; *) path="$w/$path" ;; esac
    # Missing entries (deletions, broken symlinks) are simply not stat'd.
    if [ -e "$path" ]; then
      printf '%s\0' "$path" >>"$STATPATHS"
    fi
  done <<EOF
$(git -C "$w" status --porcelain --untracked-files=normal 2>/dev/null | head -n "$STATUS_FILE_CAP" || true)
EOF
  if [ -s "$STATPATHS" ]; then
    newest="$(xargs -0 stat -f '%m' <"$STATPATHS" 2>/dev/null | sort -nr | head -n 1 || true)"
    bump_best "$newest"
  fi

  if [ "$BEST" -gt 0 ]; then
    printf '%s' "$BEST"
  fi
}

# ---------------------------------------------------------------------------
# 1. Enumerate worktrees: directories containing a .git entry (dir = primary
#    clone, file = linked worktree). Prune descent into node_modules and .git
#    for speed, and past the .git we just matched.
# ---------------------------------------------------------------------------
FIND_DEPTH=$(( MAX_DEPTH + 1 ))
FIND_ERRS="$TMPDIR_RUN/find.err"
WORKTREES="$TMPDIR_RUN/worktrees.txt"

find "$ROOT" -maxdepth "$FIND_DEPTH" \
     \( -name node_modules -o -name .Trashes -o -name .fseventsd -o -name .Spotlight-V100 \) -prune -o \
     -name .git -print -prune \
     2>"$FIND_ERRS" |
  sed 's:/\.git$::' |
  sort -u >"$WORKTREES" || true

if [ -s "$FIND_ERRS" ]; then
  while IFS= read -r line; do
    note_anomaly "find: $line"
  done <"$FIND_ERRS"
fi

scanned=0
candidates=0

while IFS= read -r wt; do
  [ -n "$wt" ] || continue
  [ -d "$wt" ] || continue
  scanned=$(( scanned + 1 ))

  gitentry="$wt/.git"
  if [ "$LINKED_ONLY" -eq 1 ] && [ -d "$gitentry" ]; then
    continue    # primary checkout, and we were asked for linked worktrees only
  fi

  nm="$wt/node_modules"
  pkg="$wt/package.json"

  # Hard gates: package.json must exist AND node_modules must exist.
  [ -f "$pkg" ] || continue
  [ -e "$nm" ] || continue

  if [ -L "$nm" ]; then
    note_anomaly "symlinked node_modules, left alone: $nm -> $(readlink "$nm" 2>/dev/null || echo '?')"
    continue
  fi
  [ -d "$nm" ] || { note_anomaly "node_modules is not a directory, left alone: $nm"; continue; }

  candidates=$(( candidates + 1 ))

  act="$(last_activity "$wt" || true)"
  if [ -z "$act" ]; then
    note_anomaly "activity undetectable (unreadable or empty repo) — kept, fail-safe: $wt"
    continue
  fi

  age_secs=$(( NOW - act ))
  [ "$age_secs" -ge 0 ] || age_secs=0
  age_days=$(( age_secs / 86400 ))

  if [ "$age_secs" -le "$CUTOFF_SECS" ]; then
    printf '%s\t%s\n' "$age_days" "$wt" >>"$SKIPPED"
    continue
  fi

  kb="$(du -sk "$nm" 2>/dev/null | awk 'NR==1{print $1}' || true)"
  case "$kb" in ''|*[!0-9]*) kb=0; note_anomaly "could not size node_modules (reported as 0): $nm" ;; esac

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s\t%s\t%s\n' "$kb" "$age_days" "$wt" >>"$DELETED"
    continue
  fi

  # Belt-and-braces guards before any destructive action.
  case "$nm" in
    "$ROOT"/*/node_modules|"$ROOT"/*/*/node_modules|"$ROOT"/*/*/*/node_modules|"$ROOT"/*/*/*/*/node_modules) ;;
    *) note_anomaly "refusing to delete (path failed safety check): $nm"; continue ;;
  esac
  if [ "$(basename "$nm")" != "node_modules" ] || [ -L "$nm" ] || [ ! -d "$nm" ]; then
    note_anomaly "refusing to delete (final check failed): $nm"
    continue
  fi

  if rm -rf "$nm" 2>>"$ANOMALY"; then
    printf '%s\t%s\t%s\n' "$kb" "$age_days" "$wt" >>"$DELETED"
  else
    note_anomaly "rm -rf failed: $nm"
  fi
done <"$WORKTREES"

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
  VERB="WOULD DELETE"; HEADLINE="dry run — nothing was removed"
else
  VERB="DELETED"; HEADLINE="live run"
fi

del_count="$(wc -l <"$DELETED" | tr -d ' ')"
skip_count="$(wc -l <"$SKIPPED" | tr -d ' ')"
total_kb="$(awk -F'\t' '{s+=$1} END{printf "%d", s+0}' "$DELETED")"

echo "prune-stale-node-modules — $HEADLINE"
echo "  root:           $ROOT (max depth $MAX_DEPTH)"
echo "  cutoff:         no activity for more than $DAYS days"
echo "  scope:          $([ "$LINKED_ONLY" -eq 1 ] && echo 'linked worktrees only' || echo 'all worktrees (primary clones + linked)')"
echo "  worktrees seen: $scanned  (with package.json + node_modules: $candidates)"
echo

if [ "$del_count" -gt 0 ]; then
  echo "$VERB ($del_count):"
  sort -t"$(printf '\t')" -k1,1nr "$DELETED" |
    while IFS="$(printf '\t')" read -r kb age path; do
      printf '  %10s  %5s days  %s\n' "$(human_kb "$kb")" "$age" "$path"
    done
  echo
else
  echo "$VERB: nothing qualified."
  echo
fi

if [ "$skip_count" -gt 0 ]; then
  echo "Kept — active within $DAYS days ($skip_count):"
  sort -t"$(printf '\t')" -k1,1nr "$SKIPPED" |
    while IFS="$(printf '\t')" read -r age path; do
      printf '  %5s days  %s\n' "$age" "$path"
    done
  echo
fi

if [ -s "$ANOMALY" ]; then
  echo "Anomalies:"
  sed 's/^/  /' "$ANOMALY"
  echo
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Total that would be freed: $(human_kb "$total_kb")  across $del_count worktree(s)"
else
  echo "Total freed: $(human_kb "$total_kb")  across $del_count worktree(s)"
fi

exit 0
