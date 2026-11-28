## Nov 28: which ruins have junk lying around? (F976)

**What we did:** the owner asked if every ruin has the junk and other made props lying around. I counted, for each ruin plan
in `blueprints/ruins/`, its chests, torches, creatures and props, and looked for its junk file.

**Result:** 13 ruins. Only 4 have floor junk, catalog decor and an old camp outside (Watchtower, Outpost, Spire, Brewhall).
The other 9 have none: 4 have only 4-5 loot boxes (Brickcrown, Cliff Galleries, Smeltery, Pillar Spiral), 4 have furniture
only (Kiln, Manor, Prow Hall, Twin Gate) and the Mine-head has rails, carts and ore baskets. The owner chose: give all 9
junk + decor + a camp, keep their furniture. Logged as F976 for a new chat.

**How junk gets in:** `tools/ruins/ruin_junk.py` (a RUINS entry per ruin: paths, kept spots, pools) writes
`<ruin>_ruin_junk.json`; the game reads it through `RuinJunk.PLANS` in `src/world/ruin_junk.gd` (only 4 ruins listed).

**Mistakes and hurdles:**
- My first count looked for `<ruin>_junk.json`, but the files are named `<ruin>_ruin_junk.json`, so every ruin showed "no
  junk". Fixed by counting again with the right name.
- The owner said "12 ruins"; there are 13 now (the Pillar Spiral is new today).
