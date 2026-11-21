# Seven new building piece kinds (owner, Nov 21, 2026)

Kinds of piece a big survival builder has that our kit lacked. We copy the KIND only, never names or looks.
Sketch page (rough sand shapes beside real pieces): https://claude.ai/artifact/8YtAAhBeSZPmLAJ6sLFpvW
Sketch shapes and sizes: `tools/asset_forge/builds/new_pieces_sketch.py` (game coords, origin bottom centre).
The sketches are thrown away; real models follow `docs/art/MODEL-RULES.md` and each kit's own build script.

## Owner's answers (all 7 yes, every piece in all three kits)
"all seven you can build it for the entire three pieces": Shack (`plank_root`, `shack_v2.py`),
Stonehold (`cut_stone`, `stonehold_v2.py`), Hearthbrick (`clay_brick`, `hearthbrick_v2*.py`).

| # | id (proposal) | size | owner notes |
|---|---|---|---|
| 1a | `stairs_corner` | 2 x 2 x 2, quarter turn | yes |
| 1b | `stairs_spiral` | 2 x 2 x 2, one turn round a post | yes |
| 2 | `railing_stairs` | 2 run, 2 rise, 1 tall | "wooden, like dark wood, similar to real railing" (the existing railings' dark turned wood) |
| 3 | `sloped_wall_down` | 2 x 2 x 0.3 | "build it for all three" |
| 4 | `edge_strip` | 2 x 0.3 x 0.07 | "not sure we need it, but sure, build it" |
| 5 | `roof_cap` | ~1.1 base | "remove the little pointy thing" (no knob/finial). Shack + Hearthbrick only (Stonehold roofs are flat, rule 4) |
| 6 | `floor_hatch` | 2 x 0.25 x 2, round hole + lid | "make sure it's dark wood as well" (the lid/hatch is dark wood; the floor around it is the kit's floor) |
| 7 | `lattice_wall` | 2 x 2 x 0.3 | yes |

## Build order (small reviewed batches, ~4 pieces each, owner OKs before the next)
1. Stairs set: `stairs_corner`, `stairs_spiral`, `railing_stairs`, in one kit first (Stonehold), then the others.
2. `sloped_wall_down`, `edge_strip`, `floor_hatch`, `lattice_wall`.
3. `roof_cap` (Shack + Hearthbrick).
Each piece: model + automatic model checks, entry in `src/build/pieces.gd` LIST (walkable stairs:
`walkable_slope`, like `stairs`), icon (`tools/model_check/make_piece_icons.py`), test.

## Later (waiting, not this job)
- The 5 Twin Gate trims as real pieces (decorative: not walkable, no collision to stand on, never needed as support),
  then the overhanging battlement on brackets and the balcony.
- Kiln Crown price (stone only): Claude suggested 60 cut stone + 12 mortar; owner hasn't answered yet.
