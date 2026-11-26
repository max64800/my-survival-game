## Nov 26: Quiet Barrows first-play fixes, the saved perk build, Last Swing check

**What we did**
- F907 (monsters couldn't climb the Spiral Stair): the Barrow Warden stopped at the stair-top doorway for good. His "is there a pit ahead?" feeler is one ray straight down. It fell through the thin seam where two floor slabs meet, so he thought the doorway was a cliff. Now three feelers a hand apart must all find nothing before it counts as a pit. The two parked spiral-stair tests are back on and pass.
- F908 (strips beside the Ash Bridge need spikes): they were really 10 m deep with spikes at the bottom, but in the dark they looked like a flat floor. The owner picked a shallow trench: now 3 m deep, with spikes you can see.
- F909 (4 spear walls at the Spear Gate): now 1.
- The owner's perk build (29 points: Toughness up to Unbreakable, plus Fighting's Light Feet/Last Swing/Battle Breath/Quick Reload/Steady Aim) is now bought automatically at every dev dungeon start (`PERK_BUILD` in src/debug/dungeon_test_start.gd). A test checks that every point fits.
- "Last Swing doesn't work": a new test kills a spider with Last Swing 3 and health goes 50 → 59, so it works. It's just only 9 health, and nothing shows on screen. I asked the owner whether to make it bigger or show it.
- Logged F910 🔁 (F902 came back): Hald Ironbrow still can't get round his tomb on the brazier side. Left for a new chat.

**Mistakes and hurdles**
- First guess for F907 was "the Warden is too big for the door". I shrank him (1.25 → 1.1); that didn't help. A debug print showed the real cause (the pit feeler). The smaller size stays; tests pass with it.
- test_hald had an old check saying "only the Hald may be dark". The Barrows is dark on purpose, so the check now allows both.
- The test runner's "N checks" means N whole tests, not single checks. For a moment "2 checks" looked like my new test hadn't run.
