---
name: vibe-coders-edit-kit7
description: "How video 013 (vibe coders, IMG_3882) was built — kit7 plate, face-fitted placement, stills.mjs QA tool"
metadata:
  node_type: memory
  type: project
  originSessionId: db80a14d-def3-49f8-b467-bfcb8a1d4bc8
  modified: 2026-10-11T18:31:48.357Z
---

Video 013 "I hate vibe coders" (IMG_3882), edited 2026-10-11 → out/IMG_3882_master_v2.mp4 (76.8 s, Edit60). Max asked for the full edit with no check-ins ("you do the entire of it").

New pieces worth reusing:
- **kit7.tsx `VibePlate`**: one graphite plate morphing per beat, per-state `scale` (fitted to the room above his head), `jump` (fade-out/pop-in instead of a glide that would cross his face), `bg` (gold dot hand-off), a 1-2-3-4 stepper through-line, goo-merge buttons (keep one fill colour during the merge or it looks blurry).
- **Plate placement from the face track** (work/IMG_3882/plan_vibe.py): plate bottom ≤ face-box top + 40 (p10 per span); when he's filmed small and high, the plate drops under his chin and captions are capped at 2 lines there.
- **`levelsBottom`** prop in Edit.tsx: captions anchored to y 1410 when his face fills the frame (chin often at 1260-1400).
- **editor/motion/stills.mjs**: one bundle → many QA stills (`node stills.mjs props.json outdir 1.2,3.4,...`).
- Cut from **runs.json** (per-run transcription, work/IMG_3882/runs_transcribe.py), end lines on the last word + 0.12 s (run ends include breaths → the pause Max heard after "one of them").

Filming note: his hook takes include a deliberate push-in toward the lens (blurred, head at the frame top at the end). Takes 1-2 say "I'm the one", takes 3-4 "one of them".

Related: [[edit-hard-rules]], [[qa-every-render]], [[culture-video-feedback]], [[shapes-are-one-tool]], [[keep-morph-and-zoom-punches]].
