## Nov 22 (night, PC): F565 🔁 the slow Twin Gate (7 FPS), F733 triangle gaps and wall halves

**What we did**
- **F565 🔁 (7 FPS at the rebuilt wooden Twin Gate).** Measured first this time. A new `perf` mode in the ruin test
  robot times everything out front, then switches the usual suspects off one at a time: shadows, lights, fog,
  collision, fireflies. Each cost only 1-7 ms. The real cost was the script: 180 ms a frame.
  - Why: the rebuild was stuck at 99%. Old raised stone stairs (from before F169 put stairs straight on the
    floor) stood 25 cm above the spot where the new stairs go, so the first floor never finished. In the dev
    Ruins world, a stuck site retries every frame, and each try re-checked the strength of all 2,852 pieces
    (120 ms).
  - Fix: the old stairs and their slabs make way. A stuck site waits 1 second between tries. Taking ruin
    pieces down in one go checks strength once, not once per piece. The ruin file was remade, so it matches
    the blueprint again.
  - Result: 147 ms -> 9.3 ms a frame (7 -> about 107 FPS). The rebuild takes 18 s and reaches 100%. A new
    test keeps it fast.
- **F733 (three triangle gaps).** Found the owner's screenshot. The triangles were old worn stone walls with
  broken, slanted tops. A wood rebuild leaves worn walls standing.
  - Hidden bug: "do worn walls stay?" was decided by the first piece in the build list. That list is sorted by
    height, then by distance from the chest, so the answer was luck. In the tests it was a stone trim, so every
    worn wall got rebuilt. In the owner's game it was a wooden piece, so 70 of the 78 worn walls stayed.
  - Fix: the answer now comes from the plan's walls. The Twin Gate rebuilds every worn wall in planks
    (`Builder.RUIN_REBUILD_WORN`).
  - **Wall halves:** a Sloped Wall (full along the bottom) and a Sloped Wall (down) (full along the top), in the
    same wall spot and turned the same way, are now two halves of one wall, in any two materials. Example: a
    stone half and a wood half (`Structure.halves_fit`). Test: `test_two_wall_halves_share_one_spot`.
  - Twin Gate page: the note and the prices were updated. The prices were older than the 30% ruin discount.

**Mistakes and hurdles (and how they were fixed)**
- `godot` isn't on this PC's PATH. Used the full WinGet path to the console exe.
- The first perf run never finished the rebuild (114 s, still at 99%). That was itself the clue.
- **Commit slip:** the first F565 commit swept in another chat's 19 already-staged files, including deleted
  research notes. Caught from the file list and undone with a soft reset. Recommitted with only the 5 own files.
  For F733, Claude built the commit in a fresh private index made right before committing (the lesson from
  the F716 slip), then checked the parent commit and the file count.
- Test slips by Claude: "99%" inside a `%` format string (needs "99%%"); wrong tab indentation in a scripted
  edit; the stone test placed its stairs slab with the wrong turn; a "corner" check put the second wall in the
  same spot, not at the corner.
- Claude's own maths slip: first thought half a turn also makes two matching halves. Worked it through: half
  a turn makes them cross. Only the same turn fits.
- Claude's first barracks pictures came out black (camera inside the rock). Switched to counting with
  numbers and finding the owner's screenshot instead.
- A temporary price print in the test made the timing check fail once. It passed again once the print was
  removed.
- Found, not fixed (waiting for the owner's OK): the wooden sloped walls' slope trim board reaches 10 cm past
  the slant. Against a stone half it's hidden inside the thicker stone. Two wooden halves together could
  flicker where their boards cross. Also, taking down one wall in the normal game still re-checks the whole
  building's strength (a short hitch at very big builds).
