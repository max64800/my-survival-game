# #2 Lampwick Drift

> **Traps changed Nov 20:** see [traps-and-variety.md](traps-and-variety.md). It wins over the trap notes below.

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

A long, dark mine tunnel. Old lamps hang along it, and you light them as you go, so the way you came glows behind you.

| | |
|---|---|
| Size | small, 13 spaces, 1 level(s), 8-10 min |
| Built from | root wood (Delver's Shack pieces, `plank_root`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 4 m in rooms, more in tall halls |
| Teaches one of | Copper Axe, Crossbow, Spear, Copper-shod Boots (shuffled per world) |
| Way out | The lever in Back Rails opens a gate, and the rails run you back into the Lamp Room. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Lamp Room | Level 1 | 6 x 6 | Entrance. A rail cart on old tracks, the first lamp to light. | loot: chest |
| 2 | Rail Tunnel (corridor) | Level 1 | 2 x 10 | Long and narrow. Holes in the wall shoot darts as you pass. Clue: rows of small holes. Safe: the darts fire in bursts; run in the gap, or hold up a shield. | trap: dart wall |
| 3 | Cart Junction | Level 1 | 6 x 6 | The rails split. A runaway cart comes rattling down the main track. Clue: the rails rattle first. Safe: step onto the side track to the tool store. | mob: tunnel rats; trap: runaway cart |
| 4 | Tool Store | Level 1 | 6 x 6 | Side room. One floor stone is loose: a buried chest under it. | loot: chest; hid: buried chest |
| 5 | Drip Tunnel (corridor) | Level 1 | 2 x 10 | Stalactites hang low and fall when you walk under them. Clue: cracks and trickling dust. Safe: shoot them down with a crossbow first, or run through fast. | trap: falling stalactites; mob: tunnel rats |
| 6 | Bat Gallery | Level 1 | 10 x 8 | Tall and dark, Tunnel Rats in the dark. One wall is cracked. | mob: tunnel rats |
| 7 | Hidden Vault | Level 1 | 4 x 4 | Behind the cracked wall: break it to get in. Gold and a chance of a gem. | hid: cracked wall; loot: vault chest |
| 8 | The Old Shaft | Level 1 | 6 x 6 | Rotten boards over a deep shaft full of spikes. Cracked boards and a creak warn you. Walk the edge beam. Safe: keep to the solid edge along the wall. | **deadly: shaft + spikes** |
| 9 | Old Copper Face | Level 1 | 6 x 6 | Where they last dug. Lost Miners. One boulder in the wall hides a niche with a chest. | mob: lost miners; hid: hidden boulder |
| 10 | Prop Corridor (corridor) | Level 1 | 2 x 10 | Old props hold up a crusher. Watch its rhythm, then run. Clue: a heavy thud and grooves in the floor. Safe: watch its rhythm and run while it rises. | trap: crusher |
| 11 | Miners' Rest | Level 1 | 6 x 6 | Side room with a healing shrine and a chest. | heal: healing shrine; loot: chest |
| 12 | Foreman's Office | Level 1 | 10 x 10 | The Foreman and his Lost Miners. The recipe stand. | mob: Foreman + miners; page: recipe stand |
| 13 | Back Rails (corridor) | Level 1 | 2 x 10 | A lever opens a gate onto rails that run back to the Lamp Room. | out: gate to room 1 |

Paths: 1-2, 2-3, 3-4, 3-5, 5-6, 6-7, 6-8, 8-9, 9-10, 10-11, 10-12, 12-13, 13 → 1 (way out).

## Creatures

- Tunnel Rat: 3 room(s)
- Lost Miner: 1 room(s)
- the Foreman with his Lost Miners (end fight): 1 room(s)

## Loot

- Side chest: 2-5 Rusty Scrap, 3-8 gold, 1-3 rope or 2 Crystal Torches, 30% a cooked food
- Hidden chest (vault, buried, niche): 8-15 gold, 1-2 Copper Ingots, 20% a rune, 3% a gem
- Recipe stand: this dungeon's page (always the same recipe), 10-20 gold
- Everything refills 1 hour of play after it was taken (DungeonLoot).

## 3D models it needs

| Model | Status | Note |
|---|---|---|
| root wood building pieces (walls, floors, round doorways, stairs, pillars, beams, railings, ladders) | exists | |
| dungeon_entrance | exists | the round door in the cave wall |
| trap_dart_wall | exists |  |
| mine_cart | exists |  |
| rail_track | exists |  |
| floor_loose_stone + chest | exists |  |
| trap_drip_thin / trap_drip_fat / trap_drip_cluster | exists |  |
| wall_cracked / wall_broken | exists |  |
| trap_floor_break | exists |  |
| trap_spikes | exists |  |
| cave boulder (Boulders.SHAPES) | exists |  |
| trap_crusher | exists |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| recipe_stand + recipe_scroll | exists |  |
| gate_round + lever | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
