#!/bin/sh
# env/verify.sh：以低畫質（480p15）渲染兩個驗收場景並檢查輸出。
set -eu
TOOLS="${TOOLS:-/workspace/tools}"
SCRATCH="${SCRATCH:-/workspace/scratch}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck disable=SC1091
. "$TOOLS/env.sh"

OUT="$SCRATCH/out/verify"
rm -rf "$OUT"
mkdir -p "$OUT"
cd "$SCRIPT_DIR/tests"

fail=0
for pair in "text_scene.py ChineseText" "math_scene.py FormulaTest"; do
    set -- $pair
    file=$1
    scene=$2
    if ! manim render -ql --disable_caching --media_dir "$OUT/media" "$file" "$scene" >"$OUT/$scene.log" 2>&1; then
        echo "FAIL render $scene"; tail -30 "$OUT/$scene.log"; fail=1; continue
    fi
    mp4=$(find "$OUT/media/videos" -name "$scene.mp4" | head -1)
    if [ -z "$mp4" ]; then echo "FAIL no mp4 for $scene"; fail=1; continue; fi
    info=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=codec_name,width,height,r_frame_rate:format=duration \
        -of default=nw=1 "$mp4" | tr '\n' ' ')
    echo "OK $scene: $info"
done
rm -rf "$OUT"
[ "$fail" -eq 0 ]
