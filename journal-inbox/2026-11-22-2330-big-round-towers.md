## Nov 22: Big round towers, the castle research (F656, steps 1-2)

**What we did**
- The owner wants castle builds like the best survival-game builders make (F656). Step 1 was research: web searches
  for castle floor plans, circle tutorials and blueprint sites, plus the owner's 12 reference pictures, viewed as one
  small contact sheet (one picture instead of twelve, to save tokens).
- Wrote a 9-point learning list into `docs/design/GRAND-RUIN-RECIPE.md` ("Castle builds"): round towers made of
  squares and triangles, bigger rings, towers on a rectangle's corners, tower + wall + tower, wedge tips, stairs round
  the edge, many heights, pointed roofs, plan the foundation layer first.
- Step 2: our game already had the small 12-sided ring (Stone Watchtower, Lantern Spire). What was missing was
  **size**: every round tower was the same 7.5 m. The owner's rule (squares = 6 R^2, triangles = 12 R^2) means a
  bigger ring is the same plan scaled up, each piece split into R x R. New helpers `_big_ring_layer`, `_big_ring_edges`,
  `_big_ring_corners`, `_big_ring_stairs`, `_big_ring_rails` make a ring of any size.
- A test tower `stonehold_round_test`: a 15 m round base (24 squares + 48 triangles a layer, 2 floors, trim bands,
  battlements) with the small ring standing on its roof. Its side of 4 m got a centred round door from
  narrow wall + doorway + narrow wall.
- A comparison 3D page (old small ring next to the new big one): https://claude.ai/artifact/Nbj5t3NaZX9Soc6pKC3Uhj,
  made by `tools/ruins/make_round_tower_page.py` + `round_tower_page.html` (a copy of the Cliff Watch page tool).
- A test: `test_big_round_tower_is_sound` (nothing overlaps or falls, 24 + 48 pieces a layer).

**Mistakes and hurdles**
- The web research was thin: the big blueprint-collection name gave no results at all, and many hits were spam copies
  of guides. The reference pictures taught the most. Lesson: for building patterns, pictures beat search.
- Claude's own bug: the first version of the gap-triangle code passed two *corner points* where it needed two *side
  directions*; caught by re-reading the math before running it.
- Checked the result with numbers before pictures: the floor area of every layer matched a true 12-sided shape to the
  millimetre, and no two triangles sat on each other. Then one photo from above showed the tiles had no holes.
- The first top-down photo didn't go overhead (the camera spot was too far forward); a second spot fixed it.
- `tools/run_tests.sh only=<test name>` ran 0 checks: `only=` matches the *file* name, `fn=` the test name.
- Other chats had their own edits in `FEEDBACK.md`: staged only this chat's one line with a patch
  (`git apply --cached`), not the whole file.

- The owner liked the big tower but said it's "not enough": the reference castles are whole complexes, not one tower.
  So before placing real pieces, a **plan page in simple shapes** (12-sided blocks sized to our real rings, wedges,
  walls, boxes): https://claude.ai/artifact/PECKgVdBwpDtHqJBpFfPMV (`tools/ruins/castle_plans_page.html`).
  Three ideas: A Six-Tower Hold (towers in a hexagon + walls + a stepped keep), B Prow Hall (hall with corner towers,
  pointed prow, keep, bridge to a lone tower on a rock), C Star Keep (rings stacked smaller and smaller + six pointed
  bastions with turrets). A "Floor plan" button shows every real square and triangle tile; cone roofs can be switched off.
- Hurdle: the "Laying out..." label stayed on the page because a CSS rule beat the `hidden` switch; now it is removed.

**Waiting for the owner:** which plan (or mix) to build, and which style (Shack or Hearthbrick, since Stonehold
roofs are flat only) gets cone roofs. Then step 3: build that castle with real pieces.

**Owner's answer (same day):** plan B, the Prow Hall, in stone (Stonehold, so flat roofs). New rule F657: every ruin
from now on is built *into* the cave (rock walls, ledges, rock lumps, dips), written into GRAND-RUIN-RECIPE.md
("Built into the cave"). Building the Prow Hall with real pieces goes to a fresh chat.
