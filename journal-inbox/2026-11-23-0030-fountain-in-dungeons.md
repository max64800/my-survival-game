## Nov 23: F782 healing fountain goes into all four dungeons

**What we did**
- The owner asked to put the reworked TRELLIS dwarf-face fountain into every dungeon to test it. Built it into
  `assets/models/decor/healing_fountain.glb` and swapped it for `decor/mushroom_fountain.glb` (the "Healing basin") in
  Mossgate, Lampwick, Mossprop and Pell: the make_*.py scripts and their blueprint JSONs.
- The old fountain was round, so it never had to face anywhere. The new one has a face, so each one is turned to look into its
  room: Mossgate and Pell 0° (toward the doorway / away from the back wall), Lampwick 90° (toward its doorway),
  Mossprop -90° (away from the wall beside it). Every spot has at least 2.5 m clear for the bigger (1.3 m) fountain.
- The rubble piles under the Lampwick and Pell basins stay: they are walk-over piles on purpose (owner, Nov 20).
- The owner also asked: does this detailed TRELLIS look clash with the rest of the game? Claude's advice: change the fountain,
  not the whole game (calmer paint, fewer bumps), but judge it in a real dungeon first. And can TRELLIS make an animated
  four-legged lizard? Possible but hard: TRELLIS makes one solid statue with no bones, legs fused to the body. A test was offered.

**Mistakes and hurdles**
- Godot is not on the shell's search path, so `tools/run_tests.sh` failed at first. It lives in the WinGet packages folder;
  set `GODOT=` to it. The owner stopped the test run partway and asked to commit, so the dungeon tests have not finished yet.
