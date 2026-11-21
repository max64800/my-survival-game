# Decor catalogue (Nov 22, 2026)

Every decor model from the decor night (the `tools/asset_forge/builds/decor_nov21_*.py` files): **530 models**, plus
12 looted `_empty` twins (named in their full model's Notes). Nothing here is placed in the game yet: the owner looks at
this list first. Rules for decor: `docs/art/DECOR-BRIEF-NOV21.md`. Placement rule: `CLAUDE.md` (nothing grown inside
built things; keep paths, doors and stairs free).

How to read a row:
- **Where it goes**: the place and the kind of room. "(guess)" = our best guess, the build file didn't say.
- **How it's placed**: floor / against a wall / flat on a wall / hanging / in a corner, then the size
  (width × depth × height in metres, measured from the model), then alone or in a group.
- **Notes**: lootable (and how much), a lid that opens, walk-through, "Heavy file" (over about 1 MB: fine for a few,
  not for dozens), or a clash with the decor rules.
- Older decor (`night_decor.py`, `furniture.py`, 99 models such as `keg`) is not in this list.

## Things that clash with the owner's decor rules (owner decides: keep, fix or remove)
Found while writing this list, from the build files (not yet checked by eye):
- **Water, puddles or spills:** `floor_grate` (puddle in its shaft), `table_overturned` (spilled puddle; a 10/10 pick),
  `ef_cracked_quench` (water in the tub), `ef_quench_trough` (owner said leave it for now), `cf_moulders_bench`
  (bucket of water), `lw_lamp_fallen_spill` (oil stain), `op_diary_table` (spilled ink).
- **Rails:** `hw_ingot_cart` (+ its `_empty`), `hw_derailed_cart`, `lw_rail_switch_lever`, `lw_spare_rail_rack`,
  `lw_cart_jammed`.
- **Arrows (only crossbow bolts allowed):** `cf_mould_board` has an arrowhead mould. (`rt_arrow_slit_shutter`,
  `rt_arrow_crate_spill` and `ro_archery_bale` only have old names: they hold bolts.)
- **Lit in an abandoned place:** `mg_lantern_post`; Lampwick Drift `lw_lamp_rack_wall`, `lw_signal_lamp_post`,
  `lw_walkway_ladder`, `lw_ledger_desk`, `lw_last_shift_stool` (and maybe `lw_broken_lamp_rack`); Tomb of Hald
  `th_brazier_grand`, `th_niche_candles`, `th_wall_lamp`; 17 Quiet Barrows pieces with candles or lamps (fine if the
  Barrows are still tended?). Lit in places that may still be working: `bv_wall_lantern`, `hs_watch_brazier`,
  `vo_vigil_brazier`, `vo_vigil_candles`, `vo_wall_brazier`, `hw_rivet_brazier`, `cf_crucible_furnace`,
  `cf_crucible_stand`, `cf_ingot_mould_row`, `cf_cooling_rack`.
- **Soft things or food:** `miner_tent` (bedroll inside), `rocking_chair` (throw and seat pad; a 10/10 pick),
  `cage_floor_open` (straw), `last_meal` and `kitchen_block` (food).
- **Looks lootable but has no `_empty` twin:** `offering_bowl_coins`, `th_niche_coins`, `th_offering_table`,
  `th_robber_pinned`, `mg_toll_table`.
- **Name doesn't match:** `hs_tower_shields_chained` has no chain (owner asked for one, Nov 22); `fur_rug` is a woven
  rug; the `mp_bucket_line` header mentions a puddle that isn't in the model.

## Dungeon story pieces, group A (decor_nov21_a.py, no prefix)

Round 1. Old, worn story pieces for dungeons and ruins: stone, root wood, iron. Wall pieces have a flat back.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `ancestor_stone_tall` | Tall carved ancestor name stone | Stone dungeon tomb hall or shrine; home memorial corner (guess) | Floor, against a wall, 1.1×0.6×1.8 m; alone or with the small one | Solemn, grand | Carvings cut into the stone |
| `ancestor_stone_small` | Small name slab with burned-down candles | Tomb hall, shrine niche; home memorial corner (guess) | Floor, against a wall, 0.6×0.4×0.7 m; group with the tall stone | Solemn |  |
| `notice_board_torn` | Roofed plank notice board, torn notes, WANTED sketch | Small dungeon or mine entrance; outpost camp | Floor, against a wall or beside a path, 1.5×0.5×2.0 m; alone | Abandoned |  |
| `hanging_cage` | Iron cage on a ceiling chain, door open, old bones | Prison or cell room of any dungeon | Hanging from the ceiling (needs 2.5 m of height), 0.8×1.0×2.5 m; alone or 2-3 in a row; keep off paths | Eerie | Owner's 10/10 |
| `wall_shackles` | Wall plate with two chains and cuffs | Prison cells, guard room | Flat on a wall, 0.8×0.2×1.5 m; in rows along a cell wall | Grim |  |
| `forge_bellows_broken` | Old torn forge bellows on a stone block | Old forge row in any dungeon or ruin | Floor, 0.7×0.9×0.7 m; group with the cracked anvil | Abandoned |  |
| `forge_anvil_cracked` | Cracked anvil on a tree stump, slag heap | Old forge row, smithy | Floor, 1.2×0.5×0.8 m; group with the bellows | Abandoned |  |
| `skeleton_with_note` | Dead dwarf skeleton slumped on a stone, note in its lap | Dead end or side room of any dungeon (story spot) | Floor, against a wall, 1.0×1.2×0.7 m; alone | Eerie, sad | Heavy file (1.4 MB) |
| `wall_carving_1` | Carved wall picture: dwarves digging ore | Stone dungeon halls, ruins, tomb corridors | Flat on a wall, 1.6×0.2×1.2 m; best as a set of 3 in order | Ancient | Carved in |
| `wall_carving_2` | Carved wall picture: dwarves building a great hall | Same as wall_carving_1 | Flat on a wall, 1.6×0.2×1.2 m; set of 3 | Ancient, proud | Carved in |
| `wall_carving_3` | Carved wall picture: a huge thing rising from the deep, dwarves flee | Same; end of the story, near a deep or dangerous room | Flat on a wall, 1.6×0.2×1.2 m; set of 3 | Ominous | Carved in |
| `pickaxe_in_wall` | Rock face with a pick stuck in it, rubble at the foot | Mine tunnels, dead-end dig spots | Against a wall (flat back), 1.1×1.0×1.0 m; alone | Abandoned |  |
| `miner_tent` | Small canvas tent with a torn flap, bedroll inside | Outside camp at a mine; cave camp spot; outpost | Floor/ground, 1.4×2.4×1.1 m; alone or 2-3 as a camp; keep off paths | Abandoned | Has a bedroll inside (brief: beds bare, no bedding) |
| `lantern_post_burnt` | Scorched post with a cracked, empty lantern | Mine tunnels, burned camp, path edges | Floor, beside a path, 0.3×0.6×1.8 m; alone or in a line | Burnt, abandoned | Lantern is not lit |
| `rope_ladder_broken` | Beam in the wall with a rope ladder, rungs snapped | Shaft walls, ledges in mines and ruins | Against a wall (flat back), 1.0×0.7×2.3 m; alone | Abandoned |  |

## Dungeon story pieces, group B (decor_nov21_b.py, no prefix)

Round 1. Tombs, shrines, spiders and wrecked stores: carved stone, old wood, iron.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `statue_toppled` | Stone dwarf guardian fallen over, head snapped off | Stone dungeon hall, tomb, ruin courtyard | Floor, 1.9×1.5×0.9 m; alone; keep off paths | Ruined, eerie | Made from the real dwarf model. Heavy file (1.7 MB) |
| `statue_cracked_plinth` | Stone dwarf guardian with axe on a cracked plinth | Tomb entrance, gate, great hall | Floor, 1.2×1.1×1.7 m; alone or a pair either side of a door (not in it) | Grand, ancient | Made from the real dwarf model. Heavy file (1.6 MB) |
| `shrine_broken` | Small stone shrine, cracked roof, idol fallen | Tomb hall, chapel corner | Floor, against a wall, 1.1×0.7×1.0 m; alone | Abandoned, sacred |  |
| `offering_bowl_coins` | Carved stone bowl heaped with old coins | Shrine, tomb hall, treasure room | Floor, 0.9×0.8×0.8 m; alone or in front of a shrine or altar | Sacred, rich | Looks lootable but has no _empty twin. Heavy file (1.5 MB) |
| `altar_candles` | Stone altar with candle stubs and wax runs | Shrine, tomb hall, chapel | Floor, against a wall, 1.3×0.7×1.1 m; alone | Solemn |  |
| `sarcophagus_closed` | Stone coffin, lid carved as a sleeping dwarf | Tomb hall, crypt | Floor, 1.8×1.0×0.8 m; in rows | Solemn |  |
| `sarcophagus_open` | Same coffin, lid pushed aside, bones inside | Tomb hall, crypt | Floor, 2.5×1.5×0.9 m; mix with closed ones; keep off paths | Looted, eerie |  |
| `bone_pile` | Heap of old bones with a skull | Monster lair, cells, crypt, dead ends | Floor or corner, 0.9×0.7×0.3 m; scatter a few | Eerie |  |
| `skull_spike` | Skull on a sharpened stake in a rock pile | Warning at a dungeon or lair entrance; camp edge | Floor or outside on the ground, 0.6×0.5×1.2 m; alone or a few | Warning, eerie |  |
| `spider_eggs` | Pale spider egg sacs in webbing | Spider lair, webbed corners | Flat on a wall, 0.9×0.1×0.8 m; clusters | Creepy |  |
| `cobweb_corner` | Old cobweb filling a corner | Upper corners of any old room | In a corner (two flat backs), lifted high, 0.8×0.8×1.0 m; many | Abandoned, dusty | See-through |
| `cobweb_beams` | Big web stretched in an old timber frame | Spider lair, old mine galleries | Floor, 1.7×0.3×1.7 m; alone; keep off paths (it blocks a walk line) | Creepy | See-through |
| `barrel_smashed` | Smashed barrel, staves and head on the floor | Store rooms, cellars, raided camps | Floor, 1.9×1.9×0.8 m; alone or with crates | Wrecked, looted |  |
| `well_dry` | Dry stone well with a little roof, rope and bucket | Underground village square, ruin courtyard, camp | Floor/ground, 1.8×1.4×1.7 m; alone; keep off paths | Abandoned | Dry inside (fits the no-water rule) |
| `bookshelf_collapsed` | Leaning bookshelf, one shelf snapped, books spilled | Library or study in stone dungeons | Floor, against a wall, 1.1×1.4×1.7 m; alone | Abandoned |  |

## Dungeon story pieces, group C (decor_nov21_c.py, no prefix)

Round 1. War, prison and work-site pieces: cut stone, old wood, rusted iron, copper.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `map_torn_wall` | Torn parchment map nailed to the wall | Guard room, war room, explorer camp, study | Flat on a wall, 0.8×0.0×0.5 m; alone or near a table | Adventurous |  |
| `war_drum_split` | Big split war drum on a log stand | Guard room, barracks, great hall, gate | Floor, 0.9×0.9×1.0 m; alone | Old war, abandoned |  |
| `war_horn_stand` | Long war horn resting in forked posts | Gate, watch post, barracks | Floor, 1.3×0.4×1.1 m; alone | Old war, proud | Horn is hollow |
| `portcullis_rusted` | Half-lowered rusted gate grid in a stone frame | Stone dungeon gate or a passage between rooms | Floor, set in a passage, 2.4×0.5×2.2 m; alone | Grim | Blocks the walk line (use where the way is meant to be shut, guess); see-through bars |
| `floor_grate` | Iron grate over a stone drain shaft | Cells, dungeon floors, drain room | Flat in the floor, 1.0×1.0×0.2 m; alone | Grim | Has a "wet puddle" at the bottom of the shaft: breaks the no-water rule |
| `cage_floor_open` | Rusted floor cage, door hanging open, straw and a bone | Prison, monster pens, lair | Floor, 1.4×2.0×1.3 m; alone or in a row; keep off paths | Eerie | Straw inside (soft clutter?) |
| `prison_bench` | Stone bench under a wall, two chains with cuffs | Prison cells | Against a wall, 1.6×0.6×1.6 m; one per cell | Grim | Owner's 10/10 |
| `hanging_hook` | Log frame with a big iron hook on a chain | Butcher room, lifting spot in a mine, store yard (guess) | Floor, 1.6×0.7×2.0 m; alone; keep off paths | Grim |  |
| `chandelier_fallen` | Smashed iron ring chandelier on the floor | Great hall, feast hall, mess hall | Floor, middle of the room, 2.0×1.4×0.2 m; alone | Ruined | Owner's 10/10; low and flat |
| `table_overturned` | Plank table on its side, mugs and plate on the floor | Mess hall, tavern, guard room after a fight | Floor, 1.3×1.2×0.8 m; alone | Wrecked | Owner's 10/10; has a "spilled puddle": breaks the no-water rule |
| `dice_on_crate` | Crate used as a dice table: dice, coins, mug, candle | Guard room, barracks, camp | Floor, 0.6×0.6×0.6 m; alone or with stools | Lived-in, left behind |  |
| `last_meal` | Stool with a loaf, gnawed bone, knife and mug | Lonely cell, guard post, beside a skeleton | Floor, 0.4×0.4×0.6 m; alone | Sad, story | Food on it (brief: no food piles; here it is the story) |
| `pit_bucket` | Log pulley frame over a stone pit, bucket on a rope | Mine shaft spot, dig site, well room | Floor, 1.4×1.0×1.7 m; alone; keep off paths | Abandoned | Pit is a dark hollow shaft |
| `ore_crusher_broken` | Broken wooden trip-hammer ore crusher, ore spilled | Mine work area, ore room | Floor, 2.0×1.1×1.3 m; alone; keep off paths | Abandoned |  |
| `coal_pile_shovel` | Heap of glossy black coal with a shovel in it | Forge store, mine, furnace room | Floor or corner, 1.4×1.4×1.2 m; alone | Worked, abandoned |  |
| `tally_marks` | Wall slab with tally marks cut in | Prison cell, lonely post | Flat on a wall, 1.0×0.2×0.8 m; alone | Grim, lonely | Carved in |
| `graffiti_pell` | Wall slab with a cut-in dwarf face and pickaxe doodle | Pell dungeon (by its name), any mine tunnel, cells, barracks | Flat on a wall, 1.0×0.2×0.8 m; alone | Cheeky | Carved in, no letters |

## Column, banner and home trophies, group D (decor_nov21_d.py, no prefix)

Round 1. A root-wrapped column, a faded banner, and the owner's favourite home trophies. Wall trophies stand on a short floor post.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `column_rootwrapped` | Stone column gripped by old roots | Old stone halls, ruins, edges of root-wood dungeons | Floor, 1.0×1.2×2.1 m; alone or in pairs; keep off paths | Ancient, overgrown | No moss |
| `banner_torn_faded` | Faded torn banner with a hammer sign on a post | Great hall, gate, ruins | Floor post by a wall, 0.8×0.2×1.6 m; alone or a pair | Faded, old |  |
| `gem_stand` | One gem on a carved stone pillar | Home trophy room; treasure room | Floor, 0.3×0.3×0.8 m; alone | Proud | Gem glows a little |
| `gem_case` | Glass display case of gems | Home trophy room, study | Floor, against a wall, 0.7×0.5×0.9 m; alone | Proud | Owner's 10/10 |
| `ore_sample_shelf` | Shelf of ore samples | Home study or trophy room; mine office | Against a wall (stands on the floor), 1.1×0.4×1.4 m; alone | Proud, tidy | Owner's 10/10 |
| `tooth_necklace` | Monster-tooth necklace on a wall board | Home trophy wall | Against a wall on a floor post, 0.5×0.3×1.6 m; group with other trophies | Proud | Owner's 10/10 |
| `bat_wing_trophy` | Bat wings mounted on a board | Home trophy wall | Against a wall on a floor post, 1.1×0.3×1.6 m; group | Proud | Owner's 10/10 |
| `crossed_swords` | Crossed swords on a plaque | Home trophy wall; great hall | Against a wall on a floor post, 0.7×0.2×1.6 m; group | Proud |  |
| `crossed_axes` | Crossed axes on a plaque | Home trophy wall; great hall | Against a wall on a floor post, 0.7×0.2×1.7 m; group | Proud | Owner's 10/10 |
| `medal_board` | Board with four hanging medals | Home trophy wall | Against a wall on a floor post, 0.8×0.2×1.6 m; group | Proud |  |
| `golden_pickaxe` | Golden pickaxe set in a stone block | Home trophy room, centre spot | Floor, 0.7×0.6×1.2 m; alone | Proud, grand |  |
| `first_coin_frame` | Framed first gold coin with a brass plate | Home trophy wall, study | Against a wall on a floor post, 0.3×0.2×1.3 m; group | Proud, cosy |  |
| `foreman_helmet_trophy` | Miner foreman's helmet on a round plaque | Home trophy wall | Against a wall on a floor post, 0.8×0.6×1.7 m; group | Proud | Owner's 10/10 |

## Cosy home furniture, group E (decor_nov21_e.py, no prefix)

Round 1. Bedroom, washroom, study, tavern and kitchen pieces in warm wood and stone. Tubs, basins and racks are empty.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `rocking_chair` | Wooden rocking chair with a knitted throw | Home living room by the fire | Floor, 0.7×0.9×1.1 m; alone | Cosy | Owner's 10/10; throw and seat pad are soft items (brief rule), owner liked it anyway |
| `fur_rug` | Woven rug with leather border and fringe | Home living room, bedroom | Flat on the floor, 1.8×1.0×0.0 m; walk over it | Cosy | Walk-over. Id says fur, but it is woven now. Heavy file (1.4 MB) |
| `hammock` | Rope-net hammock between two posts | Home bedroom; outside camp | Floor, 2.4×0.9×1.4 m; alone; keep off paths | Relaxed |  |
| `bunk_bed` | Bare wooden bunks with a ladder | Home bedroom; barracks in dungeons and the outpost (guess) | Floor, against a wall, 1.9×1.0×1.6 m; alone or a row | Plain | Bare (no bedding) |
| `wardrobe` | Tall two-door wardrobe | Home bedroom | Floor, against a wall, 1.1×0.6×1.8 m; alone | Cosy |  |
| `bathtub_barrel` | Empty half-barrel bathtub with a stool | Home washroom | Floor, 1.5×1.1×0.6 m; alone | Cosy | Empty (no water) |
| `washbasin` | Wash stand with an empty basin and jug | Home washroom, bedroom | Floor, against a wall, 0.6×0.5×1.0 m; alone | Cosy | Empty |
| `boot_rack` | Empty two-shelf boot rack | Home entrance hall | Floor, against a wall, 0.9×0.3×0.4 m; alone | Tidy |  |
| `writing_desk` | Desk with pigeon-holes, scrolls, ink and quill | Home study | Floor, against a wall, 1.2×0.6×1.0 m; alone | Cosy, busy | Owner's 10/10 |
| `world_stone` | Carved stone globe on a wooden stand | Home study, library | Floor, 0.8×0.7×1.0 m; alone | Learned | Owner's 10/10 |
| `storage_trunk` | Old trunk, broken and empty, lid torn half off | Home store room; old dungeon store (guess) | Floor, against a wall, 1.0×1.0×0.5 m; alone | Old, broken | Lid is not a separate part |
| `bar_counter` | Wooden bar counter | Home tavern corner; Brewhall drinking hall (guess) | Floor, 2.1×0.8×1.1 m; alone; keep off paths | Lively, cosy | Owner's 10/10 |
| `tap_keg_stand` | Keg on a cradle stand with a copper tap | Home tavern corner, kitchen | Floor, 0.7×0.9×1.3 m; alone or beside the bar | Cosy |  |
| `mug_rack` | Wall rack of mugs | Home tavern corner, kitchen | Against a wall (stands on the floor), 0.9×0.2×1.5 m; alone | Cosy | Owner's 10/10 |
| `bread_oven` | Clay bread oven on a stone base | Home kitchen | Floor, against a wall, 1.2×1.1×1.2 m; alone | Warm, cosy | Bread removed (empty) |
| `cooking_spit` | Roasting spit over a stone fire ring | Home kitchen hearth; outside camp | Floor, 2.0×1.0×0.9 m; alone; keep off paths | Cosy |  |

## Kitchen, lights and workshop, group F (decor_nov21_f.py, no prefix)

Round 1. Home kitchen, lights, workshop and plant pieces. Lights glow (they are working lights).

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `spice_shelf` | Wall shelf full of spice jars | Home kitchen | Flat on a wall, 0.8×0.2×0.7 m; alone | Tidy, cosy | Owner's 10/10 |
| `pantry_crates` | Three tidy planting crates full of soil | Home garden room, kitchen store | Floor, 1.8×0.5×0.3 m; in a row | Tidy, ready | Empty soil, ready to plant. Heavy file (1.0 MB) |
| `pie_rack` | Three-shelf rack holding pies | Home kitchen | Floor, against a wall, 0.7×0.4×0.9 m; alone | Cosy | Owner's 10/10; holds pies (the rack's point) |
| `kitchen_block` | Chopping block with cleaver, knives, vegetables, ladle | Home kitchen | Floor, 0.7×0.6×0.9 m; alone | Busy, cosy | Has vegetables on it |
| `dish_rack` | Wall rack of plates | Home kitchen | Flat on a wall, 0.9×0.3×0.8 m; alone | Tidy | Owner's 10/10 |
| `crystal_floor_lamp` | Tripod lamp, crystals in a copper cup | Home living room, study | Floor or corner, 0.6×0.6×1.6 m; alone | Cosy, glowing | Glows |
| `mushroom_lamp` | Big glowcap lamp in a clay pot | Home cosy corners | Floor, 0.6×0.6×1.0 m; alone | Cosy, glowing | Glows |
| `crystal_hanging_light` | Crystal light in a copper cup on chains | Any home room | Hanging from the ceiling, 0.3×0.3×0.9 m; alone or a few | Cosy, glowing | Glows |
| `lantern_hook` | Iron wall bracket with a lit lantern | Home doorway, hall | Flat on a wall, 0.2×0.4×0.5 m; one per door | Cosy | Lit (a working light) |
| `glowworm_jar` | Glow-worm jar on a little tripod | Home bedside, study | Floor or on a table, 0.3×0.3×0.8 m; alone | Cosy, glowing | Glows |
| `candle_wall_shelf` | Wall shelf with lit candles | Home bedroom, quiet corner | Flat on a wall, 0.8×0.2×0.6 m; alone | Cosy | Candles are lit |
| `tool_wall` | Wall board of tools on pegs | Home workshop | Flat on a wall, 1.1×0.1×0.8 m; alone | Tidy | Owner's 10/10 |
| `workbench_clutter` | Workbench with mallet, files, nails, shavings | Home workshop | Floor, against a wall, 0.9×0.6×0.9 m; alone | Busy | Owner's 10/10 |
| `blueprint_table` | Drafting table with a drawn tower plan, tools | Home study or workshop | Floor, 1.0×0.7×1.2 m; alone | Busy, clever |  |
| `parts_bin` | Bin of gears, bolts, nuts and a chain | Home workshop | Floor, 0.7×0.5×0.6 m; alone | Tidy |  |
| `glowcap_pot` | Clay pot of glowcap mushrooms | Home living room, garden corner | Floor, 0.5×0.5×0.5 m; alone or a few | Cosy, glowing | Uses the game's own glowcaps |
| `fern_basket` | Hanging wicker basket with a fern | Any home room | Hanging from the ceiling, 0.6×0.6×0.9 m; alone or a few | Cosy | Uses the game's own fern |
| `geode_stand` | Split geode on a carved stand | Home study, trophy room | Floor or on a table, 0.7×0.4×0.5 m; alone | Wondrous |  |

## Home fun and garden, group G (decor_nov21_g.py, no prefix)

Round 1. Home living-room pieces: a bonsai, games, music, crystals and two floor mosaics.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `root_bonsai` | Root-over-rock bonsai in a stone tray on a stand | Home living room, study | Floor, 0.6×0.4×0.8 m; alone | Calm | Has a few glowing buds |
| `mushroom_shelf_garden` | Standing wall shelf with trays of mushrooms | Home garden room, kitchen | Against a wall (stands on the floor), 1.0×0.3×1.4 m; alone | Cosy | Uses the game's own mushrooms. Heavy file (1.9 MB) |
| `dartboard` | Round wooden dartboard on a strap and peg | Home tavern corner; barracks (guess) | Flat on a wall, 0.5×0.2×0.6 m; alone | Fun |  |
| `stone_game_table` | Small stone table with a ring-and-hole board game | Home living room, tavern corner | Floor, 0.9×0.8×0.8 m; alone | Cosy | Owner's 10/10 |
| `drum_music_stand` | Hand drum in a three-leg stand with sticks | Home living room, tavern corner | Floor, 0.5×0.5×0.9 m; alone | Cosy |  |
| `crystal_globe` | Glass globe with a crystal rock inside | Home study | On a table or shelf, 0.4×0.4×0.4 m; alone | Wondrous | Small |
| `wind_chime` | Crystal shards on strings from a wooden disc | Home doorway, quiet corner | Hanging from the ceiling, 0.3×0.3×0.8 m; alone | Calm |  |
| `mosaic_a` | Floor mosaic: golden sun with rays | Home hall floor, great room centre | Flat on the floor, 2.0×2.0×0.0 m; walk over it | Grand, warm | Walk-over. Heavy file (1.1 MB) |
| `mosaic_b` | Floor mosaic: crossed pickaxes in a ring | Home entrance hall | Flat on the floor, 2.0×2.0×0.0 m; walk over it | Proud | Walk-over. Heavy file (1.1 MB) |

## Mossgate Hold (decor_nov21_mg.py, prefix mg_)
Small dungeon (15 spaces, about 84 x 56 m): the first diggers' gatehouse-hold, root wood (Shack logs, split boards, pegs) with iron and copper, abandoned long ago.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| mg_key_board | gatekeeper's key board, six keys, one empty hook | Mossgate, Gate Hall (gatekeeper's corner) | flat on a wall; 0.8×0.1×1.6 m; alone | abandoned | |
| mg_shield_wall | three round guard shields on pegs, one missing a plank | Mossgate, guard room in a side wing (guess) or Gate Hall | flat on a wall; 1.6×0.2×1.4 m; alone | abandoned | |
| mg_crossbow_rack | two crossbows on pegs, box shelf of bolts | Mossgate, guard room (guess) | flat on a wall; 1.4×0.2×1.2 m; alone | abandoned | heavy file (1.2 MB) |
| mg_helmet_pegs | peg rail with two guard helmets and a belt | Mossgate, guard room (guess) | flat on a wall; 1.3×0.4×1.3 m; group with shield wall | abandoned | |
| mg_bowl_shelf | mess shelf: plates, mugs, bowls, ladles | Mossgate, mess / side-wing living room (guess) | flat on a wall; 1.0×0.3×1.3 m; group with mess trestle | abandoned, tidy | heavy file (1.3 MB) |
| mg_rope_wall | rope coils, grapnel, pulley block on pegs | Mossgate, Gate Hall or store (guess) | flat on a wall; 1.3×0.2×1.3 m; alone | abandoned | |
| mg_ledger_shelf | pigeonhole cabinet of ledgers, scrolls, tally sticks | Mossgate, gatekeeper's corner of the Gate Hall (guess) | flat on a wall; 1.0×0.3×1.2 m; group with desk and chair | abandoned, tidy | heavy file (1.5 MB) |
| mg_gate_windlass | the gate's wall winch, chain going up | Mossgate, Gate Hall, next to the gate | against a wall; 1.0×0.6×1.5 m; alone | abandoned | |
| mg_last_watch | guard table, half-played peg game, tipped tankard, stool knocked over | Mossgate, Gate Hall or guard room | floor; 1.8×0.9×0.8 m; alone | abandoned, left in a hurry | heavy file (1.1 MB) |
| mg_barricade | boards nailed across two posts, braced by a log | Mossgate, a blocked side passage or doorway | floor; 2.0×1.2×1.4 m; alone; keep off paths and doors | desperate | |
| mg_gate_bar_snapped | huge gate bar snapped in two on the floor | Mossgate, Gate Hall, just inside the gate | floor; 2.0×1.1×0.2 m; alone; keep off paths and doors | broken in | |
| mg_crate_pried_open | supply crate pried open, crowbar under a lid board, empty | Mossgate, store room in a side wing (guess) | floor; 1.2×1.0×0.6 m; group with other store pieces | looted | |
| mg_sawhorse_left | sawhorse with a half-sawn log, saw stuck; axe in a chopping log | Mossgate, work corner or store (guess) | floor; 1.9×0.9×1.2 m; alone; keep off paths | left mid-job | |
| mg_strongbox_forced | iron strongbox broken open and empty, padlock and crowbar beside | Mossgate, gatekeeper's corner or Loot Room side (guess) | floor; 1.2×1.3×0.4 m; alone | looted | |
| mg_spear_rack_fallen | guard spear rack knocked over, spears spilled | Mossgate, guard room (guess) | floor; 2.4×3.1×0.4 m; alone; keep off paths and doors (long spill) | fought over | |
| mg_collapsed_shelf | store shelf with a snapped leg, crates and keg slid off | Mossgate, store room (guess) | against a wall; 1.9×1.5×1.5 m; alone | abandoned, broken | heavy file (1.1 MB) |
| mg_gatekeeper_chair | high-backed log armchair with iron studs | Mossgate, gatekeeper's corner of the Gate Hall | floor; 0.7×0.6×1.4 m; group with desk | abandoned, grand-ish | |
| mg_gatekeeper_desk | slanted writing desk, open ledger, cash box, candle stub | Mossgate, gatekeeper's corner of the Gate Hall | floor, back to a wall; 1.0×0.6×1.1 m; group with chair and ledger shelf | abandoned | |
| mg_armour_stand | log armour stand with iron cuirass and helmet, shield beside | Mossgate, guard room (guess) | floor or corner; 1.1×0.9×1.1 m; alone | abandoned | |
| mg_alarm_bell | gate alarm bell in a log frame, pull rope on a cleat | Mossgate, Gate Hall | floor, near a wall; 1.1×0.7×1.8 m; alone | silent, abandoned | |
| mg_water_butt | big stave water barrel on a log cradle, lid on | Mossgate, mess or store (guess) | floor, against a wall; 0.8×0.7×1.0 m; alone | abandoned | |
| mg_supply_shelf | tall store shelf full of kegs, crates, pots, rope, lantern | Mossgate, store room (guess) | against a wall; 1.2×0.4×1.6 m; group with grain bin | stocked, abandoned | heavy file (1.9 MB) |
| mg_wheelbarrow | plank wheelbarrow with spoked wheel | Mossgate, store or work corner (guess) | floor; 0.6×1.9×0.7 m; alone | abandoned | |
| mg_cookpot_tripod | cold cooking spot: stone ring, tripod, pot, burnt stubs, log seat | Mossgate, guards' living corner (guess) | floor, room middle or corner; 1.2×1.2×1.2 m; alone | cold, abandoned | |
| mg_guard_cot | bare log cot with rope lacing, footlocker at its foot | Mossgate, guard bunk room (guess) | floor, against a wall; 0.9×2.4×0.7 m; group of 2-3 | abandoned | |
| mg_mess_trestle | trestle table and bench with empty bowls, mugs, bread board | Mossgate, mess / living room (guess) | floor; 1.7×1.2×0.8 m; group with bowl shelf | abandoned | |
| mg_lantern_post | gate lantern post with a hanging lantern | Mossgate, Gate Hall, beside the gate | floor; 0.7×1.0×2.1 m; alone, or a pair either side of the gate | abandoned | lantern is lit (brief: nothing lit unless still in use) |
| mg_grain_bin | plank grain bin, lid propped open, scoop on the rim | Mossgate, store room (guess) | floor, against a wall; 1.0×0.6×1.1 m; group with supply shelf | abandoned | |
| mg_tool_chest | open carpenter's chest, chisels, saw in lid; mallet and plane beside | Mossgate, work corner or store (guess) | floor; 1.3×0.9×0.8 m; alone | left mid-job | |
| mg_toll_table | gate toll table: balance scale, weights, coin box, coin stacks | Mossgate, Gate Hall | floor; 1.0×0.6×1.2 m; alone | abandoned | has coin stacks but no _empty twin (guess: not lootable) |

## Lampwick Drift (decor_nov21_lw.py, prefix lw_)
Small dungeon (13 spaces, 1 level): a root-wood mine drift lit by oil lamps, with cart rails and an upper walkway; lamp-makers and miners, now abandoned. Root wood + iron, copper, glass.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| lw_lamp_rack_wall | two rails of hanging oil lamps, one peg empty, spare chimneys | Lampwick, Lamp Room | flat on a wall; 1.0×0.2×1.0 m; alone | still working | most lamps lit (brief: only if clearly in use); heavy file (1.1 MB) |
| lw_wick_spool_shelf | wick spools, coiled wicks, wax pot, trimmer | Lampwick, Lamp Room or Tool Store | flat on a wall; 0.9×0.3×0.8 m; group with lamp workbench | tidy, abandoned | |
| lw_oil_flask_shelf | shelf of stoppered glass oil flasks and copper oil cans | Lampwick, Lamp Room or Tool Store | flat on a wall; 1.0×0.3×1.0 m; group with oil barrel | tidy, abandoned | |
| lw_lamp_parts_board | board of chimneys, burners, pliers, hammer, snips | Lampwick, Lamp Room (lamp-maker's corner) | flat on a wall; 1.0×0.2×0.9 m; group with lamp workbench | tidy | |
| lw_lamp_token_board | miners' lamp-check board, copper tokens on hooks, some empty | Lampwick, Lamp Room (entrance) | flat on a wall; 0.9×0.1×1.0 m; alone | eerie (missing miners) | |
| lw_signal_code_board | board with bell code cut in, bell-pull and hand bell | Lampwick, Cart Junction or Back Rails | flat on a wall; 0.8×0.2×0.9 m; alone | abandoned | |
| lw_spare_rail_rack | wall frame with spare rails and fishplates, box of spikes | Lampwick, Tool Store | flat on a wall; 1.3×0.3×0.8 m; alone | abandoned | has rails (brief: avoid rails) |
| lw_oil_barrel_tap | oil barrel in a log cradle, copper tap, empty basin, funnel | Lampwick, Lamp Room or Tool Store | floor, against a wall; 0.7×0.9×0.7 m; alone | abandoned | |
| lw_lamp_workbench | lamp-maker's bench, vise with a lamp, tools on a back rail | Lampwick, Lamp Room (lamp-maker's corner) | floor, against a wall; 1.2×0.6×1.1 m; group with parts board and wick shelf | left mid-job | |
| lw_wick_twisting_wheel | big hand wheel twisting three wick strands | Lampwick, Lamp Room or Tool Store (guess) | floor; 0.4×1.3×1.0 m; alone | abandoned | |
| lw_ore_sorting_table | sloped sorting table, ore heap, four bins, rake | Lampwick, Old Copper Face | floor; 1.3×0.8×1.0 m; alone | abandoned | heavy file (1.8 MB) |
| lw_ore_sieve_cradle | rocking ore sieve on two rockers, push pole, trough | Lampwick, Old Copper Face | floor; 1.5×0.5×0.5 m; alone | abandoned | |
| lw_rail_switch_lever | rail switch: main track, branch, throw lever | Lampwick, Cart Junction or Back Rails | floor; 1.4×1.5×0.7 m; alone; keep off paths | abandoned | has rails (brief: avoid rails) |
| lw_signal_lamp_post | siding lamp post, two lamps (one shuttered), wick tin | Lampwick, Cart Junction or Rail Tunnel | floor; 0.9×0.9×1.8 m; alone | still working | lamps lit (brief: only if clearly in use) |
| lw_walkway_ladder | pegged ladder up to the walkway, rope rail, hanging lamp | Lampwick, below the upper walkway (The Old Shaft, guess) | floor, against a wall/walkway edge; 0.7×0.7×2.0 m; alone | abandoned | hanging lamp lit (brief: only if clearly in use) |
| lw_rest_nook_bench | miners' bench with back, shelf with cold lamp, mug, lunch tin | Lampwick, Miners' Rest | against a wall; 1.3×0.4×1.3 m; alone | quiet, abandoned | |
| lw_lamp_barrow | one-wheel barrow carrying six lamps | Lampwick, Lamp Room | floor; 0.5×1.4×0.5 m; alone | abandoned | |
| lw_oil_can_crate | open crate of copper oil cans, one missing, lid leaning | Lampwick, Tool Store | floor; 0.7×0.6×0.7 m; group with chimney crate | abandoned | |
| lw_chimney_crate | crate of glass chimneys in a grid, two gone, one broken, lid on floor | Lampwick, Tool Store | floor; 0.6×1.3×0.2 m; group with oil can crate | abandoned | |
| lw_bell_frame | free-standing signal bell in a braced frame | Lampwick, Cart Junction | floor; 1.1×0.6×1.6 m; alone | silent | |
| lw_ledger_desk | lamp-man's standing desk, ledger, quill, lamp, tally notches | Lampwick, Lamp Room or Foreman's Office | floor, back to a wall; 0.7×0.5×1.4 m; alone | abandoned | lamp lit (brief: only if clearly in use) |
| lw_ore_bucket_hoist | hand winch on an A-frame lowering a bucket of ore | Lampwick, The Old Shaft (shaft edge) | floor; 1.2×0.9×1.4 m; alone | abandoned | |
| lw_lamp_fallen_spill | lamp stand knocked flat, broken glass, dark oil stain | Lampwick, Rail Tunnel or Drip Tunnel (guess) | floor; 0.8×1.4×0.6 m; alone | accident | dark oil stain on the floor (brief: no oil pools) |
| lw_cart_jammed | mine cart stuck on rails under a fallen roof prop | Lampwick, Prop Corridor or Back Rails | floor; 1.8×2.0×0.9 m; alone; keep off paths and doors | stuck, abandoned | has rails (brief: avoid rails); heavy file (1.8 MB) |
| lw_last_shift_stool | tipped stool, dropped pick, open empty lunch tin, lamp burning low | Lampwick, Old Copper Face | floor; 0.9×1.0×0.4 m; alone | eerie, left in a hurry | lamp lit (brief: only if clearly in use) |
| lw_broken_lamp_rack | wall lamp rack with snapped bracket, lamps fallen and smashed | Lampwick, Lamp Room or Prop Corridor | against a wall; 1.0×0.7×1.0 m; alone | broken | one lamp still lit (guess) |
| lw_leaking_oil_cask | upright cask with a cracked stave, wedge, empty catch pan | Lampwick, Tool Store | floor; 0.5×0.8×0.7 m; alone | abandoned | pan is dry (fits brief) |
| lw_bell_fallen | signal bell fallen and cracked, snapped yoke, loose rope | Lampwick, Cart Junction | floor; 1.4×0.9×0.3 m; alone | broken | |
| lw_collapsed_walkway | walkway section broken down, deck slanting to the floor | Lampwick, The Old Shaft or Bat Gallery (guess) | floor, against a wall; 2.0×1.8×1.7 m; alone; keep off paths and doors | collapsed | |

## Old Pell's Diggings (decor_nov21_op.py, prefix op_)
Small dungeon (13 spaces, 2 levels): the private diggings of Old Pell, a clever, half-mad old miner who lived alone and booby-trapped everything. Root wood (Shack paintings) + iron and copper.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| op_rock_shelf | two shelves of Pell's odd rocks on stands with tags | Old Pell's, Pell's Hut | flat on a wall; 1.0×0.2×0.8 m; alone | quirky collector | crystals glow faintly; heavy file (1.1 MB) |
| op_bone_board | beast jaw, four rat skulls, crossed long bones on a board | Old Pell's, Pell's Hut | flat on a wall; 0.9×0.2×0.8 m; alone | creepy collector | |
| op_madness_board | diary pages nailed up, red cord between tacks, knife pinning a page | Old Pell's, Pell's Hut or Pell's Last Dig | flat on a wall; 1.1×0.2×0.8 m; alone | mad, eerie | |
| op_trap_parts_rack | trap jaws, spring, tripwire spool, chain, spike strip on pegs | Old Pell's, Winch Shed or Pell's Hut | flat on a wall; 1.2×0.2×0.9 m; group with trapmaker table | menacing | |
| op_key_board | framed key board, one hook empty with a key-shaped dent | Old Pell's, Pell's Hut | flat on a wall; 0.7×0.1×0.8 m; alone | secretive | |
| op_warning_plank | plank with carved skull, bones, teeth, a little bell | Old Pell's, Ladder Landing or Cave-in Tunnel entrance | flat on a wall; 1.1×0.2×0.5 m; alone | warning, eerie | |
| op_map_rack | rack of rolled maps, one hanging open with a red X | Old Pell's, Pell's Hut | flat on a wall; 0.9×0.3×0.9 m; alone | secretive | heavy file (1.1 MB) |
| op_pipe_rack | smoking pipes in a rack, tobacco pouch, tinder box | Old Pell's, Pell's Hut | flat on a wall; 0.6×0.2×0.5 m; alone | cosy, lived-in | |
| op_still | stone firebox, copper pot, coiled worm barrel, a cup | Old Pell's, Pell's Hut or Pantry | floor, against a wall; 1.5×0.7×1.1 m; alone | cold, lived-in | |
| op_tinker_bench | bench with vise, gear train, springs, magnifier, drawers | Old Pell's, Pell's Hut or Winch Shed | floor, against a wall; 1.1×0.8×1.1 m; alone | left mid-job | heavy file (1.4 MB) |
| op_trapmaker_table | half-built bear trap, stakes, hammer, sketch | Old Pell's, Winch Shed | floor; 1.3×0.7×0.9 m; group with trap parts rack | menacing | |
| op_cot | bare root-wood cot, boots under it, candle stump | Old Pell's, Pell's Hut | floor, against a wall; 1.1×1.8×0.9 m; alone | lived-in, abandoned | |
| op_root_armchair | crooked armchair of bent roots, spectacles, book by its foot | Old Pell's, Pell's Hut | floor, in a corner; 1.1×0.8×1.0 m; alone | cosy, odd | |
| op_tumbler | hand-crank rock-polishing barrel, tray of pebbles | Old Pell's, Sorting Room or Pell's Hut | floor; 1.1×0.7×0.8 m; alone | quirky | |
| op_sieve_stack | stacked ore sieves, sorting tray of chips, copper scoop | Old Pell's, Sorting Room | floor; 1.0×0.5×0.2 m; group with ore scale | abandoned | heavy file (1.1 MB) |
| op_hearth_tripod | cold fire ring, charred logs, tripod with a lidded kettle | Old Pell's, Pell's Hut | floor, room middle; 1.0×1.2×1.1 m; alone | cold, lived-in | |
| op_signpost | root signpost in a cairn, three warning boards, rat skull | Old Pell's, Ladder Landing or a tunnel fork | floor; 1.3×0.8×1.7 m; alone; keep off paths | warning, eerie | |
| op_spike_crate | crate of fire-hardened stakes, hatchet in a stump | Old Pell's, Winch Shed or Cave-in Tunnel side | floor; 1.1×0.7×0.9 m; alone | menacing | |
| op_wire_spools | sled stand with three tripwire spools, loose coil, snips | Old Pell's, Winch Shed | floor; 1.0×0.8×0.7 m; group with trapmaker table | menacing | |
| op_ore_scale | balance scale on a stump, nugget in one pan, weights | Old Pell's, Sorting Room | floor; 0.8×0.4×1.1 m; group with sieve stack | abandoned | |
| op_caught_boot | bear trap shut on an empty boot, snapped stick, fallen lantern | Old Pell's, Cave-in Tunnel or Sorting Room | floor; 0.9×0.9×0.2 m; alone; keep off paths (looks like a live trap) | eerie, darkly funny | lantern is cold |
| op_diary_table | open diary on a stump table, quill dropped, ink spilled, stool over | Old Pell's, Pell's Last Dig or Pell's Hut | floor; 0.9×1.3×0.7 m; alone | eerie, last entry | spilled ink (brief: no spills) |
| op_x_marks_dig | dig patch in a board frame, spoil heap with shovel, tipped bucket, X map | Old Pell's, Pell's Last Dig or Spoil Tunnel | floor; 2.0×1.5×1.0 m; alone; keep off paths and doors | treasure hunt | |
| op_bell_tripwire | cord between stakes with small bells, big bell at one end | Old Pell's, Ladder Landing or Cave-in Tunnel | floor; 1.6×0.3×0.5 m; alone; across a side spot, not the main path | alarm, paranoid | |
| op_barricade | planks across two posts, sharpened stakes out, peephole | Old Pell's, blocked side passage (Spoil Tunnel, guess) | floor; 1.8×1.2×1.3 m; alone; keep off paths and doors | paranoid | |
| op_decoy_chest | open chest with a spring that shot up a spiked plate, no gold | Old Pell's, Pantry or Rotten Gallery | floor; 0.8×0.7×0.9 m; alone | trap, darkly funny | already "sprung", no loot |
| op_hat_on_pick | pick in a stump, battered candle hat on it, little cairn | Old Pell's, Pell's Last Dig or Miner's Shrine | floor; 1.1×0.6×0.9 m; alone | grave-like, sad | |
| op_rat_traps | row of rat traps on a plank, one with a rat, gnawed crate | Old Pell's, Pantry | floor, against a wall; 1.1×0.6×0.3 m; alone | grimy, darkly funny | |
| op_strongbox_pried | iron strongbox pried open, crowbar wedged in, broken padlock | Old Pell's, Pell's Hut or Pantry | floor; 0.6×0.8×0.5 m; alone | looted | |
| op_watch_post | plank screen with a peephole, crossbow leaning on it, stool, bolt quiver | Old Pell's, Winch Shed or Ladder Landing | floor; 1.6×0.8×1.3 m; alone; keep off paths | paranoid, abandoned | crossbow + bolts (fits brief) |

## Mossprop Workings (decor_nov21_mp.py, prefix mp_)
Small dungeon (14 spaces, 3 levels up a cliff): an abandoned timber-propped working mine. Root wood (Shack paintings) + iron and rope.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| mp_wedge_rack | two shelves packed with hardwood wedges, a mallet | Mossprop, Store Shed or Prop Room | flat on a wall; 1.1×0.2×0.8 m; alone | tidy, abandoned | |
| mp_saw_wall | two-man saw, bow saw, axe, whetstone ledge | Mossprop, Store Shed or Prop Room | flat on a wall; 1.4×0.2×0.9 m; alone | tidy | |
| mp_tag_board | shift board of miners' tags, five hooks empty, one tag fallen | Mossprop, Base Camp | flat on a wall; 1.0×0.2×0.9 m; alone | eerie (missing miners) | |
| mp_lamp_shelf | shelf of iron frog lamps (one tipped), oil keg, lamps hanging below | Mossprop, Store Shed or Base Camp | flat on a wall; 1.0×0.2×0.8 m; alone | abandoned | lamps are cold |
| mp_rope_rack | heavy wall beam with rope coils, pulley block, chain | Mossprop, Store Shed or Plank Bridge end | flat on a wall; 1.4×0.3×0.9 m; alone | abandoned | |
| mp_auger_rack | T-handled augers in a holder bar, drawknife, pry bar | Mossprop, Store Shed or Tool Niche | flat on a wall; 1.1×0.2×0.9 m; alone | tidy | |
| mp_bucket_hooks | beam of hooks, two bailing buckets, long dipper | Mossprop, Base Camp or Store Shed | flat on a wall; 1.4×0.4×1.0 m; group with bailing tub | abandoned | |
| mp_lagging_burst | propped wall whose boards snapped and bowed out, rock spilling | Mossprop, Prop Room or Rockfall Ledge | against a wall; 1.6×0.8×1.9 m; alone | collapsing, tense | |
| mp_saw_bench_cut | log on a sawbuck, saw stuck half way, rounds and chips | Mossprop, Base Camp or Store Shed | floor; 2.1×1.3×0.9 m; alone; keep off paths | left mid-job | |
| mp_prop_cracked | prop kinked and split, lashed and clamped, second prop braced on it | Mossprop, Prop Room | floor, against a wall (roof height ~2 m); 1.1×0.4×2.0 m; alone | tense, about to give | |
| mp_collapsed_set | timber set gave way, cap on a slant, rubble, dropped lamp | Mossprop, Rockfall Ledge or Crusher Gallery side | floor, against a wall; 2.2×1.4×1.4 m; alone; keep off paths and doors | collapsed | lamp is cold |
| mp_rest_corner | timber-men's break spot: bench, crate table, dice, mugs, stool over | Mossprop, Climbers' Rest | floor, in a corner; 1.8×1.1×0.7 m; alone | left in a hurry | lamp is cold |
| mp_bucket_line | dropped bailing line: buckets upright/tipped, a yoke | Mossprop, Base Camp or Lower Walkway side | floor; 1.5×0.9×0.3 m; alone | left in a hurry | header says "small puddle" but the build has none (guess) |
| mp_hewing_log | log on bearers, half hewn flat, broad axe stuck in it, chips | Mossprop, Base Camp or Store Shed | floor; 1.9×1.1×1.2 m; alone; keep off paths | left mid-job | |
| mp_foreman_desk | slanted lectern desk, ledger, burnt-down candle, measuring rod | Mossprop, Top Hall or Base Camp | floor, back to a wall; 1.1×0.6×1.3 m; alone | abandoned | |
| mp_prop_crib | crib of crossed square timbers, wedged, roof support | Mossprop, Prop Room or Top Hall | floor; 0.9×0.9×1.0 m; group of 1-3 | still holding | |
| mp_prop_and_cap | standing pit prop with cap board, wedges, lamp on a spike | Mossprop, Prop Room or corridors | floor, against a wall (~2 m roof); 1.0×0.5×2.0 m; group in rows | still holding | lamp is cold |
| mp_door_set | three-piece timber set (two legs, cap) with lagging over | Mossprop, at tunnel mouths and room entrances | floor, framing an opening; 1.6×1.0×2.0 m; alone | still holding | walk-through frame (guess) |
| mp_shaft_windlass | hand windlass over a small shaft collar, rope to a bucket | Mossprop, Base Camp or Top Hall (guess) | floor; 1.6×1.2×1.2 m; alone; keep off paths | abandoned | |
| mp_hoist_tripod | three lashed poles, chain and hook slinging a prop | Mossprop, Base Camp | floor, room middle; 1.8×1.8×2.3 m; alone; keep off paths and doors | abandoned | needs 2.3 m headroom |
| mp_sorting_table | ore sorting table, rock heap, three trays, hammer, tub below | Mossprop, Store Shed or Top Hall | floor; 1.4×0.7×1.1 m; alone | abandoned | heavy file (1.3 MB) |
| mp_tool_shed | small open lean-to shed with shovels, pick, bar, shelf, lamp | Mossprop, Base Camp | floor, against a wall; 1.6×1.2×1.8 m; alone; keep off paths | abandoned | lamp is cold |
| mp_bailing_tub | big empty stave tub, dipper leaning in, two buckets beside | Mossprop, Base Camp | floor; 1.3×0.9×0.6 m; group with bucket hooks | abandoned | empty (fits brief) |
| mp_bell_frame | collapse-warning bell in a braced frame, pull rope | Mossprop, Prop Room or Top Hall | floor; 1.2×0.7×1.6 m; alone | silent | |
| mp_wedge_crate | open crate of wedges, a few on the floor, maul leaning | Mossprop, Store Shed | floor; 1.1×0.9×0.4 m; group with wedge rack | abandoned | |
| mp_prop_trolley | low four-wheel trolley loaded with roped props | Mossprop, Base Camp or Lower Walkway | floor; 2.1×0.8×0.7 m; alone; keep off paths | abandoned | |
| mp_lagging_stack | lagging boards stacked on bearers, stone weight, hatchet | Mossprop, Store Shed or Base Camp | floor; 1.2×0.9×0.6 m; group with prop rack | tidy, abandoned | |
| mp_prop_rack | lean-to rack with eight props stood against it | Mossprop, Base Camp or Store Shed | against a wall; 1.6×0.7×1.9 m; alone | tidy | |
| mp_tool_barrel | cut-down barrel holding shovels, pick, bar, maul | Mossprop, Tool Niche or Store Shed | floor; 0.9×0.7×1.2 m; alone | abandoned | |
| mp_nail_keg | tipped nail keg, spikes and dogs spilled, lid, claw hammer | Mossprop, Store Shed | floor; 1.1×1.0×0.4 m; alone | messy, abandoned | |

## Tomb of Hald Ironbrow (decor_nov21_th.py, prefix th_)
Medium dungeon (21 spaces, 2 levels): the tomb of the great dwarf lord Hald Ironbrow, famed for his iron brow-helm. Cut stone (Stonehold greystone), bronze, iron and gold; every carving cut into the stone.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| th_hald_tomb | Hald's grand carved tomb chest, helm sign and runes on the lid | Tomb, Hald's Tomb (centre) | floor, room centre; 2.5×1.3×1.0 m; alone; keep off paths | grand | |
| th_brow_helm_plinth | the iron brow-helm on a tall carved plinth | Tomb, Hald's Tomb or Grave Chamber | floor; 0.7×0.7×1.5 m; alone | grand, sacred | |
| th_armour_stand | his armour (game dwarf armour) on an iron stand, helmet, boots | Tomb, Grave Chamber or Honour Chapel | floor; 0.8×0.6×1.4 m; alone | grand | heavy file (1.5 MB) |
| th_hammer_rest | his war hammer in stone cradles on a carved block | Tomb, Grave Chamber or Hald's Tomb | floor; 1.3×0.7×0.7 m; alone | grand | |
| th_drinking_horn | silver-banded horn in a bronze holder on a pedestal, silver cup | Tomb, Grave Goods or Offering Room | floor; 0.6×0.5×1.3 m; alone | grand | |
| th_honour_guard | stone honour-guard statue (game dwarf) with shield and spear on a plinth | Tomb, Honour Chapel, Statue Corridor, Antechamber | floor, against a wall or in pairs by a door; 1.5×0.9×2.7 m; group in pairs/rows | grand, watchful | heavy file (1.9 MB); needs 2.7 m headroom |
| th_guard_snapped | the same guard with its stone spear snapped, top on the plinth | Tomb, Statue Corridor or Wardens' Hall | floor, against a wall; 1.9×1.4×1.9 m; with intact guards | broken, old | heavy file (1.9 MB) |
| th_brazier_grand | ceremonial stone brazier, bronze bowl on claws, glowing coals | Tomb, Hald's Tomb or Honour Chapel | floor; 0.9×0.8×1.0 m; pairs | grand | burning coals and fire (brief: nothing lit unless clearly in use) |
| th_brazier_toppled | iron tripod brazier knocked over, cold coals spilled | Tomb, Antechamber or Wardens' Hall | floor; 1.1×0.6×0.6 m; alone | fought over | coals are cold (fits brief) |
| th_mourning_banner | dark mourning banner with helm emblem on a carved backing stone | Tomb, Hall of Names, Hald's Tomb, Mourners' Gate | against a wall; 1.0×0.3×2.2 m; pairs | solemn | |
| th_mourning_bell | bronze bell in a cut-stone frame, striker on a hook | Tomb, Mourners' Gate or Quiet Chapel | floor; 1.6×0.6×2.1 m; alone; keep off paths | solemn | |
| th_relief_battle | carved panel: Hald and his guard against a great deep-worm | Tomb, Hall of Names or Wardens' Hall | against a wall; 1.7×0.3×1.5 m; alone or paired with forge relief | grand, story | |
| th_relief_forge | carved panel: Hald forging his brow-helm at the anvil | Tomb, Hall of Names or Wardens' Hall | against a wall; 1.7×0.3×1.5 m; paired with battle relief | grand, story | |
| th_name_plaque | framed stone plaque on a post, helm emblem, six rune lines | Tomb, Hall of Names or Mourners' Gate | against a wall; 0.8×0.3×1.9 m; alone or in a row | solemn | |
| th_niche_coins | arched offering niche full of coins, cups, ring, gold bars | Tomb, Offering Room or Grave Goods | against a wall; 1.0×0.5×1.3 m; alone | rich, untouched | heavy file (1.5 MB); looks lootable but no _empty twin |
| th_niche_candles | offering niche with lit candles and a small helm idol | Tomb, Hall of Candles | against a wall; 1.0×0.5×1.3 m; row along the corridor | solemn | candles lit (brief: nothing lit unless clearly in use) |
| th_niche_looted | niche pried open, broken corner on the floor, pry bar jammed in | Tomb, Offering Room or Collapsed Tunnel | against a wall; 1.0×0.9×1.3 m; next to full niches | looted | |
| th_urn_shelf | two-level stone shelf of bronze urns and stone ash boxes | Tomb, Ossuary or Antechamber | against a wall; 1.3×0.5×1.8 m; alone or row | solemn, tidy | |
| th_sealed_door | round sealed tomb door: carved disc, iron bands, chain, great lock | Tomb, Grave Chamber entrance or a fake sealed door (guess) | flat on a wall; 2.1×0.4×1.9 m; alone | grand, forbidding | not a real door (decor only, guess) |
| th_door_fallen | round tomb door broken in two on the floor, pry bars | Tomb, Collapsed Tunnel or Antechamber | floor; 2.1×2.0×0.2 m; alone; keep off paths and doors | broken in | |
| th_chest_looted | stone grave-goods chest, lid shoved onto the floor, empty, pry bar | Tomb, Grave Goods or Embalmers' Room | floor; 2.1×1.2×0.6 m; alone | looted | |
| th_weapon_rack | carved stone rack of axes, hammers and a spear | Tomb, Shield Hall or Antechamber | against a wall; 1.5×0.5×2.0 m; alone | grand | |
| th_shield_wall | three round shields of fallen guards on a stone rail, one split | Tomb, Shield Hall | against a wall; 1.8×0.3×1.6 m; row along the corridor | solemn | |
| th_ash_urn | grand bronze urn on a carved pedestal, little helm on the lid | Tomb, Hald's Tomb or Quiet Chapel | floor; 0.6×0.7×1.5 m; alone or pair | grand | |
| th_kneeling_mourner | stone mourner (game dwarf) on one knee, hand on an axe | Tomb, Hald's Tomb or Quiet Chapel | floor; 1.3×1.1×1.4 m; alone or pair by the tomb | solemn | heavy file (1.7 MB) |
| th_robber_pinned | fallen lintel pinning a tomb robber's bones, satchel, coins | Tomb, Collapsed Tunnel or Broken Stair foot | floor; 1.9×1.1×0.5 m; alone | eerie, warning | coins on the floor; no _empty twin |
| th_pillar_fallen | carved column broken into drums, stump on its base | Tomb, Wardens' Hall or Statue Corridor | floor; 2.5×1.1×0.8 m; alone; keep off paths | ruined | |
| th_mourning_bench | long stone bench with helm-emblem legs, silver cup on it | Tomb, Quiet Chapel or Mourners' Gate | floor, against a wall; 1.7×0.5×0.7 m; alone | solemn | candle on it is cold |
| th_offering_table | stone table with grave goods in rows: cups, coins, ring dish, dagger | Tomb, Offering Room | floor; 1.4×0.7×0.9 m; one or two | solemn, rich | looks lootable but no _empty twin |
| th_wall_lamp | carved stone lamp stele, chained bronze oil lamp, lit | Tomb, Hall of Candles, Hall of Names, corridors | against a wall; 0.5×0.3×1.9 m; row along walls | solemn | lit flame (brief: nothing lit unless clearly in use) |

## The Quiet Barrows (decor_nov21_qb.py, prefix qb_)
Medium dungeon (21 spaces, 3 levels): long, low burial passages of ordinary dwarf families, humble and old, still visited. Cut stone (limestone), clay urns, one wood, plain iron and a little copper; carvings cut into the stone.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| qb_loculus_wall | six burial niches sealed with name-stones, small offerings | Barrows, First Ring, Second Ring, Long Barrow walls | against a wall; 1.9×0.3×1.9 m; row along walls | quiet, cared-for | heavy file (1.2 MB); one oil lamp lit |
| qb_loculus_open | family niche opened for a new burial, name-stone below, mortar tub | Barrows, First Ring or Second Ring | against a wall; 1.5×0.8×1.7 m; next to sealed niches | still in use | oil lamp lit |
| qb_loculus_collapsed | name-stone fallen and broken, crack in the wall, old bones show | Barrows, Sunken Barrow or Hall of Bones | against a wall; 1.5×0.7×1.4 m; next to sealed niches | decayed, eerie | |
| qb_urn_shelves | three stone shelves of lidded clay family urns with tags | Barrows, family barrows (Smith, Hunter, Twins) | against a wall; 1.6×0.5×1.8 m; alone | quiet, tidy | heavy file (1.5 MB) |
| qb_crest_hammers | family crest stele with crossed hammers, names, candle ledge | Barrows, Barrow of the Smith | against a wall; 0.9×0.3×1.5 m; alone | quiet, proud | one candle lit |
| qb_crest_mountain | round mountain-sign crest stele, two clay lamps on chains | Barrows, Barrow of the Hunter or Twins (guess) | against a wall; 0.9×0.3×1.4 m; alone | quiet, proud | one lamp lit |
| qb_lamp_alcove | arched lamp alcove with lit oil lamp, oil jug, tinder box | Barrows, Long Barrow, Spiral Stair, Keeper's Corridor | against a wall; 0.9×0.5×1.3 m; row along passages | quiet, still visited | lamp lit |
| qb_candle_ledge | long ledge on corbels, row of candles, wax runs | Barrows, Shrine of Rest or First Ring | against a wall; 1.6×0.4×1.3 m; alone | quiet, cared-for | most candles lit |
| qb_ossuary_wall | stacked long bones and rows of skulls in a stone frame | Barrows, Hall of Bones | against a wall; 1.7×0.3×1.4 m; row along walls | eerie, orderly | heavy file (1.9 MB) |
| qb_family_shrine | small shrine, columned niche with ancestor bust, cups, candles | Barrows, Shrine of Rest or a family barrow | against a wall; 0.8×0.5×1.5 m; alone | warm, sacred | candles lit |
| qb_name_roll | family name tablet, newest name half cut, chisels and mallet left | Barrows, Second Ring or Keeper's Barrow | against a wall; 1.5×0.5×1.3 m; alone | still in use | candle lit |
| qb_digger_tool_wall | gravedigger's rack: spade, pick, rope, lantern; broom leaning | Barrows, Keeper's Barrow or Barrow Door | against a wall; 1.5×0.6×1.7 m; alone | still in use | lantern lit |
| qb_sealed_passage | arched passage walled up, seal plaque, chain and padlock | Barrows, any dead-end wall (Second Ring, guess) | flat on a wall; 1.8×0.4×2.0 m; alone | sealed, forbidding | not a real door |
| qb_vault_gate | round vault opening, pitch-black beyond, iron grille gate, padlock | Barrows, Second Ring or First King's Barrow | flat on a wall; 1.9×0.3×1.8 m; alone | forbidding | not a real door (decor only, guess) |
| qb_mourners_bench | stone bench with knee hollows, lantern, cup, walking stick | Barrows, Shrine of Rest or First Ring | floor, against a wall; 1.6×0.7×0.7 m; alone | quiet, still visited | lantern lit |
| qb_floor_slab | floor grave slab in a kerb, lift ring, candle stubs at the head | Barrows, First Ring, Second Ring, family barrows | floor (low, can be walked past); 0.9×1.6×0.2 m; group of 2-4 | quiet | one candle lit |
| qb_cairn_grave | stepped-stone barrow grave with headstone, cup and tokens | Barrows, family barrows or First King's Barrow | floor; 0.9×1.8×0.8 m; group of 2-3; keep off paths | humble, old | oil lamp lit |
| qb_headstone_row | three headstones of different ages on one kerb, one cracked | Barrows, Long Barrow or family barrows | floor, against a wall; 1.9×0.6×0.8 m; alone | humble, old | oil lamp lit |
| qb_urn_pedestal | turned stone pedestal with one big lidded urn, copper cup | Barrows, family barrows or Mourning Niche | floor; 0.4×0.4×1.3 m; alone or pair | quiet | |
| qb_urn_cart | two-wheeled hand cart of urns, one set on the floor | Barrows, Spiral Stair landing or Second Ring | floor; 1.8×1.0×0.7 m; alone; keep off paths | still in use | |
| qb_digger_rest | gravedigger's corner: stool, barrel table, lantern, mug, slate, tools | Barrows, Keeper's Barrow or First Ring corner | floor, in a corner; 1.7×1.0×0.9 m; alone | still in use | lantern lit |
| qb_mason_bench | name-cutter's bench, name-stone half carved, chisels, blanks | Barrows, Keeper's Barrow or First Ring | floor; 1.8×0.8×0.7 m; alone | left mid-job | |
| qb_kneeler_stele | small prayer stele with crest, candle ledge, kneeling step | Barrows, Shrine of Rest or Mourning Niche | floor, against a wall; 0.6×0.6×1.1 m; alone | quiet, sacred | candle lit |
| qb_bier_trestles | empty wooden bier resting on two carved stone trestles | Barrows, First Ring or Barrow of the Twins | floor; 2.0×0.8×0.6 m; alone; keep off paths | quiet, ready | |
| qb_bone_chest | stone ossuary chest, lid slid aside, bones and two skulls inside | Barrows, Hall of Bones or Sunken Barrow | floor; 1.3×0.6×0.9 m; alone | eerie | not lootable (bones only) |
| qb_waymarker | passage marker post with runes, iron arm, hanging lit lantern | Barrows, Long Barrow, Keeper's Corridor, corridor forks | floor, beside the path; 0.4×0.6×1.3 m; alone | guiding | lantern lit |
| qb_token_pillar | short octagonal pillar with visitors' token stones | Barrows, Shrine of Rest or family barrows | floor; 0.6×0.6×0.9 m; alone | humble, cared-for | |
| qb_incense_stand | stone stand with copper incense bowl, tongs, box of cakes | Barrows, Shrine of Rest or Mourning Niche | floor; 0.4×0.4×0.9 m; alone | sacred | |
| qb_wash_basin | mourners' empty hand basin on a pedestal, clay jug | Barrows, Barrow Door or Shrine of Rest | floor; 0.7×0.5×0.7 m; alone | quiet | basin empty (fits brief) |
| qb_ancestor_bust | founder's carved bust (game dwarf) on a tall plinth, tokens, candle | Barrows, First King's Barrow or a family barrow | floor; 0.6×0.6×1.4 m; alone | proud, sacred | heavy file (1.9 MB); candle lit |

Note on lit flames: the Quiet Barrows are still visited (new burials, half-cut names), so lit lamps and candles there can count as "in use"; owner should confirm. Lampwick Drift, Mossgate Hold and Hald's Tomb are abandoned, so their lit lamps, lantern, brazier and candles break the "nothing lit unless working" rule unless the owner wants them.

## Brassgate Vault (decor_nov21_bv.py, prefix bv_)
Medium dungeon in cut stone (Stonehold greystone) with warm worn brass, iron and copper: the old treasury and counting-house of a dwarf hold.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| bv_counting_table | long stone counting table with coins, balance, ledger | Brassgate Vault: Counting Room | floor; 1.5×0.8×1.2 m; centre of a group with ledger desk and shelves | tidy, frozen in time | heavy file (1.5 MB) |
| bv_count_abandoned | counting table left mid-count: toppled coins, tipped ink, stool knocked over | Brassgate Vault: Counting Room or Clerks' Rooms | floor; 1.1×1.4×1.1 m; alone or next to bv_counting_table | abandoned | heavy file (1.8 MB) |
| bv_balance_great | great brass balance on a carved stepped plinth | Brassgate Vault: Weighing Hall | floor; 1.3×0.6×1.5 m; alone, room centrepiece | grand | |
| bv_ledger_desk | tall stone desk with chained ledger, inkwell, candle | Brassgate Vault: Counting Room, Clerks' Rooms | floor; 0.8×0.7×1.3 m; in a row of desks | quiet, abandoned | |
| bv_strongbox | iron-banded strongbox on a stone step, padlock lying open | Brassgate Vault: The Strongroom, Vault Hall | floor; 0.8×0.6×0.5 m; alone | guarded | lid is its own part (should open in game) |
| bv_strongbox_looted | strongbox smashed open, lid flung back, pry bar on floor | Brassgate Vault: Treasury Corridor, Captain's Quarters | floor; 0.7×1.0×0.8 m; alone | looted | |
| bv_coin_chest_tipped | brass-bound coin chest on its side, coins spilled in a fan | Brassgate Vault: Treasury Corridor, Forgotten Alcove | floor; 0.8×0.9×0.6 m; alone | looted, spilled | lootable: 60 gold coins → `bv_coin_chest_tipped_empty`; heavy file (1.3 MB) |
| bv_assay_bench | bench for testing gold: touchstone, needles, small balance, crucibles | Brassgate Vault: Old Mint, Weighing Hall | floor; 1.4×0.6×1.1 m; against a wall | workshop, abandoned | |
| bv_teller_counter | carved stone counter with brass grille, pay window, bell | Brassgate Vault: Toll Hall | floor; 1.6×0.6×1.7 m; one or a row across the room; keep off paths and doors | grand, abandoned | |
| bv_guard_post | guard's pillar and bench, halberd, lantern, helmet, bell | Brassgate Vault: Brass Gate, Guard Corridor, Vault Hall | floor or in a corner; 1.3×0.7×2.2 m; alone by a door | watchful | |
| bv_minting_block | eight-sided stone minting block with die, punch, blanks, hammer | Brassgate Vault: Old Mint, Workers' Hall | floor; 0.7×0.7×0.9 m; in a row of work spots | workshop, abandoned | |
| bv_assay_furnace | small cut-stone furnace, long cold, door swung open | Brassgate Vault: Old Mint | floor, back to a wall; 0.9×0.9×1.5 m; alone or by the assay bench | cold, abandoned | |
| bv_coin_cart | low iron-wheeled cart with a chained coin box | Brassgate Vault: Vault Hall, Treasury Corridor, Coin Chute end | floor; 1.2×0.8×0.7 m; alone | heavy, guarded | |
| bv_lockbox_pedestal | carved pedestal with a brass casket in a domed cage | Brassgate Vault: The Strongroom, Vault Hall | floor; 0.6×0.5×1.4 m; alone or in pairs | precious, grand | |
| bv_ledger_shelf | stone shelf full of ledgers, scroll tubes, label plates | Brassgate Vault: Counting Room, Clerks' Rooms | against a wall; 1.4×0.4×1.9 m; in a row | tidy, dusty | heavy file (1.4 MB) |
| bv_key_rack | carved key board with three rows of tagged keys | Brassgate Vault: Captain's Quarters, Guard Corridor | against a wall; 1.1×0.3×1.7 m; alone | orderly | heavy file (1.6 MB) |
| bv_key_rack_looted | key board stripped, hooks bent, keys dropped below | Brassgate Vault: Captain's Quarters, Vault Hall | against a wall; 1.1×0.4×1.7 m; alone | looted | |
| bv_weight_shelf | two stone shelves of brass weights, huge to tiny | Brassgate Vault: Weighing Hall | against a wall; 1.2×0.4×1.7 m; alone or by the balance | tidy | |
| bv_name_plaque | stone stele with a bolted brass plaque of runes | Brassgate Vault: Brass Gate, Toll Hall | against a wall; 1.1×0.3×1.8 m; alone | grand | |
| bv_coin_niche_found | hidden wall niche, cover stone pulled out, coins inside | Brassgate Vault: Clerk's Hoard, Forgotten Alcove | against a wall; 1.2×1.1×1.5 m (cover stone lies in front); alone | secret, found | lootable: 25 gold coins → `bv_coin_niche_found_empty` |
| bv_pigeonholes | stone block of cubbies with coins, purses, scroll tubes | Brassgate Vault: Counting Room, Clerks' Rooms | against a wall; 1.4×0.5×1.6 m; alone | orderly | lootable: 40 coins (gold and silver) → `bv_pigeonholes_empty`; heavy file (1.7 MB) |
| bv_vault_door | round iron vault door with brass rim and locking wheel | Brassgate Vault: Vault Hall (in front of The Strongroom) | against a wall; 2.0×0.5×2.0 m; alone; keep off paths and doors | grand, shut | |
| bv_lock_works | great lock opened up: brass case, bolts, tumblers, key | Brassgate Vault: Vault Hall, Inner Door | against a wall; 1.2×0.4×1.7 m; alone | clever, grand | |
| bv_guild_medallion | round counting-guild medallion with carved scales | Brassgate Vault: Toll Hall, Brass Gate | against a wall; 1.3×0.3×1.9 m; alone, above eye line | grand | |
| bv_wall_lantern | carved stone post with a brass cage lantern on a chain | Brassgate Vault: any hall or corridor | against a wall; 0.6×0.5×1.9 m; repeated along walls | still lit | lit (glows) |
| bv_halberd_rack | stone rack of three guard halberds, one slot empty | Brassgate Vault: Guard Corridor, Captain's Quarters | against a wall; 1.1×0.4×2.2 m; alone | guarded | |
| bv_lockbox_shelf | shelves of small iron deed boxes, one gone, one pried open | Brassgate Vault: Clerks' Rooms, The Strongroom | against a wall; 1.3×0.4×1.7 m; alone | half-looted | |
| bv_vault_door_forced | round vault door forced open and swung wide | Brassgate Vault: Inner Door | against a wall; 2.3×1.9×2.0 m; alone; keep the doorway clear | broken in, grand | walk-through round doorway (flat, 3 cm threshold); heavy file (1.0 MB) |

## Hall of the Shieldbearers (decor_nov21_hs.py, prefix hs_)
Medium dungeon in cut stone (Stonehold greystone): barracks of an old order of dwarf shield-guards; one wood family, iron, copper and leather fittings.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| hs_shield_wall | carved stone panel hung with 5 painted shields and crossed spears | Hall of the Shieldbearers: Muster Gate, Captain's Hall | against a wall; 2.1×0.2×1.9 m; alone | grand, proud | heavy file (1.1 MB) |
| hs_spear_rack | wall spear rack with 5 spears, one empty slot | Hall of the Shieldbearers: Barracks Row, Armoury | against a wall; 1.4×0.2×2.0 m; in a row | orderly | |
| hs_axe_rack | plank board with 3 bearded axes, whetstones, oil flask | Hall of the Shieldbearers: Armoury, Captain's Armoury | against a wall; 1.2×0.2×1.7 m; in a row with other racks | orderly | |
| hs_helm_shelf | stone shelf unit with 8 helmets on wooden stands | Hall of the Shieldbearers: Armoury | against a wall; 1.4×0.4×1.5 m; alone or in a row | orderly, proud | heavy file (1.4 MB) |
| hs_order_crest | big shield-shaped stone plaque with the order's crest | Hall of the Shieldbearers: Muster Gate, Captain's Hall | against a wall; 1.1×0.2×2.0 m; alone, centred | grand | |
| hs_roll_of_honour | tall tablet of the fallen's names, shield tags, candle ledge | Hall of the Shieldbearers: Banner Hall | against a wall; 1.1×0.3×1.7 m; alone | solemn | |
| hs_split_shield_trophy | round plaque: shield split by an axe still stuck in it | Hall of the Shieldbearers: Captain's Hall, Sergeant's Quarters | flat on a wall; 0.9×0.7×0.9 m (axe sticks out); alone | proud trophy | |
| hs_buckler_rail | iron rail with 6 small bucklers on leather loops | Hall of the Shieldbearers: Armoury, Training Yard | against a wall; 1.5×0.2×1.5 m; alone | orderly | heavy file (1.4 MB) |
| hs_boss_shelf | repairer's board of shield bosses, rim strips, rivet trays | Hall of the Shieldbearers: Armoury (repair corner) | against a wall; 1.1×0.2×1.7 m; next to the repair bench | tidy workshop | heavy file (1.0 MB) |
| hs_tool_wall | shield-maker's tool board with painted outlines, one tool missing | Hall of the Shieldbearers: Armoury (repair corner) | against a wall; 1.3×0.2×1.6 m; with repair bench and boss shelf | tidy workshop | |
| hs_order_banner | swallowtail banner with shield and anvil, tassels | Hall of the Shieldbearers: Banner Hall, Captain's Hall | against a wall; 1.1×0.2×2.1 m; in a row along the walls | grand, faded | |
| hs_squad_pennants | carved stone header with 5 squad pennants | Hall of the Shieldbearers: Parade Ground, Mess Hall | against a wall; 1.5×0.2×1.9 m; alone | proud | |
| hs_strap_rack | rack of leather shield straps, buckle box, knife | Hall of the Shieldbearers: Armoury | against a wall; 1.0×0.2×1.6 m; in a row with other racks | tidy workshop | |
| hs_duty_roster | stone-framed peg board of duty tags, empty pegs | Hall of the Shieldbearers: Muster Gate, Bunk Rooms | against a wall; 1.2×0.2×1.8 m; alone | orderly, abandoned | |
| hs_repair_bench | bench with a half-repainted shield clamped down | Hall of the Shieldbearers: Armoury (repair corner) | floor, back to a wall; 1.7×0.8×1.1 m; group with boss shelf and tool wall | work left mid-way | |
| hs_shieldbearer_stand | armour stand: dwarf form in a scale shirt, helm, shield on a peg post | Hall of the Shieldbearers: Armoury, Captain's Armoury | floor; 1.3×0.6×1.1 m; alone or a pair | proud, guarded | heavy file (2.0 MB) |
| hs_muster_table | stone table with a map grid and iron shield tokens | Hall of the Shieldbearers: Sergeant's Quarters, Captain's Hall | floor; 1.5×0.9×0.9 m; alone, room centre | planning, frozen in time | |
| hs_oath_stone | oath stone with a carved hand-print, copper cup, kneeling step | Hall of the Shieldbearers: Banner Hall, Captain's Hall | floor; 1.2×1.0×1.0 m; alone | solemn | |
| hs_guard_bunk | bare two-tier guard bunk with footlocker | Hall of the Shieldbearers: Bunk Rooms | floor, against a wall; 2.2×0.9×1.6 m; rows of bunks | abandoned | |
| hs_shield_pell | training post with a battered shield nailed on | Hall of the Shieldbearers: Training Yard, Drill Cellar | floor; 1.0×1.0×1.6 m; in a row of pells | battered | |
| hs_captains_chair | captain's chair on a stone dais, shield-shaped back | Hall of the Shieldbearers: Captain's Hall | floor, back to a wall; 1.2×1.0×1.8 m; alone | grand | |
| hs_fallen_shield_wall | the last shield wall toppled like dominoes, broken spears | Hall of the Shieldbearers: Shield Bridge end, Parade Ground | floor (lying flat); 3.0×1.7×0.3 m; alone; keep off paths and doors | last stand, eerie | heavy file (1.0 MB) |
| hs_last_stand_cairn | rubble cairn with the captain's axe, helmet and shield | Hall of the Shieldbearers: Captain's Hall, Banner Hall | floor; 1.3×1.3×1.6 m; alone | solemn | |
| hs_paint_rack | drying rack of freshly painted shields, stool, paint pots | Hall of the Shieldbearers: Armoury | floor; 2.2×0.6×0.7 m; alone; keep off paths | work left mid-way | |
| hs_rim_jig | round jig with a shield rim half bent, tools | Hall of the Shieldbearers: Armoury (repair corner) | floor; 1.4×1.2×0.9 m; with repair bench | work left mid-way | |
| hs_tower_shields_chained | tall tower shields stacked against a stone ledge | Hall of the Shieldbearers: Armoury, Armoury Door | floor, against a wall; 1.6×0.7×1.1 m; alone | stored | name says "chained" but no chain (owner, Nov 22) |
| hs_war_horn_stand | stone stand with the great war horn in iron cradles | Hall of the Shieldbearers: Muster Gate, Captain's Hall | floor; 1.0×0.4×1.6 m; alone | grand | |
| hs_helm_trophy_pole | trophy pole with captured helmets and a split enemy shield | Hall of the Shieldbearers: Parade Ground, Captain's Hall | floor; 1.1×0.5×2.1 m; alone | proud, grim | |
| hs_watch_brazier | guard brazier on a carved pedestal, coal and embers, poker | Hall of the Shieldbearers: Muster Gate, Sentry Walk, Captain's Hall | floor; 0.7×0.7×1.1 m; in pairs by doors | still burning | lit (glowing embers, low flames) |
| hs_practice_trough | stone trough of padded practice weapons | Hall of the Shieldbearers: Training Yard, Drill Cellar | floor, against a wall; 1.3×0.4×1.6 m; alone | training | |

## Vigil of Orrin Stonejaw (decor_nov21_vo.py, prefix vo_)
Medium dungeon in cut stone (Stonehold greystone) with iron, bronze and dark wood: Orrin's lifelong watch over a sealed deep passage; his sign is an open eye over a bar.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| vo_vigil_brazier | the ever-burning brazier: carved pedestal, stone fire basin | Vigil of Orrin Stonejaw: Orrin's Vigil, Quiet Shrine | floor; 0.9×0.9×0.9 m; alone, centre | eerie, still burning | lit (low embers glow) |
| vo_brazier_cold | iron fire basket gone cold, poker dropped, coal scuttle tipped | Vigil of Orrin Stonejaw: Bell Walk, Antechamber | floor; 1.6×1.1×0.9 m; alone | cold, abandoned | |
| vo_lookout_seat | watchman's high stone seat on a dais, eye carved in the back | Vigil of Orrin Stonejaw: Orrin's Rest, Bell Walk | floor; 1.1×0.9×1.6 m; alone, facing the door | watchful | |
| vo_spyhole_wall | wall block with a spyhole cut right through, shutter open | Vigil of Orrin Stonejaw: Antechamber wall beside Orrin's Vigil | against a wall (part of the wall); 1.3×0.8×1.7 m; alone | eerie, watchful | real see-through hole (owner idea: peek at the boss first) |
| vo_signal_horn | great signal horn in two saddles on a carved stand | Vigil of Orrin Stonejaw: Bell Walk, Orrin's Vigil | floor; 1.4×0.5×1.2 m; alone | watchful | |
| vo_vigil_candles | three stepped stone ledges of vigil candles, wax runs | Vigil of Orrin Stonejaw: Quiet Shrine, Orrin's Rest | against a wall; 1.3×0.4×1.3 m; alone | solemn, still burning | some candles lit (glow); heavy file (1.1 MB) |
| vo_kneeling_stone | worn kneeling stone with knee hollows, prayer rail, candle stubs | Vigil of Orrin Stonejaw: Quiet Shrine, Robing Room | floor; 0.9×0.8×0.5 m; in front of an oath or prayer wall | solemn | |
| vo_oath_tablet | tall round-topped oath stele with eye sign and rune lines | Vigil of Orrin Stonejaw: Pilgrims' Door, Rune Gallery | against a wall; 0.9×0.4×1.5 m; alone | solemn | |
| vo_prayer_tablets | stone shelf wall of small carved prayer tablets | Vigil of Orrin Stonejaw: Quiet Shrine, Acolytes' Cells | against a wall; 1.4×0.4×1.3 m; alone | quiet | |
| vo_sealed_passage | round sealed door with three great iron locking bars | Vigil of Orrin Stonejaw: Orrin's Vigil (door behind the bell) | against a wall; 2.3×0.5×2.0 m; alone; keep off paths and doors | eerie, sealed | |
| vo_bar_rack | spare locking bars on notched corbels, wedges, key ring | Vigil of Orrin Stonejaw: Antechamber, Bellringer's Loft | against a wall; 1.6×0.5×1.4 m; alone | watchful | |
| vo_jawhelm_stand | Orrin's jaw-guard helm on a stone head-stand | Vigil of Orrin Stonejaw: Orrin's Rest | floor; 0.6×0.6×1.5 m; alone | proud, solemn | |
| vo_armour_stand | Orrin's lamellar coat on a stone cross-post | Vigil of Orrin Stonejaw: Orrin's Rest, Robing Room | floor; 0.8×0.6×1.1 m; alone or by the helm stand | proud, solemn | heavy file (1.7 MB) |
| vo_warning_relief | warning carving: stairs into a pit, clawed hands, the watching eye | Vigil of Orrin Stonejaw: Rune Gallery, Antechamber | against a wall; 1.7×0.4×1.5 m; alone | eerie | |
| vo_relief_oath | carved panel: Orrin swearing the vigil before the king | Vigil of Orrin Stonejaw: Rune Gallery, Hall of Pillars | against a wall; 1.7×0.3×1.5 m; part of a story row with the other reliefs | grand, story | |
| vo_relief_last_watch | carved panel: old Orrin on his seat, horn in hand | Vigil of Orrin Stonejaw: Rune Gallery | against a wall; 1.7×0.3×1.5 m; part of a story row | solemn, story | |
| vo_log_lectern | stone lectern with the chained open watch log | Vigil of Orrin Stonejaw: Orrin's Rest, Bell Walk | floor; 0.7×0.6×1.1 m; alone | quiet | |
| vo_log_shelf | stone shelf packed with leather watch logs, scroll tubes | Vigil of Orrin Stonejaw: Orrin's Rest, Carvers' Workshop | against a wall; 1.3×0.5×1.7 m; alone | dusty, orderly | heavy file (1.9 MB) |
| vo_hourglass_stand | big hourglass in a bronze cradle on a dial pedestal | Vigil of Orrin Stonejaw: Bell Walk, Orrin's Rest | floor; 0.5×0.5×1.2 m; alone | watchful | |
| vo_tally_wall | panel of day-tallies cut in rows, last row unfinished | Vigil of Orrin Stonejaw: Orrin's Rest, Bellringer's Loft | against a wall; 1.8×0.4×1.5 m; alone | lonely, eerie | |
| vo_final_vigil | Orrin's bones on his bench, horn across his lap | Vigil of Orrin Stonejaw: Orrin's Rest | floor; 1.2×1.2×1.1 m; alone, room centrepiece | eerie, sad | heavy file (1.0 MB) |
| vo_horn_fallen | horn stand with a broken saddle, horn rolled on the floor | Vigil of Orrin Stonejaw: Hall of Echoes, Bell Walk | floor; 1.7×0.8×0.8 m; alone | broken, abandoned | |
| vo_bar_snapped | locking bar snapped, staple torn out, halves on the floor | Vigil of Orrin Stonejaw: Antechamber, Rune Door | against a wall; 1.3×0.9×1.5 m; alone | broken in, eerie | |
| vo_claw_marks | wall gouged by four deep claw marks, broken block on floor | Vigil of Orrin Stonejaw: Antechamber, Acolytes' Cells | against a wall; 1.6×0.9×1.6 m; alone | eerie, danger | |
| vo_dropped_lantern | lantern dropped on its side, log face-down, stool knocked over | Vigil of Orrin Stonejaw: Bell Walk, First Stair landing | floor; 1.3×0.9×0.3 m; alone | eerie, sudden | |
| vo_oil_niche | arched niche of clay oil jars, flasks, funnel, ladle | Vigil of Orrin Stonejaw: Robing Room, Bellringer's Loft | against a wall; 1.1×0.5×1.4 m; alone | stored, quiet | |
| vo_candle_rack | iron pegs of spare candles, mould and wax pot below | Vigil of Orrin Stonejaw: Robing Room, Quiet Shrine | against a wall; 1.3×0.4×1.3 m; alone | tidy | |
| vo_wall_brazier | iron fire basket on a carved corbel, eye above | Vigil of Orrin Stonejaw: Hall of Pillars, any hall | against a wall; 0.8×0.7×1.8 m; repeated along walls | still burning | lit (low embers glow) |
| vo_axe_rest | Orrin's great axe standing in a carved socket block | Vigil of Orrin Stonejaw: Orrin's Rest, Orrin's Vigil | floor; 0.6×0.6×1.5 m; alone | proud | |
| vo_orrin_bust | stone bust of Orrin in his jaw-guard helm, name cut in | Vigil of Orrin Stonejaw: Pilgrims' Door, Orrin's Rest | floor; 0.7×0.7×1.6 m; alone | grand, solemn | heavy file (1.9 MB) |

## Emberdeep Forge (decor_nov21_ef.py, prefix ef_)
Big dungeon in clay brick (Hearthbrick style) with limestone trim, one wood family, iron, copper and leather: the great smithy of the deep, abandoned and cold.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| ef_tong_rack | brick panel with an iron rail of seven tongs | Emberdeep Forge: Tool Hall, Hall of Anvils | against a wall; 1.2×0.3×1.3 m; in a row of racks | orderly | heavy file (1.4 MB) |
| ef_hammer_rack | wooden rails with hammers hung by their heads | Emberdeep Forge: Tool Hall | against a wall; 1.2×0.3×1.4 m; in a row of racks | orderly | heavy file (1.7 MB) |
| ef_blade_rack | finished swords point-down in a slotted sill | Emberdeep Forge: Cooling Room, Forge Treasury | against a wall; 1.4×0.3×1.6 m; alone or a row | proud | heavy file (1.8 MB) |
| ef_master_display | master's wall: crossed great swords, shield, helm, gold cup | Emberdeep Forge: Master's Study, Forge Treasury | against a wall; 1.7×0.3×2.0 m; alone, centred | grand | heavy file (1.5 MB) |
| ef_smiths_lintel | long limestone lintel with eight smiths' marks | Emberdeep Forge: Hall of Anvils, Great Door | flat on a wall (high, over a hearth or door, guess); 1.7×0.2×0.6 m; alone | proud | |
| ef_file_board | plank tool board of files, rasps, punches | Emberdeep Forge: Tool Hall, Apprentices' Dorm | flat on a wall; 1.0×0.1×0.8 m; alone | tidy | heavy file (1.1 MB) |
| ef_mould_shelf | two shelves of clay casting moulds, crucibles, ladle | Emberdeep Forge: Tool Hall, Furnace Gallery | against a wall; 1.2×0.4×1.3 m; alone | dusty | heavy file (1.0 MB) |
| ef_chimney_hood | riveted copper forge hood with brick flue, tool rail | Emberdeep Forge: Hall of Anvils (over a hearth), Hidden Smithy | against a wall; 1.2×0.8×1.9 m; pairs with ef_forge_hearth | cold, grand | |
| ef_ingot_wall | wooden cubby rack of ingot stacks (iron, copper, a little gold) | Emberdeep Forge: Ore Sorting, Forge Treasury | against a wall; 1.1×0.3×1.3 m; alone | stored | lootable: amount not set by the owner yet (header suggests 3 iron ingots) → `ef_ingot_wall_empty`; heavy file (1.4 MB) |
| ef_commission_board | board of clay order tablets on copper pegs | Emberdeep Forge: Foreman's Office | flat on a wall; 1.0×0.1×0.8 m; alone | orderly, abandoned | |
| ef_blade_on_anvil | bare anvil on its stump, hammer dropped, empty bucket | Emberdeep Forge: Hall of Anvils, Ash Hall | floor; 1.0×1.1×0.9 m; in rows of anvils | abandoned mid-work | |
| ef_cracked_quench | quench tub with a sword snapped in two | Emberdeep Forge: Quench Hall, Cooling Room | floor; 1.2×1.0×0.7 m; alone | failed work | tub holds dark still water (brief says no water) |
| ef_bent_blade_vise | apprentice's vise with a sword bent crooked, split hammer | Emberdeep Forge: Apprentices' Dorm, Tool Hall | floor; 1.1×0.8×1.4 m; alone | failed work | |
| ef_axe_progression | bench showing an axe in six steps, numbered tags | Emberdeep Forge: Apprentices' Dorm, Master's Study | floor, against a wall; 1.6×0.5×0.7 m; alone | teaching, tidy | |
| ef_fallen_hood | copper hood torn down among broken flue bricks | Emberdeep Forge: Ash Hall, Furnace Gallery | floor; 1.6×1.2×0.8 m; alone; keep off paths | collapsed | |
| ef_burst_crucible | cracked crucible in halves, shards, tongs, empty mould | Emberdeep Forge: Furnace Gallery, Slag Pits | floor; 1.3×0.9×0.4 m; alone | failed work | |
| ef_broken_grindstone | snapped grinding wheel, half fallen against the frame | Emberdeep Forge: Tool Hall, Cooling Room | floor; 1.2×0.7×1.0 m; alone | broken | |
| ef_forge_hearth | brick forge hearth with iron fire pot, cold coal, tool rail | Emberdeep Forge: Hall of Anvils, Heart of Emberdeep, Hidden Smithy | floor, back to a wall; 1.8×1.1×0.9 m; under ef_chimney_hood; keep off paths | cold | heavy file (1.9 MB) |
| ef_quench_trough | brick quench trough with dark water, dipper on rim | Emberdeep Forge: Quench Hall, Hall of Anvils | floor; 1.4×0.8×0.7 m; next to a hearth | cold | has water (brief says no water; owner said leave it for now); heavy file (1.8 MB) |
| ef_grinding_wheel | treadle grinding wheel with crank and drip pot | Emberdeep Forge: Tool Hall, Cooling Room | floor; 0.8×0.7×1.2 m; alone | still usable | |
| ef_swage_block | heavy iron swage block on a banded wooden stand | Emberdeep Forge: Hall of Anvils | floor; 0.5×0.5×0.9 m; beside anvils | heavy, still usable | |
| ef_coal_bunker | brick bunker heaped with black coal, shovel stuck in | Emberdeep Forge: Coal Store, Coal Cellar | floor, against a wall; 1.4×1.2×1.0 m; one or a row | dusty | heavy file (1.8 MB) |
| ef_ember_pan | iron ember pan on three legs, cold coals, poker | Emberdeep Forge: Ash Hall, Furnace Gallery | floor; 1.0×0.7×0.5 m; alone | cold | |
| ef_bar_stock_rack | cantilever rack of iron bars and copper rods, bin of short bars | Emberdeep Forge: Tool Hall, Ore Sorting | floor, against a wall; 1.5×0.6×1.3 m; alone | stored | |
| ef_apprentice_bench | tidy bench: stake anvil, half-made knives, tools in order | Emberdeep Forge: Apprentices' Dorm, Hidden Smithy | floor, against a wall; 1.2×0.5×0.9 m; alone or a row | tidy | |
| ef_cooling_rack | iron rack on brick feet with finished blades laid across | Emberdeep Forge: Cooling Room | floor; 1.3×0.5×0.8 m; in rows | cold, still stocked | lootable: 1 stone sword → `ef_cooling_rack_empty` (blades gone) |
| ef_whetstone_table | sharpening table: whetstones, oil flask, strop, a blade | Emberdeep Forge: Tool Hall, Cooling Room | floor, against a wall; 1.0×0.5×0.9 m; alone | tidy | |
| ef_scrap_bin | iron-banded bin of broken blades and offcuts | Emberdeep Forge: Hall of Anvils, Slag Pits | floor; 0.8×0.6×0.6 m; in a corner | messy | |
| ef_coal_scuttle | copper coal scuttle heaped with coal, shovels | Emberdeep Forge: beside any hearth, Coal Store | floor; 0.7×0.5×0.9 m; next to a hearth | ready to use | lootable: 3 coal → `ef_coal_scuttle_empty` |
| ef_ring_mandrel | cone mandrel on a stump with rings slid down it | Emberdeep Forge: Master's Study, Hidden Smithy | floor; 0.4×0.4×1.1 m; beside a bench | fine craft | |

## The Hammerfall Works (decor_nov21_hw.py, prefix hw_)
Big dungeon in clay brick (Hearthbrick style) with one wood family, iron and copper: the hold's heavy works, once driven by a great water wheel (trip hammers, gears, line shafts), all dry now.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| hw_gear_wall | wall board of spare gears on pegs, cogs on a shelf | The Hammerfall Works: Gearworks, Gearmaster's Loft | against a wall; 1.6×0.3×1.4 m; alone | orderly | heavy file (1.2 MB) |
| hw_parts_rack | millwright's rack of bearing blocks, tappets, collars, bolts | The Hammerfall Works: Toolroom, Gearworks | against a wall; 1.4×0.4×1.7 m; alone | tidy | heavy file (1.1 MB) |
| hw_hammer_head_rack | wall beams holding three spare trip-hammer heads | The Hammerfall Works: Press Hall, Great Anvil Hall | against a wall; 1.4×0.3×1.1 m; alone | heavy, stored | |
| hw_tool_board | millwright's tool board: adze, mallet, auger, chisels, rope | The Hammerfall Works: Toolroom | flat on a wall; 1.2×0.2×1.0 m; alone | tidy | |
| hw_belt_pulley_wall | wall brackets with a belt drum, rope belt to a hanging weight | The Hammerfall Works: Gearworks, Belt Walk | against a wall; 0.8×0.5×1.6 m; alone | machine, still | |
| hw_chain_hook_wall | hook rail: lifting hooks on chains, chain coils, pulley block | The Hammerfall Works: Yard, Press Hall | flat on a wall; 1.3×0.2×1.2 m; alone | heavy duty | |
| hw_signal_lever_wall | three signal levers in a slot frame wired to bells | The Hammerfall Works: Gearworks, Press Hall | against a wall; 1.2×0.5×1.5 m; alone | machine | |
| hw_shift_board | board of clay tally tablets, hammer tokens, hourglass | The Hammerfall Works: Clerk's Office, Works Gate | flat on a wall; 1.1×0.2×1.0 m; alone | orderly | |
| hw_grease_shelf | shelf of grease pots, tallow, oil can, brush, pail | The Hammerfall Works: Oil Store, Gearworks | flat on a wall; 1.1×0.3×1.0 m; alone | messy workshop | |
| hw_trip_hammer | the great tail-helve trip hammer on its cam shaft | The Hammerfall Works: Press Hall, Great Anvil Hall | floor; 2.9×1.7×1.3 m; alone, room centrepiece; keep off paths and doors | grand, stopped | heavy file (1.2 MB) |
| hw_plate_anvil | plate-beating anvil with a half-beaten plate, two hammers | The Hammerfall Works: Proving Ground, Great Anvil Hall | floor; 1.1×1.1×0.7 m; alone or a row | work left mid-way | |
| hw_gear_train | right-angle drive: big face-cog and lantern pinion | The Hammerfall Works: Gearworks | floor; 2.0×1.6×2.1 m; alone; keep off paths and doors | grand machine | heavy file (1.9 MB) |
| hw_line_shaft | line shaft on brick piers with belt drums and rope belts | The Hammerfall Works: Gearworks, Belt Walk | floor; 2.3×1.0×1.7 m; alone; keep off paths | machine, still | heavy file (1.2 MB) |
| hw_wheel_trough | water wheel standing in its dry wooden race | The Hammerfall Works: Furnace Undercroft, Gearworks (guess) | floor, against a wall; 2.7×1.7×2.1 m; alone; keep off paths and doors | grand, dry | heavy file (2.0 MB) |
| hw_sluice_gate | sluice: flume channel, gate board lifted by a windlass | The Hammerfall Works: next to the wheel trough | floor; 1.1×1.6×2.0 m; with hw_wheel_trough / hw_flume_trough | dry, still | |
| hw_flume_trough | dry wooden flume on a trestle over an empty brick trough | The Hammerfall Works: Yard, Furnace Undercroft | floor; 1.6×1.4×1.2 m; in a line with the sluice | dry | heavy file (1.7 MB) |
| hw_plate_stack | three stacks of iron plate on timber skids | The Hammerfall Works: Yard, Proving Ground | floor; 2.0×0.5×0.3 m; alone, against a wall | stored | |
| hw_rivet_brazier | rivet-heating brazier with coal and glowing rivets | The Hammerfall Works: Smithy Nook, Proving Ground | floor; 1.2×1.0×0.9 m; alone | still working | glows (embers and hot rivets) |
| hw_chain_hoist | timber gantry with pulley, chain holding an iron plate | The Hammerfall Works: Yard, Press Hall | floor; 2.0×1.4×2.3 m; alone; keep off paths and doors | heavy, still | |
| hw_ingot_cart | ingot cart on a rail section, stacked bronze ingots | The Hammerfall Works: Yard, Ore Cart Ramp foot | floor; 1.7×0.8×0.7 m; alone | stocked | lootable: 3 bronze ingots → `hw_ingot_cart_empty`; has a rail section (brief: avoid rails); heavy file (1.2 MB; empty 1.1 MB) |
| hw_ingot_stack | pallet of bronze ingots, chocks, tally stick, crowbar | The Hammerfall Works: Yard, Masterwork Treasury | floor; 1.4×0.9×0.6 m; alone or in a row | stocked | lootable: 3 bronze ingots → `hw_ingot_stack_empty` |
| hw_overseer_platform | raised plank platform with railing, steps and standing desk | The Hammerfall Works: Press Hall, Great Anvil Hall | floor; 2.6×1.2×2.4 m; alone, at a room edge; keep off paths and doors | watchful | heavy file (1.3 MB) |
| hw_signal_whistle | shift whistle: wind box on a post, copper pipes, bellows | The Hammerfall Works: Works Gate, Yard | floor; 0.5×0.8×2.2 m; alone, by a wall | still | |
| hw_spare_shaft | spare cam shaft on trestles, half its tappets fitted | The Hammerfall Works: Gearworks, Toolroom | floor; 2.1×1.2×1.1 m; alone; keep off paths | work left mid-way | |
| hw_plate_shears | lever shears on a timber block, cut strips at its foot | The Hammerfall Works: Proving Ground, Press Hall | floor; 1.6×0.9×1.1 m; alone | still usable | |
| hw_jammed_hammer | trip hammer jammed with a crowbar in the cam | The Hammerfall Works: Press Hall, Great Anvil Hall | floor; 3.1×1.8×1.3 m; alone; keep off paths and doors | broken, abandoned | heavy file (1.2 MB) |
| hw_derailed_cart | empty ingot cart off its rails on its side, wheel rolled away | The Hammerfall Works: Ore Cart Ramp foot, Yard | floor; 1.8×1.5×0.6 m; alone; keep off paths | wrecked | has a rail section (brief: avoid rails); heavy file (1.1 MB) |
| hw_snapped_chain | snapped hoist chain, fallen plate cracked the floor bricks | The Hammerfall Works: Yard, Bridge of Chains | floor (lying flat); 1.6×1.3×0.2 m; alone, under/near hw_chain_hoist | accident | |
| hw_broken_cog | cog with broken teeth on a trestle, new cog half cut | The Hammerfall Works: Gearworks, Gearmaster's Loft | floor; 1.9×1.4×1.2 m; alone; keep off paths | repair left mid-way | |
| hw_burst_sluice | burst sluice gate, half the board in the dry channel | The Hammerfall Works: Furnace Undercroft (guess) | floor; 1.4×2.3×2.0 m; alone; keep off paths | broken, dry | |

## Cinderhold Foundry (decor_nov21_cf.py, prefix cf_)
Big dungeon in clay brick (Hearthbrick style) with copper and iron: where dwarves melted metal and cast bells, ingots and pots; glow only where metal is still hot.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| cf_tongs_wall | board of seven foundry tongs on iron hooks | Cinderhold Foundry: Tool Crib, Crucible Hall | flat on a wall; 1.3×0.2×1.3 m; alone | orderly | |
| cf_ladle_rack | five pouring ladles with crusted bowls, pouring cups below | Cinderhold Foundry: Casting Floor, Crucible Hall | against a wall; 1.3×0.3×1.6 m; alone | used, orderly | |
| cf_pattern_shelf | shelves of pale wooden patterns: bells, pot, gear, ingots | Cinderhold Foundry: Pattern Store, Pattern Vault | against a wall; 1.3×0.4×1.6 m; in a row | tidy | |
| cf_crucible_shelf | three shelves of clay crucibles, graded sizes | Cinderhold Foundry: Crucible Hall, Tool Crib | against a wall; 1.3×0.3×1.5 m; alone | stored | |
| cf_skimmer_rack | rack of long tools: skimmers, slag rakes, pokers | Cinderhold Foundry: Smelter Row, Tapping Hall | against a wall; 1.3×0.2×1.6 m; alone | orderly | |
| cf_mould_board | iron moulds hung by ring handles: ingots, coins, spoon | Cinderhold Foundry: Casting Floor, Tool Crib | flat on a wall; 1.2×0.2×1.4 m; alone | orderly | one mould is for arrowheads (brief: no arrows, only crossbow bolts) |
| cf_master_mark_stone | foundry master's mark carved in a stone, pour tally | Cinderhold Foundry: Foundry Master's Hall | against a wall; 1.3×0.4×1.7 m; alone | proud | |
| cf_strickle_board | bell strickle template, calipers, measuring rod | Cinderhold Foundry: Pattern Store, Casting Floor | flat on a wall; 1.2×0.2×1.6 m; near the bell pit | craft | |
| cf_casting_shelf | shelf of finished castings: bells, pots, gears, knockers | Cinderhold Foundry: Foundry Treasury, Pattern Store | against a wall; 1.3×0.3×1.5 m; alone | proud | heavy file (1.2 MB) |
| cf_flux_shelf | lidded flux jars, crock of flux lumps, small scale | Cinderhold Foundry: Smelter Row, Weighmaster's Room | against a wall; 1.1×0.3×1.4 m; alone | tidy | |
| cf_crucible_furnace | round brick crucible furnace, crucible of molten metal in coals | Cinderhold Foundry: Smelter Row, Tapping Hall | floor; 1.5×1.2×0.8 m; alone or a row | still working, hot | glows (molten metal, hot coals); heavy file (1.1 MB) |
| cf_crucible_stand | iron tripod on a brick block holding molten metal | Cinderhold Foundry: Casting Floor, Crucible Hall | floor; 0.6×0.7×0.8 m; beside moulds | still working, hot | glows (molten metal) |
| cf_crucible_shank | two-dwarf carrying shank with a cooled crucible | Cinderhold Foundry: Casting Floor, Crucible Hall | floor; 1.8×0.6×0.7 m; alone | resting, cold | |
| cf_flask_stack | three clamped sand casting flasks | Cinderhold Foundry: Casting Floor | floor; 0.8×0.6×0.6 m; in a group with moulders' bench | ready | |
| cf_mould_box_open | opened mould: hammer-head cavity, cope turned over | Cinderhold Foundry: Casting Floor | floor (lying flat); 1.3×0.6×0.2 m; with flask stack | work left mid-way | |
| cf_ingot_mould_row | long iron ingot mould on bricks, one ingot still glowing | Cinderhold Foundry: Casting Floor, Tapping Hall | floor; 1.8×0.8×0.3 m; alone or a row | just poured | one ingot glows |
| cf_ingot_stack | bronze ingots stacked crosswise on a pallet | Cinderhold Foundry: Weighmaster's Room, Foundry Treasury | floor; 0.7×0.6×0.3 m; alone or a few | stocked | lootable: 3 bronze ingots → `cf_ingot_stack_empty` |
| cf_bell_pit | half-dug bell in its brick pit, broken loam mould | Cinderhold Foundry: Casting Floor, Foundry Master's Hall | floor (sunk look, sits on top); 1.8×1.8×1.1 m; alone; keep off paths | grand, unfinished | heavy file (1.2 MB) |
| cf_bell_cracked | failed bell on its side on chocks, long crack, sledge | Cinderhold Foundry: Casting Floor, Slag Heap | floor; 1.7×1.4×1.0 m; alone; keep off paths | failed work | |
| cf_slag_cart | two-wheeled cart full of dark glassy slag | Cinderhold Foundry: Smelter Row, Slag Heap | floor; 0.9×1.3×0.6 m; alone | working | |
| cf_slag_cart_tipped | slag cart tipped forward, slag spilled across the floor | Cinderhold Foundry: Slag Heap, Ore Dock | floor; 0.9×1.8×0.9 m; alone | accident | |
| cf_flux_tub | iron-hooped stave tub of pale flux stone, wooden scoop | Cinderhold Foundry: Smelter Row | floor; 0.8×0.7×0.6 m; next to a furnace | working | |
| cf_cooling_rack | iron rack of fresh castings cooling, newest pot glowing | Cinderhold Foundry: Casting Floor, Crucible Hall | floor; 1.2×0.6×1.0 m; alone or a row | just made | one pot glows dull red |
| cf_crucible_dropped | cracked crucible dropped, cold metal slug slid out, tongs | Cinderhold Foundry: First Bridge end, Casting Floor | floor; 1.4×1.0×0.4 m; alone | accident | |
| cf_sand_bin | three-sided brick bin of moulding sand, shovel, sieve, rammer | Cinderhold Foundry: Casting Floor | floor, against a wall; 1.5×1.0×1.1 m; alone | working | |
| cf_moulders_bench | moulder's bench: half-rammed flask, rammers, trowels | Cinderhold Foundry: Casting Floor, Pattern Store | floor, against a wall; 1.2×0.6×0.9 m; with flask stack and sand bin | work left mid-way | has a bucket of water on it (brief says no water) |
| cf_quench_trough | dry brick quench trough, cast pot on a pole, tongs | Cinderhold Foundry: Casting Floor, Tapping Hall | floor; 1.2×0.6×0.6 m; alone | dry, cold | |
| cf_scrap_crate | crate of scrap for remelting: bell shards, gears, rods | Cinderhold Foundry: Ore Sorters, Smelter Row | floor; 0.9×0.6×0.6 m; in a corner | messy | |
| cf_charcoal_bay | low brick bay of black glossy charcoal, shovel, full scuttle | Cinderhold Foundry: Coal Bunker, Smelter Row | floor, against a wall; 1.5×0.8×1.0 m; alone | stocked | lootable: 5 coal → `cf_charcoal_bay_empty`; heavy file (1.1 MB) |


All 187 glbs with prefixes bv_, hs_, vo_, ef_, hw_, cf_ were placed (177 rows + 10 `_empty` twins). None left over.

## Ruined Tower / Watchtower (decor_nov21_ru.py, prefix rt_)

Inside the old dwarf stone watchtower ruin: greystone, tower wood, iron, bronze.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `rt_stair_landing_broken` | Snapped stair column with fallen steps and a bent rail | Ruined Tower: foot of the broken spiral stair | Floor, 2.2×1.5×0.9 m; alone; keep off the real stairs and paths | Ruined |  |
| `rt_lookout_brazier` | Cold iron fire bowl on a stone plinth, poker, coal scuttle | Ruined Tower: lookout top | Floor, 1.4×0.8×1.1 m; alone | Abandoned, cold | Cold coal (not lit) |
| `rt_signal_mirror_stand` | Bronze signal mirror on a post with a crank | Ruined Tower: lookout top, by an opening | Floor, 0.8×0.5×1.9 m; alone | Watchful, old |  |
| `rt_watch_table_map` | Watch table with a map, stool knocked over | Ruined Tower: watch room | Floor, 1.3×1.7×0.9 m; alone; keep off paths | Left in a hurry |  |
| `rt_arrow_slit_shutter` | Cross-shaped slit window with a broken shutter | Ruined Tower: outer walls and stair walls | Flat on a wall, 0.9×0.5×1.5 m; several along the walls | Ruined | A crossbow bolt is stuck in it (id says arrow, but no arrows are used) |
| `rt_fallen_bell` | Big cracked bronze bell fallen on its side | Ruined Tower: ground floor under the bell spot | Floor, 1.8×1.6×0.7 m; alone; keep off paths | Ruined, grand |  |
| `rt_weapon_rack` | Wall rack: spears, poleaxe, round shield | Ruined Tower: guard room or armoury | Against a wall (stands on the floor), 1.3×0.2×1.9 m; alone | Left ready |  |
| `rt_water_cistern` | Stone cistern with a winch and bucket, lid on the floor | Ruined Tower: ground floor or store room | Floor, 2.4×2.1×1.1 m; alone; keep off paths (big) | Abandoned | Lid lies on the floor (not a separate part) |
| `rt_watch_hooks` | Hook board: horn, lantern, keys, hand bell, spyglass | Ruined Tower: watch room, by the door | Flat on a wall, 1.0×0.2×0.5 m; alone | Tidy, left behind | Horn is hollow |
| `rt_watch_roster_slab` | Stone slab with a carved watch roster and candle bracket | Ruined Tower: watch room | Flat on a wall, 1.0×0.2×1.1 m; alone | Old, orderly | Carved in |
| `rt_arrow_crate_spill` | Bolt crate knocked over, bolts spilled | Ruined Tower: armoury or store, near the stairs | Floor, 1.6×1.0×0.5 m; alone | Spilled, looted | Lootable: 10 bolt_stone. Twin rt_arrow_crate_spill_empty (bolts gone). Crate lid on the floor |
| `rt_map_tube_rack` | Pigeon-hole cabinet full of map tubes and rolls | Ruined Tower: watch room or map room | Against a wall, 1.0×0.3×0.8 m; alone | Orderly | Heavy file (1.2 MB) |

## Fallen Outpost (decor_nov21_ru.py, prefix ro_)

The wooden frontier camp and training yard ruin: shack bark and planks, rope, iron. Crossbow bolts only, no bows.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `ro_stake_bundle` | Roped bundle of sharp stakes, maul, hatchet in a stump | Fallen Outpost: yard by the palisade | Outside on the ground, 2.6×1.7×0.7 m; alone; keep off paths | Unfinished work |  |
| `ro_gate_wing_broken` | Fallen palisade gate wing, stakes snapped | Fallen Outpost: the gate | Outside on the ground, 2.1×1.8×0.5 m; beside the gate, not in the way through | Broken in |  |
| `ro_supply_cart` | Handcart slumped on its axle, keg, broken wheel, crate | Fallen Outpost: yard or the road in | Outside on the ground, 2.2×3.3×1.0 m; alone; keep off paths (big) | Abandoned | Heavy file (1.2 MB) |
| `ro_camp_cookery` | Fire ring, tripod pot, spit, stump with bowls, log seat | Fallen Outpost: camp kitchen spot | Outside on the ground, 2.3×1.5×1.3 m; alone | Abandoned, cold | Cold coals (not lit) |
| `ro_duty_board` | Roofed notice board with torn notices and duty tally | Fallen Outpost: yard, by the gate or huts | Against a wall (stands on the floor), 1.5×0.4×2.1 m; alone | Orderly, left behind |  |
| `ro_armour_bench` | Armour repair bench: helmet half patched, tools | Fallen Outpost: work corner | Floor, against a wall, 1.5×0.5×1.2 m; alone | Half-done work |  |
| `ro_archery_bale` | Straw target bale with crossbow bolts stuck in | Fallen Outpost: training yard | Outside on the ground, 1.2×1.1×1.3 m; alone or a row; keep the shooting lane clear | Training | Crossbow bolts (id says archery, no bows) |
| `ro_flag_pole` | Flagpole with braces, guy ropes and a torn standard | Fallen Outpost: middle of the yard | Outside on the ground, 2.1×2.1×3.2 m (3.2 m tall); alone; keep off paths (ropes spread wide) | Proud, faded |  |
| `ro_ladder_platform` | Lookout platform on four posts with a ladder | Fallen Outpost: palisade corner or yard edge | Outside on the ground, 1.3×1.7×2.1 m; alone; keep off paths | Watchful, worn |  |
| `ro_quiver_rack` | Plank wall rack: crossbow, bolt case, spare string | Fallen Outpost: guard hut or armoury | Flat on a wall, 1.3×0.2×1.3 m; alone | Left ready | Lootable: 1 crossbow_stone + 5 bolt_stone. Twin ro_quiver_rack_empty (crossbow and bolts gone). Heavy file (1.1 MB) |
| `ro_gate_bar_brackets` | Palisade wall with gate-bar brackets, knocker, peep hatch | Fallen Outpost: inside face of the gate | Against a wall / as a wall section, 1.8×0.5×1.9 m; alone | Shut tight |  |
| `ro_palisade_section` | Short palisade, one stake snapped | Fallen Outpost: edges, filling gaps in the fence | Outside on the ground, as a wall, 1.9×0.6×1.7 m; in a row | Worn |  |

## Brewhall (decor_nov21_rx.py, prefix rb_)

A dwarf brewery and drinking hall ruin the player can rebuild: clay brick (Hearthbrick style), one warm wood, copper, iron.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `rb_mash_tun` | Big staved mash tun on a brick plinth, rake, copper tap | Brewhall: brew room | Floor, 1.6×1.6×1.6 m; alone; keep off paths | Idle |  |
| `rb_brew_kettle` | Copper kettle on a cold brick hearth, swing crane, firewood | Brewhall: brew room | Floor, against a wall, 1.8×1.1×1.9 m; alone | Idle, cold | Hearth is cold (not lit) |
| `rb_fermenting_vats` | Three tall vats on a timber stand | Brewhall: brew room or cellar | Floor, against a wall, 2.6×0.9×1.4 m; alone | Idle |  |
| `rb_vat_burst` | Burst vat, staves splayed, hoops and lid on the floor | Brewhall: brew room (story spot) | Floor, 2.9×3.1×1.1 m; alone; keep off paths (very big) | Wrecked |  |
| `rb_drying_rack` | Drying rack with trays of mushroom slices and hops | Brewhall: store or drying room | Against a wall, 1.6×0.7×1.8 m; alone | Tidy | Holds food (the rack's point). Heavy file (1.9 MB) |
| `rb_grain_quern` | Two millstones on a brick stand with a flour bin | Brewhall: mill corner | Floor, 0.9×1.4×1.0 m; alone | Idle |  |
| `rb_cask_bay` | Brick arch bay with casks on a cradle | Brewhall: cellar | Against a wall, 2.1×0.9×2.1 m; several side by side | Stocked | Heavy file (1.2 MB) |
| `rb_cooper_bench` | Shaving horse with a stave, barrel being built | Brewhall: cooper's corner | Floor, 2.7×1.4×0.9 m; alone; keep off paths | Unfinished work |  |
| `rb_horn_wall` | Plank board of drinking horns, one fallen | Brewhall: drinking hall | Against a wall (stands on a foot), 1.5×0.3×1.7 m; alone | Lively, proud | Horns are hollow |
| `rb_feast_table_broken` | Long feast table snapped in the middle, bench tipped | Brewhall: drinking hall (story spot) | Floor, 2.8×1.7×0.9 m; alone; keep off paths (very big) | Wrecked, after the party |  |
| `rb_recipe_board` | Clay recipe tablet in a brick pier, copper measures | Brewhall: brew room, by the kettle | Against a wall, 1.4×0.4×1.7 m; alone | Orderly, proud | Pictures and runes carved in |
| `rb_cask_rolled` | Cask rolled off its cradle, stave burst | Brewhall: cellar (story spot) | Floor, 2.1×1.4×0.5 m; alone | Wrecked |  |

## Lantern Spire (decor_nov21_rx.py, prefix rs_)

A tall cut-stone beacon tower ruin the player can rebuild: greystone (Stonehold style), worn brass, iron, glass, dark wood.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `rs_oil_jar_stand` | Stone stand with three lamp-oil jars, dipper, funnel | Lantern Spire: oil store or lamp room | Floor, against a wall, 1.4×0.7×1.0 m; alone | Orderly | Middle jar is open and hollow |
| `rs_lens_workbench` | Keeper's wick and lens bench with polishing stand | Lantern Spire: keeper's workshop | Floor, against a wall, 1.6×0.7×1.1 m; alone | Busy, left behind |  |
| `rs_great_lens_cradle` | The great lens in a brass yoke on a carved plinth | Lantern Spire: lamp room at the top | Floor, middle of the room, 1.2×1.1×1.6 m; alone; keep off paths | Grand |  |
| `rs_reflector_plates` | Stone panel with three brass reflector dishes | Lantern Spire: lamp room walls | Against a wall, 1.6×0.4×1.6 m; alone or a few | Grand, polished |  |
| `rs_signal_shutters` | Stone frame with shut wooden signal shutters | Lantern Spire: lamp room openings | Against a wall, 1.5×0.3×1.8 m; one per opening | Dark, shut | Lamp out (dark behind) |
| `rs_keeper_log_desk` | Standing log desk with open log book, sand-glass, quill | Lantern Spire: keeper's room | Floor, 0.9×0.6×1.3 m; alone | Orderly |  |
| `rs_oil_hoist` | Stone pilaster with an iron jib, pulley and oil jar | Lantern Spire: stair shaft or oil store wall | Against a wall, 0.6×1.1×2.1 m (sticks out 1.1 m); alone | Workmanlike |  |
| `rs_chimney_rack` | Stone cubbies of lamp chimneys and lens rings | Lantern Spire: lamp store | Against a wall, 1.3×0.5×1.5 m; alone | Orderly |  |
| `rs_wick_board` | Stone wick board: bobbins, shears, cut wicks | Lantern Spire: keeper's workshop | Against a wall, 1.4×0.3×1.5 m; alone | Orderly |  |
| `rs_lantern_cage_fallen` | Great lantern's iron cage fallen on its side, glass shards | Lantern Spire: lamp room or the floor below (story spot) | Floor, 2.8×1.9×0.8 m; alone; keep off paths (big) | Ruined |  |
| `rs_lens_shattered` | Great lens fallen and broken, ring bent, yoke tipped | Lantern Spire: lamp room (story spot) | Floor, 2.0×1.6×0.2 m; alone | Ruined | Low and flat |
| `rs_keeper_last_watch` | Stone ledge with burnt-out lamp, stool and log fallen | Lantern Spire: keeper's room or lookout ledge (story spot) | Floor, against a wall, 2.0×1.1×1.1 m; alone | Sad, eerie | Lamp burnt out (not lit) |

## The player's home (decor_nov21_hm.py, prefix hm_)

Things the player builds for their own home: one wood family, at most one stone, copper/iron fittings. Wall pieces stand on a floor post or their own legs.

| id | What it is | Where it goes | How it's placed | Vibe | Notes |
|---|---|---|---|---|---|
| `hm_spider_trophy` | Real cave spider's head on a wooden panel | Home trophy wall | Flat on a wall, 0.5×0.4×0.6 m; group with other trophies | Proud |  |
| `hm_beetle_shell_trophy` | Real rock beetle's head on a wooden panel | Home trophy wall | Flat on a wall, 0.6×0.3×0.6 m; group | Proud | Heavy file (1.9 MB) |
| `hm_snail_shell_trophy` | Real rock snail's head on a wooden panel | Home trophy wall | Flat on a wall, 0.6×0.3×0.7 m; group | Proud |  |
| `hm_pickaxe_progression` | Board of four pickaxes: stone, copper, iron, master iron | Home trophy wall, workshop | Against a wall (stands on the floor), 1.6×0.2×1.5 m; alone | Proud |  |
| `hm_crossed_hammers` | Carved stone medallion with two crossed war hammers | Home trophy wall, great room | Against a wall on a floor post, 0.7×0.2×1.7 m; group | Proud |  |
| `hm_shield_spears` | Round shield over two crossed spears | Home trophy wall, entrance hall | Against a wall on a floor post, 1.0×0.3×1.9 m; group | Proud |  |
| `hm_lamp_history_board` | Board of three old lamps: clay, iron, copper | Home hall, study | Against a wall (stands on the floor), 1.1×0.4×1.8 m; alone | Proud, cosy |  |
| `hm_bat_skull_plaque` | Real cave bat's head on a wooden panel | Home trophy wall | Flat on a wall, 0.5×0.2×0.6 m; group | Proud |  |
| `hm_heirloom_axe` | Family axe on two hooks above a carved rune stone | Home great room, above the hearth (guess) | Against a wall on a floor post, 0.9×0.2×1.6 m; alone | Proud, grand | Runes carved in |
| `hm_vein_slice_frame` | Framed polished stone slice with metal veins | Home study, trophy wall | Against a wall on a floor post, 0.6×0.2×1.6 m; group | Wondrous |  |
| `hm_potion_rack` | Three-tier rack of corked potion flasks | Home study, alchemy corner (guess) | Against a wall, 0.9×0.2×1.0 m; alone | Tidy | Heavy file (1.0 MB) |
| `hm_scroll_lattice` | Diamond lattice rack with a scroll in every cell | Home study, library | Against a wall, 1.0×0.3×1.0 m; alone | Tidy, learned | Heavy file (1.1 MB) |
| `hm_preserve_shelf` | Pantry shelf of crocks, jars, pots and a jug | Home kitchen or pantry | Against a wall, 1.0×0.4×1.3 m; alone | Cosy, tidy |  |
| `hm_tankard_shelf` | Two-tier shelf of tankards, horns, goblets, cups | Home tavern corner, kitchen | Against a wall, 1.0×0.3×1.6 m; alone | Cosy, lively |  |
| `hm_ingot_display` | Stepped stand with neat ingot stacks and rank plates | Home trophy room, workshop | Floor or on a sideboard, 1.0×0.5×0.5 m; alone | Proud, rich |  |
| `hm_gem_jar_shelf` | Wall shelf of gem jars and a small gem balance | Home trophy room, study | Against a wall, 0.9×0.3×1.6 m; alone | Proud, tidy |  |
| `hm_herb_ladder` | A-frame drying ladder with dried stalk bundles | Home kitchen, store room | Floor, 0.9×0.7×1.5 m; alone | Cosy |  |
| `hm_book_nook` | Arched stone wall niche with shelves of books | Home study, library | Against a wall, 0.8×0.3×1.6 m; alone | Cosy, learned | Heavy file (1.2 MB) |
| `hm_carved_high_chair` | High-backed carved armchair | Home great room, head of the table | Floor, 0.6×0.5×1.5 m; alone | Grand |  |
| `hm_delve_game_table` | Square game table: carved board, stone mountain, miner pieces | Home living room, tavern corner | Floor, 0.8×0.8×0.7 m; alone | Cosy, fun | Heavy file (1.2 MB) |
| `hm_map_table` | Trestle table with a cave map, weights, dividers, candle | Home study | Floor, 1.2×0.7×0.9 m; alone | Adventurous |  |
| `hm_trophy_pedestal` | Stone pedestal with a rock beetle's jaws | Home trophy room, centre spot | Floor, 0.5×0.5×1.3 m; alone | Proud |  |
| `hm_banded_sideboard` | Long sideboard: drawers, carved doors, copper bands | Home dining room, kitchen | Floor, against a wall, 1.4×0.5×0.9 m; alone | Tidy, grand |  |


Models from these files that could not be placed in a set: none.
