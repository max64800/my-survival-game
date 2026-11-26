## Nov 26: Ruin 14, the Sinkhole Ring blueprint and its 3D page (F915)

**What we did.** The owner OK'd the shape page ("Looks good, build it"), so Claude turned the plan into a real
blueprint: `BlueprintLibrary._sinkhole_ring()` (id `sinkhole_ring`, learned by rebuilding its ruin). A 9 m deep hole
in the cave floor with a ledge half way down and a high shelf behind it (`sink_rock` / `_sink_ground`); the Great
Tower (a 12-sided ring 15 m across, four stone storeys from the hole's floor to the rim); the stone keep and the
wooden Crown on its terrace with a lookout on top; the gatehouse on the rim with a watch hut; the Gate Bridge; wooden
stairs pinned to the hole's walls; the Ledge House; the High Bridge and the Winch House on the shelf. About 1,170
pieces, stone below and wood above. A new design test (`tests/test_sinkhole_ring_design.gd`) checks it all, and a new
3D page (`tools/ruins/make_sinkhole_ring_page.py` + `sinkhole_ring_page.html`) shows the ruin and the whole blueprint
from the real pieces. Not in the game yet.

**Mistakes and hurdles (Claude's own).**
- All the roofs fell down in the first test run (54 pieces). Claude put every roof 2.25 m above its walls; the
  game's roofs sit 2.0 m above them (the Cliff Galleries does `w + 2.0`). Fixed by copying that.
- A balcony floor overlapped the stone trim band under it: the trim ran right under the balcony. Fixed by leaving
  the trim out there.
- The door test missed that the tower's terrace is partly triangle floors, so the keep's door looked like it had no
  floor behind it. The test now counts triangle floors too.
- Claude put a comma after a line inside a `match`, which GDScript doesn't allow; caught before running.
- The shell broke on apostrophes in a long script again; fixed by saving the script as a file first.
- The screenshot showed the armour page: another chat's page server already used the same port. Claude used another
  port. Lesson: pick an unusual port for page servers, other chats run theirs too.

**What the owner picks next.** Whether the ruin feels grand enough (the page has an "Your call" box). Still open:
the lookout is square with a 4-sided roof because the pointed spire piece only comes in brick.

**Later the same day.** The full test run found the two wooden stairs in the hole had walls on one side only (Claude
thought the hole's rock wall closed the other side, but the stairs check wants real walls on both sides). Both now have
walls on both sides. The blueprint count test went up by one. Another chat had unsaved Brickcrown changes in the same
two files, so Claude saved only its own lines. Owner OK'd the 3D page ("that works").
