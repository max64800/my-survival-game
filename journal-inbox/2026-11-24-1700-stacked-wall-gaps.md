## 2026-11-24 (PC) — No more slits between stacked walls (F833 🔁) and no 20 m Workbench rule (F837)

- **Problem (F833, came back from F165):** a wall, window or doorway standing on another one with no floor between
  them left a 25 cm open slit. Walls are 2 m tall, but a storey step is 2.25 m.
- **Three ways weighed:** (a) make walls stack 2.0 m apart. That would break the Prow Hall's 4.5 m storeys, and every
  ruin's plan would have to be made again. (c) Give every wall model a sill. That would shimmer against the
  floor's rim where there *is* a floor. (b) **Picked:** the game adds a beam by itself wherever a slit shows
  (`Builder.gap_fill_for`). Nothing is added where a floor's rim already fills the slit.
  Works for player building, every blueprint and every ruin, in any material.
- **Round 1:** a beam in the slit, refreshed whenever a nearby wall or floor is added or removed (`_refill_gaps`).
  New `tests/test_wall_gaps.gd` checks the Prow Hall (wooden + stonehold), every blueprint, and player stacking
  (wood, stone, mixed). New `buildcheck part=stacked` photo set.
- **Owner:** "still big gaps between the windows. Same with the walls." The wood wall's edges and the beam are
  *round* logs, so they only touch along a line, and a V-shaped crack stays see-through. The same crack shows
  between walls standing side by side.
- **Round 2:** the beam now reaches 6 cm into the wall below and the wall above (past the round logs). A thin dark
  lining goes at the back of every crack. Wood walls side by side also get an upright log over their seam
  (`Builder.seams_for`, one per pair, so nothing doubles up).
- **F837 (owner):** "remove the rule that we need a workbench within 20 meters to build". The distance check is
  gone. A Workbench must still exist somewhere, and its level still unlocks pieces. The message now says
  "Needs a Workbench (build one anywhere)".
- **Hurdles (Claude's own):**
  1. The first dark lining was 20 cm deep and painted black bands over the wall's own edge logs. Made it 4 cm, and
     the photo was clean.
  2. The build-menu test expected the whole new message, but the card cuts it at " (". Fixed the test.
  3. `git reset -q` after a commit reset the shared staging list. Other chats' staged files may have been unstaged.
     Next time, use only my own scratch index.
  4. `git add src/build/pieces.gd` swept in 2 lines from another chat that weren't committed yet (`yaw_of`
     FREE_ROT). They compile. The bag and food-slot chats say they aren't theirs, so they belong to a furniture
     chat that has finished. Lesson: stage only my own lines (`git add -p` or a patch), never a whole shared file.
