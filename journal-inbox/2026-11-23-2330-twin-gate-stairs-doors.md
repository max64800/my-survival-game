## Nov 23: Twin Gate list: free blocks after stairs, floating railings, gate doors, walking down stairs (F811, F804, F810, F803)

**What we did**
- **Rebuilding Chest / F811:** the chest wouldn't start because the Twin Gate used a "half railing" that doesn't exist.
  Instead of making half railings, the deck stairs moved to the middle of the stage, so there's a whole free 2 m
  block at the top and the bottom. Plain railings go round the stair hole. It's a rule now
  (BLUEPRINT-RECIPE.md, GRAND-RUIN-RECIPE.md) with a robot check, `test_stairs_free_block`, that walks a
  dwarf-sized body onto both ends of every staircase in every blueprint. All of them pass.
- **F804:** the diagonal stair railings came down 25 cm, the same as their stairs did long ago (F169).
  Old worlds get fixed when they load. The owner checked it: attached ✅.
- **F810:** the two leaves of a double gate swing the same way now. The turned-round leaf is mirrored, so both rings face the front.
- **F803 (going down feels like jumping):** two causes.
  1. At the top of straight stairs the next floor sits 25 cm higher than the top step. The dwarf's round feet
     rolled off that edge, and he flew over the whole flight: 40 frames in the air.
     Now the hidden slope climbs those 25 cm too, but only where such a floor is.
  2. Corner stairs are very steep in the middle (about 55°, near the post 70°). Now, when the dwarf was standing
     and isn't jumping, he keeps his feet on the ground up to 0.75 m below him. On stairs that works even when steep.
  New test `test_stairs_down`: down the straight stairs, down the corner stairs, up the corner stairs.

**Mistakes and hurdles (including Claude's)**
- The first "lip" wedge sat inside the stairs' own slab, so it did nothing (still 40 frames in the air).
  Fixed by making the slope itself taller.
- The test counted the first little drop at the spawn as "in the air", so a good result looked bad (14 frames).
  It now counts only after he first lands.
- I tried a smooth bent slope for the corner stairs, like the spiral ones. Going down got better, but it was
  too steep to walk **up**, and the test robot slid off. Back to the real steps plus the dwarf's step-down.
  Lesson: test both directions.
- `run_tests.sh only=file.func` ran 0 checks: the right way is `only=file fn=func`.
- The F811 change broke the chain of fixes for old worlds (the in-between stairs were no longer in the plan).
  The swap now also takes a piece if an old one stood close by.
- The first free-block check was too strict (it bumped into the outer walls). The ground at the bottom also had to count as floor.
- I started the full test run while still changing code. I stopped it and ran it again.

**Round 2: the owner's play test**
- Walking down ✅ and the gates ✅. But climbing the round (corner) stairs still jittered (F781 🔁, 3rd time).
- Cause: the corner stairs were still climbed as real 25 cm steps: bump into a step, stop for a frame, pop 25 cm up.
- Fix: the corner stairs got one smooth bent slope again, and while the dwarf touches stairs he counts slopes up to
  78° as ground (they're 55-70° steep, too steep for the normal 52°). That's what made the first smooth slope fail.
  The slope also reaches the top step's height one step early (like the real steps), then climbs the last 25 cm to the floor above.
- Hurdles: the first climb log showed a 43 cm pop at the very top (the same 25 cm floor edge as the straight
  stairs). Then my "stall" check counted only sideways movement, and on a steep slope that is small even
  when he's moving fine. Then the real Twin Gate climb test got stuck: he left over the top step's far end,
  and there the slope was lower than the real steps. That's why the slope now reaches full height one step early.
