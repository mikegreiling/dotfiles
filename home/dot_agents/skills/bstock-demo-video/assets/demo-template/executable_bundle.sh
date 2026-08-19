#!/usr/bin/env bash
# Produce a lean, portable QA bundle of THIS demo project (a teammate extracts it,
# runs `npm ci && npx playwright test`, and reproduces the video).
# Excludes the entire node_modules (rebuilt from package.json), all outputs, and secrets.
# Usage: bash bundle.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
NAME="$(basename "$ROOT")"
OUT="$ROOT/../${NAME}-bundle.zip"
rm -f "$OUT"

( cd "$ROOT" && zip -r -q "$OUT" . \
    -x 'node_modules/*' '.auth/*' 'test-results/*' 'videos/*' \
       'playwright-report/*' 'creds.json' '*.zip' '.DS_Store' )

echo "Bundle: $OUT"
unzip -l "$OUT" | tail -n +2 | awk '{print $4}' | grep -vE '^$' | sort
echo
echo "Sanity: node_modules present in zip? -> $(unzip -l "$OUT" | grep -c 'node_modules/' || true) (must be 0)"
