---
name: caption-style-rotation
description: Don't reuse the same caption style video after video. Rotate through the top-rated styles; log of which style each video used.
metadata:
  type: feedback
---

On 2026-10-14 (video 016) Max said: "can we not do this or yesterday's captions as often? Let's try some other captions". That meant chat bubbles (014, and v1 of 016) and glass pills (015).

**ARCHIVED (Max, 2026-10-16, after 019 v1): chat bubbles (c2-04) and the orange glass pills (c2-07).** "I don't want you to use the subtitles anymore. Or the orange ones... keep them in the archive." Never use them again unless he asks. The code stays in kit8.tsx.

Log:
- 014: chat bubbles (c2-04)
- 015: glass pills (c2-07)
- 016: die-cut stickers (c1-09), `captionStyle: "stickers"` → `StickerCaptions` in kit8.tsx, built from plan_016.py
- 018 (IMG_3929, lazy superpower): highlighter tape (c2-09), `captionStyle: "tape"` → `TapeCaptions` in kit8.tsx (bottom 1630, strips appear WITH their first word, only spoken words, no SFX), built from work/IMG_3929/plan_018.py
- 019 (IMG_3941+3942, Claude analytics): v1 chat bubbles, which Max rejected; v2 big white "levels" (013 style, levelsBottom 1630), from work/IMG_3941/plan_019.py. Available next: stickers (016) or tape (018) once they're out of the last 2-3; chunks/single/stack; or a new style.

**Why:** a repeated caption look makes every video feel the same.

**How to apply:** pick a style that isn't in the last 2-3 entries of the log, then add the new video to the log. Candidates rated well in the library: c1-03 depth pull, c1-07 behind-head, c2-08/09/10. Most of these exist only in `editor/motion/src/caps/` and need porting to a data-driven component in kit8, the way stickers were. Place captions lower, per [[platform-safe-zones]]. Related: [[motion-taste-rules]].
- 020 (IMG_3993, lazy influencer): v1 "editorial" serif-on-green-bar captions (kit9), REJECTED by Max: they repeated the top text and the growing bar clipped words. v2 = die-cut stickers (016 style), from work/IMG_3993/plan_020.py. Don't use the editorial bar again.
- 021 (IMG_4044, Claude in Chrome): highlighter tape (018 style), from work/IMG_4044/plan_021.py. Next: avoid tape, stickers and levels.
- New style to rotate in (from @itsjakethewizard, batch 8, 2026-10-19): 2-word chunks, heavy all-caps sans with a thick black outline, EACH key word in its own colour (red/green/yellow), mid-chest, plus a small fixed title tag at the top naming the topic. Built 2026-10-19 as kit10 ColorCaps (captionStyle "color").
- 022 (IMG_4073, don't chase AI news): colour-word captions (kit10 ColorCaps, size 84, bottom 1630), from work/IMG_4073/plan_022.py. Next: avoid color, tape and stickers.
- 023 (IMG_4082, second five): die-cut stickers (016/020 style), from work/IMG_4082/plan_023.py. Next: avoid stickers, color and tape.
- 024 (IMG_4087, course guru): kit11 "glide" captions (Inter 800, gradient pill glides word to word, gold pill on key words), from work/IMG_4087/plan_024.py. Next: avoid glide, stickers and color.
- 030 (IMG_4226, game launch): kit12 "quiet" captions (plain Inter 800, 1-4 words, gold key words, bottom 1630), from work/IMG_4226/plan_030.py. The quiet A/B variant fixes the caption style (same as 025/027), so rotation is paused for quiet days until the A/B ends.
- 029 (IMG_4225, vibe coding backlash): highlighter tape (018/021 style, kit8 TapeCaptions, size 60, bottom 1630) on the kit11 variant, from work/IMG_4225/plan_029.py. Next kit11 day: avoid tape and glide.
- 028 (IMG_4235, one word): kit11 "glide" captions (024 style, Inter 800 size 64, bottom 1630) on the kit11 variant, from work/IMG_4235/plan_028.py. Glide was last used on 024 (029 tape, 031 stickers, 033 levels since). Next kit11 day: avoid glide, levels and stickers.
- 032 (IMG_4228, working from home is a trap): kit12 "quiet" captions (plain Inter 800 size 72, 1-4 words, gold key words, bottom 1630) on the quiet A/B variant, from work/IMG_4228/plan_032.py. Card = kit12_score.tsx (home vs office scoreboard).
- 033 (IMG_4229, Palm video disaster): big white "levels" (013/019 style, levelsBottom 1630), kit11 Lagoon card, from work/IMG_4229/plan_033.py. Next: avoid levels, glide and stickers.
- 034 (IMG_4233 + one line of IMG_4230, second brain): kit12 "quiet" captions (plain Inter 800 size 72, 1-4 words, gold key words, bottom 1630) on the quiet A/B variant, from work/IMG_4230/plan_034.py. Card = kit12b.tsx Brain (project dashboard -> passwords found -> rules -> worth it?), Lagoon palette.
- 031 (IMG_4227, cafés with playgrounds): die-cut stickers (016/023 style, size 68, slots y 1420/1515/1610) on the kit11 variant, "Garden" palette (jade -> teal, gold accents), from work/IMG_4227/plan_031.py. Cards = src/cafe031.tsx (place / trio / checks) + kit11 board/comment. Next kit11 day: avoid stickers, levels and glide.
- Nov 8 batch (035-041), one agent per video, cards in src/b1108/b0NN.tsx, plans in work/IMG_43NN/plan_0NN.py:
  - 035 (IMG_4328, Dubai worth it, kit11): colour words (kit10 ColorCaps), "Desert Sunset" palette.
  - 036 (IMG_4329, kitchen island, quiet): quiet captions, "Oak kitchen" palette, floor-plan card.
  - 037 (IMG_4330, sales guy not rich, kit11): highlighter tape, "Sunset Coast" palette.
  - 038 (IMG_4331, does it exist, quiet): quiet captions, "Harbor" palette.
  - 039 (IMG_4334, CTO Vercel bill, kit11): die-cut stickers, "Ember" palette.
  - 040 (IMG_4332, Telegram not Slack, quiet): quiet captions, "Telegram Sky" palette.
  - 041 (IMG_4333, only 3% pay for AI, kit11): big white levels, "Sunset" palette.
  Next kit11 day: avoid levels, stickers and tape (glide or color are free).
