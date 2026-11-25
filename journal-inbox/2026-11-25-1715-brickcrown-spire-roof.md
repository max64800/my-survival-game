## Nov 25: Brickcrown Keep's pointed spire roof (F895)

**What we did**
- A new building piece, the **Spire Roof** (`roof_spire`, Hearthbrick only). One piece is one sixth of a pointed
  6-sided roof and sits on one 2 m triangle, so six of them on a hexagon of triangles make the whole spire. It snaps
  like every other triangle piece, so no new way of placing was needed (a whole-hexagon piece would have needed one).
- Built by script in Blender (`tools/asset_forge/builds/brick_spire_roof.py`) the same way as the Hearthbrick
  `roof_45`: dark rafters, underlay boards, curved terracotta tiles row over row, a pale stone eave, thin and open
  underneath (rule 4). Each slanted edge carries half a round hip tile on a mortar bed, so two neighbours make one
  round hip. On top: a sixth of a stone knob (foot, waist, ball, point).
- Game side: the piece is in `pieces.gd` (and triangle pieces now also count when they say `tri = true`), it has a
  simple code shape in `piece_mesh.gd`, and the model checker knows its outline and roof size.
- Brickcrown Keep's left tower keeps its railed lookout and 6 brick pillars; the spire now sits on the pillars.
  test_brickcrown_design and the piece/model/build tests pass. The 3D page is republished (v3, same link).

**Mistakes and hurdles**
- The hip tiles poked 4 mm out of the piece at the low corner. Sliding them up the hip didn't work well; cutting
  each tile row where it meets the eave did.
- Several "shimmer" spots (two surfaces in the same place): the mortar bed sat exactly on the boards' cut edge, the
  stone knob's cut faces sat on the piece edges, the hip tiles nearly touched the cap tiles, and the tile ends met
  the mortar at the eave. Each was fixed by moving one surface about 1 cm away (rule 2).
- The model checker first said "no piece called roof_spire": the piece has to be in `pieces.gd` before the check runs.
- Claude first wanted to add the spire to the sloped-roof list, but a test needs every sloped roof to work for the
  Shack too, so it stays out of that list.
- Claude tried to open the page on a small local web server to check it; that was not allowed. Checking the
  published page in Chrome also failed (the browser helper didn't connect), so the roof was checked in Blender
  renders only; the owner checks the page.
- Publishing the page was refused once because the old page data hadn't been read in this chat; reading it first fixed it.
