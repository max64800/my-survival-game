# Decor night brief (Nov 21, 2026): how to build decor models the owner likes

Every helper building decor reads this whole page first. It comes from the owner scoring 114 decor models 1-10.

## The owner's taste (learned from the scores)
**Scored 10:** wall trophies and displays (crossed axes/swords on a plaque, bat wings, tooth necklace, foreman helmet,
gem case, ore sample shelf), tidy shelves FULL of small ordered things (dish rack, spice shelf, mug rack, tool wall,
pie rack, workbench clutter, writing desk), dungeon pieces that tell one clear story (hanging cage, fallen
chandelier, overturned table, prison bench, rocking chair, bar counter, stone game table, world stone).

**Scored 1-3, never do this:**
- **No moss at all** (owner: "no moss for now"). No lumps or blobs pretending to be moss, leaves or fur.
- **Too simple**: few parts, plain shapes. Every model needs many crisp small parts: rims, bands, rivets, pegs,
  chips, worn edges, small props. A bowl or a stone slab alone is a fail.
- **Fake carving**: markings, runes, tally marks, faces and pictures are CUT INTO the stone (boolean difference,
  or a sunken groove with dark walls). Never thin sticks laid on the surface.
- **Parts that poke out or don't join**: crystals sticking out of their holder, a pole not attached, a blade that
  doesn't meet its body. Everything sits IN or ON its holder, joined cleanly. Check this by eye, the checker misses it.
- **Piles that look fake**: rocks that don't blend, round grey "coal". Piles are many different-sized angular pieces
  that overlap and settle; coal is near-black, glossy, angular.
- **Things that make no sense**: physics wrong (a tipped cart that floats), ash where none belongs, invented machines.
  If a real medieval dwarf wouldn't have it, don't make it.
- **Mismatched colours**: one wood family per model, one stone family per model. No grey + black + green clash.
- **Soft clutter on top**: no pillows, blankets, bedding, food piles, bugs, random dots. Beds bare, tubs and basins
  empty, chests empty (and broken if they are "old"), racks empty unless the rack's point is what it holds.
- **Modern look**: signs, symbols, tools all look medieval/dwarven. No road-sign triangles, no modern machines.

## Owner's round-2 rules (Nov 22, from 95 "improve" notes on 500 models)
- **No arrows in our world, only crossbow bolts** (short, thick, fletched bolts). Never make bows or arrows.
- **Avoid rails** in new decor.
- **No water, puddles, spills or oil pools** in decor (troughs, sluices, flumes, quench tubs, crucible spills: dry/empty).
- **Nothing glowing or lit unless it is clearly working right now**: old forges, cooling blades, ember pans, crucibles from
  long ago are cold (no yellow/red/orange glow). Only fires the owner asked for stay lit.
- **Hollow things are really hollow**: horns (open bell end, dark inside), pots, buckets, bowls, shafts, dig holes,
  braziers. A horn's end must join the horn.
- **Round things are round**: buckets, bells, barrel tops (never square). Bells are a proper bell curve with lip and detail.
- **Gravity**: chains and ropes hang straight down or lie on the ground; lids lie on the ground, not mid-swing; hung
  things sit ON real hooks; ropes wrap tight round what they hold.
- **No clipping**: nothing passes through anything (horns through lamp posts, ropes through lids, logs inside carts,
  tools through buckets). Tools in a barrel lean against its rim.
- **Figures (dwarves, statues, armour) must not look "Roblox/Minecraft"**: no box bodies. Import the game's real dwarf
  `assets/characters/dwarf/dwarf_body.glb` (and `armor_hide.glb`, `Hair_Beard.gltf` if they help) with `place_glb`, pose
  it by rotating the whole thing, repaint it stone/bronze, and add carved detail. Look at the existing dwarf statue head
  `assets/models/dungeon/junk_statue_head.glb` for the stone look. Armour wraps all the way round the stand; dwarf scale
  (stands are short).
- **Trophies match their monster exactly**: use the real monster models (bats, beetles, snails, rats, miners in
  `assets/models/creatures/*.glb`, spiders in `assets/models/monsters/cave_spider_v*.glb`): just the head, mounted on
  ONE wooden wall panel, flat back. Helpers `monster_head` and `head_panel` in `decor_nov21_hm.py` do this.
- **Lootable things get an empty version**: the full model plus `<id>_empty` (same model with the loot gone). The game
  code for looting is done later; just build both models.
- **Chests that should open**: build with `kit.save(..., lid=<height>)` so the lid is its own part.
- **Coal piles**: many angular near-black glossy lumps, no smooth dome or ball underneath showing.

## Style and rules
- Read `docs/art/MODEL-RULES.md` (rules 1, 2, 5, 6; every part touches another).
- Copy the style of `tools/asset_forge/builds/night_decor.py` (header, helpers, MODELS dict, `__main__`).
  Look at the owner's favourites to match them: `tools/asset_forge/builds/decor_nov21_d.py` (crossed_axes,
  gem_case, ore_sample_shelf, foreman_helmet_trophy), `decor_nov21_f.py` (spice_shelf, dish_rack, tool_wall),
  `decor_nov21_e.py` (bar_counter, writing_desk), `decor_nov21_c.py` (prison_bench, table_overturned, chandelier_fallen).
  Import helpers from those files; never edit a file that isn't yours.
- Dungeon materials (they must match the dungeon walls): small dungeons = root wood like the Delver's Shack
  (`tools/asset_forge/builds/shack_v2.py`, `dungeon_rootwood.py`, `dungeon_mine.py`, `dungeon_pell.py`: hewn logs, split
  boards, wooden pegs, shack textures `shackbark/shackplank/shackstone/shackdark`); medium = cut stone like Stonehold
  (`stonehold_v2.py`, textures greystone/basalt/limestone); big = clay brick and fire like Hearthbrick
  (`hearthbrick_v2.py`, textures brick/brickochre/clay, copper, iron, ember glow).
- Dwarf scale: a dwarf is ~1.3 m tall, a door 1.5 m. Origin bottom-centre, front faces -Y, wall pieces flat back at +Y.
- Output: `assets/models/decor/<id>.glb` + preview `journey/3d/v2_hand_built/decor/<id>.png`, tex_size=256,
  print MODEL_OK/MODEL_FAILED. Your ids all start with your set's prefix, so nobody clashes.

## Ready-made helpers that pass the checker (import them)
- `decor_nov21_a.py`: `carve` (cut a shape INTO a part), `groove`, `groove_path`, `groove_ring`, `rune_row`, `chip`,
  `tube`, `loft_x`, `rest`, `spin`, `rubble_heap` (settled angular stone heap), `GROOVE_M`, `turn`, `prism`.
- `decor_nov21_f.py`: `lathe` (hollow round cups/bowls/pots), `group`, `toothed_gear`, `place_glb` (put one of the
  game's own models inside yours, e.g. assets/models/cave/fern.glb, glowcap.glb), `tint`, `glass`, `FLAME`.

## Lessons from the first night (other helpers hit these)
- Press parts ~5 mm into each other instead of resting face-on-face: night_decor's `stone_blocks` and `rail_track`
  can fail the checker (shimmer, or "not touching").
- Setting `rotation_euler` on kit gems/spheres can rotate around the wrong point: use a group/turn helper (see
  `decor_nov21_f.py` `group()` or `decor_nov21_a.py` `turn`).
- `floor_cut()` after dropping loose rocks next to a lying model makes shimmer: rest rocks on the floor instead.
- Thin flat strands (webs, cracks) overlapping in one plane shimmer: keep them apart or on different depths.
- Plain colours `C()` render lighter than their numbers: pick darker values.
- Use unique names for scratch files (many helpers share the scratchpad).

## Workflow
1. Write your item list (id + one line) as a comment block at the top of your file FIRST.
2. Build in batches: `blender --background --factory-startup --python tools/asset_forge/builds/<your_file>.py -- id1 id2 ...`
3. Check: `blender --background --factory-startup --python tools/model_check/check_models.py -- decor/id1 decor/id2 ...`
   Fix every FLOAT and SHIMMER.
4. Look at each preview (Read tool) against the taste list above: detailed enough? anything poking out? colours
   one family? At most 2 look-and-fix rounds per model, then keep the best and note it.
5. No src/, pieces.gd, CREDITS.md, git commits. No picture-to-3D. Never copy other games' designs.
6. Final report (short): id | ok / ok with note / failed | one line. Plus total made.
