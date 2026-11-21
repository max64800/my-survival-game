## Nov 21: Tower rebuild fixes (Claude 2): no more 10 FPS, cheaper, picture menu

**What we did**
- **F565 + F567, the lag and the blue tower.** The play log showed the graphics card spending ~60 ms a frame drawing
  hundreds of see-through blue plan pieces stacked on top of each other. Now the blue plan only shows while you hold
  the Build Hammer, and only the floor being built right now. All blue pieces share one material.
- The freezes (up to 0.7 s) were the computer's own work. Every new piece checked itself against every piece in the
  world, then re-worked out the steadiness of every piece in the world. Now pieces are kept in a grid of 4 m boxes
  (like a sorted toy shelf), so a piece only looks at its neighbours. A new piece only passes its steadiness on to what
  it touches. The models load in the background before they're needed. Slowest step: ~700 ms → under 50 ms.
- **F557, the wood price (3rd time).** A test counted the first cave's wood by our sums: 236 planks. The owner really
  found ~110, and our sums were wrong twice before, so this time the owner's number won. Rebuilding a ruin now costs
  30% of new pieces (it reuses old stone and timber). Wooden tower: 258 → 79 planks, 33 → 10 rope.
- **F560** menu: one short line + two cards with only item pictures. **F578**: "Still to put in" pictures once
  building. **F559**: a ruin doesn't carve a walkway or level ground, so no "Carving rock". **F581**: the bolt crate
  inside goes with the rest of the junk. **F580**: Forge Workshop came from reading an Old Blueprint (random
  building), not the tower; every "Blueprint learned" card now says why. **F561**: couldn't make a free shield happen
  (test); crafting one item now says what it used.

**Mistakes and hurdles**
- The test runner couldn't find Godot (not on PATH). Fix: set `GODOT=` to the exe path before `tools/run_tests.sh`.
- My first speed test failed (156 ms). Timing prints showed two culprits I hadn't guessed: the whole-world
  steadiness check and first-time model loading, not the overlap checks I fixed first.
- A background test run was started before one fix and reported a stale failure; re-running showed it passing.
- Ruin pieces are sorted after they're made, so the 30% price shares came out differently in the menu and the chest.
  Fix: work the prices out before sorting, on every computer.
- An old ruin test still expected the full stone price; it now expects the 30% share.
- Python's quoting of `\n` inside a script that edits code broke twice; I made that one edit by hand instead.
