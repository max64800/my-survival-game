## Nov 23: The Twin Gate moves into a real cave (F657), F818 closed

**What we did**
- F818 (walls left out on rebuild): asked the owner first. Answer: all walls were fine; they only wanted the rock
  formation not built separately. So F818 was closed and the work went into F657.
- F657, Twin Gate first: new worlds (cave layout 18) no longer grow a rock wall and two rock lumps round the fort
  ("growing its rock: 1026 balls" is gone). The spot picker now also scores the cave's OWN rock right behind the
  barracks (42 sample points) and checks the 10 m way in front of the grand stair (no drop; rock there is dug out).
  On the 3 test worlds the back sits in real rock: 41, 39 and 41 of 42 points. The rebuild test prints "0 balls of
  rock grown" and checks there are none.
- Old worlds keep their old layout number, so their already-built Twin Gate never moves.
- The dry moat stays (it is dug, not placed). Asked the owner if it should go too.

**Mistakes and hurdles**
- The first picker demanded already-open ground in front. World 7 has no such spot, so it found nothing. Fix: dig
  the way in instead, and make a spot that needs digging score a little worse. Only a drop rules a spot out.
- Tried easing the back-rock weight (0.3, 0.15) and making rock-to-dig count 3× more, to dig less on world 7
  (about 8,600 of 12,600 dig points hit rock). Neither helped world 7 and both broke world 42 or 1234. Went back to
  0.6. World 7's caverns are just tight for a 40 m fort. Looking at 10 caverns instead of 5 changed nothing either.
- `godot` isn't on the PC's PATH for tools/run_tests.sh: set GODOT to the WinGet Godot_v4.7.2 console exe.
- Ran three test files in one batch: keep-clear, cave layout and Prow Hall spot all failed with odd array crashes.
  Run alone, the cave layout and Prow spot tests passed. test_keep_clear.test_tower_ground_is_kept_clear fails the
  same at layout 17, so it's older and not from this change.
- test_rebuild_the_twin_gate_in_wood_rushed_stays_fast fails with a texture error (piece_node.gd:399). It does the
  same at layout 17: most likely another chat's unsaved model files.
- The Prow Hall test failures (F818's clue) come from unsaved F710 work (taller storeys) in blueprint_library.gd,
  left by a chat that has ended (chats ed and 66 said it's not theirs). Not touched. Its ruin JSON must be made
  again when F710 is finished.

**Next:** the owner play tests the Twin Gate in a new world; then the Prow Hall and every other ruin the same way.
