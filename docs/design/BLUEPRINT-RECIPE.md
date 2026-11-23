# How we make a ready-made blueprint (the owner liked this way, Nov 16, 2026)

The Delver's Hut (`BlueprintLibrary._delvers_hut`) is the example to copy.

## What the owner wants in a blueprint
- **Not a box.** An interesting shape: an L (or more) round a yard, a main block plus a wing.
- **Impressive:** two stories, stairs inside, a hole in the upper floor with a railing round it.
- **Real roofs:** peaked roofs (two slopes meeting at a ridge, gables at both ends). A lower wing's roof runs into
  the taller house's upper wall, so no extra roof pieces are needed where they meet.
- **The yard closed off** with railings, leaving a gap to walk in.
- **Two ways in:** round doors with foundation steps up to them.
- **No furniture inside.** Players furnish it themselves.
- **A starter blueprint costs no copper.** Copper comes later in Zone 1. Check the cost (see below) before
  showing it.
- **One building style per blueprint.** All of the Delver's Hut is Shack wood.
- **Everything lines up, so it can be rebuilt on the grid** (owner, Nov 17, the Fallen Outpost). Stairs end level
  with the floor they lead to (Stonehold: stand stairs on a floor slab, floors are 2.25 m apart and stairs 2 m),
  walkways and roofs that meet are the same height, and every join is flush. A 12-sided round tower's flat sides
  are 3.73 m from its middle, so it can only meet the 2 m grid flush on **one** side: plan round towers so only one
  side joins anything (stairs, walkway or wall), or use square towers where two sides must join.
- **Stairs never start against a wall or in a corner** (owner, Nov 17): their foot is on open floor.
- **A whole free block at both ends of every staircase** (owner, Nov 23, F811): past the foot and past the top
  there is a whole free 2 m block of floor (a triangle after round-stage stairs), with no door, wall, railing or pillar in
  it. Never fix a tight spot with a half railing or a smaller piece: move the stairs. Auto-check: `test_stairs_free_block`.

## Steps
1. **Sketch the plan on the 2 m grid.** Rooms are 2 x 2 m cells. Walls go on cell edges, roofs on cells, a
   second floor at +2.0 m (floor pieces), and its walls at +2.25 m.
2. **Write it in `src/build/blueprint_library.gd`.** Use `_add`, `_wall_x`, `_wall_z`, with rot 0-3 quarter
   turns.
   - Roof rows: a `roof_26` with rot 0 is low at the front (+z); rot 2 is low at the back.
   - Gables at a ridge pair up as rot 1 and rot 3 (look at the Delver's Hut).
   - A starter blueprint also goes in `STARTER`, so it's known from day one.
3. **Run the tests:** `tools\run_tests.bat only=test_blueprint_library`. They check that every piece is real and
   inside the box, that nothing overlaps, and that everything stands up. Add a check for what makes this one
   special.
   Also run `only=test_walk_through` and follow `docs/design/WALK-THROUGH-RULES.md` (owner, Nov 23: doors need room
   on both sides, nothing across a stair's way in or out).
4. **Check the cost and look at it:**
   - `godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- <id> out.json` prints
     the total cost and writes the piece list.
   - Then put it together in Blender from the real models: `tools/blueprint_viewer/assemble_blueprint.py` (each piece placed at its
     spot, Godot to Blender = (x, -z, y), turn about up by rot x 90 degrees). Photograph it, and look at the
     joins up close.
5. **Show it on a 3D page** (an artifact). Copy `tools/blueprint_viewer/index.html` (the Delver's Hut page) and
   make its files with `tools/blueprint_viewer/make_page_files.py`:
   - It loads **each kind of piece once** (`m/<piece>.json`) plus `bp.json`, and places copies. One big file
     gets too heavy.
   - It rebuilds each model into binary in the page, because artifact pages may not fetch the built-in `data:`
     links that hold a model's pictures.
   - Buttons: roof on/off, second floor on/off, doors outward/inward/closed.
6. **Fix gaps in the pieces, not in the blueprint.** If two pieces don't meet, change the piece model (see
   `shack_v2.py`: wall top beams reach the top, floor rim beams, roof eave logs, gables follow the roof slope).
   Then every player building gets the fix too.
7. **Before showing the owner:** at most 2 photo rounds.
   - Journal it in `JOURNAL.md`.
   - Add the feedback item to `FEEDBACK-done.md`.
   - Commit and push.
