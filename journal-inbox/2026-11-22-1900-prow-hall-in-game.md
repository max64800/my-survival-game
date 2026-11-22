## Nov 22: The Prow Hall goes into the game (F656, F657, F479)

**What we did**
- The owner liked the Prow Hall page and said "put it into the game". It is the first grand castle ruin and the first ruin built *into* the cave.
- A maker script (`tools/ruins/make_prow_hall_ruin.py`) turns the page's castle into the game's ruin plan: doors gone, pieces with nothing under them removed, rubble on floors, 4 loot chests, tables, benches, a map table, an armour bench, a spilled arrow crate, and 5 beetles.
- New ruin code (`src/world/ruin_prow_hall.gd`). It looks for a big mossy cavern with enough flat ground. Then it digs the castle's rooms and a dip under the bridge, *grows* rock (a wall behind the keep, a lump under the lone tower), and builds the castle. The lone tower's pieces are "anchored", so they can stand on the rock lump.
- The Rebuilding Chest teaches two blueprints: Stonehold Prow Hall and the wooden (mended) Prow Hall.
- Tests (`tests/test_ruin_prow_hall.gd`): the plan is whole, the ruin stands up, the blueprint matches, the cave shape is right, the spot keeps clear of stone columns and other places (placement rule), and a full rebuild in stone keeps the rock lump and wall.

**Mistakes and hurdles**
- First plan run: 5 rule problems (a bench by the stairs, racks hitting the floor above, a crate inside the prow wall, a bench too close to rubble). Fixed by moving or removing them, and by placing rubble after the furniture.
- The castle was bigger than blueprints were allowed to be (40 m, 2000 pieces). The limit is now 56 × 24 × 56 m and 3000 pieces.
- The rebuild digs out every "air" cell of a blueprint. The castle's air box would have dug away its own rock lump and wall. Fix: air only close to pieces, and never inside the lump or wall.
- My first bridge-dig rule still dug 43 holes into the lump. Removed the bad condition, and a test now checks it.
- The castle didn't fit anywhere on most test worlds (stone columns, steep drops, only one free cavern). Fixed by also allowing nest caverns, testing the real ground spots, trying all 4 turns, a wider search, and allowing the drop at the lump.
- The search then took 4.5 s. A distance map for columns, a smarter floor search and checking every 4th spot made it 0.2–1.9 s.
- Claude mistakes: two small typing errors in GDScript (a loop variable named like a parameter, an untyped variable), and a wrong way to run one test (`only=file.fn` instead of `only=file fn=name`).
- The rebuild test said "no rock lump", even though the code was right. The test world had no "camera" loading the rock, so digging and growing did nothing. Fix: the test adds a rock loader (VoxelViewer) at the ruin and waits for it to load. Now 125 rock balls grow.
