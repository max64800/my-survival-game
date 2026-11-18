---
name: platform-safe-zones
description: No-go zones for captions/big words on TikTok, Instagram Reels and YouTube Shorts (1080x1920); enforced in editor/motion/src/Edit.tsx SAFE
metadata:
  type: feedback
---

Max noticed (2026-10-06, Spider-Man video) that some big words and captions were hidden under the TikTok/Instagram menus. Keep all captions, big words and key text out of the platform UI zones.

Strictest combination of the three platforms on 1080x1920:
- Top 250 px (Reels tab bar; TikTok ~130, Shorts ~180).
- Bottom 500 px, so key text must end above y≈1420 (Reels ~420-500: name, caption, audio; TikTok ~484; Shorts ~390).
- Right action rail 180 px (x > 900) in the lower half (y 700-1420): likes, comments, share.
- Left 60 px.

**Why:** Platform overlays cover those areas, so text placed there gets hidden.

**How to apply:** `SAFE` + `keepSafe()` in editor/motion/src/Edit.tsx push elements out automatically. Captions are anchored to the bottom of the safe area (bottom edge at y≈1410, right margin 180). Render stills with `"guides": true` in the props to see red overlays of the zones. Sources: postplanify / adaptlypost / brandeal 2026 safe-zone guides. Related: [[editing-taste-profile]].

**Update 2026-10-14 (video 016, Max):** captions at y 1120-1405 were "way too high… so much dead space at the bottom and at the top… way too centered". He accepts going a little into the bottom zone. New default: the caption block sits on his chest, with its bottom edge at about y 1620-1640 (016 sticker slots y 1400/1495/1590). Keep it clear of the right rail, and keep the plate high (y 262).
