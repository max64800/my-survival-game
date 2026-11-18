---
name: animation-ambition
description: Max's animation preferences for video edits: custom per-script visuals, flat clip-art stickers (not rotating 3D objects), big words behind the head, full-screen kinetic-type cutaways for key phrases
metadata:
  type: feedback
---

What Max wants in animated edits (updated 2026-10-05):
- Something on every sentence: either a big keyword behind his head (person matte, `editor/matte.py`) or an animation.
- Objects as flat clip-art stickers (die-cut white border, soft shadow) that slap or fly in and land at an angle, staggered diagonally. NOT rotating/spinning 3D models: he said the 3D wine, cheese and bus "don't look good". 3D licence cards, coins, pie and the paper plane were accepted.
- Clean premium motion (eased, no bouncy springs), consistent style: Anton + Inter, white/yellow (#FFD600) text with thick black outline (reads on light walls and busy desks), dark glass chips.
- Full-screen cutaways for some key phrases: cut away from his face to a clean animated kinetic-type card (white background, words animating in), like @fabriziafranceschetti's reel (instagram.com/reel/Ddyxzt4AceF). Use sparingly for punchlines/verdicts.
- Never draw copyrighted characters (e.g. Spider-Man, Hulk, Marvel logos); evoke them with original art (spider web, swing-on-a-web-strand motion).

**Why:** his feedback across the mattress video (v2 rated 9/10), the UK wine-shop master edit and the Spider-Man review (2026-10-03 to 10-05).

**How to apply:** the overlay system lives in `editor/motion/` (Remotion: `Overlay3D.tsx` stickers/big/labels/3D, `OverlayV2.tsx` Big + badges/chips); render behind + front layers with `--gl=angle`, composite under/over the matte. Ask him to film further back against a plain wall for best results. See [[after-edit-cover-prompt-and-caption]].
