# #8 Hall of the Shieldbearers

> **Traps changed Nov 20:** see [traps-and-variety.md](traps-and-variety.md). It wins over the trap notes below.

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

An old barracks where the shield wall soldiers lived and trained. Lots of fighting, and the training traps are still armed.

| | |
|---|---|
| Size | medium, 20 spaces, 2 level(s), 12-15 min |
| Built from | Stonehold stone (`cut_stone`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 5 m in rooms, more in tall halls |
| Teaches one of | Copper Helm, Copper Mail, Copper Greaves, Copper Shield, Copper Sword (shuffled per world) |
| Way out | A hidden door in the Captain's Hall opens onto the soldiers' old way back to the Muster Gate. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Muster Gate | Level 1 (barracks) | 8 x 8 | Entrance: a round door with two stone shield-bearers on guard. |  |
| 2 | Parade Ground | Level 1 (barracks) | 12 x 12 | A big open hall. Bone Wardens still drill here. | mob: wardens |
| 3 | Sentry Walk (corridor) | Level 1 (barracks) | 4 x 12 | A balcony above the parade ground. Rune Callers shoot down from it. | mob: rune callers |
| 4 | Mess Hall | Level 1 (barracks) | 12 x 12 | Long tables. Bone Thralls. | mob: thralls; loot: chest |
| 5 | Kitchens | Level 1 (barracks) | 8 x 8 | Old pots. A loose floor stone hides a buried chest. | loot: chest; hid: buried chest |
| 6 | Barracks Row (corridor) | Level 1 (barracks) | 4 x 12 | Darts from holes in the wall. Clue: rows of small holes. Safe: the darts fire in bursts; run in the gap, or hold up a shield. | trap: dart wall |
| 7 | Bunk Rooms | Level 1 (barracks) | 8 x 8 | Grave Creepers in the bunks. One wall is cracked. | mob: creepers; hid: cracked wall |
| 8 | Deserter's Stash | Level 1 (barracks) | 4 x 4 | Behind the cracked wall: what a deserter hid. | loot: vault chest |
| 9 | Training Yard | Level 1 (barracks) | 12 x 12 | The training plates still fire darts. Clue: a cracked floor plate. Safe: step round it, or shoot or throw something onto it to use it up. | trap: dart plate; mob: thralls |
| 10 | Armoury Door | Level 1 (barracks) | 8 x 8 | Locked: it needs the Armoury Key. | lock: locked door |
| 11 | Cellar Stair (corridor) | Level 1 (barracks) | 4 x 8 stair, 8 m between levels | Down to the drill cellars. |  |
| 12 | Drill Cellar | Level 2 (drill cellars) | 8 x 8 | Wardens and Thralls together. Loose ceiling stones fall. Clue: cracks and trickling dust. Safe: shoot them down with a crossbow first, or run through fast. | mob: wardens; mob: thralls; trap: falling stones |
| 13 | Practice Pit | Level 2 (drill cellars) | 8 x 8 | A training pit whose floor gives way onto spikes. Clue: cracked boards over the pit. Safe: keep to the solid edge along the wall. | **deadly: pit + spikes** |
| 14 | Sergeant's Quarters | Level 2 (drill cellars) | 8 x 8 | Sergeant Halfhelm, a huge Bone Warden, carries the Armoury Key. | boss: Sergeant Halfhelm; key: Armoury Key |
| 15 | Infirmary | Level 2 (drill cellars) | 8 x 8 | A healing shrine. | heal: healing shrine |
| 16 | Back Stair (corridor) | Level 1 (barracks) | 4 x 8 stair, 8 m between levels | Up to the Armoury Door. |  |
| 17 | Armoury | Level 1 (barracks) | 8 x 8 | Racks of old shields. A boulder hides a niche with a chest. | loot: chest; hid: hidden boulder |
| 18 | Shield Bridge | Level 1 (barracks) | 4 x 14 (bridge), gap 10 deep | A bridge over a chasm, spikes below. Cracked slabs fall away. Grave Creepers. Safe: step only on the whole slabs, along the railing side. | **deadly: chasm + spikes**; mob: creepers |
| 19 | Banner Hall (corridor) | Level 1 (barracks) | 4 x 12 | Old banners hide a stone crusher. Clue: a heavy thud and grooves in the floor. Safe: watch its rhythm and run while it rises. | trap: crusher |
| 20 | Captain's Hall | Level 1 (barracks) | 12 x 14 | The Shield Captain and his guard. The recipe stand. A hidden door leads home. | mob: pack + leader; page: recipe stand; out: hidden door |

Paths: 1-2, 2-3, 2-4, 4-5, 4-6, 6-7, 7-8, 6-9, 9-10, 9-11, 11-12, 12-13, 13-14, 14-15, 15-16, 16-10, 10-17, 17-18, 18-19, 19-20, 20 → 1 (way out).

## Creatures

- Bone Warden: 2 room(s)
- Rune Caller: 1 room(s)
- Bone Thrall: 3 room(s)
- Grave Creeper: 2 room(s)
- Sergeant Halfhelm: 1 room(s)
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
| floor_loose_stone + chest | exists |  |
| trap_dart_wall | exists |  |
| wall_cracked / wall_broken | exists |  |
| trap_dart_plate | exists |  |
| door_locked_round (stone/brick, with a keyhole) | new |  |
| trap_ceiling_stones | new | stone version of the drips: loose ceiling blocks |
| trap_floor_break | exists |  |
| trap_spikes | exists |  |
| tr_key_copper / tr_key_iron (recoloured per key) | exists | key items are new code |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| cave boulder (Boulders.SHAPES) | exists |  |
| bridge_stone_slab (+ cracked) | new | stone/brick bridge slabs that fall away |
| trap_crusher_stone | new | stone/brick frame for the crusher |
| recipe_stand + recipe_scroll | exists |  |
| lever + hidden door (wall piece) | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
