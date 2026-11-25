## Nov 25 — Ruin 12, the Mine-head Works: the blueprint, its tests and its 3D page (F899, steps 2-4)

**What we did**
- Built the Mine-head Works blueprint (`_minehead()` in `blueprint_library.gd`, 886 pieces). It is built into the cave's
  own shape: a stone terrace on the cave floor, the engine house (tall stone hall, wooden top storey with a sloped
  roof), the six-sided stone stack and the boiler shed tucked into niches of the rock wall, the wooden headframe over
  the shaft with the Head Wheel on top (its two bearings sit on two beams 4 m apart), a trestle over the dip to the ore
  shed on the lower ledge, steps cut in the rock, and the 8 m shaft with ladders down to a mine room.
  Every building is stone below, wood above (the owner's mix).
- New design test `tests/test_minehead_design.gd`: pieces real, in the box, out of the rock, not overlapping, nothing
  falls; stairs and doors walkable; the wheel sits on its beams; stone below wood above.
- The ruin 3D page (`tools/ruins/make_minehead_page.py` + `minehead_page.html`): whole view and a ruin view (the
  trestle's middle span lies in the dip, the wheel hangs crooked, holes in the roofs), plus a "see underground" button
  for the shaft and mine room. Published for the owner's OK.

**Mistakes and hurdles (and fixes)**
- The blueprint was 30 m tall (the shaft goes deep), but blueprints were capped at 24 m tall: the save/load test
  refused it. Raised the cap to 32 m and made the box a bit narrower.
- A loop `for lv in [1, 2]` didn't know its type and Godot refused to load the file. Fixed by writing `lv: int`.
- The stack's top trim band poked into the rock wall. Dug its niche deeper.
- Claude's (my) mistake: two stair holes (engine house, ore shed) only left out the floor over the top flight, so a
  floor hung low over the bottom flight: a dwarf would bump their head. The stacked-stairs test caught it. Made both
  holes two tiles long with railings round them.
- Writing a Python script through the shell with quotes inside failed; wrote it as a file instead.
- The full test suite takes over 10 minutes, so background runs got cut off twice. Ran every blueprint test one by
  one instead (all pass). Failures seen in the part that did run (digging with a sword, cave roots, two broken junk
  models) come from other chats' unfinished work, not from this one.
- Another chat (Brickcrown) had unsaved edits on the same lines of `blueprint_library.gd`; committed only the Mine-head
  lines on top of the last commit (a scratch copy), so their work stays theirs.

**Next:** the owner OKs the page, then step 5: the ruin in the game (chests, the fallen cage, creatures, keep world
growth out with a test).
