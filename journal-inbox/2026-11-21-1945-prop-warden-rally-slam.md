## Nov 21: The Prop Warden's Rally Slam, and "I fall through the ground in dungeon 4" (warden chat)

**What we did**
- The owner picked the Prop Warden's special move (all four suggested answers): about every 25 s he raises his
  plank and slams it down. For 2 s the stone of his fallen Lost Miners glows cold blue and shakes ("Rise, my miners!"),
  then up to 2 of them get up again (never more than 3 miners up at once). Hitting him during the slam calls it off
  (his plank is over his head, so no shield then). A statue you mine away can't come back.
- Built it host-side (co-op ready): the boss picks the slam only when there is a statue to raise, the host picks the
  statues, everyone sees the glow, the host spawns the new miners and tells everyone.
- He no longer smashes his own miners' stone with his swings (he had the Pit Boss's habit; it would have broken the
  very statues he raises).
- Test: test_skeleton_miners.test_prop_warden_raises_fallen_miners. Mossprop, monsters and skeleton miner tests pass.

**Hurdles and mistakes**
- The owner couldn't test dungeon 4: they fell through the ground at once. A robot run showed it: no rock anywhere,
  only the tower floating in the dark. The cause wasn't dungeon 4 at all. Another chat's unfinished building-piece
  change (stair railing in src/build/piece_mesh.gd) had two numbers whose type Godot couldn't work out. Godot then
  refused to load that file and the 18 files that depend on it, including the rock builder. Fix: wrote `: float` on
  the two numbers (left that chat's file uncommitted; it's their work). Lesson: when "the world is missing", read the
  very first lines of the game's output; one broken file anywhere can take the whole world down.
- The next run crashed once with "out of memory" while loading a dungeon model, though 8 GB was free. The run after
  that worked; it didn't come back. Noted in case it shows up again.
- Claude's own slip: my first glow-and-shake timer would have run the shakes in the wrong order (all mixed into one
  timer). Split it into two timers before testing.
- `only=` in tools/run_tests.sh picks test files, not test names (that's `fn=`): the first run checked nothing.
