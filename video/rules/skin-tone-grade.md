---
name: skin-tone-grade
description: Max wants warm, natural skin, not pale/white; editor/cut.py GRADE changed 2026-11-10
metadata:
  type: feedback
---

Max on 2026-11-10, comparing his posted 035 frame with a reference creator: "adjust some colors so I am not as white but I am natural."

The old cut.py grade made him too pale. It desaturated reds by 0.35 and set overall saturation to 0.95.

The new default GRADE in `editor/cut.py` is HLG → BT.709, then `colortemperature=5200:mix=0.7`, then `eq contrast 1.08, saturation 1.12, gamma 0.93`. It gives warmer, golden, slightly richer skin.

**Why:** pale skin looks washed out next to warm-toned creators in the feed.

**How to apply:**
- Never desaturate skin reds again.
- If footage still looks pale, warm it further rather than cooler.
- Check one still against the reference before cutting.

Related: [[edit-hard-rules]].
