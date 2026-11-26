# Model rules (owner, November 15, 2026)

**Every Claude reads this before making or changing any 3D model** (building pieces, stations, items, decor,
creatures). Each rule has a **check**: a rule without a check gets forgotten. A model is not done until every
check passes. Breaking a rule because "it looked fine" is not allowed; ask the owner first.

## Rule 1: No Play-Doh (hand-built, or free packs rebuilt by script)
Picture-to-3D tools (TripoSR, TRELLIS, the asset forge's 3D step) make soft, melted, lumpy shapes. It happened
twice: the crafting stations (Nov 14) and the creatures (Nov 15, F68 🔁).
- **Every model in the game is hand-built in Blender by a script**, from the shared kit (`tools/asset_forge/kit.py`,
  `creature_kit.py` for moving parts): chunky shapes, bevelled edges, painted textures, a little hand-made wobble.
- ChatGPT pictures are the **design reference** only: match their shapes, colours and face by eye.
- Picture-to-3D may be used only as a rough size/shape guide that is thrown away, never as the final model.
  One exception (owner, Nov 22): the F782 healing fountain is the TRELLIS model reworked by script
  (`builds/healing_fountain_trellis.py`: lighter paint, water cut out, crystals added). Second exception (owner, Nov 26): the bronze armour (helm, mail, greaves, boots) is made the same way:
  our ChatGPT sheet -> TRELLIS -> `builds/bronze_armour_trellis.py` (size, metal look, fewer triangles). Only these two.
- **Free packs may be imported and adapted (owner, Nov 19):** a build script loads a free pack model (CC0 first,
  e.g. Quaternius, KayKit), reshapes it and repaints it with our kit textures so it passes every rule here. Pack
  skeletons and animations may be used on our own creature bodies. Only free, commercial-OK packs whose files may sit
  in the public repo (CC0; CC-BY only with a credit line). Paid, Fab, Unity, Synty or Mixamo files are never committed.
  Log every pack in `CREDITS.md`. Picks: `docs/research/RESEARCH-PLAN.md`.
- **Check:** every `.glb` in `assets/models/` has its build script in `tools/asset_forge/builds/` (or
  `build_creatures.py`); an automatic test fails if one is missing. Side-by-side picture: reference vs. model,
  same angle, before calling it done.

## Rule 2: No shimmer
Shimmer is two surfaces in exactly the same place: the game can't decide which one to draw, so it flickers.
- No two surfaces of a model may lie in the same place. A part that sits on or behind another part either
  joins it properly or stays **at least 1 cm away**.
- Pieces that meet other pieces (wall on foundation, wall beside wall) must not put a face exactly on the shared
  edge where the neighbour also has one: keep each piece's outer faces 0.5 cm inside its outline.
- **Check:** an automatic test looks for overlapping faces in the same place, in every model. Then, in the game:
  turn the camera slowly up close to doorways, windows, corners and edges (`buildcheck part=edges`).

## Rule 3: Building pieces are built in clean layers
Up to four layers, back to front:
1. **Frame / backing** (hidden): dark, set back, never seen as a strange colour through a gap.
2. **Main material:** stones, bricks or planks.
3. **Trim:** corner stones, beams, door and window frames.
4. **Decor:** copper, rope, hinges, nails.

- Each layer has a **fixed depth**, the same in every piece of that style (this also prevents shimmer).
- **Nothing pokes out:** no layer goes through another layer or past the piece's outline. Bricks, stones and
  planks are cut exactly to the edge (triangles, slopes, round openings).
- **Pieces match their neighbours:** layers line up at the edges, so two walls side by side read as one wall.
- **Calm colours:** one main colour family per style plus a few accent stones/bricks (about 1 in 8). Never
  white next to black next to brown. No grey planks in the Shack's floors.
- **Check:** the outline test (nothing outside the piece's box/triangle), a picture of two of each piece side by
  side, and the colour check by eye against the style's reference picture.

## Rule 4: Roofs
- **Stonehold (`cut_stone`):** flat roof + battlements only. No sloped roofs, ridges, roof corners or gables.
- **Delver's Shack (`plank_root`) and Hearthbrick (`clay_brick`):** sloped roofs only. No flat roof.
- **Every sloped roof piece is a thin panel** (slope, ridge, inner corner, outer corner): about 15–25 cm thick,
  **open underneath** (you see rafters and the backs of shingles/tiles from inside). Never a filled wedge,
  pyramid or block. The gable (the triangle end wall) is a wall, so it is solid.
- Roof covering matches the style: wooden shingles (Shack), curved terracotta tiles (Hearthbrick), never logs.
- **Check:** the build menu code (`src/build/pieces.gd`, `families`) only offers these combinations, with a test;
  a test measures each roof piece's thickness and checks it's open underneath; a picture from below.

## Rule 5: Round doors only
- One round doorway and one round door per style. No square openings, no second doorway kind.
- The door is a real circle (hobbit style), cut flat at the floor: radius 0.78 m, centre 0.70 m above the floor.
- **Check:** the build menu lists one doorway per style; picture of each with and without the door.

## Rule 6: Textures (owner, Nov 15, 2026, multiple-choice answers)
The look to match is the approved creature pictures (the Rock Beetle): chunky, chisel-cut faces, hand-painted.
- **Many paintings, not one:** every surface (planks, bark, log ends, stone...) comes from a ChatGPT *variant
  sheet* in the same chat and style as the piece's picture: 6-8 different planks, 4 barks, 4 log ends, 4 stones.
  Each part picks a different painting, so no two neighbouring planks match.
- **Medium variety:** neighbours are clearly different (lighter, darker, redder), but stay in one wood family.
- **Never stretched:** paintings are used at their real size (a plank painting covers one plank's width; bark
  repeats every ~0.8 m along a log). Never pull one picture across a whole long part.
- **Bright worn edges, dark gaps:** every board/log/stone edge gets a lighter worn rim and every gap or joint is
  darker, like the beetle's stone plates.
- **Log ends are chopped:** pale fresh wood with axe-cut facets and a dark bark rim (no ring "target").
- **Joints:** logs that cross are stacked and notched (one rests on the other); nothing passes through anything.
- **Fasteners:** wooden pegs with domed heads (iron only where the picture shows iron).
- **Check:** 4-side photos next to the picture; look at three neighbouring planks: are they clearly different?
  Any stretched grain? Any part passing through another? White shape first, then paint, owner OK at each step.

## Why rules used to get lost (and what changed)
- They were buried in long plan documents, and the code was never changed to follow them (example: the plan
  said "Stonehold is flat", but the build menu still offered every roof to every material).
- Two documents disagreed (the creature guide said "use the 3D tool" after the owner had asked for hand-built).
- **Now:** this one page is the source; `CLAUDE.md` points to it; every rule has a check; and when a rule changes,
  the old text that disagrees is deleted the same day.
