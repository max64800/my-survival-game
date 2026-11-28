## Nov 28: Ruin 15, the Pillar Spiral, goes into the game (F942 step 5)

**What we did**
- Wrote `tools/ruins/make_pillar_spiral_ruin.py`. It turns the whole blueprint into its ruin, the same way the
  owner-approved page did: the left flight of the wooden stair has fallen, one kiln chimney is broken, roofs have holes,
  doors rotted away, and stones from the ceiling lie on the terrace. It also adds 4 chests (the best one, copper, in the
  Eyrie at the top), 4 things to loot, 7 crystal torches and 5 rock beetles. Result: 1,110 of 1,164 pieces stand,
  0 rule problems.
- New ruin class `src/world/ruin_pillar_spiral.gd`, copied from the Cliff Galleries. The owner chose to **grow** the
  rock column, so the ruin grows it: it finds where the ceiling is above the spot, then fills balls of rock from the
  floor up into the ceiling, widening at the top like the blueprint's column. It also grows the Kiln House's rock lump,
  the high shelf behind, and a slab of cave wall behind that. Then it digs the crack under the Arch Bridge (with a ramp
  out the front) and the yard in front of the grand stair.
- Hooked it in everywhere the other ruins are: Dev menu > Ruins (layout 1112), main.gd, cave_maker.gd (the real-world
  spot, picked in a cavern with a ceiling at least 24 m up), loot, recipes, loot test.
- New test file `tests/test_ruin_pillar_spiral.gd` with 7 checks (plan, stands up, matches the blueprint, ruin rules,
  cave shape incl. "never rock where the blueprint wants air", the placement rule on 3 worlds, rebuild). All pass.

**Mistakes and hurdles (and fixes)**
- First plan run: 8 rule problems. The arches were flagged as "nothing holds them up" (arches hold themselves; added
  them to the skip list), and chests, loot and a torch stood on stairs or in walk lines. Fixed by moving each one, using
  the real model sizes.
- The page's sketch removed the left flight's top landing too, which would have left a gap after the Bunk House's top
  door. Kept that landing.
- Godot said "RuinPillarSpiral not declared": a brand-new named script must be registered first (`--import`).
- Two test fails: one rubble stone lay between the hall and the shelf, on ground the ruin didn't count as its own, and
  the shelf's far corners (31 m out) were past the kept-clear circle (29 m). Fixed: the ground now includes a 15 m
  circle round the column, and its reach is 29 m.
- One test run failed because another chat was halfway through editing the monster scripts. A re-run passed.
- The walking robot gave two different reports on two runs: in the second its door-opening didn't work, so every door
  "blocked" it. That was the robot, not the ruin. In the first run, every stair and door walked fine. Its one dip
  (0.7 m on the gatehouse stair) is the robot stepping back onto the first of two flights in a line.
- My F942 claim line looked gone from FEEDBACK.md; it was on a line further down (no F-number on it). Nothing lost.
- Shared files (main.gd, cave_maker.gd, ruin_tests.gd, loot files) also had another chat's uncommitted Brickcrown
  lines, so I committed only my own lines on top of the last committed version.
