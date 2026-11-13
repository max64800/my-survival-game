# World & Building — Detailed Design

*Written: November 14, 2026. Builds on the approved plan:
`docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md` (section 2 = the star world, section 5 = systems).
Nothing here changes a decision in that plan. Where the plan left a gap, this document makes a proposal,
and the big choices are listed as questions for you in section 9.*

**Who this is for**
- **You (the owner):** each section starts with a short "In plain words" box. You can read just those.
- **Claude (later, writing GDScript):** the rest has exact numbers and step-by-step recipes ("pseudo-code" =
  a recipe that looks like code but isn't real code yet).

**Code that already exists (Step 1) and that this document builds on**
- `src/world/cave_maker.gd` (`CaveMaker`): rooms (squashed balls) + segments (tubes), `_smin` soft blend,
  flat floors, `generate_block()` with a "solid block" fast path.
- `src/world/mat.gd` (`Mat`): material numbers 0 moss, 1 stone, 2 dirt, 3 copper, 4 border rock.
- `src/world/world.gd` (`World.apply_dig`): digs a ball, skips undiggable voxels.
- Sign rule used everywhere: **SDF positive = air, negative = rock** (same as the code).

---

## 0. Words used in this document

| Word | Meaning (simple) |
|---|---|
| **Voxel** | One "sugar cube" of the world, 1 m wide. The world is a big 3D grid of them. |
| **SDF** ("signed distance") | A number stored in each voxel: "how far to the nearest wall". Positive = air, negative = rock, 0 = exactly on the wall. Smooth walls come from this number. |
| **Material index** | A second number in each voxel: which rock it is (moss, stone, copper…). |
| **Block** | A 16×16×16 pack of voxels. Voxel Tools loads, makes and redraws the world one block at a time. |
| **Seed** | One big number that decides the whole world. Same seed = same world. |
| **Plan** (cave plan) | The list of shapes the Cave Maker decides on first (caverns, tunnels, POIs). The voxels are filled from it later. |
| **Cavern / chamber / pocket** | Big room (50–100 m wide) / medium room (15–30 m) / tiny hole (3–8 m). |
| **Capsule** | A tube with round ends. Tunnels are chains of capsules. |
| **POI** | "Point of interest": a special place, like a ruin or a boss lair. |
| **Floor** | A 20 m tall slice of the world, like a floor of a building. The map has one page per floor. |
| **Flood fill** | Like pouring paint: start at one voxel and spread to every touching voxel of the same kind. Used to find rock that is no longer attached to anything. |
| **Anchor** | Something that is "held up for sure": big solid rock, border rock, or a support beam. |
| **Snap** | When building, a piece jumps into place next to another piece so they line up perfectly. |
| **Host** | The player whose PC runs the world in co-op. The host says "yes" or "no" to every change. |
| **AABB** | A box lined up with the world axes, given by its min corner and max corner. Used for quick "do these overlap?" tests. |

---

## 1. The whole world: a star of 7 biomes

> **In plain words:** Mossy Hollows sits in the middle. Four biomes touch its sides, one sits on top, one
> underneath. Between every two biomes there is a 20 m thick wall of border rock. Each border has one or
> two "gates": tunnels that run up to the wall from both sides, so only a thin 4 m plug is left to dig.
> You need a better pickaxe for each new border. Everything always connects through Mossy Hollows,
> like spokes of a wheel. The empty corners between the arms are solid rock forever.

### 1.1 Coordinates (1 unit = 1 m; Godot: −Z is north, +Y is up)

| Order | Biome (name if decided) | Direction | x range | z range | y range | Floors (global index) | Border to Mossy needs pickaxe |
|---|---|---|---|---|---|---|---|
| 1 | **Mossy Hollows** | centre | −200 … 200 | −200 … 200 | −64 … 16 | 0, 1, 2, 3 | — (start) |
| 2 | **Fungal Jungle** | East | 220 … 620 | −200 … 200 | −64 … 16 | 0–3 | **Copper** (tier 2) |
| 3 | not decided | North | −200 … 200 | −620 … −220 | −64 … 16 | 0–3 | Silver (tier 3) |
| 4 | not decided | West | −620 … −220 | −200 … 200 | −64 … 16 | 0–3 | Iron (tier 4) |
| 5 | not decided | South | −200 … 200 | 220 … 620 | −64 … 16 | 0–3 | Steel (tier 5) |
| 6 | not decided (idea: Ancient Dwarf City) | Up | −200 … 200 | −200 … 200 | 36 … 116 | −5 … −2 | tier 6 (future pickaxe) |
| 7 | not decided (idea: The Abyss) | Down | −200 … 200 | −200 … 200 | −164 … −84 | 5 … 8 | tier 7 (future pickaxe) |

- Every biome is **400 × 400 m and 80 m tall = 4 floors**.
- **Border slabs (20 m thick):** x 200…220 (East), x −220…−200 (West), z −220…−200 (North),
  z 200…220 (South), y 16…36 (Up), y −84…−64 (Down). Each slab only covers the 400 × 400 face it touches.
- **World edge rock:** everything else (the four diagonal corners, above y 116, below y −164, beyond ±620)
  is solid rock that can never be dug.
- **Voxel Tools bounds** (rounded out to whole 16 m blocks): x, z −624…624, y −176…128.
- **Floors** are global: `floor_index(y) = floori((16.0 - y) / 20.0)`. Mossy: floor 0 = y −4…16 (top),
  floor 3 = y −64…−44 (bottom). Players see "Floor 1–4" per biome:
  `local_floor = floor_index(y) - biome.top_floor + 1`.

```
Top view (not to scale)                    Side view
          +--------+                           [ UP 36..116 ]
          | NORTH 3|                           ====slab 16..36====
 +------+ +--------+ +--------+     ... [ W ] | MOSSY -64..16 | [ E ] ...
 |WEST 4| | MOSSY 1| |FUNGAL 2|               ====slab -84..-64===
 +------+ +--------+ +--------+                [ DOWN -164..-84 ]
          | SOUTH 5|
          +--------+   (corners = edge rock)
```

**Why the order goes around Mossy:** each outer biome only touches Mossy, so every new pickaxe opens one
new border **from the hub**. Mossy becomes "home", and players naturally keep a base there.

### 1.2 How the border rock tier works

> **In plain words:** all border rock looks the same, but the game knows which wall you are hitting. If
> your pickaxe is too weak, it bounces off with sparks and a message like "Needs a Copper pickaxe".

- Keep a single material `Mat.BORDER = 4`. The **tier comes from the position**, not from the material,
  so we don't need extra materials:

```gdscript
const EDGE_TIER := 99   # never diggable
func border_tier_at(p: Vector3) -> int:
    for b in BIOMES:                         # if inside a biome box, it's not border
        if b.aabb.has_point(p): return 0
    for s in BORDER_SLABS:                   # {aabb, tier}
        if s.aabb.has_point(p): return s.tier
    return EDGE_TIER
```

- `World.apply_dig()` already skips undiggable voxels voxel-by-voxel. Change one line: a `Mat.BORDER`
  voxel is diggable only if `tool_tier >= border_tier_at(voxel)`. Hardness of border rock = 8 (hits).
- Feedback: if any voxel in the dig ball was skipped because of tier, play the "clang" + spark effect and
  show the needed pickaxe name once per 3 seconds.
- **Gate glow:** border rock faces near a gate show glowing veins in the next biome's colour
  (shader, using `border_tier_at` baked into a small lookup texture). The veins pulse brighter when the
  player holds a pickaxe that is strong enough. That is the "you can break this now" hint.

### 1.3 Gates and transitions

| Thing | Rule |
|---|---|
| Gates per border | 2 for the Mossy↔Fungal border (the first one players meet), 1 for every later border. |
| Horizontal gate | A tunnel from each side runs **8 m into the slab**, leaving a **4 m plug** in the middle (8 + 4 + 8 = 20). Both tunnels are part of each biome's tunnel network (so always reachable). |
| Vertical gate (Up/Down) | A spiral ramp (see 2.4) through the slab: the top 8 m belongs to one biome, the bottom 8 m to the other, the plug is a 4 m thick sloped section in the middle. |
| Gate frame | A carved stone archway scene (old dwarf style) placed on the Mossy side of the plug, with a rune that tells which pickaxe is needed. |
| Gate position | Random along the slab, at least 60 m from the slab ends and from the other gate; on a random floor. Decided by the **world** seed (not a biome seed) so both biomes agree. |
| Looks before the plug | The last ~24 m of tunnel on the Mossy side gets a few decorations of the next biome (e.g. a few spores and orange caps near the East gate). Behind the plug, the new biome starts right away. |
| Digging around the plug | Allowed but pointless: the whole slab is border rock of the same tier. |

---

## 2. Cave generation for one biome

> **In plain words:** for each biome the Cave Maker first writes a **plan**: where the big caverns go, how
> twisty tunnels join them, where the ruins and nests sit, where the ore veins run. This takes under a
> second. Then, whenever a 16 m block of the world is needed, it fills that block from the plan. The plan
> is never saved: the seed rebuilds it exactly. Only your digging and building get saved.

### 2.1 Order of the plan (each step uses its own random stream)

| # | Step | Random stream id |
|---|---|---|
| 1 | Gates (from the world seed, shared with the neighbour biome) | `SYS_GATES = 1` |
| 2 | Big caverns | `SYS_CAVERNS = 2` |
| 3 | Spawn point (Mossy only) and main boss lair (sealed) | `SYS_KEY = 3` |
| 4 | Medium chambers | `SYS_CHAMBERS = 4` |
| 5 | Tunnel network (tree + loops + dead ends + ramps) | `SYS_TUNNELS = 5` |
| 6 | POIs (section 3) + their connector tunnels | `SYS_POI = 6` |
| 7 | Water: lake, pools, streams | `SYS_WATER = 7` |
| 8 | Small pockets and crystal geodes | `SYS_POCKETS = 8` |
| 9 | Natural pillars and stalactites | `SYS_DETAIL = 9` |
| 10 | Ore veins and rock-colour blobs | `SYS_ORE = 10` |
| 11 | Validation (reachability + slope check) | none |

**Determinism rule (same seed = same world, on every PC):**
1. Each step gets its own `RandomNumberGenerator` seeded with `sub_seed(world_seed, biome_id, sys_id)`.
   So adding a new POI type never moves the caverns.
2. `sub_seed` is our own integer mix (never `hash()` of a Variant, never `randi()` without an object):
   ```gdscript
   static func mix(x: int) -> int:          # "splitmix" style scrambler; GDScript ints wrap at 64 bits
       x = (x ^ (x >> 30)) * -4658895280553007687   # 0xBF58476D1CE4E5B9
       x = (x ^ (x >> 27)) * -7723592293110705685   # 0x94D049BB133111EB
       return x ^ (x >> 31)
   static func sub_seed(world: int, biome: int, sys: int) -> int:
       return mix(world ^ mix(biome * 1000 + sys))
   ```
3. Loops over shapes always run in list order. Never iterate a Dictionary to make a random choice unless
   it was filled in a fixed order.
4. **`generate_block()` never uses a random generator.** It runs on several threads in any order. Anything
   "random" inside it must come from noise (`FastNoiseLite`) or from `mix(x, y, z)` of the voxel position.
5. Noise objects are created and configured **before** the terrain starts and never changed afterwards
   (threads read them at the same time).
6. Auto-check: generate 20 fixed blocks twice from the same seed and compare a checksum of SDF + material.
   Also run it on both PCs once (MacBook and gaming PC) and compare the printed checksum.

### 2.2 Big caverns

| Setting | Mossy Hollows | Fungal Jungle | Later biomes |
|---|---|---|---|
| Count | 3 (Step 1 builds 2; the 3rd arrives with POIs) | 4 | 2–5 |
| Horizontal radius (x, z separately) | 28–45 m | 30–50 m | 25–50 m |
| Vertical radius | 9–14 m (18–28 m tall before floor flattening) | 10–15 m | 8–16 m |
| Min gap between cavern edges | 30 m (so there is a real tunnel trip) | 30 m | 30 m |
| Min distance from biome edge (centre to edge) | radius + 16 m | same | same |

**Heights across floors:** every cavern is given a **home floor**. Its flattened floor is placed
2–5 m above the bottom of that floor, so it is drawn on that floor's map page (a tall cavern also reaches
into the floor above; that's fine).
- Mossy: spawn cavern on floor 1 (local "Floor 2"); one cavern on floor 2 or 3 ("deep"); one free.
- Fungal: floors chosen so that at least 3 of the 4 floors have a cavern.

```
place_caverns(rng, count):
    for i in count:
        for attempt in 200:
            r  = Vector3(rng.randf_range(RXZ_MIN, RXZ_MAX), rng.randf_range(RY_MIN, RY_MAX), rng.randf_range(RXZ_MIN, RXZ_MAX))
            f  = pick_home_floor(i, rng)                 # rules above
            floor_y = floor_bottom(f) + rng.randf_range(2, 5)
            c  = Vector3(rng.randf_range(-200 + r.x + 16, 200 - r.x - 16),
                         floor_y + 0.55 * r.y,              # floor is cut at c.y - 0.55*r.y (same as code)
                         rng.randf_range(-200 + r.z + 16, 200 - r.z - 16))
            if far_enough(c, r, caverns, gap=30): add; break
        else: shrink RXZ_MAX by 10% and retry (max 3 times), then give up on this cavern (log it)
```
(`far_enough` compares horizontal distance between centres with `max(r1.x, r1.z) + max(r2.x, r2.z) + gap`,
or passes if the two caverns' vertical ranges don't overlap.)

**Medium chambers:** Mossy 8, Fungal 10. Radius 8–14 m (horizontal), 5–7 m (vertical). Min gap 15 m from
caverns and each other. Any floor.

### 2.3 Tunnel network (every cavern reachable without digging)

> **In plain words:** first we join every room with the fewest, shortest tunnels possible (a "tree"; it
> guarantees you can reach everything). Then we add a few extra tunnels to make loops, so there's more than
> one way around, and a few dead ends that end in tiny treasure nooks.

**Nodes:** caverns, chambers, gate tunnel ends, POI entrances (step 6 adds those), spawn.
**Edge cost:** `horizontal_distance + 2.5 * abs(dy)` (going up/down costs more, so tunnels prefer staying
on a floor and the network has a few clear "stair" places).

| Part | Rule |
|---|---|
| Tree | Minimum spanning tree (Prim's method, already in `_connect_rooms`) over the edge cost. Every tree edge must be **walkable both ways** (slope rule below). |
| Loops | Add `ceil(0.25 × node_count)` extra edges: the cheapest non-tree edges between nodes that are at least 3 tree-hops apart (so a loop is a real shortcut, not a second door into the same room). Loop edges may include one-way drops. |
| Dead ends | Mossy 6, Fungal 8. Start at a random point on a tunnel, wander 20–60 m, end in a pocket (radius 3–4 m) with a 50% chance of a small loot sack or crystal cluster. |
| Tunnel radius | Main (tree edges touching a cavern): 2.6–3.4 m. Others: 2.0–2.6 m. Never below 2.0 m (after floor flattening at `cp.y − 0.6 r`, the clear height is 1.6 r = 3.2 m; the dwarf is ~1.4 m tall). |
| Worm step | 6 m per capsule; wander strength 0.65 (as in code); give up and go straight after `3 × distance / 6` steps. |
| Smooth blend | `BLEND = 3 m` between tunnels and rooms (as in code). |

**Slope rule (the dwarf must be able to walk it):**
- `CharacterBody3D.floor_max_angle` = **45°**. Tunnels are built to **≤ 30°** (`|dir.y| ≤ 0.5`) so noise
  bumps never push them past 45°. (The current code clamps `dir.y` to 0.42 ≈ 25°: keep it.)
- If an edge needs more climb than that (`abs(dy) > 0.5 × horizontal_distance`), insert a **spiral ramp**.

### 2.4 Vertical connections

| Type | Shape | Use | Walkable? |
|---|---|---|---|
| **Spiral ramp** | Helix of capsules, radius 2.4 m, helix radius 7 m, grade 28°. One full turn ≈ 23 m of height ≈ one floor. Centre column left solid (r 3 m), so it looks like a winding stair hall. | Tree edges with big height change; vertical gates. | Yes, both ways |
| **Sloped gallery** | Straight-ish worm at 25–30° for 30–60 m. | Normal climbs. | Yes, both ways |
| **Drop shaft** | Vertical capsule r 2 m, 3–5 m deep (`SAFE_DROP = 5 m`, no fall damage below that). | Only loop edges and dead ends (shortcut down). | One way (down) |
| **Chimney** | Vertical capsule r 1.5 m, 8–20 m, with a ledge every 4 m. | Decoration / dig-to-climb shortcut. Never part of the tree. | No (needs building/ladder) |

```
make_edge(a, b):
    dh = horizontal distance; dy = b.y - a.y
    if abs(dy) <= 0.5 * dh: return worm(a, b)
    # too steep: put a spiral in the middle
    mid = (a + b) / 2  (pushed sideways 10 m if that spot is inside a room)
    top = Vector3(mid.x, max(a.y, b.y) - 2, mid.z);  bottom = Vector3(mid.x, min(a.y, b.y) + 2, mid.z)
    return worm(a, top_or_bottom_near_a) + helix(top, bottom) + worm(other_end, b)

helix(top, bottom):   # capsules every 30 degrees
    turns = (top.y - bottom.y) / 23.4
    for k in range(0, ceil(turns * 12)):
        angle = k * PI/6;  y = top.y - k * (top.y - bottom.y) / ceil(turns * 12)
        point = Vector3(top.x + 7*cos(angle), y, top.z + 7*sin(angle))
        add capsule(previous_point, point, r = 2.4)
    add solid column(top.x, top.z, r = 3.0, from bottom.y - 2 to top.y + 2)     # "solid shape", see 2.6
    record VerticalLink(top_xz, floor_index(top.y), floor_index(bottom.y))      # for map markers
```

### 2.5 Small pockets, geodes, pillars, stalactites

| Feature | Mossy | Fungal | Size | Placement |
|---|---|---|---|---|
| Alcove pockets (open) | 30 | 35 | radius 1.5–4 m | On a tunnel or cavern wall, centre 1–2 m outside the wall, so they open into it. |
| Sealed pockets | 15 | 15 | radius 2–5 m | Inside rock, 3–10 m from the nearest air. Some hold rune shrines or geodes (section 3). Found by digging. |
| Natural pillars | 0–3 per cavern | 2–5 | radius 2–4 m | Solid vertical capsules from cavern floor to ceiling. Look great, and act as real rock support. |
| Stalactites | 10–25 per cavern | 5–15 | 2–8 m long cones | Solid cones hanging from the ceiling. **Max 8 m long**, well below the 20 m cave-in limit, so they never fall by themselves. |

### 2.6 How the SDF is put together (per voxel)

```gdscript
func sdf_at(p) -> float:
    var air := 1e9
    for shape in AIR_SHAPES_NEAR(p):      # caverns, chambers, tunnels, helixes, pockets, POI rooms
        air = _smin(air, shape.dist(p), BLEND)        # shape.dist < 0 inside the air shape
    var s := -air
    s += wall_noise(p) * 2.2                          # big bumps (freq 0.07, 2 octaves) — already in code
    s += detail_noise(p) * 0.6                        # small grain (freq 0.25, 1 octave) — new
    for shape in SOLID_SHAPES_NEAR(p):    # pillars, stalactites, helix columns, POI floors/platforms
        s = minf(s, shape.dist(p))                    # rock wins inside the solid shape
    for shape in FORCED_AIR_NEAR(p):      # POI interiors that must stay clean (no noise, no stalactite)
        s = maxf(s, -shape.dist(p))
    s = minf(s, bound_dist(p))                        # outside the biome = rock
    for g in GATE_TUNNELS_NEAR(p):        # gate tunnels may cut into the slab (not the plug)
        s = maxf(s, -g.dist(p))
    return s
```
- Floors of caverns and tunnels are flattened (already in `_room_dist` / `_seg_dist`). Cavern floors get
  an extra gentle bump: `floor_y += floor_noise(p.xz) * 1.5` (freq 0.03), so they are walkable but not
  table-flat.

### 2.7 Materials and ore veins

Proposed material list (extend `Mat`; 8-bit allows 256):

| Index | Material | Where | Hardness (hits, stone pickaxe) |
|---|---|---|---|
| 0 | Moss | Mossy: top surface of floors (already in code) | 1 |
| 1 | Stone | Everywhere (default) | 3 |
| 2 | Dirt | Under moss, and noise patches (already in code) | 1 |
| 3 | Copper ore | Mossy veins | 5 |
| 4 | Border rock | Slabs + world edge; tier by position | 8 (and tier check) |
| 5 | White marble | Mossy rock-colour blobs (building stone) | 4 |
| 6 | Dark basalt | Mossy floors 2–3, Fungal floor 3 blobs | 4 |
| 7 | Brown rock | Mossy blobs | 3 |
| 8 | Mycelium soil | Fungal: top surface of floors (Fungal's "moss") | 1 |
| 9 | Silver ore | Fungal veins | 6 |
| 10 | Orange clay | Fungal blobs | 2 |
| 11 | Yellow sandstone | Fungal blobs | 3 |
| 12 | Glow-crystal rock | Geode walls (crystals grow on it) | 4 |

**Ore veins** replace the current "noise cells" with planned veins (veins look and feel better: you follow
them). Keep the noise version as a sprinkle for 20% of the ore.

| Biome floor (local) | Mossy copper veins | Fungal silver veins | Vein length | Vein radius |
|---|---|---|---|---|
| Floor 1 (top) | 6 | 4 | 4–6 nodes | 0.8–1.2 m |
| Floor 2 | 10 | 7 | 5–8 nodes | 0.9–1.4 m |
| Floor 3 | 14 | 10 | 6–9 nodes | 1.0–1.6 m |
| Floor 4 (bottom) | 18 | 14 | 6–10 nodes | 1.2–1.8 m |

```
make_vein(rng, floor):
    start = random point on this floor; if rng.randf() < 0.4: start = a point on a tunnel/cavern wall  # 40% visible
    dir = random unit vector with |y| <= 0.4
    for n in node_count: add ellipsoid(start, radius); dir = (dir + random*0.5).normalized(); start += dir * 1.5
```
- A voxel is ore if it is rock and inside any vein ellipsoid. Ore never replaces border rock.
- **Rock-colour blobs:** Mossy 8 blobs (marble 3, basalt 2, brown 3), Fungal 8 (clay 3, sandstone 3,
  basalt 2), radius 6–12 m, noisy edges. These are the building-stone sources for the styles in section 5.
- Store veins and blobs in the same spatial index as shapes (2.9) so solid blocks only check nearby ones.

### 2.8 Water

Voxel Tools has no flowing water, so water is **separate flat meshes** (with an `Area3D` for drinking and
filling the waterskin). Water never flows.

| Water | Mossy | Fungal | Shape |
|---|---|---|---|
| Underground lake (POI) | 1 | 1 (spore bog, murky) | Bowl carved in a cavern floor, 20–40 m wide, 2–4 m deep. Flat water plane at the old floor height minus 0.3 m. |
| Small pools | 5 | 4 | Bowl 3–6 m wide, 0.6–1 m deep, in chamber floors or tunnel widenings. |
| Streams | 3 | 2 | A channel carved along tunnel/cavern floors (capsule chain r 0.8 m, its centre 0.4 m below the floor), 30–120 m long, from a "spring" on a wall to a pool. A ribbon mesh follows the channel. Always runs downhill or flat. |

- **Bowl = forced air shape + solid "rim" check:** after the plan, sample 16 points under the bowl
  (1 m below the bottom). If any is air, move the pool (otherwise water would float over a hole).
- **Draining:** if digging opens a hole under a pool or lake (host checks the 16 bottom points after a dig
  within 6 m), the water plane slides down and disappears over 3 s. Simple and believable.

### 2.9 Validation (runs once after the plan, ~50 ms)

1. **Reachability:** build a graph of rooms + tunnel nodes, walk only over walkable edges (both-way
   edges, plus drop shafts going down). Every cavern, chamber, open POI and both gate tunnel ends must be
   reachable from spawn. If not: add a straight walkable worm from the unreachable node to the nearest
   reachable node, then check again.
2. **Slope:** every tree capsule must have `|a.y − b.y| ≤ 0.5 × horizontal length` (helixes pre-checked).
3. **Overlaps:** no POI AABB overlaps another (section 3.3).
4. Debug-only auto-check ("walk test"): a 2 m grid flood fill over air cells with floor below, starting
   at spawn, must touch every cavern's centre column. Runs in tests, not in the game.

### 2.10 Performance (GDScript generator)

Goal: **≤ 4 ms per "surface" block** on the gaming PC, ~0.1 ms per solid block. A biome is 25 × 5 × 25 =
3125 blocks; about a quarter touch air.

| Trick | Detail |
|---|---|
| Spatial index | At plan time, put each shape (air, solid, vein, blob) into a Dictionary keyed by **block coordinate** (`Vector3i(floor(p / 16))`) for every block its padded AABB touches. `generate_block` looks up one key instead of testing every shape (the current code loops over all shapes per block; that's fine for 2 caverns, too slow for 4 + POIs). |
| Solid early-out | No air shapes in the list → `fill_f(SOLID_FILL)`, `fill(STONE)`, then stamp only veins/blobs/border (already done this way). |
| Distance early-out | For blocks with shapes: evaluate the SDF once at the block centre. If `s < -(13.9 + 2.2 + 0.6 + BLEND)` (half block diagonal + noise amplitudes + blend), the whole block is rock → fast path. |
| Coarse sampling (fallback) | If surface blocks are still > 4 ms: compute the shape part on a 2 m lattice (9³ = 729 points instead of 4096), interpolate, then add noise per voxel. Only do this after measuring. |
| Hot loop hygiene | Packed arrays of shape data (already done), no Dictionaries or Objects inside the voxel loop, cache `get_noise_3d` per voxel once. |
| Read-only | `generate_block` only reads the plan (threads). |
| Decorations | Glow crystals and mushrooms keep the decided method (find cave surfaces with the SDF). Place them per block on a 2 m grid where `sdf` changes sign between neighbours, using `mix(x,y,z)` for randomness. |

---

## 3. Points of interest (POIs)

> **In plain words:** POIs are the special places that make exploring worth it. Each one is a "stamp":
> a shape cut out of the rock (or added to it) plus a small scene with props, loot and monsters. The Cave
> Maker places them so they never overlap and you can always walk to them, except a few secret ones you
> must dig to (like the main boss lair and crystal geodes).

### 3.1 POI types

Sizes are width × height × depth in metres. "Open" = reachable without digging. "Sealed" = must dig in.

| # | POI | Size | Access | How it's carved / placed | Loot / monsters | Mossy | Fungal |
|---|---|---|---|---|---|---|---|
| 1 | **Biome Gate** | 10 × 8 × 12 | Open | Gate tunnel (1.3) + archway scene | Lore tablet about the next biome | 1–2 per border (1.3) | 2 (other side of Mossy's) |
| 2 | **Old Dwarf Ruin** (small) | 10–14 × 6 × 10–14 | Open | Forced-air box + flat solid floor; the ruin is a **blueprint** (section 7) stamped as damaged pieces (marble/stone style) | 1 chest: recipes (40%), ancient blueprint (25%), copper bars, food; 1 rune (30%) | 3 | 2 (overgrown) |
| 3 | **Great Hall** (big ruin) | 30 × 14 × 30 | Open, inside a big cavern | Uses a cavern; flattens 30 × 30 of its floor; big blueprint stamped (pillars, broken stairs, throne) | **Guaranteed ancient blueprint**, 2 chests, 1 rune, a wall marking spot (3.2) | 1 | 1 |
| 4 | **Abandoned Camp** | 8 × 4 × 8 | Open | No carving; placed on a flat spot of a chamber or tunnel widening (find with 9 floor samples, max height difference 0.6 m) | Bedroll, dead campfire, journal page (lore), crystals, food, torches | 4 | 3 |
| 5 | **Monster Nest** | 12–16 m ellipsoid | Open | Chamber-like air ellipsoid + nest mesh; joined to the network by a connector tunnel | Pack of 3–6 + **pack leader**; respawns every 20 min until the nest is smashed (HP 400); egg sack loot | 3 (critter burrows) | 5 (beetle hives) |
| 6 | **Side-boss Lair** | a whole big cavern | Open | Cavern floor flattened to a 30 m radius arena; boss scene + treasure pile | Side boss; rare ore pile; blueprint or named item; discovering it starts raids (plan 5.10) | 1 | 2 |
| 7 | **Main Boss Lair** | 36 × 18 × 36 | **Sealed** | Forced-air dome with a flat floor, 6–10 m of rock from the nearest tunnel, ≥ 150 m from spawn, on floor 2 or 3 (local). Summoning altar scene in the middle. Its walls are "protected" (blueprints can't carve them; players can dig normally) | Main boss + boss part needed for the next pickaxe | 1 | 1 |
| 8 | **Rune Shrine** | 4 × 4 × 4 | 3 open, 2 sealed | Small alcove (pocket) with a pedestal scene | 1 rune each | 5 | 5 |
| 9 | **Wall Marking** (boss clue) | 3 × 2 m relief | Open | Decal + slightly raised mesh on a vertical wall (find a wall: SDF gradient with `|n.y| < 0.3`) | Map clue (3.2) | 3 | 3 |
| 10 | **Underground Lake** | 20–40 m | Open | Bowl in a cavern floor (2.8) + water plane; small island 30% of the time | Fish spots (later), a sunken chest (50%) | 1 | 1 |
| 11 | **Crystal Geode** | 4–8 m ellipsoid | Sealed | Sealed pocket lined with material 12; crystal clusters placed on every inner surface | Lots of crystals (lantern fuel, light colours), 10% a gem | 6 | 4 |
| 12 | **Root Grove** (Mossy) / **Giant Mushroom Grove** (Fungal) | 20–30 m area | Open | No carving; tree-root / giant-mushroom scenes on a cavern or chamber floor and ceiling | **Wood source** (chop), glow mushrooms | 2 | 1 cavern + 3 chambers |
| 13 | **Spore Vent** (Fungal only) | 3 m | Open | Small hole in floor + particle cloud | Hazard (slow poison), rare spore item | 0 | 6 |

Spawn: Mossy's spawn cavern gets no nests, lairs or vents within 60 m. Monsters there are weak critters only.

### 3.2 The boss-clue system

> **In plain words:** each biome hides its main boss in a sealed room. Three old carvings on the walls
> (in any order) narrow it down: the first draws a big circle on your map, the second a small one, and the
> third shows the exact spot with an X. Then you dig in.

| Clue found (any marking, in any order) | Map shows | Floor info |
|---|---|---|
| 1st | Circle, **radius 120 m** | "Floors 2–4" (true floor ±1, clamped to the biome) |
| 2nd | Circle, **radius 45 m** (fully inside the first) | Exact floor |
| 3rd | **X** with a 6 m ring at the exact spot | Exact floor |

```
make_clue_circles(rng, L):          # L = lair centre (x, z)
    c1 = L + random_in_disc(rng, 0.5 * 120)          # lair is inside, not in the middle
    c1 = clamp c1 so the circle centre stays inside the biome
    repeat (max 50):
        c2 = L + random_in_disc(rng, 0.5 * 45)
        if c2.distance_to(c1) + 45 <= 120: break
    c3 = L
```
**Where markings go** (3 per biome):
- Each must be **open** (reachable without digging), ≥ 80 m from the lair and ≥ 60 m from each other.
- One in the Great Hall, one in a small ruin or camp, one on a cavern wall on a different floor.
- In Mossy, at least one is within 120 m (walking distance along tunnels) of spawn, so new players meet one early.
- Co-op: clues found are **shared by the whole world** (counted once).

### 3.3 Placing POIs without overlaps, and keeping them reachable

```
place_pois(rng):
    reserved = [AABBs of caverns, chambers, gate tunnels] (only for "must not cut through" checks)
    taken    = []                                         # POI AABBs, padded by 4 m
    for poi_type in FIXED_ORDER:                          # lair, side lairs, hall, ruins, nests, camps, shrines, markings, lake, groves, geodes, vents
        for i in count(poi_type, biome):
            for attempt in 100:
                spot = poi_type.pick_spot(rng)            # e.g. "a cavern floor", "a chamber", "solid rock 6-10 m from air"
                box  = poi_type.aabb_at(spot).grow(4)
                if overlaps_any(box, taken): continue
                if not poi_type.rules_ok(spot): continue  # distances to spawn, lair, other nests (>= 40 m), etc.
                taken.append(box); add_poi(poi_type, spot); break
            else: log("could not place", poi_type)        # never crash; the biome is still playable
    for poi in open_pois:
        if not touches_existing_air(poi):                  # e.g. a nest in rock beside a tunnel
            add connector worm from poi.entrance to nearest tunnel point (must pass the slope rule)
    run validation 2.9
```
- **Stamping order in the SDF** (2.6): base caves → POI forced air → POI solid floors/platforms.
- **Scenes** (props, chests, monsters) are not created at generation time. A small **POI Spawner** checks
  every second: create a POI's scene when any player is within 96 m, free it beyond 128 m. POI state
  (chest looted, nest smashed, boss dead) lives in the world save under the POI's id (`"mossy:ruin:2"`).

---

## 4. The map

> **In plain words:** the map is a stack of old parchment pages, one per floor of each biome. It starts
> blank. Wherever your lantern light reaches, ink appears: open floor, walls, water. Little ▲ and ▼ marks
> show where tunnels go up or down. You can add pins. Boss-clue circles and your grave also show up.

### 4.1 Data

```gdscript
class MapPage:                        # one per (biome, floor) = 7 biomes x 4 floors = 28 pages max
    var biome: int
    var floor: int                    # global floor index
    var img: Image                    # 400 x 400, FORMAT_L8, 1 pixel = 1 m, value = pixel class below
    var tex: ImageTexture             # updated with update() at most 4 times per second
    var dirty: bool

enum Px { UNKNOWN = 0, ROCK = 1, FLOOR = 2, DROP = 3, WATER = 4, BUILT = 5, ORE = 6 }

class MapState:
    var pages := {}                   # "biome:floor" -> MapPage (created when first visited)
    var links := []                   # {pos: Vector3, from_floor, to_floor, seen: bool}  (▲/▼)
    var pins := []                    # {id, biome, floor, xz: Vector2, icon: int (0..7), label: String (max 24), owner}
    var clue_count := {}              # biome -> 0..3 (shared, from the world state)
    var graves := []                  # {biome, floor, xz, owner}
```

### 4.2 How exploring reveals the map

| Rule | Number |
|---|---|
| Always reveal around you | radius **6 m** (even in the dark) |
| Lantern sight | every **0.4 s**, cast **48 rays** in a flat fan at head height + **16 rays** tilted ±30°; reveal every pixel along each ray up to the hit point + 1 m, max **32 m** (or the lantern light radius, if smaller) |
| Classify a pixel | For its column (x, z) inside the current floor's 20 m: sample the SDF every 1 m from the top down. Air with rock directly below = `FLOOR`; air with no rock in the floor = `DROP`; all rock = `ROCK`; inside a water area = `WATER`; a building piece there = `BUILT`; rock with ore material next to air = `ORE` |
| Budget | Classify at most **150 columns per frame** (≈ 3000 SDF reads); queue the rest |
| After digging | If a dig happens in an already-revealed spot, mark those pixels dirty; they re-classify when seen again |

### 4.3 Drawing (one shader on a `TextureRect`)
- Inputs: a parchment texture, the page's class texture (nearest filtering), a small noise texture.
- `FLOOR` = light parchment; `ROCK` = soft brown hatching; `DROP` = darker dotted area; `WATER` = blue-grey
  ink wash; `BUILT` = dark ink squares; `ORE` = tiny orange dots; `UNKNOWN` = blank parchment.
- **Ink outlines:** where a `FLOOR` pixel touches a `ROCK` pixel, draw a dark line. Wobble the UV a little with
  noise so it looks hand-drawn.
- Icons (player arrow, pins, ▲/▼, clue circles, grave) are normal Controls on top, placed by x, z.
- Header: "Mossy Hollows — Floor 2 of 4". The page follows the player's floor; **PgUp/PgDn or the mouse
  wheel over the page edge** flips pages. Map zoom: 0.5×–4×.

### 4.4 Markers

| Marker | When it appears |
|---|---|
| ▲ / ▼ | (a) Planned links (spiral ramps, galleries, drop shafts that cross a floor line): shown once their pixel is revealed. (b) **Trail markers:** whenever a player's floor index changes and no marker is within 12 m, add ▼ on the upper page and ▲ on the lower page at that x, z. This covers your own dug shafts and built stairs for free. |
| Pins | Player places them (8 icons, a short label). Max 200 per world. |
| Boss clue circle | After clue 1 / 2 / 3 (3.2), drawn on the lair's floor page(s). Other pages of that biome show a small note "Clue: Floor 3". |
| Grave | Skull icon where you died, on that floor's page. If you're on another page, a skull at the page edge with "▲2"/"▼1" telling how many floors away. |

### 4.5 Saving
Each page saves as a PNG (400 × 400 grayscale, usually under 20 KB). Pins, links and graves save as JSON.

---

## 5. Building pieces (Step 4)

> **In plain words:** building uses a 2 m grid (chunky, like big dwarf blocks). Pieces snap together at their
> edges and corners. You turn them in quarter turns. A piece can't be pushed into rock (only blueprints can
> carve rock). Each material has its own strength and its own look.

### 5.1 Grid, snapping and rotation

| Rule | Value |
|---|---|
| Main grid | **2 m** (walls 2 × 2, floors 2 × 2). Half pieces 1 m exist. |
| Snap points | Each piece lists them: corners, edge midpoints, centre (floors); ends + middle (beams); bottom, middle, top (pillars). |
| Snap search | Within **0.6 m** of the aim point, pick the closest snap point of a nearby piece; line up the new piece's matching point. |
| Rotation | **Q / E = 90° turns.** When **not** snapped: hold Shift + wheel for 15° steps. When snapped, rotation follows the neighbour (90° steps relative to it). Pieces never tilt (pitch/roll = 0); slopes are their own pieces. |
| World grid (G key) | Toggle: first piece snaps to the global 2 m grid (helps line up a whole base and blueprints). Default **on**. |
| Reach | Place within 8 m of the dwarf. |

### 5.2 Is this spot allowed? (placement validity, checked in order)

1. **Terrain:** sample the SDF at the piece's check points (8 corners of its box shrunk by 0.1 m, the box
   centre, and 6 face centres). Not allowed if any point is more than **0.35 m** inside rock. Floor pieces,
   pillars, stairs and stations may sink their **bottom** points up to **0.6 m** (uneven cave floors).
2. **Other pieces:** box shrunk by 0.05 m must not overlap another piece (`PhysicsShapeQueryParameters3D`).
3. **Bodies:** no player or monster inside the box.
4. **Protected areas:** not in a border slab, not in the main-boss arena while the boss is awake,
   not within 2 m of a gate archway or rune shrine pedestal.
5. **Stability** after placing must be ≥ **10%** (5.6).
6. **Cost:** the materials are in the bag.

Ghost colour: green = OK, red = not allowed, with a one-line reason at the crosshair ("Inside rock").

### 5.3 Materials, HP and styles

| Material family | Item used | Where it comes from | Piece HP (per 2×2 wall) | Notes |
|---|---|---|---|---|
| Wood (rootwood) | `wood` | Root Groves (Mossy) | 200 | Cheap, light, best for early bases |
| Capwood | `capwood` | Giant mushrooms (Fungal) | 260 | Fungal wood, a bit stronger |
| Mushroom brick | `mushroom_brick` | Crafted: mushroom flesh + dirt | 300 | Soft, warm look |
| Rough stone | `stone` | Stone (Mat 1) | 500 | Default heavy material |
| Marble | `marble` | Mat 5 | 600 | Old dwarf look (ruins) |
| Basalt / brown rock / clay / sandstone | `basalt`, `brown_rock`, `clay`, `sandstone` | Mat 6, 7, 10, 11 | 450–550 | Colour choices |
| Copper metal | `copper_bar` | Smelted copper | 800 | Trims, beams, doors |
| Silver metal | `silver_bar` | Smelted silver | 900 | Fungal-tier trims |
| Crystal / decor | `crystal` | Geodes, crystal clusters | 150 | Glows; decoration, lamps, windows |
| Moss / vine thatch | `fiber` | Moss, vines | 80 | Roof/canopy covers only |

**Three styles per biome** (a style = a material set + a matching look for every piece):

| Biome | Style | Main materials | Feeling |
|---|---|---|---|
| Mossy Hollows | **Rootwood Lodge** | wood + fiber thatch + copper nails | Cosy cabin |
| Mossy Hollows | **Hollow Stone** | rough stone + brown rock + copper trims | Sturdy mine house |
| Mossy Hollows | **Marble Hall** | marble + basalt + copper | Old dwarf grandeur (matches the ruins; ancient blueprints use it) |
| Fungal Jungle | **Capwood** | capwood + mushroom cap roof tiles | Round, organic |
| Fungal Jungle | **Spore Brick** | mushroom brick + clay | Earthy, soft colours |
| Fungal Jungle | **Kiln Clay** | orange clay + sandstone + silver | Warm, fired-brick look |

### 5.4 Piece catalog

"Units" = how many items of the piece's material it costs. Every structural piece exists in every
material family (except thatch); costs are the same across families.

| Piece | Size (m) | Units | Extra cost | Snap / notes |
|---|---|---|---|---|
| Wall | 2 × 2 × 0.3 | 4 | — | Edges + corners |
| Half wall | 2 × 1 × 0.3 | 2 | — | |
| Narrow wall | 1 × 2 × 0.3 | 2 | — | |
| Triangle wall | 2 × 2 (half) | 2 | — | Gable ends, under slopes |
| Floor | 2 × 2 × 0.25 | 4 | — | Corners, edges, centre |
| Small floor | 1 × 1 × 0.25 | 1 | — | |
| Beam | 2 m, 0.3 thick | 2 | — | Ends + middle |
| Short beam | 1 m | 1 | — | |
| Diagonal beam | 2 m at 45° | 2 | — | Braces |
| Pillar | 0.4 × 2 × 0.4 | 3 | — | Bottom, middle, top |
| Short pillar | 0.4 × 1 × 0.4 | 2 | — | |
| **Mine prop (support beam)** | post 2–4 m (adjusts to the ceiling) + 2 m header | 4 | +1 copper bar | **Rock support** (section 6). Wood/stone/metal only. Stretches to touch the ceiling (max 4 m). |
| Stairs | 2 × 2 × 2 (45°) | 6 | — | Walkable |
| Ramp | 2 × 1 × 2 (26.6°) | 4 | — | Walkable, carts later |
| Ladder | 0.6 × 2 | 2 | wood or metal only | Climbable (crosses floors → ▲/▼ trail marker) |
| Door + frame | 2 × 2 wall with a 1 × 2 door | 4 | +2 copper bar (hinges) | Opens both ways; can be locked to "owner + friends" |
| Big gate | 4 × 4 | 12 | +4 copper bar | Double door |
| Trapdoor | 2 × 2 floor | 4 | +1 copper bar | |
| Window wall | 2 × 2 with 1 × 1 hole | 3 | +1 crystal (glass) optional | |
| Shutters | 1 × 1 | 1 | wood/metal | |
| Railing / fence | 2 × 1 | 1 | — | |
| Slope roof 26° / 45° | 2 × 2 | 3 | — | For looks (no rain underground) and to catch ceiling drips |
| **Ceiling panel** | 2 × 2 | 4 | — | Snaps **upward** against the rock ceiling; counts as rock support when its top touches rock |
| Canopy (thatch) | 2 × 2 | 3 fiber | — | Light cover, very weak |
| Wall sconce / lantern post | 0.5 / 2 m | 1 | +1 crystal | Light (crystal colour = light colour) |

**Furniture and stations** (recipes belong to Step 3 crafting; numbers are a starting point):

| Station / furniture | Footprint | Cost | Job |
|---|---|---|---|
| Bed | 1 × 2 | 8 wood, 4 fiber | Wake-up point after death |
| Small chest | 1 × 1 | 6 wood, 1 copper bar | 16 slots |
| Large chest | 2 × 1 | 10 wood, 2 copper bar | 32 slots |
| Workbench | 2 × 1 | 10 wood, 4 stone | Basic crafting; needed nearby for building |
| Stonecutter | 2 × 1 | 12 stone, 2 copper bar | Rock → building blocks (all rock colours) |
| Smelter | 2 × 2 | 20 stone, 6 dirt | Ore → bars |
| Forge + anvil | 2 × 2 | 20 stone, 10 copper bar | Tools, weapons, upgrades |
| Cooking pot / hearth | 1 × 1 | 8 stone, 2 copper bar | Food |
| Mushroom planter | 2 × 2 | 6 wood, 8 dirt | Farming |
| Drip bucket | 1 × 1 | 3 wood | Water under a dripping ceiling |
| **Rune Slab** | 2 × 1 × 2 | 30 stone or marble | Carve runes (one per world) |
| **Builder's Chest** | 1 × 1 | 8 wood, 2 copper bar, 1 crystal | Builds blueprints (section 7) |
| Table, bench, chair, shelf, banner | various | 2–6 wood | Comfort/decoration |

Piece HP scales with size: **HP = family HP × units / 4** (a 2 × 2 wall = family HP; a beam = half).
Destroyed pieces drop **50%** of their cost. Removing your own piece (hammer, hold to deconstruct) returns
**100%**.

### 5.5 Damage
Monster damage to pieces is multiplied by material: wood 1.0, capwood 0.9, mushroom brick 0.8, stone/rock
0.6, marble 0.55, metal 0.4, crystal 1.2, thatch 1.5. (Raids target the weakest piece near the base.)

### 5.6 Building stability (how pieces hold each other up)

> **In plain words:** a piece that touches rock is 100% steady (in a cave, the floor, walls and ceiling all
> count). Every piece further away from rock is a little less steady. Wood loses steadiness fast, stone a
> bit slower, metal slowest. Sideways (like a long bridge) loses more than straight up. Below 10%, a piece
> falls apart. The ghost shows the colour (blue steady → red shaky) while placing.

| Material | Loss going **up** (per piece) | Loss going **sideways / hanging** (per piece) | Example: sideways reach from rock |
|---|---|---|---|
| Thatch / canopy | 30% | 45% | 2 pieces (4 m) |
| Crystal | 15% | 40% | 2 pieces |
| Wood / capwood | 10% | 20% | 4 pieces (8 m) |
| Mushroom brick | 8% | 25% | 3 pieces |
| Stone / rock colours / marble | 5% | 30% | 3 pieces (6 m) |
| Copper / silver metal | 4% | 12% | 7 pieces (14 m) |

- **Anchored (100%)**: the piece's check points touch rock (SDF within 0.3 m of 0) at its bottom, top
  (ceiling) or a side. In a cave this is almost always true for the first piece.
- **Others:** `stability = max over snapped neighbours n of (stability(n) − loss)`, where the loss is the
  **up** value if `n` is below this piece and the **sideways** value otherwise (side or hanging from above).
- **Update:** when a piece is added, compute its value from neighbours and push improvements outward
  (breadth-first). When a piece is removed or the rock under it is dug, reset its connected group
  (max 2000 pieces) and recompute from all anchored pieces. Pieces that end up below 10% break after
  0.5 s (one at a time, 0.1 s apart, so it looks like a collapse, not a pop).
- Runs on the host only. Cheap: pieces are few compared to voxels.

---

## 6. Support and cave-ins (Step 4)

> **In plain words:** rock only falls when nothing holds it up. Two situations:
> 1. **A loose island:** you dig all around a lump of rock until it isn't attached to anything. It falls.
> 2. **A long icicle:** a thin hanging piece of rock, about 20 m long or more, attached only at its top.
>    It snaps off and falls.
>
> Shorter overhangs, ledges, arches and big hanging slabs stay up: the limit is generous on purpose.
> Before rock falls you get 1 second of warning (dust, creaking). Mine props and ceiling panels hold rock up.

### 6.1 Numbers

| Name | Value | Meaning |
|---|---|---|
| `HANG_LIMIT` | **20 m** | A thin hanging piece this long (or longer) falls. |
| `THIN_FILL` | **16 of 25** | A hanging piece counts as "thin" at a height if fewer than 16 of the 25 voxels in a 5 × 5 square around it are rock. |
| `ISLAND_MAX` | **20 000 voxels** | Islands bigger than this never fall ("wedged in"). ~27 m cube. |
| Anchor | — | Border/edge rock; a voxel inside a block that is **completely solid** (tracked per block); any voxel within 0.75 m of a mine prop's or ceiling panel's contact point. |
| `WARN_TIME` | 1.0 s | Dust + rumble before falling. |
| Chain limit | 3 | A fall may trigger at most 3 follow-up checks. |

**Why "a voxel in a completely solid block is an anchor" is safe:** a falling island would have to contain
a whole 16 × 16 × 16 m solid cube. That is far above the generous limit anyway, and it lets the check stop
very early in normal rock (big rock walls almost always have a full block within a few metres).

Keep a `PackedByteArray` (or Dictionary) "block is fully solid" flag: set at generation (fast path blocks),
cleared when any voxel in the block becomes air.

### 6.2 Algorithm (runs on the host after each dig, carve or explosion)

```
after_dig(center: Vector3, radius: float):
    queue_check(center, radius)          # checks are batched: at most one per area every 0.25 s

run_check(center, radius):
    # --- A. Islands ---------------------------------------------------------
    seeds = rock voxels in the shell radius .. radius + 1.5 around center (about 50-150 voxels)
    visited = {}                          # key = packed voxel position (int)
    for s in seeds:
        if s in visited: continue
        result = fill(s, visited)         # breadth-first over the 6 neighbours, rock voxels only (SDF < 0)
        if result.anchored: continue      # touched an anchor, or grew past ISLAND_MAX voxels, or > 48 m from center
        schedule_fall(result.voxels)      # a real island
    # --- B. Icicles ---------------------------------------------------------
    for each column (x, z) within 4 m of center:
        for each "bottom" voxel b in the column with b.y in [center.y - 24, center.y + 4]:   # rock with air directly below
            if b already falling: continue
            y = b.y; h = 0
            while h < HANG_LIMIT + 1:
                if rock_count_5x5(x, y, z) >= THIN_FILL: break   # reached thick rock = the root
                y += 1; h += 1
            if h >= HANG_LIMIT:
                piece = fill_below(b, root_y = y, cap = 3000)    # rock connected to b, only voxels with y < root_y
                if not piece.anchored and not piece.capped:
                    schedule_fall(piece.voxels)

fill(start, visited) -> {voxels, anchored}:
    stack = [start]; voxels = []
    while stack:
        v = stack.pop_back()
        if is_anchor(v): return {anchored = true}          # leave the rest visited: they are attached too
        voxels.append(v)
        if voxels.size() > ISLAND_MAX or v.distance_to(center) > 48: return {anchored = true}
        for n in 6 neighbours of v:
            if n not in visited and sdf(n) < 0: visited[n] = true; stack.append(n)
    return {voxels, anchored = false}
```

**Reading voxels fast:** copy the area into a `VoxelBuffer` with `VoxelTool.copy()` once (start with a
33³ box around the dig; if the fill reaches the box edge, copy a 65³ box and continue). Work on the copy,
not on `get_voxel_f` calls. Use `PackedByteArray` for "visited" inside the box (index = x + y·W + z·W·W).

**Cost:** most digs hit an anchor (a full block) within a few hundred voxels: well under 1 ms. The worst case
(20 000 voxels) is about 20–40 ms in GDScript, so the fill runs on a `WorkerThreadPool` task using the
copied buffer, and the result is applied on the main thread. Digging a loose rock is rare, so this is fine.

### 6.3 What falling looks like

1. Host sends `CaveInWarning(id, center, size)`: dust particles drip from the piece, a creak sound plays,
   for `WARN_TIME`.
2. Host removes the voxels (SDF set to +1 in a single paste) and sends `CaveIn(id, packed voxel mask)`.
3. Everyone spawns **rubble**: `ceil(voxels / 8)` boulders (max 12), each a `RigidBody3D` with a premade
   rock mesh scaled to its share of the volume, starting at the island's position.
4. When a boulder stops (or after 4 s) it breaks into dropped items: **1 stone item per 4 voxels**
   (same material mix as the island; ore stays ore).
5. **Damage:** a boulder hitting a player does 15 damage + a knockback (see question 5). Pieces hit by
   rubble take 50 damage per boulder.
6. Chain check: run `run_check` again at the top of the removed area (max 3 chained).

### 6.4 Supports for rock

- **Mine prop** and **ceiling panel** (when its top touches rock) make the voxels within 0.75 m of their top
  contact points **anchors**. A rock lump held up by a prop doesn't fall, even if it's otherwise an island.
- Removing a prop runs `run_check` at its top contact point. (So knocking out the last prop under a big
  loose slab brings it down: that's the fun "danger" moment.)
- Building pieces hit by falling rubble can break, and broken props can start further falls (chain limit 3).

### 6.5 Test cases (auto-checks)
- Dig all around a 4 m ball of rock → it falls.
- Carve a 22 m thin hanging spike, then touch it → it falls. Same with an 18 m spike → stays.
- A 30 m long, 4 m thick ledge → stays. An arch → stays.
- A loose lump under a mine prop → stays; remove the prop → falls.
- Natural stalactites (≤ 8 m) never fall when you dig next to them.
- Digging inside solid rock (normal mining) never causes a fall and costs < 1 ms per check.

---

## 7. Blueprints and the Builder's Chest (Step 4)

> **In plain words:** a blueprint is a saved building. You get one by drawing a box around something you
> built, by finding old ones in ruins, or as a file from a friend. You place it as a see-through ghost and
> put down a Builder's Chest next to it. Fill the chest with materials and it builds the house by itself,
> one piece per second, from the bottom up. If the ghost is inside rock, the chest first carves the rock
> away (and keeps the rock it dug!). If materials run out, it waits.

### 7.1 Blueprint file format

Saved in `user://blueprints/<name>.dwbp` as JSON text (easy to share; shown below).

```json
{
  "format": 1,
  "name": "Small Rootwood Lodge",
  "author": "Player name",
  "created": "2026-11-20",
  "source": "player",                      // "player" | "ancient" (found in ruins)
  "size": [12, 8, 10],                     // selection box in metres (max 32 x 24 x 32)
  "origin": "bottom_center",               // positions below are relative to the box's bottom centre
  "chest_hint": [0, 0, 6],                 // suggested chest spot (optional)
  "pieces": [
    {"id": "wall_2x2",  "mat": "wood",  "pos": [-4.0, 0.0, -3.0], "rot": 0, "anchor": "rock"},
    {"id": "floor_2x2", "mat": "stone", "pos": [ 0.0, 0.0,  0.0], "rot": 1},
    {"id": "door",      "mat": "wood",  "pos": [ 0.0, 0.0,  5.0], "rot": 2}
  ],
  "air": {"cell": 1, "rle": [140, 12, 3, 9]},   // carve mask, see 7.2
  "cost": {"wood": 64, "stone": 40, "copper_bar": 6},   // recomputed on load, shown in UI
  "check": "a1b2c3d4"                       // checksum of the pieces + air, to spot broken files
}
```
- `pos` is in metres, always a multiple of 0.5. `rot` = quarter turns (0–3) around the vertical axis.
- `anchor: "rock"` marks pieces that touched rock when captured (shown in the ghost so you know they need
  rock there).
- **Loading a file is a trust boundary** (files come from friends and the internet). On load: check
  `format`; every `id` and `mat` must be in the known piece list; numbers must be finite and inside `size`;
  max **2000 pieces**; `size` within the limits; `rle` must add up to exactly the box's cell count;
  ignore unknown fields. Never run anything from the file. Reject the file with a clear message if any check fails.

### 7.2 Capture tool ("Surveyor's Chalk", crafted at the workbench)

1. Click a first corner, then a second corner: a box appears (grid-aligned to 1 m). Mouse wheel changes the
   height. Max 32 × 24 × 32 m.
2. Confirm: the game collects every **own or friend's** piece whose centre is inside the box.
3. It records the **air mask**: for each 1 m cell in the box, 1 = "this cell is open air now", 0 = "leave it as
   it is". Stored as run-lengths (`rle`): alternating counts of 0s and 1s, starting with 0s, in x→z→y order.
   This is what the chest will carve later. It means a room you built in a natural cave gets the same
   open space wherever you place it.
4. Name it, save. The cost is calculated from the pieces.

### 7.3 Placing a blueprint

- Pick it from the blueprint book. The ghost follows your aim; it snaps to the world 2 m grid
  horizontally and 1 m vertically. **Q / E rotate 90°.** Wheel moves it up/down 1 m.
- Ghost colours: pieces = blue glass; cells that will be carved = red dotted outline; problems = red solid.
- A panel shows: cost, "will carve 340 m³ (stone ~280, copper ore ~12)", and warnings.
- **Not allowed** (red, can't confirm) if the carve mask or pieces touch: border or edge rock; a main-boss
  lair's protected walls; a gate archway or shrine; another active blueprint's box; existing pieces that
  are different from the planned piece at that spot.
- Existing pieces that **exactly match** a planned piece (same id, material, position, rotation) count as
  already built. This makes "repair my house" work by re-placing its blueprint.
- **Warnings** (allowed, but shown): pieces marked `anchor: rock` with no rock at their new spot;
  "carving this will make loose rock fall" (the cave-in check 6.2 runs once on a copy of the area, and the
  rock that would fall is outlined in orange).
- Then place the **Builder's Chest** within **16 m** of the box (or at `chest_hint`). Plan + chest become one
  "build site". Max **3 active build sites per world** (host setting).

### 7.4 The build loop (host only, one tick per second)

**Setup when placed:**
```
carve_cells  = cells where air mask = 1 and the world there is rock now
carve_order  = breadth-first starting from carve cells that touch existing air, nearest to the chest first
               (the chest eats into the rock like a miner, never leaves floating chunks on purpose)
build_order  = plan pieces sorted by "support depth":
               depth 0 = pieces that will touch rock (after carving) ;
               depth n = pieces that snap to a depth n-1 piece  (breadth-first over the snap graph)
               ties: lower y first, then nearer to the chest
               pieces that no path reaches are "unsupported" and are listed in the warning, never built
```

**Each tick:**
```
tick():
    if paused_by_owner: return
    # 1. Carving runs on its own faster timer (every 0.5 s), one 2x2x2 m group of carve cells per step
    if carve_order not empty:
        cell = next group in carve_order whose space is free of players/monsters
        if none free: status = "Waiting: someone is in the way"; return
        dig cell (same path as a pickaxe dig, so cave-in checks run) ; rock items go INTO the chest,
        overflow drops on the ground next to it
        return
    # 2. Building (1 piece per tick)
    p = first piece in build_order that is: not built, its supporter is built, its space is free,
        and the chest holds its cost
    if p == null:
        if all built: status = DONE; ghost disappears; chest becomes a normal chest
        elif missing materials: status = "Paused: needs 6 wood, 2 copper bar"
        else: status = "Waiting: something is in the way"
        return
    take cost from chest; spawn piece with a 0.8 s "rises from dust" animation; mark built
```
- **Skip-ahead** (see question 3): the loop takes the *first buildable* piece, so if wood is missing it keeps
  building stone pieces whose supports are ready. With "strict" mode it would stop at the first missing piece.
- Building speed: **1 piece per second.** Carving: **one 2 × 2 × 2 m group per 0.5 s** (shown as dust and
  pick sounds coming from the ghost).
- The chest keeps the build area loaded on the host by carrying a small `VoxelViewer` (radius 32 m) while
  the build site is active, so building continues when players walk away (host only).

### 7.5 Edge cases

| Situation | What happens |
|---|---|
| Player standing in a planned spot | That piece waits; others continue. The spot glows yellow, chest says "Someone is in the way". Never pushes players. |
| Monster in the way | Same as a player. |
| Monster (or rubble) breaks a built piece | It goes back to "not built" (needs materials again; the broken piece dropped 50%). Pieces that lose support (5.6) also go back. |
| Someone digs or a cave-in fills the carve space | Every 10 s the chest re-checks its carve cells; new rock is queued for carving again. |
| Someone builds a different piece inside the plan | That planned piece is marked "blocked" (red) and skipped. Remove the stranger piece to unblock it. |
| Chest destroyed | Its items drop in a sack. The plan stays as a ghost, paused. Placing a new Builder's Chest within 16 m resumes it. |
| Cancel (owner or host only) | Ghost removed. Built pieces stay. Materials stay in the chest. Carved rock stays carved. |
| Carve meets border rock / protected rock (shouldn't happen) | That cell is skipped and logged. |
| Carving drains a pool | Normal water rule (2.8). |
| Chest full of carved rock | Overflow drops on the ground beside the chest (auto-pickup works there). |
| Save and load mid-build | Build site saves: blueprint JSON, transform, built flags, carve progress, chest id. |
| Found (ancient) blueprints | Same file format, made by us with the capture tool and shipped with the game. Ruins (POI 2, 3) are stamped from them with ~30% of pieces missing/broken. Picking up the blueprint item adds it to your book. |
| Sharing with friends | Blueprint book has "Copy file" / "Import file". In co-op, placing a blueprint sends its JSON to the host, who validates it (7.1) before anything happens. |

---

## 8. Co-op notes

> **In plain words:** all changes to the world go through the host, even when you play alone:
> you **ask**, the host **checks and says yes**, then **everyone** applies the same change. That way all
> four players always see the same caves and buildings.

**Every world edit is a request with a running number.** The host applies them in order and broadcasts
the result with its own sequence number; clients apply results strictly in that order.

| Request (from a player) | Host checks | Broadcast (to everyone) |
|---|---|---|
| `Dig(center, radius, tool_tier)` | Reach (≤ 4 m from that player), area loaded, tier vs material/border | `DigDone(seq, center, radius, tool_tier)` → every PC runs the same `apply_dig`; host spawns the drops |
| `PlacePiece(id, mat, transform)` | All of 5.2 + cost in that player's bag | `PieceAdded(seq, piece_uid, id, mat, transform)` |
| `RemovePiece(uid)` | Owner/permission, reach | `PieceRemoved(seq, uid, reason)` |
| `PlaceBlueprint(json, transform)` + `PlaceChest(...)` | 7.1 validation + 7.3 rules | `BuildSiteAdded(seq, site_id, json, transform, chest_uid)` |
| (host-made) carve step | — | `DigDone(...)` (same as a pickaxe dig) |
| (host-made) build step | — | `PieceAdded(...)` |
| (host-made) cave-in | — | `CaveInWarning(id, ...)`, then `CaveIn(seq, id, box_origin, box_size, compressed bit mask)` |
| (host-made) stability break | — | `PieceRemoved(seq, uid, "collapse")` |
| `AddPin` / `RemovePin` | Max 200 | `PinsChanged(...)` |
| `MarkingRead(poi_id)` | Player is near it | `ClueCount(biome, n)` |
| Map reveals | (no check needed) | Each client classifies its own pixels; every 2 s a client sends newly revealed pixels as small compressed bit masks; the host merges and forwards (shared map, see question 2). |

**Why the cave-in sends a bit mask instead of "check here":** if any PC were even one voxel different, a
re-run could give a different result. The mask is the safe answer (a 33³ box = 4.5 KB, compresses well).

**What a joining player receives:** world seed + game version, then the **changed blocks** (every block that
differs from what the seed generates, as compressed voxel data), all pieces, build sites, POI states,
map data, pins, clue counts, graves. After that, live updates. (The save file is the same list.)

**Must stay identical on every PC:** the generator code and game version (refuse to join on a version
mismatch), the seed, the order of applied edits. The determinism check (2.1 rule 6) protects the first one.

---

## 9. Open questions for you

Each has a suggested answer (marked ★) that this document already assumes.

1. **Which way is the Fungal Jungle?**
   A) East ★ B) North C) West D) South (only matters for how the map looks).
2. **Is the map shared in co-op?**
   A) One shared map for everyone ★ B) Each player has their own map C) Own map, but you can "copy map" at a map table.
3. **Builder's Chest out of one material — what should it do?**
   A) Keep building other pieces it can afford, bottom-up ★ B) Stop completely until that material arrives.
4. **May you carve rock when placing pieces by hand?**
   A) No, only blueprints carve ★ B) Yes, holding a key carves the spot (takes digging time) C) Only after a Smith & Builder skill.
5. **How much do cave-ins hurt?**
   A) Big damage (real danger) B) Light damage + knockback ★ C) No damage, just a scare.
6. **Building grid size?**
   A) 2 m, chunky dwarf blocks ★ B) 1 m, finer detail but more pieces to place C) 2 m with free 1 m half-pieces everywhere.
7. **Main boss lair?**
   A) Sealed in rock, you dig in after the 3rd clue ★ B) Behind a hidden breakable wall at the end of a tunnel C) Behind a door that only opens after the 3rd clue.
8. **Border gates?**
   A) Gate tunnels leave a thin 4 m plug ★ B) No gates, the whole 20 m wall is the same everywhere C) Gates only, the rest of the border is never diggable.
