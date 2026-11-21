## Nov 21: the 8 new building pieces are in the game

**What we did**
- Added the 8 new pieces to the build menu (src/build/pieces.gd): Corner Stairs, Spiral Stairs, Stair Railing,
  Edge Strip, Floor Hatch, Sloped Wall (down), Lattice Wall, Roof Cap. Each comes in the three kits (Shack wood,
  Stonehold stone, Hearthbrick brick); the Roof Cap only in Shack and Hearthbrick (Stonehold has flat roofs).
- Gave each one a shape made in code (src/build/piece_mesh.gd). That shape is what you bump into and stand on, and
  what you see if a model is missing. Corner stairs: 8 wedge steps. Spiral: a post and 12 treads. Hatch: a floor
  with a round hole you fall through. Stair railing: a slanted panel, so you can't step off the side of the stairs.
- 23 build-menu pictures made from the models' preview pictures (no Blender run needed).
- New test file tests/test_new_pieces.gd: every kit's model is really used, a dwarf walks up the corner and the
  spiral stairs to 2 m in all three kits, a dwarf drops through the hatch's hole while the floor beside it holds,
  the down-sloped wall is open underneath, and the stair railing climbs from 1 m to 3 m.

**Hurdles and mistakes**
- Claude's own mistake: my first stair railing code had two numbers whose type Godot couldn't work out. That broke
  the whole mesh file for a few minutes, and another chat's robot run found a world with no rock in it because of
  it. That chat added `: float` to fix it. Lesson: check a new code file compiles (`--check-only`) right away,
  before running anything, because other chats are using the same files at the same time.
- Two models were turned away by the "does the model fit its piece" check: the stair railing's posts stand on the
  stair steps (it starts 0.4 m up), and the down-sloped wall's pointed tip stops a little above the floor. Both are
  right, not mistakes, so those two pieces now say how high their model may start (`model_lift`).
- The spiral stairs: the dwarf got stuck on the first step. Stepping up a stair, the game first checks there is
  0.5 m of room above your head, and on spiral stairs the top tread hangs right over the bottom one. Fix: the
  spiral now feels like one smooth spiral slope (like the straight stairs feel like a ramp), so no stepping up.
- Then it got stuck again: right next to the post a spiral slope is very steep (the same climb in a tiny circle),
  and that steep strip acted like a wall. The slope now starts 30 cm from the centre, where no dwarf fits anyway.
- The test run crashed once while loading another kit's textures ("out of memory"); the same test ran fine before
  and after. Same one-off crash another chat saw today.
- Godot isn't on the PC's command path: the tests need GODOT set to the WinGet copy of Godot 4.7.2 (console exe).

**Still waiting for the owner**
- Rebuild sloped_wall__cut_stone.glb (a hidden back-sheet shimmer, already fixed in the build script).
