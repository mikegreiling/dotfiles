#!/usr/bin/env bash
# Turn Playwright's raw .webm recordings into lean, trimmed .mp4s + a combined clip.
# Usage: bash encode.sh   (run after `npx playwright test`)
set -euo pipefail
FF="$(command -v ffmpeg || true)"
[ -z "$FF" ] && { echo "ffmpeg not found (brew install ffmpeg)"; exit 1; }

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/videos"; rm -rf "$OUT"; mkdir -p "$OUT"

# Trim the leading white/blank (SSR/hydration) by negating + black-detecting,
# then input-seek past it. Encode H.264 yuv420p faststart for universal preview.
trim_encode() {
  local src="$1" out="$2" t
  t=$("$FF" -i "$src" -vf "negate,blackdetect=d=0.1:pix_th=0.10" -an -f null - 2>&1 \
      | grep -oE "black_start:0 black_end:[0-9.]+" | head -1 | grep -oE "[0-9.]+$" || true)
  [ -z "$t" ] && t=0
  echo "  $out  (trim ${t}s)"
  "$FF" -y -ss "$t" -i "$src" -c:v libx264 -pix_fmt yuv420p -movflags +faststart "$OUT/$out" >/dev/null 2>&1 \
    || echo "  WARNING: encode failed for $src — skipping"
}

# One mp4 per scenario, named by the test-results dir (Playwright names it after the test).
i=0
declare -a MADE=()
while IFS= read -r webm; do
  i=$((i+1))
  name="$(printf '%02d' "$i")-$(basename "$(dirname "$webm")" | sed 's/-chromium$//' | cut -c1-60).mp4"
  trim_encode "$webm" "$name"
  MADE+=("$name")
done < <(find "$ROOT/test-results" -name video.webm | sort)

# Combined clip (concat in order).
if [ "${#MADE[@]}" -gt 1 ]; then
  : > "$OUT/list.txt"
  for f in "${MADE[@]}"; do echo "file '$f'" >> "$OUT/list.txt"; done
  ( cd "$OUT" && "$FF" -y -f concat -safe 0 -i list.txt -c copy combined.mp4 >/dev/null 2>&1 && rm -f list.txt )
  echo "  combined.mp4"
fi
echo "Done → $OUT"
