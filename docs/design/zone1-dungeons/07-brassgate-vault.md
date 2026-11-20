# #7 Brassgate Vault

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

The old dwarf treasury: a toll hall and counting rooms on top, a mint below, and the strongroom behind a door only the Vault Captain's key opens.

| | |
|---|---|
| Size | medium, 20 spaces, 2 level(s), 12-15 min |
| Built from | Stonehold stone (`cut_stone`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 5 m in rooms, more in tall halls |
| Teaches one of | Copper Helm, Copper Mail, Copper Greaves, Copper Shield, Copper Sword (shuffled per world) |
| Way out | A hidden lever in the Strongroom opens the guards' bolt-hole back to the Brass Gate. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Brass Gate | Level 1 (toll halls) | 8 x 8 | Entrance: a round door with a big brass lock face. |  |
| 2 | Toll Hall | Level 1 (toll halls) | 12 x 12 | Where traders paid. Bone Wardens still stand guard. | mob: wardens; loot: chest |
| 3 | Counting Room | Level 1 (toll halls) | 8 x 8 | Old desks. A loose floor stone hides a buried chest. | loot: chest; hid: buried chest |
| 4 | Guard Corridor (corridor) | Level 1 (toll halls) | 4 x 12 | A thin wire fires a crossbow from a guard slot. Clue: a shiny wire at ankle height. Safe: step over it, or cut it. | trap: tripwire crossbow |
| 5 | Weighing Hall | Level 1 (toll halls) | 12 x 12 | Big scales. Floor plates fire darts. Grave Creepers. Clue: a cracked floor plate. Safe: step round it, or shoot or throw something onto it to use it up. | trap: dart plate; mob: creepers |
| 6 | Clerks' Rooms | Level 1 (toll halls) | 8 x 8 | Bone Thralls. One wall is cracked. | mob: thralls; hid: cracked wall |
| 7 | Clerk's Hoard | Level 1 (toll halls) | 4 x 4 | Behind the cracked wall: a clerk's stolen coins. | loot: vault chest |
| 8 | Strongroom Door | Level 1 (toll halls) | 8 x 8 | A huge round door, locked: it needs the Vault Key. | lock: locked door |
| 9 | Mint Stair (corridor) | Level 1 (toll halls) | 4 x 8 stair, 8 m between levels | Down to the mint. |  |
| 10 | Old Mint | Level 2 (the mint) | 12 x 12 | Cold furnaces and coin moulds. Rune Callers. | mob: rune callers |
| 11 | Workers' Hall | Level 2 (the mint) | 12 x 12 | Bone Thralls at their benches. A coin press stamps down in a rhythm. Clue: the thud and grooves in the floor. Safe: run while it rises. | mob: thralls; loot: chest; trap: crusher |
| 12 | Coin Chute (corridor) | Level 2 (the mint) | 4 x 12 | Where coins slid down to the mint. A wall block slams out and shoves you into the chute, with spikes at the bottom. Clue: scrape marks, a gap round the block. Safe: walk along the block's own wall, or step on its plate and jump back. | **deadly: push wall + chute + spikes** |
| 13 | Captain's Quarters | Level 2 (the mint) | 8 x 8 | The Vault Captain holds the key. A portcullis slams down behind you. Clue: gate grooves in the doorway. Safe: wedge it with a rock, or win the fight. | boss: Vault Captain; key: Vault Key; trap: portcullis |
| 14 | Guard Shrine | Level 2 (the mint) | 8 x 8 | A healing shrine. | heal: healing shrine |
| 15 | Back Stair (corridor) | Level 1 (toll halls) | 4 x 8 stair, 8 m between levels | A guards' stair back up to the Strongroom Door. |  |
| 16 | Pendulum Hall | Level 1 (toll halls) | 12 x 12 | Big blades swing side to side across the hall. Clue: a whoosh and deep cuts in the walls. Safe: time the gaps, or shoot a blade's rope. | **deadly: pendulum blades** |
| 17 | Treasury Corridor (corridor) | Level 1 (toll halls) | 4 x 12 | Two chests in wall niches, both on spike holes. Clue: holes in the floor. Safe: shoot each chest first: the spikes fire and pull back. | loot: 2 chests; trap: trapped chest |
| 18 | Forgotten Alcove | Level 1 (toll halls) | 4 x 4 | A boulder hides a niche with a chest. | hid: hidden boulder; loot: chest |
| 19 | The Strongroom | Level 1 (toll halls) | 12 x 14 | The vault's last guards and their leader. The recipe stand and the big chest. | mob: pack + leader; page: recipe stand; loot: big chest |
| 20 | Bolt-hole (corridor) | Level 1 (toll halls) | 4 x 12 | A hidden lever opens the guards' escape tunnel back to the Brass Gate. | hid: secret lever; out: tunnel to room 1 |

Paths: 1-2, 2-3, 2-4, 4-5, 5-6, 6-7, 5-8, 4-9, 9-10, 10-11, 11-12, 12-13, 13-14, 14-15, 15-8, 8-16, 16-17, 17-18, 17-19, 19-20, 20 → 1 (way out).

## Creatures

- Bone Warden: 1 room(s)
- Grave Creeper: 1 room(s)
- Bone Thrall: 2 room(s)
- Rune Caller: 1 room(s)
- Vault Captain: 1 room(s)
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
| trap_tripwire_crossbow (crossbow + wire + peg) | new |  |
| trap_dart_plate | exists |  |
| wall_cracked / wall_broken | exists |  |
| door_locked_round (stone/brick, with a keyhole) | new |  |
| trap_crusher_stone | new | stone/brick frame for the crusher |
| trap_floor_break | exists |  |
| trap_spikes | exists |  |
| trap_push_wall (stone/brick) + floor scrape | new |  |
| tr_key_copper / tr_key_iron (recoloured per key) | exists | key items are new code |
| portcullis (stone/brick frame) | new |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| trap_pendulum_blade + ceiling slot | new |  |
| floor_spike_holes | new | shoot the chest first: the spikes fire and pull back |
| cave boulder (Boulders.SHAPES) | exists |  |
| recipe_stand + recipe_scroll | exists |  |
| lever | exists |  |
| lever + hidden door (wall piece) | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
