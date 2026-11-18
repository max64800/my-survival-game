---
name: gold-standard-016
description: Max called video 016 (website ego, IMG_3912, out/IMG_3912_master_v2.mp4) the "gold standard" on 2026-10-14. Use it as the reference short-form edit.
metadata:
  type: feedback
---

Max on 2026-10-14: "I think this is a gold standard now". The video is out/IMG_3912_master_v2.mp4 (29.3 s); its pipeline lives in work/IMG_3912/.

What makes it the standard:
- **Script:** 28-30 s with the payoff in line 2 ("Your clients don't really care").
- **Cut:** a hand-picked take per line in build_edl.py, with an override start that trims lead-ins like "Now". Line ends land on the last word + 0.14 s, giving ~0.2 s between sentences. The cut was checked word for word with whisper.
- **Plate:** ONE kit7 plate at y 262 that morphs per beat, and each graphic explains its line: site → "0 clients" → freezes grey; question + 5 s ring → tab closed; 2-jobs checklist that grows (same scene, size-only morph = content stays steady) and gets "pretty" struck; CLIENT|EGO toggle; comment box typing the keyword. Every item appears on its spoken word.
- **Captions:** die-cut stickers placed LOW on the chest (slots y 1400/1495/1590) with coloured key words and no SFX.
- **Zoom and sound:** zoom punches on key words. 2-3 signature sounds per video (glitch / tick / crumple), with low_hit only on the 3 biggest reveals.
- **Audio:** muffled lines get a clarity EQ through cut.py --force (Max listened and accepted it).

**How to apply:** start every new short from work/IMG_3912 (build_edl.py, plan_016.py) and keep this structure and quality bar. Do rotate the caption STYLE ([[caption-style-rotation]]) and the scene designs, because a gold standard doesn't mean identical. Related: [[edit-hard-rules]], [[motion-taste-rules]], [[platform-safe-zones]].
