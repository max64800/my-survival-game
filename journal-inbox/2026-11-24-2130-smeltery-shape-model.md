## Nov 24: Smeltery Terraces, floating pieces fixed + a richer shape model (F845)

**What we did**
- The owner saw balconies floating over the broken tower top on the ruin page. Fixed in
  `tools/ruins/make_smeltery_page.py`: the tower crown and its balconies stick out past the tower's square,
  so the page counted them as "vaults" (which never break). Now anything above 12.4 m counts as the tower.
  A bridge railing hung in the air over the fallen middle of the bridge; it now falls too.
- The owner said the design looked too simple and asked for a simple shape model of a richer version first:
  more balconies, round and square mixed. Made `docs/design/ruin10/smeltery_shapes.html` (plain blocks in
  three.js, part names on/off, four camera spots). New in it: a split grand stair with a lower front terrace,
  a wooden front balcony on brackets and a round stair turret on the hall, a balcony halfway up the tower,
  four little round corner turrets, a ring room, a crown deck, a square chimney with a bronze cap, a
  kiln-bottle furnace house (fat round bottom, thin neck, railed deck, square porch), a roofed bridge with a
  round pier, and a round watch turret.
- The owner: "much better". Next: build it from our real Hearthbrick pieces in `_smeltery()`.

**Mistakes and hurdles**
- My part sorter on the ruin page used only the tower's square outline, so anything sticking out
  (balconies on brackets) was sorted wrong. Lesson: sort by height too, not only by the floor plan.
- The browser tab I had used before was gone, so I had to look the page up again.

**Next**
- Rebuild `_smeltery()` to match the shape model (the cave needs about 24 m here), re-run
  `tests/test_smeltery_design.gd`, re-dump, remake the ruin page.
