## Nov 21: the 8 new building pieces, built as models for all three kits

**What we did.** The owner asked for the missing building pieces in all three kits (wood Shack, stone Stonehold,
brick Hearthbrick): corner stairs, spiral stairs, stair railing, upside-down sloped wall, edge strip, floor with a
round hatch, lattice wall, and a roof peak cap (Shack and Hearthbrick only, no knob). All 23 models are built by
script in Blender, pass the automatic model checks, and are installed in the game folder with their preview
pictures. Hearthbrick's new pieces got their own build file (`hearthbrick_v2_new.py`); shared helpers (flip a
wall upside down, a diagonal lattice, cutting a round hole, a round lid, the pyramid cap) are in
`new_pieces_common.py`. The game code (piece list, collision shapes, icons, tests) is the next step.

**Mistakes and hurdles (and fixes).**
- The model checker failed under plain Python (it needs Blender's mesh tools). Fix: run it inside Blender.
- Hearthbrick corner stairs: mortar and brick bottoms sat in the same place (shimmer). Moved the mortar up 3 cm.
- Hearthbrick spiral stairs: the stone steps floated 1-2 cm off the column, because the round bricks sit a
  little sunk. Fix: the steps now reach a little into the column.
- Hatch hinge stuck out 1 cm: Claude gave the cylinder's turn in radians, but the kit wants degrees.
- Lattice sill poked 2 mm out of the bottom; the Shack lattice posts poked 1 cm; the roof cap's lowest shingles
  poked 1.8 cm and its hip boards 1.4 cm. All moved inside the piece box.
- Roof cap: shingles of two faces met at each corner line (shimmer). Fix: they now stop 3 cm short of the
  corner, hidden under the hip board.
- Shack hatch: the open lid stuck out the back. Fix: hole moved back 7 cm, lid made 1 cm smaller.
  (The plain Shack floor already pokes 0.7 cm at one log; the check allows it, so left alone.)
- Found a hidden shimmer in the EXISTING stone sloped wall (its back sheet steps sat exactly at the stones'
  tops). Fixed in the build code (`courses()` in `stonehold_v2.py`); the game's copy is not rebuilt yet,
  waiting for the owner's OK.
- Installing many pieces in one Blender run crashed on the second preview picture (graphics-card error in
  Blender's Vulkan code). Fix: one Blender run per piece, retrying the odd random crash. One Blender start
  also failed once with a MemoryError; a retry worked.
