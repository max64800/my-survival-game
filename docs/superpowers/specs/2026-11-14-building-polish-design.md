# Building polish for Mossy Hollows — Design

*Written Nov 14, 2026 (Claude 1). Approved by the owner in chat (multiple-choice rounds + "Yes, write it down and build").*
*Scope: the first area only (Mossy Hollows). No new biomes.*

## Goal

Make building one of the best parts of the game: lots of pieces that snap together nicely, real roofs,
foundations and columns, stations that grow, gear you can improve, gentle physics, and ready-made
blueprints you can drop into the mountain. Inspiration (ideas only, never copied): Valheim, Enshrouded,
7 Days to Die, Grounded.

## Owner's decisions

| Topic | Choice |
|---|---|
| Stations | Upgrade by placing "extras" near them (Valheim-style levels) |
| Gear | +1 to +3 upgrades at the right station. No durability |
| Physics | Forgiving, and warns first (strength colors; creak, then a soft tumble) |
| Blueprints | Miner's Homestead (carved), Stone Hall, Forge Workshop, Watchtower + cabin. **Simple for now**, bigger later |
| Grid | 2 m pieces + 1 m halves |
| Materials (Mossy) | Rootwood, Cut Stone, Clay Brick, Copper trim |
| Look | Shaped pieces (planks, blocks, bricks, plates). Claude 3 adds textures on top |

## 1. Piece catalog

Each piece: size (x × y × z, m), how it snaps, which materials, the station level needed, and its cost in material units.

| Group | Piece id | Size | Snap | Materials | Unlock |
|---|---|---|---|---|---|
| Foundations | foundation | 2×1×2 | cell | stone, brick | Mason 1 |
| | foundation_half | 2×1×1 | cell | stone, brick | Mason 1 |
| | foundation_steps | 2×1×2 | cell | stone, brick | Mason 2 |
| Floors | floor | 2×0.25×2 | cell | all | WB 1 / Mason 1 |
| | floor_half | 2×0.25×1 | cell | all | WB 1 / Mason 1 |
| | floor_small | 1×0.25×1 | cell | all | WB 1 / Mason 1 |
| Walls | wall | 2×2×0.3 | edge | wood, stone, brick | WB 1 / Mason 1 |
| | wall_narrow | 1×2×0.3 | edge | wood, stone, brick | WB 2 / Mason 1 |
| | half_wall | 2×1×0.3 | edge | wood, stone, brick | WB 1 / Mason 1 |
| | doorway | 2×2×0.3 | edge | wood, stone, brick | WB 1 / Mason 1 |
| | arch_doorway | 2×2×0.3 | edge | stone, brick | Mason 2 |
| | window_small | 2×2×0.3 | edge | wood, stone, brick | WB 2 / Mason 1 |
| | window_wide | 2×2×0.3 | edge | wood, stone, brick | WB 2 / Mason 2 |
| | gable_26 / gable_45 | 2×1 / 2×2 triangle | edge | wood, stone, brick | WB 2 / Mason 2 |
| Doors | door | 1×1.8 (in a doorway) | in doorway | wood, copper | WB 1 |
| Roofs | roof_26 / roof_45 | 2×1 / 2×2 rise, 2 deep | edge-top | wood, stone, brick | WB 2 / Mason 2 |
| | roof_26_ridge / roof_45_ridge | caps two slopes | edge-top | same | WB 2 / Mason 2 |
| | roof_26_outer / _inner, roof_45_outer / _inner | corners | corner-top | same | WB 3 / Mason 3 |
| Supports | beam | 2×0.3×0.3 | edge | wood, stone, copper | WB 1 / Anvil 1 |
| | beam_half | 1×0.3×0.3 | edge | wood, stone, copper | WB 1 / Anvil 1 |
| | brace | 2 m diagonal | edge | wood, copper | WB 2 / Anvil 1 |
| | pillar | 0.4×2×0.4 | corner | wood, stone, brick, copper | WB 1 / Mason 1 / Anvil 1 |
| | column | round, carved, 2 m (RuinKit look) | corner/cell | stone | Mason 2 |
| | arch | 2 m wide, between two pillars/columns | edge-top | stone, brick | Mason 2 |
| Getting around | stairs | 2×2×2 | cell | wood, stone, brick | WB 1 / Mason 1 |
| | ladder | 1×2 | edge | wood, copper | WB 1 |
| | railing | 2×1×0.15 | edge | wood, copper | WB 1 |
| Mining | ceiling_panel, mine_prop (kept) | — | — | as now | as now |

**Families kept for Mossy:** plank_root (Rootwood), cut_stone, clay_brick, copper_ingot. Other families stay in the
code for the Jungle and found items, but are not offered in the Mossy build menu unless the player owns the material.

## 2. Snapping

- World grid of **1 m** for positions; 2 m pieces line up with 2 m cells, and halves fill 1 m gaps.
- `edge`: the bottom-center of the piece sits on a cell edge (walls, railings, beams).
- `edge-top`: the piece sits on top of the wall or edge below the aim point (roofs, gables, arches).
- `corner`: on a cell corner (pillars, columns).
- **Aiming at an existing piece snaps relative to it:** its top face → stack; its side → extend.
- Heights snap to 0.5 m. Q turns the piece, PageUp/PageDown lift it (as now).

## 3. Stations and levels

| Station | Level 1 | +Extra → level 2 | +Extra → level 3 | +Extra → level 4 |
|---|---|---|---|---|
| Workbench (wood pieces, wood/stone gear) | base | Chopping Block | Carpenter's Vise | Tool Rack |
| Mason's Table (stone/brick pieces) | base | Chisel Rack | Stone Saw | — |
| Anvil (copper pieces + copper gear) | base | Bellows | Grindstone | — |

- An extra counts if it stands within **4 m** of its station. Each extra counts only once per station.
- The station panel shows "Level N" and what the next extra unlocks.
- To place a piece, a station of its material at the needed level must be within 20 m (as now for the workbench).
- Extras are crafted at their own station (for example, the Chopping Block at the Workbench).

## 4. Gear upgrades (+1 to +3)

- Any pickaxe, axe, weapon, shield or armor piece can be upgraded to +3 at its station:
  stone and wood gear at the Workbench, copper gear at the Anvil.
  +1 needs station level 2, +2 level 3, +3 level 4 (or the station's top level, for the Mason and Anvil).
- Cost per step: the item's main material × (2, 4, 6), plus 1 crystal (blue for +1/+2, green for +3).
- Effect per step: **+15%** dig power, damage or armor. Shown as "Copper Sword +2".
- Stored on the item's slot: `{id, count, up = 0..3}`, so it survives saving and trading.

## 5. Soft physics

- Steadiness (0..1), the same idea as now: anchored (touching rock, or any foundation) = 1.
  Each step away loses `up` or `side`. Tuned to be forgiving:
  - wood 0.08 up / 0.16 side
  - stone and brick 0.04 / 0.10
  - copper 0.03 / 0.06
  - pillars and columns lose only 0.02 going up
- Placing: allowed down to 0.10 (as now), never auto-breaks on place.
- **Hammer view:** while holding the Build Hammer, every piece is tinted by steadiness:
  blue ≥ 0.75, green ≥ 0.5, yellow ≥ 0.25, red below.
- **When a support is removed:** pieces that drop below 0.10 creak and shake for 2 s, then turn into tumbling debris
  (a short rigid-body fall that fades out after about 4 s). No damage to players. Half their materials drop on the floor.

## 6. Piece looks

- Every (piece, family) mesh is built once with SurfaceTool and cached:
  - wood = planks with small gaps
  - stone = offset blocks with recessed mortar
  - brick = small bricks
  - copper = plates with rivets
  - roofs = shingle rows
- One mesh, plus simple collision shapes (boxes, or a convex hull for slopes).
- Materials go through one helper, so Claude 3's texture system can replace the colors later.

## 7. Blueprints

- Four built-in blueprints, generated in code from the piece catalog (so they always use valid pieces),
  saved as `res://blueprints/*.json` and listed in the blueprint book (V) from the start:
  1. **Miner's Homestead (carved):** meant to be placed against or into a rock wall. A front hall 6×6 with 2 columns,
     a door and a window; a 4×4 bedroom; a 4×4 storage room. Air cells carve the rooms.
  2. **Stone Hall:** 6×8 stone foundation, 2 rows of columns, an arched doorway, gables and a 45° roof.
  3. **Forge Workshop:** a 6×6 stone floor, half walls on 3 sides, a 26° roof, a stone chimney pillar,
     and marked spots for the Smelter, Anvil and Workbench.
  4. **Watchtower + small cabin:** a 4×6 two-floor wooden cabin (stairs, windows, a 26° roof), and a
     2×2 tower 3 floors high with a ladder and a railing on top.
- Placing: the ghost shows the whole build. The **Builder's Chest appears by itself** at the front, just outside
  the footprint, on the floor. Fill the chest, and it carves the rock and builds piece by piece (as now).

## 8. Testing

- Auto-checks for: every piece has a valid size, cost and unlock; snapping (walls on floor edges, roofs on wall tops,
  pillars on corners); steadiness numbers and colors; soft collapse (creak delay, half refund, no damage);
  station levels from extras; gear upgrade cost/effect and saving; each blueprint is valid, fits its box, and every
  piece is reachable for the build loop; chest placement outside the footprint.
- A photo robot (`-- buildcheck`) places every piece in every material, and each blueprint, and takes pictures.

## Out of scope (later)

Bigger and more elaborate blueprints, other biomes' materials in the menu, furniture sets, piece damage from
monsters/raids beyond what exists, durability and repair.
