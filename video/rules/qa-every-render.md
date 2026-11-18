---
name: qa-every-render
description: After every first render, review the whole video frame by frame, fix every issue found, re-render, and only then hand it to Max
metadata:
  type: feedback
---

**SUPERSEDED 2026-10-13 (Max): "do not review after the first render, remove that from the rules unless I tell you to do it. Once you do the first render tell me and I will review it myself."** → Render ONCE, then hand it to Max immediately; no frame-by-frame QA pass or second render unless he asks. Pre-render stills checks while building are still fine. The text below is the old rule, kept for context only.

Max, 2026-10-10: "Once the first try is generated, view the video frame by frame, spot any issues and then fix them. Add it as a rule."

**Rule:** a first render is a draft. Before showing Max:
1. Extract frames across the whole video (at least 4 fps, plus dense 10-15 fps sheets around every graphic hand-off, the hook and the ending) and look at all of them.
2. Check:
   - text or cards covering his face;
   - empty or blank cards;
   - elements in the platform safe zones (see [[platform-safe-zones]]);
   - captions overlapping graphics or each other;
   - frame-edge lines;
   - wrong words or spelling in captions;
   - odometers resting between digits;
   - glitches in morphs, wipes, the background swap or the logo reveal;
   - the face bubble off-centre;
   - dead air or silences over 0.35 s (also check the audio);
   - loudness (-14 LUFS, peaks under -1 dB).
3. Fix everything, re-render, re-check the changed spots, then deliver with a short list of what was caught and fixed.

**Why:** Max kept finding issues himself (stuck counter, empty box, pauses, red strikes, a dot on his forehead). He wants them caught before he sees the video.
