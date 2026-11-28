## Nov 28 — Zone 1 shrink, part 1 (cave layout 20: F969, F971-F974)

**What we did**
- Made cave layout 20 the new default. Zone 1 (Mossy Hollows) is now 500 m wide; zone 2 stays 800 m. Each zone now has
  its own size (`CaveMaker.half_of`), and the map has one page size per zone (`MapData.page_size`).
- Every cave in zone 1 is made for one thing (`place` tag on each room): the first cave, 13 ruin caverns, the Great
  Hall, 2 Copper Deeps, 11 dungeon caves and 10 small rooms for camps and nests. Fewer and shorter extra tunnels.
- Ruins: each named ruin can only take a "ruin" cavern, and only one ruin per cavern (`ruin_room_free`, `ruin_taken`).
  Their favourite distances shrink with the zone (`dist_scale()`). On seed 42 all 12 ruins found their own cave.
- All rune shrines in zone 1 are open alcoves cut into a tunnel's own wall (none sealed, none floating in a cave).
- Dungeons: Hald, Barrows and Brassgate switched on (`since = 20`). Mossgate Hold goes in the first cave's wall.
  Each built dungeon's cave is placed first, with a block of rock kept free for it (no caves, shrines, pockets or
  tunnels dug into it), and the cave is not reshaped.

**Mistakes and hurdles**
- A shell trick to run Python inline hung the terminal (a stray `cat >` waited for typing). Fixed by writing the
  scripts to files first.
- Only 2 of 7 dungeons fit at first. The dungeons are huge (40-80 m) and the smaller zone left no solid rock. Fixed in
  steps: keep rock for them while laying out caves; stop tunnels leaving a dungeon cave through its back wall; keep
  shrines, geodes, side pockets and old-column rows out of that rock; let the dungeon sit up to 8 m deeper.
- Mossgate kept failing in the first cave: the "walk to the wall" check hit a stone column 4 m from the middle and
  thought it was the wall. Now (layout 20) the wall has to be 6 m of solid rock.
- Other chats had unsaved work in the same files (Brickcrown, Dungeon 8), so only my own hunks may be committed.

**Still to do (next chat)**: the 7th dungeon (one misses on each seed), world building got slower (40-75 s vs 27 s),
the new tests, the old tests that used the single zone size, full test run, then the owner's fly-over test.
