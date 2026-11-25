## Nov 25: the Smeltery Terraces ruin goes in the game (F845 step 2)

**What we did**
- The Smeltery Terraces (ruin 10) is now a real ruin. `tools/ruins/make_smeltery_ruin.py` breaks the blueprint the
  same way the approved 3D page did (the same dice), then makes it sound for the game: rubble lands on the floor
  below, nothing floats, ladders only stay if a floor is at both ends. It writes `blueprints/ruins/smeltery_ruin.json`.
- `src/world/ruin_smeltery.gd` builds it the first time someone comes near, the way the Prow Hall does: chests in
  the vaults and one with copper pages in the tower's ring room, lootable props, beetles, a dip in the cave floor.
- The cave maker keeps a spot for it in every world. Mossy only has 7 big caverns and the other ruins take them all,
  so the Smeltery may share a cavern with one of the small ruins (they keep clear of each other).
- Both blueprints (brick and wood) are learned by rebuilding the ruin. Dev menu "Ruins" has a Smeltery Terraces button.
- Owner changes while testing the page: wood posts at the hall end of the covered bridge, the two little spires on
  the chimney tower's roof removed, and under the bridge three rows of tall columns instead of a brick block.
- New robot `src/debug/laddercheck.gd` climbs every ladder in a ruin test world.
- Owner's new rule: balcony brackets never sit on a window's glass. 16 did (hall balcony, tower balcony, ring room).
  They now slide to the seam beside the window (`_brackets_off_windows`), with a check, written into RUIN-RULES.md.
- Owner spotted a big gap on the hall's wood roof. Cause: the wood steep-roof model stops short of its box at both
  ends, so two rows never meet. Logged as F861, to be fixed in the model (it affects every wood building).

**Mistakes and hurdles (and fixes)**
- No spot found on any test world: every big cavern was taken. Fix: allow sharing a small ruin's cavern.
- The top ladders led to the open sky (their floors had fallen). Fix: a rule that every ladder needs a floor at its
  bottom and its top, with a test.
- 13 turret walls fell over in the strength test because the floors under them were removed. Fix: keep the turrets' top floors.
- Rubble landed outside the ruin's ground, and only 2 pieces landed at all. Fix: rubble snaps onto the floor tile
  under it and gets 8 tries.
- The copper chest stood in the stair hole. Fix: search for the most central free spot in the ring room.
- Ladder robot, first run: 2 of 5 "stuck". The dwarf reached the top, kept pushing into the wall, and dropped back
  down the hole. A player steps back off the ladder at the top; once the robot did that too, all 5 climbed.
- The third row of columns would have stood in the deepest part of the dip under the bridge. Fix: the dip moved a
  step forward, so it is right in front of the bridge and all columns stand on flat ground.
- Couldn't look at the republished 3D page myself: starting a local web server was blocked.
- `git pull` blocked by another chat's unsaved CREDITS.md changes; never stashed, merged later.
- After the dip moved, two checks still looked for it in the old spot (and the dig grid was too coarse for the
  shorter dip). Fix: the checks look in the new spot and the dip is dug in half-metre steps.
- Pushing failed: this PC's main and GitHub's main both have other chats' commits that clash (Hald tomb test,
  JOURNAL.md). Merge undone, left for the chats that own those files; my commits are saved locally.
- Owner's play test: old triangle brick texture (F725, 2x), junk should vanish after rebuilding (F864), rebuilt roofs
  look plain (F865), back against the cave rock (F866), attach the round tower (F867), clearer windows (F868),
  doors close after 30 s (F869: never built).
