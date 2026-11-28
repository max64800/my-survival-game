# Zone 1 shrink + wayfinding plan (F969 to F974), Nov 28, 2026

Owner's play test 2 (flying over the map): zone 1 is too big, caves are empty, two ruins share a cave, some shrines
can't be reached, and there's no way to know where to go. Brainstormed with the owner first (Nov 28, "talk first, no
cave changes before that"). This file is the build plan; build it in the steps below, each playable before the next.

## The owner's choices (Nov 28)
- **Size (F972):** zone 1 about **500 m** wide (was 800). The white paths stay as they are.
- **One place per cave (F973), fewer small places:** zone 1 holds
  - the first cave (start, watchtower),
  - **12 ruins** (the named ones: Watchtower, Outpost, Brewhall, Spire, Manor, Prow Hall, Twin Gate, Smeltery,
    Brickcrown, Mine-head, Cliff Galleries, Pillar Spiral), each in its **own** cave, all in zone 1,
  - **12 dungeons**, each behind the wall of its **own** cave. The 7 built ones go live now (Mossgate, Lampwick,
    Pell, Mossprop, Hald, Barrows, Brassgate). The 5 not built yet: their cave is kept for them and holds **a camp
    for now**; when a dungeon is made, its door goes in that cave's wall,
  - the Great Hall, the 2 Copper Deeps,
  - **about 10** small camps and nests (today about 21; the old plain small "ruin" rooms go),
  - = about 38 caves, and **no cave without a place**.
- **F971:** two ruins never in the same cave (one "taken" list for all ruins, plus a test).
- **F969:** **every rune shrine open**, on a tunnel or cave wall you can walk to. No sealed (buried) shrines.
- **F974:** **Mossgate Hold** (the first dungeon, Nov 19) is the tutorial dungeon, its door in the **wall of the first
  cavern** (the cavern stays open for building).
- **F970 wayfinding, all four, in this order after the shrink:**
  1. landmark glows (each place shows its own light/sign from far off),
  2. old dwarf signposts at tunnel forks, pointing to the nearest place you haven't found,
  3. a compass strip at the top of the screen (nearest unfound place),
  4. the map that fills in. A map screen already exists (`src/ui/map_panel.gd`, `src/ui/map_data.gd`, floors,
     reveal): improve it (places marked once seen), don't build a new one.
- **Old saves don't need to keep working** (owner). Still make it a new layout number (layout 20) so the code stays
  clear; old worlds may simply keep their old layout.

## Where things are now (layout 19, survey Nov 28)
- `CaveMaker._init` (cave_maker.gd ~195): `_lay_out` mossy = `_place_rooms_v2` (~1576: 8 big caverns 170 m apart,
  14 halls, 40 small) + `_connect_rooms_v2` (~1787); `_find_spawn`; `_pick_deeps` (~2698, 140-320 m from spawn);
  `_plan_pois` (~2201: Great Hall, plan of 30 ruin/nest/camp small rooms, the old sealed lair, geodes, 9 open + 6
  sealed shrines); fungal zone; columns; `_plan_start`; bridges; `_reserve_tower` (~485: Tower then the 11 named
  ruins in order, each `pick` excludes some earlier ruins' rooms by index: **Smeltery to Pillar Spiral don't
  exclude the Outpost, Brewhall or Spire rooms, and nothing keeps ruins apart = F971**); `_plan_dungeons` (~317,
  `DungeonMap.find_spot` dungeon_map.gd ~534: mossy rooms 80-260 m from spawn); `_plan_trail` (~418).
- Size: `use_layout` (~90) sets HALF_SIZE 400 for every layout >= 2. **HALF_SIZE is shared by both zones** (the
  fungal zone's cx follows it). Distances that assume 800 m: 170/120 m big-cavern gap and 110 first reach (~1584),
  halls 75, small 45, lair 150, deeps 140-320 (target 230), dungeons 80-260 (best 150), nests not within 60 m.
- Dungeons: `DungeonMap.MAPS` (dungeon_map.gd ~385); `since` 14/15/16/17 live, Hald 20, Barrows 21, Brassgate 22
  (test worlds only). **Layout 20 = this plan: set Hald, Barrows and Brassgate to `since = 20`** and tell the
  Brassgate chat (it planned its own number).
- Map: `MapData.size = HALF_SIZE * 2` (map_data.gd ~16), so it follows the shrink.
- `src/world/dungeon_places.gd` (12 dungeons in rings) is dead code: only `tests/test_dungeon_places.gd` uses it.

## Step 1: the smaller zone 1 (layout 20). F969, F971, F972, F973, F974
Layout 20 places caves **from a list of places**, not "N rooms, then hand out places":
1. `use_layout`: zone 1 half-size 250 for layout >= 20. **Zone 2 stays 800 m (owner, Nov 28: "only zone 1")**, so
   give each biome its own half-size (BIOMES entries; every HALF_SIZE use must take the zone's own size: borders,
   gates, `_clamp_inside`, map size, room spans).
2. A place list: start cavern, 12 ruin caverns (big, sized for their ruin), 12 dungeon caves, Great Hall cavern,
   2 Deeps, ~10 small camp/nest rooms. Place each as a room (spacing scaled to 500 m), mark the room with its place.
3. Each named ruin's `pick` only looks at rooms marked for ruins and not taken (one shared taken list, F971).
4. `DungeonMap.find_spot` for layout >= 20: dungeon i uses its own marked cave; Mossgate (MAPS[0]) uses the first
   cavern's wall (F974). Future dungeon slots get a camp.
5. Shrines: layout >= 20 makes all of them open alcoves on tunnels (no `sealed` shrines). Geodes stay as they are.
6. Drop the old sealed "lair" hollow for layout >= 20 (it only kept old saves' shapes).
7. Scale the distance numbers above for 500 m.
8. Tests (run on 3 seeds, `full=1` at the end): every room has exactly one place (none empty); no two ruins in one
   room and ruins far enough apart; every place and every shrine reachable by walking from the spawn (flood fill over
   rooms + tunnels); Mossgate's door is in the first cavern; zone 1 width ~500 m; the existing tower, column, trail,
   ruin-spot and dungeon tests still pass.
9. Playtest: owner flies the map (`claude=zone1_small`), then plays the first cave + Mossgate.

## Step 2: landmark glows (F970 part 1)
## Step 3: signposts at forks (F970 part 2)
## Step 4: compass strip (F970 part 3)
## Step 5: the map marks places (F970 part 4)
Each of steps 2-5 starts with a short talk with the owner (what it looks like), then a small build + "go play test".
