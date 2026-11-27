## Nov 25: Brickcrown Keep goes in the game (F895, ruin 11 step 4)

**What we did**
- `tools/ruins/make_brickcrown_ruin.py` turns the owner-approved 3D page's breakage (same dice, same heights) into the
  game's ruin plan `blueprints/ruins/brickcrown_ruin.json`. 1046 pieces, 11 rubble, 4 chests (the best one on the
  right tower's top), 5 loot props, 5 rock beetles. It also makes the plan sound: no doors, nothing hanging, no ladder
  to nowhere, and rubble lies on the floors it fell onto.
- `src/world/ruin_brickcrown.gd` (copied from the Smeltery's). It finds a tall cavern whose rock stands behind the keep
  and over the courtyard. Then it grows the rock lump under the right tower, digs the dip under the bridge, and digs
  the courtyard as a cave room. The courtyard has a wobbly outline and a bumpy dome, so it looks natural and never like
  a box (owner's choice).
- The owner said "add a wooden one too": a new **Wooden Brickcrown Keep** blueprint. Rebuilding the ruin teaches both.
- `RuinTower` got `ground_y`, because this ruin's ground is 2.25 m up its own box (its dip goes below the ground).
- It is wired into the cave picker, the game start, Dev menu > Ruins (layout 1109) and the loot list.
- New tests in `tests/test_ruin_brickcrown.gd`:
  - the plan, and that it stands up
  - it matches the blueprint, and follows the ruin rules
  - the cave shape: the courtyard outline wobbles and its roof is uneven
  - the placement rule on 3 worlds
  - a full rebuild in stone

**Mistakes and hurdles**
- My Python "will it stand" check missed 5 brick pieces on top of the left tower's broken ring. The game's own strength
  test caught them. The ruin maker now drops that ring too, so the tower ends one ring lower than on the page.
- My first courtyard dig was centred too far left. It would have dug away the rock round the two little rooms that
  are meant to be inside the rock. I measured where the paving really is (x 9 to 23.7), then moved and clipped it.
- The kept-clear circle missed 4 corner cells of the front yard on every world. I trimmed the yard to what the ruin
  actually digs.
- **The Rebuilding Chest floated 1.5 to 2.5 m up.** The "find the floor" helper only knows the cave as it was first
  made, not what the ruin dug away. Fixed in two ways:
  - The yard is now dug all the way down to the ground.
  - `RuinTower._add_rebuild_chest` lets the chest settle down onto the real ground, and never trusts a floor far from
    the ruin's own ground.
  - A test checks the chest is on the ground.
- The test copied from the Smeltery skipped the new "grow the lump" step, so I changed it to run that step too.
- Another chat's commit picked up my one-line `recipes.gd` change by accident. That's harmless (an empty list).
- The robot's screenshots failed the first time because the folder didn't exist yet.
- The Python edit tool doesn't match tab-indented code, so I made the edits with small scripts instead.
