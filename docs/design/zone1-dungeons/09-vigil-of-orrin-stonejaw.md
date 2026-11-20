# #9 Vigil of Orrin Stonejaw

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

A temple of runes climbing up through the rock to a bell tower. The rune carvings glow, and Rune Callers fill it.

| | |
|---|---|
| Size | medium, 20 spaces, 3 level(s), 12-15 min |
| Built from | Stonehold stone (`cut_stone`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 5 m in rooms, more in tall halls |
| Teaches one of | Copper Helm, Copper Mail, Copper Greaves, Copper Shield, Copper Sword (shuffled per world) |
| Way out | A worn stone slide spirals down from Orrin's Vigil to the Pilgrims' Door. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Pilgrims' Door | Level 1 (entrance) | 8 x 8 | Entrance: a round door carved with glowing runes. |  |
| 2 | Hall of Pillars | Level 1 (entrance) | 12 x 12 | Bone Thralls. Darts from holes between the pillars. Clue: rows of small holes. Safe: the darts fire in bursts; run in the gap, or hold up a shield. | mob: thralls; trap: dart wall |
| 3 | Robing Room | Level 1 (entrance) | 8 x 8 | Old robes. A loose floor stone hides a buried chest. | loot: chest; hid: buried chest |
| 4 | First Stair (corridor) | Level 1 (entrance) | 4 x 8 stair, 8 m between levels | Up. Loose ceiling stones fall. Clue: cracks and trickling dust. Safe: shoot them down with a crossbow first, or run through fast. | trap: falling stones |
| 5 | Rune Gallery | Level 2 (rune halls) | 12 x 12 | Glowing carvings. Rune Callers; floor plates fire darts. Clue: a cracked floor plate. Safe: step round it, or shoot or throw something onto it to use it up. | mob: rune callers; trap: dart plate |
| 6 | Carvers' Workshop | Level 2 (rune halls) | 12 x 12 | Half-carved runes and a chest. One wall is cracked. | loot: chest; hid: cracked wall |
| 7 | Carvers' Vault | Level 2 (rune halls) | 4 x 4 | Behind the cracked wall. Gold, maybe a rune. | loot: vault chest |
| 8 | Acolytes' Cells (corridor) | Level 2 (rune halls) | 4 x 12 | Grave Creepers in the small cells. | mob: creepers |
| 9 | Hall of Echoes | Level 2 (rune halls) | 12 x 12 | Giant bells with sharp rims swing across the hall like pendulums. Clue: they ring before each swing, deep cuts in the floor. Safe: time the gaps, or shoot a bell's rope. | **deadly: bell pendulums** |
| 10 | Acolyte's Sanctum | Level 2 (rune halls) | 8 x 8 | Orrin's Last Acolyte, a big Rune Caller, holds the Rune Key. | boss: Last Acolyte; key: Rune Key |
| 11 | Quiet Shrine | Level 2 (rune halls) | 8 x 8 | A healing shrine. | heal: healing shrine |
| 12 | Rune Door | Level 2 (rune halls) | 8 x 8 | A stone door that opens only to the Rune Key. | lock: rune door |
| 13 | Tower Stair (corridor) | Level 3 (bell tower) | 4 x 8 stair, 8 m between levels | Up into the bell tower. |  |
| 14 | Bell Walk | Level 3 (bell tower) | 8 x 8 | Bone Wardens on the walkway. | mob: wardens |
| 15 | Broken Bridge | Level 3 (bell tower) | 4 x 14 (bridge), gap 10 deep | A narrow bridge. At its far end spears stab out of the wall. Clue: rows of holes, a rusty tip. Safe: crawl low, or go when they pull back. | trap: spear wall |
| 16 | Crusher Steps (corridor) | Level 3 (bell tower) | 4 x 12 | A great stone crusher slams down on the stairs. Clue: a heavy thud and a flattened step. Safe: step on its plate, jump back, and run under while it rises. | **deadly: great crusher** |
| 17 | Bellringer's Loft | Level 3 (bell tower) | 4 x 4 | A boulder hides the bellringer's chest, on spike holes. Clue: holes in the floor. Safe: shoot the chest first. | hid: hidden boulder; loot: chest; trap: trapped chest |
| 18 | Antechamber | Level 3 (bell tower) | 8 x 8 | Bone Thralls and Rune Callers. | mob: thralls; mob: rune callers |
| 19 | Orrin's Vigil | Level 3 (bell tower) | 12 x 14 | Under the great bell: Orrin's guard and their leader. The recipe stand. | mob: pack + leader; page: recipe stand |
| 20 | Pilgrims' Slide (corridor) | Level 3 (bell tower) | 4 x 12 | A worn stone slide spirals down to the Pilgrims' Door. | out: slide to room 1 |

Paths: 1-2, 2-3, 2-4, 4-5, 5-8, 8-6, 6-7, 8-9, 9-10, 10-11, 10-12, 12-13, 13-14, 14-15, 15-17, 15-16, 16-18, 18-19, 19-20, 20 → 1 (way out).

## Creatures

- Bone Thrall: 2 room(s)
- Rune Caller: 2 room(s)
- Grave Creeper: 1 room(s)
- Last Acolyte: 1 room(s)
- Bone Warden: 1 room(s)
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
| trap_dart_plate | exists |  |
| wall_cracked / wall_broken | exists |  |
| trap_bell_pendulum | new |  |
| tr_key_copper / tr_key_iron (recoloured per key) | exists | key items are new code |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| door_locked_round (stone/brick, with a keyhole) | new |  |
| trap_spear_wall (iron spears) | new |  |
| trap_crusher_great | new | bigger crusher that kills outright |
| cave boulder (Boulders.SHAPES) | exists |  |
| floor_spike_holes | new | shoot the chest first: the spikes fire and pull back |
| trap_spikes | exists |  |
| recipe_stand + recipe_scroll | exists |  |
| stone slide (building pieces) | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
