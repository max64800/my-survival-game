---
name: graphics-layout-qa
description: "HARD rules after Max hated 019 v1 graphics (2026-10-16) — no touching boxes, no jitter, colour + picture on every card, real platform logos, full-size still QA before render"
metadata:
  node_type: memory
  type: feedback
  originSessionId: db80a14d-def3-49f8-b467-bfcb8a1d4bc8
  modified: 2026-10-16T14:24:50.261Z
---

Max on video 019 v1 (2026-10-16): "I don't know why this video was so bad in terms of animations... implement some rules that it won't ever happen again."
What went wrong: the AI answer bubble touched the app tiles; "100%" touched the curve and the title; "backstory starts" touched the title; dashboard tiles touched the bottom of the plate; 3-5 s jittered; the dashboard was text-only black and white with too much text; emoji stood in for the YouTube/TikTok/Instagram logos.

**Why:** these were all layout bugs I could have caught. I checked downscaled contact sheets (360 px wide, from half-size stills), where a 5 px collision is invisible.

**How to apply (every edit, before the render):**
1. **Gaps:** keep ≥ 24 px between any two elements, and ≥ 24 px (aim for 30) between content and the plate edge. Axis labels go OUTSIDE the chart area. Tags and chips go in empty chart space, never over a title.
2. **No jitter:** never centre a row (flex/justify center) whose width changes over time, e.g. typing dots, counters or text swapping in. Use absolute positions or fixed-width boxes, and left-align anything that changes. Use tabular numbers for counters.
3. **Colour and a picture on every card:** every plate state needs a coloured visual (logo, icon, chart, tinted tile). No text-only grey/white cards. Keep it to about 8 words per card. Big numbers count up.
4. **Real platform logos:** when he names YouTube, TikTok or Instagram, use the real app icons (kit7 `AppLogo` id yt/tt/ig, Simple Icons paths), not emoji. This overrides the old "no brand logos" rule for these platforms. Other brands still get no logos, and there's still no EQT end card on non-EQT videos.
5. **Still QA at FULL size:** `stills.mjs` now renders 1080×1920 (times are comma-separated: `t1,t2,...`). Render each state's fully built moment, plus mid-merge moments. Crop the plate at 1:1 and look for touching edges, cramped bottoms and overflow before starting the render.
6. **Captions:** no faint unsaid words (capWord now hides them at opacity 0 but keeps their space). Use strong shadows so white text reads over his white shirt.

Related: [[motion-taste-rules]], [[culture-video-feedback]], [[caption-style-rotation]], [[vibe-coders-edit-kit7]].
