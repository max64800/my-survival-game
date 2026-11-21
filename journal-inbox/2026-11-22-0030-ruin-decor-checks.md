## Nov 22, 2026: ruin props, checks after VS Code closed (ruin-decor chat, part 2)

**What we did**
- VS Code closed mid-job. Nothing was lost: the ruin props were already committed (f9c786d2).
- Owner: reuse is fine for the Kiln, but the Kiln ruin isn't in the game yet, so it was skipped. Only places that are
  already built get props: Mossgate, Lampwick, Old Pell's (done before) and Watchtower, Outpost, Brewhall, Spire.
  Twin Gate (3D page only) and Mossprop (another Claude is still building it) were left alone.
- Ran every dungeon, ruin, loot and save check one at a time: all pass.

**Mistakes and hurdles**
- The full test run crashed: out of memory in test_build_geometry (look.gd `forged`) while 4 Claudes and their Godot
  runs shared the PC. Not a code fault; running the checks one file at a time worked.
- test_ruin_outpost takes over 10 minutes on a busy PC (the wood rebuild alone: 190 s), so it looked stuck. Running
  each of its checks on its own (`fn=`) showed all pass.
- Closing VS Code also stopped the background test runs; they had to be started again.
