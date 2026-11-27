## Nov 27 — Abilities on Q/R/T, the 3 abilities made real, max level 91, skill loss on death (F917, Mac)

**What we did** (parts 1+2 of `docs/design/abilities-quality-perks-plan.md`):
- **Keys:** abilities sit on Q / R / T. Q still turns build pieces while the hammer is out, and Q over a bag slot still
  drops the item. The lantern refill moved to *hold* L (a quick tap of L still puts it away). R no longer reloads the
  crossbow: clicking does. The help text, first-time cards and the settings controls list say so.
- **You choose the abilities:** the skills window (K) has 3 key boxes. Drag a ◆ you learned onto a box, or drag
  one box onto another to swap them. An ability you swap in starts its full recharge, so you can't swap to dodge waiting.
  The host checks every change (co-op ready) and saves it. Old saves fill the keys the old way (tree order).
- **Whirlwind** spins the dwarf round once. **Healing Brew** is a red flask you throw where you look (up to 14 m). It
  heals everyone within 5 m of the splash, and a red ring shows how far it reached. **Clan Banner** is planted in front
  of you for 60 s, the host owns it, and everyone within 10 m gets half poison, fire and chill. A gold ring shows the
  10 m.
- **Two new hand-built models** (`tools/asset_forge/builds/ability_props.py`): a fat flask (red brew, copper band,
  glass neck, cork, rope) and the banner (bark pole, crossbar, swallow-tail cloth with the anvil-and-hammer on both
  sides, stones at the foot). Both pass the model checks.
- **Max level 30 → 91.** The same XP curve, so levels 1-30 cost the same as before. Level 91 needs about 673,000 XP
  (30 needed about 64,000). That's "everything, slowly", as the owner chose. Nobody has measured yet how long real play takes.
- **Dying like Valheim:** every skill loses 5% (60 → 57), counting the progress into the next level. After that there is no
  loss for 10 min, and the screen shows "Skills safe from death 9:59". The Grave Walker perk now works: 25% less loss per rank.

**Mistakes and hurdles:**
- main didn't compile on the Mac: the ruin files used `ground_y` / `brickcrown_spot`, which only exist in the Brickcrown
  chat's unpushed work on the PC. Fixed with two one-line local stand-ins that were never committed and were undone
  at the end.
- R already reloaded the crossbow, so moving abilities to R clashed with it. We kept click-to-reload and removed R.
- The old ability test checked "first 3 in tree order", which is the rule we replaced. It was rewritten. Buying a perk
  in the test needs its whole chain of earlier perks first.
- The banner model shimmered twice: first the emblem floated 0.5 mm off the cloth (fixed by starting it inside the
  cloth), then a "wave" bend didn't match between pieces (fixed by keeping the cloth flat).
- The flask first looked pink, so the brew colour was made darker and deeper red.
- The level tests still expected level 30 (29 points), so they were updated to 91 (90 points).
