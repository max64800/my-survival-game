## Nov 22 (PC, night): the Twin Gate after your play test (F711-F715, F713 gaps)

**What we did**
- **F711, steps too tall:** the stone stairs now have 8 lower steps instead of 6 in the same height (25 cm each
  instead of 33 cm). Built in Blender by script (`stonehold_v2.py`), passes the model check.
- **F712, stone + wood railing:** the stone stair railing is now all stone: stacked-stone posts, a stone hand rail
  and stone bars.
- **F713, towers:** the spiral stairs were already swapped for straight + corner stairs by the open-stairs chat.
  New here: old worlds that still have the spirals get them taken out and the new stairs put in when the world loads
  (`RuinTwinGate._swap_old_stairs`). **The gaps after rebuilding:** the builder builds in bands, bottom up. If one
  piece was stuck in rock, the band never finished, so nothing above it got built. Now the builder digs the rock
  away where the next piece goes (`Builder._ruin_dig_rock`), takes the old spiral stairs down first like the old
  battlements, and the dig round the fallen tower and the drill yard is bigger.
- **F714, mossy lump:** moved from the front courtyard to the corner past the grand stair.
- **F715, wall tops:** worn and collapsed walls now get a bump shape made of 8 slices that follow the broken top
  (`PieceNode._model_slices`), so the low part of a collapsed wall is about 0.7 m tall instead of 1.7 m.
- 3D page updated (stairs without spirals, all-stone railings, a "fixed after your play test" list).
- Tests: rebuild test checks that every piece gets built and the ground is level; new tests for the lump, the
  broken wall tops and the old-stairs swap.

**Hurdles and mistakes**
- The stall wasn't the stairs at all at first: the ruin's saved plan (JSON) was old, so the rebuild was building
  pieces that no longer fit. Regenerated it from the blueprint.
- My first wall-top shape was as tall as the whole wall in every slice: I counted every triangle that touched a
  slice by its highest corner. Fix: cut each triangle to its slice first, then take the top.
- The worn wall only drops about 30 cm, so its test can't ask for more than that.
- With seed 42 the Twin Gate found no cavern: the new Prow Hall took the other big cave, and the last free one had
  two stone columns in it. Fix: if no spot is free, take the best cave anyway and move the columns in the way out.
- The lump didn't grow on high ground because the fill check was too strict; loosened by 20 cm.
- Ran tests with the wrong filter at first (`only=` matches file names, `fn=` picks the test) and without the
  `GODOT` path set.
- Port 8765 for the page check was another chat's page server; used another port.
- The open-stairs chat had staged its own work in the same files (blueprint, stairs model); committed only my hunks.
