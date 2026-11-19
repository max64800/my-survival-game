# #6 The Quiet Barrows

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

Rings of small burial rooms around a deep spiral stair. Each level down is older and darker.

| | |
|---|---|
| Size | medium, 20 spaces, 3 level(s), 12-15 min |
| Built from | Stonehold stone (`cut_stone`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 5 m in rooms, more in tall halls |
| Teaches one of | Copper Helm, Copper Mail, Copper Greaves, Copper Shield, Copper Sword (shuffled per world) |
| Way out | A rope up the old Air Shaft takes you straight back to the Barrow Door. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Barrow Door | Level 1 | 8 x 8 | Entrance: a low round door under a mossy mound of stone. |  |
| 2 | Long Barrow (corridor) | Level 1 | 4 x 12 | A long low tunnel with darts from the wall. Clue: rows of small holes. Safe: the darts fire in bursts; run in the gap, or hold up a shield. | trap: dart wall |
| 3 | First Ring | Level 1 | 12 x 12 | Burial rooms round the stair. Bone Thralls. | mob: thralls; loot: chest |
| 4 | Barrow of the Smith | Level 1 | 8 x 8 | A loose floor stone hides a buried chest. | hid: buried chest |
| 5 | Barrow of the Hunter | Level 1 | 8 x 8 | Grave Creepers wait in the dark. | mob: creepers |
| 6 | Spiral Stair (corridor) | Level 1 | 4 x 8 stair, 8 m between levels | Down round the shaft. Loose ceiling stones fall. Clue: cracks and trickling dust. Safe: shoot them down with a crossbow first, or run through fast. | trap: falling stones |
| 7 | Second Ring | Level 2 (8 m down) | 12 x 12 | Bone Wardens. The gate down is locked: it needs the Barrow Key. | mob: wardens |
| 8 | Barrow of the Twins | Level 2 (8 m down) | 8 x 8 | Two coffins and a chest. The back wall is cracked. | loot: chest; hid: cracked wall |
| 9 | Twins' Vault | Level 2 (8 m down) | 4 x 4 | Behind the cracked wall. Gold and a chance of a gem. | loot: vault chest |
| 10 | Keeper's Corridor (corridor) | Level 2 (8 m down) | 4 x 12 | Floor plates fire darts. Clue: a cracked floor plate. Safe: step round it, or shoot or throw something onto it to use it up. | trap: dart plate |
| 11 | Keeper's Barrow | Level 2 (8 m down) | 12 x 12 | The Barrow Keeper, a big Rune Caller, holds the Barrow Key. | boss: Barrow Keeper; key: Barrow Key |
| 12 | Sunken Barrow | Level 2 (8 m down) | 12 x 12 | The floor gives way into a spike pit. A chest sits on the far side. Clue: cracked floor tiles. Safe: keep to the solid edge along the wall. | **deadly: pit + spikes**; loot: chest |
| 13 | Shrine of Rest | Level 2 (8 m down) | 8 x 8 | A healing shrine. | heal: healing shrine |
| 14 | Deep Stair (corridor) | Level 2 (8 m down) | 4 x 8 stair, 8 m between levels | Behind the locked gate, down to the oldest barrows. | lock: locked gate |
| 15 | Hall of Bones | Level 3 (16 m down) | 12 x 12 | Grave Creepers and Thralls together. | mob: creepers; mob: thralls |
| 16 | Ash Bridge | Level 3 (16 m down) | 4 x 14 (bridge), gap 10 deep | A narrow bridge over a chasm, spikes below. Clue: cracked slabs. Rune Callers shoot from the far side. Safe: step only on the whole slabs, along the railing side. | **deadly: chasm + spikes**; mob: rune callers |
| 17 | Crusher Gate (corridor) | Level 3 (16 m down) | 4 x 12 | A stone crusher in the doorway. Clue: a heavy thud and grooves in the floor. Safe: watch its rhythm and run while it rises. | trap: crusher |
| 18 | Mourning Niche | Level 3 (16 m down) | 4 x 4 | A boulder hides a niche with a chest. | hid: hidden boulder; loot: chest |
| 19 | First King's Barrow | Level 3 (16 m down) | 12 x 14 | The oldest grave. A pack with a big Warden leader. The recipe stand. | mob: pack + leader; page: recipe stand |
| 20 | Air Shaft (corridor) | Level 3 (16 m down) | 4 x 12 | An old air shaft with a rope: climb straight up to the Barrow Door. | out: climb to room 1 |

Paths: 1-2, 2-3, 3-4, 4-5, 3-6, 6-7, 7-8, 8-9, 7-10, 10-11, 11-12, 10-13, 7-14, 14-15, 15-16, 16-17, 15-18, 17-19, 19-20, 20 → 1 (way out).

## Creatures

- Bone Thrall: 2 room(s)
- Grave Creeper: 2 room(s)
- Bone Warden: 1 room(s)
- Barrow Keeper: 1 room(s)
- Rune Caller: 1 room(s)
- a pack with its leader (end fight): 1 room(s)

## Loot

- Side chest: 3-6 Rusty Scrap, 5-10 gold, 1-3 Bandages or 5 Stone Bolts, 30% a cooked food
- Hidden chest: 12-20 gold, 2-3 Copper Ingots, 30% a rune, 5% a gem
- Mini boss: drops the key, 5-10 gold
- Recipe stand + big chest: this dungeon's page, 20-30 gold, 25% an Old Blueprint the group doesn't know yet, 8% a gem
- Everything refills 1 hour of play after it was taken (DungeonLoot).

## 3D models it needs

| Model | Status | Note |
|---|---|---|
| Stonehold stone building pieces (walls, floors, round doorways, stairs, pillars, beams, railings, ladders) | exists | |
| dungeon_entrance (stone/brick version) | new | the round door in the cave wall |
| trap_dart_wall | exists |  |
| floor_loose_stone + chest | exists |  |
| trap_ceiling_stones | new | stone version of the drips: loose ceiling blocks |
| wall_cracked / wall_broken | exists |  |
| trap_dart_plate | exists |  |
| tr_key_copper / tr_key_iron (recoloured per key) | exists | key items are new code |
| trap_floor_break | exists |  |
| trap_spikes | exists |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| door_locked_round (stone/brick, with a keyhole) | new |  |
| bridge_stone_slab (+ cracked) | new | stone/brick bridge slabs that fall away |
| trap_crusher_stone | new | stone/brick frame for the crusher |
| cave boulder (Boulders.SHAPES) | exists |  |
| recipe_stand + recipe_scroll | exists |  |
| rope_ladder | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
