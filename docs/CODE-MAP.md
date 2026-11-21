# Code map (made by tools/codemap/make_codemap.py — do not edit by hand)

Never read this whole file: Grep it for a word (e.g. `Grep "loot" docs/CODE-MAP.md`), then read
only ~60 lines of the file around the line number it gives. Line numbers are from the last chat start.

## src/art/ambience.gd (255 lines) — The cave's mood: light, fog, colours, and the stuff floating in the air.
- src/art/ambience.gd:1 Ambience
- src/art/ambience.gd:33 _ready
- src/art/ambience.gd:90 _process
- src/art/ambience.gd:125 _in_big_cavern
- src/art/ambience.gd:142 _look_around
- src/art/ambience.gd:162 set_dev_bright
- src/art/ambience.gd:169 _apply
- src/art/ambience.gd:187 _make_motes
- src/art/ambience.gd:247 _warm_up

## src/art/boulders.gd (323 lines) — Breakable boulders (owner, Nov 18: "rocks like in Conan Exiles that you can break to get some stone, multiple 
- src/art/boulders.gd:1 Boulders
- src/art/boulders.gd:19 _models
- src/art/boulders.gd:35 build
- src/art/boulders.gd:45 _finish
- src/art/boulders.gd:62 _exit_tree
- src/art/boulders.gd:69 cached_plan
- src/art/boulders.gd:75 plan
- src/art/boulders.gd:107 _try
- src/art/boulders.gd:179 near_wall
- src/art/boulders.gd:189 _make
- src/art/boulders.gd:221 _on_rock_changed
- src/art/boulders.gd:236 _settle
- src/art/boulders.gd:269 id_of
- src/art/boulders.gd:276 middle
- src/art/boulders.gd:280 rock
- src/art/boulders.gd:285 set_broken
- src/art/boulders.gd:306 _process

## src/art/cave_critters.gd (237 lines) — Tiny harmless cave life (owner, Nov 18, F190): glowing beetles crawling over the walls, little moths flutterin
- src/art/cave_critters.gd:1 CaveCritters
- src/art/cave_critters.gd:24 setup
- src/art/cave_critters.gd:51 _model
- src/art/cave_critters.gd:60 _process
- src/art/cave_critters.gd:77 _beetle
- src/art/cave_critters.gd:115 _on_rock_changed
- src/art/cave_critters.gd:129 _moth
- src/art/cave_critters.gd:162 _moth_anchor
- src/art/cave_critters.gd:173 _cricket
- src/art/cave_critters.gd:208 _nearest_feet
- src/art/cave_critters.gd:224 _ray_from
- src/art/cave_critters.gd:232 _normal

## src/art/cave_life.gd (837 lines) — Life on the cave floors and walls, only for looks (owner's cave-life plan, batch 1, F188): small roots poking 
- src/art/cave_life.gd:1 CaveLife
- src/art/cave_life.gd:70 build
- src/art/cave_life.gd:86 is_built
- src/art/cave_life.gd:90 _make_all
- src/art/cave_life.gd:115 breakable_at
- src/art/cave_life.gd:137 position_of
- src/art/cave_life.gd:145 remove_plant
- src/art/cave_life.gd:160 kind_of
- src/art/cave_life.gd:166 restore_plant
- src/art/cave_life.gd:179 home_of
- src/art/cave_life.gd:186 _exit_tree
- src/art/cave_life.gd:193 nearest
- src/art/cave_life.gd:208 count
- src/art/cave_life.gd:218 cached_plan
- src/art/cave_life.gd:224 plan
- src/art/cave_life.gd:361 in_cave
- src/art/cave_life.gd:376 _parallel
- src/art/cave_life.gd:395 _plan_everywhere
- src/art/cave_life.gd:448 _feel_floors
- src/art/cave_life.gd:472 _fuzz
- src/art/cave_life.gd:479 _source
- src/art/cave_life.gd:495 _clearance
- src/art/cave_life.gd:503 _pick
- src/art/cave_life.gd:515 _tint
- src/art/cave_life.gd:536 _upright
- src/art/cave_life.gd:544 Rock
- src/art/cave_life.gd:604 _ledge
- src/art/cave_life.gd:621 _key
- src/art/cave_life.gd:625 _take
- src/art/cave_life.gd:632 _free
- src/art/cave_life.gd:643 _cell
- src/art/cave_life.gd:647 _make_set
- src/art/cave_life.gd:684 mesh_of
- src/art/cave_life.gd:715 _shell_mesh
- src/art/cave_life.gd:754 _bend_part
- src/art/cave_life.gd:761 _material
- src/art/cave_life.gd:794 _process
- src/art/cave_life.gd:819 _on_rock_changed

## src/art/cave_water.gd (426 lines) — Water in the caves (owner, Nov 18, F190: "water: puddles, small streams, a low mist in the deepest spots").
- src/art/cave_water.gd:1 CaveWater
- src/art/cave_water.gd:20 _enter_tree
- src/art/cave_water.gd:24 _exit_tree
- src/art/cave_water.gd:30 water_near
- src/art/cave_water.gd:38 build
- src/art/cave_water.gd:90 plan_falls
- src/art/cave_water.gd:168 _fall_clear
- src/art/cave_water.gd:190 _make_fall
- src/art/cave_water.gd:213 _add_trickle
- src/art/cave_water.gd:236 _smoothed
- src/art/cave_water.gd:247 _fit_fall
- src/art/cave_water.gd:270 _on_rock_changed
- src/art/cave_water.gd:279 _make_pool
- src/art/cave_water.gd:295 _shape_fall
- src/art/cave_water.gd:324 _make_splash
- src/art/cave_water.gd:358 plan_puddles
- src/art/cave_water.gd:400 _flat
- src/art/cave_water.gd:410 plan_mist

## src/art/chest_open.gd (101 lines) — Opening a chest (owner F345, Nov 18: no long wobble/spring/burst show; the lid swings open on its hinge and
- src/art/chest_open.gd:1 ChestOpen
- src/art/chest_open.gd:13 open
- src/art/chest_open.gd:28 close
- src/art/chest_open.gd:48 _slide
- src/art/chest_open.gd:68 lid_of
- src/art/chest_open.gd:74 _fresh_tween
- src/art/chest_open.gd:84 _pop
- src/art/chest_open.gd:97 _look_of

## src/art/clutter.gd (704 lines) — Small loose things on cave floors, only for looks: pebbles, chunky rocks,
- src/art/clutter.gd:1 Clutter
- src/art/clutter.gd:74 build
- src/art/clutter.gd:86 is_built
- src/art/clutter.gd:90 _exit_tree
- src/art/clutter.gd:97 _cached_plan
- src/art/clutter.gd:110 _plan
- src/art/clutter.gd:165 _finish
- src/art/clutter.gd:187 _ceiling
- src/art/clutter.gd:228 _try
- src/art/clutter.gd:253 _pick
- src/art/clutter.gd:269 _make_set
- src/art/clutter.gd:316 _near_drips
- src/art/clutter.gd:337 _place_hanging_roots
- src/art/clutter.gd:373 _place_shelves
- src/art/clutter.gd:428 _make_model_cells
- src/art/clutter.gd:464 hroot_near_ray
- src/art/clutter.gd:484 hroot_top
- src/art/clutter.gd:495 hide_hroot
- src/art/clutter.gd:505 _hroot_mm
- src/art/clutter.gd:518 _make_drip_set
- src/art/clutter.gd:553 _model_mesh
- src/art/clutter.gd:600 _mesh
- src/art/clutter.gd:652 _stalactite_mesh
- src/art/clutter.gd:684 _on_rock_changed

## src/art/dig_cracks.gd (119 lines) — Cracks spreading on the rock you're digging (owner, Nov 17, F261: "the rock cracks in stages, then crumbles").
- src/art/dig_cracks.gd:1 DigCracks
- src/art/dig_cracks.gd:20 hit
- src/art/dig_cracks.gd:42 clear
- src/art/dig_cracks.gd:48 _init
- src/art/dig_cracks.gd:56 _process
- src/art/dig_cracks.gd:67 _make_textures
- src/art/dig_cracks.gd:92 _grow
- src/art/dig_cracks.gd:106 _line

## src/art/fire.gd (147 lines) — A real-looking little fire made of particles: soft flame tongues, sparks (embers) drifting up,
- src/art/fire.gd:1 Fire
- src/art/fire.gd:13 _init
- src/art/fire.gd:18 _ready
- src/art/fire.gd:25 _flames
- src/art/fire.gd:44 _embers
- src/art/fire.gd:64 _smoke
- src/art/fire.gd:84 _emitter
- src/art/fire.gd:97 _quad
- src/art/fire.gd:113 _soft_tex
- src/art/fire.gd:130 _curve
- src/art/fire.gd:139 _ramp

## src/art/glow_groves.gd (378 lines) — Glow groves (owner, Nov 19, 2026: "the trees glow ... sometimes the main source of light in some caves"; decis
- src/art/glow_groves.gd:1 GlowGroves
- src/art/glow_groves.gd:47 build
- src/art/glow_groves.gd:63 plan
- src/art/glow_groves.gd:112 wood_for
- src/art/glow_groves.gd:118 _plant
- src/art/glow_groves.gd:161 _dress
- src/art/glow_groves.gd:210 _clear
- src/art/glow_groves.gd:230 near
- src/art/glow_groves.gd:237 _add_tree
- src/art/glow_groves.gd:270 id_of
- src/art/glow_groves.gd:277 tree
- src/art/glow_groves.gd:282 set_used
- src/art/glow_groves.gd:293 set_regrow
- src/art/glow_groves.gd:298 _show
- src/art/glow_groves.gd:307 _add_dressing
- src/art/glow_groves.gd:339 _settle_dressing
- src/art/glow_groves.gd:350 _tinted
- src/art/glow_groves.gd:361 _add_lights

## src/art/glow_swarms.gd (367 lines) — Glowing swarms (owner, Nov 18: "a pack, circular, 100-150 of them, moving like a pack... the first part is wid
- src/art/glow_swarms.gd:1 GlowSwarms
- src/art/glow_swarms.gd:21 build
- src/art/glow_swarms.gd:45 _make
- src/art/glow_swarms.gd:86 _finish
- src/art/glow_swarms.gd:98 _ring_step
- src/art/glow_swarms.gd:114 _finish_some
- src/art/glow_swarms.gd:135 _finish_end
- src/art/glow_swarms.gd:148 _head_at
- src/art/glow_swarms.gd:165 _round_trunks
- src/art/glow_swarms.gd:178 _process
- src/art/glow_swarms.gd:300 _above_floor
- src/art/glow_swarms.gd:327 _keep_out
- src/art/glow_swarms.gd:352 _floor_under
- src/art/glow_swarms.gd:363 _place

## src/art/ground_snap.gd (170 lines) — Puts floor things down on the REAL rock (owner, Nov 18: boulders, mushroom grass, bones, rocks and moss "float
- src/art/ground_snap.gd:1 GroundSnap
- src/art/ground_snap.gd:19 _enter_tree
- src/art/ground_snap.gd:23 _exit_tree
- src/art/ground_snap.gd:30 take
- src/art/ground_snap.gd:38 add_batch
- src/art/ground_snap.gd:51 when_built
- src/art/ground_snap.gd:56 _physics_process
- src/art/ground_snap.gd:100 _near_player
- src/art/ground_snap.gd:108 _built
- src/art/ground_snap.gd:114 _settle
- src/art/ground_snap.gd:153 floor_at

## src/art/look.gd (116 lines) — One place that decides how things look. Every prop, station, building piece, monster and
- src/art/look.gd:1 Look
- src/art/look.gd:20 mat
- src/art/look.gd:59 guess
- src/art/look.gd:75 forged
- src/art/look.gd:91 start_preloading
- src/art/look.gd:102 finish_preloading
- src/art/look.gd:107 _collect
- src/art/look.gd:112 _load

## src/art/mushroom_grass.gd (271 lines) — Mushroom grass in the first cave (owner, Nov 18: "a small mushroom grass just in the first cave on most of the
- src/art/mushroom_grass.gd:1 MushroomGrass
- src/art/mushroom_grass.gd:29 build
- src/art/mushroom_grass.gd:66 is_built
- src/art/mushroom_grass.gd:70 _exit_tree
- src/art/mushroom_grass.gd:76 plan
- src/art/mushroom_grass.gd:147 _finish
- src/art/mushroom_grass.gd:172 _draw
- src/art/mushroom_grass.gd:226 colour_at
- src/art/mushroom_grass.gd:235 _on_rock_changed
- src/art/mushroom_grass.gd:258 clear_ground
- src/art/mushroom_grass.gd:266 count

## src/art/pick_glint.gd (82 lines) — The star that twinkles on an enemy's pick a moment before its blow lands (owner, Nov 20: "I don't see them
- src/art/pick_glint.gd:1 PickGlint
- src/art/pick_glint.gd:19 on
- src/art/pick_glint.gd:29 _ready
- src/art/pick_glint.gd:49 _process
- src/art/pick_glint.gd:62 _follow
- src/art/pick_glint.gd:67 _star

## src/art/rock_shatter.gd (270 lines) — The rock you just broke bursts into real chunks (owner, Nov 17, F261: "break in a lot of different pieces, lik
- src/art/rock_shatter.gd:1 RockShatter
- src/art/rock_shatter.gd:26 burst
- src/art/rock_shatter.gd:81 _material
- src/art/rock_shatter.gd:105 _sized_shape
- src/art/rock_shatter.gd:117 _heavy
- src/art/rock_shatter.gd:127 warm_up
- src/art/rock_shatter.gd:134 _physics_process
- src/art/rock_shatter.gd:151 _release
- src/art/rock_shatter.gd:160 _take
- src/art/rock_shatter.gd:183 _make_shapes
- src/art/rock_shatter.gd:224 _icosphere
- src/art/rock_shatter.gd:251 _hull_mesh

## src/art/root_curtains.gd (366 lines) — Root curtains (owner, Nov 17, F189): across some tunnel mouths, a curtain of thin roots hangs from the ceiling
- src/art/root_curtains.gd:1 RootCurtains
- src/art/root_curtains.gd:29 build
- src/art/root_curtains.gd:43 is_built
- src/art/root_curtains.gd:47 _exit_tree
- src/art/root_curtains.gd:52 _finish
- src/art/root_curtains.gd:99 cached_plan
- src/art/root_curtains.gd:103 plan
- src/art/root_curtains.gd:159 _plan_tunnels
- src/art/root_curtains.gd:172 _plan_under_bridges
- src/art/root_curtains.gd:197 _curtain_across
- src/art/root_curtains.gd:215 _add_strand
- src/art/root_curtains.gd:224 _big_room_at
- src/art/root_curtains.gd:237 _strand_mesh
- src/art/root_curtains.gd:248 _tube
- src/art/root_curtains.gd:274 _process
- src/art/root_curtains.gd:289 strand_near_ray
- src/art/root_curtains.gd:313 bunch_of
- src/art/root_curtains.gd:327 top_of
- src/art/root_curtains.gd:334 hide_strands
- src/art/root_curtains.gd:349 _on_rock_changed

## src/art/root_pillars.gd (281 lines) — Root Trees (owner, Nov 18: "this is a perfect way to get trees... enormous roots"; plan: docs/design/root-tree
- src/art/root_pillars.gd:1 RootPillars
- src/art/root_pillars.gd:29 build
- src/art/root_pillars.gd:36 plan
- src/art/root_pillars.gd:79 _clear
- src/art/root_pillars.gd:96 _add_tree
- src/art/root_pillars.gd:113 _show
- src/art/root_pillars.gd:158 _add_skin
- src/art/root_pillars.gd:175 trunks
- src/art/root_pillars.gd:185 set_used
- src/art/root_pillars.gd:205 add_planted
- src/art/root_pillars.gd:215 regrow_stage
- src/art/root_pillars.gd:226 set_regrow
- src/art/root_pillars.gd:234 stage_of
- src/art/root_pillars.gd:243 set_growth
- src/art/root_pillars.gd:248 _process
- src/art/root_pillars.gd:265 id_of
- src/art/root_pillars.gd:271 pillar
- src/art/root_pillars.gd:276 near

## src/art/ruin_treasure.gd (101 lines) — Treasure and lost things in old places (owner, Nov 19, 2026; batch 4 in docs/research/asset-picks-placement.md
- src/art/ruin_treasure.gd:1 RuinTreasure
- src/art/ruin_treasure.gd:18 plan
- src/art/ruin_treasure.gd:46 rng_for
- src/art/ruin_treasure.gd:53 chest_spot
- src/art/ruin_treasure.gd:65 keep_clear
- src/art/ruin_treasure.gd:78 dress
- src/art/ruin_treasure.gd:94 _settle

## src/art/tool_models.gd (176 lines) — The things a dwarf holds: pickaxes, axes, swords, maces, spears, hammers, shields,
- src/art/tool_models.gd:1 ToolModels
- src/art/tool_models.gd:17 build
- src/art/tool_models.gd:118 _head_surface
- src/art/tool_models.gd:122 _handle
- src/art/tool_models.gd:127 _grip
- src/art/tool_models.gd:131 _add
- src/art/tool_models.gd:141 _cyl
- src/art/tool_models.gd:151 _cone
- src/art/tool_models.gd:155 _box
- src/art/tool_models.gd:161 _sphere
- src/art/tool_models.gd:170 _torus

## src/art/weapon_trail.gd (106 lines) — A swoosh behind a swinging weapon or tool (only looks). Round 2 (owner, Nov 18: "juicy sword swipes", the 5 st
- src/art/weapon_trail.gd:1 WeaponTrail
- src/art/weapon_trail.gd:27 follow
- src/art/weapon_trail.gd:44 _tool_length
- src/art/weapon_trail.gd:54 _ready
- src/art/weapon_trail.gd:61 _process
- src/art/weapon_trail.gd:93 _curve

## src/build/blueprint.gd (215 lines) — A saved building (world doc section 7). Saved as JSON text so friends can share them.
- src/build/blueprint.gd:1 Blueprint
- src/build/blueprint.gd:23 capture
- src/build/blueprint.gd:51 cost
- src/build/blueprint.gd:63 world_pieces
- src/build/blueprint.gd:72 carve_cells
- src/build/blueprint.gd:91 ground_cells
- src/build/blueprint.gd:105 to_json
- src/build/blueprint.gd:118 from_json
- src/build/blueprint.gd:177 _fail
- src/build/blueprint.gd:182 _rle
- src/build/blueprint.gd:197 _unrle
- src/build/blueprint.gd:210 _checksum

## src/build/blueprint_library.gd (1435 lines) — The ready-made blueprints that come with the game (building polish spec §7). Built here in
- src/build/blueprint_library.gd:1 BlueprintLibrary
- src/build/blueprint_library.gd:43 list
- src/build/blueprint_library.gd:50 make
- src/build/blueprint_library.gd:102 _delvers_hut
- src/build/blueprint_library.gd:181 _homestead
- src/build/blueprint_library.gd:231 _stone_hall
- src/build/blueprint_library.gd:276 _forge
- src/build/blueprint_library.gd:310 _watchtower
- src/build/blueprint_library.gd:375 _dir
- src/build/blueprint_library.gd:380 _rot
- src/build/blueprint_library.gd:385 _ring_layer
- src/build/blueprint_library.gd:397 _ring_edges
- src/build/blueprint_library.gd:406 _ring_pillars
- src/build/blueprint_library.gd:417 _ring_stairs
- src/build/blueprint_library.gd:424 _ring_rails
- src/build/blueprint_library.gd:431 _stone_watchtower
- src/build/blueprint_library.gd:467 _lantern_spire
- src/build/blueprint_library.gd:521 _stone_outpost
- src/build/blueprint_library.gd:673 _outpost_part
- src/build/blueprint_library.gd:686 _outpost_line_up
- src/build/blueprint_library.gd:706 _round_tower
- src/build/blueprint_library.gd:728 _sq_tower
- src/build/blueprint_library.gd:783 _hall
- src/build/blueprint_library.gd:837 _brewhall
- src/build/blueprint_library.gd:947 _brew_chimney_level
- src/build/blueprint_library.gd:956 _brewhall_chimney_stays_brick
- src/build/blueprint_library.gd:984 _old_kiln
- src/build/blueprint_library.gd:1082 _kiln_stays_brick
- src/build/blueprint_library.gd:1116 _twin_gate
- src/build/blueprint_library.gd:1130 _tp
- src/build/blueprint_library.gd:1135 _twin_tower
- src/build/blueprint_library.gd:1181 _twin_wall
- src/build/blueprint_library.gd:1200 _twin_ring_stage
- src/build/blueprint_library.gd:1234 _twin_gatehouse
- src/build/blueprint_library.gd:1275 _twin_yard
- src/build/blueprint_library.gd:1286 _twin_barracks
- src/build/blueprint_library.gd:1385 _start
- src/build/blueprint_library.gd:1395 _to_wood
- src/build/blueprint_library.gd:1404 _add
- src/build/blueprint_library.gd:1409 _floors
- src/build/blueprint_library.gd:1416 _wall_x
- src/build/blueprint_library.gd:1421 _wall_z
- src/build/blueprint_library.gd:1427 _on_wall_z
- src/build/blueprint_library.gd:1433 _on_wall_x

## src/build/build_mode.gd (380 lines) — Build mode: active while the Build Hammer is in your hand.
- src/build/build_mode.gd:1 BuildMode
- src/build/build_mode.gd:29 _ready
- src/build/build_mode.gd:38 active
- src/build/build_mode.gd:48 choose
- src/build/build_mode.gd:64 start_blueprint
- src/build/build_mode.gd:96 stop_blueprint
- src/build/build_mode.gd:110 _update_tints
- src/build/build_mode.gd:140 _update_work
- src/build/build_mode.gd:163 turn
- src/build/build_mode.gd:169 _step
- src/build/build_mode.gd:175 held_steps
- src/build/build_mode.gd:180 _keep_turning
- src/build/build_mode.gd:200 _show_fill
- src/build/build_mode.gd:227 level_text
- src/build/build_mode.gd:236 _process
- src/build/build_mode.gd:299 _unhandled_input
- src/build/build_mode.gd:365 _save_blueprint

## src/build/builder.gd (1399 lines) — Builder: everything that's been built, and every cave-in. A helper of the GameAuthority,
- src/build/builder.gd:1 Builder
- src/build/builder.gd:46 _ready
- src/build/builder.gd:55 ask_place
- src/build/builder.gd:63 ask_remove
- src/build/builder.gd:73 ask_door
- src/build/builder.gd:81 _rpc_door
- src/build/builder.gd:87 _rpc_place
- src/build/builder.gd:93 _rpc_remove
- src/build/builder.gd:102 _ev_message
- src/build/builder.gd:110 problem
- src/build/builder.gd:152 _level_ground
- src/build/builder.gd:171 request_place
- src/build/builder.gd:199 pickup_seconds_left
- src/build/builder.gd:208 request_remove
- src/build/builder.gd:235 request_door
- src/build/builder.gd:255 ladder_at
- src/build/builder.gd:268 chest_spot
- src/build/builder.gd:288 station_problem
- src/build/builder.gd:312 _ev_add_piece
- src/build/builder.gd:338 end_batch
- src/build/builder.gd:345 _ev_remove_piece
- src/build/builder.gd:362 _ev_door
- src/build/builder.gd:372 _ev_warn
- src/build/builder.gd:378 _ev_cave_in
- src/build/builder.gd:384 _apply_pending_falls
- src/build/builder.gd:401 queue_check
- src/build/builder.gd:409 reanchor_near
- src/build/builder.gd:422 _process
- src/build/builder.gd:452 _run_check
- src/build/builder.gd:472 support_points
- src/build/builder.gd:485 _after_fall
- src/build/builder.gd:501 _queue_shaky
- src/build/builder.gd:514 _ev_shake
- src/build/builder.gd:525 _ev_collapse
- src/build/builder.gd:534 _add_rubble
- src/build/builder.gd:544 _ev_add_rubble
- src/build/builder.gd:549 _landing_for
- src/build/builder.gd:563 ask_hit_rubble
- src/build/builder.gd:571 _rpc_hit_rubble
- src/build/builder.gd:577 request_hit_rubble
- src/build/builder.gd:598 _ev_rubble_hit
- src/build/builder.gd:605 _ev_remove_rubble
- src/build/builder.gd:615 _rubble
- src/build/builder.gd:654 rock_mesh
- src/build/builder.gd:683 _bounds
- src/build/builder.gd:691 site_status
- src/build/builder.gd:698 ask_dev_fill
- src/build/builder.gd:706 _rpc_dev_fill
- src/build/builder.gd:713 request_dev_fill
- src/build/builder.gd:735 ask_place_blueprint
- src/build/builder.gd:743 _rpc_place_blueprint
- src/build/builder.gd:750 request_place_blueprint
- src/build/builder.gd:777 _ev_site
- src/build/builder.gd:818 _ev_site_piece
- src/build/builder.gd:827 _ev_site_status
- src/build/builder.gd:833 _ev_site_done
- src/build/builder.gd:841 work_site_for
- src/build/builder.gd:856 site_progress
- src/build/builder.gd:868 _someone_building
- src/build/builder.gd:877 _tick_sites
- src/build/builder.gd:896 _carve_step
- src/build/builder.gd:933 _fill_step
- src/build/builder.gd:960 site_steps
- src/build/builder.gd:980 missing_for
- src/build/builder.gd:995 _list_text
- src/build/builder.gd:1002 _build_step
- src/build/builder.gd:1082 _identical_exists
- src/build/builder.gd:1112 _ruin_reach
- src/build/builder.gd:1117 ruin_keeps_worn
- src/build/builder.gd:1123 ruin_intro
- src/build/builder.gd:1133 ruin_hard
- src/build/builder.gd:1138 ruin_choices
- src/build/builder.gd:1151 ruin_needs
- src/build/builder.gd:1170 ruin_picture
- src/build/builder.gd:1190 _ruin_broken_at
- src/build/builder.gd:1199 ruin_chest_changed
- src/build/builder.gd:1233 _ruin_slot_whole
- src/build/builder.gd:1246 _ruin_same_here
- src/build/builder.gd:1260 _worn_to_go
- src/build/builder.gd:1278 _ruin_step
- src/build/builder.gd:1319 _finish_ruin
- src/build/builder.gd:1349 _set_status
- src/build/builder.gd:1356 snapshot
- src/build/builder.gd:1372 load_snapshot
- src/build/builder.gd:1391 _spill_furniture

## src/build/cave_ins.gd (150 lines) — Decides which rock falls after a dig (world doc section 6). Works on a copy of the voxels
- src/build/cave_ins.gd:1 CaveIns
- src/build/cave_ins.gd:23 box_for
- src/build/cave_ins.gd:32 find_falls
- src/build/cave_ins.gd:92 _fill
- src/build/cave_ins.gd:124 _rock_count_5x5
- src/build/cave_ins.gd:134 _rock
- src/build/cave_ins.gd:138 _inside
- src/build/cave_ins.gd:142 _idx
- src/build/cave_ins.gd:146 _to_world

## src/build/piece_mesh.gd (868 lines) — The shapes of building pieces (building polish spec §6). Each (piece, material) shape is built
- src/build/piece_mesh.gd:1 PieceMesh
- src/build/piece_mesh.gd:20 style_of
- src/build/piece_mesh.gd:32 visual
- src/build/piece_mesh.gd:40 solid
- src/build/piece_mesh.gd:46 _make
- src/build/piece_mesh.gd:97 _plain_piece
- src/build/piece_mesh.gd:132 _wall_with_hole
- src/build/piece_mesh.gd:152 _steps
- src/build/piece_mesh.gd:161 _ramp
- src/build/piece_mesh.gd:174 _roof
- src/build/piece_mesh.gd:182 _ridge
- src/build/piece_mesh.gd:191 _roof_outer
- src/build/piece_mesh.gd:207 _roof_inner
- src/build/piece_mesh.gd:225 _gable
- src/build/piece_mesh.gd:237 _arch
- src/build/piece_mesh.gd:249 _arch_doorway
- src/build/piece_mesh.gd:253 _round_hole
- src/build/piece_mesh.gd:273 _round_top
- src/build/piece_mesh.gd:291 _column
- src/build/piece_mesh.gd:305 _column_part
- src/build/piece_mesh.gd:323 _table
- src/build/piece_mesh.gd:335 _chair
- src/build/piece_mesh.gd:348 _shelf
- src/build/piece_mesh.gd:360 _barrel
- src/build/piece_mesh.gd:370 _crate
- src/build/piece_mesh.gd:385 _banner
- src/build/piece_mesh.gd:393 _plaque
- src/build/piece_mesh.gd:398 _wall_shield
- src/build/piece_mesh.gd:409 _wall_sconce
- src/build/piece_mesh.gd:415 _weapon_rack
- src/build/piece_mesh.gd:428 _brace
- src/build/piece_mesh.gd:435 _ladder
- src/build/piece_mesh.gd:443 _railing
- src/build/piece_mesh.gd:451 _flat_roof
- src/build/piece_mesh.gd:457 _battlement
- src/build/piece_mesh.gd:465 _battlement_corner
- src/build/piece_mesh.gd:472 _tri
- src/build/piece_mesh.gd:488 _circle_half
- src/build/piece_mesh.gd:497 _circle_hole
- src/build/piece_mesh.gd:515 _circle_door
- src/build/piece_mesh.gd:530 _door
- src/build/piece_mesh.gd:546 _triangle
- src/build/piece_mesh.gd:556 _diagonal
- src/build/piece_mesh.gd:573 _slab
- src/build/piece_mesh.gd:591 _wood
- src/build/piece_mesh.gd:620 _blocks
- src/build/piece_mesh.gd:659 _plates
- src/build/piece_mesh.gd:686 _axis
- src/build/piece_mesh.gd:691 _shingles
- src/build/piece_mesh.gd:712 _push
- src/build/piece_mesh.gd:717 _pop
- src/build/piece_mesh.gd:721 _box
- src/build/piece_mesh.gd:735 _prism_x
- src/build/piece_mesh.gd:745 _prism_z
- src/build/piece_mesh.gd:755 _prism_y
- src/build/piece_mesh.gd:764 _prism_sides
- src/build/piece_mesh.gd:779 _cyl
- src/build/piece_mesh.gd:791 _face
- src/build/piece_mesh.gd:816 islands
- src/build/piece_mesh.gd:864 _root

## src/build/piece_node.gd (411 lines) — One built piece in the world: its look and its solid shape.
- src/build/piece_node.gd:1 PieceNode
- src/build/piece_node.gd:16 _ready
- src/build/piece_node.gd:39 set_shaking
- src/build/piece_node.gd:46 _process
- src/build/piece_node.gd:56 set_tint
- src/build/piece_node.gd:80 set_open
- src/build/piece_node.gd:92 _apply_swing
- src/build/piece_node.gd:102 set_ghost_ok
- src/build/piece_node.gd:108 set_ghost_plan
- src/build/piece_node.gd:120 set_legs
- src/build/piece_node.gd:174 _part_mesh
- src/build/piece_node.gd:187 rebuild
- src/build/piece_node.gd:207 forged_mesh
- src/build/piece_node.gd:240 floating_parts
- src/build/piece_node.gd:251 model_misfit
- src/build/piece_node.gd:267 _build
- src/build/piece_node.gd:299 _decor_extras
- src/build/piece_node.gd:340 _cloth
- src/build/piece_node.gd:352 _box
- src/build/piece_node.gd:372 _ramp_shape
- src/build/piece_node.gd:391 _mat

## src/build/pieces.gd (1015 lines) — The building catalog (world doc section 5 + the building polish spec, Nov 14 2026).
- src/build/pieces.gd:1 Pieces
- src/build/pieces.gd:465 station_for
- src/build/pieces.gd:479 needed_level
- src/build/pieces.gd:501 cost
- src/build/pieces.gd:527 allowed
- src/build/pieces.gd:537 hp
- src/build/pieces.gd:550 steps_of
- src/build/pieces.gd:555 rot_from_steps
- src/build/pieces.gd:560 yaw_of
- src/build/pieces.gd:564 valid_rot
- src/build/pieces.gd:568 add_rot
- src/build/pieces.gd:576 is_tri
- src/build/pieces.gd:581 on_square_grid
- src/build/pieces.gd:586 turned_size
- src/build/pieces.gd:592 outline
- src/build/pieces.gd:605 footprint
- src/build/pieces.gd:614 box
- src/build/pieces.gd:628 edges
- src/build/pieces.gd:648 outlines_overlap
- src/build/pieces.gd:671 _yaw_toward
- src/build/pieces.gd:675 _steps_for
- src/build/pieces.gd:689 snap
- src/build/pieces.gd:747 _snap_to_edges
- src/build/pieces.gd:800 _snap_tri_free
- src/build/pieces.gd:818 _on_grid
- src/build/pieces.gd:840 check_points
- src/build/pieces.gd:871 rock_problem
- src/build/pieces.gd:884 _where_rock
- src/build/pieces.gd:903 levels_ground
- src/build/pieces.gd:909 level_plan
- src/build/pieces.gd:935 ground_height
- src/build/pieces.gd:946 levelled_sdf
- src/build/pieces.gd:975 leg_spots
- src/build/pieces.gd:980 leg_drops
- src/build/pieces.gd:997 touches_rock

## src/build/rubble.gd (56 lines) — A building piece that fell down (owner, Nov 15, F90): it tumbles to where the host says it lands,
- src/build/rubble.gd:1 Rubble
- src/build/rubble.gd:17 setup
- src/build/rubble.gd:44 landing

## src/build/structure.gd (230 lines) — Everything that's been built, and how steady each piece is (world doc 5.6).
- src/build/structure.gd:1 Structure
- src/build/structure.gd:19 add
- src/build/structure.gd:33 _cells_of
- src/build/structure.gd:44 _unindex
- src/build/structure.gd:51 is_foundation
- src/build/structure.gd:56 strength_color
- src/build/structure.gd:66 remove
- src/build/structure.gd:74 box_of
- src/build/structure.gd:82 overlaps
- src/build/structure.gd:100 _overlap_outline
- src/build/structure.gd:116 overlapping
- src/build/structure.gd:133 _y_range
- src/build/structure.gd:140 _touching
- src/build/structure.gd:149 fits_inside
- src/build/structure.gd:154 _shrunk
- src/build/structure.gd:159 neighbors
- src/build/structure.gd:176 preview_stability
- src/build/structure.gd:190 recompute
- src/build/structure.gd:217 _loss
- src/build/structure.gd:225 to_data

## src/combat/combat.gd (199 lines) — Fighting rules (docs/design/combat-and-monsters.md sections 1-3).
- src/combat/combat.gd:1 Combat
- src/combat/combat.gd:14 crit_chance
- src/combat/combat.gd:87 combo_hits
- src/combat/combat.gd:93 has_heavy
- src/combat/combat.gd:98 is_finisher
- src/combat/combat.gd:105 effect
- src/combat/combat.gd:113 damage
- src/combat/combat.gd:131 situation
- src/combat/combat.gd:145 shot_damage
- src/combat/combat.gd:161 range_falloff
- src/combat/combat.gd:165 stun_value
- src/combat/combat.gd:175 defend
- src/combat/combat.gd:189 weapon_of

## src/combat/creature_rig.gd (275 lines) — Creatures that move by a skeleton (the KayKit miners of Lampwick Drift and Old Pell's Diggings, Nov 20).
- src/combat/creature_rig.gd:1 CreatureRig
- src/combat/creature_rig.gd:42 find
- src/combat/creature_rig.gd:72 lie
- src/combat/creature_rig.gd:78 rise
- src/combat/creature_rig.gd:88 rise_time
- src/combat/creature_rig.gd:93 attack
- src/combat/creature_rig.gd:123 glint_wait
- src/combat/creature_rig.gd:132 tool_tips
- src/combat/creature_rig.gd:174 lead_tip
- src/combat/creature_rig.gd:185 _glint_later
- src/combat/creature_rig.gd:211 _swing_trail
- src/combat/creature_rig.gd:231 hit
- src/combat/creature_rig.gd:242 die
- src/combat/creature_rig.gd:252 step

## src/combat/dwarf_fight.gd (465 lines) — The dwarf's fighting controls (combat doc 1.5), used while a weapon or shield is in hand:
- src/combat/dwarf_fight.gd:1 DwarfFight
- src/combat/dwarf_fight.gd:41 item
- src/combat/dwarf_fight.gd:47 weapon_mode
- src/combat/dwarf_fight.gd:51 weapon
- src/combat/dwarf_fight.gd:55 tier
- src/combat/dwarf_fight.gd:62 has_shield
- src/combat/dwarf_fight.gd:78 shield_item
- src/combat/dwarf_fight.gd:94 off_hand_free
- src/combat/dwarf_fight.gd:99 shield_blocked_by_lantern
- src/combat/dwarf_fight.gd:113 shield_tier
- src/combat/dwarf_fight.gd:123 is_crossbow
- src/combat/dwarf_fight.gd:127 aiming
- src/combat/dwarf_fight.gd:132 block_action
- src/combat/dwarf_fight.gd:136 is_blocking
- src/combat/dwarf_fight.gd:141 dodging
- src/combat/dwarf_fight.gd:145 invulnerable
- src/combat/dwarf_fight.gd:150 defense_state
- src/combat/dwarf_fight.gd:157 take_stun
- src/combat/dwarf_fight.gd:164 guard_break
- src/combat/dwarf_fight.gd:172 knock_down
- src/combat/dwarf_fight.gd:185 got_parry
- src/combat/dwarf_fight.gd:193 step
- src/combat/dwarf_fight.gd:244 has_heavy
- src/combat/dwarf_fight.gd:248 weapon_has_heavy
- src/combat/dwarf_fight.gd:254 _shield_bash
- src/combat/dwarf_fight.gd:270 dodge_velocity
- src/combat/dwarf_fight.gd:274 _attack
- src/combat/dwarf_fight.gd:307 _impact
- src/combat/dwarf_fight.gd:372 _crossbow_step
- src/combat/dwarf_fight.gd:394 start_reload
- src/combat/dwarf_fight.gd:413 bolt
- src/combat/dwarf_fight.gd:422 _shoot
- src/combat/dwarf_fight.gd:463 _ps

## src/combat/gems.gd (225 lines) — Gems (owner's plan, Nov 20: docs/design/gems.md). Socketed at a Gem Bench into weapons, shields, tools
- src/combat/gems.gd:1 Gems
- src/combat/gems.gd:76 item_id
- src/combat/gems.gd:81 base_of
- src/combat/gems.gd:87 level_of
- src/combat/gems.gd:91 with_level
- src/combat/gems.gd:96 gem_of
- src/combat/gems.gd:104 full_name
- src/combat/gems.gd:112 slot_kind
- src/combat/gems.gd:125 socket_count
- src/combat/gems.gd:135 can_socket
- src/combat/gems.gd:142 effect
- src/combat/gems.gd:151 bonus
- src/combat/gems.gd:167 armor_bonus
- src/combat/gems.gd:179 describe
- src/combat/gems.gd:192 dungeon_key
- src/combat/gems.gd:200 dungeon_gems
- src/combat/gems.gd:205 end_chest_gem
- src/combat/gems.gd:213 roll
- src/combat/gems.gd:219 shield_slot

## src/combat/monster.gd (1579 lines) — One monster. On the host it thinks (states from combat doc 5.1); on other computers it
- src/combat/monster.gd:1 Monster
- src/combat/monster.gd:96 setup
- src/combat/monster.gd:109 _ready
- src/combat/monster.gd:166 show_shell
- src/combat/monster.gd:174 show_rise
- src/combat/monster.gd:184 _awake_looks
- src/combat/monster.gd:189 _voice
- src/combat/monster.gd:194 hit_flash
- src/combat/monster.gd:233 die_visual
- src/combat/monster.gd:269 max_hp
- src/combat/monster.gd:274 stats
- src/combat/monster.gd:279 attack_options
- src/combat/monster.gd:283 is_alive
- src/combat/monster.gd:288 damage_mult
- src/combat/monster.gd:303 knock
- src/combat/monster.gd:311 _red_outline
- src/combat/monster.gd:327 _clear_outline
- src/combat/monster.gd:334 hit_stop
- src/combat/monster.gd:338 think
- src/combat/monster.gd:595 _perceive
- src/combat/monster.gd:614 _start_rise
- src/combat/monster.gd:624 alert
- src/combat/monster.gd:646 _try_blink
- src/combat/monster.gd:661 _circle_and_dive
- src/combat/monster.gd:676 _new_circle
- src/combat/monster.gd:685 _clear_line
- src/combat/monster.gd:693 _start_dive
- src/combat/monster.gd:705 _dive_step
- src/combat/monster.gd:716 _pick_attack
- src/combat/monster.gd:724 _start_attack
- src/combat/monster.gd:738 _drop_ahead
- src/combat/monster.gd:755 add_buildup
- src/combat/monster.gd:760 chases_out
- src/combat/monster.gd:768 may_step
- src/combat/monster.gd:777 _move
- src/combat/monster.gd:857 climbs
- src/combat/monster.gd:861 clinging
- src/combat/monster.gd:866 may_cling
- src/combat/monster.gd:875 up_on
- src/combat/monster.gd:885 apply_surface
- src/combat/monster.gd:892 cling_to
- src/combat/monster.gd:901 let_go
- src/combat/monster.gd:915 knocked_off
- src/combat/monster.gd:920 _tell_surface
- src/combat/monster.gd:926 _set_surface
- src/combat/monster.gd:932 _feel
- src/combat/monster.gd:941 _try_cling
- src/combat/monster.gd:958 _cling_think
- src/combat/monster.gd:999 _crawl
- src/combat/monster.gd:1058 _step_onto_floor
- src/combat/monster.gd:1065 _landed
- src/combat/monster.gd:1088 mgr_target_near
- src/combat/monster.gd:1094 _face_along
- src/combat/monster.gd:1104 high_spot
- src/combat/monster.gd:1133 high_spot_clear
- src/combat/monster.gd:1148 _rock_above
- src/combat/monster.gd:1155 _body_height
- src/combat/monster.gd:1159 _face
- src/combat/monster.gd:1184 weave
- src/combat/monster.gd:1188 _turn_toward
- src/combat/monster.gd:1206 set_net
- src/combat/monster.gd:1211 puppet_step
- src/combat/monster.gd:1219 show_tell
- src/combat/monster.gd:1265 _spit_fx
- src/combat/monster.gd:1297 _land_sound
- src/combat/monster.gd:1305 _hang_body
- src/combat/monster.gd:1315 _process
- src/combat/monster.gd:1367 show_cling
- src/combat/monster.gd:1381 _lie_on_back
- src/combat/monster.gd:1402 _creature_fx
- src/combat/monster.gd:1438 set_hp
- src/combat/monster.gd:1450 _update_label
- src/combat/monster.gd:1462 charge_line
- src/combat/monster.gd:1472 daze_after_charge
- src/combat/monster.gd:1482 charge_rear
- src/combat/monster.gd:1490 daze_sway
- src/combat/monster.gd:1495 _draw_trail
- src/combat/monster.gd:1537 _daze_stars
- src/combat/monster.gd:1553 _bar
- src/combat/monster.gd:1575 _set_bar

## src/combat/monster_manager.gd (1571 lines) — All monsters (Authority/Monsters on every computer).
- src/combat/monster_manager.gd:1 MonsterManager
- src/combat/monster_manager.gd:46 _ready
- src/combat/monster_manager.gd:53 player_node
- src/combat/monster_manager.gd:58 get_monster
- src/combat/monster_manager.gd:62 uid_of
- src/combat/monster_manager.gd:70 _physics_process
- src/combat/monster_manager.gd:86 _host_step
- src/combat/monster_manager.gd:118 _update_boosts
- src/combat/monster_manager.gd:128 _spawn_and_despawn
- src/combat/monster_manager.gd:168 _group_step
- src/combat/monster_manager.gd:187 _dungeon_groups
- src/combat/monster_manager.gd:215 _spawn_dungeon_group
- src/combat/monster_manager.gd:247 roost_variant
- src/combat/monster_manager.gd:255 _spawn_roost
- src/combat/monster_manager.gd:283 _spawn_pack
- src/combat/monster_manager.gd:348 knock_off_near
- src/combat/monster_manager.gd:356 _built_near
- src/combat/monster_manager.gd:370 monster_cling
- src/combat/monster_manager.gd:375 _ev_cling
- src/combat/monster_manager.gd:381 _nearest_player_dist
- src/combat/monster_manager.gd:389 ignores
- src/combat/monster_manager.gd:394 nearest_noticer
- src/combat/monster_manager.gd:439 in_cave
- src/combat/monster_manager.gd:449 inside_room
- src/combat/monster_manager.gd:455 _can_see
- src/combat/monster_manager.gd:460 alert_pack
- src/combat/monster_manager.gd:467 send_tell
- src/combat/monster_manager.gd:486 is_charge
- src/combat/monster_manager.gd:490 _heaviest
- src/combat/monster_manager.gd:497 monster_changed
- src/combat/monster_manager.gd:505 ask_attack
- src/combat/monster_manager.gd:513 _rpc_attack
- src/combat/monster_manager.gd:525 request_attack
- src/combat/monster_manager.gd:600 _shield_slot
- src/combat/monster_manager.gd:613 _perk_buff
- src/combat/monster_manager.gd:627 _pierced
- src/combat/monster_manager.gd:637 whirlwind
- src/combat/monster_manager.gd:650 _gem_buildup
- src/combat/monster_manager.gd:658 _hurt_monster
- src/combat/monster_manager.gd:704 ask_hit_friend
- src/combat/monster_manager.gd:712 _rpc_hit_friend
- src/combat/monster_manager.gd:717 request_hit_friend
- src/combat/monster_manager.gd:750 ask_shoot
- src/combat/monster_manager.gd:758 _rpc_shoot
- src/combat/monster_manager.gd:765 request_shoot
- src/combat/monster_manager.gd:817 _ev_shot
- src/combat/monster_manager.gd:840 _ev_glow_bolt
- src/combat/monster_manager.gd:851 max_targets_for
- src/combat/monster_manager.gd:857 _kill
- src/combat/monster_manager.gd:908 _ev_tell
- src/combat/monster_manager.gd:928 spawn_cloud
- src/combat/monster_manager.gd:933 _ev_cloud
- src/combat/monster_manager.gd:984 _clouds_step
- src/combat/monster_manager.gd:1016 _has_mask
- src/combat/monster_manager.gd:1025 _judge_incoming
- src/combat/monster_manager.gd:1104 ask_hit_back
- src/combat/monster_manager.gd:1112 _rpc_hit_back
- src/combat/monster_manager.gd:1117 request_hit_back
- src/combat/monster_manager.gd:1133 ask_blocked
- src/combat/monster_manager.gd:1141 _rpc_blocked
- src/combat/monster_manager.gd:1146 request_blocked
- src/combat/monster_manager.gd:1164 standing_over
- src/combat/monster_manager.gd:1180 may_dive
- src/combat/monster_manager.gd:1188 note
- src/combat/monster_manager.gd:1195 charge_smash
- src/combat/monster_manager.gd:1231 smash_statues_in_reach
- src/combat/monster_manager.gd:1248 smash_statue
- src/combat/monster_manager.gd:1263 charge_shove
- src/combat/monster_manager.gd:1274 _in_reach
- src/combat/monster_manager.gd:1286 ask_parried
- src/combat/monster_manager.gd:1294 _rpc_parried
- src/combat/monster_manager.gd:1302 request_parried
- src/combat/monster_manager.gd:1324 _ev_spawn
- src/combat/monster_manager.gd:1341 _ev_remove
- src/combat/monster_manager.gd:1365 add_statue
- src/combat/monster_manager.gd:1377 ask_hit_statue
- src/combat/monster_manager.gd:1385 _rpc_hit_statue
- src/combat/monster_manager.gd:1391 request_hit_statue
- src/combat/monster_manager.gd:1419 _statues_step
- src/combat/monster_manager.gd:1428 _ev_statue_hit
- src/combat/monster_manager.gd:1433 _ev_statue_gone
- src/combat/monster_manager.gd:1438 _ev_hp
- src/combat/monster_manager.gd:1445 monster_shell
- src/combat/monster_manager.gd:1455 _ev_shell
- src/combat/monster_manager.gd:1467 monster_rise
- src/combat/monster_manager.gd:1472 _ev_rise
- src/combat/monster_manager.gd:1480 _ev_note
- src/combat/monster_manager.gd:1487 _ev_hit
- src/combat/monster_manager.gd:1517 _ev_poses
- src/combat/monster_manager.gd:1532 _float_number
- src/combat/monster_manager.gd:1560 snapshot
- src/combat/monster_manager.gd:1567 load_snapshot

## src/combat/monster_model.gd (860 lines) — Placeholder monster looks made of simple shapes (until the art pack).
- src/combat/monster_model.gd:1 MonsterModel
- src/combat/monster_model.gd:23 look_of
- src/combat/monster_model.gd:27 build
- src/combat/monster_model.gd:154 _bat_wing
- src/combat/monster_model.gd:174 set_shell
- src/combat/monster_model.gd:199 _forged_shell
- src/combat/monster_model.gd:223 variant_count
- src/combat/monster_model.gd:237 _vary_stone
- src/combat/monster_model.gd:257 _tag_forged
- src/combat/monster_model.gd:357 _tag_parts
- src/combat/monster_model.gd:380 _unbox
- src/combat/monster_model.gd:400 animate
- src/combat/monster_model.gd:505 _snail
- src/combat/monster_model.gd:599 _blinks
- src/combat/monster_model.gd:616 dazed_sway
- src/combat/monster_model.gd:637 _shell_parts
- src/combat/monster_model.gd:658 add_daze_stars
- src/combat/monster_model.gd:684 spin_daze_stars
- src/combat/monster_model.gd:695 _head_spot
- src/combat/monster_model.gd:725 _in_model
- src/combat/monster_model.gd:736 _star_mesh
- src/combat/monster_model.gd:773 add_crystals
- src/combat/monster_model.gd:789 set_glow
- src/combat/monster_model.gd:804 set_angry
- src/combat/monster_model.gd:815 _add
- src/combat/monster_model.gd:826 _mat
- src/combat/monster_model.gd:830 _sphere
- src/combat/monster_model.gd:839 _capsule
- src/combat/monster_model.gd:848 _cyl
- src/combat/monster_model.gd:857 _box

## src/combat/monsters.gd (216 lines) — Monster data for Mossy Hollows and the Fungal Jungle (combat doc 5.2, 5.3, 6, 7).
- src/combat/monsters.gd:1 Monsters
- src/combat/monsters.gd:114 info
- src/combat/monsters.gd:162 roll_variant
- src/combat/monsters.gd:175 target_stats
- src/combat/monsters.gd:183 max_hp
- src/combat/monsters.gd:189 rank
- src/combat/monsters.gd:201 party
- src/combat/monsters.gd:207 food_guard

## src/combat/ragdoll.gd (458 lines) — When a creature dies it goes limp (owner, Nov 18; the Rock Beetle first, data.ragdoll): it keeps the speed it 
- src/combat/ragdoll.gd:1 Ragdoll
- src/combat/ragdoll.gd:27 make
- src/combat/ragdoll.gd:168 _close_eyes
- src/combat/ragdoll.gd:187 _dead_pose
- src/combat/ragdoll.gd:221 _settle
- src/combat/ragdoll.gd:271 _sample_points
- src/combat/ragdoll.gd:286 _in_solid
- src/combat/ragdoll.gd:301 _drape_when_still
- src/combat/ragdoll.gd:315 _later
- src/combat/ragdoll.gd:320 lies_still
- src/combat/ragdoll.gd:324 _redrape_when_still
- src/combat/ragdoll.gd:336 _drape
- src/combat/ragdoll.gd:397 _shin
- src/combat/ragdoll.gd:406 _knee_pose
- src/combat/ragdoll.gd:431 _shape_all
- src/combat/ragdoll.gd:450 _shape

## src/combat/statue.gd (228 lines) — A dead creature turns to stone (owner, Nov 18): it falls and lies still (Ragdoll), then dark cracks run out fr
- src/combat/statue.gd:1 Statue
- src/combat/statue.gd:16 id_of
- src/combat/statue.gd:25 claim
- src/combat/statue.gd:31 _meshes
- src/combat/statue.gd:40 _bounds
- src/combat/statue.gd:56 petrify
- src/combat/statue.gd:101 _freeze_when_still
- src/combat/statue.gd:112 hit
- src/combat/statue.gd:121 where
- src/combat/statue.gd:127 remove
- src/combat/statue.gd:156 _free
- src/combat/statue.gd:165 from_rig
- src/combat/statue.gd:197 bone_box
- src/combat/statue.gd:209 from_model

## src/combat/stun_meter.gd (61 lines) — A monster's stun meter (doc 2.5). Parries and heavy hits fill it. Full = dazed.
- src/combat/stun_meter.gd:1 StunMeter
- src/combat/stun_meter.gd:16 _init
- src/combat/stun_meter.gd:21 is_stunned
- src/combat/stun_meter.gd:26 add
- src/combat/stun_meter.gd:40 take_crush
- src/combat/stun_meter.gd:47 tick
- src/combat/stun_meter.gd:60 fraction

## src/debug/aimcheck.gd (61 lines) — Aim camera check (F452): photos while aiming the crossbow, zoomed right in and at the normal zoom, plus one no
- src/debug/aimcheck.gd:10 _ready
- src/debug/aimcheck.gd:19 _wait
- src/debug/aimcheck.gd:23 _shot
- src/debug/aimcheck.gd:28 _run

## src/debug/artpreview.gd (656 lines) — Art pack lineup: today's placeholder dwarf next to free CC0 character candidates, in the
- src/debug/artpreview.gd:19 _ready
- src/debug/artpreview.gd:28 _wait
- src/debug/artpreview.gd:32 _run
- src/debug/artpreview.gd:150 _fit
- src/debug/artpreview.gd:167 _creatures
- src/debug/artpreview.gd:245 _live
- src/debug/artpreview.gd:284 _boulders
- src/debug/artpreview.gd:320 _chunkbench
- src/debug/artpreview.gd:337 _procbench
- src/debug/artpreview.gd:362 _avg_process
- src/debug/artpreview.gd:373 _digbench
- src/debug/artpreview.gd:461 _treestages
- src/debug/artpreview.gd:519 _perfbench
- src/debug/artpreview.gd:574 _frame_cost
- src/debug/artpreview.gd:592 _vinetest
- src/debug/artpreview.gd:629 _falls

## src/debug/autopilot.gd (441 lines) — Autopilot: plays a short scripted run by itself, takes screenshots, prints a report
- src/debug/autopilot.gd:12 _ready
- src/debug/autopilot.gd:26 _process
- src/debug/autopilot.gd:34 _wait
- src/debug/autopilot.gd:38 _shot
- src/debug/autopilot.gd:45 _run
- src/debug/autopilot.gd:290 _visit_jungle
- src/debug/autopilot.gd:407 _to_hotbar
- src/debug/autopilot.gd:419 _teleport
- src/debug/autopilot.gd:437 _hut_pos

## src/debug/buildcheck.gd (431 lines) — Build check: puts every building piece in each Mossy material in rows, and each ready-made
- src/debug/buildcheck.gd:11 _ready
- src/debug/buildcheck.gd:20 _wait
- src/debug/buildcheck.gd:24 _shot
- src/debug/buildcheck.gd:29 _place
- src/debug/buildcheck.gd:35 _clear
- src/debug/buildcheck.gd:42 _look
- src/debug/buildcheck.gd:51 _run
- src/debug/buildcheck.gd:150 _extras
- src/debug/buildcheck.gd:186 _edges
- src/debug/buildcheck.gd:224 _snap_place
- src/debug/buildcheck.gd:240 _edge_toward
- src/debug/buildcheck.gd:250 _top_near
- src/debug/buildcheck.gd:257 _side_of
- src/debug/buildcheck.gd:262 _house

## src/debug/cavecheck.gd (192 lines) — Cave check (owner's cave-floor notes, Nov 19: F404-F407, F350): starts a fresh world and photographs the Rebui
- src/debug/cavecheck.gd:11 _ready
- src/debug/cavecheck.gd:20 _wait
- src/debug/cavecheck.gd:24 _shot
- src/debug/cavecheck.gd:29 _run
- src/debug/cavecheck.gd:165 _floor
- src/debug/cavecheck.gd:170 _open_spot_near
- src/debug/cavecheck.gd:181 _teleport

## src/debug/claude_test.gd (106 lines) — Marks games that Claude starts for testing (owner, Nov 19), so the owner can tell them apart
- src/debug/claude_test.gd:1 ClaudeTest
- src/debug/claude_test.gd:25 active
- src/debug/claude_test.gd:41 what
- src/debug/claude_test.gd:47 world_name
- src/debug/claude_test.gd:55 clean_old_worlds
- src/debug/claude_test.gd:70 _ready

## src/debug/climbcheck.gd (98 lines) — Robot (Nov 20, creature climbing F474/F475): a Cave Spider and a Rock Snail on the ceiling near the start, a R
- src/debug/climbcheck.gd:11 _physics_process
- src/debug/climbcheck.gd:17 _ready
- src/debug/climbcheck.gd:25 _shot
- src/debug/climbcheck.gd:31 _ray
- src/debug/climbcheck.gd:36 _run

## src/debug/dungeon_test_start.gd (302 lines) — "Test the dungeon" (owner, Nov 19): the dev-only start menu button makes a new world, then this puts the dwarf
- src/debug/dungeon_test_start.gd:19 _ready
- src/debug/dungeon_test_start.gd:24 _run
- src/debug/dungeon_test_start.gd:144 _pell_walks
- src/debug/dungeon_test_start.gd:228 _walk_rails
- src/debug/dungeon_test_start.gd:261 _walk_drips

## src/debug/dungeoncheck.gd (85 lines) — Dungeon check: starts a fresh world, takes the dwarf to the first dungeon (Mossgate Hold) and photographs the 
- src/debug/dungeoncheck.gd:11 _ready
- src/debug/dungeoncheck.gd:20 _wait
- src/debug/dungeoncheck.gd:24 _run
- src/debug/dungeoncheck.gd:72 _teleport

## src/debug/dwarf_studio.gd (640 lines) — Photo studio for the dwarf: bright even light, front + side cameras, a few poses
- src/debug/dwarf_studio.gd:12 _init
- src/debug/dwarf_studio.gd:47 _wait
- src/debug/dwarf_studio.gd:51 _view
- src/debug/dwarf_studio.gd:56 _shot
- src/debug/dwarf_studio.gd:62 _both
- src/debug/dwarf_studio.gd:69 _run
- src/debug/dwarf_studio.gd:208 _running_test
- src/debug/dwarf_studio.gd:237 _tool_strikes
- src/debug/dwarf_studio.gd:288 _grip_check
- src/debug/dwarf_studio.gd:311 _far_end
- src/debug/dwarf_studio.gd:324 _sword_test
- src/debug/dwarf_studio.gd:343 _rot_lineup
- src/debug/dwarf_studio.gd:367 _fire_test
- src/debug/dwarf_studio.gd:395 _anim_sheet
- src/debug/dwarf_studio.gd:420 _props_test
- src/debug/dwarf_studio.gd:445 _monster_lineup
- src/debug/dwarf_studio.gd:463 _armor_lineup
- src/debug/dwarf_studio.gd:480 _three_lineup
- src/debug/dwarf_studio.gd:522 _creature
- src/debug/dwarf_studio.gd:533 _aim
- src/debug/dwarf_studio.gd:538 _creature_shoot
- src/debug/dwarf_studio.gd:617 _variety_shoot

## src/debug/freeze_watch.gd (141 lines) — Writes slowdowns and freezes into the game's log, so a play session's log says what happened (owner, Nov 17:
- src/debug/freeze_watch.gd:1 FreezeWatch
- src/debug/freeze_watch.gd:35 open_player_file
- src/debug/freeze_watch.gd:40 _say
- src/debug/freeze_watch.gd:55 _ready
- src/debug/freeze_watch.gd:62 _exit_tree
- src/debug/freeze_watch.gd:69 time_part
- src/debug/freeze_watch.gd:78 _process
- src/debug/freeze_watch.gd:102 _low_check
- src/debug/freeze_watch.gd:128 _watch
- src/debug/freeze_watch.gd:140 _clock

## src/debug/gemcheck.gd (175 lines) — Gem check (Mac gem rebuild, Nov 20; docs/design/gems.md): in a real game, combine 3 Rough gems at a Gem Bench,
- src/debug/gemcheck.gd:13 _ready
- src/debug/gemcheck.gd:22 _wait
- src/debug/gemcheck.gd:26 _shot
- src/debug/gemcheck.gd:31 _say
- src/debug/gemcheck.gd:35 _run
- src/debug/gemcheck.gd:50 _ahead
- src/debug/gemcheck.gd:59 _gem_bench
- src/debug/gemcheck.gd:90 _snail
- src/debug/gemcheck.gd:101 _attack
- src/debug/gemcheck.gd:116 _snail_poison
- src/debug/gemcheck.gd:135 _fire_through_block

## src/debug/kitcheck.gd (194 lines) — Kit check (Claude 2, art): builds one small house in each Zone 1 building style with the hand-made
- src/debug/kitcheck.gd:12 _ready
- src/debug/kitcheck.gd:21 _wait
- src/debug/kitcheck.gd:25 _shot
- src/debug/kitcheck.gd:30 _place
- src/debug/kitcheck.gd:35 _look
- src/debug/kitcheck.gd:47 _house
- src/debug/kitcheck.gd:93 _run
- src/debug/kitcheck.gd:146 _stations
- src/debug/kitcheck.gd:175 _doors

## src/debug/lookdev.gd (518 lines) — Look test: visits a few fixed spots (Mossy spawn, a ruin, the great hall, the Fungal Jungle),
- src/debug/lookdev.gd:17 _ready
- src/debug/lookdev.gd:34 _process
- src/debug/lookdev.gd:39 _wait
- src/debug/lookdev.gd:43 _shot
- src/debug/lookdev.gd:48 _teleport
- src/debug/lookdev.gd:66 _portrait
- src/debug/lookdev.gd:82 _wall_shot
- src/debug/lookdev.gd:111 _plant_shots
- src/debug/lookdev.gd:150 _cover_shots
- src/debug/lookdev.gd:209 _clear_view
- src/debug/lookdev.gd:228 _kind_shots
- src/debug/lookdev.gd:395 _nearest_room
- src/debug/lookdev.gd:408 _lamp_shot
- src/debug/lookdev.gd:429 _run

## src/debug/menucheck.gd (90 lines) — Menu check (menu overhaul, owner F187): fills the bag with a few things, then photographs the bag +
- src/debug/menucheck.gd:10 _ready
- src/debug/menucheck.gd:19 _wait
- src/debug/menucheck.gd:23 _shot
- src/debug/menucheck.gd:28 _run
- src/debug/menucheck.gd:69 _put

## src/debug/minercheck.gd (148 lines) — Robot (Nov 20): the skeleton miners in the real game. In the dungeon test world, on the cave floor in front of
- src/debug/minercheck.gd:12 _physics_process
- src/debug/minercheck.gd:18 _ready
- src/debug/minercheck.gd:26 _shot
- src/debug/minercheck.gd:32 _run
- src/debug/minercheck.gd:141 _report

## src/debug/monster_export.gd (129 lines) — Saves the creatures as 3D files (.glb) so they can be looked at outside the game
- src/debug/monster_export.gd:34 _init
- src/debug/monster_export.gd:42 _run
- src/debug/monster_export.gd:88 _drop_hidden
- src/debug/monster_export.gd:95 _habitat
- src/debug/monster_export.gd:105 _plain_materials

## src/debug/nan_watch.gd (39 lines) — A lookout for "broken numbers" (Claude, Nov 19): the owner's log had ~1,300 "Vector3 cannot be normalized" war
- src/debug/nan_watch.gd:1 NanWatch
- src/debug/nan_watch.gd:16 _process

## src/debug/netcheck.gd (236 lines) — Co-op robot test. Start two copies of the game:
- src/debug/netcheck.gd:17 _ready
- src/debug/netcheck.gd:29 _wait
- src/debug/netcheck.gd:33 _run
- src/debug/netcheck.gd:42 _run_client
- src/debug/netcheck.gd:137 _run_host
- src/debug/netcheck.gd:225 _report
- src/debug/netcheck.gd:230 _ready_to_fight
- src/debug/netcheck.gd:235 _want_door

## src/debug/outpostcheck.gd (71 lines) — Outpost check: starts a fresh world, moves the dwarf to the Fallen Outpost's cavern (so its rock loads and the
- src/debug/outpostcheck.gd:10 _ready
- src/debug/outpostcheck.gd:19 _wait
- src/debug/outpostcheck.gd:23 _run
- src/debug/outpostcheck.gd:60 _teleport

## src/debug/perfcheck.gd (487 lines) — Speed check: turns off the frame cap (vsync), stands in the first big cavern and measures
- src/debug/perfcheck.gd:10 _ready
- src/debug/perfcheck.gd:19 _wait
- src/debug/perfcheck.gd:24 _measure
- src/debug/perfcheck.gd:42 _line
- src/debug/perfcheck.gd:47 _run
- src/debug/perfcheck.gd:162 _warmup
- src/debug/perfcheck.gd:203 _Stamp
- src/debug/perfcheck.gd:218 _hitch_start
- src/debug/perfcheck.gd:251 _hitch_loop
- src/debug/perfcheck.gd:274 _split_process
- src/debug/perfcheck.gd:312 _hitch_walk
- src/debug/perfcheck.gd:336 _spawn_cost
- src/debug/perfcheck.gd:393 _fight
- src/debug/perfcheck.gd:446 _hitches

## src/debug/ragdoll_room.gd (69 lines) — Test room for big hits (F237): a floor, a wall, a dwarf thrown from a different side every 3.5 s.
- src/debug/ragdoll_room.gd:10 _init
- src/debug/ragdoll_room.gd:18 _block
- src/debug/ragdoll_room.gd:36 _run
- src/debug/ragdoll_room.gd:68 _shot

## src/debug/ruincheck.gd (60 lines) — Ruin check: visits old dwarf stonework (ruins, column rows, the Great Hall) and takes a
- src/debug/ruincheck.gd:10 _ready
- src/debug/ruincheck.gd:19 _wait
- src/debug/ruincheck.gd:23 _run

## src/debug/savecheck.gd (49 lines) — Save robot test, in two runs:
- src/debug/savecheck.gd:10 _ready
- src/debug/savecheck.gd:18 _wait
- src/debug/savecheck.gd:22 _run

## src/debug/skillscheck.gd (55 lines) — Skills window check (owner's mock-up, Nov 19): a level-18 dwarf with a few perks and skills,
- src/debug/skillscheck.gd:10 _ready
- src/debug/skillscheck.gd:19 _wait
- src/debug/skillscheck.gd:23 _shot
- src/debug/skillscheck.gd:28 _run

## src/debug/spirecheck.gd (80 lines) — Spire check (F479): starts a fresh world, moves the dwarf to the Lantern Spire's cavern (so its rock loads and
- src/debug/spirecheck.gd:10 _ready
- src/debug/spirecheck.gd:19 _wait
- src/debug/spirecheck.gd:23 _run
- src/debug/spirecheck.gd:69 _teleport

## src/debug/startcheck.gd (154 lines) — Start check: plays the first minutes of a real new game by itself (feedback F10/F11) and
- src/debug/startcheck.gd:12 _ready
- src/debug/startcheck.gd:21 _wait
- src/debug/startcheck.gd:25 _shot
- src/debug/startcheck.gd:30 _say
- src/debug/startcheck.gd:34 _face
- src/debug/startcheck.gd:40 _run
- src/debug/startcheck.gd:149 _finish

## src/debug/steamshots.gd (130 lines) — Steam shots: store-page pictures at full window size, no HUD (owner, Nov 18: dwarf facing the camera with the
- src/debug/steamshots.gd:12 _ready
- src/debug/steamshots.gd:21 _wait
- src/debug/steamshots.gd:25 _run
- src/debug/steamshots.gd:112 _floor
- src/debug/steamshots.gd:116 _mesh_around
- src/debug/steamshots.gd:123 _shoot

## src/debug/towercheck.gd (68 lines) — Tower check (F254): starts a fresh world, waits until the ruined Stone Watchtower in the first cave is built,
- src/debug/towercheck.gd:10 _ready
- src/debug/towercheck.gd:19 _wait
- src/debug/towercheck.gd:23 _run
- src/debug/towercheck.gd:57 _teleport

## src/debug/turncheck.gd (83 lines) — Turn check (F397, owner Nov 19): holds a workbench, taps Q and holds Q, and writes down how far
- src/debug/turncheck.gd:10 _ready
- src/debug/turncheck.gd:19 _wait
- src/debug/turncheck.gd:23 _shot
- src/debug/turncheck.gd:28 _deg
- src/debug/turncheck.gd:32 _run
- src/debug/turncheck.gd:74 _tap

## src/items/crafting.gd (84 lines) — Crafting with a bag (and later, nearby chests). All-or-nothing: if anything is missing,
- src/items/crafting.gd:1 Crafting
- src/items/crafting.gd:6 missing
- src/items/crafting.gd:17 can_craft
- src/items/crafting.gd:24 craft
- src/items/crafting.gd:36 _fits
- src/items/crafting.gd:48 plan
- src/items/crafting.gd:60 _need_inputs
- src/items/crafting.gd:68 _take
- src/items/crafting.gd:79 _maker_of

## src/items/drop.gd (98 lines) — A chunk of stuff that fell out of the rock. It bounces on the floor, and when
- src/items/drop.gd:1 Drop
- src/items/drop.gd:29 _ready
- src/items/drop.gd:53 _mesh_for
- src/items/drop.gd:66 _physics_process
- src/items/drop.gd:94 pickup_refused

## src/items/durability.gd (68 lines) — Tools and weapons wear out (Nov 20; makes Quick Fix, Thrifty and the Crafting ★25 repair discount work).
- src/items/durability.gd:1 Durability
- src/items/durability.gd:16 wears
- src/items/durability.gd:20 max_uses
- src/items/durability.gd:24 used
- src/items/durability.gd:28 left
- src/items/durability.gd:32 broken
- src/items/durability.gd:37 fraction
- src/items/durability.gd:42 wear
- src/items/durability.gd:52 repair_cost
- src/items/durability.gd:63 status_text

## src/items/inventory.gd (259 lines) — Inventory: the hotbar (slots 0-8, keys 1-9) plus the bag (slots 9-38).
- src/items/inventory.gd:1 Inventory
- src/items/inventory.gd:26 _init
- src/items/inventory.gd:33 equip_index
- src/items/inventory.gd:37 is_equip_index
- src/items/inventory.gd:41 is_pack_index
- src/items/inventory.gd:46 equip_slot_for
- src/items/inventory.gd:57 equipped
- src/items/inventory.gd:62 best_of_kind
- src/items/inventory.gd:73 pack_open
- src/items/inventory.gd:78 _carry
- src/items/inventory.gd:84 add
- src/items/inventory.gd:117 count_of
- src/items/inventory.gd:127 remove
- src/items/inventory.gd:155 get_slot
- src/items/inventory.gd:160 fits
- src/items/inventory.gd:173 swap
- src/items/inventory.gd:184 swap_allowed
- src/items/inventory.gd:199 split
- src/items/inventory.gd:215 quick_move
- src/items/inventory.gd:242 _pack_slots_empty
- src/items/inventory.gd:250 to_data
- src/items/inventory.gd:254 load_data

## src/items/items.gd (297 lines) — The list of every item in the game, and what it is.
- src/items/items.gd:1 Items
- src/items/items.gd:212 _data
- src/items/items.gd:238 exists
- src/items/items.gd:242 info
- src/items/items.gd:246 stack_size
- src/items/items.gd:250 display_name
- src/items/items.gd:254 color
- src/items/items.gd:258 short_label
- src/items/items.gd:268 icon
- src/items/items.gd:277 kind
- src/items/items.gd:282 dig_power
- src/items/items.gd:287 tier
- src/items/items.gd:292 fuel_seconds
- src/items/items.gd:296 ids

## src/items/recipes.gd (304 lines) — Every recipe (progression doc sections 1.6, 3.2, 4, 5.4, 6, 10.2).
- src/items/recipes.gd:1 Recipes
- src/items/recipes.gd:181 get_recipe
- src/items/recipes.gd:186 station_type
- src/items/recipes.gd:190 for_station
- src/items/recipes.gd:232 how_to_get
- src/items/recipes.gd:243 page_kind
- src/items/recipes.gd:260 page_recipes
- src/items/recipes.gd:266 random_page
- src/items/recipes.gd:280 unlock_hint
- src/items/recipes.gd:291 is_unlocked

## src/items/storage.gd (410 lines) — Storage: chests, graves and Builder's Chests. A helper of the GameAuthority (Authority/Storage),
- src/items/storage.gd:1 Storage
- src/items/storage.gd:21 _ready
- src/items/storage.gd:28 get_box
- src/items/storage.gd:32 box_id_of
- src/items/storage.gd:41 ask_transfer
- src/items/storage.gd:50 ask_pick_up
- src/items/storage.gd:60 _rpc_pick_up
- src/items/storage.gd:66 request_pick_up
- src/items/storage.gd:83 ask_take_all
- src/items/storage.gd:91 _rpc_transfer
- src/items/storage.gd:97 _rpc_take_all
- src/items/storage.gd:104 request_transfer
- src/items/storage.gd:124 _move_slot
- src/items/storage.gd:146 request_take_all
- src/items/storage.gd:159 accepts
- src/items/storage.gd:174 _piece_extras
- src/items/storage.gd:183 create_box
- src/items/storage.gd:191 put
- src/items/storage.gd:200 _changed
- src/items/storage.gd:216 _far
- src/items/storage.gd:223 _ev_add_box
- src/items/storage.gd:243 _ev_box
- src/items/storage.gd:257 fill_level
- src/items/storage.gd:266 show_fill
- src/items/storage.gd:276 _ev_remove_box
- src/items/storage.gd:285 _is_furniture
- src/items/storage.gd:289 _build_look
- src/items/storage.gd:393 _mat
- src/items/storage.gd:399 snapshot
- src/items/storage.gd:407 load_snapshot

## src/items/upgrades.gd (75 lines) — Gear upgrades +1 to +3 (building polish spec §4).
- src/items/upgrades.gd:1 Upgrades
- src/items/upgrades.gd:15 level
- src/items/upgrades.gd:20 bonus
- src/items/upgrades.gd:24 can_upgrade
- src/items/upgrades.gd:29 display_name
- src/items/upgrades.gd:34 is_metal
- src/items/upgrades.gd:41 station_for
- src/items/upgrades.gd:46 needed_level
- src/items/upgrades.gd:52 material_for
- src/items/upgrades.gd:68 next_cost

## src/main.gd (1061 lines) — Starts a game: makes the cave, the glow, the referee, the dwarf(s) and the screen.
- src/main.gd:51 _ready
- src/main.gd:269 _on_defended
- src/main.gd:284 _show_menu
- src/main.gd:336 _with_loading
- src/main.gd:374 _prefetch
- src/main.gd:384 _new_world
- src/main.gd:392 pause_action
- src/main.gd:416 _close_menu
- src/main.gd:424 start_game
- src/main.gd:642 _spawn_dwarf
- src/main.gd:680 _spawn_spot
- src/main.gd:694 player_name
- src/main.gd:699 _free_slot
- src/main.gd:706 _on_peer_connected
- src/main.gd:734 _on_peer_disconnected
- src/main.gd:751 _on_server_disconnected
- src/main.gd:759 _on_connection_failed
- src/main.gd:768 _welcome
- src/main.gd:778 _player_joined
- src/main.gd:788 _make_environment
- src/main.gd:794 _process
- src/main.gd:834 save_now
- src/main.gd:842 _notification
- src/main.gd:858 _turn_with_e
- src/main.gd:874 _unhandled_input
- src/main.gd:1047 _set_bag
- src/main.gd:1052 take_screenshot
- src/main.gd:1060 is_ready_to_play

## src/net/game_authority.gd (3100 lines) — The referee. Every action that changes the shared world goes through here:
- src/net/game_authority.gd:1 GameAuthority
- src/net/game_authority.gd:102 PlayerState
- src/net/game_authority.gd:178 _enter_tree
- src/net/game_authority.gd:182 _ready
- src/net/game_authority.gd:200 _exit_tree
- src/net/game_authority.gd:205 is_host
- src/net/game_authority.gd:209 local_peer_id
- src/net/game_authority.gd:220 add_player
- src/net/game_authority.gd:235 remove_player
- src/net/game_authority.gd:239 get_player
- src/net/game_authority.gd:243 _process
- src/net/game_authority.gd:294 ask_select_slot
- src/net/game_authority.gd:305 ask_hit
- src/net/game_authority.gd:314 ask_hit_boulder
- src/net/game_authority.gd:322 _rpc_hit_boulder
- src/net/game_authority.gd:327 request_hit_boulder
- src/net/game_authority.gd:362 ask_hit_column
- src/net/game_authority.gd:370 _rpc_hit_column
- src/net/game_authority.gd:375 request_hit_column
- src/net/game_authority.gd:410 smash_boulder
- src/net/game_authority.gd:429 smash_column
- src/net/game_authority.gd:450 _ev_column
- src/net/game_authority.gd:456 _ev_boulder
- src/net/game_authority.gd:462 _tick_boulders
- src/net/game_authority.gd:475 ask_chop_pillar
- src/net/game_authority.gd:483 _rpc_chop_pillar
- src/net/game_authority.gd:489 onyx_wood
- src/net/game_authority.gd:495 request_chop_pillar
- src/net/game_authority.gd:544 ask_chop_grove
- src/net/game_authority.gd:552 _rpc_chop_grove
- src/net/game_authority.gd:557 request_chop_grove
- src/net/game_authority.gd:586 _ev_grove_used
- src/net/game_authority.gd:593 _ev_grove_back
- src/net/game_authority.gd:600 _ev_tree_used
- src/net/game_authority.gd:611 _plant_seed
- src/net/game_authority.gd:637 _ev_planted
- src/net/game_authority.gd:643 _tick_trees
- src/net/game_authority.gd:668 _ev_regrow
- src/net/game_authority.gd:676 _ev_grow
- src/net/game_authority.gd:683 ask_break_hanging
- src/net/game_authority.gd:691 _rpc_break_hanging
- src/net/game_authority.gd:696 request_break_hanging
- src/net/game_authority.gd:719 _ev_break_hanging
- src/net/game_authority.gd:737 ask_pick_plant
- src/net/game_authority.gd:745 _rpc_pick_plant
- src/net/game_authority.gd:750 request_pick_plant
- src/net/game_authority.gd:760 ask_harvest
- src/net/game_authority.gd:768 ask_use
- src/net/game_authority.gd:776 ask_body_xp
- src/net/game_authority.gd:784 ask_ability
- src/net/game_authority.gd:792 ask_respec
- src/net/game_authority.gd:799 ask_buy_perk
- src/net/game_authority.gd:807 ask_poi
- src/net/game_authority.gd:815 ask_socket
- src/net/game_authority.gd:822 ask_unsocket
- src/net/game_authority.gd:830 _rpc_socket
- src/net/game_authority.gd:836 _rpc_unsocket
- src/net/game_authority.gd:842 ask_combine
- src/net/game_authority.gd:850 _rpc_combine
- src/net/game_authority.gd:855 request_combine
- src/net/game_authority.gd:878 _near_kind
- src/net/game_authority.gd:886 request_socket
- src/net/game_authority.gd:906 request_unsocket
- src/net/game_authority.gd:932 taught_recipes
- src/net/game_authority.gd:940 _ev_learned_blueprint
- src/net/game_authority.gd:945 _ev_learned
- src/net/game_authority.gd:950 give_stamina
- src/net/game_authority.gd:962 _rpc_stamina
- src/net/game_authority.gd:967 heal
- src/net/game_authority.gd:979 _rpc_heal
- src/net/game_authority.gd:985 ask_pickup_station
- src/net/game_authority.gd:993 _rpc_pickup_station
- src/net/game_authority.gd:998 request_pickup_station
- src/net/game_authority.gd:1015 _ev_remove_station
- src/net/game_authority.gd:1023 ask_carve
- src/net/game_authority.gd:1030 ask_craft
- src/net/game_authority.gd:1037 ask_pickup
- src/net/game_authority.gd:1044 ask_refill
- src/net/game_authority.gd:1052 ask_upgrade
- src/net/game_authority.gd:1060 _rpc_upgrade
- src/net/game_authority.gd:1066 request_upgrade
- src/net/game_authority.gd:1097 ask_repair
- src/net/game_authority.gd:1105 _rpc_repair
- src/net/game_authority.gd:1111 repair_discount
- src/net/game_authority.gd:1116 request_repair
- src/net/game_authority.gd:1147 wear_slot
- src/net/game_authority.gd:1159 ask_swap
- src/net/game_authority.gd:1168 _rpc_select_slot
- src/net/game_authority.gd:1174 _rpc_hit
- src/net/game_authority.gd:1180 _rpc_harvest
- src/net/game_authority.gd:1186 _rpc_use
- src/net/game_authority.gd:1193 _rpc_body_xp
- src/net/game_authority.gd:1199 _rpc_ability
- src/net/game_authority.gd:1205 _rpc_respec
- src/net/game_authority.gd:1211 _rpc_low_health
- src/net/game_authority.gd:1218 tell
- src/net/game_authority.gd:1226 _rpc_tell
- src/net/game_authority.gd:1235 send_cooldown
- src/net/game_authority.gd:1243 _rpc_cooldown
- src/net/game_authority.gd:1247 _cooldown_started
- src/net/game_authority.gd:1252 cooldown_left
- src/net/game_authority.gd:1261 send_effect
- src/net/game_authority.gd:1272 _rpc_effect
- src/net/game_authority.gd:1277 _rpc_buy_perk
- src/net/game_authority.gd:1283 _rpc_poi
- src/net/game_authority.gd:1289 _rpc_carve
- src/net/game_authority.gd:1295 _rpc_craft
- src/net/game_authority.gd:1301 _rpc_pickup
- src/net/game_authority.gd:1307 _rpc_refill
- src/net/game_authority.gd:1313 _rpc_swap
- src/net/game_authority.gd:1320 request_select_slot
- src/net/game_authority.gd:1330 ask_stow_lantern
- src/net/game_authority.gd:1341 _rpc_stow_lantern
- src/net/game_authority.gd:1346 request_stow_lantern
- src/net/game_authority.gd:1353 ask_draw_weapon
- src/net/game_authority.gd:1364 _rpc_draw_weapon
- src/net/game_authority.gd:1369 request_draw_weapon
- src/net/game_authority.gd:1376 request_swap
- src/net/game_authority.gd:1383 ask_split
- src/net/game_authority.gd:1390 ask_quick_move
- src/net/game_authority.gd:1398 _rpc_split
- src/net/game_authority.gd:1404 _rpc_quick_move
- src/net/game_authority.gd:1409 request_split
- src/net/game_authority.gd:1415 request_quick_move
- src/net/game_authority.gd:1423 request_hit
- src/net/game_authority.gd:1434 ore_too_hard
- src/net/game_authority.gd:1441 _break_plant_at
- src/net/game_authority.gd:1457 _judge_hit
- src/net/game_authority.gd:1523 _judge_level
- src/net/game_authority.gd:1568 host_fill
- src/net/game_authority.gd:1588 _dig_ramp
- src/net/game_authority.gd:1624 request_harvest
- src/net/game_authority.gd:1691 _read_page
- src/net/game_authority.gd:1698 _learn_from_page
- src/net/game_authority.gd:1731 ask_read
- src/net/game_authority.gd:1739 _rpc_read
- src/net/game_authority.gd:1744 request_read
- src/net/game_authority.gd:1755 request_use
- src/net/game_authority.gd:1871 ask_farm
- src/net/game_authority.gd:1879 _rpc_farm
- src/net/game_authority.gd:1886 request_farm
- src/net/game_authority.gd:1920 _ev_farm
- src/net/game_authority.gd:1928 ask_collect_water
- src/net/game_authority.gd:1936 _rpc_collect_water
- src/net/game_authority.gd:1943 request_collect_water
- src/net/game_authority.gd:1966 _ev_water
- src/net/game_authority.gd:1975 now
- src/net/game_authority.gd:1979 add_boost
- src/net/game_authority.gd:1986 boost_total
- src/net/game_authority.gd:1995 damage_boost
- src/net/game_authority.gd:2013 _ev_horn
- src/net/game_authority.gd:2022 _ev_throw
- src/net/game_authority.gd:2043 ask_train
- src/net/game_authority.gd:2051 _rpc_train
- src/net/game_authority.gd:2056 request_train
- src/net/game_authority.gd:2069 _take_sip
- src/net/game_authority.gd:2080 request_poi
- src/net/game_authority.gd:2104 request_carve
- src/net/game_authority.gd:2128 request_body_xp
- src/net/game_authority.gd:2143 request_ability
- src/net/game_authority.gd:2188 _war_horn
- src/net/game_authority.gd:2196 _ev_ability
- src/net/game_authority.gd:2205 request_respec
- src/net/game_authority.gd:2220 request_buy_perk
- src/net/game_authority.gd:2230 request_craft
- src/net/game_authority.gd:2298 request_pickup
- src/net/game_authority.gd:2320 request_refill
- src/net/game_authority.gd:2348 spawn_start_items
- src/net/game_authority.gd:2362 _host_dig
- src/net/game_authority.gd:2379 _host_remove_glow
- src/net/game_authority.gd:2389 spawn_drop
- src/net/game_authority.gd:2396 _tell_feedback
- src/net/game_authority.gd:2403 _send_inventory
- src/net/game_authority.gd:2413 _ev_dig
- src/net/game_authority.gd:2420 _apply_pending_digs
- src/net/game_authority.gd:2447 _start_regrow
- src/net/game_authority.gd:2454 _root_regrow_mult
- src/net/game_authority.gd:2459 _tick_regrow
- src/net/game_authority.gd:2485 _ev_restore_glow
- src/net/game_authority.gd:2492 _ev_restore_plant
- src/net/game_authority.gd:2499 _ev_break_plant
- src/net/game_authority.gd:2505 _ev_remove_glow
- src/net/game_authority.gd:2511 _ev_spot_chops
- src/net/game_authority.gd:2517 wall_spot
- src/net/game_authority.gd:2525 _ev_place_station
- src/net/game_authority.gd:2538 _ev_spawn_drop
- src/net/game_authority.gd:2555 _ev_remove_drop
- src/net/game_authority.gd:2563 _ev_drop_count
- src/net/game_authority.gd:2572 _rpc_feedback
- src/net/game_authority.gd:2577 _rpc_inventory
- src/net/game_authority.gd:2585 _ev_state
- src/net/game_authority.gd:2597 _ev_slab
- src/net/game_authority.gd:2602 rune_biome_at
- src/net/game_authority.gd:2606 _seed_fungal_loot
- src/net/game_authority.gd:2627 seed_poi_loot
- src/net/game_authority.gd:2661 _rpc_consumed
- src/net/game_authority.gd:2668 _rpc_progress
- src/net/game_authority.gd:2675 _rpc_fuel
- src/net/game_authority.gd:2685 snapshot
- src/net/game_authority.gd:2708 load_snapshot
- src/net/game_authority.gd:2795 _pay_hit
- src/net/game_authority.gd:2803 _give_dig_drops
- src/net/game_authority.gd:2835 ask_died
- src/net/game_authority.gd:2843 _rpc_died
- src/net/game_authority.gd:2850 request_died
- src/net/game_authority.gd:2877 _track_safe_spots
- src/net/game_authority.gd:2903 grave_spot
- src/net/game_authority.gd:2915 _bond_of_the_clan
- src/net/game_authority.gd:2929 _rpc_respawn
- src/net/game_authority.gd:2933 _respawn_here
- src/net/game_authority.gd:2948 hurt
- src/net/game_authority.gd:2959 _rpc_hurt
- src/net/game_authority.gd:2965 _take_hurt
- src/net/game_authority.gd:2975 set_friendly_fire
- src/net/game_authority.gd:2981 friendly_fire
- src/net/game_authority.gd:2986 give_xp
- src/net/game_authority.gd:3001 _peer_of
- src/net/game_authority.gd:3012 _tick_vitals
- src/net/game_authority.gd:3067 station_near
- src/net/game_authority.gd:3078 pack_fill
- src/net/game_authority.gd:3082 pack_dig
- src/net/game_authority.gd:3087 unpack_dig
- src/net/game_authority.gd:3091 drop_count
- src/net/game_authority.gd:3095 pending_dig_count
- src/net/game_authority.gd:3099 _chest

## src/net/session.gd (137 lines) — Session: connects friends together.
- src/net/session.gd:1 Session
- src/net/session.gd:27 _ready
- src/net/session.gd:32 _process
- src/net/session.gd:39 host_direct
- src/net/session.gd:51 join_direct
- src/net/session.gd:66 steam_available
- src/net/session.gd:83 host_steam
- src/net/session.gd:92 join_steam_lobby
- src/net/session.gd:101 _on_lobby_created
- src/net/session.gd:115 _on_lobby_joined
- src/net/session.gd:129 _on_join_requested
- src/net/session.gd:133 leave

## src/player/chunk_swarm.gd (111 lines) — A broken block bursts into lots of little bits (feedback F13): 25-50 pieces pop out,
- src/player/chunk_swarm.gd:1 ChunkSwarm
- src/player/chunk_swarm.gd:24 burst
- src/player/chunk_swarm.gd:40 _mesh_for
- src/player/chunk_swarm.gd:54 _setup
- src/player/chunk_swarm.gd:81 _process
- src/player/chunk_swarm.gd:107 _write

## src/player/controls.gd (96 lines) — The game's buttons. Kept in one place so a settings menu (Step 7) can change them.
- src/player/controls.gd:1 Controls
- src/player/controls.gd:59 captured
- src/player/controls.gd:64 set_captured
- src/player/controls.gd:71 setup
- src/player/controls.gd:92 _ensure

## src/player/dwarf.gd (935 lines) — The dwarf: walking, running, jumping, the camera behind them, and swinging the pickaxe.
- src/player/dwarf.gd:1 Dwarf
- src/player/dwarf.gd:53 _notification
- src/player/dwarf.gd:89 _ready
- src/player/dwarf.gd:125 set_respawn
- src/player/dwarf.gd:129 _build_camera
- src/player/dwarf.gd:156 build_lifts
- src/player/dwarf.gd:160 _unhandled_input
- src/player/dwarf.gd:212 set_dev_fly
- src/player/dwarf.gd:219 _fly
- src/player/dwarf.gd:231 _physics_process
- src/player/dwarf.gd:348 _process
- src/player/dwarf.gd:404 aim_far
- src/player/dwarf.gd:417 aim
- src/player/dwarf.gd:438 _aim_info
- src/player/dwarf.gd:500 _on_swing_impact
- src/player/dwarf.gd:582 _try_step_up
- src/player/dwarf.gd:604 _footsteps
- src/player/dwarf.gd:618 defense_state
- src/player/dwarf.gd:622 is_invulnerable
- src/player/dwarf.gd:626 guard_break
- src/player/dwarf.gd:636 _guard_fall
- src/player/dwarf.gd:656 hold_legs
- src/player/dwarf.gd:669 shove
- src/player/dwarf.gd:674 knock_down
- src/player/dwarf.gd:685 big_hit
- src/player/dwarf.gd:691 _net_big_hit
- src/player/dwarf.gd:712 got_parry
- src/player/dwarf.gd:717 add_shake
- src/player/dwarf.gd:725 hit_stop
- src/player/dwarf.gd:738 _ladder_here
- src/player/dwarf.gd:754 face_camera
- src/player/dwarf.gd:758 _holding_hammer
- src/player/dwarf.gd:765 _send_body_xp
- src/player/dwarf.gd:777 _progress
- src/player/dwarf.gd:783 _vitals
- src/player/dwarf.gd:790 _can_swing
- src/player/dwarf.gd:801 _on_dig_feedback
- src/player/dwarf.gd:842 sit_on
- src/player/dwarf.gd:851 stand_up
- src/player/dwarf.gd:862 _sit_step
- src/player/dwarf.gd:877 sitting
- src/player/dwarf.gd:882 _net_sit
- src/player/dwarf.gd:888 _online
- src/player/dwarf.gd:893 _net_pose
- src/player/dwarf.gd:899 _net_swing
- src/player/dwarf.gd:905 _net_look
- src/player/dwarf.gd:914 _worn_items
- src/player/dwarf.gd:934 _net_react

## src/player/dwarf_fist.gd (1061 lines) — The dwarf's fists (owner, Nov 19: "the handle runs past his hand and his fingers stay open; he isn't really gr
- src/player/dwarf_fist.gd:1 DwarfFist
- src/player/dwarf_fist.gd:87 setup
- src/player/dwarf_fist.gd:112 _bend_axis
- src/player/dwarf_fist.gd:123 _process_modification_with_delta
- src/player/dwarf_fist.gd:167 _close
- src/player/dwarf_fist.gd:173 _hold
- src/player/dwarf_fist.gd:243 _roll_forearm
- src/player/dwarf_fist.gd:267 _great_hold
- src/player/dwarf_fist.gd:343 _apply_pose
- src/player/dwarf_fist.gd:375 _reach_shoulder
- src/player/dwarf_fist.gd:393 _lay_weapon
- src/player/dwarf_fist.gd:417 _arms
- src/player/dwarf_fist.gd:449 _fit_shapes
- src/player/dwarf_fist.gd:515 _keep_out
- src/player/dwarf_fist.gd:556 _within_reach
- src/player/dwarf_fist.gd:584 _clearance
- src/player/dwarf_fist.gd:639 _to_sk_turn
- src/player/dwarf_fist.gd:646 _fist_to
- src/player/dwarf_fist.gd:674 _turn_fist
- src/player/dwarf_fist.gd:686 _one_aim
- src/player/dwarf_fist.gd:709 _tip_dir
- src/player/dwarf_fist.gd:734 _clear_head
- src/player/dwarf_fist.gd:773 _blade_of
- src/player/dwarf_fist.gd:819 _set_turn
- src/player/dwarf_fist.gd:826 _reach
- src/player/dwarf_fist.gd:862 _guard
- src/player/dwarf_fist.gd:898 _wear_shield
- src/player/dwarf_fist.gd:966 _handle_of
- src/player/dwarf_fist.gd:1004 _old_hold
- src/player/dwarf_fist.gd:1018 _measure
- src/player/dwarf_fist.gd:1029 _measure_side

## src/player/dwarf_great_swing.gd (129 lines) — How the dwarf holds and swings the great axe and the great maul (F389, owner's decision Nov 20: "use the Lampw
- src/player/dwarf_great_swing.gd:1 DwarfGreatSwing
- src/player/dwarf_great_swing.gd:41 _load
- src/player/dwarf_great_swing.gd:64 has_moves
- src/player/dwarf_great_swing.gd:70 clip_length
- src/player/dwarf_great_swing.gd:76 clip_pose
- src/player/dwarf_great_swing.gd:89 stance
- src/player/dwarf_great_swing.gd:97 swing
- src/player/dwarf_great_swing.gd:108 clip_time
- src/player/dwarf_great_swing.gd:117 blend

## src/player/dwarf_model.gd (402 lines) — The dwarf's body. Normally the real rigged, animated dwarf (DwarfRig, src/player/dwarf_rig.gd).
- src/player/dwarf_model.gd:1 DwarfModel
- src/player/dwarf_model.gd:46 _ready
- src/player/dwarf_model.gd:98 work
- src/player/dwarf_model.gd:107 swing
- src/player/dwarf_model.gd:135 attack
- src/player/dwarf_model.gd:167 set_held
- src/player/dwarf_model.gd:192 _build_rig
- src/player/dwarf_model.gd:225 _rig_play
- src/player/dwarf_model.gd:239 set_motion
- src/player/dwarf_model.gd:259 set_climbing
- src/player/dwarf_model.gd:265 set_sitting
- src/player/dwarf_model.gd:271 set_wear
- src/player/dwarf_model.gd:278 set_shield
- src/player/dwarf_model.gd:289 set_pose
- src/player/dwarf_model.gd:296 react
- src/player/dwarf_model.gd:328 _build_dwarf_rig
- src/player/dwarf_model.gd:340 _rest
- src/player/dwarf_model.gd:347 _part
- src/player/dwarf_model.gd:357 _mat
- src/player/dwarf_model.gd:361 _cyl
- src/player/dwarf_model.gd:371 _capsule
- src/player/dwarf_model.gd:380 _sphere
- src/player/dwarf_model.gd:389 _hemisphere
- src/player/dwarf_model.gd:399 _box

## src/player/dwarf_one_swing.gd (89 lines) — How the dwarf swings the sword and the mace (F389, owner Nov 20: "do the same for the sword and the mace", he 
- src/player/dwarf_one_swing.gd:1 DwarfOneSwing
- src/player/dwarf_one_swing.gd:30 _load
- src/player/dwarf_one_swing.gd:37 _load_file
- src/player/dwarf_one_swing.gd:65 has_move
- src/player/dwarf_one_swing.gd:71 clip_length
- src/player/dwarf_one_swing.gd:77 swing

## src/player/dwarf_proportions.gd (267 lines) — Turns a normal human skeleton into a dwarf, every frame, AFTER the animation.
- src/player/dwarf_proportions.gd:1 DwarfProportions
- src/player/dwarf_proportions.gd:71 setup
- src/player/dwarf_proportions.gd:116 _shoulders_forward
- src/player/dwarf_proportions.gd:142 no_skew
- src/player/dwarf_proportions.gd:168 _total_thickness
- src/player/dwarf_proportions.gd:176 _thick
- src/player/dwarf_proportions.gd:182 _rest_global
- src/player/dwarf_proportions.gd:198 _process_modification_with_delta
- src/player/dwarf_proportions.gd:233 _settle_feet
- src/player/dwarf_proportions.gd:243 _lowest_foot
- src/player/dwarf_proportions.gd:256 _pose_global

## src/player/dwarf_ragdoll.gd (172 lines) — Big hits (F237: mine cart, swinging boulder or anvil, spiked flail): the dwarf goes floppy like a rag doll,
- src/player/dwarf_ragdoll.gd:1 DwarfRagdoll
- src/player/dwarf_ragdoll.gd:44 _ready
- src/player/dwarf_ragdoll.gd:49 down
- src/player/dwarf_ragdoll.gd:54 start
- src/player/dwarf_ragdoll.gd:124 _physics_process
- src/player/dwarf_ragdoll.gd:155 _process_modification_with_delta

## src/player/dwarf_rig.gd (1675 lines) — The real dwarf: a rigged, animated model built from free CC0 Quaternius packs
- src/player/dwarf_rig.gd:1 DwarfRig
- src/player/dwarf_rig.gd:128 loop_rate
- src/player/dwarf_rig.gd:241 build
- src/player/dwarf_rig.gd:314 _wear_body
- src/player/dwarf_rig.gd:369 _hide_skin_under_shirt
- src/player/dwarf_rig.gd:453 _bind_to_skeleton
- src/player/dwarf_rig.gd:474 _fit_colliders
- src/player/dwarf_rig.gd:533 _add_swing_bones
- src/player/dwarf_rig.gd:574 _hair_on_shirt
- src/player/dwarf_rig.gd:617 _torso_mesh
- src/player/dwarf_rig.gd:627 _add_springs
- src/player/dwarf_rig.gd:640 dwarf_rest_poses
- src/player/dwarf_rig.gd:654 _process
- src/player/dwarf_rig.gd:675 hold_turn
- src/player/dwarf_rig.gd:704 _lift_roll
- src/player/dwarf_rig.gd:715 _update_grip
- src/player/dwarf_rig.gd:734 great_two_hands
- src/player/dwarf_rig.gd:740 great_pose
- src/player/dwarf_rig.gd:768 one_pose
- src/player/dwarf_rig.gd:798 grip_transform
- src/player/dwarf_rig.gd:807 shield_transform
- src/player/dwarf_rig.gd:813 snap_grip
- src/player/dwarf_rig.gd:822 set_climbing
- src/player/dwarf_rig.gd:828 set_sitting
- src/player/dwarf_rig.gd:834 set_hold
- src/player/dwarf_rig.gd:846 set_motion
- src/player/dwarf_rig.gd:892 play_upper
- src/player/dwarf_rig.gd:897 stop_upper
- src/player/dwarf_rig.gd:903 play_full
- src/player/dwarf_rig.gd:915 ual_slow
- src/player/dwarf_rig.gd:919 attack_seconds
- src/player/dwarf_rig.gd:928 attack
- src/player/dwarf_rig.gd:938 stab
- src/player/dwarf_rig.gd:942 _play
- src/player/dwarf_rig.gd:965 _build_tree
- src/player/dwarf_rig.gd:1052 _add_oneshot
- src/player/dwarf_rig.gd:1069 _arm_filter
- src/player/dwarf_rig.gd:1081 _roll_on
- src/player/dwarf_rig.gd:1086 _upper_filter
- src/player/dwarf_rig.gd:1097 _hand_socket
- src/player/dwarf_rig.gd:1107 _borrow_meshes
- src/player/dwarf_rig.gd:1123 set_wear
- src/player/dwarf_rig.gd:1192 _wear_armor
- src/player/dwarf_rig.gd:1238 _wear_built_armor
- src/player/dwarf_rig.gd:1261 _helmet_shape
- src/player/dwarf_rig.gd:1285 _on_bone
- src/player/dwarf_rig.gd:1296 _head_space
- src/player/dwarf_rig.gd:1309 _piece
- src/player/dwarf_rig.gd:1320 _ball
- src/player/dwarf_rig.gd:1330 _ring
- src/player/dwarf_rig.gd:1339 _tube
- src/player/dwarf_rig.gd:1351 _wear_spore_mask
- src/player/dwarf_rig.gd:1387 _build_helmet
- src/player/dwarf_rig.gd:1437 _build_beard
- src/player/dwarf_rig.gd:1488 _quad
- src/player/dwarf_rig.gd:1495 _big_beard
- src/player/dwarf_rig.gd:1524 _add_rim
- src/player/dwarf_rig.gd:1541 _tint_clothes
- src/player/dwarf_rig.gd:1555 _made_library
- src/player/dwarf_rig.gd:1593 _split_anim
- src/player/dwarf_rig.gd:1623 _source
- src/player/dwarf_rig.gd:1629 _library
- src/player/dwarf_rig.gd:1642 _head_only

## src/player/dwarf_weight.gd (206 lines) — Makes the dwarf feel heavy and chunky (owner, Nov 19: "heavy + chunky"; F30, F342 squash and stretch).
- src/player/dwarf_weight.gd:1 DwarfWeight
- src/player/dwarf_weight.gd:60 setup
- src/player/dwarf_weight.gd:100 _sign_of
- src/player/dwarf_weight.gd:106 land
- src/player/dwarf_weight.gd:111 takeoff
- src/player/dwarf_weight.gd:115 _process_modification_with_delta
- src/player/dwarf_weight.gd:173 _begin
- src/player/dwarf_weight.gd:187 _turn
- src/player/dwarf_weight.gd:198 _squash

## src/player/even_head.gd (63 lines) — Keeps the dwarf's neck and head their own shape whatever the body does (F280, owner Nov 17: "the head is squas
- src/player/even_head.gd:1 EvenHead
- src/player/even_head.gd:24 setup
- src/player/even_head.gd:43 _process_modification_with_delta
- src/player/even_head.gd:59 _nearest_turn

## src/player/fx.gd (148 lines) — Little visual effects: rock bits flying when you dig, plus a puff of dust.
- src/player/fx.gd:1 Fx
- src/player/fx.gd:12 burst
- src/player/fx.gd:52 dust
- src/player/fx.gd:97 material_color
- src/player/fx.gd:108 _chunk
- src/player/fx.gd:119 _chunk_mat
- src/player/fx.gd:135 _dust

## src/player/hair_swing.gd (258 lines) — Hair that swings (owner, F192: "the 3 braids need a lot of skeleton points where it bends, so it actually look
- src/player/hair_swing.gd:1 HairSwing
- src/player/hair_swing.gd:62 setup
- src/player/hair_swing.gd:107 _pose_global
- src/player/hair_swing.gd:118 _process_modification_with_delta
- src/player/hair_swing.gd:137 _on_shirt
- src/player/hair_swing.gd:153 _step

## src/player/lantern.gd (127 lines) — The dwarf's lantern. Bright while it has fuel; a small dim glow when empty,
- src/player/lantern.gd:1 Lantern
- src/player/lantern.gd:20 _ready
- src/player/lantern.gd:71 _piece
- src/player/lantern.gd:82 is_on_back
- src/player/lantern.gd:90 has_lantern
- src/player/lantern.gd:99 _process

## src/player/place_ghost.gd (137 lines) — Holding a station or chest (workbench, campfire, bed, chest...): a see-through copy shows where it
- src/player/place_ghost.gd:1 PlaceGhost
- src/player/place_ghost.gd:23 _ready
- src/player/place_ghost.gd:29 _ghost_mat
- src/player/place_ghost.gd:37 _process
- src/player/place_ghost.gd:62 where
- src/player/place_ghost.gd:84 turn
- src/player/place_ghost.gd:92 held_turn
- src/player/place_ghost.gd:96 _keep_turning
- src/player/place_ghost.gd:107 _unhandled_input
- src/player/place_ghost.gd:113 _show
- src/player/place_ghost.gd:132 _paint

## src/player/station_links.gd (81 lines) — Station helper lines (owner, Nov 20): while you hold a station, a helper (chopping block, bellows...) or the b
- src/player/station_links.gd:1 StationLinks
- src/player/station_links.gd:16 _ready
- src/player/station_links.gd:26 _process
- src/player/station_links.gd:49 links
- src/player/station_links.gd:62 ghost_links
- src/player/station_links.gd:73 _ribbon

## src/progress/goals.gd (61 lines) — "Next steps" (owner, Nov 15, F103): a short to-do list on screen that shows the next few things to
- src/progress/goals.gd:1 Goals
- src/progress/goals.gd:31 done
- src/progress/goals.gd:54 next_steps

## src/progress/progression.gd (583 lines) — How a dwarf grows (progression doc section 7):
- src/progress/progression.gd:1 Progression
- src/progress/progression.gd:128 xp_to_next
- src/progress/progression.gd:132 _zeros
- src/progress/progression.gd:140 skill_xp_to_next
- src/progress/progression.gd:145 weapon_skill
- src/progress/progression.gd:150 has_star
- src/progress/progression.gd:154 total_xp_for_level
- src/progress/progression.gd:162 points_for_level
- src/progress/progression.gd:169 add_xp
- src/progress/progression.gd:195 points_total
- src/progress/progression.gd:199 points_free
- src/progress/progression.gd:203 perk_rank
- src/progress/progression.gd:208 why_not
- src/progress/progression.gd:221 buy_perk
- src/progress/progression.gd:230 respec_cost
- src/progress/progression.gd:235 respec
- src/progress/progression.gd:241 ability_slots
- src/progress/progression.gd:252 dig_power_mult
- src/progress/progression.gd:256 chop_power_mult
- src/progress/progression.gd:261 swing_stamina_mult
- src/progress/progression.gd:266 lantern_range_mult
- src/progress/progression.gd:270 run_speed_mult
- src/progress/progression.gd:274 run_stamina_mult
- src/progress/progression.gd:278 jump_speed_mult
- src/progress/progression.gd:282 jump_stamina_mult
- src/progress/progression.gd:288 _lv
- src/progress/progression.gd:293 attack_stamina_mult
- src/progress/progression.gd:299 skill_armor_pierce
- src/progress/progression.gd:309 skill_stun_mult
- src/progress/progression.gd:322 reach_mult
- src/progress/progression.gd:327 block_bonus
- src/progress/progression.gd:332 parry_mult
- src/progress/progression.gd:339 crossbow_reload_mult
- src/progress/progression.gd:344 craft_time_mult
- src/progress/progression.gd:350 star_damage_bonus
- src/progress/progression.gd:375 riposte_crits
- src/progress/progression.gd:380 extra_targets
- src/progress/progression.gd:386 dig_swing_mult
- src/progress/progression.gd:391 guard_walk_mult
- src/progress/progression.gd:396 weapon_damage_bonus
- src/progress/progression.gd:402 gather_extra_chance
- src/progress/progression.gd:406 hunger_drain_mult
- src/progress/progression.gd:410 thirst_drain_mult
- src/progress/progression.gd:414 food_duration_mult
- src/progress/progression.gd:419 max_health_bonus
- src/progress/progression.gd:423 max_stamina_bonus
- src/progress/progression.gd:427 health_regen_bonus
- src/progress/progression.gd:432 ailment_resist
- src/progress/progression.gd:439 armor_bonus
- src/progress/progression.gd:444 perk_damage_bonus
- src/progress/progression.gd:448 dodge_stamina_mult
- src/progress/progression.gd:452 reload_mult
- src/progress/progression.gd:457 armor_pierce
- src/progress/progression.gd:461 heavy_stun_mult
- src/progress/progression.gd:466 ore_power_mult
- src/progress/progression.gd:470 smelt_time_mult
- src/progress/progression.gd:474 extra_ore_chance
- src/progress/progression.gd:478 save_material_chance
- src/progress/progression.gd:482 extra_drop_chance
- src/progress/progression.gd:487 quality_smithing
- src/progress/progression.gd:492 roll_quality
- src/progress/progression.gd:504 quality_bonus
- src/progress/progression.gd:510 add_kill
- src/progress/progression.gd:514 kills_of
- src/progress/progression.gd:524 hunter_rank
- src/progress/progression.gd:532 hunter_bonus
- src/progress/progression.gd:537 hunter_title
- src/progress/progression.gd:544 total_kills
- src/progress/progression.gd:553 to_data
- src/progress/progression.gd:562 load_data

## src/progress/rune_slab.gd (161 lines) — The world's Rune Slab (progression doc section 8). One per world, shared by every player.
- src/progress/rune_slab.gd:1 RuneSlab
- src/progress/rune_slab.gd:53 colour_of
- src/progress/rune_slab.gd:57 set_of
- src/progress/rune_slab.gd:61 runes_in_set
- src/progress/rune_slab.gd:71 offer
- src/progress/rune_slab.gd:82 carve_with_shards
- src/progress/rune_slab.gd:91 _carve
- src/progress/rune_slab.gd:99 is_set_done
- src/progress/rune_slab.gd:106 finished_sets
- src/progress/rune_slab.gd:115 bonus
- src/progress/rune_slab.gd:123 taught_recipes
- src/progress/rune_slab.gd:135 pick_drop
- src/progress/rune_slab.gd:153 to_data
- src/progress/rune_slab.gd:157 load_data

## src/save_game.gd (174 lines) — Saving and loading a world (spec 5.11: autosave every 5 minutes and when you quit,
- src/save_game.gd:1 SaveGame
- src/save_game.gd:16 folder
- src/save_game.gd:24 path_for
- src/save_game.gd:29 new_path
- src/save_game.gd:34 list_worlds
- src/save_game.gd:53 load_world
- src/save_game.gd:63 delete_world
- src/save_game.gd:72 world_name
- src/save_game.gd:78 save
- src/save_game.gd:124 read
- src/save_game.gd:138 newest
- src/save_game.gd:160 player_data
- src/save_game.gd:165 apply_player

## src/sfx.gd (57 lines) — Plays sound effects from assets/sfx (CC0 sounds by Kenney, see CREDITS.md).
- src/sfx.gd:1 Sfx
- src/sfx.gd:15 _variants
- src/sfx.gd:28 play
- src/sfx.gd:46 ui

## src/survival/ailments.gd (117 lines) — Poison, burn and chill on a dwarf or a creature (docs/design/gems.md, owner Nov 20).
- src/survival/ailments.gd:1 Ailments
- src/survival/ailments.gd:31 add
- src/survival/ailments.gd:43 _stack
- src/survival/ailments.gd:63 tick
- src/survival/ailments.gd:79 has
- src/survival/ailments.gd:83 stacks_of
- src/survival/ailments.gd:88 blocks_regen
- src/survival/ailments.gd:93 speed_mult
- src/survival/ailments.gd:99 clear
- src/survival/ailments.gd:108 describe

## src/survival/comfort.gd (53 lines) — How cozy a spot is (the "Cozy" rest buff). Rest near a campfire or bed for a few seconds and you
- src/survival/comfort.gd:1 Comfort
- src/survival/comfort.gd:29 score
- src/survival/comfort.gd:52 duration

## src/survival/darkness.gd (28 lines) — F293 (owner, Nov 19): standing in the dark hurts. No healing at all, and every action costs 50% more stamina.
- src/survival/darkness.gd:1 Darkness
- src/survival/darkness.gd:13 mark
- src/survival/darkness.gd:18 is_lit

## src/survival/fall_damage.gd (35 lines) — Falling hurts (Nov 20; Jumping ★100 is "no fall damage"). Runs on the player's own computer, like the rest of
- src/survival/fall_damage.gd:1 FallDamage
- src/survival/fall_damage.gd:16 damage_for
- src/survival/fall_damage.gd:21 step

## src/survival/foods.gd (81 lines) — Every buff dish and brewed drink (progression doc 6.6).
- src/survival/foods.gd:1 Foods
- src/survival/foods.gd:42 is_buff_food
- src/survival/foods.gd:46 buff_of
- src/survival/foods.gd:50 minutes_of
- src/survival/foods.gd:54 is_drink
- src/survival/foods.gd:60 heart_halves
- src/survival/foods.gd:67 effect_lines

## src/survival/vitals.gd (283 lines) — A dwarf's body: health, stamina, hunger, thirst, and the food buffs (2 foods + 1 drink).
- src/survival/vitals.gd:1 Vitals
- src/survival/vitals.gd:48 buff_total
- src/survival/vitals.gd:59 _rank
- src/survival/vitals.gd:64 status
- src/survival/vitals.gd:75 is_tired
- src/survival/vitals.gd:79 max_health
- src/survival/vitals.gd:83 max_stamina
- src/survival/vitals.gd:88 regen_per_second
- src/survival/vitals.gd:92 health_regen_mult
- src/survival/vitals.gd:102 set_cozy
- src/survival/vitals.gd:109 stamina_regen_mult
- src/survival/vitals.gd:126 tick
- src/survival/vitals.gd:165 use_stamina
- src/survival/vitals.gd:174 drain_stamina
- src/survival/vitals.gd:183 take_damage
- src/survival/vitals.gd:198 add_ailment
- src/survival/vitals.gd:204 add_effect
- src/survival/vitals.gd:212 consume
- src/survival/vitals.gd:228 food_slots
- src/survival/vitals.gd:232 _add_buff
- src/survival/vitals.gd:253 respawn
- src/survival/vitals.gd:267 is_dead
- src/survival/vitals.gd:273 to_data
- src/survival/vitals.gd:277 load_data

## src/ui/ailment_badges.gd (62 lines) — Round badges above the health bar for Burning / Chilled / Poisoned / Frozen (owner, Nov 20). A ring round each
- src/ui/ailment_badges.gd:1 AilmentBadges
- src/ui/ailment_badges.gd:13 _init
- src/ui/ailment_badges.gd:19 show_ailments
- src/ui/ailment_badges.gd:37 Badge

## src/ui/blueprint_menu.gd (201 lines) — The blueprint book (V while holding the Build Hammer). Blueprints that ship with the
- src/ui/blueprint_menu.gd:1 BlueprintMenu
- src/ui/blueprint_menu.gd:23 _ready
- src/ui/blueprint_menu.gd:79 all_files
- src/ui/blueprint_menu.gd:92 ready_made_keys
- src/ui/blueprint_menu.gd:100 ready_made_name
- src/ui/blueprint_menu.gd:106 _known
- src/ui/blueprint_menu.gd:112 entries
- src/ui/blueprint_menu.gd:126 still_hidden
- src/ui/blueprint_menu.gd:131 refresh
- src/ui/blueprint_menu.gd:169 _show_page
- src/ui/blueprint_menu.gd:196 _place_picked

## src/ui/blueprint_preview.gd (116 lines) — A small turning 3D picture of a blueprint for the blueprint book (owner F99: "the list has no
- src/ui/blueprint_preview.gd:1 BlueprintPreview
- src/ui/blueprint_preview.gd:14 _init
- src/ui/blueprint_preview.gd:43 show_blueprint
- src/ui/blueprint_preview.gd:63 show_ruin
- src/ui/blueprint_preview.gd:95 _glow
- src/ui/blueprint_preview.gd:114 _process

## src/ui/boss_bar.gd (43 lines) — The mini boss's name and a long health bar at the top of the screen (owner, Nov 20, F237).
- src/ui/boss_bar.gd:1 BossBar
- src/ui/boss_bar.gd:15 _init
- src/ui/boss_bar.gd:33 track
- src/ui/boss_bar.gd:39 _process

## src/ui/box_panel.gd (149 lines) — A chest, grave or Builder's Chest. Click a stack to move it to your bag;
- src/ui/box_panel.gd:1 BoxPanel
- src/ui/box_panel.gd:19 _ready
- src/ui/box_panel.gd:42 open
- src/ui/box_panel.gd:56 _on_visibility
- src/ui/box_panel.gd:61 _shut_lid
- src/ui/box_panel.gd:70 has_items
- src/ui/box_panel.gd:77 refresh
- src/ui/box_panel.gd:129 _show_ways
- src/ui/box_panel.gd:147 _process

## src/ui/build_menu.gd (197 lines) — Pick what to build (B while holding the Build Hammer).
- src/ui/build_menu.gd:1 BuildMenu
- src/ui/build_menu.gd:10 _ready
- src/ui/build_menu.gd:25 pieces_in
- src/ui/build_menu.gd:33 refresh
- src/ui/build_menu.gd:100 _family_for
- src/ui/build_menu.gd:105 station_item
- src/ui/build_menu.gd:109 _cost_text
- src/ui/build_menu.gd:118 _piece_button
- src/ui/build_menu.gd:173 piece_picture
- src/ui/build_menu.gd:179 missing
- src/ui/build_menu.gd:189 needs_text

## src/ui/craft_panel.gd (663 lines) — The crafting list: by hand (shown next to the bag) or at a station (press E at it).
- src/ui/craft_panel.gd:1 CraftPanel
- src/ui/craft_panel.gd:42 _ready
- src/ui/craft_panel.gd:134 make_upgrade_panel
- src/ui/craft_panel.gd:153 reset_amount
- src/ui/craft_panel.gd:160 tab_of
- src/ui/craft_panel.gd:175 open_for
- src/ui/craft_panel.gd:182 refresh
- src/ui/craft_panel.gd:275 craft_time
- src/ui/craft_panel.gd:286 can_make_count
- src/ui/craft_panel.gd:294 start_making
- src/ui/craft_panel.gd:317 cancel_making
- src/ui/craft_panel.gd:326 _finish
- src/ui/craft_panel.gd:331 _me
- src/ui/craft_panel.gd:337 _process
- src/ui/craft_panel.gd:370 _prog
- src/ui/craft_panel.gd:376 _upgrade_rows
- src/ui/craft_panel.gd:448 _ready_to_make
- src/ui/craft_panel.gd:456 _can_chain
- src/ui/craft_panel.gd:467 _fuel_have
- src/ui/craft_panel.gd:472 _card
- src/ui/craft_panel.gd:502 _show_detail
- src/ui/craft_panel.gd:541 _gem_bench
- src/ui/craft_panel.gd:608 _rune_slab
- src/ui/craft_panel.gd:649 _food_lines

## src/ui/dev_items.gd (85 lines) — The owner's item menu (F8, Nov 19: "a menu where if I click an item, it just gets into my inventory so I don't
- src/ui/dev_items.gd:1 DevItems
- src/ui/dev_items.gd:12 _ready
- src/ui/dev_items.gd:41 all_ids
- src/ui/dev_items.gd:51 refresh
- src/ui/dev_items.gd:75 give

## src/ui/dev_menu.gd (64 lines) — The owner's dev menu (P, Nov 16): place ANY ready-made blueprint to preview it (learned or not, no hammer
- src/ui/dev_menu.gd:1 DevMenu
- src/ui/dev_menu.gd:12 enabled
- src/ui/dev_menu.gd:17 all_blueprints
- src/ui/dev_menu.gd:27 _ready
- src/ui/dev_menu.gd:46 refresh

## src/ui/graphics_settings.gd (143 lines) — Graphics settings (owner, Nov 19: "optimize... for potato computers"; plan: docs/research/Voxel game performan
- src/ui/graphics_settings.gd:1 GraphicsSettings
- src/ui/graphics_settings.gd:32 load_and_apply
- src/ui/graphics_settings.gd:49 guess
- src/ui/graphics_settings.gd:55 choose
- src/ui/graphics_settings.gd:65 set_value
- src/ui/graphics_settings.gd:74 set_fps
- src/ui/graphics_settings.gd:81 apply
- src/ui/graphics_settings.gd:102 apply_env
- src/ui/graphics_settings.gd:113 light_count
- src/ui/graphics_settings.gd:118 grass
- src/ui/graphics_settings.gd:123 chunk_share
- src/ui/graphics_settings.gd:129 cheap_light
- src/ui/graphics_settings.gd:136 save

## src/ui/hud.gd (1287 lines) — Everything drawn on top of the game: crosshair, what you're aiming at,
- src/ui/hud.gd:1 Hud
- src/ui/hud.gd:73 _ready
- src/ui/hud.gd:86 _build
- src/ui/hud.gd:389 _label
- src/ui/hud.gd:399 _overlay
- src/ui/hud.gd:421 _make_slot
- src/ui/hud.gd:454 _add_key_plate
- src/ui/hud.gd:478 _size_slot
- src/ui/hud.gd:512 _slot_style
- src/ui/hud.gd:524 _refresh_slots
- src/ui/hud.gd:574 _show_cooldown
- src/ui/hud.gd:595 cooldown_shade_height
- src/ui/hud.gd:600 _show_wear
- src/ui/hud.gd:621 _on_slot_input
- src/ui/hud.gd:677 _slot_outline
- src/ui/hud.gd:686 wants_equip_click
- src/ui/hud.gd:695 _quick_equip
- src/ui/hud.gd:722 _on_dig_feedback
- src/ui/hud.gd:746 _update_first_steps
- src/ui/hud.gd:782 _in_start_room
- src/ui/hud.gd:790 show_toast
- src/ui/hud.gd:796 set_loading_progress
- src/ui/hud.gd:801 set_loading
- src/ui/hud.gd:807 is_bag_open
- src/ui/hud.gd:813 _layout_panels
- src/ui/hud.gd:841 _place_hotbar
- src/ui/hud.gd:858 _place_vitals
- src/ui/hud.gd:886 _size_hotbar
- src/ui/hud.gd:893 is_hotbar_in_bag
- src/ui/hud.gd:897 set_bag_open
- src/ui/hud.gd:911 open_box
- src/ui/hud.gd:918 is_build_menu_open
- src/ui/hud.gd:922 set_build_menu_open
- src/ui/hud.gd:929 is_dev_menu_open
- src/ui/hud.gd:933 set_dev_menu_open
- src/ui/hud.gd:941 open_builder_chest
- src/ui/hud.gd:948 is_blueprints_open
- src/ui/hud.gd:952 set_blueprints_open
- src/ui/hud.gd:960 is_map_open
- src/ui/hud.gd:964 set_map_open
- src/ui/hud.gd:971 is_skills_open
- src/ui/hud.gd:975 set_skills_open
- src/ui/hud.gd:981 open_station
- src/ui/hud.gd:987 is_paused
- src/ui/hud.gd:991 set_paused
- src/ui/hud.gd:1012 _build_pause
- src/ui/hud.gd:1069 _update_work_bar
- src/ui/hud.gd:1088 _update_reload_bar
- src/ui/hud.gd:1096 _process
- src/ui/hud.gd:1219 _refresh_selection
- src/ui/hud.gd:1225 _local_dwarf
- src/ui/hud.gd:1232 _exit_tree
- src/ui/hud.gd:1237 _unhandled_input
- src/ui/hud.gd:1250 _input
- src/ui/hud.gd:1265 hotbar_key
- src/ui/hud.gd:1273 take_down_text
- src/ui/hud.gd:1281 steadiness_text

## src/ui/learned_cards.gd (81 lines) — Owner (Nov 19): "any time you learn a recipe it should say on the left-hand side, like a pop-up, and actually 
- src/ui/learned_cards.gd:1 LearnedCards
- src/ui/learned_cards.gd:12 _ready
- src/ui/learned_cards.gd:28 show_card
- src/ui/learned_cards.gd:71 show_recipe
- src/ui/learned_cards.gd:80 show_blueprint

## src/ui/map_data.gd (120 lines) — The explored map: one parchment page per "floor" (20 m of height) in each biome, 1 pixel = 1 meter.
- src/ui/map_data.gd:1 MapData
- src/ui/map_data.gd:22 _init
- src/ui/map_data.gd:33 floors_at
- src/ui/map_data.gd:37 center_x
- src/ui/map_data.gd:44 floor_count
- src/ui/map_data.gd:48 floor_of
- src/ui/map_data.gd:53 to_pixel
- src/ui/map_data.gd:59 reveal
- src/ui/map_data.gd:90 to_data
- src/ui/map_data.gd:100 load_data
- src/ui/map_data.gd:113 seen_fraction

## src/ui/map_panel.gd (132 lines) — The map screen (M). Shows one floor page at a time; arrows flip floors.
- src/ui/map_panel.gd:1 MapPanel
- src/ui/map_panel.gd:21 _ready
- src/ui/map_panel.gd:91 open
- src/ui/map_panel.gd:100 show_floor
- src/ui/map_panel.gd:115 _draw_marks

## src/ui/perk_tree_view.gd (204 lines) — The perk tree in the middle of the skills window (owner, Nov 19-20; mock-up: claude.ai/artifact/MBTFW9LdXc4mA3
- src/ui/perk_tree_view.gd:1 PerkTreeView
- src/ui/perk_tree_view.gd:57 _ready
- src/ui/perk_tree_view.gd:91 _scale
- src/ui/perk_tree_view.gd:95 _center
- src/ui/perk_tree_view.gd:99 _gui_input
- src/ui/perk_tree_view.gd:120 _clamp_pan
- src/ui/perk_tree_view.gd:126 spot
- src/ui/perk_tree_view.gd:135 radius
- src/ui/perk_tree_view.gd:140 refresh
- src/ui/perk_tree_view.gd:154 _draw
- src/ui/perk_tree_view.gd:169 _draw_over

## src/ui/settings_panel.gd (108 lines) — The Settings panel (owner F187 mock-up): sound volume, mute, mouse speed and graphics (owner, Nov 19), remembe
- src/ui/settings_panel.gd:1 SettingsPanel
- src/ui/settings_panel.gd:8 _ready
- src/ui/settings_panel.gd:104 _row

## src/ui/skills_panel.gd (327 lines) — The K window, two tabs (owner, Nov 20, F445):
- src/ui/skills_panel.gd:1 SkillsPanel
- src/ui/skills_panel.gd:35 perk_icon
- src/ui/skills_panel.gd:40 _ready
- src/ui/skills_panel.gd:48 set_ui
- src/ui/skills_panel.gd:57 _px
- src/ui/skills_panel.gd:61 _lbl
- src/ui/skills_panel.gd:68 _build
- src/ui/skills_panel.gd:142 _framed
- src/ui/skills_panel.gd:152 show_tab
- src/ui/skills_panel.gd:166 _progress
- src/ui/skills_panel.gd:172 refresh
- src/ui/skills_panel.gd:200 _show_skills
- src/ui/skills_panel.gd:246 _wrap
- src/ui/skills_panel.gd:261 _show_detail

## src/ui/sound_settings.gd (50 lines) — Volume and mute (feedback F15) and mouse speed (F187), set on the Settings panel and remembered
- src/ui/sound_settings.gd:1 SoundSettings
- src/ui/sound_settings.gd:12 load_and_apply
- src/ui/sound_settings.gd:21 apply
- src/ui/sound_settings.gd:27 set_volume
- src/ui/sound_settings.gd:33 set_muted
- src/ui/sound_settings.gd:39 set_mouse_scale
- src/ui/sound_settings.gd:44 save

## src/ui/start_menu.gd (282 lines) — The first screen (F87): your saved worlds (play, host for friends, delete), a new world
- src/ui/start_menu.gd:29 _ready
- src/ui/start_menu.gd:127 _show_part
- src/ui/start_menu.gd:135 _fill_worlds
- src/ui/start_menu.gd:170 _open_world
- src/ui/start_menu.gd:182 ask_delete
- src/ui/start_menu.gd:190 _make_confirm
- src/ui/start_menu.gd:230 _unhandled_input
- src/ui/start_menu.gd:236 _delete_confirmed
- src/ui/start_menu.gd:244 set_status
- src/ui/start_menu.gd:249 _seed
- src/ui/start_menu.gd:253 _name
- src/ui/start_menu.gd:257 _field
- src/ui/start_menu.gd:266 _button
- src/ui/start_menu.gd:276 _gold

## src/ui/ui_kit.gd (187 lines) — The "dwarf workshop" look for every menu (owner F187): dark oak frames with iron brackets,
- src/ui/ui_kit.gd:1 UiKit
- src/ui/ui_kit.gd:30 heading_font
- src/ui/ui_kit.gd:41 style
- src/ui/ui_kit.gd:61 panel
- src/ui/ui_kit.gd:66 title
- src/ui/ui_kit.gd:80 label
- src/ui/ui_kit.gd:90 gold_button
- src/ui/ui_kit.gd:106 dark_button
- src/ui/ui_kit.gd:124 slider
- src/ui/ui_kit.gd:141 line_edit
- src/ui/ui_kit.gd:151 divider
- src/ui/ui_kit.gd:163 clear
- src/ui/ui_kit.gd:170 fit
- src/ui/ui_kit.gd:175 hearts

## src/ui/vital_dial.gd (117 lines) — A small round dial for hunger or thirst (F229): a bronze ring, and inside it a coloured
- src/ui/vital_dial.gd:18 _init
- src/ui/vital_dial.gd:34 _update_tip
- src/ui/vital_dial.gd:40 set_value
- src/ui/vital_dial.gd:48 _process
- src/ui/vital_dial.gd:54 _frac
- src/ui/vital_dial.gd:58 _fill_color
- src/ui/vital_dial.gd:62 _draw
- src/ui/vital_dial.gd:90 _draw_picture

## src/world/auto_smelt.gd (116 lines) — Furnaces that run themselves (feedback F32):
- src/world/auto_smelt.gd:1 AutoSmelt
- src/world/auto_smelt.gd:20 feed
- src/world/auto_smelt.gd:40 _has_job
- src/world/auto_smelt.gd:48 chests_near
- src/world/auto_smelt.gd:61 _count
- src/world/auto_smelt.gd:68 _take
- src/world/auto_smelt.gd:81 _fuel
- src/world/auto_smelt.gd:87 _start
- src/world/auto_smelt.gd:110 store

## src/world/cave_generator.gd (18 lines) — Hands Voxel Tools the blocks that the Cave Maker designs.
- src/world/cave_generator.gd:1 CaveGenerator
- src/world/cave_generator.gd:9 _init
- src/world/cave_generator.gd:13 _get_used_channels_mask
- src/world/cave_generator.gd:17 _generate_block

## src/world/cave_maker.gd (2731 lines) — Cave Maker: turns a seed number into a cave.
- src/world/cave_maker.gd:1 CaveMaker
- src/world/cave_maker.gd:60 _static_init
- src/world/cave_maker.gd:77 use_layout
- src/world/cave_maker.gd:176 _init
- src/world/cave_maker.gd:231 _lay_out
- src/world/cave_maker.gd:249 _add_column
- src/world/cave_maker.gd:264 _seg_inside_room
- src/world/cave_maker.gd:284 _plan_dungeons
- src/world/cave_maker.gd:300 _make_dungeon_only
- src/world/cave_maker.gd:318 _dungeon_sdf
- src/world/cave_maker.gd:326 in_dungeon_stone
- src/world/cave_maker.gd:333 _overlaps_dungeon
- src/world/cave_maker.gd:340 reserve
- src/world/cave_maker.gd:345 is_reserved
- src/world/cave_maker.gd:359 _reserve_tower
- src/world/cave_maker.gd:394 _plan_cavern_columns
- src/world/cave_maker.gd:445 _plan_columns
- src/world/cave_maker.gd:472 _column_fits
- src/world/cave_maker.gd:498 _in_column
- src/world/cave_maker.gd:517 _plan_bridges
- src/world/cave_maker.gd:587 _plan_bridges_v11
- src/world/cave_maker.gd:680 _over_tower_ground
- src/world/cave_maker.gd:691 _first_cave_bridge
- src/world/cave_maker.gd:731 _bridge_has_room
- src/world/cave_maker.gd:748 guide_points
- src/world/cave_maker.gd:781 _rel
- src/world/cave_maker.gd:786 _leads_on
- src/world/cave_maker.gd:807 on_bridge
- src/world/cave_maker.gd:814 _bridge_blocks
- src/world/cave_maker.gd:842 _add_bridge
- src/world/cave_maker.gd:856 _bridge_dist
- src/world/cave_maker.gd:873 _bridges_min
- src/world/cave_maker.gd:883 _with_columns
- src/world/cave_maker.gd:906 _plan_colonnades
- src/world/cave_maker.gd:951 _plan_start
- src/world/cave_maker.gd:1009 _start_fits
- src/world/cave_maker.gd:1034 _place_start_things
- src/world/cave_maker.gd:1075 _start_dist
- src/world/cave_maker.gd:1088 _capsule_dist
- src/world/cave_maker.gd:1096 _near_start
- src/world/cave_maker.gd:1104 _start_overlaps
- src/world/cave_maker.gd:1109 in_start_plug
- src/world/cave_maker.gd:1123 _setup_noise
- src/world/cave_maker.gd:1171 _place_rooms
- src/world/cave_maker.gd:1191 _count_big
- src/world/cave_maker.gd:1199 _far_from_rooms
- src/world/cave_maker.gd:1209 _connect_rooms
- src/world/cave_maker.gd:1257 _dig_gates
- src/world/cave_maker.gd:1288 _nearest_room
- src/world/cave_maker.gd:1305 mouth
- src/world/cave_maker.gd:1311 _dig_worm
- src/world/cave_maker.gd:1327 _clamp_inside
- src/world/cave_maker.gd:1364 _place_rooms_v2
- src/world/cave_maker.gd:1417 _clear_of_first
- src/world/cave_maker.gd:1425 huge_first
- src/world/cave_maker.gd:1432 star_room
- src/world/cave_maker.gd:1443 quiet_room
- src/world/cave_maker.gd:1450 first_cavern
- src/world/cave_maker.gd:1463 _set_proportions
- src/world/cave_maker.gd:1511 _reshape
- src/world/cave_maker.gd:1529 _is_tall
- src/world/cave_maker.gd:1535 _cliff_mouth
- src/world/cave_maker.gd:1547 _dig_ledge
- src/world/cave_maker.gd:1571 _link_cost
- src/world/cave_maker.gd:1575 _connect_rooms_v2
- src/world/cave_maker.gd:1643 _dig_passage
- src/world/cave_maker.gd:1683 _pick_kind
- src/world/cave_maker.gd:1697 _kind_size
- src/world/cave_maker.gd:1713 _dig_worm_v2
- src/world/cave_maker.gd:1739 _trim_in_rooms
- src/world/cave_maker.gd:1761 _deep_inside
- src/world/cave_maker.gd:1769 _assign_shapes
- src/world/cave_maker.gd:1792 _sdf_with_v2
- src/world/cave_maker.gd:1840 _room_dist_v2
- src/world/cave_maker.gd:1863 _fallen_block
- src/world/cave_maker.gd:1878 _seg_shape
- src/world/cave_maker.gd:1912 _bake_shapes
- src/world/cave_maker.gd:1959 _grid_add
- src/world/cave_maker.gd:1972 _find_spawn
- src/world/cave_maker.gd:1978 find_floor
- src/world/cave_maker.gd:1989 _plan_pois
- src/world/cave_maker.gd:2102 _ramp_high_holes
- src/world/cave_maker.gd:2141 _dig_ramp
- src/world/cave_maker.gd:2156 _add_poi
- src/world/cave_maker.gd:2160 _far_from_pois
- src/world/cave_maker.gd:2171 _solid_around
- src/world/cave_maker.gd:2183 pois_of
- src/world/cave_maker.gd:2188 biome_at
- src/world/cave_maker.gd:2216 block_value
- src/world/cave_maker.gd:2226 _hash01
- src/world/cave_maker.gd:2233 _corner
- src/world/cave_maker.gd:2246 sdf_at
- src/world/cave_maker.gd:2266 _smooth_at
- src/world/cave_maker.gd:2279 material_at
- src/world/cave_maker.gd:2306 _wall_rock
- src/world/cave_maker.gd:2314 _sdf_with
- src/world/cave_maker.gd:2352 _wall_bumps
- src/world/cave_maker.gd:2365 march_slack
- src/world/cave_maker.gd:2374 _rock_detail
- src/world/cave_maker.gd:2386 _ledge
- src/world/cave_maker.gd:2394 _floor_guard
- src/world/cave_maker.gd:2407 rockiness_at
- src/world/cave_maker.gd:2412 gate_free_z
- src/world/cave_maker.gd:2425 _room_dist
- src/world/cave_maker.gd:2434 _seg_dist
- src/world/cave_maker.gd:2446 _region_dist
- src/world/cave_maker.gd:2456 _gate_dist
- src/world/cave_maker.gd:2465 _smin
- src/world/cave_maker.gd:2471 _is_clay
- src/world/cave_maker.gd:2476 _is_patch
- src/world/cave_maker.gd:2484 _pick_deeps
- src/world/cave_maker.gd:2504 in_deeps
- src/world/cave_maker.gd:2511 _is_ore
- src/world/cave_maker.gd:2526 generate_block
- src/world/cave_maker.gd:2648 _coarse_sdf
- src/world/cave_maker.gd:2701 _block_inside_a_biome
- src/world/cave_maker.gd:2710 _fill_ore
- src/world/cave_maker.gd:2720 _fill_border
- src/world/cave_maker.gd:2729 _overlaps

## src/world/dungeon_build.gd (1416 lines) — Builds a dungeon's insides in the game (owner, Nov 19): the root wood floors, walls, ceilings and doorways, th
- src/world/dungeon_build.gd:1 DungeonBuild
- src/world/dungeon_build.gd:187 ladder_at
- src/world/dungeon_build.gd:195 load_plan
- src/world/dungeon_build.gd:205 thing_kind
- src/world/dungeon_build.gd:233 _xform
- src/world/dungeon_build.gd:240 placements
- src/world/dungeon_build.gd:260 _ready
- src/world/dungeon_build.gd:285 _hook
- src/world/dungeon_build.gd:307 place_lootables
- src/world/dungeon_build.gd:316 _exit_tree
- src/world/dungeon_build.gd:321 _build
- src/world/dungeon_build.gd:381 _build_things
- src/world/dungeon_build.gd:425 _scene
- src/world/dungeon_build.gd:434 _own_mesh
- src/world/dungeon_build.gd:446 add_boxes
- src/world/dungeon_build.gd:450 _add_boxes
- src/world/dungeon_build.gd:464 _is_flat_junk
- src/world/dungeon_build.gd:468 _rel_xform
- src/world/dungeon_build.gd:479 id_of
- src/world/dungeon_build.gd:488 ask_hit
- src/world/dungeon_build.gd:499 _rpc_hit
- src/world/dungeon_build.gd:508 request_hit
- src/world/dungeon_build.gd:558 _break
- src/world/dungeon_build.gd:570 is_broken
- src/world/dungeon_build.gd:576 _ev_hit
- src/world/dungeon_build.gd:588 _ev_broke
- src/world/dungeon_build.gd:623 _hide
- src/world/dungeon_build.gd:642 _tumble
- src/world/dungeon_build.gd:674 _free_later
- src/world/dungeon_build.gd:685 _topple
- src/world/dungeon_build.gd:732 _apply_broken
- src/world/dungeon_build.gd:747 _fall
- src/world/dungeon_build.gd:760 _drip_lands
- src/world/dungeon_build.gd:776 drip_damage
- src/world/dungeon_build.gd:787 _drop_drip
- src/world/dungeon_build.gd:814 _parts
- src/world/dungeon_build.gd:824 _physics_process
- src/world/dungeon_build.gd:878 _traps_hit_creatures
- src/world/dungeon_build.gd:900 near_crusher
- src/world/dungeon_build.gd:909 _under_crusher
- src/world/dungeon_build.gd:926 _check_deadly_drop
- src/world/dungeon_build.gd:939 drip_time
- src/world/dungeon_build.gd:944 drip_warn
- src/world/dungeon_build.gd:948 drip_fall
- src/world/dungeon_build.gd:953 _check_heal
- src/world/dungeon_build.gd:992 basin_key
- src/world/dungeon_build.gd:999 _make_crusher
- src/world/dungeon_build.gd:1024 crush_down
- src/world/dungeon_build.gd:1037 crushing
- src/world/dungeon_build.gd:1043 crushers_awake
- src/world/dungeon_build.gd:1051 _check_crushers_wake
- src/world/dungeon_build.gd:1062 set_crushers_awake
- src/world/dungeon_build.gd:1080 _move_crusher
- src/world/dungeon_build.gd:1113 list_id
- src/world/dungeon_build.gd:1117 is_door_open
- src/world/dungeon_build.gd:1124 _on_dungeon_room
- src/world/dungeon_build.gd:1140 _sync_doors
- src/world/dungeon_build.gd:1165 is_gate_open
- src/world/dungeon_build.gd:1171 opened_by_hand
- src/world/dungeon_build.gd:1177 use_info
- src/world/dungeon_build.gd:1192 ask_use
- src/world/dungeon_build.gd:1207 _rpc_use
- src/world/dungeon_build.gd:1215 request_use
- src/world/dungeon_build.gd:1235 _ev_hand_door
- src/world/dungeon_build.gd:1246 _on_gate_changed
- src/world/dungeon_build.gd:1262 _pull_lever
- src/world/dungeon_build.gd:1280 _on_door_changed
- src/world/dungeon_build.gd:1292 _open_door
- src/world/dungeon_build.gd:1314 _close_door
- src/world/dungeon_build.gd:1327 deadly_space
- src/world/dungeon_build.gd:1343 show_scroll
- src/world/dungeon_build.gd:1396 add_chests

## src/world/dungeon_keys.gd (256 lines) — Keys and locked round doors of the medium and big Zone 1 dungeons (owner, Nov 20, F237; key names from
- src/world/dungeon_keys.gd:1 DungeonKeys
- src/world/dungeon_keys.gd:50 _ready
- src/world/dungeon_keys.gd:54 _process
- src/world/dungeon_keys.gd:63 keys_of
- src/world/dungeon_keys.gd:68 item_data
- src/world/dungeon_keys.gd:77 add_door
- src/world/dungeon_keys.gd:82 locks_of
- src/world/dungeon_keys.gd:87 is_open
- src/world/dungeon_keys.gd:93 set_lock
- src/world/dungeon_keys.gd:105 boss_has_key
- src/world/dungeon_keys.gd:110 drop_key
- src/world/dungeon_keys.gd:123 ask_unlock
- src/world/dungeon_keys.gd:131 _rpc_unlock
- src/world/dungeon_keys.gd:138 request_unlock
- src/world/dungeon_keys.gd:160 _ev_door
- src/world/dungeon_keys.gd:169 add_gate
- src/world/dungeon_keys.gd:173 gate_open
- src/world/dungeon_keys.gd:177 ask_pull_lever
- src/world/dungeon_keys.gd:185 _rpc_pull_lever
- src/world/dungeon_keys.gd:192 request_pull_lever
- src/world/dungeon_keys.gd:206 _ev_gate
- src/world/dungeon_keys.gd:219 tick
- src/world/dungeon_keys.gd:238 _take_back
- src/world/dungeon_keys.gd:252 _someone_near

## src/world/dungeon_list.gd (42 lines) — The 12 dungeons of Zone 1 (owner, Nov 20, F237; docs/design/zone1-dungeons/). Only the list: placing and build
- src/world/dungeon_list.gd:1 DungeonList
- src/world/dungeon_list.gd:29 get_dungeon
- src/world/dungeon_list.gd:37 recipe_of

## src/world/dungeon_loot.gd (61 lines) — Dungeon chests that fill up again (owner, Nov 19, F237; docs/design/zone1-dungeons-plan.md). An hour of play a
- src/world/dungeon_loot.gd:1 DungeonLoot
- src/world/dungeon_loot.gd:12 add
- src/world/dungeon_loot.gd:21 tick
- src/world/dungeon_loot.gd:43 _someone_near
- src/world/dungeon_loot.gd:52 recipes_for

## src/world/dungeon_map.gd (380 lines) — Dungeons dug into solid rock (owner, Nov 19, 2026: docs/decisions/2026-11-19-dungeons.md).
- src/world/dungeon_map.gd:1 DungeonMap
- src/world/dungeon_map.gd:147 place
- src/world/dungeon_map.gd:182 mouth_z
- src/world/dungeon_map.gd:187 to_local
- src/world/dungeon_map.gd:193 to_world
- src/world/dungeon_map.gd:198 near_box
- src/world/dungeon_map.gd:207 sdf
- src/world/dungeon_map.gd:218 covers
- src/world/dungeon_map.gd:223 space_at
- src/world/dungeon_map.gd:234 space_floor
- src/world/dungeon_map.gd:242 _box_in
- src/world/dungeon_map.gd:255 find_spot
- src/world/dungeon_map.gd:282 _clear_of_dungeons
- src/world/dungeon_map.gd:298 _try

## src/world/dungeon_places.gd (125 lines) — Where the 12 Zone 1 dungeons (DungeonList) sit in a world (owner, Nov 20, F237). Only the world seed (through 
- src/world/dungeon_places.gd:1 DungeonPlaces
- src/world/dungeon_places.gd:24 pick
- src/world/dungeon_places.gd:43 reserve_all
- src/world/dungeon_places.gd:50 _find
- src/world/dungeon_places.gd:86 middle
- src/world/dungeon_places.gd:91 _clear
- src/world/dungeon_places.gd:110 _solid
- src/world/dungeon_places.gd:124 _flat

## src/world/dungeon_variety.gd (40 lines) — Same dungeon, a bit different in each world (owner, Nov 20, F237; docs/design/zone1-dungeons/traps-and-variety
- src/world/dungeon_variety.gd:1 DungeonVariety
- src/world/dungeon_variety.gd:19 pick
- src/world/dungeon_variety.gd:37 _rng

## src/world/glow_field.gd (688 lines) — Shows the glowing crystals and mushrooms that the Glow Placer picked.
- src/world/glow_field.gd:1 GlowField
- src/world/glow_field.gd:37 build
- src/world/glow_field.gd:62 get_spot
- src/world/glow_field.gd:66 spot_count
- src/world/glow_field.gd:70 spots_near
- src/world/glow_field.gd:84 _cell
- src/world/glow_field.gd:88 _grid_add
- src/world/glow_field.gd:96 set_chops
- src/world/glow_field.gd:113 restore_spot
- src/world/glow_field.gd:130 remove_spot
- src/world/glow_field.gd:145 id_of
- src/world/glow_field.gd:151 _add_node
- src/world/glow_field.gd:231 _add_solid
- src/world/glow_field.gd:267 _model_of
- src/world/glow_field.gd:280 _cave_mesh
- src/world/glow_field.gd:305 _tint_glow_parts
- src/world/glow_field.gd:349 _bend_mushroom
- src/world/glow_field.gd:379 _push_mushrooms
- src/world/glow_field.gd:394 _add_drip
- src/world/glow_field.gd:430 _surface_of
- src/world/glow_field.gd:438 _material_for
- src/world/glow_field.gd:453 crystal_pulse
- src/world/glow_field.gd:463 _process
- src/world/glow_field.gd:529 _giant_mesh
- src/world/glow_field.gd:563 _make_crystal_mesh
- src/world/glow_field.gd:581 _make_mushroom_mesh
- src/world/glow_field.gd:606 _make_twig_mesh
- src/world/glow_field.gd:626 _make_fiber_mesh
- src/world/glow_field.gd:647 _make_root_mesh
- src/world/glow_field.gd:664 _root_tube

## src/world/glow_placer.gd (644 lines) — Glow Placer: picks spots on cave surfaces for things you can harvest:
- src/world/glow_placer.gd:1 GlowPlacer
- src/world/glow_placer.gd:56 place
- src/world/glow_placer.gd:66 _place
- src/world/glow_placer.gd:138 _add_bridge_roots
- src/world/glow_placer.gd:177 _add_low_crystals
- src/world/glow_placer.gd:220 _add_more_roots
- src/world/glow_placer.gd:252 _mix_crystal_colours
- src/world/glow_placer.gd:268 _thin_crystals_under_stars
- src/world/glow_placer.gd:287 star_patch
- src/world/glow_placer.gd:291 _shader_hash
- src/world/glow_placer.gd:296 _vnoise
- src/world/glow_placer.gd:309 _add_twigs
- src/world/glow_placer.gd:339 _add_wood_everywhere
- src/world/glow_placer.gd:373 _move_roots_to_tunnels
- src/world/glow_placer.gd:427 _add_first_drip
- src/world/glow_placer.gd:456 _add_start_spots
- src/world/glow_placer.gd:481 _spaced
- src/world/glow_placer.gd:490 _grid_put
- src/world/glow_placer.gd:497 _spaced_grid
- src/world/glow_placer.gd:510 _add_spot
- src/world/glow_placer.gd:515 _random_dir
- src/world/glow_placer.gd:520 _try_add
- src/world/glow_placer.gd:561 size_boost
- src/world/glow_placer.gd:573 _solid_ground
- src/world/glow_placer.gd:580 _pick_kind
- src/world/glow_placer.gd:596 _pick_fungal
- src/world/glow_placer.gd:613 _march
- src/world/glow_placer.gd:626 normal_at
- src/world/glow_placer.gd:636 drip_near
- src/world/glow_placer.gd:643 is_plant

## src/world/loot_props.gd (261 lines) — Lootable decor (handover Nov 22, section 4): a coin chest, a charcoal bay, an ingot cart... You press E, you g
- src/world/loot_props.gd:1 LootProps
- src/world/loot_props.gd:65 _ready
- src/world/loot_props.gd:73 model_id
- src/world/loot_props.gd:78 is_lootable
- src/world/loot_props.gd:82 empty_model
- src/world/loot_props.gd:86 key_of
- src/world/loot_props.gd:92 is_looted
- src/world/loot_props.gd:98 place
- src/world/loot_props.gd:131 use_info
- src/world/loot_props.gd:141 ask_loot
- src/world/loot_props.gd:151 _rpc_loot
- src/world/loot_props.gd:158 request_loot
- src/world/loot_props.gd:186 _ev_looted
- src/world/loot_props.gd:191 _show_looted
- src/world/loot_props.gd:218 _process
- src/world/loot_props.gd:231 apply_looted
- src/world/loot_props.gd:241 place_ruin

## src/world/mat.gd (64 lines) — Rock materials. Each voxel stores one of these numbers.
- src/world/mat.gd:1 Mat
- src/world/mat.gd:47 hardness
- src/world/mat.gd:51 min_tier
- src/world/mat.gd:56 is_diggable
- src/world/mat.gd:61 hits_needed

## src/world/mine_traps.gd (1001 lines) — Lampwick Drift's mine traps and lamps (owner, Nov 20, F477; plan: docs/design/zone1-dungeons/02-lampwick-drift
- src/world/mine_traps.gd:1 MineTraps
- src/world/mine_traps.gd:94 kind_of
- src/world/mine_traps.gd:129 _ready
- src/world/mine_traps.gd:136 setup
- src/world/mine_traps.gd:213 show_spent
- src/world/mine_traps.gd:244 step
- src/world/mine_traps.gd:270 lit
- src/world/mine_traps.gd:275 _light
- src/world/mine_traps.gd:295 _ev_lamp
- src/world/mine_traps.gd:310 cart_xform
- src/world/mine_traps.gd:325 _place_cart
- src/world/mine_traps.gd:337 cart_distance
- src/world/mine_traps.gd:342 _run_cart
- src/world/mine_traps.gd:374 _release_cart
- src/world/mine_traps.gd:384 on_broke
- src/world/mine_traps.gd:425 swing_angle
- src/world/mine_traps.gd:429 _swing_pose
- src/world/mine_traps.gd:438 ball_at
- src/world/mine_traps.gd:442 _move_swing
- src/world/mine_traps.gd:474 _drop_swing
- src/world/mine_traps.gd:488 _shut_jaws
- src/world/mine_traps.gd:514 _ev_hold
- src/world/mine_traps.gd:525 _dart_of
- src/world/mine_traps.gd:539 dart_line
- src/world/mine_traps.gd:544 _fire_bolt
- src/world/mine_traps.gd:562 _trip
- src/world/mine_traps.gd:568 _fire_dart
- src/world/mine_traps.gd:588 _slam_spikes
- src/world/mine_traps.gd:601 on_spike_floor
- src/world/mine_traps.gd:606 _fire_spikes
- src/world/mine_traps.gd:621 spikes_near
- src/world/mine_traps.gd:632 on_hit
- src/world/mine_traps.gd:673 use_info
- src/world/mine_traps.gd:688 request_use
- src/world/mine_traps.gd:722 host_check
- src/world/mine_traps.gd:768 _moving_box
- src/world/mine_traps.gd:787 spear_out
- src/world/mine_traps.gd:801 in_spears
- src/world/mine_traps.gd:807 _move_spears
- src/world/mine_traps.gd:836 _ev_push
- src/world/mine_traps.gd:846 push_out
- src/world/mine_traps.gd:862 in_push
- src/world/mine_traps.gd:869 _move_push
- src/world/mine_traps.gd:899 lift_up
- src/world/mine_traps.gd:903 _lift_state
- src/world/mine_traps.gd:912 lift_frac
- src/world/mine_traps.gd:918 lift_moving
- src/world/mine_traps.gd:923 lift_pos
- src/world/mine_traps.gd:931 lift_of
- src/world/mine_traps.gd:947 lift_end_near
- src/world/mine_traps.gd:956 send_lift
- src/world/mine_traps.gd:972 _move_lift

## src/world/peephole.gd (71 lines) — The glowing crack in the starting room's soft wall (feedback F10): "something is glowing
- src/world/peephole.gd:1 Peephole
- src/world/peephole.gd:17 make
- src/world/peephole.gd:39 _ready
- src/world/peephole.gd:66 _process

## src/world/plan_cache.gd (66 lines) — Faster second load (owner, Nov 19; docs/research/Voxel game performance plan.md): working out where every crys
- src/world/plan_cache.gd:1 PlanCache
- src/world/plan_cache.gd:20 get_or_make
- src/world/plan_cache.gd:43 _path
- src/world/plan_cache.gd:48 _fingerprint
- src/world/plan_cache.gd:62 _clean_old

## src/world/poi_field.gd (305 lines) — Shows the special places the Cave Maker planned (world doc 3.1): ruins, camps, rune
- src/world/poi_field.gd:1 PoiField
- src/world/poi_field.gd:21 build
- src/world/poi_field.gd:44 _ground_shrine
- src/world/poi_field.gd:57 poi_id_of
- src/world/poi_field.gd:64 set_taken
- src/world/poi_field.gd:70 _make
- src/world/poi_field.gd:145 _col
- src/world/poi_field.gd:157 column_id_of
- src/world/poi_field.gd:163 column
- src/world/poi_field.gd:169 column_middle
- src/world/poi_field.gd:177 set_column_broken
- src/world/poi_field.gd:193 _settle_column
- src/world/poi_field.gd:222 _on_rock_changed
- src/world/poi_field.gd:236 _rng_for
- src/world/poi_field.gd:243 _on_floor
- src/world/poi_field.gd:249 _label
- src/world/poi_field.gd:262 _shape
- src/world/poi_field.gd:271 _part
- src/world/poi_field.gd:280 _mat
- src/world/poi_field.gd:284 _box
- src/world/poi_field.gd:290 _cyl
- src/world/poi_field.gd:299 _sphere

## src/world/ruin_brewhall.gd (170 lines) — The Brewhall (owner, Nov 20, F479): the third ruin, an old dwarf tavern and brewery in clay brick, in a plain 
- src/world/ruin_brewhall.gd:1 RuinBrewhall
- src/world/ruin_brewhall.gd:26 pick_room
- src/world/ruin_brewhall.gd:44 pick
- src/world/ruin_brewhall.gd:85 _init
- src/world/ruin_brewhall.gd:97 _chest_spots
- src/world/ruin_brewhall.gd:101 _path_z
- src/world/ruin_brewhall.gd:105 _ready
- src/world/ruin_brewhall.gd:150 _process

## src/world/ruin_junk.gd (194 lines) — Ruin junk (owner, Nov 20): small things "just for looks" in and around the ruins, hugging their walls. Decorat
- src/world/ruin_junk.gd:1 RuinJunk
- src/world/ruin_junk.gd:23 _init
- src/world/ruin_junk.gd:28 _ready
- src/world/ruin_junk.gd:32 _exit_tree
- src/world/ruin_junk.gd:37 junk_file
- src/world/ruin_junk.gd:41 load_list
- src/world/ruin_junk.gd:51 world_list
- src/world/ruin_junk.gd:67 floor_at
- src/world/ruin_junk.gd:81 _column_floor
- src/world/ruin_junk.gd:95 _process
- src/world/ruin_junk.gd:116 _make_missing
- src/world/ruin_junk.gd:138 _draw

## src/world/ruin_kit.gd (145 lines) — Carved dwarf stonework for ruins and halls (feedback F9/F21: "columns should look better,
- src/world/ruin_kit.gd:1 RuinKit
- src/world/ruin_kit.gd:17 column
- src/world/ruin_kit.gd:97 broken_wall
- src/world/ruin_kit.gd:123 _mesh
- src/world/ruin_kit.gd:132 _box
- src/world/ruin_kit.gd:138 _cyl

## src/world/ruin_outpost.gd (193 lines) — The Fallen Outpost (owner, Nov 17): the big ruined stone fort, in a plain big cavern of Mossy Hollows about
- src/world/ruin_outpost.gd:1 RuinOutpost
- src/world/ruin_outpost.gd:22 pick_room
- src/world/ruin_outpost.gd:38 pick
- src/world/ruin_outpost.gd:79 _init
- src/world/ruin_outpost.gd:90 _chest_spots
- src/world/ruin_outpost.gd:94 _path_z
- src/world/ruin_outpost.gd:98 _ready
- src/world/ruin_outpost.gd:144 _has_chest
- src/world/ruin_outpost.gd:158 _process

## src/world/ruin_spire.gd (301 lines) — The Lantern Spire (owner, Nov 20, F479): the fourth ruin, a tall thin round Stonehold beacon tower whose top h
- src/world/ruin_spire.gd:1 RuinSpire
- src/world/ruin_spire.gd:30 rooms_to_try
- src/world/ruin_spire.gd:52 wreck_feet
- src/world/ruin_spire.gd:68 wreck_spots
- src/world/ruin_spire.gd:80 ground_under
- src/world/ruin_spire.gd:92 door_is_open
- src/world/ruin_spire.gd:108 pick
- src/world/ruin_spire.gd:191 _init
- src/world/ruin_spire.gd:203 _chest_spots
- src/world/ruin_spire.gd:208 _ready
- src/world/ruin_spire.gd:268 _lay_wreckage
- src/world/ruin_spire.gd:281 _process

## src/world/ruin_tower.gd (276 lines) — The ruined Stone Watchtower in the first cave of a new world (owner, Nov 17, F254): the first stone place to
- src/world/ruin_tower.gd:1 RuinTower
- src/world/ruin_tower.gd:39 add_missing_chest
- src/world/ruin_tower.gd:51 load_plan
- src/world/ruin_tower.gd:61 find_spot
- src/world/ruin_tower.gd:102 _init
- src/world/ruin_tower.gd:107 _ready
- src/world/ruin_tower.gd:141 _process
- src/world/ruin_tower.gd:170 _floor_at
- src/world/ruin_tower.gd:174 _build
- src/world/ruin_tower.gd:220 _tower_here
- src/world/ruin_tower.gd:244 _add_rebuild_chest
- src/world/ruin_tower.gd:269 _chest_spots
- src/world/ruin_tower.gd:275 _path_z

## src/world/station.gd (530 lines) — A crafting station placed in the world (campfire, workbench, smelter, ...).
- src/world/station.gd:1 Station
- src/world/station.gd:30 can_plant
- src/world/station.gd:55 on_fire_spot
- src/world/station.gd:68 fire_under
- src/world/station.gd:76 helps_kind
- src/world/station.gd:84 station_type
- src/world/station.gd:88 level
- src/world/station.gd:92 max_level
- src/world/station.gd:97 next_extra
- src/world/station.gd:105 _extras_near
- src/world/station.gd:116 _process
- src/world/station.gd:131 _ready
- src/world/station.gd:147 can_queue
- src/world/station.gd:151 queue_job
- src/world/station.gd:157 tick
- src/world/station.gd:173 tick_water
- src/world/station.gd:185 crop_ripe
- src/world/station.gd:189 set_crop
- src/world/station.gd:197 farm_text
- src/world/station.gd:206 _show_crop
- src/world/station.gd:236 set_water
- src/world/station.gd:243 busy_text
- src/world/station.gd:249 _size
- src/world/station.gd:258 scale_of
- src/world/station.gd:263 size_of
- src/world/station.gd:270 in_rock
- src/world/station.gd:285 _base_size
- src/world/station.gd:313 _add_fire
- src/world/station.gd:328 _build_look
- src/world/station.gd:487 _add_label
- src/world/station.gd:502 _part
- src/world/station.gd:511 _sphere_mesh
- src/world/station.gd:518 _box
- src/world/station.gd:524 _cyl

## src/world/world.gd (282 lines) — World: holds the dig-anywhere terrain (Voxel Tools) and changes it.
- src/world/world.gd:1 World
- src/world/world.gd:20 setup
- src/world/world.gd:63 is_ready_at
- src/world/world.gd:69 material_at
- src/world/world.gd:77 sdf_at
- src/world/world.gd:84 apply_fill
- src/world/world.gd:116 sdf_smooth
- src/world/world.gd:129 rock_material_near
- src/world/world.gd:148 _material_of
- src/world/world.gd:164 apply_dig
- src/world/world.gd:198 remove_voxels
- src/world/world.gd:229 copy_area
- src/world/world.gd:246 _process
- src/world/world.gd:272 _send_guides

## tests/run_tests.gd (83 lines) — Counts every engine/script error, so a crashing check can't sneak through as PASS.
- tests/run_tests.gd:5 ErrorCounter
- tests/run_tests.gd:26 _initialize
- tests/run_tests.gd:30 _run

## tests/test_ailments.gd (89 lines) — Poison, burn and chill on a dwarf (combat doc 2.6).
- tests/test_ailments.gd:5 test_buildup_tips_over_into_poison
- tests/test_ailments.gd:17 test_poison_stacks_up_to_3_and_fire_is_a_short_burst
- tests/test_ailments.gd:35 test_buildup_drains_when_quiet
- tests/test_ailments.gd:45 test_chill_stacks_freeze_and_fire_cancels_chill
- tests/test_ailments.gd:59 test_vitals_take_poison_damage_and_respawn_clears
- tests/test_ailments.gd:69 test_jungle_attacks_poison
- tests/test_ailments.gd:75 test_badges_above_the_health_bar

## tests/test_aim_camera.gd (67 lines) — F452 (owner, Nov 20): "when I aim, I'm looking at his head, not to the right shoulder a little bit".
- tests/test_aim_camera.gd:6 _room
- tests/test_aim_camera.gd:22 _crosshair_at_dwarf
- tests/test_aim_camera.gd:32 test_aiming_looks_past_the_right_shoulder

## tests/test_authority.gd (878 lines) — Checks the referee (request → approve → everyone updates) with a real cave.
- tests/test_authority.gd:11 _setup
- tests/test_authority.gd:48 _teardown
- tests/test_authority.gd:53 _find_rock
- tests/test_authority.gd:66 test_stone_takes_three_hits_and_drops_stone
- tests/test_authority.gd:86 test_bare_hands_dig_stone_slowly
- tests/test_authority.gd:105 test_dirt_is_one_hit_moss_two
- tests/test_authority.gd:118 test_border_rock_is_blocked
- tests/test_authority.gd:127 test_needs_pickaxe_selected
- tests/test_authority.gd:139 test_too_far_is_refused
- tests/test_authority.gd:146 test_pickup_puts_items_in_bag
- tests/test_authority.gd:160 test_lantern_bearer_reaches_further
- tests/test_authority.gd:175 test_lantern_refill_uses_a_crystal
- tests/test_authority.gd:187 test_fuel_burns_down_but_not_below_zero
- tests/test_authority.gd:195 test_breaking_glow_crystal_gives_crystals
- tests/test_authority.gd:208 _first_spot
- tests/test_authority.gd:215 test_roots_give_wood_four_times
- tests/test_authority.gd:235 test_axe_beats_pickaxe_on_wood
- tests/test_authority.gd:251 test_mushrooms_by_hand
- tests/test_authority.gd:261 _slot_of
- tests/test_authority.gd:268 test_eat_from_hotbar
- tests/test_authority.gd:280 test_waterskin_has_five_sips
- tests/test_authority.gd:292 test_craft_campfire_and_place_it
- tests/test_authority.gd:310 test_smelter_takes_time_and_fuel
- tests/test_authority.gd:331 test_digging_gives_mining_xp
- tests/test_authority.gd:341 test_unknown_player_is_ignored
- tests/test_authority.gd:349 test_copper_needs_the_fang_pickaxe
- tests/test_authority.gd:358 test_same_hotbar_number_puts_the_tool_away
- tests/test_authority.gd:376 test_lantern_put_away_uses_no_fuel
- tests/test_authority.gd:391 test_digging_up_ahead_leaves_a_ramp
- tests/test_authority.gd:413 test_station_in_the_wall_is_refused
- tests/test_authority.gd:429 test_masons_shovel_levels_the_ground
- tests/test_authority.gd:459 test_every_hit_pays
- tests/test_authority.gd:476 test_hanging_roots_break
- tests/test_authority.gd:498 test_root_pillar_chops
- tests/test_authority.gd:519 test_root_tree_cracks_and_replants
- tests/test_authority.gd:572 test_boulder_breaks_and_comes_back
- tests/test_authority.gd:599 test_charging_beetle_smash_gives_all_the_stone
- tests/test_authority.gd:620 _stone_on_floor
- tests/test_authority.gd:629 test_boulder_drops_when_dug_under
- tests/test_authority.gd:678 test_root_tree_is_solid_outside
- tests/test_authority.gd:706 test_root_tree_regrows_from_both_ends
- tests/test_authority.gd:740 test_floor_things_are_put_down_on_the_real_rock
- tests/test_authority.gd:778 test_running_jumping_and_shield_xp_are_checked_by_the_host
- tests/test_authority.gd:792 test_active_perks_need_the_perk_and_recharge
- tests/test_authority.gd:810 test_perk_reset_costs_gold
- tests/test_authority.gd:822 test_toughness_perks_on_the_body
- tests/test_authority.gd:836 test_skills_window_shows_perk_pictures
- tests/test_authority.gd:852 test_crafting_makes_missing_planks_first
- tests/test_authority.gd:865 test_pot_on_the_fire_makes_a_kitchen

## tests/test_auto_smelt.gd (98 lines) — Kiln and smelters that run by themselves from nearby chests (feedback F32).
- tests/test_auto_smelt.gd:7 _setup
- tests/test_auto_smelt.gd:18 _teardown
- tests/test_auto_smelt.gd:22 test_kiln_turns_chest_wood_into_coal
- tests/test_auto_smelt.gd:40 test_smelter_takes_ore_from_the_ore_crate
- tests/test_auto_smelt.gd:57 test_twin_smelter_smelts_and_makes_coal
- tests/test_auto_smelt.gd:71 test_coal_is_fuel
- tests/test_auto_smelt.gd:77 test_ore_crate_looks_fuller
- tests/test_auto_smelt.gd:95 test_builders_chest_takes_decor_extras

## tests/test_barrels.gd (13 lines) — Owner, Nov 17 ("I want to live in the first tower"): barrels hold things (one row), chests two rows, stone che
- tests/test_barrels.gd:5 test_rows
- tests/test_barrels.gd:11 test_barrel_can_be_made_and_placed

## tests/test_blueprint.gd (75 lines) — Blueprints: capture, save, load (with the safety checks), and turning.
- tests/test_blueprint.gd:7 _hut
- tests/test_blueprint.gd:17 test_capture_and_cost
- tests/test_blueprint.gd:26 test_json_round_trip
- tests/test_blueprint.gd:37 test_bad_files_are_refused
- tests/test_blueprint.gd:60 test_turning_a_blueprint
- tests/test_blueprint.gd:70 test_starter_blueprint_file_loads

## tests/test_blueprint_library.gd (80 lines) — The 4 ready-made blueprints (building polish spec §7).
- tests/test_blueprint_library.gd:5 test_four_blueprints_exist
- tests/test_blueprint_library.gd:11 test_every_piece_is_real_and_inside_the_box
- tests/test_blueprint_library.gd:23 test_no_two_pieces_overlap
- tests/test_blueprint_library.gd:34 test_everything_stands_up
- tests/test_blueprint_library.gd:50 test_json_round_trip
- tests/test_blueprint_library.gd:59 test_homestead_carves_its_rooms
- tests/test_blueprint_library.gd:65 test_starter_hut_known_from_the_start

## tests/test_build_geometry.gd (252 lines) — Building geometry (owner's test list, Nov 15): 60° triangles, snapping edge to edge, no gaps,
- tests/test_build_geometry.gd:8 _edge_pts
- tests/test_build_geometry.gd:17 _share_side
- tests/test_build_geometry.gd:26 test_triangle_is_equilateral
- tests/test_build_geometry.gd:39 test_triangle_snaps_onto_a_square_side
- tests/test_build_geometry.gd:52 test_six_triangles_make_a_hexagon
- tests/test_build_geometry.gd:87 test_walls_stand_on_triangle_edges
- tests/test_build_geometry.gd:110 test_squares_join_with_no_gaps
- tests/test_build_geometry.gd:123 test_triangles_stack_and_take_pillars
- tests/test_build_geometry.gd:135 test_old_saves_still_load
- tests/test_build_geometry.gd:147 test_code_shapes_sit_on_their_base
- tests/test_build_geometry.gd:168 floating_islands
- tests/test_build_geometry.gd:172 test_code_shapes_have_no_floating_bits
- tests/test_build_geometry.gd:186 test_hand_made_models_fit_and_hold_together
- tests/test_build_geometry.gd:232 test_removing_a_support

## tests/test_build_menu.gd (122 lines) — Build menu tabs, the blueprint book and where a blueprint's chest goes (building polish B5).
- tests/test_build_menu.gd:5 test_every_piece_is_on_a_tab
- tests/test_build_menu.gd:16 test_blueprint_book_has_the_ready_made_buildings
- tests/test_build_menu.gd:33 test_chest_goes_on_the_open_side_nearest_you
- tests/test_build_menu.gd:50 test_steadiness_words
- tests/test_build_menu.gd:58 test_menu_refill_does_not_grow
- tests/test_build_menu.gd:77 test_q_and_e_turn_the_piece_walking_does_not
- tests/test_build_menu.gd:118 test_take_down_text_says_how

## tests/test_builder.gd (464 lines) — Building and cave-ins in the real cave, through the referee.
- tests/test_builder.gd:10 _setup
- tests/test_builder.gd:39 _teardown
- tests/test_builder.gd:45 _floor_spot
- tests/test_builder.gd:57 test_needs_a_workbench_and_materials
- tests/test_builder.gd:76 test_soft_collapse_warns_then_tumbles
- tests/test_builder.gd:108 test_propped_up_in_time_is_saved
- tests/test_builder.gd:125 test_station_levels_unlock_pieces
- tests/test_builder.gd:150 test_pick_up_right_after_placing_or_break_for_half
- tests/test_builder.gd:177 test_cant_build_inside_rock
- tests/test_builder.gd:186 test_normal_digging_no_cave_in
- tests/test_builder.gd:203 test_cave_in_removes_rock_and_drops_rubble
- tests/test_builder.gd:219 test_mine_prop_marks_support
- tests/test_builder.gd:228 test_blueprint_builds_itself
- tests/test_builder.gd:279 _chest_spot
- tests/test_builder.gd:289 _work_by
- tests/test_builder.gd:298 test_dev_fill_builders_chest
- tests/test_builder.gd:330 test_doors_open_and_ladders_climb
- tests/test_builder.gd:365 test_falling_rocks_are_rock_shaped
- tests/test_builder.gd:376 test_blueprint_steps_go_floor_by_floor
- tests/test_builder.gd:397 test_fang_pickaxe_needs_workbench_level_2
- tests/test_builder.gd:412 test_furniture_beds_and_cupboards_do_something
- tests/test_builder.gd:434 test_floor_levels_the_ground_under_it

## tests/test_building.gd (132 lines) — Building pieces, snapping and stability (world doc section 5).
- tests/test_building.gd:7 test_costs
- tests/test_building.gd:17 test_snap_floor_to_grid
- tests/test_building.gd:22 test_snap_wall_to_edge
- tests/test_building.gd:32 test_inside_rock_is_refused
- tests/test_building.gd:39 test_ground_pieces_are_anchored
- tests/test_building.gd:45 test_foundation_legs_reach_the_ground
- tests/test_building.gd:64 test_wood_tower_and_bridge
- tests/test_building.gd:83 test_metal_reaches_further_than_stone
- tests/test_building.gd:97 test_overlap_blocks_duplicates
- tests/test_building.gd:107 test_removing_support_drops_the_rest
- tests/test_building.gd:117 test_room_under_the_stairs

## tests/test_case.gd (37 lines) — Base for auto-checks. Every method starting with "test_" is one check.
- tests/test_case.gd:1 TestCase
- tests/test_case.gd:9 check
- tests/test_case.gd:14 check_eq
- tests/test_case.gd:19 check_near
- tests/test_case.gd:25 frames
- tests/test_case.gd:32 first_item_slot

## tests/test_cave_floor.gd (212 lines) — The owner's cave-floor notes of Nov 19: F404 (a calmer floor), F405 (Root Trees in the starting cave),
- tests/test_cave_floor.gd:8 _maker
- tests/test_cave_floor.gd:17 test_floor_has_no_moss_grass_or_cave_roots
- tests/test_cave_floor.gd:41 test_wood_roots_only_in_tunnels
- tests/test_cave_floor.gd:60 test_pebbles_only_in_tunnels_and_spread
- tests/test_cave_floor.gd:92 test_roots_on_bridges
- tests/test_cave_floor.gd:104 test_few_boulders_by_the_walls
- tests/test_cave_floor.gd:137 test_starting_cave_has_two_root_trees
- tests/test_cave_floor.gd:159 test_crystals_grow_back
- tests/test_cave_floor.gd:172 test_swarms_finish_a_little_each_frame
- tests/test_cave_floor.gd:199 test_swarm_stays_above_the_floor

## tests/test_cave_ins.gd (111 lines) — The cave-in rules (world doc 6.5) on a hand-made block of voxels.
- tests/test_cave_ins.gd:8 _world
- tests/test_cave_ins.gd:19 _put
- tests/test_cave_ins.gd:24 _air_box
- tests/test_cave_ins.gd:31 _rock_ball
- tests/test_cave_ins.gd:40 _total
- tests/test_cave_ins.gd:47 test_normal_mining_never_falls
- tests/test_cave_ins.gd:56 test_loose_ball_falls
- tests/test_cave_ins.gd:65 test_ball_on_a_mine_prop_stays
- tests/test_cave_ins.gd:73 test_long_icicle_falls_short_one_stays
- tests/test_cave_ins.gd:87 test_thick_ledge_and_arch_stay
- tests/test_cave_ins.gd:105 test_border_rock_is_an_anchor

## tests/test_cave_layout2.gd (340 lines) — Cave layout 2 (F211, epic caves step 1): the old caves stay exactly the same, and the new ones are big, varied
- tests/test_cave_layout2.gd:8 test_old_caves_unchanged
- tests/test_cave_layout2.gd:56 test_columns_keep_out_of_the_tower
- tests/test_cave_layout2.gd:72 test_columns_in_big_caverns
- tests/test_cave_layout2.gd:106 test_rock_bridges
- tests/test_cave_layout2.gd:125 test_bridge_in_the_starting_cave
- tests/test_cave_layout2.gd:150 test_first_cavern_columns
- tests/test_cave_layout2.gd:169 test_huge_first_cavern
- tests/test_cave_layout2.gd:189 test_cavern_kinds_and_cliffs
- tests/test_cave_layout2.gd:221 test_new_caves_have_every_kind
- tests/test_cave_layout2.gd:242 test_new_passages_fit_a_dwarf
- tests/test_cave_layout2.gd:264 test_cave_checks_pass_in_old_layout
- tests/test_cave_layout2.gd:280 test_high_holes_have_ramps
- tests/test_cave_layout2.gd:300 test_more_places_in_new_caves
- tests/test_cave_layout2.gd:310 _v2
- tests/test_cave_layout2.gd:318 _fits
- tests/test_cave_layout2.gd:332 _fingerprint

## tests/test_cave_life.gd (121 lines) — Cave life (F188, src/art/cave_life.gd): moss, grass, small roots, lichen and ferns. Hand-built models that loa
- tests/test_cave_life.gd:6 test_models_load_with_their_pictures
- tests/test_cave_life.gd:22 test_moss_is_drawn_in_fuzz_layers
- tests/test_cave_life.gd:30 test_same_cave_same_patches
- tests/test_cave_life.gd:44 test_patches_near_life_on_real_rock
- tests/test_cave_life.gd:79 test_digging_removes_what_grew_there
- tests/test_cave_life.gd:92 test_hitting_a_fern_breaks_it
- tests/test_cave_life.gd:107 test_small_roots_break_and_grow_back

## tests/test_cave_maker.gd (254 lines)
- tests/test_cave_maker.gd:4 test_same_seed_same_cave
- tests/test_cave_maker.gd:18 test_different_seed_different_cave
- tests/test_cave_maker.gd:24 test_three_big_caverns_far_apart
- tests/test_cave_maker.gd:36 test_spawn_is_standing_on_rock
- tests/test_cave_maker.gd:44 test_room_centers_are_open_air
- tests/test_cave_maker.gd:51 test_tunnels_join_every_room
- tests/test_cave_maker.gd:67 test_outside_box_is_border_rock
- tests/test_cave_maker.gd:84 test_two_biomes_joined_by_gates
- tests/test_cave_maker.gd:102 test_copper_only_in_the_deeps
- tests/test_cave_maker.gd:131 test_generated_block_matches_queries
- tests/test_cave_maker.gd:163 test_solid_block_fast_path
- tests/test_cave_maker.gd:174 test_generation_speed
- tests/test_cave_maker.gd:191 test_there_is_clay_for_a_smelter
- tests/test_cave_maker.gd:206 test_special_places_are_planned
- tests/test_cave_maker.gd:222 test_tunnel_mouths_are_at_floor_height
- tests/test_cave_maker.gd:233 test_rock_is_chunky_blocks

## tests/test_cave_models.gd (32 lines) — The hand-built cave plants and crystals (tools/asset_forge/builds/cave_plants.py): each loads with its painted
- tests/test_cave_models.gd:6 test_every_part_has_its_painted_pictures
- tests/test_cave_models.gd:25 test_glow_field_uses_them

## tests/test_chunks.gd (43 lines) — Breaking a block bursts into lots of bits that fly into the dwarf (feedback F13).
- tests/test_chunks.gd:5 test_burst_has_25_to_50_bits_that_fly_to_you_and_vanish
- tests/test_chunks.gd:27 test_bits_are_only_for_looks

## tests/test_climbing.gd (259 lines) — Creatures climbing walls and ceilings (owner, Nov 20: F236, F474, F475;
- tests/test_climbing.gd:12 FakeDwarf
- tests/test_climbing.gd:25 _setup
- tests/test_climbing.gd:55 _teardown
- tests/test_climbing.gd:59 _ray
- tests/test_climbing.gd:65 _ceiling_near
- tests/test_climbing.gd:78 _spawn_at
- tests/test_climbing.gd:85 test_who_climbs_where
- tests/test_climbing.gd:102 test_body_turns_onto_the_rock
- tests/test_climbing.gd:110 test_snail_on_ceiling_knocked_down_dazed
- tests/test_climbing.gd:141 test_spider_ambush_hisses_then_drops
- tests/test_climbing.gd:173 test_climbers_get_out_of_a_pit_the_boss_doesnt
- tests/test_climbing.gd:209 test_up_high_keeps_clear_of_built_things
- tests/test_climbing.gd:248 test_everyone_sees_the_surface

## tests/test_combat.gd (184 lines) — Fighting rules, checked against the worked examples in the combat doc.
- tests/test_combat.gd:8 test_doc_example_copper_mace_on_stone
- tests/test_combat.gd:14 test_doc_example_copper_sword_on_stone
- tests/test_combat.gd:19 test_silver_sword_light_on_nothing
- tests/test_combat.gd:24 test_armor_halves_at_100
- tests/test_combat.gd:28 test_minimum_one_damage
- tests/test_combat.gd:32 test_situations_dont_stack
- tests/test_combat.gd:38 test_combo_finisher_hits_harder
- tests/test_combat.gd:45 test_combos_build_up_to_a_big_last_hit
- tests/test_combat.gd:54 test_spear_two_thrusts_then_a_spin
- tests/test_combat.gd:65 test_great_maul_slice_shove_then_whirl
- tests/test_combat.gd:77 test_stone_has_no_finisher_and_no_heavy
- tests/test_combat.gd:90 test_hit_number_colour_follows_the_damage_type
- tests/test_combat.gd:99 test_balance_plan_f532
- tests/test_combat.gd:117 test_elemental_skips_armor
- tests/test_combat.gd:124 test_parry_block_hit
- tests/test_combat.gd:139 test_crushing_needs_a_shield
- tests/test_combat.gd:144 test_stun_meter
- tests/test_combat.gd:164 test_crossbow_numbers
- tests/test_combat.gd:180 test_every_weapon_can_crit

## tests/test_comfort.gd (46 lines) — The Cozy rest buff: comfort from a fire/bed, different furniture nearby, and a roof.
- tests/test_comfort.gd:5 _station
- tests/test_comfort.gd:12 test_comfort_counts_different_things
- tests/test_comfort.gd:33 test_cozy_buff

## tests/test_crafting.gd (169 lines)
- tests/test_crafting.gd:4 test_every_recipe_uses_real_items
- tests/test_crafting.gd:15 test_every_station_can_be_made
- tests/test_crafting.gd:24 test_every_dish_has_a_recipe
- tests/test_crafting.gd:33 test_craft_campfire_by_hand
- tests/test_crafting.gd:46 test_planks_make_two
- tests/test_crafting.gd:53 test_full_bag_takes_nothing
- tests/test_crafting.gd:62 test_inputs_free_room_for_output
- tests/test_crafting.gd:69 test_heartwood_needed_for_copper_pickaxe
- tests/test_crafting.gd:82 test_holding_the_ingredients_shows_the_station_too
- tests/test_crafting.gd:101 test_rune_slab_shows_after_any_rune
- tests/test_crafting.gd:107 test_unlocks
- tests/test_crafting.gd:115 test_copper_pickaxe_digs_border_rock
- tests/test_crafting.gd:122 test_dwarf_makes_the_in_between_items_first
- tests/test_crafting.gd:139 test_helpers_link_to_stations_within_10_m
- tests/test_crafting.gd:148 _FakeStation
- tests/test_crafting.gd:153 _fake
- tests/test_crafting.gd:161 test_kitchen_levels

## tests/test_darkness.gd (34 lines) — F293: lights that count, and how far they reach.
- tests/test_darkness.gd:5 test_lights_reach_and_empty_lantern_is_dark

## tests/test_dungeon.gd (868 lines) — Dungeons dug into the rock (owner, Nov 19, 2026; DungeonMap). Step 1: Mossgate Hold's rooms are carved into so
- tests/test_dungeon.gd:11 _maker
- tests/test_dungeon.gd:20 test_every_new_world_gets_mossgate_hold
- tests/test_dungeon.gd:34 test_old_worlds_keep_their_caves
- tests/test_dungeon.gd:41 test_rooms_are_open_and_walls_are_old_dwarf_stone
- tests/test_dungeon.gd:60 test_every_room_can_be_reached
- tests/test_dungeon.gd:84 test_nothing_grows_inside_the_dungeon
- tests/test_dungeon.gd:117 test_the_plan_builds
- tests/test_dungeon.gd:136 test_the_door_frame_covers_its_hole
- tests/test_dungeon.gd:154 test_corridors_and_doorways_are_tall_enough
- tests/test_dungeon.gd:170 test_most_floors_and_walls_are_old
- tests/test_dungeon.gd:186 test_the_bridge_is_level_with_the_floor
- tests/test_dungeon.gd:199 test_stalactites_hang_down
- tests/test_dungeon.gd:212 test_stalactites_bait_the_chests
- tests/test_dungeon.gd:234 test_chests_and_breakable_things
- tests/test_dungeon.gd:251 test_the_chasm_and_spike_pit_kill
- tests/test_dungeon.gd:266 _rig
- tests/test_dungeon.gd:285 _kind
- tests/test_dungeon.gd:292 _thing
- tests/test_dungeon.gd:300 test_stalactites_fall_fast_and_hurt
- tests/test_dungeon.gd:318 test_the_spike_pit_shows_under_the_breaking_floor
- tests/test_dungeon.gd:339 test_the_cracked_wall_breaks
- tests/test_dungeon.gd:356 test_the_shrine_basin_heals
- tests/test_dungeon.gd:372 test_the_bridge_has_ropes_and_a_gap
- tests/test_dungeon.gd:386 test_the_crushers_kill
- tests/test_dungeon.gd:414 test_the_loot_door_opens_when_the_pack_dies
- tests/test_dungeon.gd:437 test_the_dungeon_test_world_has_no_caves
- tests/test_dungeon.gd:462 test_walking_under_a_stalactite_brings_it_down
- tests/test_dungeon.gd:496 test_the_bridge_is_two_big_jumps
- tests/test_dungeon.gd:521 test_the_chasm_is_as_deep_as_the_pit
- tests/test_dungeon.gd:532 test_the_pack_hall_door_and_its_crushers
- tests/test_dungeon.gd:592 test_killing_the_pack_opens_the_loot_door
- tests/test_dungeon.gd:628 test_the_lever_opens_the_way_out_gate
- tests/test_dungeon.gd:657 test_the_cracked_wall_is_wood
- tests/test_dungeon.gd:664 test_most_ceilings_are_old
- tests/test_dungeon.gd:674 test_the_scroll_rolls_up_when_taken
- tests/test_dungeon.gd:696 test_the_dungeon_hooks_in_when_built_first
- tests/test_dungeon.gd:731 test_dungeon_creatures_stay_in_their_room
- tests/test_dungeon.gd:762 test_the_rubble_tunnel_clears
- tests/test_dungeon.gd:787 test_stalactites_hit_under_and_splash_round
- tests/test_dungeon.gd:811 test_the_basin_heals_only_30
- tests/test_dungeon.gd:825 test_bandages_have_a_cooldown
- tests/test_dungeon.gd:838 test_dungeon_creatures_notice_you_only_in_their_room
- tests/test_dungeon.gd:846 test_bandage_cooldown_shows_on_its_slot
- tests/test_dungeon.gd:865 test_mossgate_is_dark

## tests/test_dungeon_decor.gd (185 lines) — Dungeon decor from the decor catalogue (docs/art/DECOR-CATALOG.md, owner Nov 22: every piece in its own room a
- tests/test_dungeon_decor.gd:17 _plans
- tests/test_dungeon_decor.gd:26 _decor
- tests/test_dungeon_decor.gd:30 _xz
- tests/test_dungeon_decor.gd:35 _corners
- tests/test_dungeon_decor.gd:46 _dist
- tests/test_dungeon_decor.gd:55 _inside
- tests/test_dungeon_decor.gd:61 _on
- tests/test_dungeon_decor.gd:66 _same_level
- tests/test_dungeon_decor.gd:70 _seg
- tests/test_dungeon_decor.gd:74 test_mossgate_has_its_catalogue_decor
- tests/test_dungeon_decor.gd:87 test_pell_has_its_catalogue_decor
- tests/test_dungeon_decor.gd:99 test_decor_stands_on_the_floor_inside_the_rooms
- tests/test_dungeon_decor.gd:118 test_decor_keeps_off_doors_paths_and_chests
- tests/test_dungeon_decor.gd:174 test_decor_pieces_do_not_overlap

## tests/test_dungeon_junk.gd (205 lines) — Dungeon junk (owner, Nov 20; traps-and-variety.md "Dungeon junk"; laid out by tools/dungeons/junk.py). The own
- tests/test_dungeon_junk.gd:18 _plans
- tests/test_dungeon_junk.gd:27 _junk
- tests/test_dungeon_junk.gd:31 _xz
- tests/test_dungeon_junk.gd:35 _inside
- tests/test_dungeon_junk.gd:39 _in_any
- tests/test_dungeon_junk.gd:48 _on
- tests/test_dungeon_junk.gd:52 _same_level
- tests/test_dungeon_junk.gd:56 _seg
- tests/test_dungeon_junk.gd:61 _doors_of
- tests/test_dungeon_junk.gd:70 test_mossgate_has_junk
- tests/test_dungeon_junk.gd:82 test_pell_has_junk_on_both_levels
- tests/test_dungeon_junk.gd:88 test_junk_lies_on_the_floor_by_a_wall
- tests/test_dungeon_junk.gd:109 test_junk_keeps_off_doors_paths_and_traps
- tests/test_dungeon_junk.gd:165 test_no_junk_over_drops_rails_or_the_plank_walk
- tests/test_dungeon_junk.gd:177 test_half_the_junk_lies_out_in_the_rooms
- tests/test_dungeon_junk.gd:184 test_no_junk_twice_in_a_room
- tests/test_dungeon_junk.gd:201 test_junk_has_no_body_but_old_props_still_smash

## tests/test_dungeon_keys.gd (131 lines) — Dungeon keys and locked doors (owner, Nov 20, F237): one key per medium and big dungeon, a door opens only for
- tests/test_dungeon_keys.gd:11 _setup
- tests/test_dungeon_keys.gd:26 _teardown
- tests/test_dungeon_keys.gd:30 test_one_key_per_medium_and_big_dungeon
- tests/test_dungeon_keys.gd:40 test_a_door_opens_only_for_its_own_key
- tests/test_dungeon_keys.gd:55 test_two_friends_open_the_twin_locks
- tests/test_dungeon_keys.gd:70 test_the_key_goes_back_to_its_boss_after_an_hour
- tests/test_dungeon_keys.gd:97 test_the_boss_bar_follows_its_boss
- tests/test_dungeon_keys.gd:115 test_the_exit_gate_opens_with_its_lever_and_closes_on_refill

## tests/test_dungeon_list.gd (28 lines) — The 12 Zone 1 dungeons (owner, Nov 20, F237): 4 small wooden, 5 medium stone, 3 big clay, and together they te
- tests/test_dungeon_list.gd:6 test_twelve_dungeons_in_three_sizes
- tests/test_dungeon_list.gd:18 test_every_copper_recipe_once_per_world

## tests/test_dungeon_places.gd (73 lines) — Where the 12 Zone 1 dungeons sit (owner, Nov 20, F237): in their rings, 40 m apart, inside rock, and clear of 
- tests/test_dungeon_places.gd:8 test_all_twelve_in_their_rings
- tests/test_dungeon_places.gd:38 test_dungeons_keep_out_of_ruins_and_places
- tests/test_dungeon_places.gd:54 test_same_world_same_places_and_mossgate_from_the_pc
- tests/test_dungeon_places.gd:67 test_reserved_ground_covers_the_dungeons

## tests/test_dungeon_test_gear.gd (28 lines) — The dev "Test the dungeon" buttons' gear (owner, Nov 21: "I only have the spear and the mace": the worn sword 
- tests/test_dungeon_test_gear.gd:8 test_every_weapon_kind_is_on_the_hotbar

## tests/test_dungeon_variety.gd (50 lines) — Dungeon variety (owner, Nov 20, F237; traps-and-variety.md "Variety"): picked from world seed + dungeon only.
- tests/test_dungeon_variety.gd:12 test_same_world_same_dungeon_same_picks
- tests/test_dungeon_variety.gd:21 test_picks_stay_inside_the_rules
- tests/test_dungeon_variety.gd:43 test_adding_a_chest_keeps_the_other_picks

## tests/test_dungeons.gd (81 lines) — Zone 1 dungeons (owner, Nov 19, F237; docs/design/zone1-dungeons-plan.md): each one's page always teaches the 
- tests/test_dungeons.gd:10 _setup
- tests/test_dungeons.gd:20 _teardown
- tests/test_dungeons.gd:24 test_every_copper_recipe_has_its_own_page
- tests/test_dungeons.gd:35 test_a_dungeon_page_teaches_its_one_recipe
- tests/test_dungeons.gd:46 test_dungeon_chests_fill_up_again_after_an_hour_of_play
- tests/test_dungeons.gd:72 test_each_world_shuffles_which_dungeon_teaches_what

## tests/test_durability.gd (59 lines)
- tests/test_durability.gd:4 test_wear_numbers
- tests/test_durability.gd:29 test_broken_tools_do_nothing_and_repair_at_the_bench

## tests/test_dwarf.gd (415 lines) — The dwarf standing in the real cave, with real physics.
- tests/test_dwarf.gd:5 test_dwarf_does_not_fall_through_floor
- tests/test_dwarf.gd:43 _room
- tests/test_dwarf.gd:52 _block
- tests/test_dwarf.gd:64 _dwarf_in
- tests/test_dwarf.gd:71 _walk_forward
- tests/test_dwarf.gd:81 test_jump_goes_up_and_lands
- tests/test_dwarf.gd:98 test_jump_pressed_just_before_landing_still_counts
- tests/test_dwarf.gd:117 test_steps_up_small_ledge
- tests/test_dwarf.gd:130 test_does_not_step_up_tall_wall
- tests/test_dwarf.gd:142 test_lantern_ignores_dwarf_body_for_shadows
- tests/test_dwarf.gd:166 test_hand_built_body_fits_the_skeleton
- tests/test_dwarf.gd:191 test_hand_built_armor_fits_the_body
- tests/test_dwarf.gd:222 test_braid_tufts_swing_when_moving
- tests/test_dwarf.gd:260 test_dev_fly_floats_and_lands_again
- tests/test_dwarf.gd:282 test_aim_skips_things_behind_the_dwarf
- tests/test_dwarf.gd:311 test_crossbow_reload_needs_standing_still
- tests/test_dwarf.gd:365 test_beetle_charge_throws_a_couple_of_metres
- tests/test_dwarf.gd:389 test_your_own_stun_meter

## tests/test_dwarf_fist.gd (272 lines) — The dwarf's fists (DwarfFist, owner Nov 19: "the handle runs past his hand and his fingers stay open"):
- tests/test_dwarf_fist.gd:10 _handle_line
- tests/test_dwarf_fist.gd:18 _off_line
- tests/test_dwarf_fist.gd:24 _check_grip
- tests/test_dwarf_fist.gd:46 test_fist_closes_round_the_handle
- tests/test_dwarf_fist.gd:77 test_shield_hand_makes_a_fist
- tests/test_dwarf_fist.gd:97 test_open_hand_without_a_tool
- tests/test_dwarf_fist.gd:114 test_two_handed_weapons_take_both_hands
- tests/test_dwarf_fist.gd:157 test_great_swings_keep_fists_and_handle_room
- tests/test_dwarf_fist.gd:203 test_shield_worn_on_the_forearm
- tests/test_dwarf_fist.gd:239 test_one_handed_swings_hold_and_hit_in_front

## tests/test_dwarf_weight.gd (81 lines) — The dwarf's weight (DwarfWeight, owner Nov 19: "heavy + chunky"): feet on the floor, a heavy landing.
- tests/test_dwarf_weight.gd:5 _make_rig
- tests/test_dwarf_weight.gd:17 _lowest_foot
- tests/test_dwarf_weight.gd:25 test_feet_stay_out_of_the_floor_walking_and_running
- tests/test_dwarf_weight.gd:44 test_landing_squashes_then_springs_back

## tests/test_equipment.gd (120 lines) — Equipment slots (feedback F23): pickaxe, lantern, weapon, shield, head, chest, legs, feet, pack.
- tests/test_equipment.gd:5 _dwarf_inv
- tests/test_equipment.gd:9 test_tools_and_clothes_go_into_their_slots_by_themselves
- tests/test_equipment.gd:25 test_slots_only_take_the_right_things
- tests/test_equipment.gd:36 test_backpack_opens_ten_slots_and_must_be_empty_to_take_off
- tests/test_equipment.gd:52 test_hand_uses_equipped_pickaxe_and_drawn_weapon
- tests/test_equipment.gd:75 test_armor_soaks_up_damage
- tests/test_equipment.gd:88 test_lantern_lights_only_from_its_slot
- tests/test_equipment.gd:99 test_right_click_equips_and_shield_is_usable

## tests/test_fall_damage.gd (46 lines) — Drops `h` metres from a ledge with real gravity (frames of 1/60 s) and returns the drop the tracker reports.
- tests/test_fall_damage.gd:5 _drop
- tests/test_fall_damage.gd:16 test_fall_damage_numbers
- tests/test_fall_damage.gd:23 test_falls_are_measured
- tests/test_fall_damage.gd:28 test_ladders_jumps_and_teleports_dont_hurt

## tests/test_farming.gd (84 lines) — Farm Plots (owner F176), crystal torches (F177), hand recipes at the workbench (F174).
- tests/test_farming.gd:8 _setup
- tests/test_farming.gd:25 _teardown
- tests/test_farming.gd:29 test_plant_grow_and_pick
- tests/test_farming.gd:51 test_tuber_seeds_and_firecaps_grow
- tests/test_farming.gd:69 test_crystal_torch_is_cheap_and_by_hand
- tests/test_farming.gd:76 test_more_fiber_and_roots_give_some

## tests/test_furniture.gd (39 lines) — The Furnish tab (owner, Nov 19): free CC0 furniture rebuilt in our paint. Every piece shows its own model (it 
- tests/test_furniture.gd:6 _furniture
- tests/test_furniture.gd:10 test_every_furniture_piece_has_a_model_that_fits
- tests/test_furniture.gd:31 test_furniture_that_does_something

## tests/test_gems.gd (192 lines) — Gems in weapons, shields and pickaxes (combat doc 4).
- tests/test_gems.gd:10 _setup
- tests/test_gems.gd:31 _teardown
- tests/test_gems.gd:35 _slot_of
- tests/test_gems.gd:42 test_socket_counts_and_bonuses
- tests/test_gems.gd:63 test_bench_socket_and_remove
- tests/test_gems.gd:84 test_ember_sword_burns
- tests/test_gems.gd:106 test_creature_burns_and_freezes
- tests/test_gems.gd:136 test_shield_gems_change_blocks
- tests/test_gems.gd:144 test_combine_three_into_a_better_gem
- tests/test_gems.gd:160 test_where_gems_come_from
- tests/test_gems.gd:170 test_armor_gems
- tests/test_gems.gd:181 test_owner_nov21_rules

## tests/test_glow_groves.gd (146 lines) — Glow groves (owner, Nov 19): 1-2 big caverns per biome hold a forest of glowing and dark trees, never the firs
- tests/test_glow_groves.gd:7 test_groves_per_biome
- tests/test_glow_groves.gd:27 test_grove_trees_keep_clear
- tests/test_glow_groves.gd:47 test_grove_models_exist
- tests/test_glow_groves.gd:52 test_trees_come_in_very_different_sizes
- tests/test_glow_groves.gd:75 test_chop_a_grove_tree_down_and_it_grows_back
- tests/test_glow_groves.gd:115 test_no_big_rocks_in_groves
- tests/test_glow_groves.gd:130 test_groves_glow_in_several_colours

## tests/test_glow_placer.gd (133 lines)
- tests/test_glow_placer.gd:4 test_same_seed_same_spots
- tests/test_glow_placer.gd:12 test_enough_of_every_kind
- tests/test_glow_placer.gd:28 test_roots_grow_out_of_the_floor
- tests/test_glow_placer.gd:41 test_jungle_grows_its_own_things
- tests/test_glow_placer.gd:56 test_spots_sit_on_rock_surface
- tests/test_glow_placer.gd:65 test_ids_are_unique_and_spaced
- tests/test_glow_placer.gd:74 test_first_cavern_has_a_drip
- tests/test_glow_placer.gd:89 test_size_boost_only_grows
- tests/test_glow_placer.gd:105 test_crystals_and_roots_are_solid
- tests/test_glow_placer.gd:122 test_twigs_on_mossy_floors

## tests/test_goals.gd (62 lines) — "Next steps" (F103): the list starts at the beginning and ticks off as you go.
- tests/test_goals.gd:5 test_next_steps_tick_off
- tests/test_goals.gd:46 test_placing_preview_rules

## tests/test_graphics_settings.gd (39 lines) — Graphics presets (owner, Nov 19: "run well on potato computers"): Potato..Ultra, remembered on this computer.
- tests/test_graphics_settings.gd:7 test_presets_apply_and_are_remembered
- tests/test_graphics_settings.gd:32 test_settings_panel_has_graphics

## tests/test_home_decor.gd (59 lines) — The home decor tabs (owner, Nov 22): every approved home piece of docs/art/DECOR-CATALOG.md is in the build me
- tests/test_home_decor.gd:15 _home
- tests/test_home_decor.gd:19 test_home_tabs_are_full_and_on_the_menu
- tests/test_home_decor.gd:29 test_every_home_piece_has_a_model_a_cost_and_a_picture
- tests/test_home_decor.gd:43 test_home_pieces_hang_the_catalogue_way
- tests/test_home_decor.gd:55 test_trophies_cost_the_creature

## tests/test_icons.gd (37 lines) — Item pictures (F17): every item has one, and they load as small square pictures.
- tests/test_icons.gd:6 test_every_item_has_an_icon
- tests/test_icons.gd:14 test_icons_are_small_squares
- tests/test_icons.gd:22 test_runes_share_their_colour_picture
- tests/test_icons.gd:28 test_unknown_item_has_no_icon
- tests/test_icons.gd:32 test_every_perk_has_a_picture

## tests/test_inventory.gd (60 lines)
- tests/test_inventory.gd:4 test_add_and_count
- tests/test_inventory.gd:11 test_full_stack_starts_new_slot
- tests/test_inventory.gd:19 test_fills_existing_stack_first
- tests/test_inventory.gd:28 test_full_bag_returns_leftover
- tests/test_inventory.gd:34 test_tools_do_not_stack
- tests/test_inventory.gd:41 test_remove
- tests/test_inventory.gd:50 test_unknown_item_rejected
- tests/test_inventory.gd:55 test_data_roundtrip

## tests/test_item_sources.gd (138 lines) — Every item a recipe needs can really be got (owner, Nov 19: the bosses and most creatures were taken out, and
- tests/test_item_sources.gd:18 _sources
- tests/test_item_sources.gd:41 test_every_recipe_item_has_a_source
- tests/test_item_sources.gd:59 test_no_recipe_or_drop_names_a_missing_item
- tests/test_item_sources.gd:82 test_every_creature_lives_somewhere
- tests/test_item_sources.gd:96 test_only_the_five_creatures_are_left
- tests/test_item_sources.gd:105 test_new_drops
- tests/test_item_sources.gd:120 test_a_bandage_heals_a_little
- tests/test_item_sources.gd:128 test_old_saves_still_load

## tests/test_jungle.gd (90 lines) — The Fungal Jungle (biome 2): its monsters, plants and rocks fit together.
- tests/test_jungle.gd:5 test_every_monster_is_complete
- tests/test_jungle.gd:28 test_jungle_spawns_use_jungle_monsters
- tests/test_jungle.gd:35 test_jungle_rocks
- tests/test_jungle.gd:60 test_glow_items_exist
- tests/test_jungle.gd:69 test_jungle_runes_and_backfill
- tests/test_jungle.gd:77 test_crystal_variants

## tests/test_keep_clear.gd (308 lines) — The owner's placement rule (Nov 17): nothing the world grows stands inside something built. The ruined
- tests/test_keep_clear.gd:6 test_tower_ground_is_kept_clear
- tests/test_keep_clear.gd:44 test_root_curtains
- tests/test_keep_clear.gd:64 test_root_pillars
- tests/test_keep_clear.gd:81 test_puddles
- tests/test_keep_clear.gd:93 test_boulders_keep_clear
- tests/test_keep_clear.gd:111 test_mushroom_grass_keeps_clear
- tests/test_keep_clear.gd:136 test_nothing_grows_inside_root_trees
- tests/test_keep_clear.gd:170 test_waterfalls_keep_clear
- tests/test_keep_clear.gd:194 test_no_roots_on_crystals
- tests/test_keep_clear.gd:212 test_rune_shrines_stand_on_the_floor
- tests/test_keep_clear.gd:237 test_clutter_keeps_clear_of_boxes

## tests/test_lampwick.gd (500 lines) — Lampwick Drift, the second dungeon (owner, Nov 20, F477: "Dungeon 2 should be a new dungeon. We planned it.").
- tests/test_lampwick.gd:11 _maker
- tests/test_lampwick.gd:21 _test_world
- tests/test_lampwick.gd:30 _lampwick
- tests/test_lampwick.gd:37 test_new_worlds_get_lampwick_too
- tests/test_lampwick.gd:53 test_layout_14_worlds_keep_only_mossgate
- tests/test_lampwick.gd:61 test_the_dungeon_2_test_world
- tests/test_lampwick.gd:78 test_every_space_can_be_reached
- tests/test_lampwick.gd:106 test_nothing_grows_inside_lampwick
- tests/test_lampwick.gd:131 test_the_plan
- tests/test_lampwick.gd:158 test_creatures_stand_in_their_rooms
- tests/test_lampwick.gd:174 _rig
- tests/test_lampwick.gd:191 _all
- tests/test_lampwick.gd:195 test_every_trap_is_built
- tests/test_lampwick.gd:210 test_lamps_light_for_everyone
- tests/test_lampwick.gd:225 test_a_cart_comes_down_its_lane
- tests/test_lampwick.gd:248 test_the_other_lanes_wait
- tests/test_lampwick.gd:259 test_the_swinging_boulder_hits_and_can_be_shot_down
- tests/test_lampwick.gd:286 test_bear_jaws_bite_and_hold
- tests/test_lampwick.gd:304 test_the_tripwire_fires_the_dart_and_a_jump_clears_it
- tests/test_lampwick.gd:321 test_the_tripwire_can_be_cut
- tests/test_lampwick.gd:332 test_the_vault_chest_spikes
- tests/test_lampwick.gd:365 test_each_basin_keeps_its_own_water
- tests/test_lampwick.gd:372 test_the_dart_poisons_and_carts_hurt_through_armour
- tests/test_lampwick.gd:377 test_bear_jaws_can_be_sprung_safely
- tests/test_lampwick.gd:395 test_crashed_carts_leave_the_way_in_free
- tests/test_lampwick.gd:405 test_the_boss_room_has_a_door
- tests/test_lampwick.gd:418 test_stalactites_fall_slower_here_and_quieter
- tests/test_lampwick.gd:426 test_the_healing_basin_can_be_reached
- tests/test_lampwick.gd:441 test_lampwick_creatures_follow_you_out
- tests/test_lampwick.gd:449 test_the_foreman_is_weaker_and_smashes_stone
- tests/test_lampwick.gd:458 test_no_prop_in_front_of_a_doorway
- tests/test_lampwick.gd:472 test_the_back_rails_have_stalactites
- tests/test_lampwick.gd:484 test_the_boulder_spares_you_while_you_get_up
- tests/test_lampwick.gd:498 test_the_foremans_spin_shows_a_red_outline

## tests/test_loot_props.gd (261 lines) — Lootable decor (handover Nov 22, section 4; LootProps): E gives the prop's few items once, the model swaps to 
- tests/test_loot_props.gd:13 _setup
- tests/test_loot_props.gd:25 _teardown
- tests/test_loot_props.gd:29 _shown
- tests/test_loot_props.gd:33 test_the_loot_table
- tests/test_loot_props.gd:49 test_it_gives_its_items_once_and_goes_empty
- tests/test_loot_props.gd:77 test_request_host_everyone
- tests/test_loot_props.gd:104 test_it_stays_looted_after_save_and_load
- tests/test_loot_props.gd:126 test_dungeon_and_ruin_plans
- tests/test_loot_props.gd:163 test_the_strongbox_lid_opens
- tests/test_loot_props.gd:191 _body
- tests/test_loot_props.gd:204 _ray
- tests/test_loot_props.gd:210 _mesh_open
- tests/test_loot_props.gd:220 test_the_forced_vault_door_is_walk_through
- tests/test_loot_props.gd:248 test_the_spyhole_is_see_through

## tests/test_map.gd (52 lines) — Pretend world: open air where x < 0, rock where x >= 0.
- tests/test_map.gd:4 test_floors_cover_the_biome
- tests/test_map.gd:10 test_reveal_draws_open_and_rock
- tests/test_map.gd:26 test_each_biome_has_its_own_pages
- tests/test_map.gd:41 test_climbing_leaves_markers
- tests/test_map.gd:51 _same

## tests/test_menu.gd (190 lines) — The menus (F87): the main menu lists your worlds and can delete them (after asking);
- tests/test_menu.gd:6 _fake_world
- tests/test_menu.gd:16 _clean
- tests/test_menu.gd:24 test_worlds_are_listed_and_deleted
- tests/test_menu.gd:46 test_main_menu_rows_and_delete_asks_first
- tests/test_menu.gd:69 test_escape_menu_buttons
- tests/test_menu.gd:90 test_hotbar_stays_when_the_bag_opens
- tests/test_menu.gd:111 test_carried_pickaxe_is_found
- tests/test_menu.gd:124 test_blueprints_are_learned_from_pages
- tests/test_menu.gd:142 test_crafting_takes_a_moment
- tests/test_menu.gd:154 test_crafting_tabs_and_amounts
- tests/test_menu.gd:170 test_craft_status_keeps_its_height
- tests/test_menu.gd:187 test_number_keys_mean_hotbar_slots

## tests/test_model_pictures.gd (52 lines) — Models must arrive in the game WITH their pictures (F164, Nov 16). Blender 5.3 writes a colour profile into ev
- tests/test_model_pictures.gd:8 _baked_without_picture
- tests/test_model_pictures.gd:23 test_creatures_load_with_their_pictures
- tests/test_model_pictures.gd:38 test_dwarf_body_loads_with_its_pictures

## tests/test_model_rules.gd (143 lines) — The owner's model rules (docs/art/MODEL-RULES.md, Nov 15) as the build menu must follow them:
- tests/test_model_rules.gd:13 _menu
- tests/test_model_rules.gd:21 test_stonehold_has_flat_roofs_only
- tests/test_model_rules.gd:28 test_shack_and_hearthbrick_have_sloped_roofs_only
- tests/test_model_rules.gd:35 test_copper_is_for_decor_and_doors_only
- tests/test_model_rules.gd:43 test_one_round_doorway_and_one_door_per_style
- tests/test_model_rules.gd:56 test_old_saves_with_removed_pieces_still_load
- tests/test_model_rules.gd:65 test_wall_decor_hangs_on_walls
- tests/test_model_rules.gd:79 test_wall_decor_models_exist
- tests/test_model_rules.gd:92 test_every_model_has_a_build_script
- tests/test_model_rules.gd:104 _made_by_script
- tests/test_model_rules.gd:116 _said
- tests/test_model_rules.gd:124 _files
- tests/test_model_rules.gd:139 test_building_styles_unlock_with_station_levels

## tests/test_monsters.gd (1286 lines) — Monsters and fighting, with the real cave and referee.
- tests/test_monsters.gd:11 FakeDwarf
- tests/test_monsters.gd:25 _setup
- tests/test_monsters.gd:54 _teardown
- tests/test_monsters.gd:58 _spawn
- tests/test_monsters.gd:65 test_monster_data_is_sane
- tests/test_monsters.gd:74 test_notices_and_chases_you
- tests/test_monsters.gd:84 test_sword_damage_and_kill
- tests/test_monsters.gd:102 test_shield_bash_hits_with_the_shield
- tests/test_monsters.gd:121 test_crystal_monster_hits_harder_and_drops_crystals
- tests/test_monsters.gd:151 test_a_healthy_snail_fights_back_a_hurt_one_runs
- tests/test_monsters.gd:166 test_crossbow_shot
- tests/test_monsters.gd:188 test_friendly_fire
- tests/test_monsters.gd:213 test_spore_clouds
- tests/test_monsters.gd:231 test_sneak_attack_doubles
- tests/test_monsters.gd:242 test_parry_stuns_the_monster
- tests/test_monsters.gd:255 test_unblocked_hit_hurts
- tests/test_monsters.gd:264 test_poison_jabs_build_up
- tests/test_monsters.gd:282 test_too_far_misses
- tests/test_monsters.gd:291 test_pack_leader_boost_ends_when_it_dies
- tests/test_monsters.gd:308 test_spawner_fills_nearby_caves
- tests/test_monsters.gd:344 test_attack_animation_keeps_monster_size
- tests/test_monsters.gd:356 test_rock_snail_hides_in_its_shell
- tests/test_monsters.gd:382 test_rock_beetle_soft_back
- tests/test_monsters.gd:404 test_creature_sounds_and_tells
- tests/test_monsters.gd:432 test_shield_stops_snail_spit
- tests/test_monsters.gd:455 test_snail_foot_stays_put
- tests/test_monsters.gd:497 test_bat_wings_and_roost
- tests/test_monsters.gd:522 test_snail_turns_before_it_moves
- tests/test_monsters.gd:542 test_beetles_and_bats_turn_before_moving
- tests/test_monsters.gd:568 test_beetle_ragdoll_on_death
- tests/test_monsters.gd:616 test_snail_ragdoll_leaves_its_foot
- tests/test_monsters.gd:649 _settled_clear
- tests/test_monsters.gd:655 test_bat_ragdoll_falls_out_of_the_air
- tests/test_monsters.gd:696 test_dead_creature_turns_to_stone_and_is_mined
- tests/test_monsters.gd:750 test_bat_shot_down_from_high_turns_to_stone
- tests/test_monsters.gd:784 test_cave_spider_walks_pounces_and_turns_to_stone
- tests/test_monsters.gd:820 test_no_broken_numbers_when_creatures_die
- tests/test_monsters.gd:843 _all_nodes
- tests/test_monsters.gd:851 test_a_hit_pushes_and_freezes
- tests/test_monsters.gd:873 test_every_cave_has_its_own_bat_roost
- tests/test_monsters.gd:890 _solid_ground
- tests/test_monsters.gd:902 test_beetles_and_snails_climb_out_of_holes
- tests/test_monsters.gd:935 test_beetles_bump_never_overlap
- tests/test_monsters.gd:954 test_spider_pounce_doesnt_knock_down
- tests/test_monsters.gd:964 test_bats_wake_to_light_and_stay_until_you_leave
- tests/test_monsters.gd:997 test_bats_stay_under_the_ceiling
- tests/test_monsters.gd:1015 test_leaders_are_big_without_a_crown
- tests/test_monsters.gd:1027 test_sword_star_perks_in_a_real_fight
- tests/test_monsters.gd:1047 test_no_bat_roost_by_the_start
- tests/test_monsters.gd:1068 test_beetle_rears_up_then_charges_flat
- tests/test_monsters.gd:1090 test_charging_beetle_smashes_a_stone_body
- tests/test_monsters.gd:1118 test_daze_ends_cleanly
- tests/test_monsters.gd:1136 test_dazed_shows_stars_and_sways
- tests/test_monsters.gd:1178 test_bat_circles_then_dives_through_you
- tests/test_monsters.gd:1226 test_sidestep_a_bat_dive
- tests/test_monsters.gd:1245 test_bats_take_turns_diving
- tests/test_monsters.gd:1259 test_beetle_charge_runs_its_full_length_then_is_dazed

## tests/test_pell.gd (331 lines) — Old Pell's Diggings, the third dungeon (owner, Nov 20: "start working on dung 3"; the Foreman again as its bos
- tests/test_pell.gd:12 _maker
- tests/test_pell.gd:22 _test_world
- tests/test_pell.gd:31 _pell
- tests/test_pell.gd:38 _apart
- tests/test_pell.gd:43 test_new_worlds_get_old_pells_too
- tests/test_pell.gd:60 test_layout_15_worlds_keep_two
- tests/test_pell.gd:68 test_the_dungeon_3_test_world
- tests/test_pell.gd:85 test_every_space_can_be_reached
- tests/test_pell.gd:122 test_nothing_grows_inside_old_pells
- tests/test_pell.gd:147 test_the_plan
- tests/test_pell.gd:169 test_creatures_stand_in_their_rooms
- tests/test_pell.gd:177 _rig
- tests/test_pell.gd:194 _all
- tests/test_pell.gd:198 test_every_trap_is_built
- tests/test_pell.gd:210 test_the_ladders
- tests/test_pell.gd:222 test_only_the_spike_pit_kills
- tests/test_pell.gd:229 test_the_dart_plate_fires_and_can_be_used_up
- tests/test_pell.gd:254 test_the_crushers_never_sleep
- tests/test_pell.gd:265 test_the_spear_walls_stab_in_rhythm
- tests/test_pell.gd:289 test_the_push_wall_fires_once_and_rests
- tests/test_pell.gd:309 test_the_rope_lift

## tests/test_pieces.gd (179 lines) — The building pieces (building polish spec §1-§2): the catalog, the soft numbers, and snapping.
- tests/test_pieces.gd:8 test_every_piece_is_valid
- tests/test_pieces.gd:25 test_old_ids_still_exist
- tests/test_pieces.gd:30 test_starter_lodge_pieces_exist
- tests/test_pieces.gd:39 test_soft_numbers
- tests/test_pieces.gd:52 test_wall_snaps_to_floor_edge
- tests/test_pieces.gd:59 test_roof_sits_on_wall_top
- tests/test_pieces.gd:67 test_pillar_snaps_to_floor_corner
- tests/test_pieces.gd:72 test_half_floor_fills_1m
- tests/test_pieces.gd:77 test_no_anchor_uses_1m_grid
- tests/test_pieces.gd:81 test_floor_extends_from_side
- tests/test_pieces.gd:86 test_rotation_cycles
- tests/test_pieces.gd:95 test_foundation_always_anchored
- tests/test_pieces.gd:105 test_stone_reaches_farther_than_wood
- tests/test_pieces.gd:118 test_pillar_stack_stays_strong
- tests/test_pieces.gd:127 test_strength_colors
- tests/test_pieces.gd:137 test_stations_by_material
- tests/test_pieces.gd:150 test_ladder_snaps_onto_a_wall_face
- tests/test_pieces.gd:166 test_wall_decor_hangs_facing_out

## tests/test_plan_cache.gd (27 lines) — Faster second load (owner, Nov 19): a cave's plans are saved the first time and read back the next time; a pla
- tests/test_plan_cache.gd:6 test_saved_plan_is_read_back_and_code_changes_plan_fresh

## tests/test_pois.gd (142 lines) — Special places: rune shrines, ruin loot, carving runes.
- tests/test_pois.gd:10 _setup
- tests/test_pois.gd:31 _teardown
- tests/test_pois.gd:35 test_shrine_gives_one_rune
- tests/test_pois.gd:49 test_ruin_and_camp_chests_have_loot
- tests/test_pois.gd:70 test_carving_runes_at_the_slab
- tests/test_pois.gd:84 test_ruin_columns_break_for_stone
- tests/test_pois.gd:109 _stone_on_floor
- tests/test_pois.gd:117 test_ruin_column_sits_on_the_real_floor

## tests/test_progression.gd (253 lines) — Rows from progression doc 7.3 (skipping level 1, which sits exactly on a .5 rounding edge).
- tests/test_progression.gd:4 test_level_curve_matches_doc_table
- tests/test_progression.gd:13 test_one_point_per_level
- tests/test_progression.gd:19 test_skill_curve_total
- tests/test_progression.gd:27 test_xp_goes_to_skill_and_level
- tests/test_progression.gd:36 test_level_up_signal_and_carry_over
- tests/test_progression.gd:46 test_level_cap
- tests/test_progression.gd:53 test_perk_needs_points_and_the_perk_before
- tests/test_progression.gd:68 test_respec_refunds_points
- tests/test_progression.gd:80 test_every_perk_is_reachable
- tests/test_progression.gd:99 test_ability_keys_take_the_first_active_perks
- tests/test_progression.gd:105 test_old_tree_perks_give_their_points_back
- tests/test_progression.gd:117 test_quality_table_rows_add_to_100
- tests/test_progression.gd:125 test_quality_roll
- tests/test_progression.gd:133 test_network_roundtrip
- tests/test_progression.gd:144 test_skills_list_and_info_match
- tests/test_progression.gd:150 test_weapons_train_their_skill
- tests/test_progression.gd:160 test_stars_and_branches
- tests/test_progression.gd:169 test_old_four_skill_save_carries_over
- tests/test_progression.gd:183 test_skill_level_bonuses
- tests/test_progression.gd:202 test_star_perks
- tests/test_progression.gd:223 test_kill_counts
- tests/test_progression.gd:240 test_kill_rewards

## tests/test_ragdoll.gd (54 lines) — Big hits (F237): the dwarf goes floppy, tumbles the way he was pushed, stays on the floor, then gets back up.
- tests/test_ragdoll.gd:5 _room
- tests/test_ragdoll.gd:20 test_big_hit_tumbles_and_gets_up

## tests/test_regrow.gd (41 lines) — F106: chopped roots grow back after a while, so a cave never runs out of rootwood.
- tests/test_regrow.gd:5 test_roots_grow_back

## tests/test_ruin_brewhall.gd (272 lines) — The Brewhall (owner, Nov 20, F479): the third ruin, a clay-brick tavern and brewery. Its plan, where it goes,
- tests/test_ruin_brewhall.gd:9 _setup
- tests/test_ruin_brewhall.gd:17 test_plan_is_whole
- tests/test_ruin_brewhall.gd:29 _whole_pieces
- tests/test_ruin_brewhall.gd:35 test_blueprint_matches_its_ruin
- tests/test_ruin_brewhall.gd:60 test_steps_land_on_open_ground_and_doors_have_no_window_beside
- tests/test_ruin_brewhall.gd:78 test_spot_is_found_quickly
- tests/test_ruin_brewhall.gd:94 _build_brewhall
- tests/test_ruin_brewhall.gd:122 _rebuild
- tests/test_ruin_brewhall.gd:159 _count
- tests/test_ruin_brewhall.gd:167 test_rebuild_the_brewhall_in_wood
- tests/test_ruin_brewhall.gd:203 test_rebuild_the_brewhall_in_brick
- tests/test_ruin_brewhall.gd:235 test_a_half_rebuilt_brewhall_saves_and_is_shared

## tests/test_ruin_junk.gd (137 lines) — Ruin junk (owner, Nov 20; laid out by tools/ruins/ruin_junk.py, drawn by RuinJunk). The owner's placement rule
- tests/test_ruin_junk.gd:20 _ruins
- tests/test_ruin_junk.gd:27 _top
- tests/test_ruin_junk.gd:31 _fp
- tests/test_ruin_junk.gd:35 _seg_dist
- tests/test_ruin_junk.gd:39 _poly_dist
- tests/test_ruin_junk.gd:48 test_both_ruins_have_junk
- tests/test_ruin_junk.gd:62 test_ruin_junk_keeps_off_the_ruin
- tests/test_ruin_junk.gd:108 test_ruin_junk_keeps_off_the_way_in
- tests/test_ruin_junk.gd:127 test_rebuilt_ruin_drops_its_inside_junk

## tests/test_ruin_outpost.gd (311 lines) — The Fallen Outpost (owner, Nov 17): its plan, where it goes, and that building it doesn't freeze the game.
- tests/test_ruin_outpost.gd:7 _setup
- tests/test_ruin_outpost.gd:15 test_plan_is_whole
- tests/test_ruin_outpost.gd:28 test_spot_is_found_quickly
- tests/test_ruin_outpost.gd:41 test_many_pieces_check_fast
- tests/test_ruin_outpost.gd:62 _build_outpost
- tests/test_ruin_outpost.gd:89 _whole_pieces
- tests/test_ruin_outpost.gd:97 test_blueprint_matches_its_ruin
- tests/test_ruin_outpost.gd:139 _rebuild
- tests/test_ruin_outpost.gd:174 _count
- tests/test_ruin_outpost.gd:182 test_rebuild_the_outpost_in_wood
- tests/test_ruin_outpost.gd:226 test_rebuild_the_outpost_in_stone
- tests/test_ruin_outpost.gd:253 test_a_half_rebuilt_outpost_saves_and_is_shared
- tests/test_ruin_outpost.gd:294 test_old_outpost_chest_is_set_right

## tests/test_ruin_spire.gd (319 lines) — The Lantern Spire (owner, Nov 20, F479): the fourth ruin, a tall round Stonehold beacon tower whose top half l
- tests/test_ruin_spire.gd:10 _setup
- tests/test_ruin_spire.gd:18 test_plan_is_whole
- tests/test_ruin_spire.gd:32 _whole_pieces
- tests/test_ruin_spire.gd:38 test_blueprint_matches_its_ruin
- tests/test_ruin_spire.gd:67 test_fire_bowl_is_a_real_piece_with_a_fire
- tests/test_ruin_spire.gd:88 test_spot_keeps_clear_of_what_the_world_grows
- tests/test_ruin_spire.gd:114 test_spot_is_found_quickly
- tests/test_ruin_spire.gd:125 _build_spire
- tests/test_ruin_spire.gd:153 _rebuild
- tests/test_ruin_spire.gd:190 _count
- tests/test_ruin_spire.gd:198 _wreck_count
- tests/test_ruin_spire.gd:205 test_rebuild_the_spire_in_wood
- tests/test_ruin_spire.gd:255 test_rebuild_the_spire_in_stone
- tests/test_ruin_spire.gd:282 test_a_half_rebuilt_spire_saves_and_is_shared

## tests/test_ruin_tower.gd (280 lines) — F254: the ruined Stone Watchtower in the first cave of a new world (owner, Nov 17).
- tests/test_ruin_tower.gd:8 _setup
- tests/test_ruin_tower.gd:27 test_plan_has_the_ruin
- tests/test_ruin_tower.gd:57 test_built_in_the_first_cave_without_monsters
- tests/test_ruin_tower.gd:118 test_plans_teach_the_watchtower
- tests/test_ruin_tower.gd:126 test_rebuilding_chest_is_there_and_explains_itself
- tests/test_ruin_tower.gd:181 test_old_world_gets_its_rebuilding_chest
- tests/test_ruin_tower.gd:221 test_rebuild_the_ruin_in_wood

## tests/test_ruin_treasure.gd (29 lines) — Treasure in old places (owner, Nov 19): ruins get coins, candles and books by the loot chest (never on it), ca
- tests/test_ruin_treasure.gd:6 test_treasure_by_the_chest_never_on_it
- tests/test_ruin_treasure.gd:23 test_loot_chest_has_a_lid

## tests/test_rune_crafts.gd (152 lines) — Water, and the things rune carvings teach (progression doc 6.4 and 8).
- tests/test_rune_crafts.gd:10 _setup
- tests/test_rune_crafts.gd:31 _teardown
- tests/test_rune_crafts.gd:35 test_every_rune_recipe_exists
- tests/test_rune_crafts.gd:47 test_drip_bucket_fills_and_gives_water
- tests/test_rune_crafts.gd:67 test_drips_exist_in_the_cave
- tests/test_rune_crafts.gd:75 test_whetstone_and_bug_oil_boost_damage
- tests/test_rune_crafts.gd:88 test_twin_smelter_runs_two_jobs
- tests/test_rune_crafts.gd:99 test_ore_crate_only_takes_ore
- tests/test_rune_crafts.gd:105 test_recipe_pages_from_ruins
- tests/test_rune_crafts.gd:123 test_each_page_kind_teaches_its_own_kind

## tests/test_rune_slab.gd (64 lines)
- tests/test_rune_slab.gd:4 test_44_runes_in_8_sets
- tests/test_rune_slab.gd:11 test_carve_then_duplicate_becomes_shard
- tests/test_rune_slab.gd:19 test_three_shards_carve_a_missing_rune
- tests/test_rune_slab.gd:31 test_set_finish_signal
- tests/test_rune_slab.gd:41 test_runes_teach_recipes
- tests/test_rune_slab.gd:48 test_drop_prefers_missing_runes
- tests/test_rune_slab.gd:57 test_roundtrip

## tests/test_safety.gd (110 lines) — Fixes from the code review: bad messages from a friend's computer, and items that
- tests/test_safety.gd:11 _setup
- tests/test_safety.gd:32 _teardown
- tests/test_safety.gd:36 test_a_stretched_aim_cant_dig_far_away
- tests/test_safety.gd:59 test_broken_numbers_are_refused
- tests/test_safety.gd:71 test_waterskin_keeps_its_sips_in_a_chest
- tests/test_safety.gd:90 test_unknown_rune_is_not_eaten
- tests/test_safety.gd:99 test_smelting_jobs_survive_a_save

## tests/test_save.gd (163 lines) — Saving and loading a world.
- tests/test_save.gd:8 FakeMain
- tests/test_save.gd:16 _world
- tests/test_save.gd:44 _clean
- tests/test_save.gd:50 test_save_and_load_a_world
- tests/test_save.gd:105 test_backups_and_broken_saves
- tests/test_save.gd:129 test_robots_never_touch_real_saves
- tests/test_save.gd:146 test_claude_test_worlds_are_marked_and_only_they_get_deleted

## tests/test_scripts_load.gd (22 lines) — Every script in the game must load. (Nov 14: hud.gd had a type error that broke the game at
- tests/test_scripts_load.gd:6 test_every_script_compiles

## tests/test_sfx.gd (28 lines) — Every sound the game asks for must exist (a missing file is just silence, easy to miss).
- tests/test_sfx.gd:5 _sound_names_in_code
- tests/test_sfx.gd:21 test_every_sound_used_in_code_loads

## tests/test_skeleton_miners.gd (266 lines) — The skeleton miners of Lampwick Drift and Old Pell's Diggings (Nov 20): Tunnel Rat, Lost Miner, the Foreman.
- tests/test_skeleton_miners.gd:11 _setup
- tests/test_skeleton_miners.gd:40 _teardown
- tests/test_skeleton_miners.gd:44 _spawn
- tests/test_skeleton_miners.gd:51 test_miners_have_skeletons_and_their_looks
- tests/test_skeleton_miners.gd:75 test_bones_rise_when_you_come_near
- tests/test_skeleton_miners.gd:97 test_hit_pile_gets_up
- tests/test_skeleton_miners.gd:108 test_miner_numbers
- tests/test_skeleton_miners.gd:127 test_no_crystal_miners
- tests/test_skeleton_miners.gd:135 test_falls_apart_then_stone
- tests/test_skeleton_miners.gd:166 test_foreman_spin_rests
- tests/test_skeleton_miners.gd:184 test_piles_lie_every_way_and_the_foreman_smashes_stone
- tests/test_skeleton_miners.gd:200 test_stone_corpses_dont_block_and_lose_their_stars
- tests/test_skeleton_miners.gd:216 test_pick_glint_comes_before_the_blow
- tests/test_skeleton_miners.gd:228 test_foreman_whirl_chases_and_lost_miners_leap
- tests/test_skeleton_miners.gd:256 test_the_spark_sits_on_the_tool_points

## tests/test_sound_settings.gd (38 lines) — The volume slider and Mute switch on the pause screen (feedback F15).
- tests/test_sound_settings.gd:7 test_mute_and_volume_change_the_sound_and_are_remembered
- tests/test_sound_settings.gd:28 test_mouse_speed_is_remembered

## tests/test_start.gd (135 lines) — The new start (feedback F10, F11, F12): a small sealed room, a soft wall, a tunnel to the
- tests/test_start.gd:6 test_every_cave_gets_a_start_room
- tests/test_start.gd:17 test_room_is_sealed_by_a_soft_dirt_wall
- tests/test_start.gd:46 test_start_room_has_roots_mushrooms_and_a_glow_behind_the_wall
- tests/test_start.gd:67 test_reachable_crystals_in_every_big_cavern
- tests/test_start.gd:83 test_first_tools_by_hand_from_the_room
- tests/test_start.gd:98 test_waking_with_nothing_and_the_lantern_rules

## tests/test_storage.gd (219 lines) — Chests, graves and dying.
- tests/test_storage.gd:10 _setup
- tests/test_storage.gd:31 _teardown
- tests/test_storage.gd:35 test_inventory_any_size
- tests/test_storage.gd:41 test_chest_place_fill_and_empty
- tests/test_storage.gd:62 test_too_far_from_chest
- tests/test_storage.gd:70 test_builder_chest_only_takes_building_stuff
- tests/test_storage.gd:77 test_dying_makes_a_grave_and_keeps_tools
- tests/test_storage.gd:97 test_empty_grave_crumbles
- tests/test_storage.gd:112 test_box_menu_closes_when_emptied
- tests/test_storage.gd:136 test_chest_lid_swings_open_and_shut
- tests/test_storage.gd:182 test_dev_item_menu_gives_items

## tests/test_ui_kit.gd (60 lines) — The "dwarf workshop" menus (owner F187): the kit pieces, and the fewer-clicks bag actions.
- tests/test_ui_kit.gd:5 test_kit_pieces_load_and_stretch_without_smearing
- tests/test_ui_kit.gd:17 test_right_click_splits_a_stack_in_half
- tests/test_ui_kit.gd:27 test_shift_click_moves_between_hotbar_and_bag
- tests/test_ui_kit.gd:45 test_blueprint_preview_builds_the_pieces

## tests/test_upgrades.gd (63 lines) — Gear upgrades +1 to +3 (building polish spec §4).
- tests/test_upgrades.gd:5 test_rules
- tests/test_upgrades.gd:20 test_upgrading_at_a_station
- tests/test_upgrades.gd:46 test_upgraded_armor_and_weapons_are_stronger
- tests/test_upgrades.gd:57 test_upgrade_level_is_saved

## tests/test_visuals.gd (253 lines) — The look of the game: shared materials, the rigged dwarf, tools, fire, rock chips, textures.
- tests/test_visuals.gd:5 test_look_materials_are_shared_and_textured
- tests/test_visuals.gd:16 test_terrain_textures_have_one_slice_per_material
- tests/test_visuals.gd:23 test_rigged_dwarf_builds_and_animates
- tests/test_visuals.gd:47 test_sword_swings_the_ual_combo_slowly
- tests/test_visuals.gd:66 test_tools_sit_right_in_the_hands
- tests/test_visuals.gd:94 test_dwarf_is_short_and_wide
- tests/test_visuals.gd:122 test_tool_models_cover_every_tool
- tests/test_visuals.gd:136 test_fire_and_chips_make_particles
- tests/test_visuals.gd:149 test_armor_and_wear_show_on_the_dwarf
- tests/test_visuals.gd:167 test_monsters_have_moving_parts
- tests/test_visuals.gd:187 test_first_three_creatures
- tests/test_visuals.gd:211 test_forged_creatures

## tests/test_vitals.gd (220 lines)
- tests/test_vitals.gd:4 _minutes
- tests/test_vitals.gd:9 test_hunger_takes_about_40_minutes
- tests/test_vitals.gd:18 test_never_dies_from_hunger
- tests/test_vitals.gd:26 test_resting_halves_drain
- tests/test_vitals.gd:35 test_worse_meter_counts
- tests/test_vitals.gd:43 test_health_regen_waits_after_damage
- tests/test_vitals.gd:52 test_heals_one_health_every_five_seconds
- tests/test_vitals.gd:62 test_no_healing_in_the_dark
- tests/test_vitals.gd:73 test_stamina_costs_more_in_the_dark
- tests/test_vitals.gd:82 test_stamina_spend_and_regen
- tests/test_vitals.gd:92 test_buff_food_raises_max_health
- tests/test_vitals.gd:99 test_same_dish_refreshes_not_stacks
- tests/test_vitals.gd:108 test_two_foods_and_one_drink
- tests/test_vitals.gd:122 test_food_speeds_up_healing_to_the_cap
- tests/test_vitals.gd:135 test_buffs_run_out_and_clear_on_death
- tests/test_vitals.gd:148 test_raw_meat_can_upset_belly
- tests/test_vitals.gd:158 test_not_food_is_refused
- tests/test_vitals.gd:163 test_damage_reduction_food
- tests/test_vitals.gd:170 test_network_roundtrip
- tests/test_vitals.gd:180 test_meat_guards_and_bullet_lines
- tests/test_vitals.gd:192 test_second_wind
- tests/test_vitals.gd:206 test_god_mode_cannot_be_hurt_and_monsters_ignore_you

## tests/test_walking.gd (170 lines) — Can a dwarf walk on what you build? (owner's test list, Nov 15)
- tests/test_walking.gd:8 Walker
- tests/test_walking.gd:71 _piece
- tests/test_walking.gd:80 test_dwarf_walks_on_buildings

## tests/test_waterskin_fill.gd (50 lines) — F401 (owner, Nov 20): an empty waterskin fills with pool water at a pool or a waterfall's pool, nowhere else.
- tests/test_waterskin_fill.gd:9 _setup
- tests/test_waterskin_fill.gd:31 _held
- tests/test_waterskin_fill.gd:35 test_fills_only_at_water
- tests/test_waterskin_fill.gd:46 test_fills_standing_in_the_pool

## tests/test_world.gd (68 lines) — Checks that need the real Voxel Tools terrain loaded.
- tests/test_world.gd:5 _make_world
- tests/test_world.gd:17 _wait_ready
- tests/test_world.gd:25 test_world_loads_and_matches_cave_maker
- tests/test_world.gd:36 test_digging_makes_air_and_counts_rock
- tests/test_world.gd:52 test_border_rock_cannot_be_dug
- tests/test_world.gd:63 test_dig_size_survives_the_network_packing

## tools/art/bake_prop_textures.py (76 lines) — Bakes the "detail" textures for props, monsters and the dwarf (src/art/prop.gdshader).
- tools/art/bake_prop_textures.py:38 bake
- tools/art/bake_prop_textures.py:59 main

## tools/art/bake_terrain_looks.py (153 lines) — Gives every cave material 4 different looks (owner F213: "many paintings, not one").
- tools/art/bake_terrain_looks.py:34 spans
- tools/art/bake_terrain_looks.py:47 cut
- tools/art/bake_terrain_looks.py:61 seamless
- tools/art/bake_terrain_looks.py:70 blur_wrap
- tools/art/bake_terrain_looks.py:79 normal_from
- tools/art/bake_terrain_looks.py:90 painted_looks
- tools/art/bake_terrain_looks.py:103 mirrored_looks
- tools/art/bake_terrain_looks.py:120 main

## tools/art/bake_terrain_textures.py (166 lines) — Bakes the dig-anywhere rock textures from CC0 photo textures (ambientCG).
- tools/art/bake_terrain_textures.py:50 fetch
- tools/art/bake_terrain_textures.py:63 load
- tools/art/bake_terrain_textures.py:70 kuwahara
- tools/art/bake_terrain_textures.py:93 tint
- tools/art/bake_terrain_textures.py:100 glow_mask
- tools/art/bake_terrain_textures.py:114 bake_layer
- tools/art/bake_terrain_textures.py:142 main

## tools/art/cut_armor_tiles.py (50 lines) — Cuts an armor set's hand-painted ChatGPT sheet into 4 tiles that repeat without a seam (Claude, Nov 18, 2026).
- tools/art/cut_armor_tiles.py:24 seamless
- tools/art/cut_armor_tiles.py:34 main

## tools/art/cut_perk_icons.py (45 lines) — Cut a ChatGPT perk sheet (4 x 3 grid of stone tiles) into one 128 px picture per perk.
- tools/art/cut_perk_icons.py:16 tile_box
- tools/art/cut_perk_icons.py:28 main

## tools/art/make_creature_sounds.py (213 lines) — Makes the creature sounds, and swaps out the menu-ish sounds, using REAL recordings only.
- tools/art/make_creature_sounds.py:40 load
- tools/art/make_creature_sounds.py:47 rpg
- tools/art/make_creature_sounds.py:51 ours
- tools/art/make_creature_sounds.py:55 speed
- tools/art/make_creature_sounds.py:61 trim
- tools/art/make_creature_sounds.py:66 mix
- tools/art/make_creature_sounds.py:76 lowpass
- tools/art/make_creature_sounds.py:81 fade
- tools/art/make_creature_sounds.py:88 rasp
- tools/art/make_creature_sounds.py:97 bat_screech
- tools/art/make_creature_sounds.py:105 bat_flap
- tools/art/make_creature_sounds.py:111 snail_slam
- tools/art/make_creature_sounds.py:117 shell_clunk
- tools/art/make_creature_sounds.py:122 shell_clank
- tools/art/make_creature_sounds.py:128 beetle_hiss
- tools/art/make_creature_sounds.py:141 beetle_rumble
- tools/art/make_creature_sounds.py:159 open_
- tools/art/make_creature_sounds.py:163 close
- tools/art/make_creature_sounds.py:167 pickup
- tools/art/make_creature_sounds.py:172 refill
- tools/art/make_creature_sounds.py:177 death
- tools/art/make_creature_sounds.py:192 write
- tools/art/make_creature_sounds.py:200 main

## tools/art/make_page_icons.py (76 lines) — Recipe page icons (owner, Nov 19: "pages should look different"): one page kind per thing it teaches.
- tools/art/make_page_icons.py:20 norm
- tools/art/make_page_icons.py:36 tint
- tools/art/make_page_icons.py:43 ink_sketch
- tools/art/make_page_icons.py:55 seal

## tools/asset_forge/batch3d.py (85 lines) — Turn the icon sheets into 3D models, many at once (free, TripoSR on this PC).
- tools/asset_forge/batch3d.py:31 tool_height
- tools/asset_forge/batch3d.py:46 main

## tools/asset_forge/blender_cleanup.py (343 lines) — Blender cleanup for AI-made 3D models ("asset forge", step 4).
- tools/asset_forge/blender_cleanup.py:24 parse_args
- tools/asset_forge/blender_cleanup.py:46 load
- tools/asset_forge/blender_cleanup.py:61 join
- tools/asset_forge/blender_cleanup.py:79 drop_crumbs
- tools/asset_forge/blender_cleanup.py:112 _bounds
- tools/asset_forge/blender_cleanup.py:119 auto_level
- tools/asset_forge/blender_cleanup.py:137 place
- tools/asset_forge/blender_cleanup.py:156 tri_count
- tools/asset_forge/blender_cleanup.py:160 decimate
- tools/asset_forge/blender_cleanup.py:172 grade
- tools/asset_forge/blender_cleanup.py:180 fix_corner_colors
- tools/asset_forge/blender_cleanup.py:192 fix_textures
- tools/asset_forge/blender_cleanup.py:231 ensure_material
- tools/asset_forge/blender_cleanup.py:287 preview
- tools/asset_forge/blender_cleanup.py:321 main

## tools/asset_forge/build_creatures.py (83 lines) — Builds every hand-made creature (by Claude 3).
- tools/asset_forge/build_creatures.py:40 blender
- tools/asset_forge/build_creatures.py:47 main

## tools/asset_forge/build_hand.py (55 lines) — Build hand-made models and keep the journey copies.
- tools/asset_forge/build_hand.py:23 blender
- tools/asset_forge/build_hand.py:30 folder_of
- tools/asset_forge/build_hand.py:35 main

## tools/asset_forge/builds/_parts.py (114 lines) — Bigger shared parts built from the kit (chests, furnace domes, fire pits, chains).
- tools/asset_forge/builds/_parts.py:8 chest
- tools/asset_forge/builds/_parts.py:38 chain
- tools/asset_forge/builds/_parts.py:53 coals
- tools/asset_forge/builds/_parts.py:63 dome
- tools/asset_forge/builds/_parts.py:85 chimney
- tools/asset_forge/builds/_parts.py:93 fire_pit
- tools/asset_forge/builds/_parts.py:108 log_pile

## tools/asset_forge/builds/anvil.py (53 lines) — Anvil (folder: stations): a forged iron anvil (stepped feet, tapered waist, heel, hardy hole, a horn that grow

## tools/asset_forge/builds/barrel_box.py (58 lines) — Loot barrel (folder: stations): the building kit's barrel (build_pieces.py barrel(), F61), but open-topped wit
- tools/asset_forge/builds/barrel_box.py:20 G

## tools/asset_forge/builds/bed.py (65 lines) — Bed (folder: stations): a plank bed with rounded posts and one plain, slightly lumpy straw-and-linen mattress.

## tools/asset_forge/builds/bellows.py (29 lines) — Bellows (folder: stations): leather forge bellows between two wooden boards, iron nozzle and handles, on a sma

## tools/asset_forge/builds/build_pieces.py (750 lines) — Building pieces (folder: build), hand-built from the kit, in every material family.
- tools/asset_forge/builds/build_pieces.py:40 G
- tools/asset_forge/builds/build_pieces.py:44 GS
- tools/asset_forge/builds/build_pieces.py:48 tm
- tools/asset_forge/builds/build_pieces.py:52 gbox
- tools/asset_forge/builds/build_pieces.py:58 gcyl
- tools/asset_forge/builds/build_pieces.py:63 gmesh
- tools/asset_forge/builds/build_pieces.py:67 gprism_x
- tools/asset_forge/builds/build_pieces.py:78 gprism_y
- tools/asset_forge/builds/build_pieces.py:88 gprism_z
- tools/asset_forge/builds/build_pieces.py:100 wall_fill
- tools/asset_forge/builds/build_pieces.py:145 floor_fill
- tools/asset_forge/builds/build_pieces.py:172 wall_fill_floor_metal
- tools/asset_forge/builds/build_pieces.py:178 timber
- tools/asset_forge/builds/build_pieces.py:212 wall
- tools/asset_forge/builds/build_pieces.py:249 edge_trim
- tools/asset_forge/builds/build_pieces.py:260 floor
- tools/asset_forge/builds/build_pieces.py:269 foundation
- tools/asset_forge/builds/build_pieces.py:297 roof
- tools/asset_forge/builds/build_pieces.py:316 ridge
- tools/asset_forge/builds/build_pieces.py:330 roof_corner
- tools/asset_forge/builds/build_pieces.py:354 gable
- tools/asset_forge/builds/build_pieces.py:369 pillar
- tools/asset_forge/builds/build_pieces.py:376 column_parts
- tools/asset_forge/builds/build_pieces.py:407 beam
- tools/asset_forge/builds/build_pieces.py:411 brace
- tools/asset_forge/builds/build_pieces.py:419 arch
- tools/asset_forge/builds/build_pieces.py:433 stairs
- tools/asset_forge/builds/build_pieces.py:449 ramp
- tools/asset_forge/builds/build_pieces.py:471 ladder
- tools/asset_forge/builds/build_pieces.py:481 railing
- tools/asset_forge/builds/build_pieces.py:493 door
- tools/asset_forge/builds/build_pieces.py:508 ceiling_panel
- tools/asset_forge/builds/build_pieces.py:514 mine_prop
- tools/asset_forge/builds/build_pieces.py:523 diagonal
- tools/asset_forge/builds/build_pieces.py:539 wood_or
- tools/asset_forge/builds/build_pieces.py:543 table
- tools/asset_forge/builds/build_pieces.py:555 bench
- tools/asset_forge/builds/build_pieces.py:562 chair
- tools/asset_forge/builds/build_pieces.py:573 shelf
- tools/asset_forge/builds/build_pieces.py:585 barrel
- tools/asset_forge/builds/build_pieces.py:610 crate
- tools/asset_forge/builds/build_pieces.py:624 rug
- tools/asset_forge/builds/build_pieces.py:633 banner
- tools/asset_forge/builds/build_pieces.py:662 wall_shield
- tools/asset_forge/builds/build_pieces.py:675 wall_sconce
- tools/asset_forge/builds/build_pieces.py:686 weapon_rack

## tools/asset_forge/builds/campfire.py (16 lines) — Campfire (folder: stations): a ring of stones around a teepee of straight logs and glowing coals; the game pla

## tools/asset_forge/builds/carpenters_vise.py (34 lines) — Carpenter's Vise (folder: stations): a heavy plank bench with a big iron screw vise on its front edge.

## tools/asset_forge/builds/cave_boulders.py (140 lines) — Breakable boulders (owner, Nov 18, 2026: "rocks like in Conan Exiles that you can break to get some stone, mul
- tools/asset_forge/builds/cave_boulders.py:33 chunk
- tools/asset_forge/builds/cave_boulders.py:54 finish
- tools/asset_forge/builds/cave_boulders.py:61 boulder_round
- tools/asset_forge/builds/cave_boulders.py:68 boulder_tall
- tools/asset_forge/builds/cave_boulders.py:77 boulder_slabs
- tools/asset_forge/builds/cave_boulders.py:87 boulder_cluster
- tools/asset_forge/builds/cave_boulders.py:95 boulder_split

## tools/asset_forge/builds/cave_cover.py (514 lines) — Cave ground cover, batch 1 of docs/design/cave-life-plan.md (F188; owner: "I want moss to be fluffy, some gras
- tools/asset_forge/builds/cave_cover.py:47 fix_xf
- tools/asset_forge/builds/cave_cover.py:54 cut_below
- tools/asset_forge/builds/cave_cover.py:64 ribbon
- tools/asset_forge/builds/cave_cover.py:100 self_bake
- tools/asset_forge/builds/cave_cover.py:133 finish
- tools/asset_forge/builds/cave_cover.py:153 moss_paint
- tools/asset_forge/builds/cave_cover.py:157 moss_skin
- tools/asset_forge/builds/cave_cover.py:162 build_moss
- tools/asset_forge/builds/cave_cover.py:182 build_moss_drape
- tools/asset_forge/builds/cave_cover.py:211 build_grass
- tools/asset_forge/builds/cave_cover.py:242 hook_path
- tools/asset_forge/builds/cave_cover.py:255 hairs
- tools/asset_forge/builds/cave_cover.py:272 soil_heaps
- tools/asset_forge/builds/cave_cover.py:287 build_rootlet
- tools/asset_forge/builds/cave_cover.py:336 build_lichen
- tools/asset_forge/builds/cave_cover.py:371 build_fern
- tools/asset_forge/builds/cave_cover.py:423 build_gravel
- tools/asset_forge/builds/cave_cover.py:456 build_tinycaps
- tools/asset_forge/builds/cave_cover.py:487 tint_for_pictures

## tools/asset_forge/builds/cave_dripstone.py (135 lines) — Dripstone for cave ceilings (F232, owner Nov 17, 2026: "something on the walls and the roof besides crystals a
- tools/asset_forge/builds/cave_dripstone.py:37 rock_chunk
- tools/asset_forge/builds/cave_dripstone.py:48 stalactite
- tools/asset_forge/builds/cave_dripstone.py:66 drip_skin
- tools/asset_forge/builds/cave_dripstone.py:73 finish_parts
- tools/asset_forge/builds/cave_dripstone.py:87 build_a
- tools/asset_forge/builds/cave_dripstone.py:100 build_b
- tools/asset_forge/builds/cave_dripstone.py:111 build_d

## tools/asset_forge/builds/cave_hanging.py (161 lines) — Roots hanging from cave ceilings (F232, owner Nov 17, 2026; picture: assets/concepts/cave-decor/hanging_roots_
- tools/asset_forge/builds/cave_hanging.py:32 hang_path
- tools/asset_forge/builds/cave_hanging.py:42 forks
- tools/asset_forge/builds/cave_hanging.py:58 hairs
- tools/asset_forge/builds/cave_hanging.py:73 branch
- tools/asset_forge/builds/cave_hanging.py:105 bark_fn
- tools/asset_forge/builds/cave_hanging.py:114 finish
- tools/asset_forge/builds/cave_hanging.py:124 build_a
- tools/asset_forge/builds/cave_hanging.py:132 build_b
- tools/asset_forge/builds/cave_hanging.py:144 build_c

## tools/asset_forge/builds/cave_mushgrass.py (118 lines) — Mushroom grass (owner, Nov 18, 2026: "a small mushroom grass just in the first cave on most of the surfaces";
- tools/asset_forge/builds/cave_mushgrass.py:36 one
- tools/asset_forge/builds/cave_mushgrass.py:51 tuft
- tools/asset_forge/builds/cave_mushgrass.py:62 ring
- tools/asset_forge/builds/cave_mushgrass.py:72 mushgrass_a
- tools/asset_forge/builds/cave_mushgrass.py:76 mushgrass_b
- tools/asset_forge/builds/cave_mushgrass.py:82 mushgrass_c
- tools/asset_forge/builds/cave_mushgrass.py:86 mushgrass_d
- tools/asset_forge/builds/cave_mushgrass.py:90 mushgrass_e
- tools/asset_forge/builds/cave_mushgrass.py:94 mushgrass_f
- tools/asset_forge/builds/cave_mushgrass.py:106 tuft_far

## tools/asset_forge/builds/cave_plants.py (589 lines) — Cave plants and crystals, hand-built, sculpted and painted the Rock Beetle way (Claude 2, Nov 16, 2026; owner:
- tools/asset_forge/builds/cave_plants.py:49 grey
- tools/asset_forge/builds/cave_plants.py:53 tube
- tools/asset_forge/builds/cave_plants.py:59 smooth_path
- tools/asset_forge/builds/cave_plants.py:73 lump
- tools/asset_forge/builds/cave_plants.py:80 carve
- tools/asset_forge/builds/cave_plants.py:89 join
- tools/asset_forge/builds/cave_plants.py:103 bite
- tools/asset_forge/builds/cave_plants.py:114 twisted
- tools/asset_forge/builds/cave_plants.py:133 arch_path
- tools/asset_forge/builds/cave_plants.py:146 build_root
- tools/asset_forge/builds/cave_plants.py:248 mushroom
- tools/asset_forge/builds/cave_plants.py:291 build_glowcap
- tools/asset_forge/builds/cave_plants.py:328 prism
- tools/asset_forge/builds/cave_plants.py:379 build_crystal
- tools/asset_forge/builds/cave_plants.py:409 build_giant
- tools/asset_forge/builds/cave_plants.py:486 finish
- tools/asset_forge/builds/cave_plants.py:519 pictures
- tools/asset_forge/builds/cave_plants.py:566 export

## tools/asset_forge/builds/cave_rootpillar.py (207 lines) — Giant root pillars (F189, owner Nov 17, 2026: "huge twisted tree roots running floor to ceiling in some cavern
- tools/asset_forge/builds/cave_rootpillar.py:27 twist_root
- tools/asset_forge/builds/cave_rootpillar.py:45 build_a
- tools/asset_forge/builds/cave_rootpillar.py:58 build_b
- tools/asset_forge/builds/cave_rootpillar.py:75 build_braided
- tools/asset_forge/builds/cave_rootpillar.py:92 tree_bark_fn
- tools/asset_forge/builds/cave_rootpillar.py:107 tree_finish
- tools/asset_forge/builds/cave_rootpillar.py:120 moss_cushions
- tools/asset_forge/builds/cave_rootpillar.py:149 build_trunk
- tools/asset_forge/builds/cave_rootpillar.py:184 build_cage

## tools/asset_forge/builds/cave_shelves.py (126 lines) — Rock shelves on cave walls (F232, owner Nov 17, 2026; picture: assets/concepts/cave-decor/rock_shelves_sheet.p
- tools/asset_forge/builds/cave_shelves.py:35 chunk
- tools/asset_forge/builds/cave_shelves.py:57 wall
- tools/asset_forge/builds/cave_shelves.py:71 slab
- tools/asset_forge/builds/cave_shelves.py:90 rock_part
- tools/asset_forge/builds/cave_shelves.py:97 build_a
- tools/asset_forge/builds/cave_shelves.py:101 build_b
- tools/asset_forge/builds/cave_shelves.py:105 build_c
- tools/asset_forge/builds/cave_shelves.py:109 build_d

## tools/asset_forge/builds/chest_copper.py (45 lines) — Copper-bound Chest (folder: stations): a strongbox clad in copper corners and studs, with a raised hipped lid,

## tools/asset_forge/builds/chest_small.py (16 lines) — Chest (folder: stations): a plank chest with iron straps and a rounded lid.

## tools/asset_forge/builds/chest_stone.py (40 lines) — Stone Chest (folder: stations): a crate of thick stone slabs with iron corner bands and a hinged stone lid.

## tools/asset_forge/builds/chisel_rack.py (28 lines) — Chisel Rack (folder: stations): a stone mason's bench of cut stone with a wooden block holding a row of chisel

## tools/asset_forge/builds/chopping_block.py (27 lines) — Chopping Block (folder: stations): a thick banded stump with an axe buried in its top, wood chips around.

## tools/asset_forge/builds/cooking_pot.py (33 lines) — Cooking Pot (folder: stations): an iron pot hanging on a linked chain from a lashed log frame over a fire.

## tools/asset_forge/builds/copper_drip_basin.py (24 lines) — Copper Drip Basin (folder: stations): a riveted copper basin of still water with ripples under a falling drop.

## tools/asset_forge/builds/crate_ore.py (29 lines) — Ore Crate (folder: stations): an open plank crate with iron corner brackets (empty; the ore pile is crate_ore_

## tools/asset_forge/builds/crate_ore_fill.py (42 lines) — Ore Crate fill (folder: stations): the heap of ore inside the crate. Origin bottom-centre; at scale 1 and y=0.
- tools/asset_forge/builds/crate_ore_fill.py:28 surface

## tools/asset_forge/builds/critters.py (127 lines) — Tiny harmless cave life (F190, owner Nov 18: "critters: glowing beetles crawling on walls, little moths around
- tools/asset_forge/builds/critters.py:23 leg
- tools/asset_forge/builds/critters.py:29 _len
- tools/asset_forge/builds/critters.py:33 _mid
- tools/asset_forge/builds/critters.py:37 _rot
- tools/asset_forge/builds/critters.py:47 feeler
- tools/asset_forge/builds/critters.py:57 glow_beetle
- tools/asset_forge/builds/critters.py:75 moth_body
- tools/asset_forge/builds/critters.py:84 moth_wing
- tools/asset_forge/builds/critters.py:106 cave_cricket

## tools/asset_forge/builds/crystal_sconce.py (25 lines) — Crystal Sconce (folder: stations): a stone wall plate with a forged iron arm and cup holding a glowing amber c

## tools/asset_forge/builds/decor_nov21_a.py (1115 lines) — Decor group A (Nov 21): dungeon and ruin story pieces: abandoned, old, worn. Same style as night_decor.py.
- tools/asset_forge/builds/decor_nov21_a.py:27 objs
- tools/asset_forge/builds/decor_nov21_a.py:31 slim
- tools/asset_forge/builds/decor_nov21_a.py:53 turn
- tools/asset_forge/builds/decor_nov21_a.py:61 shift
- tools/asset_forge/builds/decor_nov21_a.py:66 low_z
- tools/asset_forge/builds/decor_nov21_a.py:70 rod
- tools/asset_forge/builds/decor_nov21_a.py:74 prism
- tools/asset_forge/builds/decor_nov21_a.py:87 circ
- tools/asset_forge/builds/decor_nov21_a.py:91 bar
- tools/asset_forge/builds/decor_nov21_a.py:101 chain
- tools/asset_forge/builds/decor_nov21_a.py:115 floor_cut
- tools/asset_forge/builds/decor_nov21_a.py:129 flat_back_rock
- tools/asset_forge/builds/decor_nov21_a.py:142 carve
- tools/asset_forge/builds/decor_nov21_a.py:168 groove
- tools/asset_forge/builds/decor_nov21_a.py:184 groove_path
- tools/asset_forge/builds/decor_nov21_a.py:191 groove_ring
- tools/asset_forge/builds/decor_nov21_a.py:195 rune_row
- tools/asset_forge/builds/decor_nov21_a.py:223 chip
- tools/asset_forge/builds/decor_nov21_a.py:228 tube
- tools/asset_forge/builds/decor_nov21_a.py:247 loft_x
- tools/asset_forge/builds/decor_nov21_a.py:262 rest
- tools/asset_forge/builds/decor_nov21_a.py:269 spin
- tools/asset_forge/builds/decor_nov21_a.py:275 rubble_heap
- tools/asset_forge/builds/decor_nov21_a.py:315 ancestor_stone_tall
- tools/asset_forge/builds/decor_nov21_a.py:373 ancestor_stone_small
- tools/asset_forge/builds/decor_nov21_a.py:414 paper
- tools/asset_forge/builds/decor_nov21_a.py:419 notice_board_torn
- tools/asset_forge/builds/decor_nov21_a.py:481 hanging_cage
- tools/asset_forge/builds/decor_nov21_a.py:525 wall_shackles
- tools/asset_forge/builds/decor_nov21_a.py:541 forge_bellows_broken
- tools/asset_forge/builds/decor_nov21_a.py:594 forge_anvil_cracked
- tools/asset_forge/builds/decor_nov21_a.py:632 skeleton_with_note
- tools/asset_forge/builds/decor_nov21_a.py:789 carving_slab
- tools/asset_forge/builds/decor_nov21_a.py:800 rl
- tools/asset_forge/builds/decor_nov21_a.py:805 dwarf
- tools/asset_forge/builds/decor_nov21_a.py:829 wall_carving_1
- tools/asset_forge/builds/decor_nov21_a.py:851 wall_carving_2
- tools/asset_forge/builds/decor_nov21_a.py:882 wall_carving_3
- tools/asset_forge/builds/decor_nov21_a.py:918 hit_y
- tools/asset_forge/builds/decor_nov21_a.py:926 pickaxe_in_wall
- tools/asset_forge/builds/decor_nov21_a.py:977 miner_tent
- tools/asset_forge/builds/decor_nov21_a.py:1020 lantern_post_burnt
- tools/asset_forge/builds/decor_nov21_a.py:1049 rope_ladder_broken

## tools/asset_forge/builds/decor_nov21_b.py (897 lines) — Decor group B (Nov 21): dungeon and ruin story pieces: old, abandoned, worn. Same style as night_decor.py.
- tools/asset_forge/builds/decor_nov21_b.py:27 flat_back
- tools/asset_forge/builds/decor_nov21_b.py:42 strip
- tools/asset_forge/builds/decor_nov21_b.py:54 bone
- tools/asset_forge/builds/decor_nov21_b.py:66 skull
- tools/asset_forge/builds/decor_nov21_b.py:84 crack_line
- tools/asset_forge/builds/decor_nov21_b.py:91 coin
- tools/asset_forge/builds/decor_nov21_b.py:98 _aim
- tools/asset_forge/builds/decor_nov21_b.py:109 _curl
- tools/asset_forge/builds/decor_nov21_b.py:119 stone_dwarf
- tools/asset_forge/builds/decor_nov21_b.py:177 statue_stone
- tools/asset_forge/builds/decor_nov21_b.py:184 stone_axe
- tools/asset_forge/builds/decor_nov21_b.py:201 plinth_runes
- tools/asset_forge/builds/decor_nov21_b.py:209 statue_toppled
- tools/asset_forge/builds/decor_nov21_b.py:270 statue_cracked_plinth
- tools/asset_forge/builds/decor_nov21_b.py:296 shrine_broken
- tools/asset_forge/builds/decor_nov21_b.py:327 thin_coin
- tools/asset_forge/builds/decor_nov21_b.py:338 coin_stack
- tools/asset_forge/builds/decor_nov21_b.py:347 offering_bowl_coins
- tools/asset_forge/builds/decor_nov21_b.py:396 altar_candles
- tools/asset_forge/builds/decor_nov21_b.py:428 _sarcophagus
- tools/asset_forge/builds/decor_nov21_b.py:470 sarcophagus_closed
- tools/asset_forge/builds/decor_nov21_b.py:475 sarcophagus_open
- tools/asset_forge/builds/decor_nov21_b.py:480 bone_pile
- tools/asset_forge/builds/decor_nov21_b.py:507 skull_spike
- tools/asset_forge/builds/decor_nov21_b.py:522 spider_eggs
- tools/asset_forge/builds/decor_nov21_b.py:551 web
- tools/asset_forge/builds/decor_nov21_b.py:595 cobweb_corner
- tools/asset_forge/builds/decor_nov21_b.py:639 cobweb_beams
- tools/asset_forge/builds/decor_nov21_b.py:663 stave
- tools/asset_forge/builds/decor_nov21_b.py:692 round_board
- tools/asset_forge/builds/decor_nov21_b.py:700 barrel_smashed
- tools/asset_forge/builds/decor_nov21_b.py:765 well_dry
- tools/asset_forge/builds/decor_nov21_b.py:807 wood_bucket
- tools/asset_forge/builds/decor_nov21_b.py:828 bookshelf_collapsed

## tools/asset_forge/builds/decor_nov21_bv.py (1394 lines) — Decor set BV (Nov 21): BRASSGATE VAULT, a MEDIUM dungeon in cut stone (Stonehold style): the old treasury and
- tools/asset_forge/builds/decor_nov21_bv.py:69 BRASS
- tools/asset_forge/builds/decor_nov21_bv.py:91 drop
- tools/asset_forge/builds/decor_nov21_bv.py:98 stack
- tools/asset_forge/builds/decor_nov21_bv.py:106 coin_fan
- tools/asset_forge/builds/decor_nov21_bv.py:118 ledger
- tools/asset_forge/builds/decor_nov21_bv.py:132 page
- tools/asset_forge/builds/decor_nov21_bv.py:141 open_ledger
- tools/asset_forge/builds/decor_nov21_bv.py:151 quill
- tools/asset_forge/builds/decor_nov21_bv.py:159 inkwell
- tools/asset_forge/builds/decor_nov21_bv.py:165 bell_weight
- tools/asset_forge/builds/decor_nov21_bv.py:174 disc_weights
- tools/asset_forge/builds/decor_nov21_bv.py:186 balance
- tools/asset_forge/builds/decor_nov21_bv.py:223 ingot
- tools/asset_forge/builds/decor_nov21_bv.py:230 strongbox
- tools/asset_forge/builds/decor_nov21_bv.py:281 padlock
- tools/asset_forge/builds/decor_nov21_bv.py:291 stool
- tools/asset_forge/builds/decor_nov21_bv.py:305 scales_emblem
- tools/asset_forge/builds/decor_nov21_bv.py:319 key_emblem
- tools/asset_forge/builds/decor_nov21_bv.py:330 hook
- tools/asset_forge/builds/decor_nov21_bv.py:339 tag
- tools/asset_forge/builds/decor_nov21_bv.py:345 halberd
- tools/asset_forge/builds/decor_nov21_bv.py:361 wall_slab
- tools/asset_forge/builds/decor_nov21_bv.py:367 bv_counting_table
- tools/asset_forge/builds/decor_nov21_bv.py:411 bv_count_abandoned
- tools/asset_forge/builds/decor_nov21_bv.py:445 bv_balance_great
- tools/asset_forge/builds/decor_nov21_bv.py:462 bv_ledger_desk
- tools/asset_forge/builds/decor_nov21_bv.py:493 bv_strongbox
- tools/asset_forge/builds/decor_nov21_bv.py:500 bv_strongbox_looted
- tools/asset_forge/builds/decor_nov21_bv.py:518 bv_coin_chest_tipped
- tools/asset_forge/builds/decor_nov21_bv.py:535 bv_coin_chest_tipped_empty
- tools/asset_forge/builds/decor_nov21_bv.py:539 bv_assay_bench
- tools/asset_forge/builds/decor_nov21_bv.py:582 bv_teller_counter
- tools/asset_forge/builds/decor_nov21_bv.py:627 bv_guard_post
- tools/asset_forge/builds/decor_nov21_bv.py:657 lantern
- tools/asset_forge/builds/decor_nov21_bv.py:675 bv_minting_block
- tools/asset_forge/builds/decor_nov21_bv.py:736 bv_assay_furnace
- tools/asset_forge/builds/decor_nov21_bv.py:813 bv_coin_cart
- tools/asset_forge/builds/decor_nov21_bv.py:840 bv_lockbox_pedestal
- tools/asset_forge/builds/decor_nov21_bv.py:876 bv_ledger_shelf
- tools/asset_forge/builds/decor_nov21_bv.py:933 key_board
- tools/asset_forge/builds/decor_nov21_bv.py:973 bv_key_rack
- tools/asset_forge/builds/decor_nov21_bv.py:977 bv_key_rack_looted
- tools/asset_forge/builds/decor_nov21_bv.py:981 bv_weight_shelf
- tools/asset_forge/builds/decor_nov21_bv.py:1011 bv_name_plaque
- tools/asset_forge/builds/decor_nov21_bv.py:1030 bv_coin_niche_found
- tools/asset_forge/builds/decor_nov21_bv.py:1060 bv_coin_niche_found_empty
- tools/asset_forge/builds/decor_nov21_bv.py:1064 bv_pigeonholes
- tools/asset_forge/builds/decor_nov21_bv.py:1111 bv_pigeonholes_empty
- tools/asset_forge/builds/decor_nov21_bv.py:1115 coin_bowl
- tools/asset_forge/builds/decor_nov21_bv.py:1123 vault_disc
- tools/asset_forge/builds/decor_nov21_bv.py:1155 vault_wall
- tools/asset_forge/builds/decor_nov21_bv.py:1227 bv_vault_door
- tools/asset_forge/builds/decor_nov21_bv.py:1231 bv_vault_door_forced
- tools/asset_forge/builds/decor_nov21_bv.py:1235 bv_lock_works
- tools/asset_forge/builds/decor_nov21_bv.py:1272 bv_guild_medallion
- tools/asset_forge/builds/decor_nov21_bv.py:1300 bv_wall_lantern
- tools/asset_forge/builds/decor_nov21_bv.py:1315 bv_halberd_rack
- tools/asset_forge/builds/decor_nov21_bv.py:1336 bv_lockbox_shelf

## tools/asset_forge/builds/decor_nov21_c.py (986 lines) — Decor, Nov 21 group C: dungeon and ruin story pieces, old and worn (maps, war drum, portcullis, prison bench,
- tools/asset_forge/builds/decor_nov21_c.py:30 slab_xz
- tools/asset_forge/builds/decor_nov21_c.py:38 tube
- tools/asset_forge/builds/decor_nov21_c.py:60 chain
- tools/asset_forge/builds/decor_nov21_c.py:76 line_xz
- tools/asset_forge/builds/decor_nov21_c.py:84 wall_slab
- tools/asset_forge/builds/decor_nov21_c.py:103 mug
- tools/asset_forge/builds/decor_nov21_c.py:120 plate
- tools/asset_forge/builds/decor_nov21_c.py:126 splinters
- tools/asset_forge/builds/decor_nov21_c.py:139 ground_lump
- tools/asset_forge/builds/decor_nov21_c.py:147 turn
- tools/asset_forge/builds/decor_nov21_c.py:153 low_z
- tools/asset_forge/builds/decor_nov21_c.py:158 map_torn_wall
- tools/asset_forge/builds/decor_nov21_c.py:245 tally_marks
- tools/asset_forge/builds/decor_nov21_c.py:266 graffiti_pell
- tools/asset_forge/builds/decor_nov21_c.py:305 war_drum_split
- tools/asset_forge/builds/decor_nov21_c.py:362 horn_shell
- tools/asset_forge/builds/decor_nov21_c.py:389 war_horn_stand
- tools/asset_forge/builds/decor_nov21_c.py:442 stone_column
- tools/asset_forge/builds/decor_nov21_c.py:449 portcullis_rusted
- tools/asset_forge/builds/decor_nov21_c.py:482 floor_grate
- tools/asset_forge/builds/decor_nov21_c.py:535 hanging_hook
- tools/asset_forge/builds/decor_nov21_c.py:558 plank_crate
- tools/asset_forge/builds/decor_nov21_c.py:593 dice_on_crate
- tools/asset_forge/builds/decor_nov21_c.py:622 last_meal
- tools/asset_forge/builds/decor_nov21_c.py:664 ring_wall
- tools/asset_forge/builds/decor_nov21_c.py:673 pit_bucket
- tools/asset_forge/builds/decor_nov21_c.py:707 coal_pile_shovel
- tools/asset_forge/builds/decor_nov21_c.py:785 cage_floor_open
- tools/asset_forge/builds/decor_nov21_c.py:838 prison_bench
- tools/asset_forge/builds/decor_nov21_c.py:866 chandelier_fallen
- tools/asset_forge/builds/decor_nov21_c.py:900 table_overturned
- tools/asset_forge/builds/decor_nov21_c.py:920 ore_crusher_broken

## tools/asset_forge/builds/decor_nov21_cf.py (1549 lines) — Decor set CF (Nov 21): CINDERHOLD FOUNDRY, a big clay-brick dungeon where dwarves melted metal and cast bells,
- tools/asset_forge/builds/decor_nov21_cf.py:56 P
- tools/asset_forge/builds/decor_nov21_cf.py:77 CLAY
- tools/asset_forge/builds/decor_nov21_cf.py:82 BRICK
- tools/asset_forge/builds/decor_nov21_cf.py:87 objs
- tools/asset_forge/builds/decor_nov21_cf.py:91 since
- tools/asset_forge/builds/decor_nov21_cf.py:95 turn
- tools/asset_forge/builds/decor_nov21_cf.py:102 group
- tools/asset_forge/builds/decor_nov21_cf.py:114 low_z
- tools/asset_forge/builds/decor_nov21_cf.py:119 settle
- tools/asset_forge/builds/decor_nov21_cf.py:126 rod
- tools/asset_forge/builds/decor_nov21_cf.py:130 prism
- tools/asset_forge/builds/decor_nov21_cf.py:143 strip
- tools/asset_forge/builds/decor_nov21_cf.py:163 lathe
- tools/asset_forge/builds/decor_nov21_cf.py:186 carve
- tools/asset_forge/builds/decor_nov21_cf.py:205 groove
- tools/asset_forge/builds/decor_nov21_cf.py:213 groove_path
- tools/asset_forge/builds/decor_nov21_cf.py:220 hole
- tools/asset_forge/builds/decor_nov21_cf.py:225 rune_row
- tools/asset_forge/builds/decor_nov21_cf.py:247 floor_cut
- tools/asset_forge/builds/decor_nov21_cf.py:261 spin
- tools/asset_forge/builds/decor_nov21_cf.py:266 heap
- tools/asset_forge/builds/decor_nov21_cf.py:307 brick_block
- tools/asset_forge/builds/decor_nov21_cf.py:324 brick_ring
- tools/asset_forge/builds/decor_nov21_cf.py:347 crucible
- tools/asset_forge/builds/decor_nov21_cf.py:369 bell
- tools/asset_forge/builds/decor_nov21_cf.py:382 settle_pile
- tools/asset_forge/builds/decor_nov21_cf.py:418 coal_tones
- tools/asset_forge/builds/decor_nov21_cf.py:423 bell_profile
- tools/asset_forge/builds/decor_nov21_cf.py:435 bell_r
- tools/asset_forge/builds/decor_nov21_cf.py:444 bell_big
- tools/asset_forge/builds/decor_nov21_cf.py:489 sandy
- tools/asset_forge/builds/decor_nov21_cf.py:509 ingot
- tools/asset_forge/builds/decor_nov21_cf.py:517 wall_board
- tools/asset_forge/builds/decor_nov21_cf.py:524 rack_back
- tools/asset_forge/builds/decor_nov21_cf.py:534 wall_shelf
- tools/asset_forge/builds/decor_nov21_cf.py:544 iron_hook
- tools/asset_forge/builds/decor_nov21_cf.py:553 peg
- tools/asset_forge/builds/decor_nov21_cf.py:557 tongs
- tools/asset_forge/builds/decor_nov21_cf.py:583 bowl
- tools/asset_forge/builds/decor_nov21_cf.py:590 ladle_hang
- tools/asset_forge/builds/decor_nov21_cf.py:611 shell
- tools/asset_forge/builds/decor_nov21_cf.py:627 flask
- tools/asset_forge/builds/decor_nov21_cf.py:648 cf_tongs_wall
- tools/asset_forge/builds/decor_nov21_cf.py:664 cf_ladle_rack
- tools/asset_forge/builds/decor_nov21_cf.py:684 cf_pattern_shelf
- tools/asset_forge/builds/decor_nov21_cf.py:720 cf_crucible_shelf
- tools/asset_forge/builds/decor_nov21_cf.py:738 cf_skimmer_rack
- tools/asset_forge/builds/decor_nov21_cf.py:776 cf_mould_board
- tools/asset_forge/builds/decor_nov21_cf.py:818 cf_master_mark_stone
- tools/asset_forge/builds/decor_nov21_cf.py:853 cf_strickle_board
- tools/asset_forge/builds/decor_nov21_cf.py:891 cf_casting_shelf
- tools/asset_forge/builds/decor_nov21_cf.py:926 cf_flux_shelf
- tools/asset_forge/builds/decor_nov21_cf.py:969 brick_block_y
- tools/asset_forge/builds/decor_nov21_cf.py:974 brick_floor
- tools/asset_forge/builds/decor_nov21_cf.py:991 embers
- tools/asset_forge/builds/decor_nov21_cf.py:1002 tongs_at
- tools/asset_forge/builds/decor_nov21_cf.py:1008 cf_crucible_furnace
- tools/asset_forge/builds/decor_nov21_cf.py:1035 cf_crucible_stand
- tools/asset_forge/builds/decor_nov21_cf.py:1050 cf_crucible_shank
- tools/asset_forge/builds/decor_nov21_cf.py:1066 cf_flask_stack
- tools/asset_forge/builds/decor_nov21_cf.py:1091 cf_mould_box_open
- tools/asset_forge/builds/decor_nov21_cf.py:1118 cf_ingot_mould_row
- tools/asset_forge/builds/decor_nov21_cf.py:1147 cf_ingot_stack
- tools/asset_forge/builds/decor_nov21_cf.py:1173 cf_ingot_stack_empty
- tools/asset_forge/builds/decor_nov21_cf.py:1177 cf_bell_pit
- tools/asset_forge/builds/decor_nov21_cf.py:1200 cf_bell_cracked
- tools/asset_forge/builds/decor_nov21_cf.py:1229 slag_cart
- tools/asset_forge/builds/decor_nov21_cf.py:1262 cf_slag_cart
- tools/asset_forge/builds/decor_nov21_cf.py:1266 cf_slag_cart_tipped
- tools/asset_forge/builds/decor_nov21_cf.py:1288 cf_flux_tub
- tools/asset_forge/builds/decor_nov21_cf.py:1312 cf_cooling_rack
- tools/asset_forge/builds/decor_nov21_cf.py:1347 cf_crucible_dropped
- tools/asset_forge/builds/decor_nov21_cf.py:1372 cf_sand_bin
- tools/asset_forge/builds/decor_nov21_cf.py:1398 cf_moulders_bench
- tools/asset_forge/builds/decor_nov21_cf.py:1430 cf_quench_trough
- tools/asset_forge/builds/decor_nov21_cf.py:1458 cf_scrap_crate
- tools/asset_forge/builds/decor_nov21_cf.py:1484 cf_charcoal_bay
- tools/asset_forge/builds/decor_nov21_cf.py:1516 cf_charcoal_bay_empty

## tools/asset_forge/builds/decor_nov21_d.py (421 lines) — Decor batch Nov 21 (group d): a root-wrapped column, a faded banner and home trophies.
- tools/asset_forge/builds/decor_nov21_d.py:24 tube
- tools/asset_forge/builds/decor_nov21_d.py:44 root
- tools/asset_forge/builds/decor_nov21_d.py:48 slab
- tools/asset_forge/builds/decor_nov21_d.py:58 rot2
- tools/asset_forge/builds/decor_nov21_d.py:63 glass
- tools/asset_forge/builds/decor_nov21_d.py:79 column_rootwrapped
- tools/asset_forge/builds/decor_nov21_d.py:135 banner_torn_faded
- tools/asset_forge/builds/decor_nov21_d.py:167 gem_stand
- tools/asset_forge/builds/decor_nov21_d.py:181 gem_case
- tools/asset_forge/builds/decor_nov21_d.py:209 ore_sample_shelf
- tools/asset_forge/builds/decor_nov21_d.py:236 tooth_necklace
- tools/asset_forge/builds/decor_nov21_d.py:257 bat_wing_trophy
- tools/asset_forge/builds/decor_nov21_d.py:280 sword
- tools/asset_forge/builds/decor_nov21_d.py:290 crossed_swords
- tools/asset_forge/builds/decor_nov21_d.py:297 crossed_axes
- tools/asset_forge/builds/decor_nov21_d.py:317 medal_board
- tools/asset_forge/builds/decor_nov21_d.py:335 golden_pickaxe
- tools/asset_forge/builds/decor_nov21_d.py:349 first_coin_frame
- tools/asset_forge/builds/decor_nov21_d.py:371 foreman_helmet_trophy

## tools/asset_forge/builds/decor_nov21_e.py (565 lines) — Cosy dwarf-home decor (Nov 21, group e): bedroom, washroom, study, tavern and kitchen pieces in warm wood and 
- tools/asset_forge/builds/decor_nov21_e.py:26 bar
- tools/asset_forge/builds/decor_nov21_e.py:41 floor_post
- tools/asset_forge/builds/decor_nov21_e.py:47 mug
- tools/asset_forge/builds/decor_nov21_e.py:55 rocking_chair
- tools/asset_forge/builds/decor_nov21_e.py:75 fur_rug
- tools/asset_forge/builds/decor_nov21_e.py:125 hammock
- tools/asset_forge/builds/decor_nov21_e.py:169 bunk_bed
- tools/asset_forge/builds/decor_nov21_e.py:214 wardrobe
- tools/asset_forge/builds/decor_nov21_e.py:240 bathtub_barrel
- tools/asset_forge/builds/decor_nov21_e.py:267 washbasin
- tools/asset_forge/builds/decor_nov21_e.py:288 boot_rack
- tools/asset_forge/builds/decor_nov21_e.py:304 writing_desk
- tools/asset_forge/builds/decor_nov21_e.py:332 world_stone
- tools/asset_forge/builds/decor_nov21_e.py:363 storage_trunk
- tools/asset_forge/builds/decor_nov21_e.py:411 bar_counter
- tools/asset_forge/builds/decor_nov21_e.py:430 tap_keg_stand
- tools/asset_forge/builds/decor_nov21_e.py:455 mug_rack
- tools/asset_forge/builds/decor_nov21_e.py:472 bread_oven
- tools/asset_forge/builds/decor_nov21_e.py:497 cooking_spit

## tools/asset_forge/builds/decor_nov21_ef.py (1461 lines) — Decor set EF (Nov 21): EMBERDEEP FORGE, a BIG dungeon in clay brick and fire (Hearthbrick style): the great
- tools/asset_forge/builds/decor_nov21_ef.py:81 new_since
- tools/asset_forge/builds/decor_nov21_ef.py:85 group
- tools/asset_forge/builds/decor_nov21_ef.py:97 settle
- tools/asset_forge/builds/decor_nov21_ef.py:106 rod
- tools/asset_forge/builds/decor_nov21_ef.py:110 cut
- tools/asset_forge/builds/decor_nov21_ef.py:117 brick_m
- tools/asset_forge/builds/decor_nov21_ef.py:122 brick_row
- tools/asset_forge/builds/decor_nov21_ef.py:141 brick_box
- tools/asset_forge/builds/decor_nov21_ef.py:162 brick_wall
- tools/asset_forge/builds/decor_nov21_ef.py:172 lime_cap
- tools/asset_forge/builds/decor_nov21_ef.py:189 mark
- tools/asset_forge/builds/decor_nov21_ef.py:200 turned
- tools/asset_forge/builds/decor_nov21_ef.py:217 coal_heap
- tools/asset_forge/builds/decor_nov21_ef.py:239 coal_bits
- tools/asset_forge/builds/decor_nov21_ef.py:248 tongs
- tools/asset_forge/builds/decor_nov21_ef.py:273 hammer
- tools/asset_forge/builds/decor_nov21_ef.py:290 fine
- tools/asset_forge/builds/decor_nov21_ef.py:299 sword
- tools/asset_forge/builds/decor_nov21_ef.py:325 sword_tip
- tools/asset_forge/builds/decor_nov21_ef.py:333 axe
- tools/asset_forge/builds/decor_nov21_ef.py:346 file_tool
- tools/asset_forge/builds/decor_nov21_ef.py:355 punch
- tools/asset_forge/builds/decor_nov21_ef.py:363 shield
- tools/asset_forge/builds/decor_nov21_ef.py:381 anvil
- tools/asset_forge/builds/decor_nov21_ef.py:398 stump
- tools/asset_forge/builds/decor_nov21_ef.py:409 bench
- tools/asset_forge/builds/decor_nov21_ef.py:429 ingot
- tools/asset_forge/builds/decor_nov21_ef.py:434 hood_shell
- tools/asset_forge/builds/decor_nov21_ef.py:446 tag_plate
- tools/asset_forge/builds/decor_nov21_ef.py:454 ef_tong_rack
- tools/asset_forge/builds/decor_nov21_ef.py:488 ef_hammer_rack
- tools/asset_forge/builds/decor_nov21_ef.py:517 ef_blade_rack
- tools/asset_forge/builds/decor_nov21_ef.py:540 ef_master_display
- tools/asset_forge/builds/decor_nov21_ef.py:597 ef_smiths_lintel
- tools/asset_forge/builds/decor_nov21_ef.py:615 ef_file_board
- tools/asset_forge/builds/decor_nov21_ef.py:648 ef_mould_shelf
- tools/asset_forge/builds/decor_nov21_ef.py:690 ef_chimney_hood
- tools/asset_forge/builds/decor_nov21_ef.py:736 ef_ingot_wall
- tools/asset_forge/builds/decor_nov21_ef.py:772 ef_commission_board
- tools/asset_forge/builds/decor_nov21_ef.py:814 ef_blade_on_anvil
- tools/asset_forge/builds/decor_nov21_ef.py:830 ef_cracked_quench
- tools/asset_forge/builds/decor_nov21_ef.py:853 ef_bent_blade_vise
- tools/asset_forge/builds/decor_nov21_ef.py:897 ef_axe_progression
- tools/asset_forge/builds/decor_nov21_ef.py:931 ef_fallen_hood
- tools/asset_forge/builds/decor_nov21_ef.py:964 ef_burst_crucible
- tools/asset_forge/builds/decor_nov21_ef.py:985 grind_frame
- tools/asset_forge/builds/decor_nov21_ef.py:998 ef_broken_grindstone
- tools/asset_forge/builds/decor_nov21_ef.py:1029 ef_forge_hearth
- tools/asset_forge/builds/decor_nov21_ef.py:1083 ef_quench_trough
- tools/asset_forge/builds/decor_nov21_ef.py:1109 ef_grinding_wheel
- tools/asset_forge/builds/decor_nov21_ef.py:1146 ef_swage_block
- tools/asset_forge/builds/decor_nov21_ef.py:1184 ef_coal_bunker
- tools/asset_forge/builds/decor_nov21_ef.py:1208 ef_ember_pan
- tools/asset_forge/builds/decor_nov21_ef.py:1225 ef_bar_stock_rack
- tools/asset_forge/builds/decor_nov21_ef.py:1258 ef_apprentice_bench
- tools/asset_forge/builds/decor_nov21_ef.py:1297 ef_cooling_rack
- tools/asset_forge/builds/decor_nov21_ef.py:1325 ef_whetstone_table
- tools/asset_forge/builds/decor_nov21_ef.py:1345 ef_scrap_bin
- tools/asset_forge/builds/decor_nov21_ef.py:1378 ef_coal_scuttle
- tools/asset_forge/builds/decor_nov21_ef.py:1408 ef_ring_mandrel
- tools/asset_forge/builds/decor_nov21_ef.py:1430 ef_coal_scuttle_empty
- tools/asset_forge/builds/decor_nov21_ef.py:1434 ef_cooling_rack_empty
- tools/asset_forge/builds/decor_nov21_ef.py:1438 ef_ingot_wall_empty

## tools/asset_forge/builds/decor_nov21_f.py (911 lines) — Decor batch F (Nov 21): kitchen, lights, workshop and plant decorations, hand-built in the night_decor style.
- tools/asset_forge/builds/decor_nov21_f.py:32 place_glb
- tools/asset_forge/builds/decor_nov21_f.py:65 tint
- tools/asset_forge/builds/decor_nov21_f.py:89 glass
- tools/asset_forge/builds/decor_nov21_f.py:106 aim
- tools/asset_forge/builds/decor_nov21_f.py:112 geode_half
- tools/asset_forge/builds/decor_nov21_f.py:163 lathe
- tools/asset_forge/builds/decor_nov21_f.py:186 group
- tools/asset_forge/builds/decor_nov21_f.py:197 wall_board
- tools/asset_forge/builds/decor_nov21_f.py:204 wall_shelf
- tools/asset_forge/builds/decor_nov21_f.py:215 jar
- tools/asset_forge/builds/decor_nov21_f.py:221 pouch
- tools/asset_forge/builds/decor_nov21_f.py:227 open_crate
- tools/asset_forge/builds/decor_nov21_f.py:241 veg_pile
- tools/asset_forge/builds/decor_nov21_f.py:262 candle
- tools/asset_forge/builds/decor_nov21_f.py:273 spice_shelf
- tools/asset_forge/builds/decor_nov21_f.py:289 pantry_crates
- tools/asset_forge/builds/decor_nov21_f.py:323 pie
- tools/asset_forge/builds/decor_nov21_f.py:338 pie_rack
- tools/asset_forge/builds/decor_nov21_f.py:352 kitchen_block
- tools/asset_forge/builds/decor_nov21_f.py:397 plate
- tools/asset_forge/builds/decor_nov21_f.py:403 dish_rack
- tools/asset_forge/builds/decor_nov21_f.py:428 crystal_floor_lamp
- tools/asset_forge/builds/decor_nov21_f.py:461 mushroom_lamp
- tools/asset_forge/builds/decor_nov21_f.py:497 crystal_hanging_light
- tools/asset_forge/builds/decor_nov21_f.py:528 lantern_hook
- tools/asset_forge/builds/decor_nov21_f.py:539 glowworm_jar
- tools/asset_forge/builds/decor_nov21_f.py:573 candle_wall_shelf
- tools/asset_forge/builds/decor_nov21_f.py:583 tool_wall
- tools/asset_forge/builds/decor_nov21_f.py:626 workbench_clutter
- tools/asset_forge/builds/decor_nov21_f.py:663 blueprint_table
- tools/asset_forge/builds/decor_nov21_f.py:748 gear
- tools/asset_forge/builds/decor_nov21_f.py:759 toothed_gear
- tools/asset_forge/builds/decor_nov21_f.py:786 bolt
- tools/asset_forge/builds/decor_nov21_f.py:798 parts_bin
- tools/asset_forge/builds/decor_nov21_f.py:823 glowcap_pot
- tools/asset_forge/builds/decor_nov21_f.py:844 fern_basket
- tools/asset_forge/builds/decor_nov21_f.py:863 geode_stand

## tools/asset_forge/builds/decor_nov21_g.py (409 lines) — Home decor, Nov 21 batch g: bonsai, mushroom shelf, dartboard, stone game table, drum, crystal globe, wind chi
- tools/asset_forge/builds/decor_nov21_g.py:24 chain
- tools/asset_forge/builds/decor_nov21_g.py:35 leaf_cluster
- tools/asset_forge/builds/decor_nov21_g.py:53 root_bonsai
- tools/asset_forge/builds/decor_nov21_g.py:91 mushroom_shelf_garden
- tools/asset_forge/builds/decor_nov21_g.py:126 dartboard
- tools/asset_forge/builds/decor_nov21_g.py:159 stone_game_table
- tools/asset_forge/builds/decor_nov21_g.py:188 drum_music_stand
- tools/asset_forge/builds/decor_nov21_g.py:216 crystal_globe
- tools/asset_forge/builds/decor_nov21_g.py:248 wind_chime
- tools/asset_forge/builds/decor_nov21_g.py:293 mosaic
- tools/asset_forge/builds/decor_nov21_g.py:325 _pick
- tools/asset_forge/builds/decor_nov21_g.py:329 mosaic_a
- tools/asset_forge/builds/decor_nov21_g.py:354 mosaic_b

## tools/asset_forge/builds/decor_nov21_hm.py (1070 lines) — Home decor batch Nov 21 (group hm): things the player builds for their own home, in the spirit of the owner's
- tools/asset_forge/builds/decor_nov21_hm.py:60 tube_r
- tools/asset_forge/builds/decor_nov21_hm.py:78 dome
- tools/asset_forge/builds/decor_nov21_hm.py:95 aim_obj
- tools/asset_forge/builds/decor_nov21_hm.py:100 top_groove
- tools/asset_forge/builds/decor_nov21_hm.py:108 label
- tools/asset_forge/builds/decor_nov21_hm.py:127 flame_at
- tools/asset_forge/builds/decor_nov21_hm.py:132 posts2
- tools/asset_forge/builds/decor_nov21_hm.py:139 board
- tools/asset_forge/builds/decor_nov21_hm.py:146 flatten_floor
- tools/asset_forge/builds/decor_nov21_hm.py:162 monster_head
- tools/asset_forge/builds/decor_nov21_hm.py:192 head_panel
- tools/asset_forge/builds/decor_nov21_hm.py:215 hm_spider_trophy
- tools/asset_forge/builds/decor_nov21_hm.py:221 hm_beetle_shell_trophy
- tools/asset_forge/builds/decor_nov21_hm.py:226 hm_snail_shell_trophy
- tools/asset_forge/builds/decor_nov21_hm.py:232 pick
- tools/asset_forge/builds/decor_nov21_hm.py:259 hm_pickaxe_progression
- tools/asset_forge/builds/decor_nov21_hm.py:275 hm_crossed_hammers
- tools/asset_forge/builds/decor_nov21_hm.py:302 hm_shield_spears
- tools/asset_forge/builds/decor_nov21_hm.py:341 iron_lantern
- tools/asset_forge/builds/decor_nov21_hm.py:355 clay_lamp
- tools/asset_forge/builds/decor_nov21_hm.py:368 hm_lamp_history_board
- tools/asset_forge/builds/decor_nov21_hm.py:391 hm_bat_skull_plaque
- tools/asset_forge/builds/decor_nov21_hm.py:396 hm_heirloom_axe
- tools/asset_forge/builds/decor_nov21_hm.py:426 hm_vein_slice_frame
- tools/asset_forge/builds/decor_nov21_hm.py:450 flask
- tools/asset_forge/builds/decor_nov21_hm.py:469 hm_potion_rack
- tools/asset_forge/builds/decor_nov21_hm.py:486 scroll
- tools/asset_forge/builds/decor_nov21_hm.py:495 hm_scroll_lattice
- tools/asset_forge/builds/decor_nov21_hm.py:544 crock
- tools/asset_forge/builds/decor_nov21_hm.py:553 preserve_jar
- tools/asset_forge/builds/decor_nov21_hm.py:561 hm_preserve_shelf
- tools/asset_forge/builds/decor_nov21_hm.py:597 tankard
- tools/asset_forge/builds/decor_nov21_hm.py:608 horn
- tools/asset_forge/builds/decor_nov21_hm.py:616 hm_tankard_shelf
- tools/asset_forge/builds/decor_nov21_hm.py:642 ingot
- tools/asset_forge/builds/decor_nov21_hm.py:649 ingot_stack
- tools/asset_forge/builds/decor_nov21_hm.py:657 hm_ingot_display
- tools/asset_forge/builds/decor_nov21_hm.py:678 gem_jar
- tools/asset_forge/builds/decor_nov21_hm.py:691 hm_gem_jar_shelf
- tools/asset_forge/builds/decor_nov21_hm.py:719 bundle
- tools/asset_forge/builds/decor_nov21_hm.py:736 hm_herb_ladder
- tools/asset_forge/builds/decor_nov21_hm.py:763 book_up
- tools/asset_forge/builds/decor_nov21_hm.py:774 book_flat
- tools/asset_forge/builds/decor_nov21_hm.py:782 hm_book_nook
- tools/asset_forge/builds/decor_nov21_hm.py:837 hm_carved_high_chair
- tools/asset_forge/builds/decor_nov21_hm.py:875 hm_delve_game_table
- tools/asset_forge/builds/decor_nov21_hm.py:924 hm_map_table
- tools/asset_forge/builds/decor_nov21_hm.py:971 hm_trophy_pedestal
- tools/asset_forge/builds/decor_nov21_hm.py:1003 hm_banded_sideboard

## tools/asset_forge/builds/decor_nov21_hs.py (1485 lines) — Decor set HS (Nov 21): HALL OF THE SHIELDBEARERS, a medium cut-stone dungeon (Stonehold greystone) where an ol
- tools/asset_forge/builds/decor_nov21_hs.py:72 made
- tools/asset_forge/builds/decor_nov21_hs.py:78 place
- tools/asset_forge/builds/decor_nov21_hs.py:87 xf
- tools/asset_forge/builds/decor_nov21_hs.py:92 put_frame
- tools/asset_forge/builds/decor_nov21_hs.py:103 orient
- tools/asset_forge/builds/decor_nov21_hs.py:110 tgroove
- tools/asset_forge/builds/decor_nov21_hs.py:118 tgroove_path
- tools/asset_forge/builds/decor_nov21_hs.py:125 band_path
- tools/asset_forge/builds/decor_nov21_hs.py:140 foot
- tools/asset_forge/builds/decor_nov21_hs.py:146 board
- tools/asset_forge/builds/decor_nov21_hs.py:160 dedupe
- tools/asset_forge/builds/decor_nov21_hs.py:169 _star
- tools/asset_forge/builds/decor_nov21_hs.py:174 _rays
- tools/asset_forge/builds/decor_nov21_hs.py:200 emblem
- tools/asset_forge/builds/decor_nov21_hs.py:209 heater_pts
- tools/asset_forge/builds/decor_nov21_hs.py:213 heater
- tools/asset_forge/builds/decor_nov21_hs.py:231 roundsh
- tools/asset_forge/builds/decor_nov21_hs.py:263 helm
- tools/asset_forge/builds/decor_nov21_hs.py:298 helm_stand
- tools/asset_forge/builds/decor_nov21_hs.py:303 spear
- tools/asset_forge/builds/decor_nov21_hs.py:329 broken_spear
- tools/asset_forge/builds/decor_nov21_hs.py:339 axe
- tools/asset_forge/builds/decor_nov21_hs.py:359 hammer
- tools/asset_forge/builds/decor_nov21_hs.py:368 tongs
- tools/asset_forge/builds/decor_nov21_hs.py:375 hang
- tools/asset_forge/builds/decor_nov21_hs.py:383 candle
- tools/asset_forge/builds/decor_nov21_hs.py:391 hs_shield_wall
- tools/asset_forge/builds/decor_nov21_hs.py:423 hs_spear_rack
- tools/asset_forge/builds/decor_nov21_hs.py:450 hs_axe_rack
- tools/asset_forge/builds/decor_nov21_hs.py:478 hs_helm_shelf
- tools/asset_forge/builds/decor_nov21_hs.py:505 hs_order_crest
- tools/asset_forge/builds/decor_nov21_hs.py:533 hs_roll_of_honour
- tools/asset_forge/builds/decor_nov21_hs.py:563 hs_split_shield_trophy
- tools/asset_forge/builds/decor_nov21_hs.py:588 hs_buckler_rail
- tools/asset_forge/builds/decor_nov21_hs.py:610 hs_boss_shelf
- tools/asset_forge/builds/decor_nov21_hs.py:658 hs_tool_wall
- tools/asset_forge/builds/decor_nov21_hs.py:710 hs_order_banner
- tools/asset_forge/builds/decor_nov21_hs.py:751 hs_squad_pennants
- tools/asset_forge/builds/decor_nov21_hs.py:774 hs_strap_rack
- tools/asset_forge/builds/decor_nov21_hs.py:819 hs_duty_roster
- tools/asset_forge/builds/decor_nov21_hs.py:848 hs_repair_bench
- tools/asset_forge/builds/decor_nov21_hs.py:893 slim
- tools/asset_forge/builds/decor_nov21_hs.py:904 hs_shieldbearer_stand
- tools/asset_forge/builds/decor_nov21_hs.py:952 token
- tools/asset_forge/builds/decor_nov21_hs.py:960 book
- tools/asset_forge/builds/decor_nov21_hs.py:971 hs_muster_table
- tools/asset_forge/builds/decor_nov21_hs.py:1006 hs_oath_stone
- tools/asset_forge/builds/decor_nov21_hs.py:1040 hs_guard_bunk
- tools/asset_forge/builds/decor_nov21_hs.py:1079 hs_shield_pell
- tools/asset_forge/builds/decor_nov21_hs.py:1120 hs_captains_chair
- tools/asset_forge/builds/decor_nov21_hs.py:1152 hs_fallen_shield_wall
- tools/asset_forge/builds/decor_nov21_hs.py:1173 plaque_stone
- tools/asset_forge/builds/decor_nov21_hs.py:1181 hs_last_stand_cairn
- tools/asset_forge/builds/decor_nov21_hs.py:1193 bare_shield
- tools/asset_forge/builds/decor_nov21_hs.py:1199 stencil
- tools/asset_forge/builds/decor_nov21_hs.py:1205 hs_paint_rack
- tools/asset_forge/builds/decor_nov21_hs.py:1243 hs_rim_jig
- tools/asset_forge/builds/decor_nov21_hs.py:1277 tower
- tools/asset_forge/builds/decor_nov21_hs.py:1291 hs_tower_shields_chained
- tools/asset_forge/builds/decor_nov21_hs.py:1308 hs_war_horn_stand
- tools/asset_forge/builds/decor_nov21_hs.py:1340 hs_helm_trophy_pole
- tools/asset_forge/builds/decor_nov21_hs.py:1369 hs_watch_brazier
- tools/asset_forge/builds/decor_nov21_hs.py:1406 practice_spear
- tools/asset_forge/builds/decor_nov21_hs.py:1414 practice_axe
- tools/asset_forge/builds/decor_nov21_hs.py:1423 practice_sword
- tools/asset_forge/builds/decor_nov21_hs.py:1432 hs_practice_trough

## tools/asset_forge/builds/decor_nov21_hw.py (1646 lines) — Decor for THE HAMMERFALL WORKS (Nov 21): a big clay-brick dungeon, the hold's heavy works, driven by a great w
- tools/asset_forge/builds/decor_nov21_hw.py:61 W
- tools/asset_forge/builds/decor_nov21_hw.py:84 rod
- tools/asset_forge/builds/decor_nov21_hw.py:90 beam
- tools/asset_forge/builds/decor_nov21_hw.py:99 lathe
- tools/asset_forge/builds/decor_nov21_hw.py:119 pot
- tools/asset_forge/builds/decor_nov21_hw.py:128 sector
- tools/asset_forge/builds/decor_nov21_hw.py:143 cog_wheel
- tools/asset_forge/builds/decor_nov21_hw.py:179 pinion
- tools/asset_forge/builds/decor_nov21_hw.py:192 shaft
- tools/asset_forge/builds/decor_nov21_hw.py:202 bearing
- tools/asset_forge/builds/decor_nov21_hw.py:216 wall_back
- tools/asset_forge/builds/decor_nov21_hw.py:227 peg
- tools/asset_forge/builds/decor_nov21_hw.py:233 shelf
- tools/asset_forge/builds/decor_nov21_hw.py:247 bricks_face
- tools/asset_forge/builds/decor_nov21_hw.py:266 brick_pier
- tools/asset_forge/builds/decor_nov21_hw.py:278 hammer_head
- tools/asset_forge/builds/decor_nov21_hw.py:291 open_box
- tools/asset_forge/builds/decor_nov21_hw.py:299 ingot
- tools/asset_forge/builds/decor_nov21_hw.py:306 splinters
- tools/asset_forge/builds/decor_nov21_hw.py:317 mallet
- tools/asset_forge/builds/decor_nov21_hw.py:331 wedge
- tools/asset_forge/builds/decor_nov21_hw.py:337 tappet
- tools/asset_forge/builds/decor_nov21_hw.py:347 bucket
- tools/asset_forge/builds/decor_nov21_hw.py:361 plate
- tools/asset_forge/builds/decor_nov21_hw.py:365 coal_bed
- tools/asset_forge/builds/decor_nov21_hw.py:376 rail
- tools/asset_forge/builds/decor_nov21_hw.py:384 track
- tools/asset_forge/builds/decor_nov21_hw.py:398 wheel
- tools/asset_forge/builds/decor_nov21_hw.py:412 lift_hook
- tools/asset_forge/builds/decor_nov21_hw.py:421 bell
- tools/asset_forge/builds/decor_nov21_hw.py:432 hang_ring
- tools/asset_forge/builds/decor_nov21_hw.py:440 hw_gear_wall
- tools/asset_forge/builds/decor_nov21_hw.py:466 hw_parts_rack
- tools/asset_forge/builds/decor_nov21_hw.py:518 hw_hammer_head_rack
- tools/asset_forge/builds/decor_nov21_hw.py:543 hw_tool_board
- tools/asset_forge/builds/decor_nov21_hw.py:596 hw_belt_pulley_wall
- tools/asset_forge/builds/decor_nov21_hw.py:636 hw_chain_hook_wall
- tools/asset_forge/builds/decor_nov21_hw.py:683 hw_signal_lever_wall
- tools/asset_forge/builds/decor_nov21_hw.py:731 tally
- tools/asset_forge/builds/decor_nov21_hw.py:747 hw_shift_board
- tools/asset_forge/builds/decor_nov21_hw.py:781 hw_grease_shelf
- tools/asset_forge/builds/decor_nov21_hw.py:821 stump
- tools/asset_forge/builds/decor_nov21_hw.py:831 trip_hammer
- tools/asset_forge/builds/decor_nov21_hw.py:905 hw_trip_hammer
- tools/asset_forge/builds/decor_nov21_hw.py:914 hw_jammed_hammer
- tools/asset_forge/builds/decor_nov21_hw.py:931 hand_hammer
- tools/asset_forge/builds/decor_nov21_hw.py:941 hw_plate_anvil
- tools/asset_forge/builds/decor_nov21_hw.py:967 hw_gear_train
- tools/asset_forge/builds/decor_nov21_hw.py:971 _gear_train
- tools/asset_forge/builds/decor_nov21_hw.py:1002 belt_loop
- tools/asset_forge/builds/decor_nov21_hw.py:1019 drum
- tools/asset_forge/builds/decor_nov21_hw.py:1032 hw_line_shaft
- tools/asset_forge/builds/decor_nov21_hw.py:1055 hw_wheel_trough
- tools/asset_forge/builds/decor_nov21_hw.py:1096 on_floor
- tools/asset_forge/builds/decor_nov21_hw.py:1106 sluice
- tools/asset_forge/builds/decor_nov21_hw.py:1155 hw_sluice_gate
- tools/asset_forge/builds/decor_nov21_hw.py:1159 hw_burst_sluice
- tools/asset_forge/builds/decor_nov21_hw.py:1169 hw_flume_trough
- tools/asset_forge/builds/decor_nov21_hw.py:1197 hw_plate_stack
- tools/asset_forge/builds/decor_nov21_hw.py:1230 hw_rivet_brazier
- tools/asset_forge/builds/decor_nov21_hw.py:1265 hw_chain_hoist
- tools/asset_forge/builds/decor_nov21_hw.py:1309 hw_snapped_chain
- tools/asset_forge/builds/decor_nov21_hw.py:1350 hw_broken_cog
- tools/asset_forge/builds/decor_nov21_hw.py:1377 cart
- tools/asset_forge/builds/decor_nov21_hw.py:1419 hw_ingot_cart
- tools/asset_forge/builds/decor_nov21_hw.py:1424 hw_ingot_cart_empty
- tools/asset_forge/builds/decor_nov21_hw.py:1428 hw_derailed_cart
- tools/asset_forge/builds/decor_nov21_hw.py:1435 hw_ingot_stack
- tools/asset_forge/builds/decor_nov21_hw.py:1468 hw_ingot_stack_empty
- tools/asset_forge/builds/decor_nov21_hw.py:1472 hw_overseer_platform
- tools/asset_forge/builds/decor_nov21_hw.py:1531 hw_signal_whistle
- tools/asset_forge/builds/decor_nov21_hw.py:1571 hw_spare_shaft
- tools/asset_forge/builds/decor_nov21_hw.py:1597 hw_plate_shears

## tools/asset_forge/builds/decor_nov21_lw.py (1483 lines) — Decor for LAMPWICK DRIFT (Nov 21): a small root-wood mine drift lit by oil lamps, with cart rails and an upper
- tools/asset_forge/builds/decor_nov21_lw.py:56 PL
- tools/asset_forge/builds/decor_nov21_lw.py:60 BK
- tools/asset_forge/builds/decor_nov21_lw.py:64 DK
- tools/asset_forge/builds/decor_nov21_lw.py:68 END
- tools/asset_forge/builds/decor_nov21_lw.py:86 LOG
- tools/asset_forge/builds/decor_nov21_lw.py:91 rod
- tools/asset_forge/builds/decor_nov21_lw.py:95 board
- tools/asset_forge/builds/decor_nov21_lw.py:99 peghead
- tools/asset_forge/builds/decor_nov21_lw.py:104 peg
- tools/asset_forge/builds/decor_nov21_lw.py:110 lathe
- tools/asset_forge/builds/decor_nov21_lw.py:130 cup
- tools/asset_forge/builds/decor_nov21_lw.py:136 cut
- tools/asset_forge/builds/decor_nov21_lw.py:162 wall_back
- tools/asset_forge/builds/decor_nov21_lw.py:173 shelf
- tools/asset_forge/builds/decor_nov21_lw.py:184 lamp
- tools/asset_forge/builds/decor_nov21_lw.py:208 hang_lamp
- tools/asset_forge/builds/decor_nov21_lw.py:214 chimney
- tools/asset_forge/builds/decor_nov21_lw.py:219 broken_chimney
- tools/asset_forge/builds/decor_nov21_lw.py:228 flask
- tools/asset_forge/builds/decor_nov21_lw.py:239 oil_can
- tools/asset_forge/builds/decor_nov21_lw.py:249 funnel
- tools/asset_forge/builds/decor_nov21_lw.py:256 spool
- tools/asset_forge/builds/decor_nov21_lw.py:267 staves
- tools/asset_forge/builds/decor_nov21_lw.py:300 bell
- tools/asset_forge/builds/decor_nov21_lw.py:311 rail_seg
- tools/asset_forge/builds/decor_nov21_lw.py:323 sleepers
- tools/asset_forge/builds/decor_nov21_lw.py:330 track
- tools/asset_forge/builds/decor_nov21_lw.py:343 crate
- tools/asset_forge/builds/decor_nov21_lw.py:360 ore_rock
- tools/asset_forge/builds/decor_nov21_lw.py:371 ore_pile
- tools/asset_forge/builds/decor_nov21_lw.py:389 shards
- tools/asset_forge/builds/decor_nov21_lw.py:396 stain
- tools/asset_forge/builds/decor_nov21_lw.py:402 splinters
- tools/asset_forge/builds/decor_nov21_lw.py:413 tipped
- tools/asset_forge/builds/decor_nov21_lw.py:424 tin_mug
- tools/asset_forge/builds/decor_nov21_lw.py:429 lunch_tin
- tools/asset_forge/builds/decor_nov21_lw.py:441 pickaxe
- tools/asset_forge/builds/decor_nov21_lw.py:451 lw_lamp_rack_wall
- tools/asset_forge/builds/decor_nov21_lw.py:470 lw_wick_spool_shelf
- tools/asset_forge/builds/decor_nov21_lw.py:510 lw_oil_flask_shelf
- tools/asset_forge/builds/decor_nov21_lw.py:527 lw_lamp_parts_board
- tools/asset_forge/builds/decor_nov21_lw.py:566 lw_lamp_token_board
- tools/asset_forge/builds/decor_nov21_lw.py:600 lw_signal_code_board
- tools/asset_forge/builds/decor_nov21_lw.py:660 rail_bar
- tools/asset_forge/builds/decor_nov21_lw.py:668 lw_spare_rail_rack
- tools/asset_forge/builds/decor_nov21_lw.py:701 lw_oil_barrel_tap
- tools/asset_forge/builds/decor_nov21_lw.py:740 lw_lamp_workbench
- tools/asset_forge/builds/decor_nov21_lw.py:799 lw_wick_twisting_wheel
- tools/asset_forge/builds/decor_nov21_lw.py:844 lw_ore_sorting_table
- tools/asset_forge/builds/decor_nov21_lw.py:883 lw_ore_sieve_cradle
- tools/asset_forge/builds/decor_nov21_lw.py:923 lw_rail_switch_lever
- tools/asset_forge/builds/decor_nov21_lw.py:965 lw_signal_lamp_post
- tools/asset_forge/builds/decor_nov21_lw.py:992 lw_walkway_ladder
- tools/asset_forge/builds/decor_nov21_lw.py:1026 lw_rest_nook_bench
- tools/asset_forge/builds/decor_nov21_lw.py:1063 lw_lamp_barrow
- tools/asset_forge/builds/decor_nov21_lw.py:1099 lw_oil_can_crate
- tools/asset_forge/builds/decor_nov21_lw.py:1120 lw_chimney_crate
- tools/asset_forge/builds/decor_nov21_lw.py:1151 lw_bell_frame
- tools/asset_forge/builds/decor_nov21_lw.py:1176 lw_ledger_desk
- tools/asset_forge/builds/decor_nov21_lw.py:1213 lw_ore_bucket_hoist
- tools/asset_forge/builds/decor_nov21_lw.py:1250 lw_lamp_fallen_spill
- tools/asset_forge/builds/decor_nov21_lw.py:1270 lw_cart_jammed
- tools/asset_forge/builds/decor_nov21_lw.py:1321 lw_last_shift_stool
- tools/asset_forge/builds/decor_nov21_lw.py:1340 lw_broken_lamp_rack
- tools/asset_forge/builds/decor_nov21_lw.py:1366 lw_leaking_oil_cask
- tools/asset_forge/builds/decor_nov21_lw.py:1389 lw_bell_fallen
- tools/asset_forge/builds/decor_nov21_lw.py:1424 lw_collapsed_walkway

## tools/asset_forge/builds/decor_nov21_mg.py (1485 lines) — Decor for MOSSGATE HOLD (Nov 21): the old gatehouse-hold of the first diggers, a small root-wood dungeon
- tools/asset_forge/builds/decor_nov21_mg.py:74 new_since
- tools/asset_forge/builds/decor_nov21_mg.py:78 lay
- tools/asset_forge/builds/decor_nov21_mg.py:90 hlog
- tools/asset_forge/builds/decor_nov21_mg.py:97 rod
- tools/asset_forge/builds/decor_nov21_mg.py:101 beam
- tools/asset_forge/builds/decor_nov21_mg.py:110 board
- tools/asset_forge/builds/decor_nov21_mg.py:114 peg
- tools/asset_forge/builds/decor_nov21_mg.py:124 nail
- tools/asset_forge/builds/decor_nov21_mg.py:131 arc
- tools/asset_forge/builds/decor_nov21_mg.py:141 panel
- tools/asset_forge/builds/decor_nov21_mg.py:156 shelf
- tools/asset_forge/builds/decor_nov21_mg.py:166 corner_irons
- tools/asset_forge/builds/decor_nov21_mg.py:176 cband
- tools/asset_forge/builds/decor_nov21_mg.py:184 barrel
- tools/asset_forge/builds/decor_nov21_mg.py:210 keg_lying
- tools/asset_forge/builds/decor_nov21_mg.py:216 crate
- tools/asset_forge/builds/decor_nov21_mg.py:238 mug
- tools/asset_forge/builds/decor_nov21_mg.py:247 bowl
- tools/asset_forge/builds/decor_nov21_mg.py:260 spoon
- tools/asset_forge/builds/decor_nov21_mg.py:267 smooth
- tools/asset_forge/builds/decor_nov21_mg.py:273 loft
- tools/asset_forge/builds/decor_nov21_mg.py:286 helmet
- tools/asset_forge/builds/decor_nov21_mg.py:300 shield
- tools/asset_forge/builds/decor_nov21_mg.py:334 lantern
- tools/asset_forge/builds/decor_nov21_mg.py:346 crowbar
- tools/asset_forge/builds/decor_nov21_mg.py:357 hammer
- tools/asset_forge/builds/decor_nov21_mg.py:366 splinters
- tools/asset_forge/builds/decor_nov21_mg.py:379 carve
- tools/asset_forge/builds/decor_nov21_mg.py:398 legs_log
- tools/asset_forge/builds/decor_nov21_mg.py:404 top_boards
- tools/asset_forge/builds/decor_nov21_mg.py:409 stool_logs
- tools/asset_forge/builds/decor_nov21_mg.py:418 strongbox_body
- tools/asset_forge/builds/decor_nov21_mg.py:437 key_part
- tools/asset_forge/builds/decor_nov21_mg.py:450 mg_key_board
- tools/asset_forge/builds/decor_nov21_mg.py:476 mg_shield_wall
- tools/asset_forge/builds/decor_nov21_mg.py:493 crossbow
- tools/asset_forge/builds/decor_nov21_mg.py:510 mg_crossbow_rack
- tools/asset_forge/builds/decor_nov21_mg.py:539 mg_helmet_pegs
- tools/asset_forge/builds/decor_nov21_mg.py:563 mg_bowl_shelf
- tools/asset_forge/builds/decor_nov21_mg.py:596 coil
- tools/asset_forge/builds/decor_nov21_mg.py:604 mg_rope_wall
- tools/asset_forge/builds/decor_nov21_mg.py:643 book
- tools/asset_forge/builds/decor_nov21_mg.py:653 scroll
- tools/asset_forge/builds/decor_nov21_mg.py:659 mg_ledger_shelf
- tools/asset_forge/builds/decor_nov21_mg.py:711 mg_gate_windlass
- tools/asset_forge/builds/decor_nov21_mg.py:754 mg_last_watch
- tools/asset_forge/builds/decor_nov21_mg.py:785 mg_barricade
- tools/asset_forge/builds/decor_nov21_mg.py:815 mg_gate_bar_snapped
- tools/asset_forge/builds/decor_nov21_mg.py:844 mg_crate_pried_open
- tools/asset_forge/builds/decor_nov21_mg.py:865 mg_sawhorse_left
- tools/asset_forge/builds/decor_nov21_mg.py:896 mg_strongbox_forced
- tools/asset_forge/builds/decor_nov21_mg.py:918 spear
- tools/asset_forge/builds/decor_nov21_mg.py:931 mg_spear_rack_fallen
- tools/asset_forge/builds/decor_nov21_mg.py:957 mg_collapsed_shelf
- tools/asset_forge/builds/decor_nov21_mg.py:992 mg_gatekeeper_chair
- tools/asset_forge/builds/decor_nov21_mg.py:1023 mg_gatekeeper_desk
- tools/asset_forge/builds/decor_nov21_mg.py:1070 mg_armour_stand
- tools/asset_forge/builds/decor_nov21_mg.py:1109 mg_alarm_bell
- tools/asset_forge/builds/decor_nov21_mg.py:1139 round_lid
- tools/asset_forge/builds/decor_nov21_mg.py:1163 mg_water_butt
- tools/asset_forge/builds/decor_nov21_mg.py:1172 mg_supply_shelf
- tools/asset_forge/builds/decor_nov21_mg.py:1208 mg_wheelbarrow
- tools/asset_forge/builds/decor_nov21_mg.py:1238 mg_cookpot_tripod
- tools/asset_forge/builds/decor_nov21_mg.py:1269 mg_guard_cot
- tools/asset_forge/builds/decor_nov21_mg.py:1298 mg_mess_trestle
- tools/asset_forge/builds/decor_nov21_mg.py:1332 mg_lantern_post
- tools/asset_forge/builds/decor_nov21_mg.py:1356 mg_grain_bin
- tools/asset_forge/builds/decor_nov21_mg.py:1388 mg_tool_chest
- tools/asset_forge/builds/decor_nov21_mg.py:1418 mg_toll_table

## tools/asset_forge/builds/decor_nov21_mp.py (1244 lines) — Decor for the dungeon MOSSPROP WORKINGS (Nov 21): a small, abandoned, timber-propped working mine. Root wood
- tools/asset_forge/builds/decor_nov21_mp.py:55 BARK
- tools/asset_forge/builds/decor_nov21_mp.py:59 PLK
- tools/asset_forge/builds/decor_nov21_mp.py:63 DARK
- tools/asset_forge/builds/decor_nov21_mp.py:67 END
- tools/asset_forge/builds/decor_nov21_mp.py:71 ROCK
- tools/asset_forge/builds/decor_nov21_mp.py:75 IRON
- tools/asset_forge/builds/decor_nov21_mp.py:88 place
- tools/asset_forge/builds/decor_nov21_mp.py:106 low_z
- tools/asset_forge/builds/decor_nov21_mp.py:111 drop
- tools/asset_forge/builds/decor_nov21_mp.py:119 grain_uv
- tools/asset_forge/builds/decor_nov21_mp.py:135 G
- tools/asset_forge/builds/decor_nov21_mp.py:140 bvh
- tools/asset_forge/builds/decor_nov21_mp.py:146 rest
- tools/asset_forge/builds/decor_nov21_mp.py:150 post
- tools/asset_forge/builds/decor_nov21_mp.py:161 hewn
- tools/asset_forge/builds/decor_nov21_mp.py:167 peg
- tools/asset_forge/builds/decor_nov21_mp.py:173 hpeg
- tools/asset_forge/builds/decor_nov21_mp.py:178 board
- tools/asset_forge/builds/decor_nov21_mp.py:189 shelf
- tools/asset_forge/builds/decor_nov21_mp.py:199 wedge
- tools/asset_forge/builds/decor_nov21_mp.py:208 lathe
- tools/asset_forge/builds/decor_nov21_mp.py:218 splinters
- tools/asset_forge/builds/decor_nov21_mp.py:231 staves
- tools/asset_forge/builds/decor_nov21_mp.py:247 bucket
- tools/asset_forge/builds/decor_nov21_mp.py:259 mug
- tools/asset_forge/builds/decor_nov21_mp.py:267 lamp
- tools/asset_forge/builds/decor_nov21_mp.py:281 hung_lamp
- tools/asset_forge/builds/decor_nov21_mp.py:286 coil
- tools/asset_forge/builds/decor_nov21_mp.py:297 rubble
- tools/asset_forge/builds/decor_nov21_mp.py:335 chips
- tools/asset_forge/builds/decor_nov21_mp.py:350 k_even
- tools/asset_forge/builds/decor_nov21_mp.py:355 t_axe
- tools/asset_forge/builds/decor_nov21_mp.py:368 t_maul
- tools/asset_forge/builds/decor_nov21_mp.py:376 t_pick
- tools/asset_forge/builds/decor_nov21_mp.py:383 t_shovel
- tools/asset_forge/builds/decor_nov21_mp.py:394 t_bar
- tools/asset_forge/builds/decor_nov21_mp.py:400 t_hammer
- tools/asset_forge/builds/decor_nov21_mp.py:407 t_crosscut
- tools/asset_forge/builds/decor_nov21_mp.py:425 crate
- tools/asset_forge/builds/decor_nov21_mp.py:441 mp_wedge_rack
- tools/asset_forge/builds/decor_nov21_mp.py:465 mp_saw_wall
- tools/asset_forge/builds/decor_nov21_mp.py:505 mp_tag_board
- tools/asset_forge/builds/decor_nov21_mp.py:533 mp_lamp_shelf
- tools/asset_forge/builds/decor_nov21_mp.py:551 mp_rope_rack
- tools/asset_forge/builds/decor_nov21_mp.py:580 mp_auger_rack
- tools/asset_forge/builds/decor_nov21_mp.py:607 mp_bucket_hooks
- tools/asset_forge/builds/decor_nov21_mp.py:634 mp_lagging_burst
- tools/asset_forge/builds/decor_nov21_mp.py:673 sawbuck
- tools/asset_forge/builds/decor_nov21_mp.py:680 mp_saw_bench_cut
- tools/asset_forge/builds/decor_nov21_mp.py:698 mp_prop_cracked
- tools/asset_forge/builds/decor_nov21_mp.py:719 mp_collapsed_set
- tools/asset_forge/builds/decor_nov21_mp.py:741 mp_rest_corner
- tools/asset_forge/builds/decor_nov21_mp.py:769 mp_bucket_line
- tools/asset_forge/builds/decor_nov21_mp.py:784 mp_hewing_log
- tools/asset_forge/builds/decor_nov21_mp.py:813 mp_foreman_desk
- tools/asset_forge/builds/decor_nov21_mp.py:851 mp_prop_crib
- tools/asset_forge/builds/decor_nov21_mp.py:875 mp_prop_and_cap
- tools/asset_forge/builds/decor_nov21_mp.py:891 mp_door_set
- tools/asset_forge/builds/decor_nov21_mp.py:905 mp_shaft_windlass
- tools/asset_forge/builds/decor_nov21_mp.py:945 mp_hoist_tripod
- tools/asset_forge/builds/decor_nov21_mp.py:967 mp_sorting_table
- tools/asset_forge/builds/decor_nov21_mp.py:1003 mp_tool_shed
- tools/asset_forge/builds/decor_nov21_mp.py:1041 mp_bailing_tub
- tools/asset_forge/builds/decor_nov21_mp.py:1055 mp_bell_frame
- tools/asset_forge/builds/decor_nov21_mp.py:1079 mp_wedge_crate
- tools/asset_forge/builds/decor_nov21_mp.py:1099 mp_prop_trolley
- tools/asset_forge/builds/decor_nov21_mp.py:1139 mp_lagging_stack
- tools/asset_forge/builds/decor_nov21_mp.py:1158 mp_prop_rack
- tools/asset_forge/builds/decor_nov21_mp.py:1177 mp_tool_barrel
- tools/asset_forge/builds/decor_nov21_mp.py:1203 mp_nail_keg

## tools/asset_forge/builds/decor_nov21_op.py (1611 lines) — Decor for OLD PELL'S DIGGINGS (Nov 21): the private diggings of Old Pell, a stubborn, clever, half-mad old min
- tools/asset_forge/builds/decor_nov21_op.py:78 group
- tools/asset_forge/builds/decor_nov21_op.py:91 low_z
- tools/asset_forge/builds/decor_nov21_op.py:95 settle
- tools/asset_forge/builds/decor_nov21_op.py:103 turn
- tools/asset_forge/builds/decor_nov21_op.py:110 carve
- tools/asset_forge/builds/decor_nov21_op.py:139 groove
- tools/asset_forge/builds/decor_nov21_op.py:147 ink
- tools/asset_forge/builds/decor_nov21_op.py:155 rlog
- tools/asset_forge/builds/decor_nov21_op.py:166 board
- tools/asset_forge/builds/decor_nov21_op.py:179 peg
- tools/asset_forge/builds/decor_nov21_op.py:185 nail
- tools/asset_forge/builds/decor_nov21_op.py:189 hpeg
- tools/asset_forge/builds/decor_nov21_op.py:195 shelf
- tools/asset_forge/builds/decor_nov21_op.py:204 tag
- tools/asset_forge/builds/decor_nov21_op.py:211 arc_pts
- tools/asset_forge/builds/decor_nov21_op.py:215 jaw
- tools/asset_forge/builds/decor_nov21_op.py:232 helix
- tools/asset_forge/builds/decor_nov21_op.py:239 gear
- tools/asset_forge/builds/decor_nov21_op.py:252 lantern
- tools/asset_forge/builds/decor_nov21_op.py:270 boot
- tools/asset_forge/builds/decor_nov21_op.py:285 stump
- tools/asset_forge/builds/decor_nov21_op.py:289 stool3
- tools/asset_forge/builds/decor_nov21_op.py:300 page
- tools/asset_forge/builds/decor_nov21_op.py:317 tack
- tools/asset_forge/builds/decor_nov21_op.py:322 bell
- tools/asset_forge/builds/decor_nov21_op.py:332 barrel
- tools/asset_forge/builds/decor_nov21_op.py:346 coal_bits
- tools/asset_forge/builds/decor_nov21_op.py:354 spectacles
- tools/asset_forge/builds/decor_nov21_op.py:365 op_rock_shelf
- tools/asset_forge/builds/decor_nov21_op.py:408 op_bone_board
- tools/asset_forge/builds/decor_nov21_op.py:446 op_madness_board
- tools/asset_forge/builds/decor_nov21_op.py:494 op_trap_parts_rack
- tools/asset_forge/builds/decor_nov21_op.py:528 op_key_board
- tools/asset_forge/builds/decor_nov21_op.py:568 op_warning_plank
- tools/asset_forge/builds/decor_nov21_op.py:605 sheet
- tools/asset_forge/builds/decor_nov21_op.py:628 op_map_rack
- tools/asset_forge/builds/decor_nov21_op.py:683 op_pipe_rack
- tools/asset_forge/builds/decor_nov21_op.py:720 op_still
- tools/asset_forge/builds/decor_nov21_op.py:765 op_tinker_bench
- tools/asset_forge/builds/decor_nov21_op.py:822 op_trapmaker_table
- tools/asset_forge/builds/decor_nov21_op.py:868 op_cot
- tools/asset_forge/builds/decor_nov21_op.py:907 op_root_armchair
- tools/asset_forge/builds/decor_nov21_op.py:936 op_tumbler
- tools/asset_forge/builds/decor_nov21_op.py:983 op_sieve_stack
- tools/asset_forge/builds/decor_nov21_op.py:1023 op_hearth_tripod
- tools/asset_forge/builds/decor_nov21_op.py:1058 op_signpost
- tools/asset_forge/builds/decor_nov21_op.py:1098 op_spike_crate
- tools/asset_forge/builds/decor_nov21_op.py:1131 op_wire_spools
- tools/asset_forge/builds/decor_nov21_op.py:1162 op_ore_scale
- tools/asset_forge/builds/decor_nov21_op.py:1193 op_caught_boot
- tools/asset_forge/builds/decor_nov21_op.py:1220 op_diary_table
- tools/asset_forge/builds/decor_nov21_op.py:1260 op_x_marks_dig
- tools/asset_forge/builds/decor_nov21_op.py:1325 round_bell
- tools/asset_forge/builds/decor_nov21_op.py:1337 op_bell_tripwire
- tools/asset_forge/builds/decor_nov21_op.py:1369 op_barricade
- tools/asset_forge/builds/decor_nov21_op.py:1404 op_decoy_chest
- tools/asset_forge/builds/decor_nov21_op.py:1444 op_hat_on_pick
- tools/asset_forge/builds/decor_nov21_op.py:1472 op_rat_traps
- tools/asset_forge/builds/decor_nov21_op.py:1511 op_strongbox_pried
- tools/asset_forge/builds/decor_nov21_op.py:1547 op_watch_post

## tools/asset_forge/builds/decor_nov21_qb.py (1128 lines) — Decor set QB (Nov 21): THE QUIET BARROWS, a MEDIUM dungeon in cut stone (Stonehold style): the long, low buria
- tools/asset_forge/builds/decor_nov21_qb.py:70 sb
- tools/asset_forge/builds/decor_nov21_qb.py:74 drop
- tools/asset_forge/builds/decor_nov21_qb.py:80 ashlar
- tools/asset_forge/builds/decor_nov21_qb.py:105 wall_kit
- tools/asset_forge/builds/decor_nov21_qb.py:122 crest
- tools/asset_forge/builds/decor_nov21_qb.py:160 name_stone
- tools/asset_forge/builds/decor_nov21_qb.py:175 niche_trim
- tools/asset_forge/builds/decor_nov21_qb.py:190 r_at
- tools/asset_forge/builds/decor_nov21_qb.py:197 urn
- tools/asset_forge/builds/decor_nov21_qb.py:217 corbel
- tools/asset_forge/builds/decor_nov21_qb.py:223 oil_lamp
- tools/asset_forge/builds/decor_nov21_qb.py:235 lantern
- tools/asset_forge/builds/decor_nov21_qb.py:251 chips
- tools/asset_forge/builds/decor_nov21_qb.py:258 tokens
- tools/asset_forge/builds/decor_nov21_qb.py:264 spade
- tools/asset_forge/builds/decor_nov21_qb.py:277 pickaxe
- tools/asset_forge/builds/decor_nov21_qb.py:286 mallet
- tools/asset_forge/builds/decor_nov21_qb.py:293 chisel
- tools/asset_forge/builds/decor_nov21_qb.py:299 trowel
- tools/asset_forge/builds/decor_nov21_qb.py:306 tub
- tools/asset_forge/builds/decor_nov21_qb.py:317 barrel
- tools/asset_forge/builds/decor_nov21_qb.py:326 hammers_slab
- tools/asset_forge/builds/decor_nov21_qb.py:341 lay_flat
- tools/asset_forge/builds/decor_nov21_qb.py:348 qb_loculus_wall
- tools/asset_forge/builds/decor_nov21_qb.py:369 qb_loculus_open
- tools/asset_forge/builds/decor_nov21_qb.py:390 qb_loculus_collapsed
- tools/asset_forge/builds/decor_nov21_qb.py:430 qb_urn_shelves
- tools/asset_forge/builds/decor_nov21_qb.py:451 stele
- tools/asset_forge/builds/decor_nov21_qb.py:464 qb_crest_hammers
- tools/asset_forge/builds/decor_nov21_qb.py:480 qb_crest_mountain
- tools/asset_forge/builds/decor_nov21_qb.py:503 qb_lamp_alcove
- tools/asset_forge/builds/decor_nov21_qb.py:525 qb_candle_ledge
- tools/asset_forge/builds/decor_nov21_qb.py:546 qb_ossuary_wall
- tools/asset_forge/builds/decor_nov21_qb.py:574 real_bust
- tools/asset_forge/builds/decor_nov21_qb.py:591 bust
- tools/asset_forge/builds/decor_nov21_qb.py:603 qb_family_shrine
- tools/asset_forge/builds/decor_nov21_qb.py:626 qb_name_roll
- tools/asset_forge/builds/decor_nov21_qb.py:656 qb_digger_tool_wall
- tools/asset_forge/builds/decor_nov21_qb.py:686 spandrel
- tools/asset_forge/builds/decor_nov21_qb.py:697 voussoirs
- tools/asset_forge/builds/decor_nov21_qb.py:707 qb_sealed_passage
- tools/asset_forge/builds/decor_nov21_qb.py:742 qb_vault_gate
- tools/asset_forge/builds/decor_nov21_qb.py:780 qb_mourners_bench
- tools/asset_forge/builds/decor_nov21_qb.py:796 qb_floor_slab
- tools/asset_forge/builds/decor_nov21_qb.py:821 qb_cairn_grave
- tools/asset_forge/builds/decor_nov21_qb.py:845 headstone
- tools/asset_forge/builds/decor_nov21_qb.py:857 qb_headstone_row
- tools/asset_forge/builds/decor_nov21_qb.py:878 qb_urn_pedestal
- tools/asset_forge/builds/decor_nov21_qb.py:890 wheel
- tools/asset_forge/builds/decor_nov21_qb.py:900 qb_urn_cart
- tools/asset_forge/builds/decor_nov21_qb.py:926 qb_digger_rest
- tools/asset_forge/builds/decor_nov21_qb.py:951 qb_mason_bench
- tools/asset_forge/builds/decor_nov21_qb.py:975 qb_kneeler_stele
- tools/asset_forge/builds/decor_nov21_qb.py:990 qb_bier_trestles
- tools/asset_forge/builds/decor_nov21_qb.py:1007 qb_bone_chest
- tools/asset_forge/builds/decor_nov21_qb.py:1031 qb_waymarker
- tools/asset_forge/builds/decor_nov21_qb.py:1048 qb_token_pillar
- tools/asset_forge/builds/decor_nov21_qb.py:1065 qb_incense_stand
- tools/asset_forge/builds/decor_nov21_qb.py:1084 qb_wash_basin
- tools/asset_forge/builds/decor_nov21_qb.py:1095 qb_ancestor_bust

## tools/asset_forge/builds/decor_nov21_ru.py (1531 lines) — Decor group RU (Nov 21): what lies around inside the two surface-cave ruins, and what fits once they are rebui
- tools/asset_forge/builds/decor_nov21_ru.py:79 made
- tools/asset_forge/builds/decor_nov21_ru.py:87 place
- tools/asset_forge/builds/decor_nov21_ru.py:95 settle
- tools/asset_forge/builds/decor_nov21_ru.py:102 carve1
- tools/asset_forge/builds/decor_nov21_ru.py:109 top_cut
- tools/asset_forge/builds/decor_nov21_ru.py:116 gem_at
- tools/asset_forge/builds/decor_nov21_ru.py:125 hexa
- tools/asset_forge/builds/decor_nov21_ru.py:129 rodm
- tools/asset_forge/builds/decor_nov21_ru.py:133 stake
- tools/asset_forge/builds/decor_nov21_ru.py:142 splinters
- tools/asset_forge/builds/decor_nov21_ru.py:155 bolt
- tools/asset_forge/builds/decor_nov21_ru.py:184 lying_bolt
- tools/asset_forge/builds/decor_nov21_ru.py:191 wheel
- tools/asset_forge/builds/decor_nov21_ru.py:217 keg
- tools/asset_forge/builds/decor_nov21_ru.py:226 shield_round
- tools/asset_forge/builds/decor_nov21_ru.py:245 _tread
- tools/asset_forge/builds/decor_nov21_ru.py:262 rt_stair_landing_broken
- tools/asset_forge/builds/decor_nov21_ru.py:296 rt_lookout_brazier
- tools/asset_forge/builds/decor_nov21_ru.py:339 rt_signal_mirror_stand
- tools/asset_forge/builds/decor_nov21_ru.py:387 _stool
- tools/asset_forge/builds/decor_nov21_ru.py:395 rt_watch_table_map
- tools/asset_forge/builds/decor_nov21_ru.py:463 rt_arrow_slit_shutter
- tools/asset_forge/builds/decor_nov21_ru.py:529 bell_r
- tools/asset_forge/builds/decor_nov21_ru.py:537 rt_fallen_bell
- tools/asset_forge/builds/decor_nov21_ru.py:599 _spear
- tools/asset_forge/builds/decor_nov21_ru.py:611 rt_weapon_rack
- tools/asset_forge/builds/decor_nov21_ru.py:651 rt_water_cistern
- tools/asset_forge/builds/decor_nov21_ru.py:713 _lantern
- tools/asset_forge/builds/decor_nov21_ru.py:725 _key
- tools/asset_forge/builds/decor_nov21_ru.py:734 rt_watch_hooks
- tools/asset_forge/builds/decor_nov21_ru.py:792 rt_watch_roster_slab
- tools/asset_forge/builds/decor_nov21_ru.py:835 rt_arrow_crate_spill
- tools/asset_forge/builds/decor_nov21_ru.py:876 rt_map_tube_rack
- tools/asset_forge/builds/decor_nov21_ru.py:926 ro_stake_bundle
- tools/asset_forge/builds/decor_nov21_ru.py:959 ro_gate_wing_broken
- tools/asset_forge/builds/decor_nov21_ru.py:997 ro_supply_cart
- tools/asset_forge/builds/decor_nov21_ru.py:1048 ro_camp_cookery
- tools/asset_forge/builds/decor_nov21_ru.py:1109 ro_duty_board
- tools/asset_forge/builds/decor_nov21_ru.py:1169 ro_armour_bench
- tools/asset_forge/builds/decor_nov21_ru.py:1224 ro_archery_bale
- tools/asset_forge/builds/decor_nov21_ru.py:1253 ro_flag_pole
- tools/asset_forge/builds/decor_nov21_ru.py:1301 ro_ladder_platform
- tools/asset_forge/builds/decor_nov21_ru.py:1345 _fix_crossbow_clamp
- tools/asset_forge/builds/decor_nov21_ru.py:1377 ro_quiver_rack
- tools/asset_forge/builds/decor_nov21_ru.py:1428 ro_gate_bar_brackets
- tools/asset_forge/builds/decor_nov21_ru.py:1470 ro_palisade_section

## tools/asset_forge/builds/decor_nov21_rx.py (1431 lines) — Decor set RX (Nov 21): decor for two RUINS the player can rebuild.
- tools/asset_forge/builds/decor_nov21_rx.py:90 BRASS
- tools/asset_forge/builds/decor_nov21_rx.py:112 new_since
- tools/asset_forge/builds/decor_nov21_rx.py:116 along
- tools/asset_forge/builds/decor_nov21_rx.py:130 drop
- tools/asset_forge/builds/decor_nov21_rx.py:136 ring_mesh
- tools/asset_forge/builds/decor_nov21_rx.py:145 hoop
- tools/asset_forge/builds/decor_nov21_rx.py:154 rat
- tools/asset_forge/builds/decor_nov21_rx.py:162 staves
- tools/asset_forge/builds/decor_nov21_rx.py:187 head_boards
- tools/asset_forge/builds/decor_nov21_rx.py:199 cask
- tools/asset_forge/builds/decor_nov21_rx.py:217 tankard
- tools/asset_forge/builds/decor_nov21_rx.py:228 bucket
- tools/asset_forge/builds/decor_nov21_rx.py:240 mallet
- tools/asset_forge/builds/decor_nov21_rx.py:250 turned_hoop
- tools/asset_forge/builds/decor_nov21_rx.py:255 lie_stave
- tools/asset_forge/builds/decor_nov21_rx.py:272 rb_mash_tun
- tools/asset_forge/builds/decor_nov21_rx.py:312 rb_brew_kettle
- tools/asset_forge/builds/decor_nov21_rx.py:370 rb_fermenting_vats
- tools/asset_forge/builds/decor_nov21_rx.py:406 rb_vat_burst
- tools/asset_forge/builds/decor_nov21_rx.py:443 slat_tray
- tools/asset_forge/builds/decor_nov21_rx.py:457 rb_drying_rack
- tools/asset_forge/builds/decor_nov21_rx.py:521 rb_grain_quern
- tools/asset_forge/builds/decor_nov21_rx.py:562 rb_cask_bay
- tools/asset_forge/builds/decor_nov21_rx.py:605 rb_cooper_bench
- tools/asset_forge/builds/decor_nov21_rx.py:648 hollow_tube
- tools/asset_forge/builds/decor_nov21_rx.py:682 horn
- tools/asset_forge/builds/decor_nov21_rx.py:708 horn_bottom
- tools/asset_forge/builds/decor_nov21_rx.py:715 rb_horn_wall
- tools/asset_forge/builds/decor_nov21_rx.py:748 rb_feast_table_broken
- tools/asset_forge/builds/decor_nov21_rx.py:797 rb_recipe_board
- tools/asset_forge/builds/decor_nov21_rx.py:846 rb_cask_rolled
- tools/asset_forge/builds/decor_nov21_rx.py:878 lens_disc
- tools/asset_forge/builds/decor_nov21_rx.py:884 oil_jar
- tools/asset_forge/builds/decor_nov21_rx.py:904 open_book
- tools/asset_forge/builds/decor_nov21_rx.py:916 bobbin
- tools/asset_forge/builds/decor_nov21_rx.py:928 rs_oil_jar_stand
- tools/asset_forge/builds/decor_nov21_rx.py:959 rs_lens_workbench
- tools/asset_forge/builds/decor_nov21_rx.py:1004 rs_great_lens_cradle
- tools/asset_forge/builds/decor_nov21_rx.py:1046 rs_reflector_plates
- tools/asset_forge/builds/decor_nov21_rx.py:1083 rs_signal_shutters
- tools/asset_forge/builds/decor_nov21_rx.py:1115 rs_keeper_log_desk
- tools/asset_forge/builds/decor_nov21_rx.py:1146 rs_oil_hoist
- tools/asset_forge/builds/decor_nov21_rx.py:1189 chimney
- tools/asset_forge/builds/decor_nov21_rx.py:1196 rs_chimney_rack
- tools/asset_forge/builds/decor_nov21_rx.py:1228 rs_wick_board
- tools/asset_forge/builds/decor_nov21_rx.py:1268 rs_lantern_cage_fallen
- tools/asset_forge/builds/decor_nov21_rx.py:1317 rs_lens_shattered
- tools/asset_forge/builds/decor_nov21_rx.py:1369 rs_keeper_last_watch

## tools/asset_forge/builds/decor_nov21_th.py (1345 lines) — Decor set TH (Nov 21): the Tomb of Hald Ironbrow, a MEDIUM dungeon in cut stone (Stonehold style).
- tools/asset_forge/builds/decor_nov21_th.py:70 foot
- tools/asset_forge/builds/decor_nov21_th.py:75 new_since
- tools/asset_forge/builds/decor_nov21_th.py:79 apply_mods
- tools/asset_forge/builds/decor_nov21_th.py:87 carve
- tools/asset_forge/builds/decor_nov21_th.py:111 cy
- tools/asset_forge/builds/decor_nov21_th.py:116 gline
- tools/asset_forge/builds/decor_nov21_th.py:127 runes
- tools/asset_forge/builds/decor_nov21_th.py:143 helm_emblem
- tools/asset_forge/builds/decor_nov21_th.py:156 lathe
- tools/asset_forge/builds/decor_nov21_th.py:170 group
- tools/asset_forge/builds/decor_nov21_th.py:183 rotp
- tools/asset_forge/builds/decor_nov21_th.py:188 plinth
- tools/asset_forge/builds/decor_nov21_th.py:196 frame_band
- tools/asset_forge/builds/decor_nov21_th.py:205 helm
- tools/asset_forge/builds/decor_nov21_th.py:233 hammer
- tools/asset_forge/builds/decor_nov21_th.py:254 rough_chips
- tools/asset_forge/builds/decor_nov21_th.py:261 coal_heap
- tools/asset_forge/builds/decor_nov21_th.py:270 goblet
- tools/asset_forge/builds/decor_nov21_th.py:277 candle
- tools/asset_forge/builds/decor_nov21_th.py:286 pry_bar
- tools/asset_forge/builds/decor_nov21_th.py:295 round_shield
- tools/asset_forge/builds/decor_nov21_th.py:320 niche_block
- tools/asset_forge/builds/decor_nov21_th.py:339 panel_wall
- tools/asset_forge/builds/decor_nov21_th.py:347 flat_back
- tools/asset_forge/builds/decor_nov21_th.py:361 flat_hammer
- tools/asset_forge/builds/decor_nov21_th.py:369 bounds
- tools/asset_forge/builds/decor_nov21_th.py:374 ring_at
- tools/asset_forge/builds/decor_nov21_th.py:382 face
- tools/asset_forge/builds/decor_nov21_th.py:394 beard
- tools/asset_forge/builds/decor_nov21_th.py:412 real_dwarf
- tools/asset_forge/builds/decor_nov21_th.py:461 curl
- tools/asset_forge/builds/decor_nov21_th.py:467 palm
- tools/asset_forge/builds/decor_nov21_th.py:476 guard_figure
- tools/asset_forge/builds/decor_nov21_th.py:508 th_hald_tomb
- tools/asset_forge/builds/decor_nov21_th.py:558 th_brow_helm_plinth
- tools/asset_forge/builds/decor_nov21_th.py:570 th_armour_stand
- tools/asset_forge/builds/decor_nov21_th.py:604 th_hammer_rest
- tools/asset_forge/builds/decor_nov21_th.py:627 th_drinking_horn
- tools/asset_forge/builds/decor_nov21_th.py:652 th_honour_guard
- tools/asset_forge/builds/decor_nov21_th.py:658 th_guard_snapped
- tools/asset_forge/builds/decor_nov21_th.py:673 th_brazier_grand
- tools/asset_forge/builds/decor_nov21_th.py:694 th_brazier_toppled
- tools/asset_forge/builds/decor_nov21_th.py:715 th_mourning_banner
- tools/asset_forge/builds/decor_nov21_th.py:761 th_mourning_bell
- tools/asset_forge/builds/decor_nov21_th.py:799 fig_cuts
- tools/asset_forge/builds/decor_nov21_th.py:829 th_relief_battle
- tools/asset_forge/builds/decor_nov21_th.py:858 th_relief_forge
- tools/asset_forge/builds/decor_nov21_th.py:889 th_name_plaque
- tools/asset_forge/builds/decor_nov21_th.py:908 coin_pile
- tools/asset_forge/builds/decor_nov21_th.py:916 th_niche_coins
- tools/asset_forge/builds/decor_nov21_th.py:934 th_niche_candles
- tools/asset_forge/builds/decor_nov21_th.py:948 th_niche_looted
- tools/asset_forge/builds/decor_nov21_th.py:968 urn
- tools/asset_forge/builds/decor_nov21_th.py:977 th_urn_shelf
- tools/asset_forge/builds/decor_nov21_th.py:997 th_sealed_door
- tools/asset_forge/builds/decor_nov21_th.py:1037 th_door_fallen
- tools/asset_forge/builds/decor_nov21_th.py:1083 th_chest_looted
- tools/asset_forge/builds/decor_nov21_th.py:1111 axe
- tools/asset_forge/builds/decor_nov21_th.py:1124 th_weapon_rack
- tools/asset_forge/builds/decor_nov21_th.py:1145 th_shield_wall
- tools/asset_forge/builds/decor_nov21_th.py:1160 th_ash_urn
- tools/asset_forge/builds/decor_nov21_th.py:1176 mourner
- tools/asset_forge/builds/decor_nov21_th.py:1199 th_kneeling_mourner
- tools/asset_forge/builds/decor_nov21_th.py:1205 th_robber_pinned
- tools/asset_forge/builds/decor_nov21_th.py:1231 drum
- tools/asset_forge/builds/decor_nov21_th.py:1242 th_pillar_fallen
- tools/asset_forge/builds/decor_nov21_th.py:1260 th_mourning_bench
- tools/asset_forge/builds/decor_nov21_th.py:1274 dagger
- tools/asset_forge/builds/decor_nov21_th.py:1281 th_offering_table
- tools/asset_forge/builds/decor_nov21_th.py:1305 th_wall_lamp

## tools/asset_forge/builds/decor_nov21_vo.py (1470 lines) — Decor set VO (Nov 21): the Vigil of Orrin Stonejaw, a MEDIUM dungeon in cut stone (Stonehold style).
- tools/asset_forge/builds/decor_nov21_vo.py:76 czt
- tools/asset_forge/builds/decor_nov21_vo.py:81 gtop
- tools/asset_forge/builds/decor_nov21_vo.py:86 arcpts
- tools/asset_forge/builds/decor_nov21_vo.py:90 eye_sign
- tools/asset_forge/builds/decor_nov21_vo.py:105 arc_plate
- tools/asset_forge/builds/decor_nov21_vo.py:125 dwarf_form
- tools/asset_forge/builds/decor_nov21_vo.py:167 body_pts
- tools/asset_forge/builds/decor_nov21_vo.py:171 body_ring
- tools/asset_forge/builds/decor_nov21_vo.py:189 ring_r
- tools/asset_forge/builds/decor_nov21_vo.py:196 lame_row
- tools/asset_forge/builds/decor_nov21_vo.py:228 two_mat
- tools/asset_forge/builds/decor_nov21_vo.py:237 hollow_lathe
- tools/asset_forge/builds/decor_nov21_vo.py:250 hollow_horn
- tools/asset_forge/builds/decor_nov21_vo.py:279 jaw_helm
- tools/asset_forge/builds/decor_nov21_vo.py:343 hourglass
- tools/asset_forge/builds/decor_nov21_vo.py:365 book_flat
- tools/asset_forge/builds/decor_nov21_vo.py:377 book_stand
- tools/asset_forge/builds/decor_nov21_vo.py:387 open_log
- tools/asset_forge/builds/decor_nov21_vo.py:400 inkpot_quill
- tools/asset_forge/builds/decor_nov21_vo.py:408 lantern
- tools/asset_forge/builds/decor_nov21_vo.py:424 vfig
- tools/asset_forge/builds/decor_nov21_vo.py:474 round_door_cuts
- tools/asset_forge/builds/decor_nov21_vo.py:492 hand_cuts
- tools/asset_forge/builds/decor_nov21_vo.py:502 iron_bar
- tools/asset_forge/builds/decor_nov21_vo.py:515 horn
- tools/asset_forge/builds/decor_nov21_vo.py:542 chisel_mallet
- tools/asset_forge/builds/decor_nov21_vo.py:553 vo_vigil_brazier
- tools/asset_forge/builds/decor_nov21_vo.py:579 vo_brazier_cold
- tools/asset_forge/builds/decor_nov21_vo.py:619 vo_lookout_seat
- tools/asset_forge/builds/decor_nov21_vo.py:641 vo_spyhole_wall
- tools/asset_forge/builds/decor_nov21_vo.py:675 vo_signal_horn
- tools/asset_forge/builds/decor_nov21_vo.py:695 vo_vigil_candles
- tools/asset_forge/builds/decor_nov21_vo.py:712 vo_kneeling_stone
- tools/asset_forge/builds/decor_nov21_vo.py:743 vo_oath_tablet
- tools/asset_forge/builds/decor_nov21_vo.py:767 vo_prayer_tablets
- tools/asset_forge/builds/decor_nov21_vo.py:785 vo_sealed_passage
- tools/asset_forge/builds/decor_nov21_vo.py:822 vo_bar_rack
- tools/asset_forge/builds/decor_nov21_vo.py:845 vo_jawhelm_stand
- tools/asset_forge/builds/decor_nov21_vo.py:861 mannequin
- tools/asset_forge/builds/decor_nov21_vo.py:867 pauldron
- tools/asset_forge/builds/decor_nov21_vo.py:880 vo_armour_stand
- tools/asset_forge/builds/decor_nov21_vo.py:932 vo_warning_relief
- tools/asset_forge/builds/decor_nov21_vo.py:964 vo_relief_oath
- tools/asset_forge/builds/decor_nov21_vo.py:983 vo_relief_last_watch
- tools/asset_forge/builds/decor_nov21_vo.py:1009 vo_log_lectern
- tools/asset_forge/builds/decor_nov21_vo.py:1034 vo_log_shelf
- tools/asset_forge/builds/decor_nov21_vo.py:1080 vo_hourglass_stand
- tools/asset_forge/builds/decor_nov21_vo.py:1100 vo_tally_wall
- tools/asset_forge/builds/decor_nov21_vo.py:1122 vo_final_vigil
- tools/asset_forge/builds/decor_nov21_vo.py:1171 horn_stand
- tools/asset_forge/builds/decor_nov21_vo.py:1183 vo_horn_fallen
- tools/asset_forge/builds/decor_nov21_vo.py:1208 vo_bar_snapped
- tools/asset_forge/builds/decor_nov21_vo.py:1249 vo_claw_marks
- tools/asset_forge/builds/decor_nov21_vo.py:1279 vo_dropped_lantern
- tools/asset_forge/builds/decor_nov21_vo.py:1313 vo_oil_niche
- tools/asset_forge/builds/decor_nov21_vo.py:1336 vo_candle_rack
- tools/asset_forge/builds/decor_nov21_vo.py:1365 vo_wall_brazier
- tools/asset_forge/builds/decor_nov21_vo.py:1391 vo_axe_rest
- tools/asset_forge/builds/decor_nov21_vo.py:1416 vo_orrin_bust

## tools/asset_forge/builds/drip_bucket.py (21 lines) — Drip Bucket (folder: stations): a wooden bucket with iron hoops and a handle, full of clear water.

## tools/asset_forge/builds/dungeon_junk.py (1965 lines) — Dungeon junk (owner's picks, Nov 20, 2026): small floor models just for looks, lying along walls and in corner
- tools/asset_forge/builds/dungeon_junk.py:66 meshes
- tools/asset_forge/builds/dungeon_junk.py:70 tinted
- tools/asset_forge/builds/dungeon_junk.py:92 BONE
- tools/asset_forge/builds/dungeon_junk.py:96 BRASS
- tools/asset_forge/builds/dungeon_junk.py:100 STEEL
- tools/asset_forge/builds/dungeon_junk.py:104 DARK
- tools/asset_forge/builds/dungeon_junk.py:108 lump
- tools/asset_forge/builds/dungeon_junk.py:122 rod
- tools/asset_forge/builds/dungeon_junk.py:152 slab
- tools/asset_forge/builds/dungeon_junk.py:171 turn
- tools/asset_forge/builds/dungeon_junk.py:184 jag
- tools/asset_forge/builds/dungeon_junk.py:191 long_bone
- tools/asset_forge/builds/dungeon_junk.py:204 skull
- tools/asset_forge/builds/dungeon_junk.py:221 junk_bones
- tools/asset_forge/builds/dungeon_junk.py:234 junk_sword_snapped
- tools/asset_forge/builds/dungeon_junk.py:258 junk_axe_head
- tools/asset_forge/builds/dungeon_junk.py:292 splinters
- tools/asset_forge/builds/dungeon_junk.py:308 junk_spear_broken
- tools/asset_forge/builds/dungeon_junk.py:328 board_slab
- tools/asset_forge/builds/dungeon_junk.py:335 board_poly
- tools/asset_forge/builds/dungeon_junk.py:352 arc_band
- tools/asset_forge/builds/dungeon_junk.py:370 shield
- tools/asset_forge/builds/dungeon_junk.py:428 junk_shield_wood
- tools/asset_forge/builds/dungeon_junk.py:432 junk_shield_iron
- tools/asset_forge/builds/dungeon_junk.py:437 rubble_board
- tools/asset_forge/builds/dungeon_junk.py:447 junk_rubble_wood
- tools/asset_forge/builds/dungeon_junk.py:461 _footprint
- tools/asset_forge/builds/dungeon_junk.py:468 _overlap
- tools/asset_forge/builds/dungeon_junk.py:481 rubble_pile
- tools/asset_forge/builds/dungeon_junk.py:521 rag
- tools/asset_forge/builds/dungeon_junk.py:565 junk_rags
- tools/asset_forge/builds/dungeon_junk.py:598 rags_pair
- tools/asset_forge/builds/dungeon_junk.py:619 dull
- tools/asset_forge/builds/dungeon_junk.py:633 GLASS
- tools/asset_forge/builds/dungeon_junk.py:645 RUST
- tools/asset_forge/builds/dungeon_junk.py:649 bolt
- tools/asset_forge/builds/dungeon_junk.py:654 junk_pickaxe_broken
- tools/asset_forge/builds/dungeon_junk.py:683 junk_shovel_bent
- tools/asset_forge/builds/dungeon_junk.py:711 hewn_beam
- tools/asset_forge/builds/dungeon_junk.py:820 beam_band
- tools/asset_forge/builds/dungeon_junk.py:842 junk_beam_snapped
- tools/asset_forge/builds/dungeon_junk.py:865 junk_helmet
- tools/asset_forge/builds/dungeon_junk.py:906 junk_lantern
- tools/asset_forge/builds/dungeon_junk.py:937 spin
- tools/asset_forge/builds/dungeon_junk.py:950 drop
- tools/asset_forge/builds/dungeon_junk.py:963 lathe
- tools/asset_forge/builds/dungeon_junk.py:993 urn_body
- tools/asset_forge/builds/dungeon_junk.py:1009 junk_urns
- tools/asset_forge/builds/dungeon_junk.py:1019 shard
- tools/asset_forge/builds/dungeon_junk.py:1027 smashed_urn
- tools/asset_forge/builds/dungeon_junk.py:1071 lid_on_floor
- tools/asset_forge/builds/dungeon_junk.py:1079 urn_broken
- tools/asset_forge/builds/dungeon_junk.py:1116 plait
- tools/asset_forge/builds/dungeon_junk.py:1130 junk_statue_head
- tools/asset_forge/builds/dungeon_junk.py:1161 sheet
- tools/asset_forge/builds/dungeon_junk.py:1182 tube
- tools/asset_forge/builds/dungeon_junk.py:1203 ring
- tools/asset_forge/builds/dungeon_junk.py:1219 old_helm
- tools/asset_forge/builds/dungeon_junk.py:1272 plate_w
- tools/asset_forge/builds/dungeon_junk.py:1278 plate_pt
- tools/asset_forge/builds/dungeon_junk.py:1290 chest_plate
- tools/asset_forge/builds/dungeon_junk.py:1339 pauldron
- tools/asset_forge/builds/dungeon_junk.py:1357 vambrace
- tools/asset_forge/builds/dungeon_junk.py:1374 junk_armour_pile
- tools/asset_forge/builds/dungeon_junk.py:1387 coffin_w
- tools/asset_forge/builds/dungeon_junk.py:1394 junk_coffin_lid
- tools/asset_forge/builds/dungeon_junk.py:1459 wavy
- tools/asset_forge/builds/dungeon_junk.py:1471 slag_lump
- tools/asset_forge/builds/dungeon_junk.py:1487 junk_slag
- tools/asset_forge/builds/dungeon_junk.py:1501 junk_tongs_hammer
- tools/asset_forge/builds/dungeon_junk.py:1543 crucible_piece
- tools/asset_forge/builds/dungeon_junk.py:1563 junk_crucible_mould
- tools/asset_forge/builds/dungeon_junk.py:1586 junk_scrap
- tools/asset_forge/builds/dungeon_junk.py:1619 junk_rubble_brick
- tools/asset_forge/builds/dungeon_junk.py:1661 CHAR
- tools/asset_forge/builds/dungeon_junk.py:1666 ASH
- tools/asset_forge/builds/dungeon_junk.py:1670 flat_lump
- tools/asset_forge/builds/dungeon_junk.py:1684 stick
- tools/asset_forge/builds/dungeon_junk.py:1721 junk_campfire_cold
- tools/asset_forge/builds/dungeon_junk.py:1756 bed_height
- tools/asset_forge/builds/dungeon_junk.py:1761 cloth_rect
- tools/asset_forge/builds/dungeon_junk.py:1803 junk_bedroll_rotten
- tools/asset_forge/builds/dungeon_junk.py:1835 junk_torch_dropped
- tools/asset_forge/builds/dungeon_junk.py:1863 junk_cookpot_tipped
- tools/asset_forge/builds/dungeon_junk.py:1910 settle

## tools/asset_forge/builds/dungeon_mine.py (710 lines) — Lampwick Drift's mine set (dungeon 2, owner Nov 20, 2026: "new assets by type of dungeon"). Built from the sam
- tools/asset_forge/builds/dungeon_mine.py:62 board
- tools/asset_forge/builds/dungeon_mine.py:69 iron
- tools/asset_forge/builds/dungeon_mine.py:73 nail
- tools/asset_forge/builds/dungeon_mine.py:78 rail_lane
- tools/asset_forge/builds/dungeon_mine.py:106 side_prism
- tools/asset_forge/builds/dungeon_mine.py:116 rail_wedge
- tools/asset_forge/builds/dungeon_mine.py:135 rail_buffer
- tools/asset_forge/builds/dungeon_mine.py:156 trap_cart
- tools/asset_forge/builds/dungeon_mine.py:212 bake
- tools/asset_forge/builds/dungeon_mine.py:220 big_stone
- tools/asset_forge/builds/dungeon_mine.py:239 trap_swing_boulder
- tools/asset_forge/builds/dungeon_mine.py:274 jaw
- tools/asset_forge/builds/dungeon_mine.py:310 trap_bear_jaws
- tools/asset_forge/builds/dungeon_mine.py:334 trap_tripwire_wall
- tools/asset_forge/builds/dungeon_mine.py:379 tripwire
- tools/asset_forge/builds/dungeon_mine.py:391 spike_floor
- tools/asset_forge/builds/dungeon_mine.py:427 trap_chest_spikes
- tools/asset_forge/builds/dungeon_mine.py:457 tri_prism
- tools/asset_forge/builds/dungeon_mine.py:469 mine_lamp
- tools/asset_forge/builds/dungeon_mine.py:514 rubble_ore
- tools/asset_forge/builds/dungeon_mine.py:597 groove_paint
- tools/asset_forge/builds/dungeon_mine.py:612 floor_grooved
- tools/asset_forge/builds/dungeon_mine.py:644 heal_fountain

## tools/asset_forge/builds/dungeon_pell.py (202 lines) — Old Pell's Diggings' new pieces (dungeon 3, owner Nov 20, 2026: "build whatever you need for Dungeon 3"). Buil
- tools/asset_forge/builds/dungeon_pell.py:49 boards_between
- tools/asset_forge/builds/dungeon_pell.py:61 trap_spear_wall
- tools/asset_forge/builds/dungeon_pell.py:100 trap_push_wall
- tools/asset_forge/builds/dungeon_pell.py:125 floor_scrape
- tools/asset_forge/builds/dungeon_pell.py:136 lift_platform
- tools/asset_forge/builds/dungeon_pell.py:167 lift_winch

## tools/asset_forge/builds/dungeon_rootwood.py (966 lines) — Dungeon traps in root wood, batch 2 (owner, Nov 19, 2026: dungeons, docs/decisions/2026-11-19-dungeons.md: "al
- tools/asset_forge/builds/dungeon_rootwood.py:49 meshes
- tools/asset_forge/builds/dungeon_rootwood.py:54 dart_plate
- tools/asset_forge/builds/dungeon_rootwood.py:68 bore
- tools/asset_forge/builds/dungeon_rootwood.py:83 dart_wall
- tools/asset_forge/builds/dungeon_rootwood.py:119 floor_break
- tools/asset_forge/builds/dungeon_rootwood.py:148 board_groups
- tools/asset_forge/builds/dungeon_rootwood.py:174 chain_hanging
- tools/asset_forge/builds/dungeon_rootwood.py:180 chain
- tools/asset_forge/builds/dungeon_rootwood.py:191 crusher
- tools/asset_forge/builds/dungeon_rootwood.py:238 rope
- tools/asset_forge/builds/dungeon_rootwood.py:244 bridge
- tools/asset_forge/builds/dungeon_rootwood.py:295 entrance
- tools/asset_forge/builds/dungeon_rootwood.py:325 loot_door
- tools/asset_forge/builds/dungeon_rootwood.py:368 gate_round
- tools/asset_forge/builds/dungeon_rootwood.py:396 lever
- tools/asset_forge/builds/dungeon_rootwood.py:418 railing_broken
- tools/asset_forge/builds/dungeon_rootwood.py:448 vprism
- tools/asset_forge/builds/dungeon_rootwood.py:459 jag
- tools/asset_forge/builds/dungeon_rootwood.py:464 crack_line
- tools/asset_forge/builds/dungeon_rootwood.py:469 split_board
- tools/asset_forge/builds/dungeon_rootwood.py:476 wall_frame3
- tools/asset_forge/builds/dungeon_rootwood.py:486 wall_cracked
- tools/asset_forge/builds/dungeon_rootwood.py:536 wall_old
- tools/asset_forge/builds/dungeon_rootwood.py:577 floor_old
- tools/asset_forge/builds/dungeon_rootwood.py:612 chisel_slab
- tools/asset_forge/builds/dungeon_rootwood.py:644 floor_loose_stone
- tools/asset_forge/builds/dungeon_rootwood.py:685 rot_x
- tools/asset_forge/builds/dungeon_rootwood.py:698 wall_broken
- tools/asset_forge/builds/dungeon_rootwood.py:725 recipe_stand
- tools/asset_forge/builds/dungeon_rootwood.py:758 parchment
- tools/asset_forge/builds/dungeon_rootwood.py:789 recipe_scroll
- tools/asset_forge/builds/dungeon_rootwood.py:836 bridge_posts
- tools/asset_forge/builds/dungeon_rootwood.py:861 age_paint
- tools/asset_forge/builds/dungeon_rootwood.py:901 save_parts
- tools/asset_forge/builds/dungeon_rootwood.py:940 pictures

## tools/asset_forge/builds/dungeon_traps.py (149 lines) — Dungeon traps, batch 1 (owner, Nov 19, 2026: dungeons, docs/decisions/2026-11-19-dungeons.md): falling stalact
- tools/asset_forge/builds/dungeon_traps.py:38 cracked_skin
- tools/asset_forge/builds/dungeon_traps.py:46 drip_parts
- tools/asset_forge/builds/dungeon_traps.py:62 build_thin
- tools/asset_forge/builds/dungeon_traps.py:68 build_fat
- tools/asset_forge/builds/dungeon_traps.py:74 build_cluster
- tools/asset_forge/builds/dungeon_traps.py:83 spike_bed_rock
- tools/asset_forge/builds/dungeon_traps.py:101 build_spikes

## tools/asset_forge/builds/dwarf_armor.py (974 lines) — The dwarf's armor sets, hand-built OVER the finished dwarf body (Claude, Nov 18, 2026; F55, MODEL-RULES Rule 1
- tools/asset_forge/builds/dwarf_armor.py:53 log
- tools/asset_forge/builds/dwarf_armor.py:68 world_verts
- tools/asset_forge/builds/dwarf_armor.py:76 bvh_of
- tools/asset_forge/builds/dwarf_armor.py:86 smin
- tools/asset_forge/builds/dwarf_armor.py:90 smax
- tools/asset_forge/builds/dwarf_armor.py:94 blur
- tools/asset_forge/builds/dwarf_armor.py:108 G
- tools/asset_forge/builds/dwarf_armor.py:175 drop_inside
- tools/asset_forge/builds/dwarf_armor.py:194 drop_crumbs
- tools/asset_forge/builds/dwarf_armor.py:206 wobble
- tools/asset_forge/builds/dwarf_armor.py:217 lumps
- tools/asset_forge/builds/dwarf_armor.py:229 ray_to
- tools/asset_forge/builds/dwarf_armor.py:238 frame_at
- tools/asset_forge/builds/dwarf_armor.py:248 small_piece
- tools/asset_forge/builds/dwarf_armor.py:294 plain
- tools/asset_forge/builds/dwarf_armor.py:326 stitch_band
- tools/asset_forge/builds/dwarf_armor.py:336 helm_region
- tools/asset_forge/builds/dwarf_armor.py:348 panel_seam
- tools/asset_forge/builds/dwarf_armor.py:360 capped_head
- tools/asset_forge/builds/dwarf_armor.py:396 dome_reach
- tools/asset_forge/builds/dwarf_armor.py:418 dome_dist
- tools/asset_forge/builds/dwarf_armor.py:433 build_helmet
- tools/asset_forge/builds/dwarf_armor.py:489 jerkin_region
- tools/asset_forge/builds/dwarf_armor.py:505 jerkin_seams
- tools/asset_forge/builds/dwarf_armor.py:519 strap_dist
- tools/asset_forge/builds/dwarf_armor.py:529 pad_zone
- tools/asset_forge/builds/dwarf_armor.py:535 pad_strips
- tools/asset_forge/builds/dwarf_armor.py:545 quilt
- tools/asset_forge/builds/dwarf_armor.py:558 build_jerkin
- tools/asset_forge/builds/dwarf_armor.py:697 build_boots
- tools/asset_forge/builds/dwarf_armor.py:802 pick
- tools/asset_forge/builds/dwarf_armor.py:873 source_points

## tools/asset_forge/builds/dwarf_body.py (1197 lines) — The player dwarf's body, hand-built around the game's real skeleton (Claude 3, Nov 16, 2026; MODEL-RULES Rule 
- tools/asset_forge/builds/dwarf_body.py:50 L2B
- tools/asset_forge/builds/dwarf_body.py:58 B
- tools/asset_forge/builds/dwarf_body.py:62 P
- tools/asset_forge/builds/dwarf_body.py:77 ring_loft
- tools/asset_forge/builds/dwarf_body.py:86 tube
- tools/asset_forge/builds/dwarf_body.py:104 Q
- tools/asset_forge/builds/dwarf_body.py:109 QV
- tools/asset_forge/builds/dwarf_body.py:113 QD
- tools/asset_forge/builds/dwarf_body.py:119 clay
- tools/asset_forge/builds/dwarf_body.py:125 torus
- tools/asset_forge/builds/dwarf_body.py:135 ering
- tools/asset_forge/builds/dwarf_body.py:143 finish
- tools/asset_forge/builds/dwarf_body.py:172 torso_at
- tools/asset_forge/builds/dwarf_body.py:181 loft
- tools/asset_forge/builds/dwarf_body.py:197 body_ring
- tools/asset_forge/builds/dwarf_body.py:206 on_torso
- tools/asset_forge/builds/dwarf_body.py:214 hem_up
- tools/asset_forge/builds/dwarf_body.py:222 chaikin
- tools/asset_forge/builds/dwarf_body.py:233 press
- tools/asset_forge/builds/dwarf_body.py:244 crease
- tools/asset_forge/builds/dwarf_body.py:434 on_surf
- tools/asset_forge/builds/dwarf_body.py:450 groove
- tools/asset_forge/builds/dwarf_body.py:459 etube
- tools/asset_forge/builds/dwarf_body.py:479 patch_box
- tools/asset_forge/builds/dwarf_body.py:692 weave
- tools/asset_forge/builds/dwarf_body.py:796 chain_along
- tools/asset_forge/builds/dwarf_body.py:810 path_s
- tools/asset_forge/builds/dwarf_body.py:977 head_share
- tools/asset_forge/builds/dwarf_body.py:982 set_weights
- tools/asset_forge/builds/dwarf_body.py:1005 along
- tools/asset_forge/builds/dwarf_body.py:1018 smooth01
- tools/asset_forge/builds/dwarf_body.py:1023 along_by_height
- tools/asset_forge/builds/dwarf_body.py:1094 main_chain

## tools/asset_forge/builds/dwarf_head.py (1431 lines) — The Happy dwarf's head, hair and beard, round 2 (Claude, Nov 16, 2026), built the Rock Beetle way
- tools/asset_forge/builds/dwarf_head.py:51 Hd
- tools/asset_forge/builds/dwarf_head.py:56 Dv
- tools/asset_forge/builds/dwarf_head.py:65 bvh_of
- tools/asset_forge/builds/dwarf_head.py:80 hit_front
- tools/asset_forge/builds/dwarf_head.py:86 hit_round
- tools/asset_forge/builds/dwarf_head.py:95 w_of
- tools/asset_forge/builds/dwarf_head.py:99 shirt_front
- tools/asset_forge/builds/dwarf_head.py:105 sblob
- tools/asset_forge/builds/dwarf_head.py:111 ell
- tools/asset_forge/builds/dwarf_head.py:125 tube
- tools/asset_forge/builds/dwarf_head.py:131 _spline
- tools/asset_forge/builds/dwarf_head.py:145 _resample
- tools/asset_forge/builds/dwarf_head.py:161 lock
- tools/asset_forge/builds/dwarf_head.py:222 jit
- tools/asset_forge/builds/dwarf_head.py:227 _smin
- tools/asset_forge/builds/dwarf_head.py:232 Clay
- tools/asset_forge/builds/dwarf_head.py:283 surface_nets
- tools/asset_forge/builds/dwarf_head.py:341 eye_centre
- tools/asset_forge/builds/dwarf_head.py:345 eye_look
- tools/asset_forge/builds/dwarf_head.py:349 build_face
- tools/asset_forge/builds/dwarf_head.py:386 build_lids
- tools/asset_forge/builds/dwarf_head.py:431 build_ear
- tools/asset_forge/builds/dwarf_head.py:455 hairline
- tools/asset_forge/builds/dwarf_head.py:460 scalp_lock
- tools/asset_forge/builds/dwarf_head.py:473 build_hair
- tools/asset_forge/builds/dwarf_head.py:593 build_brows
- tools/asset_forge/builds/dwarf_head.py:612 wface
- tools/asset_forge/builds/dwarf_head.py:623 build_moustache
- tools/asset_forge/builds/dwarf_head.py:635 build_beard
- tools/asset_forge/builds/dwarf_head.py:703 lathe
- tools/asset_forge/builds/dwarf_head.py:725 braid
- tools/asset_forge/builds/dwarf_head.py:827 build_braids
- tools/asset_forge/builds/dwarf_head.py:835 arrays
- tools/asset_forge/builds/dwarf_head.py:845 put
- tools/asset_forge/builds/dwarf_head.py:850 line_dist
- tools/asset_forge/builds/dwarf_head.py:860 on_face
- tools/asset_forge/builds/dwarf_head.py:869 sculpt_face
- tools/asset_forge/builds/dwarf_head.py:915 sculpt_hair
- tools/asset_forge/builds/dwarf_head.py:925 lay_on_body
- tools/asset_forge/builds/dwarf_head.py:973 pinch_rings
- tools/asset_forge/builds/dwarf_head.py:994 creases
- tools/asset_forge/builds/dwarf_head.py:1014 nose_pockets
- tools/asset_forge/builds/dwarf_head.py:1062 hard_lines
- tools/asset_forge/builds/dwarf_head.py:1090 body_gap
- tools/asset_forge/builds/dwarf_head.py:1101 hair_mask
- tools/asset_forge/builds/dwarf_head.py:1115 smooth_values
- tools/asset_forge/builds/dwarf_head.py:1133 measure
- tools/asset_forge/builds/dwarf_head.py:1179 plain
- tools/asset_forge/builds/dwarf_head.py:1192 build
- tools/asset_forge/builds/dwarf_head.py:1343 review

## tools/asset_forge/builds/farm_plot.py (35 lines) — Farm Plot (folder: stations): a low square bed of dark soil framed with stones, with cave mushrooms.

## tools/asset_forge/builds/furniture.py (97 lines) — Furniture for the Decor tab (owner, Nov 19, 2026: "some do something": beds, seats, shelves, lights; decisions
- tools/asset_forge/builds/furniture.py:66 build

## tools/asset_forge/builds/gem_bench.py (56 lines) — Gem Bench (folder: stations), hand-built from the kit (follows the ChatGPT concept: stone-block top, wooden fr

## tools/asset_forge/builds/glow_lamp.py (26 lines) — Glow Lamp (folder: stations): a short post on stone feet with a little iron cage holding a glowing green gland

## tools/asset_forge/builds/glow_marker.py (30 lines) — Glow Marker (folder: stations): a stake with spiral and cross rope lashing and an iron claw holding a glowing 

## tools/asset_forge/builds/glow_trees.py (313 lines) — Glow trees for the glow groves (owner, Nov 19, 2026: "the trees glow ... sometimes the main source of light in
- tools/asset_forge/builds/glow_trees.py:67 import_tree
- tools/asset_forge/builds/glow_trees.py:83 split_leaves
- tools/asset_forge/builds/glow_trees.py:102 glow_leaf_material
- tools/asset_forge/builds/glow_trees.py:145 wobble
- tools/asset_forge/builds/glow_trees.py:156 crack_bark_material
- tools/asset_forge/builds/glow_trees.py:190 repaint_bark
- tools/asset_forge/builds/glow_trees.py:197 scale_to
- tools/asset_forge/builds/glow_trees.py:211 export
- tools/asset_forge/builds/glow_trees.py:244 _bark_as_jpeg
- tools/asset_forge/builds/glow_trees.py:269 _leaves_cutout
- tools/asset_forge/builds/glow_trees.py:291 build

## tools/asset_forge/builds/grindstone.py (30 lines) — Grindstone (folder: stations): a round sharpening stone on an axle in a wooden frame, with a crank and a littl

## tools/asset_forge/builds/grove_dressing.py (125 lines) — The floor of the glow groves (owner, Nov 19, 2026: rocks, pebbles, grass, ferns and plants "added alongside ou
- tools/asset_forge/builds/grove_dressing.py:74 rock
- tools/asset_forge/builds/grove_dressing.py:86 plant
- tools/asset_forge/builds/grove_dressing.py:100 _cutout_all

## tools/asset_forge/builds/hearthbrick_v2.py (787 lines) — Hearthbrick, version 2 (owner, Nov 20): the dwarven brick style the owner picked, idea B on
- tools/asset_forge/builds/hearthbrick_v2.py:41 tag
- tools/asset_forge/builds/hearthbrick_v2.py:47 since
- tools/asset_forge/builds/hearthbrick_v2.py:51 cbox
- tools/asset_forge/builds/hearthbrick_v2.py:60 m_brick
- tools/asset_forge/builds/hearthbrick_v2.py:64 m_lime
- tools/asset_forge/builds/hearthbrick_v2.py:68 m_mortar
- tools/asset_forge/builds/hearthbrick_v2.py:72 Panel
- tools/asset_forge/builds/hearthbrick_v2.py:99 cut_circle
- tools/asset_forge/builds/hearthbrick_v2.py:111 simplify
- tools/asset_forge/builds/hearthbrick_v2.py:127 arch_cut
- tools/asset_forge/builds/hearthbrick_v2.py:142 mortar_arc
- tools/asset_forge/builds/hearthbrick_v2.py:164 thickness
- tools/asset_forge/builds/hearthbrick_v2.py:170 thin
- tools/asset_forge/builds/hearthbrick_v2.py:175 lay_row
- tools/asset_forge/builds/hearthbrick_v2.py:189 brick
- tools/asset_forge/builds/hearthbrick_v2.py:212 bevel_seen
- tools/asset_forge/builds/hearthbrick_v2.py:234 stone
- tools/asset_forge/builds/hearthbrick_v2.py:249 in_diamond
- tools/asset_forge/builds/hearthbrick_v2.py:263 segments
- tools/asset_forge/builds/hearthbrick_v2.py:276 round_cutter
- tools/asset_forge/builds/hearthbrick_v2.py:297 ring
- tools/asset_forge/builds/hearthbrick_v2.py:327 keystone
- tools/asset_forge/builds/hearthbrick_v2.py:336 arch_backing
- tools/asset_forge/builds/hearthbrick_v2.py:356 wall_body
- tools/asset_forge/builds/hearthbrick_v2.py:456 leaded_glass
- tools/asset_forge/builds/hearthbrick_v2.py:493 glass_m
- tools/asset_forge/builds/hearthbrick_v2.py:510 wall
- tools/asset_forge/builds/hearthbrick_v2.py:514 doorway
- tools/asset_forge/builds/hearthbrick_v2.py:518 window_wall
- tools/asset_forge/builds/hearthbrick_v2.py:526 herringbone
- tools/asset_forge/builds/hearthbrick_v2.py:566 stone_frame
- tools/asset_forge/builds/hearthbrick_v2.py:595 floor
- tools/asset_forge/builds/hearthbrick_v2.py:625 foundation
- tools/asset_forge/builds/hearthbrick_v2.py:676 split_big_faces
- tools/asset_forge/builds/hearthbrick_v2.py:699 hb
- tools/asset_forge/builds/hearthbrick_v2.py:703 band_uv
- tools/asset_forge/builds/hearthbrick_v2.py:716 paint

## tools/asset_forge/builds/hearthbrick_v2_diagonal.py (107 lines) — Hearthbrick v2: the 4 old diagonal pieces (owner, Nov 20: the old ones failed the model checks). They are hidd
- tools/asset_forge/builds/hearthbrick_v2_diagonal.py:28 cut_to_square
- tools/asset_forge/builds/hearthbrick_v2_diagonal.py:65 turn

## tools/asset_forge/builds/hearthbrick_v2_frame.py (275 lines) — Hearthbrick v2, the frame pieces (owner, Nov 20: "work through all of the batches"): beam, short beam, brace,
- tools/asset_forge/builds/hearthbrick_v2_frame.py:25 timber_m
- tools/asset_forge/builds/hearthbrick_v2_frame.py:29 copper_m
- tools/asset_forge/builds/hearthbrick_v2_frame.py:33 tagged
- tools/asset_forge/builds/hearthbrick_v2_frame.py:41 rivet
- tools/asset_forge/builds/hearthbrick_v2_frame.py:46 beam
- tools/asset_forge/builds/hearthbrick_v2_frame.py:62 beam_half
- tools/asset_forge/builds/hearthbrick_v2_frame.py:67 brace
- tools/asset_forge/builds/hearthbrick_v2_frame.py:94 arch
- tools/asset_forge/builds/hearthbrick_v2_frame.py:140 railing
- tools/asset_forge/builds/hearthbrick_v2_frame.py:193 ladder
- tools/asset_forge/builds/hearthbrick_v2_frame.py:209 mine_prop
- tools/asset_forge/builds/hearthbrick_v2_frame.py:241 paint

## tools/asset_forge/builds/hearthbrick_v2_ground.py (519 lines) — Hearthbrick, version 2: the ground pieces (owner, Nov 20: "work through all of the batches"). Same look as the
- tools/asset_forge/builds/hearthbrick_v2_ground.py:27 lime_roles
- tools/asset_forge/builds/hearthbrick_v2_ground.py:34 herringbone_in
- tools/asset_forge/builds/hearthbrick_v2_ground.py:72 rect_planes
- tools/asset_forge/builds/hearthbrick_v2_ground.py:76 rect_pts
- tools/asset_forge/builds/hearthbrick_v2_ground.py:81 floor_any
- tools/asset_forge/builds/hearthbrick_v2_ground.py:110 floor_half
- tools/asset_forge/builds/hearthbrick_v2_ground.py:114 small_floor
- tools/asset_forge/builds/hearthbrick_v2_ground.py:118 ceiling_panel
- tools/asset_forge/builds/hearthbrick_v2_ground.py:126 tri_band
- tools/asset_forge/builds/hearthbrick_v2_ground.py:135 tri_box
- tools/asset_forge/builds/hearthbrick_v2_ground.py:140 floor_triangle
- tools/asset_forge/builds/hearthbrick_v2_ground.py:167 turn
- tools/asset_forge/builds/hearthbrick_v2_ground.py:174 arch_side
- tools/asset_forge/builds/hearthbrick_v2_ground.py:206 foundation_any
- tools/asset_forge/builds/hearthbrick_v2_ground.py:232 foundation_half
- tools/asset_forge/builds/hearthbrick_v2_ground.py:236 foundation_triangle
- tools/asset_forge/builds/hearthbrick_v2_ground.py:269 stairs
- tools/asset_forge/builds/hearthbrick_v2_ground.py:338 stair_sides
- tools/asset_forge/builds/hearthbrick_v2_ground.py:373 foundation_steps
- tools/asset_forge/builds/hearthbrick_v2_ground.py:378 ramp

## tools/asset_forge/builds/hearthbrick_v2_kiln.py (316 lines) — The Old Kiln (owner, Nov 21: ruin 5 of Zone 1, F479): the kiln-master's brick kiln, its crown and its wreckage
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:43 meshes
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:47 since
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:51 bake
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:62 at
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:67 ring_dir
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:72 settle
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:81 knocked
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:115 prism
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:130 turn_objs
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:134 crown_slope
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:146 under
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:151 crown
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:213 kiln_crown
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:217 kiln_crown_broken
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:222 kiln_wall_fallen
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:244 brick
- tools/asset_forge/builds/hearthbrick_v2_kiln.py:252 brick_stack_toppled

## tools/asset_forge/builds/hearthbrick_v2_roofs.py (405 lines) — Hearthbrick v2 roofs (owner, Nov 20, F427): curved terracotta tiles, like the old dwarven kilns made them.
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:39 tag
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:47 since
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:51 col_range
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:68 tile_mesh
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:85 slope_point
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:90 tiles
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:158 box_between
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:172 normal
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:180 slope_panel
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:215 top_h
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:221 roof
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:226 ridge_tiles
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:243 prism
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:258 ridge
- tools/asset_forge/builds/hearthbrick_v2_roofs.py:289 roof_corner

## tools/asset_forge/builds/hearthbrick_v2_round.py (343 lines) — Hearthbrick, version 2: the round pieces (owner, Nov 20, F427): the deep green round door with big hammered
- tools/asset_forge/builds/hearthbrick_v2_round.py:31 make_green
- tools/asset_forge/builds/hearthbrick_v2_round.py:61 arc
- tools/asset_forge/builds/hearthbrick_v2_round.py:65 sector
- tools/asset_forge/builds/hearthbrick_v2_round.py:70 chisel_edges
- tools/asset_forge/builds/hearthbrick_v2_round.py:77 brick_course
- tools/asset_forge/builds/hearthbrick_v2_round.py:95 mortar_core
- tools/asset_forge/builds/hearthbrick_v2_round.py:102 lime_block
- tools/asset_forge/builds/hearthbrick_v2_round.py:106 lime_ring
- tools/asset_forge/builds/hearthbrick_v2_round.py:119 courses
- tools/asset_forge/builds/hearthbrick_v2_round.py:130 pillar
- tools/asset_forge/builds/hearthbrick_v2_round.py:149 col_base
- tools/asset_forge/builds/hearthbrick_v2_round.py:159 col_shaft
- tools/asset_forge/builds/hearthbrick_v2_round.py:169 col_capital
- tools/asset_forge/builds/hearthbrick_v2_round.py:180 column
- tools/asset_forge/builds/hearthbrick_v2_round.py:188 column_base
- tools/asset_forge/builds/hearthbrick_v2_round.py:192 column_shaft
- tools/asset_forge/builds/hearthbrick_v2_round.py:196 column_capital
- tools/asset_forge/builds/hearthbrick_v2_round.py:201 door
- tools/asset_forge/builds/hearthbrick_v2_round.py:266 rune_uv
- tools/asset_forge/builds/hearthbrick_v2_round.py:288 paint
- tools/asset_forge/builds/hearthbrick_v2_round.py:305 tri_count

## tools/asset_forge/builds/hearthbrick_v2_ruin.py (312 lines) — Hearthbrick ruin pieces (owner, Nov 20, F479: the Brewhall, the third ruin): the clay-brick versions of the
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:36 meshes
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:40 box_of
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:47 sheet_after
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:65 hole_backs
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:78 ruin_wall_worn
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:100 ruin_wall_collapsed
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:126 ruin_rubble
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:160 bake
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:168 chimney_section
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:187 chimney_fallen
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:230 bmesh_trim
- tools/asset_forge/builds/hearthbrick_v2_ruin.py:240 barrel_smashed

## tools/asset_forge/builds/hearthbrick_v2_walls.py (411 lines) — Hearthbrick, version 2, the wall family (owner, Nov 20: "work through all of the batches"): half wall, narrow
- tools/asset_forge/builds/hearthbrick_v2_walls.py:28 slope_line
- tools/asset_forge/builds/hearthbrick_v2_walls.py:35 body
- tools/asset_forge/builds/hearthbrick_v2_walls.py:173 coping
- tools/asset_forge/builds/hearthbrick_v2_walls.py:189 rune_roundel
- tools/asset_forge/builds/hearthbrick_v2_walls.py:199 half_wall
- tools/asset_forge/builds/hearthbrick_v2_walls.py:203 wall_narrow
- tools/asset_forge/builds/hearthbrick_v2_walls.py:207 window_wide
- tools/asset_forge/builds/hearthbrick_v2_walls.py:213 trim_tri_ends
- tools/asset_forge/builds/hearthbrick_v2_walls.py:249 sloped_wall
- tools/asset_forge/builds/hearthbrick_v2_walls.py:254 gable_26
- tools/asset_forge/builds/hearthbrick_v2_walls.py:258 gable_45
- tools/asset_forge/builds/hearthbrick_v2_walls.py:262 battlement
- tools/asset_forge/builds/hearthbrick_v2_walls.py:322 battlement_corner
- tools/asset_forge/builds/hearthbrick_v2_walls.py:364 band_uv
- tools/asset_forge/builds/hearthbrick_v2_walls.py:376 paint

## tools/asset_forge/builds/items_food.py (201 lines) — Food and drink (folder: items), hand-built from the kit: bowls, pots, skewers, pies, roasts, tankards, cups, b
- tools/asset_forge/builds/items_food.py:17 col
- tools/asset_forge/builds/items_food.py:22 chunks
- tools/asset_forge/builds/items_food.py:33 bowl
- tools/asset_forge/builds/items_food.py:44 pot
- tools/asset_forge/builds/items_food.py:53 skewer
- tools/asset_forge/builds/items_food.py:63 pie
- tools/asset_forge/builds/items_food.py:81 board
- tools/asset_forge/builds/items_food.py:86 steak
- tools/asset_forge/builds/items_food.py:95 roast
- tools/asset_forge/builds/items_food.py:103 snail_on_stick
- tools/asset_forge/builds/items_food.py:109 mash
- tools/asset_forge/builds/items_food.py:117 risotto
- tools/asset_forge/builds/items_food.py:123 tankard
- tools/asset_forge/builds/items_food.py:134 cup
- tools/asset_forge/builds/items_food.py:141 bottle
- tools/asset_forge/builds/items_food.py:150 jug

## tools/asset_forge/builds/items_gear.py (222 lines) — Gear and armor (folder: items), hand-built from the kit, many models in one run.
- tools/asset_forge/builds/items_gear.py:19 dome
- tools/asset_forge/builds/items_gear.py:34 mat_of
- tools/asset_forge/builds/items_gear.py:38 shell_spiral
- tools/asset_forge/builds/items_gear.py:44 helm
- tools/asset_forge/builds/items_gear.py:65 chest_armor
- tools/asset_forge/builds/items_gear.py:82 legs
- tools/asset_forge/builds/items_gear.py:96 boots
- tools/asset_forge/builds/items_gear.py:112 satchel
- tools/asset_forge/builds/items_gear.py:121 lantern
- tools/asset_forge/builds/items_gear.py:137 spore_mask
- tools/asset_forge/builds/items_gear.py:148 prospectors_lens
- tools/asset_forge/builds/items_gear.py:155 war_horn
- tools/asset_forge/builds/items_gear.py:181 waterskin
- tools/asset_forge/builds/items_gear.py:192 water_bucket

## tools/asset_forge/builds/items_materials.py (471 lines) — Materials, crystals, gems, runes, monster parts and odds and ends (folder: items), hand-built from the kit.
- tools/asset_forge/builds/items_materials.py:20 col
- tools/asset_forge/builds/items_materials.py:25 lump
- tools/asset_forge/builds/items_materials.py:32 rock
- tools/asset_forge/builds/items_materials.py:38 ore
- tools/asset_forge/builds/items_materials.py:48 crystal
- tools/asset_forge/builds/items_materials.py:53 block
- tools/asset_forge/builds/items_materials.py:61 bricks
- tools/asset_forge/builds/items_materials.py:69 ingot
- tools/asset_forge/builds/items_materials.py:74 planks
- tools/asset_forge/builds/items_materials.py:80 root_log
- tools/asset_forge/builds/items_materials.py:89 mush_log
- tools/asset_forge/builds/items_materials.py:95 fiber
- tools/asset_forge/builds/items_materials.py:105 moss
- tools/asset_forge/builds/items_materials.py:112 dirt
- tools/asset_forge/builds/items_materials.py:119 rope_coil
- tools/asset_forge/builds/items_materials.py:125 leather
- tools/asset_forge/builds/items_materials.py:135 scrap
- tools/asset_forge/builds/items_materials.py:144 blob
- tools/asset_forge/builds/items_materials.py:163 snail_meat
- tools/asset_forge/builds/items_materials.py:172 bug_meat
- tools/asset_forge/builds/items_materials.py:181 flesh
- tools/asset_forge/builds/items_materials.py:189 amber_block
- tools/asset_forge/builds/items_materials.py:196 tuber
- tools/asset_forge/builds/items_materials.py:204 mushroom
- tools/asset_forge/builds/items_materials.py:220 morel
- tools/asset_forge/builds/items_materials.py:226 meat
- tools/asset_forge/builds/items_materials.py:239 plate
- tools/asset_forge/builds/items_materials.py:258 curved_blade
- tools/asset_forge/builds/items_materials.py:279 fang
- tools/asset_forge/builds/items_materials.py:298 silk
- tools/asset_forge/builds/items_materials.py:303 pouch
- tools/asset_forge/builds/items_materials.py:312 brilliant
- tools/asset_forge/builds/items_materials.py:339 rune
- tools/asset_forge/builds/items_materials.py:351 bottle
- tools/asset_forge/builds/items_materials.py:360 bomb
- tools/asset_forge/builds/items_materials.py:373 page
- tools/asset_forge/builds/items_materials.py:381 whetstone
- tools/asset_forge/builds/items_materials.py:387 heartstone
- tools/asset_forge/builds/items_materials.py:400 lens
- tools/asset_forge/builds/items_materials.py:406 shell_piece

## tools/asset_forge/builds/items_tools.py (442 lines) — Tools and weapons (folder: items), hand-built from the kit, many models in one run.
- tools/asset_forge/builds/items_tools.py:21 hm
- tools/asset_forge/builds/items_tools.py:25 fr
- tools/asset_forge/builds/items_tools.py:45 stoneify
- tools/asset_forge/builds/items_tools.py:53 handle
- tools/asset_forge/builds/items_tools.py:68 cross_lash
- tools/asset_forge/builds/items_tools.py:80 pickaxe
- tools/asset_forge/builds/items_tools.py:96 axe
- tools/asset_forge/builds/items_tools.py:112 great_axe
- tools/asset_forge/builds/items_tools.py:130 sword
- tools/asset_forge/builds/items_tools.py:164 mace
- tools/asset_forge/builds/items_tools.py:183 great_maul
- tools/asset_forge/builds/items_tools.py:201 spear
- tools/asset_forge/builds/items_tools.py:222 build_hammer
- tools/asset_forge/builds/items_tools.py:236 masons_shovel
- tools/asset_forge/builds/items_tools.py:256 root_seed
- tools/asset_forge/builds/items_tools.py:266 crossbow
- tools/asset_forge/builds/items_tools.py:296 shield
- tools/asset_forge/builds/items_tools.py:313 shield_back
- tools/asset_forge/builds/items_tools.py:336 bolt
- tools/asset_forge/builds/items_tools.py:382 bone_fang
- tools/asset_forge/builds/items_tools.py:389 pickaxe_fang
- tools/asset_forge/builds/items_tools.py:398 shield_shell

## tools/asset_forge/builds/kaykit_miners.py (762 lines) — Lampwick Drift's creatures (dungeon 2, owner Nov 20, 2026: "download them and try to adjust them a little bit"
- tools/asset_forge/builds/kaykit_miners.py:127 paint_mat
- tools/asset_forge/builds/kaykit_miners.py:165 bone_marks
- tools/asset_forge/builds/kaykit_miners.py:222 socket_mat
- tools/asset_forge/builds/kaykit_miners.py:233 glow_mat
- tools/asset_forge/builds/kaykit_miners.py:243 classify
- tools/asset_forge/builds/kaykit_miners.py:261 uv_box
- tools/asset_forge/builds/kaykit_miners.py:282 repaint
- tools/asset_forge/builds/kaykit_miners.py:313 skin_to
- tools/asset_forge/builds/kaykit_miners.py:324 unparent_bone
- tools/asset_forge/builds/kaykit_miners.py:334 apply_mods
- tools/asset_forge/builds/kaykit_miners.py:344 reshape
- tools/asset_forge/builds/kaykit_miners.py:374 bounds
- tools/asset_forge/builds/kaykit_miners.py:379 group
- tools/asset_forge/builds/kaykit_miners.py:393 new_objs
- tools/asset_forge/builds/kaykit_miners.py:399 beard
- tools/asset_forge/builds/kaykit_miners.py:433 helmet
- tools/asset_forge/builds/kaykit_miners.py:532 crack_skull
- tools/asset_forge/builds/kaykit_miners.py:661 tool
- tools/asset_forge/builds/kaykit_miners.py:694 place
- tools/asset_forge/builds/kaykit_miners.py:700 build

## tools/asset_forge/builds/kiln.py (56 lines) — Kiln (folder: stations): a round fired-clay dome on a ring of bricks, an arched glowing mouth with coals

## tools/asset_forge/builds/kit_zone1.py (1509 lines) — Zone 1 building kit (folder: build): three styles, each its own design (docs/design/building-kit-zone1.md).
- tools/asset_forge/builds/kit_zone1.py:34 G
- tools/asset_forge/builds/kit_zone1.py:38 GS
- tools/asset_forge/builds/kit_zone1.py:42 J
- tools/asset_forge/builds/kit_zone1.py:46 T
- tools/asset_forge/builds/kit_zone1.py:50 blk
- tools/asset_forge/builds/kit_zone1.py:55 fix_normals
- tools/asset_forge/builds/kit_zone1.py:64 mesh
- tools/asset_forge/builds/kit_zone1.py:68 log
- tools/asset_forge/builds/kit_zone1.py:102 lash
- tools/asset_forge/builds/kit_zone1.py:112 peg
- tools/asset_forge/builds/kit_zone1.py:116 strap
- tools/asset_forge/builds/kit_zone1.py:129 layout
- tools/asset_forge/builds/kit_zone1.py:183 round_hole
- tools/asset_forge/builds/kit_zone1.py:203 rect_hole
- tools/asset_forge/builds/kit_zone1.py:211 slope_limit
- tools/asset_forge/builds/kit_zone1.py:220 slope_clip
- tools/asset_forge/builds/kit_zone1.py:225 Frame
- tools/asset_forge/builds/kit_zone1.py:238 masonry
- tools/asset_forge/builds/kit_zone1.py:278 slab_poly
- tools/asset_forge/builds/kit_zone1.py:286 clip_poly
- tools/asset_forge/builds/kit_zone1.py:305 needs_clip
- tools/asset_forge/builds/kit_zone1.py:309 area
- tools/asset_forge/builds/kit_zone1.py:313 floor_poly
- tools/asset_forge/builds/kit_zone1.py:321 tri_planes
- tools/asset_forge/builds/kit_zone1.py:336 plank_shape
- tools/asset_forge/builds/kit_zone1.py:343 planks_v
- tools/asset_forge/builds/kit_zone1.py:373 stone_tone
- tools/asset_forge/builds/kit_zone1.py:378 brick_tone
- tools/asset_forge/builds/kit_zone1.py:383 LIME
- tools/asset_forge/builds/kit_zone1.py:388 mortar_m
- tools/asset_forge/builds/kit_zone1.py:392 wood_dark
- tools/asset_forge/builds/kit_zone1.py:397 wall_body
- tools/asset_forge/builds/kit_zone1.py:444 shack_frame
- tools/asset_forge/builds/kit_zone1.py:469 wall
- tools/asset_forge/builds/kit_zone1.py:477 cap_row
- tools/asset_forge/builds/kit_zone1.py:483 half_wall
- tools/asset_forge/builds/kit_zone1.py:487 sloped_wall
- tools/asset_forge/builds/kit_zone1.py:495 coping
- tools/asset_forge/builds/kit_zone1.py:513 arch_ring
- tools/asset_forge/builds/kit_zone1.py:526 doorway
- tools/asset_forge/builds/kit_zone1.py:546 arch_backing
- tools/asset_forge/builds/kit_zone1.py:560 voussoirs
- tools/asset_forge/builds/kit_zone1.py:578 window_wall
- tools/asset_forge/builds/kit_zone1.py:629 leaded
- tools/asset_forge/builds/kit_zone1.py:665 door
- tools/asset_forge/builds/kit_zone1.py:706 tri_pts
- tools/asset_forge/builds/kit_zone1.py:710 tri_half
- tools/asset_forge/builds/kit_zone1.py:715 in_tri
- tools/asset_forge/builds/kit_zone1.py:730 tri_edges
- tools/asset_forge/builds/kit_zone1.py:742 edge_planes
- tools/asset_forge/builds/kit_zone1.py:749 tile_piece
- tools/asset_forge/builds/kit_zone1.py:760 deck
- tools/asset_forge/builds/kit_zone1.py:807 mesh_tri_slab
- tools/asset_forge/builds/kit_zone1.py:814 joists
- tools/asset_forge/builds/kit_zone1.py:833 floor
- tools/asset_forge/builds/kit_zone1.py:842 floor_triangle
- tools/asset_forge/builds/kit_zone1.py:853 shack_legs
- tools/asset_forge/builds/kit_zone1.py:864 foundation
- tools/asset_forge/builds/kit_zone1.py:888 foundation_side
- tools/asset_forge/builds/kit_zone1.py:908 ring_band
- tools/asset_forge/builds/kit_zone1.py:925 cap_top
- tools/asset_forge/builds/kit_zone1.py:953 foundation_triangle
- tools/asset_forge/builds/kit_zone1.py:993 stairs
- tools/asset_forge/builds/kit_zone1.py:1026 pillar
- tools/asset_forge/builds/kit_zone1.py:1057 beam
- tools/asset_forge/builds/kit_zone1.py:1074 railing
- tools/asset_forge/builds/kit_zone1.py:1119 Slope
- tools/asset_forge/builds/kit_zone1.py:1170 half_tube
- tools/asset_forge/builds/kit_zone1.py:1202 roof_panel
- tools/asset_forge/builds/kit_zone1.py:1263 fascia
- tools/asset_forge/builds/kit_zone1.py:1272 roof
- tools/asset_forge/builds/kit_zone1.py:1278 ridge_cap
- tools/asset_forge/builds/kit_zone1.py:1297 ridge
- tools/asset_forge/builds/kit_zone1.py:1306 roof_corner
- tools/asset_forge/builds/kit_zone1.py:1351 gable
- tools/asset_forge/builds/kit_zone1.py:1377 flat_roof
- tools/asset_forge/builds/kit_zone1.py:1385 battlement
- tools/asset_forge/builds/kit_zone1.py:1397 battlement_corner
- tools/asset_forge/builds/kit_zone1.py:1449 fit_check
- tools/asset_forge/builds/kit_zone1.py:1477 all_keys

## tools/asset_forge/builds/masonry_table.py (29 lines) — Masonry Table (folder: stations): a heavy stone-topped table with a cut block, chisel, mallet and rubble.

## tools/asset_forge/builds/monster_cave_bat.py (786 lines) — Cave Bat, rebuilt the Rock Beetle way (Claude, Nov 18, 2026; docs/art/CREATURE-RECIPE.md).
- tools/asset_forge/builds/monster_cave_bat.py:66 mat
- tools/asset_forge/builds/monster_cave_bat.py:78 _recalc
- tools/asset_forge/builds/monster_cave_bat.py:86 mesh_obj
- tools/asset_forge/builds/monster_cave_bat.py:99 ell
- tools/asset_forge/builds/monster_cave_bat.py:112 tube
- tools/asset_forge/builds/monster_cave_bat.py:140 claw
- tools/asset_forge/builds/monster_cave_bat.py:154 on_ball
- tools/asset_forge/builds/monster_cave_bat.py:161 in_face
- tools/asset_forge/builds/monster_cave_bat.py:420 W
- tools/asset_forge/builds/monster_cave_bat.py:431 wing_normal
- tools/asset_forge/builds/monster_cave_bat.py:436 bone
- tools/asset_forge/builds/monster_cave_bat.py:451 bez
- tools/asset_forge/builds/monster_cave_bat.py:461 membrane
- tools/asset_forge/builds/monster_cave_bat.py:493 poly
- tools/asset_forge/builds/monster_cave_bat.py:501 bez_part
- tools/asset_forge/builds/monster_cave_bat.py:510 tag
- tools/asset_forge/builds/monster_cave_bat.py:527 _on_skin
- tools/asset_forge/builds/monster_cave_bat.py:542 wing_glow
- tools/asset_forge/builds/monster_cave_bat.py:642 join_objs
- tools/asset_forge/builds/monster_cave_bat.py:668 paint
- tools/asset_forge/builds/monster_cave_bat.py:721 part
- tools/asset_forge/builds/monster_cave_bat.py:735 section

## tools/asset_forge/builds/monster_cave_spider.py (116 lines) — Cave Spider, a small Zone 1 pest (owner, Nov 19, 2026: "the spider is a Zone 1 pest"; decisions in
- tools/asset_forge/builds/monster_cave_spider.py:27 build

## tools/asset_forge/builds/monster_rock_beetle.py (827 lines) — Rock Beetle, hand-built to match the owner's approved pictures (Claude 3; MODEL-RULES Rule 1: hand-built only)
- tools/asset_forge/builds/monster_rock_beetle.py:69 rim_z
- tools/asset_forge/builds/monster_rock_beetle.py:80 _sp
- tools/asset_forge/builds/monster_rock_beetle.py:84 surf
- tools/asset_forge/builds/monster_rock_beetle.py:93 dir_of
- tools/asset_forge/builds/monster_rock_beetle.py:97 dir_xy
- tools/asset_forge/builds/monster_rock_beetle.py:104 dir_back
- tools/asset_forge/builds/monster_rock_beetle.py:111 dir_side
- tools/asset_forge/builds/monster_rock_beetle.py:123 amber_at
- tools/asset_forge/builds/monster_rock_beetle.py:151 _jitter
- tools/asset_forge/builds/monster_rock_beetle.py:164 frame
- tools/asset_forge/builds/monster_rock_beetle.py:172 hull2d
- tools/asset_forge/builds/monster_rock_beetle.py:191 simplify
- tools/asset_forge/builds/monster_rock_beetle.py:205 plate
- tools/asset_forge/builds/monster_rock_beetle.py:282 in_plate_area
- tools/asset_forge/builds/monster_rock_beetle.py:287 corner_indices
- tools/asset_forge/builds/monster_rock_beetle.py:317 boundary_loop
- tools/asset_forge/builds/monster_rock_beetle.py:337 cushion_plates
- tools/asset_forge/builds/monster_rock_beetle.py:477 amber_point
- tools/asset_forge/builds/monster_rock_beetle.py:518 belly_at
- tools/asset_forge/builds/monster_rock_beetle.py:548 mandible
- tools/asset_forge/builds/monster_rock_beetle.py:682 mushroom
- tools/asset_forge/builds/monster_rock_beetle.py:693 crystal_cluster
- tools/asset_forge/builds/monster_rock_beetle.py:705 on_shell
- tools/asset_forge/builds/monster_rock_beetle.py:756 barrel
- tools/asset_forge/builds/monster_rock_beetle.py:781 talon
- tools/asset_forge/builds/monster_rock_beetle.py:790 leg

## tools/asset_forge/builds/monster_rock_snail.py (649 lines) — Rock Snail, rebuilt the Rock Beetle way (Claude, Nov 17, 2026; docs/art/CREATURE-RECIPE.md, F68/F31).
- tools/asset_forge/builds/monster_rock_snail.py:60 mat
- tools/asset_forge/builds/monster_rock_snail.py:72 mesh_obj
- tools/asset_forge/builds/monster_rock_snail.py:82 ell
- tools/asset_forge/builds/monster_rock_snail.py:95 tube
- tools/asset_forge/builds/monster_rock_snail.py:120 _recalc
- tools/asset_forge/builds/monster_rock_snail.py:128 apply_scale
- tools/asset_forge/builds/monster_rock_snail.py:147 spow
- tools/asset_forge/builds/monster_rock_snail.py:151 egg
- tools/asset_forge/builds/monster_rock_snail.py:171 seam
- tools/asset_forge/builds/monster_rock_snail.py:198 stone_of
- tools/asset_forge/builds/monster_rock_snail.py:269 crystal
- tools/asset_forge/builds/monster_rock_snail.py:294 shell_top
- tools/asset_forge/builds/monster_rock_snail.py:359 catmull
- tools/asset_forge/builds/monster_rock_snail.py:581 join
- tools/asset_forge/builds/monster_rock_snail.py:599 split_stalk

## tools/asset_forge/builds/night_decor.py (897 lines) — Decor remade from the night pictures decor_* (furniture per building style, lights, storage, mine props,
- tools/asset_forge/builds/night_decor.py:22 legs4
- tools/asset_forge/builds/night_decor.py:31 plank_top
- tools/asset_forge/builds/night_decor.py:39 rope_tie
- tools/asset_forge/builds/night_decor.py:47 blanket
- tools/asset_forge/builds/night_decor.py:53 cushion
- tools/asset_forge/builds/night_decor.py:58 stone_blocks
- tools/asset_forge/builds/night_decor.py:73 rug_mesh
- tools/asset_forge/builds/night_decor.py:91 shack_bed
- tools/asset_forge/builds/night_decor.py:105 shack_table
- tools/asset_forge/builds/night_decor.py:119 shack_stool
- tools/asset_forge/builds/night_decor.py:127 shack_bench
- tools/asset_forge/builds/night_decor.py:136 shack_shelf
- tools/asset_forge/builds/night_decor.py:149 shack_nightstand
- tools/asset_forge/builds/night_decor.py:159 shack_peg_rack
- tools/asset_forge/builds/night_decor.py:169 shack_rug
- tools/asset_forge/builds/night_decor.py:174 stone_bed
- tools/asset_forge/builds/night_decor.py:186 stone_table
- tools/asset_forge/builds/night_decor.py:197 stone_stool
- tools/asset_forge/builds/night_decor.py:207 stone_throne
- tools/asset_forge/builds/night_decor.py:220 stone_wall_shelf
- tools/asset_forge/builds/night_decor.py:230 stone_weapon_plaque
- tools/asset_forge/builds/night_decor.py:243 stone_chest
- tools/asset_forge/builds/night_decor.py:252 stone_rug
- tools/asset_forge/builds/night_decor.py:257 brick_box
- tools/asset_forge/builds/night_decor.py:274 hearth_bed
- tools/asset_forge/builds/night_decor.py:291 hearth_table
- tools/asset_forge/builds/night_decor.py:303 hearth_chair
- tools/asset_forge/builds/night_decor.py:314 hearth_fireplace
- tools/asset_forge/builds/night_decor.py:335 hearth_dresser
- tools/asset_forge/builds/night_decor.py:349 hearth_planter
- tools/asset_forge/builds/night_decor.py:358 hearth_pot_rack
- tools/asset_forge/builds/night_decor.py:378 hearth_rug
- tools/asset_forge/builds/night_decor.py:383 hanging_lantern
- tools/asset_forge/builds/night_decor.py:392 lantern_body
- tools/asset_forge/builds/night_decor.py:403 brazier
- tools/asset_forge/builds/night_decor.py:413 candle_cluster
- tools/asset_forge/builds/night_decor.py:421 chandelier
- tools/asset_forge/builds/night_decor.py:437 crystal_lamp_post
- tools/asset_forge/builds/night_decor.py:450 wall_torch
- tools/asset_forge/builds/night_decor.py:461 firefly_jar
- tools/asset_forge/builds/night_decor.py:470 stone_lantern
- tools/asset_forge/builds/night_decor.py:483 crate
- tools/asset_forge/builds/night_decor.py:495 crate_stack
- tools/asset_forge/builds/night_decor.py:500 grain_sacks
- tools/asset_forge/builds/night_decor.py:510 cheese_shelf
- tools/asset_forge/builds/night_decor.py:524 keg
- tools/asset_forge/builds/night_decor.py:537 hanging_herbs
- tools/asset_forge/builds/night_decor.py:550 ore_basket
- tools/asset_forge/builds/night_decor.py:559 firewood_rack
- tools/asset_forge/builds/night_decor.py:571 tavern_table
- tools/asset_forge/builds/night_decor.py:586 mine_cart
- tools/asset_forge/builds/night_decor.py:602 rail_track
- tools/asset_forge/builds/night_decor.py:610 signpost
- tools/asset_forge/builds/night_decor.py:618 timber_stack
- tools/asset_forge/builds/night_decor.py:627 rope_fence
- tools/asset_forge/builds/night_decor.py:639 plank_board
- tools/asset_forge/builds/night_decor.py:652 wall_post
- tools/asset_forge/builds/night_decor.py:658 banner
- tools/asset_forge/builds/night_decor.py:667 banner_anvil
- tools/asset_forge/builds/night_decor.py:674 banner_landscape
- tools/asset_forge/builds/night_decor.py:682 horn_plaque
- tools/asset_forge/builds/night_decor.py:689 fossil_plaque
- tools/asset_forge/builds/night_decor.py:700 crossed_pickaxes
- tools/asset_forge/builds/night_decor.py:709 bat_trophy
- tools/asset_forge/builds/night_decor.py:721 rune_shield
- tools/asset_forge/builds/night_decor.py:731 map_board
- tools/asset_forge/builds/night_decor.py:743 mushroom_planter
- tools/asset_forge/builds/night_decor.py:752 potted_fungus
- tools/asset_forge/builds/night_decor.py:760 hanging_basket
- tools/asset_forge/builds/night_decor.py:776 stepping_stones
- tools/asset_forge/builds/night_decor.py:785 mushroom_fountain
- tools/asset_forge/builds/night_decor.py:798 mushroom_stool
- tools/asset_forge/builds/night_decor.py:807 glow_trellis
- tools/asset_forge/builds/night_decor.py:822 mossy_bench
- tools/asset_forge/builds/night_decor.py:834 beam
- tools/asset_forge/builds/night_decor.py:846 pole
- tools/asset_forge/builds/night_decor.py:851 brace_corner

## tools/asset_forge/builds/night_fixes.py (408 lines) — Stations remade from the night "fix" pictures (FEEDBACK F34-F65), one object per picture.
- tools/asset_forge/builds/night_fixes.py:15 _pear
- tools/asset_forge/builds/night_fixes.py:27 bellows
- tools/asset_forge/builds/night_fixes.py:52 campfire
- tools/asset_forge/builds/night_fixes.py:66 carpenters_vise
- tools/asset_forge/builds/night_fixes.py:105 tanning_rack
- tools/asset_forge/builds/night_fixes.py:146 chest_small
- tools/asset_forge/builds/night_fixes.py:177 chopping_block
- tools/asset_forge/builds/night_fixes.py:204 _chain
- tools/asset_forge/builds/night_fixes.py:217 cooking_pot
- tools/asset_forge/builds/night_fixes.py:260 grindstone
- tools/asset_forge/builds/night_fixes.py:279 stone_saw
- tools/asset_forge/builds/night_fixes.py:308 tool_rack
- tools/asset_forge/builds/night_fixes.py:340 training_dummy

## tools/asset_forge/builds/night_materials.py (389 lines) — Material items remade from the night pictures materials_1..4 (F56), one object per picture cell.
- tools/asset_forge/builds/night_materials.py:18 C
- tools/asset_forge/builds/night_materials.py:36 lump
- tools/asset_forge/builds/night_materials.py:45 sphere
- tools/asset_forge/builds/night_materials.py:57 rootwood
- tools/asset_forge/builds/night_materials.py:67 plank_root
- tools/asset_forge/builds/night_materials.py:74 mushroom_wood
- tools/asset_forge/builds/night_materials.py:83 plank_mushroom
- tools/asset_forge/builds/night_materials.py:90 rope
- tools/asset_forge/builds/night_materials.py:96 leather
- tools/asset_forge/builds/night_materials.py:105 ingot
- tools/asset_forge/builds/night_materials.py:110 clay_brick
- tools/asset_forge/builds/night_materials.py:115 block
- tools/asset_forge/builds/night_materials.py:120 lantern_lens
- tools/asset_forge/builds/night_materials.py:130 rock
- tools/asset_forge/builds/night_materials.py:140 clay
- tools/asset_forge/builds/night_materials.py:147 coal
- tools/asset_forge/builds/night_materials.py:156 fiber
- tools/asset_forge/builds/night_materials.py:165 moss
- tools/asset_forge/builds/night_materials.py:173 dirt
- tools/asset_forge/builds/night_materials.py:181 amberrock
- tools/asset_forge/builds/night_materials.py:186 rusty_scrap
- tools/asset_forge/builds/night_materials.py:199 critter_hide
- tools/asset_forge/builds/night_materials.py:208 chitin_plate
- tools/asset_forge/builds/night_materials.py:217 shell_piece
- tools/asset_forge/builds/night_materials.py:228 wing
- tools/asset_forge/builds/night_materials.py:239 bat_fang
- tools/asset_forge/builds/night_materials.py:248 needle
- tools/asset_forge/builds/night_materials.py:253 glow_gland
- tools/asset_forge/builds/night_materials.py:262 spitter_gill
- tools/asset_forge/builds/night_materials.py:270 ironshell_plate
- tools/asset_forge/builds/night_materials.py:279 sivix_silk
- tools/asset_forge/builds/night_materials.py:285 spore_powder
- tools/asset_forge/builds/night_materials.py:294 venom_sac
- tools/asset_forge/builds/night_materials.py:305 crystal_on_rock
- tools/asset_forge/builds/night_materials.py:316 slime
- tools/asset_forge/builds/night_materials.py:323 root_tuber
- tools/asset_forge/builds/night_materials.py:334 shroom

## tools/asset_forge/builds/night_stations.py (501 lines) — Stations rebuilt from the night pictures (assets/concepts/night-2026-11-15/), one object per picture,
- tools/asset_forge/builds/night_stations.py:23 J
- tools/asset_forge/builds/night_stations.py:27 T
- tools/asset_forge/builds/night_stations.py:31 B
- tools/asset_forge/builds/night_stations.py:35 _fix
- tools/asset_forge/builds/night_stations.py:44 mesh
- tools/asset_forge/builds/night_stations.py:48 log
- tools/asset_forge/builds/night_stations.py:84 stone
- tools/asset_forge/builds/night_stations.py:89 stone_tone
- tools/asset_forge/builds/night_stations.py:94 rivet
- tools/asset_forge/builds/night_stations.py:98 cband
- tools/asset_forge/builds/night_stations.py:111 plank
- tools/asset_forge/builds/night_stations.py:115 ring_of
- tools/asset_forge/builds/night_stations.py:121 ember_bed
- tools/asset_forge/builds/night_stations.py:129 disc
- tools/asset_forge/builds/night_stations.py:138 water_disc
- tools/asset_forge/builds/night_stations.py:145 stream
- tools/asset_forge/builds/night_stations.py:151 twin_smelter
- tools/asset_forge/builds/night_stations.py:202 furnace_dome
- tools/asset_forge/builds/night_stations.py:240 crucible
- tools/asset_forge/builds/night_stations.py:247 gem_bench
- tools/asset_forge/builds/night_stations.py:322 gem_mat
- tools/asset_forge/builds/night_stations.py:333 mesh_cloth
- tools/asset_forge/builds/night_stations.py:359 drip_bucket
- tools/asset_forge/builds/night_stations.py:386 copper_drip_basin
- tools/asset_forge/builds/night_stations.py:430 crystal_sconce
- tools/asset_forge/builds/night_stations.py:458 glow_marker

## tools/asset_forge/builds/rope_ladder.py (26 lines) — Rope Ladder (folder: stations): two twisted ropes tied round a top bar, wooden rungs lashed to the ropes.

## tools/asset_forge/builds/rune_slab.py (56 lines) — Rune Slab (folder: stations): a tall standing stone on a stepped plinth with a carved border, a glowing rune c
- tools/asset_forge/builds/rune_slab.py:24 groove

## tools/asset_forge/builds/shack_v2.py (1479 lines) — Delver's Shack, version 2 (owner, Nov 15): the first 4 pieces rebuilt to match the turnaround sheet
- tools/asset_forge/builds/shack_v2.py:28 bolt
- tools/asset_forge/builds/shack_v2.py:37 xrope
- tools/asset_forge/builds/shack_v2.py:54 post
- tools/asset_forge/builds/shack_v2.py:59 planks
- tools/asset_forge/builds/shack_v2.py:86 wall_frame
- tools/asset_forge/builds/shack_v2.py:102 wall
- tools/asset_forge/builds/shack_v2.py:110 circle_cut
- tools/asset_forge/builds/shack_v2.py:117 doorway
- tools/asset_forge/builds/shack_v2.py:156 door
- tools/asset_forge/builds/shack_v2.py:185 foundation
- tools/asset_forge/builds/shack_v2.py:215 roof
- tools/asset_forge/builds/shack_v2.py:250 _flat
- tools/asset_forge/builds/shack_v2.py:256 facet_log
- tools/asset_forge/builds/shack_v2.py:291 boulder
- tools/asset_forge/builds/shack_v2.py:306 rough_board
- tools/asset_forge/builds/shack_v2.py:346 real_log
- tools/asset_forge/builds/shack_v2.py:406 peg
- tools/asset_forge/builds/shack_v2.py:419 foundation_v3
- tools/asset_forge/builds/shack_v2.py:472 rough_ring
- tools/asset_forge/builds/shack_v2.py:498 rough_vboard
- tools/asset_forge/builds/shack_v2.py:537 hewn
- tools/asset_forge/builds/shack_v2.py:541 pegs_on
- tools/asset_forge/builds/shack_v2.py:545 wall_v3
- tools/asset_forge/builds/shack_v2.py:567 doorway_v3
- tools/asset_forge/builds/shack_v2.py:618 door_v3
- tools/asset_forge/builds/shack_v2.py:659 window_wall_v3
- tools/asset_forge/builds/shack_v2.py:718 _inside
- tools/asset_forge/builds/shack_v2.py:722 shingle_slope
- tools/asset_forge/builds/shack_v2.py:773 roof_v3
- tools/asset_forge/builds/shack_v2.py:782 roof_corner_v3
- tools/asset_forge/builds/shack_v2.py:817 ridge_v3
- tools/asset_forge/builds/shack_v2.py:836 gable_v3
- tools/asset_forge/builds/shack_v2.py:880 board_x
- tools/asset_forge/builds/shack_v2.py:890 side_board
- tools/asset_forge/builds/shack_v2.py:899 stairs_v3
- tools/asset_forge/builds/shack_v2.py:929 ramp_v3
- tools/asset_forge/builds/shack_v2.py:975 ladder_v3
- tools/asset_forge/builds/shack_v2.py:988 railing_v3
- tools/asset_forge/builds/shack_v2.py:1005 beam_v3
- tools/asset_forge/builds/shack_v2.py:1012 pillar_v3
- tools/asset_forge/builds/shack_v2.py:1020 brace_v3
- tools/asset_forge/builds/shack_v2.py:1031 mine_prop_v3
- tools/asset_forge/builds/shack_v2.py:1054 deck_boards
- tools/asset_forge/builds/shack_v2.py:1085 rim_beams
- tools/asset_forge/builds/shack_v2.py:1105 floor_v3
- tools/asset_forge/builds/shack_v2.py:1115 floor_triangle_v3
- tools/asset_forge/builds/shack_v2.py:1129 _hewn_style
- tools/asset_forge/builds/shack_v2.py:1138 foundation_triangle_v3
- tools/asset_forge/builds/shack_v2.py:1166 wall_any_v3
- tools/asset_forge/builds/shack_v2.py:1193 foundation_leg_v3
- tools/asset_forge/builds/shack_v2.py:1199 foundation_foot_v3
- tools/asset_forge/builds/shack_v2.py:1209 fit_uv
- tools/asset_forge/builds/shack_v2.py:1242 paint
- tools/asset_forge/builds/shack_v2.py:1264 _uvs
- tools/asset_forge/builds/shack_v2.py:1271 paint3
- tools/asset_forge/builds/shack_v2.py:1394 _hewn
- tools/asset_forge/builds/shack_v2.py:1401 _mix
- tools/asset_forge/builds/shack_v2.py:1439 make_grey

## tools/asset_forge/builds/smelter.py (17 lines) — Smelter (folder: stations): a stone dome with a copper-banded chimney, flames and a glowing crucible in its mo

## tools/asset_forge/builds/stone_saw.py (31 lines) — Stone Saw (folder: stations): two wooden A-frames holding a big round iron saw blade on an axle, with a crank.

## tools/asset_forge/builds/stonehold_v2.py (1184 lines) — Stonehold, version 2 (owner, Nov 17): set 1 rebuilt to match the turnaround sheet
- tools/asset_forge/builds/stonehold_v2.py:34 stone_m
- tools/asset_forge/builds/stonehold_v2.py:38 mortar_m
- tools/asset_forge/builds/stonehold_v2.py:42 timber_m
- tools/asset_forge/builds/stonehold_v2.py:46 copper_m
- tools/asset_forge/builds/stonehold_v2.py:50 _tag
- tools/asset_forge/builds/stonehold_v2.py:56 _new_since
- tools/asset_forge/builds/stonehold_v2.py:60 chisel
- tools/asset_forge/builds/stonehold_v2.py:95 block
- tools/asset_forge/builds/stonehold_v2.py:104 _inset
- tools/asset_forge/builds/stonehold_v2.py:127 prism
- tools/asset_forge/builds/stonehold_v2.py:153 backing
- tools/asset_forge/builds/stonehold_v2.py:176 rivet
- tools/asset_forge/builds/stonehold_v2.py:180 copper_band
- tools/asset_forge/builds/stonehold_v2.py:197 _cut_by_circle
- tools/asset_forge/builds/stonehold_v2.py:255 courses
- tools/asset_forge/builds/stonehold_v2.py:318 wall
- tools/asset_forge/builds/stonehold_v2.py:322 ring_stones
- tools/asset_forge/builds/stonehold_v2.py:357 doorway
- tools/asset_forge/builds/stonehold_v2.py:371 half_wall
- tools/asset_forge/builds/stonehold_v2.py:375 wall_narrow
- tools/asset_forge/builds/stonehold_v2.py:379 iron_m
- tools/asset_forge/builds/stonehold_v2.py:383 window_wall
- tools/asset_forge/builds/stonehold_v2.py:416 window_wide
- tools/asset_forge/builds/stonehold_v2.py:420 pillar
- tools/asset_forge/builds/stonehold_v2.py:446 beam
- tools/asset_forge/builds/stonehold_v2.py:464 beam_half
- tools/asset_forge/builds/stonehold_v2.py:468 door
- tools/asset_forge/builds/stonehold_v2.py:499 flagstones
- tools/asset_forge/builds/stonehold_v2.py:527 foundation
- tools/asset_forge/builds/stonehold_v2.py:568 stairs
- tools/asset_forge/builds/stonehold_v2.py:580 foundation_steps
- tools/asset_forge/builds/stonehold_v2.py:584 ramp
- tools/asset_forge/builds/stonehold_v2.py:613 baluster
- tools/asset_forge/builds/stonehold_v2.py:644 railing
- tools/asset_forge/builds/stonehold_v2.py:661 floor
- tools/asset_forge/builds/stonehold_v2.py:666 floor_half
- tools/asset_forge/builds/stonehold_v2.py:670 small_floor
- tools/asset_forge/builds/stonehold_v2.py:674 ceiling_panel
- tools/asset_forge/builds/stonehold_v2.py:678 _tri_flagstones
- tools/asset_forge/builds/stonehold_v2.py:717 floor_triangle
- tools/asset_forge/builds/stonehold_v2.py:733 foundation_half
- tools/asset_forge/builds/stonehold_v2.py:737 foundation_triangle
- tools/asset_forge/builds/stonehold_v2.py:765 sloped_wall
- tools/asset_forge/builds/stonehold_v2.py:777 slab_xz
- tools/asset_forge/builds/stonehold_v2.py:796 floor_rim
- tools/asset_forge/builds/stonehold_v2.py:817 flat_roof
- tools/asset_forge/builds/stonehold_v2.py:832 battlement
- tools/asset_forge/builds/stonehold_v2.py:862 door_broken
- tools/asset_forge/builds/stonehold_v2.py:924 ruin_wall_worn
- tools/asset_forge/builds/stonehold_v2.py:934 ruin_wall_collapsed
- tools/asset_forge/builds/stonehold_v2.py:949 ruin_rubble
- tools/asset_forge/builds/stonehold_v2.py:972 gateway
- tools/asset_forge/builds/stonehold_v2.py:985 gate_leaf
- tools/asset_forge/builds/stonehold_v2.py:1018 gate_broken
- tools/asset_forge/builds/stonehold_v2.py:1035 _straw_m
- tools/asset_forge/builds/stonehold_v2.py:1039 straw_dummy
- tools/asset_forge/builds/stonehold_v2.py:1059 archery_target
- tools/asset_forge/builds/stonehold_v2.py:1083 spear_rack
- tools/asset_forge/builds/stonehold_v2.py:1101 boulder
- tools/asset_forge/builds/stonehold_v2.py:1126 paint
- tools/asset_forge/builds/stonehold_v2.py:1149 make_grey

## tools/asset_forge/builds/stonehold_v2_frame.py (106 lines) — Stonehold, version 2: the brace and the ladder (owner, Nov 20: Stonehold gets the same frame pieces as the Sha
- tools/asset_forge/builds/stonehold_v2_frame.py:23 tagged
- tools/asset_forge/builds/stonehold_v2_frame.py:31 iron_rivet
- tools/asset_forge/builds/stonehold_v2_frame.py:35 brace
- tools/asset_forge/builds/stonehold_v2_frame.py:61 ladder

## tools/asset_forge/builds/stonehold_v2_spire.py (320 lines) — The Lantern Spire (owner, Nov 20: ruin 4 of Zone 1, a tall thin round Stonehold beacon tower): its fire bowl, 
- tools/asset_forge/builds/stonehold_v2_spire.py:34 meshes
- tools/asset_forge/builds/stonehold_v2_spire.py:38 since
- tools/asset_forge/builds/stonehold_v2_spire.py:42 bake
- tools/asset_forge/builds/stonehold_v2_spire.py:53 at
- tools/asset_forge/builds/stonehold_v2_spire.py:58 piece
- tools/asset_forge/builds/stonehold_v2_spire.py:67 ring_dir
- tools/asset_forge/builds/stonehold_v2_spire.py:72 godot
- tools/asset_forge/builds/stonehold_v2_spire.py:76 centre
- tools/asset_forge/builds/stonehold_v2_spire.py:81 settle
- tools/asset_forge/builds/stonehold_v2_spire.py:91 _bowl
- tools/asset_forge/builds/stonehold_v2_spire.py:119 _plinth_and_pedestal
- tools/asset_forge/builds/stonehold_v2_spire.py:144 beacon_bowl
- tools/asset_forge/builds/stonehold_v2_spire.py:153 beacon_bowl_fallen
- tools/asset_forge/builds/stonehold_v2_spire.py:185 lie
- tools/asset_forge/builds/stonehold_v2_spire.py:190 hrel
- tools/asset_forge/builds/stonehold_v2_spire.py:195 broken_wall
- tools/asset_forge/builds/stonehold_v2_spire.py:213 keep_below
- tools/asset_forge/builds/stonehold_v2_spire.py:228 spire_top_fallen
- tools/asset_forge/builds/stonehold_v2_spire.py:279 spire_wall_chunk

## tools/asset_forge/builds/stonehold_v2_twin.py (243 lines) — The Twin Gate (owner, Nov 21: ruin 6 of Zone 1, the first showpiece, docs/design/GRAND-RUIN-RECIPE.md): the ne
- tools/asset_forge/builds/stonehold_v2_twin.py:37 meshes
- tools/asset_forge/builds/stonehold_v2_twin.py:41 side
- tools/asset_forge/builds/stonehold_v2_twin.py:47 clip_y
- tools/asset_forge/builds/stonehold_v2_twin.py:66 corbel
- tools/asset_forge/builds/stonehold_v2_twin.py:82 cornice
- tools/asset_forge/builds/stonehold_v2_twin.py:96 cornice_corner
- tools/asset_forge/builds/stonehold_v2_twin.py:107 buttress
- tools/asset_forge/builds/stonehold_v2_twin.py:131 tear
- tools/asset_forge/builds/stonehold_v2_twin.py:142 ring_stones
- tools/asset_forge/builds/stonehold_v2_twin.py:176 bartizan

## tools/asset_forge/builds/tanning_rack.py (37 lines) — Tanning Rack (folder: stations): a log frame with a hide stretched by ropes tied to its legs and edges, on sto

## tools/asset_forge/builds/tool_rack.py (37 lines) — Tool Rack (folder: stations): a standing plank board on feet with pegs holding a hammer, a saw and tongs.

## tools/asset_forge/builds/training_dummy.py (42 lines) — Training Dummy (folder: stations): stacked stones on a post bound by rope bands that hug the stones, log arms 
- tools/asset_forge/builds/training_dummy.py:22 band

## tools/asset_forge/builds/treasure.py (154 lines) — Treasure and table things for the ruins (owner, Nov 19, 2026: batch 4 in docs/research/asset-picks-placement.m
- tools/asset_forge/builds/treasure.py:64 _chest_import
- tools/asset_forge/builds/treasure.py:93 _chest_save

## tools/asset_forge/builds/twin_smelter.py (25 lines) — Twin Smelter (folder: stations): left a charcoal kiln (log pile beside it, iron-banded chimney), right an ore 

## tools/asset_forge/builds/workbench.py (69 lines) — Workbench (folder: stations), hand-built from the owner's ChatGPT concept: one thick mossy stone slab

## tools/asset_forge/creature_closeup.py (43 lines) — Close-up photos of one part of a creature (face, feet, glowing back) from any angle (by Claude 3).

## tools/asset_forge/creature_compare.py (77 lines) — Side-by-side check: the approved picture next to the hand-built model, seen from the same angle (by Claude 3).

## tools/asset_forge/creature_fit.py (152 lines) — Outline check for a creature against its turnaround sheet (by Claude 3).
- tools/asset_forge/creature_fit.py:54 model_extent
- tools/asset_forge/creature_fit.py:61 render_mask
- tools/asset_forge/creature_fit.py:88 save_png
- tools/asset_forge/creature_fit.py:143 stack

## tools/asset_forge/creature_forge.py (571 lines) — Turns a forged creature (one solid statue from forge.py) into a game creature (by Claude 3).
- tools/asset_forge/creature_forge.py:36 log
- tools/asset_forge/creature_forge.py:87 basis
- tools/asset_forge/creature_forge.py:100 screen
- tools/asset_forge/creature_forge.py:119 score
- tools/asset_forge/creature_forge.py:209 project
- tools/asset_forge/creature_forge.py:327 add_part

## tools/asset_forge/creature_kit.py (334 lines) — Creature add-on for the hand-built model kit (kit.py, by Claude 2). By Claude 3.
- tools/asset_forge/creature_kit.py:31 reset
- tools/asset_forge/creature_kit.py:39 part
- tools/asset_forge/creature_kit.py:48 color
- tools/asset_forge/creature_kit.py:57 skin
- tools/asset_forge/creature_kit.py:76 eye_mat
- tools/asset_forge/creature_kit.py:88 _frame
- tools/asset_forge/creature_kit.py:97 loft
- tools/asset_forge/creature_kit.py:135 _fix_normals
- tools/asset_forge/creature_kit.py:143 path_rings
- tools/asset_forge/creature_kit.py:149 bezier
- tools/asset_forge/creature_kit.py:163 limb
- tools/asset_forge/creature_kit.py:177 blob
- tools/asset_forge/creature_kit.py:196 membrane
- tools/asset_forge/creature_kit.py:219 wrap_sheet
- tools/asset_forge/creature_kit.py:252 save
- tools/asset_forge/creature_kit.py:306 _previews

## tools/asset_forge/creature_sculpt.py (710 lines) — Sculpt-and-bake add-on for hand-built creatures (by Claude 3), the way game studios make creatures, all by scr
- tools/asset_forge/creature_sculpt.py:20 _select_only
- tools/asset_forge/creature_sculpt.py:26 _apply_all
- tools/asset_forge/creature_sculpt.py:32 melt
- tools/asset_forge/creature_sculpt.py:57 _displace
- tools/asset_forge/creature_sculpt.py:69 _crack
- tools/asset_forge/creature_sculpt.py:75 carve_stone
- tools/asset_forge/creature_sculpt.py:94 carve_chitin
- tools/asset_forge/creature_sculpt.py:111 detail_copy
- tools/asset_forge/creature_sculpt.py:126 uv_only
- tools/asset_forge/creature_sculpt.py:136 game_copy
- tools/asset_forge/creature_sculpt.py:165 _node
- tools/asset_forge/creature_sculpt.py:175 lin
- tools/asset_forge/creature_sculpt.py:180 paint_material
- tools/asset_forge/creature_sculpt.py:409 glow_paint
- tools/asset_forge/creature_sculpt.py:518 paint_eye
- tools/asset_forge/creature_sculpt.py:568 islands
- tools/asset_forge/creature_sculpt.py:592 island_kd
- tools/asset_forge/creature_sculpt.py:607 tint_islands
- tools/asset_forge/creature_sculpt.py:623 gradient_attr
- tools/asset_forge/creature_sculpt.py:635 eye_attrs
- tools/asset_forge/creature_sculpt.py:651 carve_moss
- tools/asset_forge/creature_sculpt.py:666 bake

## tools/asset_forge/creature_sources.py (51 lines) — Cuts the approved creature pictures into one picture per variant, with the background removed.
- tools/asset_forge/creature_sources.py:24 pad
- tools/asset_forge/creature_sources.py:33 main

## tools/asset_forge/creature_textures.py (169 lines) — Makes the creatures' skin textures from the kit's hand-painted ones (Claude 2's, see CREDITS.md):
- tools/asset_forge/creature_textures.py:30 make
- tools/asset_forge/creature_textures.py:45 _cells
- tools/asset_forge/creature_textures.py:56 _noise
- tools/asset_forge/creature_textures.py:65 snail_skin
- tools/asset_forge/creature_textures.py:78 knobbly_rock
- tools/asset_forge/creature_textures.py:91 beetle_wax
- tools/asset_forge/creature_textures.py:108 pebble
- tools/asset_forge/creature_textures.py:118 mossy_rock
- tools/asset_forge/creature_textures.py:128 recolor
- tools/asset_forge/creature_textures.py:143 main

## tools/asset_forge/crossbow_kaykit_bake.gd (87 lines) — Bakes the KayKit skeletons' crossbow moves (aim, shoot, reload) onto the dwarf as plain upper-body clips
- tools/asset_forge/crossbow_kaykit_bake.gd:26 _init

## tools/asset_forge/derive_tex_calm.py (19 lines) — Calm kit colours (owner F73/F74, Nov 15): recolour our own hand-painted stone texture.
- tools/asset_forge/derive_tex_calm.py:7 load
- tools/asset_forge/derive_tex_calm.py:8 tint
- tools/asset_forge/derive_tex_calm.py:12 save

## tools/asset_forge/derive_tex_hearthbrick.py (58 lines) — Cut the Hearthbrick texture sheet (ChatGPT, owner's chat "Generate Building Kit Sheet", Nov 20) into kit textu
- tools/asset_forge/derive_tex_hearthbrick.py:19 spans
- tools/asset_forge/derive_tex_hearthbrick.py:35 seamless

## tools/asset_forge/derive_tex_hearthbrick_roof.py (57 lines) — Cut the Hearthbrick ROOF TILE sheet (ChatGPT, owner's chat "Generate Building Kit Sheet", Nov 20) into kit tex
- tools/asset_forge/derive_tex_hearthbrick_roof.py:18 spans
- tools/asset_forge/derive_tex_hearthbrick_roof.py:34 seamless

## tools/asset_forge/derive_tex_shack.py (114 lines) — Cut the Delver's Shack texture sheet (ChatGPT, same chat as the Shack kit pictures) into kit textures:
- tools/asset_forge/derive_tex_shack.py:15 spans
- tools/asset_forge/derive_tex_shack.py:36 seamless
- tools/asset_forge/derive_tex_shack.py:46 seamless_v

## tools/asset_forge/dwarf_anim_export.gd (285 lines) — Records the game dwarf (hand-built body, shaped skeleton) playing its animations and writes it all to one .glb
- tools/asset_forge/dwarf_anim_export.gd:41 _look_of
- tools/asset_forge/dwarf_anim_export.gd:46 _tool_look
- tools/asset_forge/dwarf_anim_export.gd:52 _init
- tools/asset_forge/dwarf_anim_export.gd:167 _skel_in_look
- tools/asset_forge/dwarf_anim_export.gd:176 _own
- tools/asset_forge/dwarf_anim_export.gd:185 _drive
- tools/asset_forge/dwarf_anim_export.gd:201 _record

## tools/asset_forge/dwarf_clip_check.py (149 lines) — Does the dwarf's beard, hair or face go through his body while he moves? (owner, F183: "the beard clips throug
- tools/asset_forge/dwarf_clip_check.py:33 signed
- tools/asset_forge/dwarf_clip_check.py:91 hair_angle
- tools/asset_forge/dwarf_clip_check.py:97 lean

## tools/asset_forge/dwarf_gait_check.gd (73 lines) — Measures the dwarf's walk and run (Nov 19, dwarf-animations Claude): for each speed the game uses, one whole l
- tools/asset_forge/dwarf_gait_check.gd:12 _init

## tools/asset_forge/dwarf_moves_export.gd (155 lines) — Records the game dwarf moving around (standing, walking, running, a whole jump with take-off and landing) into
- tools/asset_forge/dwarf_moves_export.gd:20 _init
- tools/asset_forge/dwarf_moves_export.gd:86 _state
- tools/asset_forge/dwarf_moves_export.gd:92 _look_base
- tools/asset_forge/dwarf_moves_export.gd:96 _record
- tools/asset_forge/dwarf_moves_export.gd:143 _skel_in_look
- tools/asset_forge/dwarf_moves_export.gd:152 _own

## tools/asset_forge/dwarf_page_copy.py (205 lines) — A lighter copy of a recorded dwarf (.glb from dwarf_anim_export.gd) for the "Dwarf Body" 3D page (Claude, Nov 
- tools/asset_forge/dwarf_page_copy.py:21 read_glb
- tools/asset_forge/dwarf_page_copy.py:30 main

## tools/asset_forge/dwarf_pose_dump.gd (122 lines) — Writes the hand-built dwarf's head (face, hair, beard) and torso (shirt, shorts seat) exactly as the GAME bend
- tools/asset_forge/dwarf_pose_dump.gd:18 _init
- tools/asset_forge/dwarf_pose_dump.gd:79 _count
- tools/asset_forge/dwarf_pose_dump.gd:83 _write
- tools/asset_forge/dwarf_pose_dump.gd:89 _record

## tools/asset_forge/dwarf_skeleton_dump.gd (35 lines) — Writes the game dwarf's skeleton, shaped by DwarfProportions and standing in its rest pose, to a JSON file, so
- tools/asset_forge/dwarf_skeleton_dump.gd:10 _init

## tools/asset_forge/dwarf_turnaround_measure.py (114 lines) — Measure the approved dwarf turnaround picture (assets/concepts/dwarf/dwarf_turnaround.png: front, side, back o
- tools/asset_forge/dwarf_turnaround_measure.py:54 height_of
- tools/asset_forge/dwarf_turnaround_measure.py:59 row_of
- tools/asset_forge/dwarf_turnaround_measure.py:65 classify

## tools/asset_forge/forge.py (166 lines) — Asset forge: picture -> 3D model -> cleaned up -> in the game's assets folder.
- tools/asset_forge/forge.py:43 find_blender
- tools/asset_forge/forge.py:55 run_triposr
- tools/asset_forge/forge.py:67 cut_out
- tools/asset_forge/forge.py:85 run_trellis
- tools/asset_forge/forge.py:107 cleanup
- tools/asset_forge/forge.py:124 main

## tools/asset_forge/forge_creatures.py (74 lines) — The whole creature chain, for all 3 creatures x 4 variants (by Claude 3).
- tools/asset_forge/forge_creatures.py:26 blender
- tools/asset_forge/forge_creatures.py:33 main

## tools/asset_forge/glb_jpeg_clean.py (87 lines) — Clean the JPEG pictures inside a .glb so Godot can read them (Nov 20).
- tools/asset_forge/glb_jpeg_clean.py:18 strip_jpeg
- tools/asset_forge/glb_jpeg_clean.py:41 clean

## tools/asset_forge/glb_jpeg_fix.py (76 lines) — Makes Blender's JPEG textures inside .glb models readable by Godot.
- tools/asset_forge/glb_jpeg_fix.py:18 strip_jpeg
- tools/asset_forge/glb_jpeg_fix.py:37 fix

## tools/asset_forge/glb_scale.py (27 lines) — Give a finished .glb model its size in the game (by Claude 3, Nov 16, 2026).
- tools/asset_forge/glb_scale.py:12 set_scale

## tools/asset_forge/great_kaykit_bake.gd (176 lines) — Bakes the Lampwick Foreman's two-handed moves onto the dwarf (F389, owner Nov 20: "use the Foreman's moves").
- tools/asset_forge/great_kaykit_bake.gd:44 _init
- tools/asset_forge/great_kaykit_bake.gd:123 _globals
- tools/asset_forge/great_kaykit_bake.gd:134 _sample
- tools/asset_forge/great_kaykit_bake.gd:157 _mirror
- tools/asset_forge/great_kaykit_bake.gd:168 _delta
- tools/asset_forge/great_kaykit_bake.gd:174 _off_line

## tools/asset_forge/great_swing_export.gd (160 lines) — Records the game dwarf swinging the great axe (F389: DwarfGreatSwing + DwarfFist, exactly as the game plays it
- tools/asset_forge/great_swing_export.gd:14 _init
- tools/asset_forge/great_swing_export.gd:83 _record
- tools/asset_forge/great_swing_export.gd:138 _slim
- tools/asset_forge/great_swing_export.gd:157 _own

## tools/asset_forge/hand_page_split.py (81 lines) — Split a recorded dwarf (.glb from dwarf_anim_export.gd hands=1) into the body and its moves, for the close-up
- tools/asset_forge/hand_page_split.py:21 read_glb
- tools/asset_forge/hand_page_split.py:30 write_glb
- tools/asset_forge/hand_page_split.py:39 values
- tools/asset_forge/hand_page_split.py:48 main

## tools/asset_forge/holecheck.py (64 lines) — See-through check (owner, Nov 17: "I don't want any holes"): renders a building piece straight from the front

## tools/asset_forge/icons.py (137 lines) — Item icons: make ChatGPT prompts, and cut ChatGPT's icon sheets into one picture per item.
- tools/asset_forge/icons.py:44 make_prompts
- tools/asset_forge/icons.py:64 cut
- tools/asset_forge/icons.py:99 slots
- tools/asset_forge/icons.py:110 contact

## tools/asset_forge/islands.py (89 lines) — Floating-part check for any .glb (same rule as the game's PieceMesh.islands, owner notes F34-F62):
- tools/asset_forge/islands.py:15 _acc
- tools/asset_forge/islands.py:28 islands

## tools/asset_forge/kit.py (585 lines) — Hand-built model kit for Blender: chunky stylized parts (stone blocks, planks, beams, metal bands,
- tools/asset_forge/kit.py:38 reset
- tools/asset_forge/kit.py:43 mat
- tools/asset_forge/kit.py:62 tex_mat
- tools/asset_forge/kit.py:82 _uv_box
- tools/asset_forge/kit.py:98 _finish
- tools/asset_forge/kit.py:121 box
- tools/asset_forge/kit.py:130 stone
- tools/asset_forge/kit.py:137 plank
- tools/asset_forge/kit.py:141 tbox
- tools/asset_forge/kit.py:146 tcyl
- tools/asset_forge/kit.py:150 ring
- tools/asset_forge/kit.py:157 cone
- tools/asset_forge/kit.py:163 glow
- tools/asset_forge/kit.py:168 cylinder
- tools/asset_forge/kit.py:174 rivet
- tools/asset_forge/kit.py:181 band
- tools/asset_forge/kit.py:191 gem
- tools/asset_forge/kit.py:205 roughen
- tools/asset_forge/kit.py:218 soft
- tools/asset_forge/kit.py:228 _mesh_obj
- tools/asset_forge/kit.py:242 flame
- tools/asset_forge/kit.py:266 fire
- tools/asset_forge/kit.py:281 crystal
- tools/asset_forge/kit.py:302 crystal_cluster
- tools/asset_forge/kit.py:313 mushroom
- tools/asset_forge/kit.py:342 water
- tools/asset_forge/kit.py:349 drop
- tools/asset_forge/kit.py:360 rope_wrap
- tools/asset_forge/kit.py:372 _rope_wrap_z
- tools/asset_forge/kit.py:400 rope
- tools/asset_forge/kit.py:414 hide_tips
- tools/asset_forge/kit.py:427 taper
- tools/asset_forge/kit.py:440 fire_spot
- tools/asset_forge/kit.py:448 hide
- tools/asset_forge/kit.py:473 save
- tools/asset_forge/kit.py:522 _cut_lid
- tools/asset_forge/kit.py:557 _preview
- tools/asset_forge/kit.py:583 args

## tools/asset_forge/one_kaykit_bake.gd (114 lines) — Bakes the KayKit Skeletons warrior's ONE-handed moves onto the dwarf (F389, owner Nov 20: "do the same for the
- tools/asset_forge/one_kaykit_bake.gd:21 _init

## tools/asset_forge/one_swing_export.gd (424 lines) — Records the game dwarf swinging the sword and the mace with the KayKit warrior's one-handed moves (F389 chat 1
- tools/asset_forge/one_swing_export.gd:41 _init
- tools/asset_forge/one_swing_export.gd:167 _record
- tools/asset_forge/one_swing_export.gd:268 _clear_check
- tools/asset_forge/one_swing_export.gd:312 _box_of
- tools/asset_forge/one_swing_export.gd:327 _thin_axis
- tools/asset_forge/one_swing_export.gd:331 _axis
- tools/asset_forge/one_swing_export.gd:336 _disc_dist
- tools/asset_forge/one_swing_export.gd:345 _slim
- tools/asset_forge/one_swing_export.gd:364 _own
- tools/asset_forge/one_swing_export.gd:371 _record_all

## tools/asset_forge/one_ual_bake.gd (199 lines) — Bakes Quaternius's Universal Animation Library 2 sword moves (CC0, already the dwarf's own pack) into the swin
- tools/asset_forge/one_ual_bake.gd:44 _init
- tools/asset_forge/one_ual_bake.gd:170 _lock_shield_arm
- tools/asset_forge/one_ual_bake.gd:180 _q
- tools/asset_forge/one_ual_bake.gd:184 _arg
- tools/asset_forge/one_ual_bake.gd:193 _less_lean

## tools/asset_forge/one_video_bake.gd (145 lines) — Bakes the owner's OWN filmed sword and mace combos onto the dwarf (F389 chat 13, owner Nov 20: "copy my videos
- tools/asset_forge/one_video_bake.gd:32 _edge_turn
- tools/asset_forge/one_video_bake.gd:47 _v
- tools/asset_forge/one_video_bake.gd:52 _turn
- tools/asset_forge/one_video_bake.gd:58 _square
- tools/asset_forge/one_video_bake.gd:62 _init

## tools/asset_forge/one_video_preview.gd (118 lines) — Key-pose pictures of the owner's filmed sword / mace combos on the dwarf (F389 chat 13: DwarfOneSwing's video 
- tools/asset_forge/one_video_preview.gd:22 _init
- tools/asset_forge/one_video_preview.gd:60 _share
- tools/asset_forge/one_video_preview.gd:68 _process
- tools/asset_forge/one_video_preview.gd:116 _show_shield

## tools/asset_forge/overview.py (69 lines) — Overview picture of many forged models, side by side (to check them all at a glance).

## tools/asset_forge/pack_page_gltf.py (134 lines) — Shrink a .glb for the 3D page and write it as glTF text with the buffer inside (the page host doesn't serve .g
- tools/asset_forge/pack_page_gltf.py:20 view_bytes
- tools/asset_forge/pack_page_gltf.py:61 add_view

## tools/asset_forge/sculpt_test_beetle.py (347 lines) — The Rock Beetle's sculpt-and-bake pass (by Claude 3): the grey hand-built beetle in, the finished game beetle 
- tools/asset_forge/sculpt_test_beetle.py:68 split_by_material
- tools/asset_forge/sculpt_test_beetle.py:100 shoot
- tools/asset_forge/sculpt_test_beetle.py:257 _leg_table
- tools/asset_forge/sculpt_test_beetle.py:270 _seg_dist
- tools/asset_forge/sculpt_test_beetle.py:276 split_knee

## tools/asset_forge/sides4.py (84 lines) — Four-side picture of building pieces, laid out like a turnaround sheet: one row per model, columns

## tools/asset_forge/swing_sheet.py (63 lines) — Picture sheet of the great axe swings for the owner (F389): one row per key pose, columns = from behind (the g
- tools/asset_forge/swing_sheet.py:17 font
- tools/asset_forge/swing_sheet.py:26 crop
- tools/asset_forge/swing_sheet.py:32 main

## tools/asset_forge/twohand_preview.gd (158 lines) — Preview pictures for F389 (great axe / great maul, the Lampwick Foreman's moves: DwarfGreatSwing, chat 11): th
- tools/asset_forge/twohand_preview.gd:29 _init
- tools/asset_forge/twohand_preview.gd:93 _shot
- tools/asset_forge/twohand_preview.gd:97 _process
- tools/asset_forge/twohand_preview.gd:154 _report

## tools/blender_poses/add_arm_controls.py (104 lines) — Adds shoulder and elbow balls to the owner's pose file, keeping every pose he has made (owner, Nov 20: "can yo
- tools/blender_poses/add_arm_controls.py:18 shape

## tools/blender_poses/add_wrist_balls.py (106 lines) — Owner, Nov 20 (screenshot): one ball on the fist (on the handle), one on the wrist, one on the elbow, one on t
- tools/blender_poses/add_wrist_balls.py:25 paint
- tools/blender_poses/add_wrist_balls.py:40 ball

## tools/blender_poses/make_pose_file.py (387 lines) — Builds the owner's pose file for the great axe (F389, Nov 20: "I'll pose the dwarf by hand in Blender").
- tools/blender_poses/make_pose_file.py:36 gm
- tools/blender_poses/make_pose_file.py:44 gv
- tools/blender_poses/make_pose_file.py:48 gd
- tools/blender_poses/make_pose_file.py:52 rigid
- tools/blender_poses/make_pose_file.py:57 as_list
- tools/blender_poses/make_pose_file.py:127 bone_world
- tools/blender_poses/make_pose_file.py:137 empty
- tools/blender_poses/make_pose_file.py:150 material
- tools/blender_poses/make_pose_file.py:174 shape
- tools/blender_poses/make_pose_file.py:206 frame
- tools/blender_poses/make_pose_file.py:230 slide

## tools/blender_poses/place_arm_balls.py (71 lines) — Puts the arm balls right ON the joints (owner, Nov 20: "the bubbles actually in the wrist, elbow and shoulder,
- tools/blender_poses/place_arm_balls.py:26 keyed

## tools/blender_poses/pose_from_video.py (360 lines) — Copies the owner's filmed swing onto the dwarf by moving the pose file's controls (F389, chat 10, Nov 20, 2026
- tools/blender_poses/pose_from_video.py:61 upd
- tools/blender_poses/pose_from_video.py:65 head
- tools/blender_poses/pose_from_video.py:69 set_world_loc
- tools/blender_poses/pose_from_video.py:75 key
- tools/blender_poses/pose_from_video.py:112 shoulder_rest_spots
- tools/blender_poses/pose_from_video.py:128 body_tree
- tools/blender_poses/pose_from_video.py:155 clearance
- tools/blender_poses/pose_from_video.py:169 nelder_mead
- tools/blender_poses/pose_from_video.py:197 dir_from

## tools/blender_poses/read_poses.py (95 lines) — Reads the owner's great axe poses out of his Blender file and writes them for the game (F389, Nov 20).
- tools/blender_poses/read_poses.py:22 gm
- tools/blender_poses/read_poses.py:30 pose_at
- tools/blender_poses/read_poses.py:52 compare

## tools/blender_poses/render_poses.py (51 lines) — Pictures of the pose file's key poses from the front (like the owner's video) and from behind (the game camera
- tools/blender_poses/render_poses.py:39 look

## tools/blender_poses/shoulders_help_reach.py (18 lines) — The shoulders help the arms reach again (owner, Nov 20: "he's not actually holding the axe"): with the shoulde

## tools/blender_poses/view_setup.py (100 lines) — Opens the pose file in Blender WITH its window (run once after make_pose_file.py): sets the view the owner sta
- tools/blender_poses/view_setup.py:16 view3d
- tools/blender_poses/view_setup.py:23 setup
- tools/blender_poses/view_setup.py:51 shot
- tools/blender_poses/view_setup.py:77 tick

## tools/blueprint_viewer/assemble_blueprint.py (43 lines) — Put a blueprint together from the game's real models (Blender, for photos):

## tools/blueprint_viewer/make_page_files.py (17 lines) — Make the files the blueprint 3D page needs: bp.json (piece list) + m/<piece>.json (each kind of piece once).

## tools/bolt_check.gd (102 lines) — Real crossbow shot at a bat in the air (Claude, Nov 19: owner "I shoot at the bat and nothing happened").
- tools/bolt_check.gd:8 _init
- tools/bolt_check.gd:15 _run

## tools/cave_map/export_zone.gd (37 lines) — Writes one zone's cave plan (rooms, tunnels, places) as JSON for the 3D map page (tools/cave_map/map.html).
- tools/cave_map/export_zone.gd:4 _init

## tools/cave_map/make_map.py (11 lines) — Puts a zone's cave plan (from export_zone.gd) into the 3D map page, so it opens straight from disk in a browse

## tools/cave_stats.gd (113 lines) — Cave numbers and timings, without opening the game (F211 step 1).
- tools/cave_stats.gd:8 _init
- tools/cave_stats.gd:78 _bench
- tools/cave_stats.gd:105 fingerprint

## tools/claude-budget/check.py (75 lines) — !/usr/bin/env python3
- tools/claude-budget/check.py:21 week_start
- tools/claude-budget/check.py:32 verdict
- tools/claude-budget/check.py:40 main

## tools/claude-budget/test_check.py (17 lines) — !/usr/bin/env python3

## tools/codemap/make_codemap.py (65 lines) — Builds docs/CODE-MAP.md: the code's table of contents (owner, Nov 21: "read only the part you need").
- tools/codemap/make_codemap.py:20 purpose
- tools/codemap/make_codemap.py:33 main

## tools/craft_wiki/build.py (45 lines) — Builds the Crafting Wiki page (one HTML file, pictures inside) from dump.gd's JSON.
- tools/craft_wiki/build.py:17 icon_data
- tools/craft_wiki/build.py:27 main

## tools/craft_wiki/dump.gd (52 lines) — Dumps every item, recipe and "where to get it" to JSON for the Crafting Wiki page.
- tools/craft_wiki/dump.gd:7 _init

## tools/crossbow_walk_check.gd (76 lines) — Walk around with the crossbow: aim, shoot, reload, then try every direction (owner, Nov 19: "with the crossbow
- tools/crossbow_walk_check.gd:9 _init
- tools/crossbow_walk_check.gd:16 _walk
- tools/crossbow_walk_check.gd:29 _all_dirs
- tools/crossbow_walk_check.gd:34 _run

## tools/dump_blueprint.gd (19 lines) — Writes a ready-made blueprint as JSON (for making 3D previews of it in Blender).
- tools/dump_blueprint.gd:6 _init

## tools/dungeons/decor.py (160 lines) — Dungeon decor from the decor catalogue (docs/art/DECOR-CATALOG.md, owner Nov 22: "every single piece has its o
- tools/dungeons/decor.py:25 _origin
- tools/dungeons/decor.py:32 footprint
- tools/dungeons/decor.py:36 wall
- tools/dungeons/decor.py:48 corner
- tools/dungeons/decor.py:56 mid
- tools/dungeons/decor.py:62 rect_dist
- tools/dungeons/decor.py:71 rects_dist
- tools/dungeons/decor.py:76 check
- tools/dungeons/decor.py:134 height
- tools/dungeons/decor.py:141 blocks_wall_spot
- tools/dungeons/decor.py:149 props

## tools/dungeons/glb_bounds.py (42 lines) — Size of a .glb model (with its node moves/turns/scales): python tools/dungeons/glb_bounds.py <file.glb>...
- tools/dungeons/glb_bounds.py:5 quat_m
- tools/dungeons/glb_bounds.py:9 node_m
- tools/dungeons/glb_bounds.py:18 bounds

## tools/dungeons/junk.py (370 lines) — Dungeon junk (owner, Nov 20): small floor models "just for looks", laid along the walls and in room corners.
- tools/dungeons/junk.py:44 is_flat
- tools/dungeons/junk.py:75 size
- tools/dungeons/junk.py:83 model_of
- tools/dungeons/junk.py:91 part_at
- tools/dungeons/junk.py:99 corners
- tools/dungeons/junk.py:111 seg_dist
- tools/dungeons/junk.py:120 poly_dist
- tools/dungeons/junk.py:124 in_rect
- tools/dungeons/junk.py:128 cell_of
- tools/dungeons/junk.py:132 walk_lines
- tools/dungeons/junk.py:169 place_junk

## tools/dungeons/make_lampwick.py (573 lines) — Lampwick Drift (dungeon map 2): every root wood piece, rail, trap, lamp, piece of furniture, chest and creatur
- tools/dungeons/make_lampwick.py:43 group
- tools/dungeons/make_lampwick.py:47 height
- tools/dungeons/make_lampwick.py:51 space_of
- tools/dungeons/make_lampwick.py:62 in_box
- tools/dungeons/make_lampwick.py:67 ground
- tools/dungeons/make_lampwick.py:79 r3
- tools/dungeons/make_lampwick.py:83 piece
- tools/dungeons/make_lampwick.py:87 prop
- tools/dungeons/make_lampwick.py:96 creature
- tools/dungeons/make_lampwick.py:101 chest
- tools/dungeons/make_lampwick.py:106 slope_point
- tools/dungeons/make_lampwick.py:181 wall_pos
- tools/dungeons/make_lampwick.py:408 _d

## tools/dungeons/make_mossgate.py (552 lines) — Mossgate Hold (dungeon map 1): every root wood piece, trap, door, piece of furniture, chest and creature, laid
- tools/dungeons/make_mossgate.py:33 group
- tools/dungeons/make_mossgate.py:37 height
- tools/dungeons/make_mossgate.py:47 space_of
- tools/dungeons/make_mossgate.py:60 in_box
- tools/dungeons/make_mossgate.py:68 piece
- tools/dungeons/make_mossgate.py:72 prop
- tools/dungeons/make_mossgate.py:77 creature
- tools/dungeons/make_mossgate.py:84 chest
- tools/dungeons/make_mossgate.py:149 wall_pos
- tools/dungeons/make_mossgate.py:379 _d

## tools/dungeons/make_pell.py (521 lines) — Old Pell's Diggings (dungeon map 3): every root wood piece, ladder, trap, piece of furniture, chest and creatu
- tools/dungeons/make_pell.py:35 level
- tools/dungeons/make_pell.py:39 floor_y
- tools/dungeons/make_pell.py:43 height
- tools/dungeons/make_pell.py:47 in_box
- tools/dungeons/make_pell.py:55 r3
- tools/dungeons/make_pell.py:59 piece
- tools/dungeons/make_pell.py:63 prop
- tools/dungeons/make_pell.py:72 creature
- tools/dungeons/make_pell.py:77 chest
- tools/dungeons/make_pell.py:149 wall_pos
- tools/dungeons/make_pell.py:378 _d

## tools/fiber_count.gd (24 lines) — How much fiber a world has (Nov 20 economy check): spots by kind, and the fiber near the start.
- tools/fiber_count.gd:6 _init

## tools/journal/merge_inbox.py (70 lines) — Moves journal entries from journal-inbox/ into JOURNAL.md (owner, Nov 21).
- tools/journal/merge_inbox.py:18 git
- tools/journal/merge_inbox.py:23 main

## tools/make_starter_blueprint.gd (34 lines) — Writes res://blueprints/small_rootwood_lodge.dwbp (the blueprint that ships with the game).
- tools/make_starter_blueprint.gd:6 _initialize

## tools/mocap/one_hand_scan.py (84 lines) — Step 1 for the owner's one-handed videos (F389 chat 13: sword IMG_4428, mace IMG_4429; front view, pale blue g
- tools/mocap/one_hand_scan.py:34 mend
- tools/mocap/one_hand_scan.py:43 smooth

## tools/mocap/one_hand_targets.py (254 lines) — Step 2 for the owner's one-handed videos (F389 chat 13): his tracked moves -> bone DIRECTIONS for the dwarf.
- tools/mocap/one_hand_targets.py:29 unit
- tools/mocap/one_hand_targets.py:34 smooth
- tools/mocap/one_hand_targets.py:41 load
- tools/mocap/one_hand_targets.py:48 seg
- tools/mocap/one_hand_targets.py:63 hinge
- tools/mocap/one_hand_targets.py:76 turned_line
- tools/mocap/one_hand_targets.py:92 frame_of
- tools/mocap/one_hand_targets.py:98 build

## tools/mocap/stick_finder.py (52 lines) — Finds a plain white stick held in the pale-gloved fist (F389 chat 13: the owner's sword/mace videos, no tape).
- tools/mocap/stick_finder.py:15 ridge_image
- tools/mocap/stick_finder.py:21 find

## tools/mocap/swing_from_video.py (195 lines) — Turn a phone video of the owner swinging a taped stick into key poses for the dwarf (F389, great axe).
- tools/mocap/swing_from_video.py:42 find_color
- tools/mocap/swing_from_video.py:58 make_pose
- tools/mocap/swing_from_video.py:65 body_numbers
- tools/mocap/swing_from_video.py:91 pick_keys
- tools/mocap/swing_from_video.py:116 draw
- tools/mocap/swing_from_video.py:129 run

## tools/mocap/test_swing_tool.py (66 lines) — Self-check for swing_from_video.py without a real person: a made-up video of a taped stick doing a slow
- tools/mocap/test_swing_tool.py:19 angles
- tools/mocap/test_swing_tool.py:28 make_video
- tools/mocap/test_swing_tool.py:44 main

## tools/mocap/track_all_frames.py (53 lines) — Run MediaPipe Pose on every extracted frame; save pixel + world joints, plus glove/handle colour blobs.
- tools/mocap/track_all_frames.py:16 blob
- tools/mocap/track_all_frames.py:27 line

## tools/mocap/video_targets.py (33 lines) — Video key frames -> direction numbers for the dwarf (Blender axes: x = his left, y = his back (front = -y), z 
- tools/mocap/video_targets.py:6 W
- tools/mocap/video_targets.py:9 P

## tools/model_check/check_models.py (437 lines) — Model checks from docs/art/MODEL-RULES.md, run on real model surfaces (not rough boxes).
- tools/model_check/check_models.py:37 piece_sizes
- tools/model_check/check_models.py:52 script_text
- tools/model_check/check_models.py:60 load
- tools/model_check/check_models.py:86 key
- tools/model_check/check_models.py:90 find
- tools/model_check/check_models.py:97 Part
- tools/model_check/check_models.py:122 split_parts
- tools/model_check/check_models.py:139 touching
- tools/model_check/check_models.py:158 whole
- tools/model_check/check_models.py:162 _flat
- tools/model_check/check_models.py:172 check_float
- tools/model_check/check_models.py:206 min_gap
- tools/model_check/check_models.py:219 hidden
- tools/model_check/check_models.py:231 check_shimmer
- tools/model_check/check_models.py:262 check_outline
- tools/model_check/check_models.py:291 check_roof
- tools/model_check/check_models.py:339 model_list
- tools/model_check/check_models.py:355 has_script
- tools/model_check/check_models.py:374 main

## tools/model_check/chest_shot.gd (47 lines) — Pictures of a chest's lid swinging open (ChestOpen, owner F345) at a few moments (Claude, Nov 18).
- tools/model_check/chest_shot.gd:10 _init
- tools/model_check/chest_shot.gd:42 _process

## tools/model_check/eye_dump.gd (15 lines) — Prints the eye materials of a creature as the game sets it up (Claude, Nov 18: "the snail's eyes are white").
- tools/model_check/eye_dump.gd:4 _init

## tools/model_check/flap_shot.gd (45 lines) — Pictures of a flying creature's wing beat, front view, at 4 moments of one beat (Claude, Nov 18: the bat's joi
- tools/model_check/flap_shot.gd:10 _init
- tools/model_check/flap_shot.gd:37 _process

## tools/model_check/glow_dump.gd (16 lines) — Prints how a creature's glowing materials breathe in the game, over 12 seconds (Claude, Nov 18).
- tools/model_check/glow_dump.gd:4 _init

## tools/model_check/looks_shot.gd (45 lines) — A row of creatures: the 4 looks of the Rock Snail, Rock Beetle and Cave Bat, and an Ember-crested (crystal)
- tools/model_check/looks_shot.gd:9 _init
- tools/model_check/looks_shot.gd:41 _process

## tools/model_check/make_piece_icons.py (72 lines) — Small pictures of the building pieces for the build menu (owner, Nov 15, F132: "pictures, I don't want
- tools/model_check/make_piece_icons.py:17 make
- tools/model_check/make_piece_icons.py:42 home_decor
- tools/model_check/make_piece_icons.py:55 main

## tools/model_check/ragdoll_shot.gd (69 lines) — Pictures of a creature's death ragdoll falling onto a floor (Claude, Nov 18).
- tools/model_check/ragdoll_shot.gd:7 _init
- tools/model_check/ragdoll_shot.gd:56 _process

## tools/model_check/shatter_overlap.gd (38 lines) — Do rock chunks end up inside each other? Two bursts on one spot onto a floor, then counts pairs of chunks whos
- tools/model_check/shatter_overlap.gd:9 _init
- tools/model_check/shatter_overlap.gd:25 _physics_process

## tools/model_check/swing_shot.gd (48 lines) — Pictures of the dwarf's swing trail (WeaponTrail) at a few moments of one swing (Claude, Nov 18).
- tools/model_check/swing_shot.gd:10 _init
- tools/model_check/swing_shot.gd:41 _process

## tools/nan_hunt.gd (45 lines) — Hunts "broken numbers" (NaN / infinite places), Claude Nov 19: the owner's log had ~1,300 "Vector3 cannot be
- tools/nan_hunt.gd:11 _init
- tools/nan_hunt.gd:18 _run
- tools/nan_hunt.gd:41 _all

## tools/perf_probe.gd (188 lines) — Finds what eats the physics time (Claude, Nov 19: the owner had 5 FPS with "physics 25 ms").
- tools/perf_probe.gd:10 _init
- tools/perf_probe.gd:18 _avg_physics
- tools/perf_probe.gd:28 _kind
- tools/perf_probe.gd:33 _run
- tools/perf_probe.gd:100 _monster_breakdown
- tools/perf_probe.gd:177 _cap
- tools/perf_probe.gd:184 _all

## tools/quiet_run.py (62 lines) — Runs a command (a Godot game run, the tests, a Blender script...) and prints only the useful part of its outpu
- tools/quiet_run.py:25 main

## tools/ruins/make_brewhall_ruin.py (203 lines) — The RUINED Brewhall (owner, Nov 20, F479: the third ruin): made from the real blueprint, then broken.
- tools/ruins/make_brewhall_ruin.py:27 near
- tools/ruins/make_brewhall_ruin.py:31 at
- tools/ruins/make_brewhall_ruin.py:86 add
- tools/ruins/make_brewhall_ruin.py:122 same_here
- tools/ruins/make_brewhall_ruin.py:127 rebuild

## tools/ruins/make_kiln_ruin.py (316 lines) — The RUINED Old Kiln (owner, Nov 21, F479: ruin 5 of Zone 1): made from the real blueprint, then broken.
- tools/ruins/make_kiln_ruin.py:38 with_crown
- tools/ruins/make_kiln_ruin.py:48 rot_from
- tools/ruins/make_kiln_ruin.py:54 steps_of
- tools/ruins/make_kiln_ruin.py:58 turned
- tools/ruins/make_kiln_ruin.py:62 ring_j
- tools/ruins/make_kiln_ruin.py:67 in_kiln
- tools/ruins/make_kiln_ruin.py:71 near
- tools/ruins/make_kiln_ruin.py:153 add
- tools/ruins/make_kiln_ruin.py:157 kiln_spot
- tools/ruins/make_kiln_ruin.py:184 wall_back
- tools/ruins/make_kiln_ruin.py:234 same_here
- tools/ruins/make_kiln_ruin.py:239 rebuild
- tools/ruins/make_kiln_ruin.py:270 plan_of

## tools/ruins/make_outpost_ruin.py (188 lines) — The RUINED Stone Outpost (the "Fallen Outpost", owner Nov 17): made from the real blueprint, then broken.
- tools/ruins/make_outpost_ruin.py:25 steps
- tools/ruins/make_outpost_ruin.py:29 near
- tools/ruins/make_outpost_ruin.py:95 part_of
- tools/ruins/make_outpost_ruin.py:105 near_xz
- tools/ruins/make_outpost_ruin.py:109 slide
- tools/ruins/make_outpost_ruin.py:122 add

## tools/ruins/make_spire_ruin.py (245 lines) — The RUINED Lantern Spire (owner, Nov 20: ruin 4 of Zone 1): made from the real blueprint, then broken.
- tools/ruins/make_spire_ruin.py:33 step_of
- tools/ruins/make_spire_ruin.py:38 off
- tools/ruins/make_spire_ruin.py:44 steps_of
- tools/ruins/make_spire_ruin.py:48 rot_from
- tools/ruins/make_spire_ruin.py:54 turned
- tools/ruins/make_spire_ruin.py:116 add
- tools/ruins/make_spire_ruin.py:120 along
- tools/ruins/make_spire_ruin.py:142 ring_spot
- tools/ruins/make_spire_ruin.py:166 same_here
- tools/ruins/make_spire_ruin.py:171 rebuild
- tools/ruins/make_spire_ruin.py:202 plan_of

## tools/ruins/make_twin_gate_ruin.py (622 lines) — The RUINED Twin Gate (owner, Nov 21: ruin 6, the first GRAND ruin, docs/design/GRAND-RUIN-RECIPE.md).
- tools/ruins/make_twin_gate_ruin.py:44 rot_from
- tools/ruins/make_twin_gate_ruin.py:49 steps_of
- tools/ruins/make_twin_gate_ruin.py:53 turned
- tools/ruins/make_twin_gate_ruin.py:60 plan_of
- tools/ruins/make_twin_gate_ruin.py:69 extras
- tools/ruins/make_twin_gate_ruin.py:146 with_extras
- tools/ruins/make_twin_gate_ruin.py:151 near
- tools/ruins/make_twin_gate_ruin.py:155 at
- tools/ruins/make_twin_gate_ruin.py:162 in_r_tower
- tools/ruins/make_twin_gate_ruin.py:166 break_r_tower
- tools/ruins/make_twin_gate_ruin.py:269 is_piece
- tools/ruins/make_twin_gate_ruin.py:273 supported
- tools/ruins/make_twin_gate_ruin.py:316 add
- tools/ruins/make_twin_gate_ruin.py:345 dims
- tools/ruins/make_twin_gate_ruin.py:355 on_wall
- tools/ruins/make_twin_gate_ruin.py:364 free_at
- tools/ruins/make_twin_gate_ruin.py:431 corners_of
- tools/ruins/make_twin_gate_ruin.py:437 poly_pt_dist
- tools/ruins/make_twin_gate_ruin.py:443 seg_dist
- tools/ruins/make_twin_gate_ruin.py:450 poly_dist
- tools/ruins/make_twin_gate_ruin.py:456 top_of
- tools/ruins/make_twin_gate_ruin.py:460 check_things
- tools/ruins/make_twin_gate_ruin.py:524 shifted
- tools/ruins/make_twin_gate_ruin.py:544 same_here
- tools/ruins/make_twin_gate_ruin.py:549 rebuild

## tools/ruins/make_watchtower_ruin.py (146 lines) — The RUINED Stone Watchtower (owner, Nov 17): made from the real blueprint, then broken.
- tools/ruins/make_watchtower_ruin.py:25 steps
- tools/ruins/make_watchtower_ruin.py:29 dir_of
- tools/ruins/make_watchtower_ruin.py:33 at
- tools/ruins/make_watchtower_ruin.py:79 add

## tools/ruins/ruin_junk.py (595 lines) — Ruin junk (owner, Nov 20): small floor models "just for looks" in and around the ruins (the Watchtower, the Fa
- tools/ruins/ruin_junk.py:178 _pieces
- tools/ruins/ruin_junk.py:192 steps_of
- tools/ruins/ruin_junk.py:196 turn
- tools/ruins/ruin_junk.py:202 outline
- tools/ruins/ruin_junk.py:213 footprint
- tools/ruins/ruin_junk.py:222 grow_by
- tools/ruins/ruin_junk.py:232 overlap
- tools/ruins/ruin_junk.py:245 inside
- tools/ruins/ruin_junk.py:263 height
- tools/ruins/ruin_junk.py:272 make

## tools/shot_skills.gd (44 lines) — Photographs the skills window with a sample dwarf (level 18, some perks). Usage:
- tools/shot_skills.gd:6 _init
- tools/shot_skills.gd:10 _run

## tools/shove_check.gd (43 lines) — How far a beetle's charge throws the dwarf (owner, Nov 17/19, F234: "much too far, a couple of metres at most"
- tools/shove_check.gd:4 _init
- tools/shove_check.gd:8 _run

## tools/ui_kit/cut_ui_kit.py (73 lines) — Cuts the "dwarf workshop" UI kit sheet (ChatGPT, owner-approved, F187) into pieces.
- tools/ui_kit/cut_ui_kit.py:37 main
- tools/ui_kit/cut_ui_kit.py:57 split_slider

## tools/zone1_gear_check.gd (111 lines) — What can a player make in Zone 1 (Mossy Hollows, incl. the Copper Deeps), and what's out of reach?
- tools/zone1_gear_check.gd:18 _init
- tools/zone1_gear_check.gd:103 _shown
