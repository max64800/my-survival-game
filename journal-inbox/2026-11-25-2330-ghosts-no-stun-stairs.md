## Nov 25: Ghosts can't be stunned, always swing after a teleport, and climb the Grand Stair (F873 🔁, F852, F897, F898)

**What the owner said (Tomb of Hald, 4th round):** sometimes a ghost teleports and then does nothing, maybe because it was hit too hard. Ghosts must never be stunned. After every teleport a ghost should be behind you, facing you, and attack. The blue ghost sometimes runs at you and does nothing. And ghosts you lure up the stairs get stuck on them.

**What we did:**
- **No stun for ghosts:** their stun bar is now so big it can never fill, and "fall apart" knockdowns skip ghosts. (We tried "infinity" first. A friend's copy of the game multiplies the bar by 0, and infinity × 0 is not a number, so we used a huge number instead.)
- **Always swing after a teleport:** when a ghost fades away, it forgets any daze and any push from your hit. It comes back in "chase" mode, facing you, and swings at once. Even if it was in the middle of something else as it faded, it switches back to chasing.
- **Blue ghost:** its only blow is a swooping lunge. No creature could start a lunge closer than 2 m, so right next to you it had nothing to do and just ran into you. Ghosts may now lunge from close up. The Lost Miner keeps the old rule (it circles and waits on purpose).
- **The Grand Stair:** a new test lets a ghost chase you from the Hall of Names to the top. It failed in three places, one after another:
  1. The stair slope is 45°, and creatures could only climb 45°. Ghosts can now climb 52°, like the dwarf.
  2. A "pit ahead?" check looks down just ahead of the creature. On the stair, that spot was already under the thin stone slab, so the check saw only the floor far below, called it a pit and stopped. Now it looks from as high as a stair rises over that distance.
  3. At the top, the hall floor's edge is a lip about a hand high. Round feet press against it like a wall. Ghosts now rise over low edges when there's room above them.

**Mistakes and hurdles (Claude's own):**
- I inserted a debug print into the wrong `move_and_slide()` in monster.gd and broke the file. Another Claude chat couldn't run any tests until I fixed it. They told me, and I removed it. Lesson: after adding a temporary line, run one test right away and look for "SCRIPT ERROR".
- I first thought the "may I step there?" room check was blocking the ghost. Printing each check separately showed it was the "pit ahead" check. I undid my room-check change because it wasn't needed.

**Tests:** test_ghost (2 new: hard hit never stuns + swings facing you; blue ghost swings when right next to you), test_hald (new: a ghost follows you up the Grand Stair), test_lampwick, test_monsters.
