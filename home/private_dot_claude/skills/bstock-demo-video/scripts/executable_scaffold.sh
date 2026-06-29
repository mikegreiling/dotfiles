#!/usr/bin/env bash
# Lay the demo-template into a target repo as <repo>/demo, git-ignore it, install deps.
# Usage: bash scaffold.sh /path/to/repo-or-worktree
set -euo pipefail
REPO="${1:?usage: scaffold.sh <repo-dir>}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$SKILL_DIR/assets/demo-template"
DEST="$REPO/demo"

if [ -d "$DEST" ]; then
  echo "note: $DEST already exists — not overwriting. Edit it in place or remove it first."
else
  mkdir -p "$DEST"
  # copy template incl. dotfiles, but never stale outputs/secrets
  ( cd "$TEMPLATE" && cp -R ./. "$DEST/" )
  echo "scaffolded → $DEST"
fi

# Keep demo/ out of the repo's git (shared common-dir exclude works for worktrees too).
COMMON="$(cd "$REPO" && git rev-parse --git-common-dir 2>/dev/null || true)"
if [ -n "$COMMON" ]; then
  mkdir -p "$COMMON/info"
  grep -qxF 'demo/' "$COMMON/info/exclude" 2>/dev/null || \
    printf '\n# bstock-demo-video (uncommitted)\ndemo/\n' >> "$COMMON/info/exclude"
  echo "git-excluded: demo/"
fi

echo "installing Playwright in $DEST …"
( cd "$DEST" && npm install >/dev/null 2>&1 && npx playwright install chromium >/dev/null 2>&1 )
echo "done. Next: edit demo/demo.config.ts, set BSTOCK_DEMO_PASSWORD, ensure VPN + app at baseUrl, then: (cd demo && npx playwright test)"
