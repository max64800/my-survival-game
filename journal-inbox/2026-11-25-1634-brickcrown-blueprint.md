## Nov 25: Ruin 11 "Brickcrown Keep" built from real pieces, 3D page made (F895)

**What we did**
- Built the blueprint `brickcrown_keep` in `BlueprintLibrary._brickcrown()` from real game pieces, mixing Stonehold
  stone (bottom, towers, curtain wall, courtyard) and Hearthbrick brick (keep's top two storeys, the left tower's top,
  one mended crack). 1,211 pieces. It isn't learnable yet; like the Smeltery, the 3D page comes first.
- Keep: two tall stone storeys, a brick 3rd storey that juts out on stone brackets, a smaller brick 4th storey with a
  tile roof, dormers and a chimney. Left round tower with a brick 6-sided lookout on top. Curtain wall with a round
  gate, a passage, a walk on top. A stone bridge over a dip. A right tower on a rock lump, a wall to the rock, and the
  courtyard with a well and two rooms in the rock.
- New test `tests/test_brickcrown_design.gd`: nothing overlaps or falls, every stair and door is open, no bracket on
  glass, and stone below and brick above (roofs brick, battlements stone).
- 3D page with "The ruin" and "The whole blueprint" (`tools/ruins/make_brickcrown_page.py` + `brickcrown_page.html`),
  the cave made from the blueprint's own ground (dip, lump, carved courtyard).
  https://claude.ai/artifact/DVpUTMzYs7siXeKMTd8rWE

**Mistakes and hurdles**
- GDScript couldn't guess the type of `rtop` (a number made from an array value): fixed by writing `: float`.
- In the ruin sketch my circle for "this is a tower" was too small (2.3 m, but the round walls reach 3.7 m), so tower
  walls were cut down like the curtain wall. Made the circle 4.2 m (and kept it off the keep and curtain).
- The curtain's ruin height was just below its battlements, so all of them vanished. Raised it to 8.1 m.
- The first courtyard camera sat inside the rock; moved it up over the right tower.
- A bash heredoc with backticks in it broke the shell; wrote the script as a file instead.
- The first page upload dropped (connection reset); the second try worked.

**Open**
- Asked the owner: a new pointed brick roof piece for the left tower, or keep the railed lookout?
- After the owner's OK: the ruin in the game with a natural, lumpy courtyard carve.
