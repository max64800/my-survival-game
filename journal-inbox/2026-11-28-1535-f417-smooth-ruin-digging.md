## Nov 28: F417 part 3, smoother digging when you walk up to a big ruin

**What we did**
- The owner asked if all ruins should be built while the world loads. Claude offered "smooth near-build" (still build when
  you get near, but dig smarter), and the owner picked it.
- Measured first with a robot at the Brickcrown: 187 frames over 30 ms, 18.8 s in total (7-9 FPS). Switching off rock
  collision and the "rock changed" listeners barely helped. The real cost: 30 small digs a frame kept making the same
  16 m patches of rock redraw again and again.
- Now the room is dug one 16 m patch per frame: all its balls are cut into a copy of the rock in one go (Voxel Tools'
  own sphere cut), and the copy is pasted back once. Brickcrown: slow frames 187 → ~57, 18.8 s → 4.1 s. Mine-head the same way.
- World-made digs no longer play digging sounds (host and friends).
- Rocks and columns now settle at most once per 0.25 s instead of 3 timers for every single dig ball.
- Digs waiting for far rock to load (from a save or a friend's game) were all checked against each other every frame:
  0.25 s a frame with 2 far ruins, 1.5 s with 4. Now they sit in 4 m boxes and only the ones near rock that just
  loaded are tried (Voxel Tools' "block loaded" signal, plus a slow sweep of one box a frame just in case).
  The order rule (a fill and a dig in the same spot happen in the order they were made) is kept.
  New test: `test_authority.test_waiting_digs_are_cheap_and_keep_their_order` (6002 waiting digs: under 2 ms a frame).

**Mistakes and hurdles**
- Claude tried `set_meta` on an Array to remember "already sorted". Arrays can't hold that, so it uses a plain flag now.
- `only=<test name>` ran 0 checks. The right way is `only=<file> fn=<test>`.
- The first try of the new waiting system still failed its own speed check (2.3 ms): the safety sweep looked at 8 boxes
  a frame. One box a frame is enough.
- A Python check Claude wrote to edit the file matched the wrong function names; fixed with a sharper pattern.
- Still left: a few 0.3-0.5 s pauses while a ruin is first dug (cause not found yet). The owner suggested looking at how
  7 Days to Die does it: cities are put into the world while it loads, so nothing is built when you walk up.
  The next step is to carve ruin rooms into the rock while the cave is made.
- Not ours: `test_authority.test_needs_pickaxe_selected` fails (a sword still "hits" rock), and that code wasn't touched here.
