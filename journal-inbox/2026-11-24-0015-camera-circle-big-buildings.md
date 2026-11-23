## Nov 23 — The see-through circle in big buildings (F807 round 3c)

**Owner's play test:** "already a 9 out of 10". Left: in the Twin Gate a 4th floor plate right over the dwarf
stayed solid, and moving the camera made the plates "switch" between see-through and solid.

**What was wrong:** the game asks "which pieces are on screen in front of him?", but it only took the first
128 answers. The Twin Gate has many more pieces than that. The floors under him (which stay solid anyway)
filled the list first, so a few slabs over his head got left out, a different few each frame. It's like a
teacher who only reads the first 128 names on a list: who gets missed depends on the order.

**Fix:**
- The screen search may now hand back up to 4096 pieces (SCREEN_HITS).
- The circle stays on for 0.4 s after something was last in the way (HOLD), so it doesn't blink off
  when the line from the camera slips through a gap between two slabs.
- New test: test_big_building_still_clears_every_slab_over_him (484 floor pieces around him). Before the fix
  only 5 of the 9 slabs over him faded; after the fix all of them do.

**Other notes:**
- New F814: small gaps where the round doorway's arch meets the wall.
- F813 (black door leaf) said again. The Twin Gate chat took it: its F810 mirror (a -1 scale on the leaf)
  most likely flips the leaf's light.
- Hurdle: my first journal entry and FEEDBACK notes had already been committed by another chat that
  saved the shared files whole. Nothing was lost, but I had to check before committing so I didn't save their
  half-done work (dwarf.gd has their stairs changes; I commit only my camera line).
