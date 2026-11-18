---
name: bold-plate-kit10
description: Max on 021 v1 (2026-10-18) — graphite kit7 box "looks very software / vibe coded"; use kit10 BoldPlate: bright colour-block plate, colour sweeps + slide hand-offs, Anton/Inter 900, NO emojis, bold outlined behind-head words
metadata:
  type: feedback
---

Max on 021 v1 (2026-10-18):
- the graphite box "looks very software... very vibe coded, just a box";
- he wants "color theory... bigger and brighter... big bold bright as some of the other TikToks";
- emojis look "vibe codey";
- the animations had "no transition between animations";
- the behind-head serif words "clipping a little bit... not bold and big";
- the useless "but" kicker;
- chips sticking out of the plate (Search Console / Google Ads);
- rows touching the box edge (What's broken / In plain English).

**Why:** the dark frosted plate plus emoji chips had become his "AI slop" look again ([[culture-video-feedback]] rule 6).

**How to apply (default plate from now on):**
- `editor/motion/src/kit10.tsx` BoldPlate, wired as the `bold` prop in Edit.tsx; example in work/IMG_4044/plan_021.py.
- ONE plate the whole video. Each beat gets its own saturated iOS colour (blue / green / purple / orange / white / blue), alternating warm and cool. The new colour sweeps out from the centre while the plate morphs size like water.
- Old content slides up and blurs out; new content rises in only AFTER the old has left. One element always carries over (the plate).
- Heavy type: Anton for headlines and pills, Inter 900 for rows. White pills with black Anton on colour; tags as coloured Anton pills.
- **No emojis.** Use drawn shapes instead: a red "?" badge, a thick strike bar, an arrow and a check (SVG).
- Fixed pixel layouts: rows stacked vertically when two chips would be too wide, and at least 24 px padding on every side. Check at full size.
- Behind-head words: kit9 EdBig with `font: "anton"` and `stroke: 6-7` (thick dark outline), big (EXPERT 300 px), only the bottom ~15% behind his hair. Use `MATTE_FIRM=1 editor/matte.py` for a crisp hair edge. No small kickers.
- Keep the 80/20 rule ([[own-style-80-20]]): zoom punches, the wall-colour soft split and rotating caption styles stay.
- **No white text for the big behind-head words** (Max, 2026-10-18: "I prefer not to use white text... maybe like bright orange... some kind of very color that's gonna stand out"). Use bright, saturated colours (orange #FF9F0A, yellow #FFD60A, red #FF3B30, green #30D158, pink #FF2D55) with the thick dark outline, picked per video so they stand out against his wall.
