## 2026-11-25: Mine-head Works in the game (F899 step 5, paused)

**What we did**
- New `src/world/ruin_minehead.gd`: the Mine-head Works ruin. It looks for a wide Mossy cavern with rock behind it, digs the cave shape (rock wall, ledge, dip), digs the 8 m shaft and the mine room, then builds the blueprint. The crooked head wheel and the bridge floors in the dip are placed as fallen rubble (a new "fallen" option in ruin_tower.gd).
- Chests (best one in the mine room), junk and creatures through loot_props.gd. Rails and carts are the decor ones.
- World growth keeps out of it (cave_maker reserve) with its test in `tests/test_ruin_minehead.gd`.
- Build menu: a ruin that is both wood and stone now shows one "Stone and wood" card.
- The owner said "pause and commit", so it stopped before the in-game check.

**Mistakes and hurdles**
- Seed 7 found no cavern: the only free Mossy cavern was taken by the Lantern Spire. Fix: fall back to Fungal caverns (at most 3, with a big penalty). Needs the owner's OK.
- The spot search was slow (15 s). A coarser grid lost seed 1234's spot, so I undid that. I used exact early exits and wall-first tries instead (now 7-12 s, still over the 6 s test limit).
- Committing only my own lines: another chat (Brickcrown) had unsaved edits in the same files. I built the files with only my lines in a scratch index. My first script failed because one anchor line appeared twice in ruin_tower.gd, and the file list had Windows line endings.
- This commit leans on the Brickcrown chat's uncommitted lines (ruin_tower ground_y, brickcrown_spot). The game won't load from this commit alone until that chat commits.

**Left:** rerun the test, check in the game, GO PLAY TEST, ask the owner the two questions.
