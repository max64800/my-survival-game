---
name: motion-library-2026-10-12
description: "The 100-demo motion-graphics library + 20 caption styles built overnight 2026-10-12 for Max to score; where the code, renders and scores live"
metadata:
  node_type: memory
  type: project
  originSessionId: db80a14d-def3-49f8-b467-bfcb8a1d4bc8
  modified: 2026-10-11T19:59:53.966Z
---

Overnight 2026-10-12 Max asked for (1) 100 motion-graphic demos (10-15 s each), (2) 20 caption styles on his own voice (incl. Kelssie + a crumpled-paper comic unfold), (3) study of 26 edit TikToks. He'll score each 1-10 in the morning; winners become the reusable library ("use at your discretion on every video").

- **Code**: `editor/motion/src/lib/` — `common.tsx` (shared kit: Backdrop/BackPerson clips of Max, Plate, Odo, GooDefs, Sfx/Sounds, palette `C`, SAFE), families `m1.tsx` shape stories & liquid morphs, `m2.tsx` 3D shape stories (@remotion/three), `m3.tsx` data & UI, `m4.tsx` kinetic type & transitions (words behind head), `m5.tsx` real-estate & money explainers. Captions: `src/caps/` (`capcommon.tsx` = 11.6 s clip of his vibe-coders voice + WORDS; `c1.tsx`, `c2.tsx`). Brief: `work/library/SPEC.md`.
- **Compositions**: `L-<id>` and `C-<id>` (registered in Root.tsx from the registries). Tools: `node libstills.mjs <dir> L-m1-03:1,5` (stills), `node renderLib.mjs [prefix]` (batch, skips existing; `work/library/render_all.sh` renders all in sequence — never queue renders with pgrep waiters, they match their own command line and deadlock). Both use `public_lib/` (54 MB) instead of `public/` (5 GB) and delete their temp bundle — stale Remotion bundles once filled the disk (39 GB).
- **Renders**: `out/library/motion/<id>.mp4`, `out/library/captions/<id>.mp4`; gallery with scoring + export: `out/library/index.html` (rebuild: `python3 work/library/build_gallery.py`).
- **Caption scores, batch c2 (Max, 2026-10-12)** — code in src/caps/c2.tsx:
  - WINNERS: c2-04 Chat bubbles 8/10 ("very unique"), c2-07 Glass pills stepper "really good, similar to 4" (~8).
  - KEEP for mixing several caption formats in one video: c2-08 Flying 3D words 7, c2-09 Highlighter tape 7, c2-10 Colour punch 7 (border flash removed at his request: no frame border matching the caption colour), c2-01 Karaoke sweep 6.
  - REJECTED: c2-02 Terminal, c2-03 3D slam (too fast), c2-05 Word ladder (barely visible), c2-06 Outline→fill (weird, fast, not visible).
  - Lesson: he rejects captions that are fast, thin/hard to see, or gimmicky; he likes captions with a container (bubble, pill, card) and a clear reading order.
  - Rotation plan (recommended to him): one primary caption style per video, rotating the winners; at most one "accent" style per video for a specific beat (e.g. chat bubbles for a quoted conversation, pills for a list).
- **Caption scores, batch c1 (Max, 2026-10-12)** — code in src/caps/c1.tsx:
  - KEEP: c1-09 Die-cut stickers 7 → "9/10" once fixed (done: no SFX on every new caption, no see-through preview letters, sticker grows word by word); c1-03 Kelssie twist "depth pull" 7; c1-07 Behind the head (huge navy setup words on the wall, payoffs in front) 7; c1-08 Magazine editorial 5.
  - REJECTED (removed): c1-01 our house "levels" captions 4 ("it's basic"), c1-02 Kelssie recreation 4, c1-05 serif+script stack 4, c1-04 paper unfold 1, c1-06 quiet-luxury one-word 1, c1-10 marker scribble 1.
  - So: the "levels" style in Edit.tsx is no longer the default. Default caption pool = c2-04 chat bubbles, c2-07 glass pills, c1-09 stickers (top), then c1-03, c1-07, c2-08, c2-09, c2-10 (no colour border), c2-01. No caption SFX on every new line.
- **Motion scores (2026-10-12)**: all in `work/library/scores-2026-10-12.json`; rules + fix list in [[motion-taste-rules]]. 21 rejected items (≤4) were removed from the code (backup of the pre-deletion files: work/library/code_backup/); all reviewed renders were deleted. Library now: 83 motion demos + 16 caption styles (c1 batch still to be scored).

Related: [[vibe-coders-edit-kit7]], [[edit-research-2026-10-12]], [[motion-flow-rules]], [[shapes-are-one-tool]].
