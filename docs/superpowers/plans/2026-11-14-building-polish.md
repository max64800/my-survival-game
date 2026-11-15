# Building polish (Mossy Hollows) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** About 30 snapping building pieces in 4 materials, soft physics, station levels, gear +1..+3, and 4 prebuilt blueprints.

**Architecture:** Data-driven pieces in `Pieces.LIST`. Snapping uses a 1 m grid, plus "anchor" snapping to the piece being aimed at.
Steadiness stays in `Structure`. Blueprints are generated in code by `BlueprintLibrary`. Visuals, station levels,
upgrades and soft collapse come in phase B, after Claude 3's `visuals` branch is merged (it touches piece_node, station, builder, items).

**Tech Stack:** Godot 4.7.2, GDScript (strict typing), own test runner (`tests/run_tests.gd`, `only=<file>`).

**Spec:** `docs/superpowers/specs/2026-11-14-building-polish-design.md`

## Global Constraints

- Old piece ids stay valid: floor, small_floor, wall, half_wall, doorway, window_wall, beam, pillar, stairs, ceiling_panel, mine_prop (saved blueprints use them).
- Mossy menu families: plank_root, cut_stone, clay_brick, copper_ingot.
- Steadiness: wood 0.08 up / 0.16 side; stone and brick 0.04 / 0.10; copper 0.03 / 0.06; pillars and columns 0.02 going up; foundations always anchored; minimum 0.10.
- Strength colors: blue ≥ 0.75, green ≥ 0.5, yellow ≥ 0.25, red below.
- Every game run Claude starts uses `--audio-driver Dummy`. Robots never grab the mouse (`Controls.robot`).

## Review Focus

- Aiming at a floor's top with a wall → the wall lands on that floor's nearest edge, never mid-floor (test in A2).
- Aiming at a wall's top with a roof → the roof's base sits at the wall's top height (A2).
- A roof turned with Q four times → back to the same placement (A2).
- A piece on a foundation that isn't touching rock → anchored anyway (A3).
- Old `small_rootwood_lodge.dwbp` still loads, and every one of its pieces exists (A1).

---

## Phase A (now: files Claude 3 hasn't touched)

### Task A1: Piece catalog

**Files:** Modify `src/build/pieces.gd` (LIST, FAMILIES numbers, new keys). Test: `tests/test_pieces.gd` (new).

**Interfaces (produces):** `Pieces.LIST[id]` keys: name, size, units, place ∈ {cell, edge, corner, free, ceiling}, group ∈
{foundation, floor, wall, door, roof, support, around, mining}, optional: foundation (bool), shape ∈
{box, roof, ridge, roof_outer, roof_inner, gable, arch, column, brace, ladder, railing, door}, rise (m, roofs/gables),
opening, extra, families, station = {"workbench": lvl, "mason": lvl, "anvil": lvl} (the lowest level that unlocks it per station),
walkable_slope. `Pieces.MOSSY_FAMILIES: Array[String]`. `Pieces.station_for(family) -> String` (plank_root→workbench,
cut_stone/clay_brick→mason, copper_ingot→anvil, others→workbench).

- [x] Test `test_every_piece_is_valid`: every LIST entry has size>0, units>0, a known place/group, and at least one Mossy family allowed.
- [x] Test `test_old_ids_still_exist` and `test_starter_lodge_pieces_exist` (load `res://blueprints/small_rootwood_lodge.dwbp`, every id in LIST).
- [x] Test `test_soft_numbers`: FAMILIES up/side match the Global Constraints.
- [x] Implement the spec §1 table (ids as written there; window_small = old `window_wall`, floor_small = old `small_floor`).
- [x] Run `tests/run_tests.bat only=test_pieces` → PASS. Run the full suite → PASS. Commit.

### Task A2: Snapping (1 m grid + anchor)

**Files:** Modify `src/build/pieces.gd` (`snap`). Modify `src/build/build_mode.gd:102` (pass the anchor box). Test: `tests/test_pieces.gd`.

**Interfaces:** `Pieces.snap(piece: String, p: Vector3, n: Vector3, yaw: float, rot: int, lift: float = 0.0, anchor: AABB = AABB()) -> Dictionary {pos, rot}`.
The anchor is the box of the built piece under the crosshair (or empty).

- [x] Tests:
  - `test_wall_snaps_to_floor_edge` (floor box (0,0,0)-(2,0.25,2), aim (1.0,0.25,1.7) up → wall at z=2, y=0.25)
  - `test_roof_sits_on_wall_top` (anchor = wall box top y=2.25 → roof pos.y == 2.25)
  - `test_pillar_snaps_to_floor_corner`
  - `test_half_floor_fills_1m`
  - `test_no_anchor_uses_1m_grid` (cell 2×2 at p.x=3.4 → center x=3)
  - `test_floor_extends_from_side` (aim the side of a floor → new floor adjacent, same y)
  - `test_rotation_cycles`
- [x] Implement: with an anchor and n.y>0.5, the base y = anchor.end.y; edge → nearest anchor face across the axis; corner → nearest anchor corner;
  cell → 1 m grid clamped inside the anchor's top. With an anchor and a side hit on a cell/foundation piece → place adjacent along n.
  Without an anchor: the old rules, but on a 1 m grid.
- [x] build_mode passes `Structure.box_of(uid)` when the hit collider is a PieceNode.
- [x] Run the tests, then the full suite. Commit.

### Task A3: Soft steadiness rules

**Files:** Modify `src/build/structure.gd`. Test: `tests/test_pieces.gd` (or test_building).

**Interfaces:** `Structure.add(...)` anchors foundations. `Structure._loss(family, neighbor, me, piece := "")` gives pillar/column the 0.02 "up" loss.
`static func Structure.strength_color(s: float) -> Color`.

- [x] Tests:
  - `test_foundation_always_anchored`
  - `test_stone_reaches_farther_than_wood` (count how many floors stick out sideways before <0.10)
  - `test_pillar_stack_stays_strong` (5 stacked pillars > 0.85)
  - `test_strength_colors`
- [x] Implement, run, commit.

### Task A4: BlueprintLibrary (4 simple blueprints)

**Files:** Create `src/build/blueprint_library.gd`. Create `tools/make_blueprints.gd` (writes `res://blueprints/<id>.dwbp`).
Test: `tests/test_blueprint_library.gd`.

**Interfaces:** `BlueprintLibrary.IDS := ["miners_homestead", "stone_hall", "forge_workshop", "watchtower_cabin"]`,
`static func make(id: String) -> Blueprint`, `static func list() -> Array[Dictionary] {id, name, file}`.

- [x] Tests:
  - every blueprint: all piece ids/families are allowed; fits inside `size`; no two pieces overlap (Structure.overlaps)
  - JSON round trip
  - the homestead has air cells for the rooms
  - every non-foundation piece touches another piece or the floor
- [x] Implement per spec §7 (simple versions). Run, commit.

## Phase B (after the visuals merge)

- **B1 Piece meshes:** `src/build/piece_mesh.gd` builds and caches an ArrayMesh per (piece, family) (planks / blocks / bricks / plates / shingles); piece_node uses it; collision: boxes, convex for roof/stairs.
- **B2 Soft collapse + hammer tint:** builder: below 0.10 → creak and shake for 2 s → RigidBody debris that fades after 4 s, half refund, no damage; build_mode tints pieces with `strength_color` while holding the hammer.
- **B3 Station levels:** station.gd: workbench/mason/anvil level from extras within 4 m; items/recipes for the extras; builder checks `station_for(family)` level ≥ the piece's need; the build menu groups by `group` and greys out locked pieces.
- **B4 Gear upgrades:** slot `up` 0..3; `Items` power/damage/armor read ×(1+0.15·up); the upgrade action in the station panel; cost per spec §4; name suffix "+N".
- **B5 Blueprint UX:** the chest auto-placed outside the front of the footprint; the 4 blueprints in the V book; the `-- buildcheck` photo robot.

## Status (Nov 14, 2026): all of phase A and B done

A1–A4 and B1–B5 are built, tested and pushed. Extras added on top:
- 45° triangle and diagonal pieces.
- Climbable built ladders, and doors that open (E).
- A walkable Ramp.
- A Decor tab with 14 pieces, used to furnish the four blueprints.
- The Cozy rest buff, which gives comfort from furniture.
- Claude 2's hand-made piece models load automatically from `assets/models/build/<piece>__<family>.glb`.
