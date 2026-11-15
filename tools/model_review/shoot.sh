#!/bin/bash
# Photo sheets of 3D models: each model from 4 sides (front, side, back, from above), 3 models per sheet.
# Usage: from this folder, with a web server running here that also serves the models:
#   ln -s ../../assets/models models; python3 -m http.server 8765 --bind 127.0.0.1 &
#   ./shoot.sh list.txt <prefix>     (list.txt = one "folder/name" per line, e.g. stations/anvil)
# Set CHROME to the Chrome program (default: the macOS path). Sheets go to sheets/<prefix>_NN.png.
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
mkdir -p sheets; n=0; split -l 3 "$1" "tmp_$2_"
for part in tmp_$2_*; do
  f=$(paste -sd, "$part"); c=$(wc -l < "$part" | tr -d ' ')
  "$CHROME" --headless=new --use-angle=swiftshader --enable-unsafe-swiftshader --user-data-dir="$PWD/.chrome_$2" --hide-scrollbars \
    --window-size=1200,$((c*322)) --virtual-time-budget=400000 --screenshot="sheets/$2_$(printf %02d $n).png" \
    "http://127.0.0.1:8765/render.html?f=$f" >/dev/null 2>&1
  echo "$2_$(printf %02d $n): $(paste -sd' ' "$part")" >> sheets/index.txt
  rm "$part"; n=$((n+1))
done
