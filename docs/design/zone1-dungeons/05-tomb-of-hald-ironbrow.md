# #5 Tomb of Hald Ironbrow

> **Traps changed Nov 20:** see [traps-and-variety.md](traps-and-variety.md). It wins over the trap notes below.

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

A famous warrior's tomb, still guarded by the soldiers who swore to protect him. Upper halls for the mourners, deep burial halls below.

| | |
|---|---|
| Size | medium, 20 spaces, 2 level(s), 12-15 min |
| Built from | Stonehold stone (`cut_stone`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 5 m in rooms, more in tall halls |
| Teaches one of | Copper Helm, Copper Mail, Copper Greaves, Copper Shield, Copper Sword (shuffled per world) |
| Way out | A lever behind Hald's coffin opens a secret stair back up to the Mourners' Gate. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Mourners' Gate | Level 1 (mourners' halls) | 8 x 8 | Entrance: a round stone door carved with Hald's face. | loot: chest |
| 2 | Hall of Candles (corridor) | Level 1 (mourners' halls) | 4 x 12 | Holes between the candle niches shoot darts. Clue: rows of small holes. Safe: the darts fire in bursts; run in the gap, or hold up a shield. | trap: dart wall |
| 3 | Offering Room | Level 1 (mourners' halls) | 8 x 8 | Old gifts on stone tables. Bone Thralls. | mob: thralls; loot: chest |
| 4 | Scribe's Niche | Level 1 (mourners' halls) | 4 x 4 | A tiny room. A loose floor stone hides a buried chest. | hid: buried chest |
| 5 | Statue Corridor (corridor) | Level 1 (mourners' halls) | 4 x 12 | Loose ceiling stones fall when you walk under them. Clue: cracks and trickling dust. Safe: shoot them down with a crossbow first, or run through fast. | trap: falling stones |
| 6 | Wardens' Hall | Level 1 (mourners' halls) | 12 x 12 | Bone Wardens. A great door to the east is locked: it needs the Bronze Key. | mob: wardens |
| 7 | Ossuary | Level 1 (mourners' halls) | 8 x 8 | Walls of bones. Grave Creepers hide among them. One wall is cracked. | mob: creepers; hid: cracked wall |
| 8 | Broken Stair (corridor) | Level 1 (mourners' halls) | 4 x 12 | The steps give way into a spike pit. The cracked steps are the clue. Safe: keep to the solid edge along the wall. | **deadly: pit + spikes** |
| 9 | Key Chapel | Level 1 (mourners' halls) | 8 x 8 | Hald's Shield-Brother, a huge Bone Warden, guards the Bronze Key. | boss: Shield-Brother; key: Bronze Key |
| 10 | Grand Stair (corridor) | Level 1 (mourners' halls) | 4 x 8 stair, 8 m between levels | Behind the locked door. A wide stair down to the burial halls. | lock: locked door |
| 11 | Hall of Names | Level 2 (deep burial) | 12 x 12 | Every warrior's name carved in the walls. Rune Callers shoot from balconies; floor plates fire darts. Clue: a cracked floor plate. Safe: step round it, or shoot or throw something onto it to use it up. | mob: rune callers; trap: dart plate |
| 12 | Embalmers' Room | Level 2 (deep burial) | 8 x 8 | Old jars and tools. A boulder in the wall hides a niche with a chest. | hid: hidden boulder; loot: chest |
| 13 | Quiet Chapel | Level 2 (deep burial) | 8 x 8 | A healing shrine. | heal: healing shrine |
| 14 | Bridge of Oaths | Level 2 (deep burial) | 4 x 14 (bridge), gap 10 deep | A stone bridge over a chasm. Cracked slabs fall away; spikes far below. Grave Creepers. Safe: step only on the whole slabs, along the railing side. | **deadly: chasm + spikes**; mob: creepers |
| 15 | Crusher Hall (corridor) | Level 2 (deep burial) | 4 x 12 | A stone crusher. Watch its rhythm, then run. Clue: a heavy thud and grooves in the floor. Safe: watch its rhythm and run while it rises. | trap: crusher |
| 16 | Antechamber | Level 2 (deep burial) | 8 x 8 | Bone Wardens and Thralls stand in rows. | mob: wardens; mob: thralls |
| 17 | Hald's Tomb | Level 2 (deep burial) | 12 x 14 | Hald's Honour Guard (a big Warden) and his pack. The recipe stand and his coffin chest. | mob: pack + leader; page: recipe stand; loot: coffin chest |
| 18 | Secret Stair (corridor) | Level 2 (deep burial) | 4 x 12 | A lever behind the coffin opens a hidden stair up to the Mourners' Gate. | hid: secret lever; out: stair to room 1 |
| 19 | Grave Goods | Level 2 (deep burial) | 8 x 8 | Side store of burial gifts. | loot: chest |
| 20 | Collapsed Tunnel (corridor) | Level 2 (deep burial) | 4 x 12 | Half fallen in, with darts from the wall. Clue: rows of small holes. Safe: the darts fire in bursts; run in the gap, or hold up a shield. | trap: dart wall |

Paths: 1-2, 2-3, 3-4, 3-5, 5-6, 6-7, 7-8, 8-9, 6-10, 10-11, 11-12, 12-13, 11-14, 14-15, 15-16, 16-17, 15-19, 19-20, 17-18, 18 → 1 (way out).

## Creatures

- Bone Thrall: 2 room(s)
- Bone Warden: 2 room(s)
- Grave Creeper: 2 room(s)
- Shield-Brother: 1 room(s)
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
| trap_floor_break | exists |  |
| trap_spikes | exists |  |
| tr_key_copper / tr_key_iron (recoloured per key) | exists | key items are new code |
| door_locked_round (stone/brick, with a keyhole) | new |  |
| trap_dart_plate | exists |  |
| cave boulder (Boulders.SHAPES) | exists |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| bridge_stone_slab (+ cracked) | new | stone/brick bridge slabs that fall away |
| trap_crusher_stone | new | stone/brick frame for the crusher |
| recipe_stand + recipe_scroll | exists |  |
| lever | exists |  |
| lever + hidden door (wall piece) | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
