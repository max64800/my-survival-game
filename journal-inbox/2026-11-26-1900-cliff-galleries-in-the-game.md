## Nov 26 — F913 step 5: ruin 13, the Cliff Galleries, is in the game

**What we did:** The owner had OK'd the Cliff Galleries' ruin page (dwarf homes up a tall cave wall, stone below,
brick above). This chat put the ruin into real worlds, the same way as the Mine-head Works (ruin 12).
- **`src/world/ruin_cliff_galleries.gd`** (new): finds its cavern (the tallest Mossy caverns first, then the widest,
  about 320 m from the start, never another grand ruin's), and tries spots slid back to a cave wall plus a grid. Each
  spot is scored by 64 "is this rock?" samples: the cliff behind it (up to 22 m), the shelf under the tower (10.75 m
  up), the ledge under the Ledge House (4.5 m up), the crack's walls, the floor under the hall. Missing rock and rock
  in the way of the buildings both cost points. Then the world keeps the whole spot clear (the placement rule) and
  takes out any stone column in it.
- **Rock fill:** a natural cave almost never has a flat shelf exactly 10.75 m up. So when it builds, it first fills
  only the empty bits under the shelf and the ledge with balls of rock (saved like digging, the same trick as
  Brickcrown's rock lump). In real worlds the spot picker chooses places that already have most of that rock
  (41 to 58 of 64 samples on the three test seeds). Then it digs the blueprint's air (the niches in the cliff),
  the crack under the bridge (ramping up in front so you can walk out), and the yard in front.
- **`tools/ruins/make_cliff_galleries_ruin.py`** (new): the page's exact dice (same random seed, same order), then
  "made sound": no doors, nothing floating, rubble only on floors or ground. The gallery's middle lies as tipped
  rubble on the hall's roof, the bridge's far floor sags, the lookout's roof corners lean. Chests: the best (copper)
  in the tower's lookout, stone chest + strongbox in the Stone Hall, small chest + pigeonholes in the Ledge House,
  quiver rack in the tower, coal scuttle in the shed. Torches and rock beetles. 643 pieces, 0 rule problems.
- **Wired in** (one or two lines each): recipes.gd, ruin_tests.gd (a Ruins test world), main.gd, cave_maker.gd,
  loot_props.gd, test_ruin_loot.gd.
- **`tests/test_ruin_cliff_galleries.gd`** (new, 7 tests): plan whole, stands up, matches the blueprint, ruin rules,
  cave shape (and the fill never sticks out past the shelf or ledge), keep-clear on seeds 42, 7 and 1234, and a full
  rebuild that teaches the blueprint. All pass. A muted test game built it with no script errors.

**Mistakes and hurdles:**
- **Spot search too slow on seed 7** (8.7 s, the limit is 8). Fix: the grid round the cavern's middle went from
  9×9 to 7×7 spots (the "slid back to the wall" spots are the good ones anyway).
- **The rebuild test got stuck: "someone is in the way".** On seed 42 the natural floor in front was 2.5 m higher
  than the ruin's floor (the yard is dug out), so none of the chest spots counted as level ground. The chest used its
  backup spot, 2 m from the grand stair, and the test dwarf standing next to it blocked the stair's rebuild.
  Fix: the backup spot is now 4 m out from the stair's foot.
- **The full test run found two more:** (1) the cliff stairs had no wall on the cliff side (the stair rule 1.13 wants
  walls on both sides, so no dark slit opens between the steps and lumpy rock): three brick wall pieces added, plan
  rebuilt (645 pieces, 0 problems). (2) The Ruins test world check wanted flat ground all round the ruin's middle,
  but the three wall-built ruins (Brickcrown, Mine-head, Cliff Galleries) have their cliff right behind it: the check
  now looks only in front for them, with a 0.5 m dip allowed (their floor covers it).
- **Grep tripped over a `[`** in a pattern (a shell slip, re-run with a plain pattern).
- **Note for the owner:** the committed Mine-head code already leans on another chat's not-yet-committed Brickcrown
  work (ground_y, brickcrown_spot), so the GitHub copy only builds once that chat commits too.

**Left:** the owner's play test (the rock under the shelf and ledge should look like cave rock; the tower needs a
short build across the fallen gallery to reach the lookout chest).
