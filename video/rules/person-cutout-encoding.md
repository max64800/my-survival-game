---
name: person-cutout-encoding
description: "Person cut-out (person.webm) must be built from a CONSTANT 30 fps cut and encoded VP9 with -auto-alt-ref 0, or a ghost head and black blotches appear"
metadata:
  type: project
---

Found on 024 (2026-10-21): the behind-head layer showed a second "ghost" head next to Max and black blotches around his hands.

There were two causes:
1. `cut.py` output is variable frame rate (avg 29.97 fps). `matte.py` writes a fixed 30 fps matte, so the two drift apart.
2. VP9 with an alpha channel needs `-auto-alt-ref 0`. Without it the alpha frames don't decode (libvpx "Failed to decode frame"), and Remotion shows stale frames.

**How to apply (every short with a person cut-out):**
```
ffmpeg -i out/X_cut.mp4 -vf fps=30 -c:v libx264 -crf 14 -pix_fmt yuv420p -c:a copy out/X_cut30.mp4   # use THIS as public/vX/cut.mp4
MATTE_FIRM=1 editor/.venv/bin/python editor/matte.py out/X_cut30.mp4 work/X/matte.mp4
ffmpeg -i out/X_cut30.mp4 -i work/X/matte.mp4 -filter_complex "[1:v]format=gray[m];[0:v][m]alphamerge,format=yuva420p" -an -r 30 \
  -c:v libvpx-vp9 -pix_fmt yuva420p -auto-alt-ref 0 -b:v 8M -deadline good -cpu-used 4 -row-mt 1 editor/motion/public/vX/person.webm
```
Then check that the frame counts match (`ffprobe -count_frames`), and check a still where he moves.

Also: Remotion bundles copy all of `public/` (about 6 GB) into /tmp, and that filled the disk. `stills.mjs` now honours `PUBLIC_DIR`. Point it, and `remotion render --public-dir`, at a slim folder of hard links (sfx, eqt, lib, vX). Related: [[gradient-glass-style]].

**Update 2026-10-25 (Facebook ads):** for behind-head text use `editor/matte_rvm.py` (Robust Video Matting, ONNX, model in editor/models/rvm/) instead of `matte.py`: the mediapipe matte lags ~1 frame and its head edge is off by thousands of px on full-body shots, so letters "clip" through the head. RVM: same CLI, ~17 s per 5 s clip on CPU. Also keep hero words to a light overlap (top ~8% of the hair).
