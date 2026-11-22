## Nov 22: Ruin 8, Cliff Watch: the stone trims and the layered blueprint (F479)

**What we did**
- Asked the owner first: ruin 8 = **Cliff Watch**, in **Stonehold**, no extra research. It is the owner's "layered" wish:
  "it goes up, then it expands, then it goes up, then it expands again".
- The stone bracket (corbel), trim band (cornice) and trim corner were already made and OK'd for the Twin Gate, but
  only lived in its ruin script. Installed them as real game pieces in Stonehold (`stonehold_v2_twin.py install=1`,
  `pieces.gd` families, piece icons, `test_new_pieces` updated).
- Wrote the blueprint `BlueprintLibrary._cliff_watch` (plus a wooden version): a stone plinth with a 6 m grand stair;
  storey 1, the gate hall; storey 2 juts 2 m OUT at both sides and in a bay over the round main door, on brackets;
  storey 3 steps IN with a battlement terrace round it; storey 4 juts OUT again on brackets, with stone pillars
  under its front corners; a roof deck with a six-sided lantern room and the fire bowl on top. The back is plain:
  it goes into the cave's rock. Not in the learnable list yet (its 3D page first).
- New test `test_cliff_watch_is_layered_and_sound`: nothing overlaps or falls, no half floors, every stair's foot
  and top land on floor, and the outline goes out, in, out (measured from the walls).
- Price (stone): 4,376 cut stone, 426 mortar, 15 copper.
- The owner asked for its 3D model: a page with the stone and wooden watches side by side against a rock wall,
  storey buttons that cut it away floor by floor, and a "from the side" view (`tools/ruins/make_cliff_watch_page.py`,
  `cliff_watch_page.html`).
- The owner found the Twin Gate missing from the dev menu (P): it was never in `BlueprintLibrary.IDS`, and had no
  names either. Added the Twin Gate's two and Cliff Watch's two to `IDS` and `REBUILD_ONLY` (so no Old Blueprint
  page teaches them), with their names.

**Mistakes and hurdles**
- The shell broke on apostrophes inside a long Python heredoc (a word like "storey 2's"). Fixed by writing the code
  to a file first and inserting it with a small script.
- `godot` isn't on the PATH on this PC, so the test runner failed at first. Godot lives in the WinGet packages
  folder; set `GODOT` to it.
- `fn=` didn't pick the one test (1 check ran); running the whole file with `verbose=1` showed it passing.
- Diagonal walls turned out to be old "legacy" pieces, so the top changes shape with the Twin Gate's six-sided
  lantern room instead.
- Adding the Twin Gate to the list first broke two tests: it had no entry in `NAMES` (the dev menu needs one).
- Another apostrophe in a heredoc broke the shell again; the page script went into a file this time from the start.

**Next**
- The ruin (`tools/ruins/make_cliff_watch_ruin.py`, copy of the manor's) and its 3D page; photograph it; owner's OK;
  then the world class (a spot against a cave wall).
