# #2 Lampwick Drift

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
| 2 | Rail Tunnel (corridor) | Level 1 | 2 x 10 | Long and narrow. A thin wire across the floor fires a hidden crossbow. Clue: a shiny wire at ankle height. Safe: step over it, or cut it. | trap: tripwire crossbow |
| 3 | Cart Junction | Level 1 | 6 x 6 | Three rails side by side, sloping down. Carts come rattling down each rail at different times in a pattern: dodge the middle one, step into the middle to dodge the left one, stay there for the right one. A hit throws you like a rag doll. Clue: each rail rattles just before its cart. Safe: learn the pattern and stand in the empty lane. | mob: tunnel rats; **deadly: triple carts** |
| 4 | Tool Store | Level 1 | 6 x 6 | Side room. One floor stone is loose: a buried chest under it. | loot: chest; hid: buried chest |
| 5 | Drip Tunnel (corridor) | Level 1 | 2 x 10 | Stalactites hang low and fall when you walk under them. Clue: cracks and trickling dust. Safe: shoot them down with a crossbow first, or run through fast. | trap: falling stalactites; mob: tunnel rats |
| 6 | Bat Gallery | Level 1 | 10 x 8 | Tall and dark, Tunnel Rats in the dark. One wall is cracked. | mob: tunnel rats |
| 7 | Hidden Vault | Level 1 | 4 x 4 | Behind the cracked wall. The chest sits on spike holes. Clue: holes in the floor round it. Safe: shoot the chest with a crossbow: the spikes fire and pull back, then open it. | hid: cracked wall; loot: vault chest; trap: trapped chest |
| 8 | The Old Shaft | Level 1 | 6 x 6 | A plank walk with railings over a deep shaft. A boulder on a chain swings across it and knocks you back. Clue: grooves on the planks and a creaking chain. Safe: time it, or shoot the chain. | trap: swinging boulder |
| 9 | Old Copper Face | Level 1 | 6 x 6 | Where they last dug. Lost Miners. Bear jaw traps in the rubble grab your leg. Clue: a rusty glint in the dust. Safe: look down; a friend can pry it open. One boulder in the wall hides a niche with a chest. | mob: lost miners; trap: bear jaws; hid: hidden boulder |
| 10 | Prop Corridor (corridor) | Level 1 | 2 x 10 | Old props hold up the roof. Tunnel Rats in the dark. | mob: tunnel rats |
| 11 | Miners' Rest | Level 1 | 6 x 6 | Side room with a healing shrine and a chest. | heal: healing shrine; loot: chest |
| 12 | Foreman's Office | Level 1 | 10 x 10 | The Foreman and his Lost Miners. The recipe stand. | mob: Foreman + miners; page: recipe stand |
| 13 | Back Rails (corridor) | Level 1 | 2 x 10 | A lever opens a gate onto rails that run back to the Lamp Room. | out: gate to room 1 |

Paths: 1-2, 2-3, 3-4, 3-5, 5-6, 6-7, 6-8, 8-9, 9-10, 10-11, 10-12, 12-13, 13 → 1 (way out).

## Creatures

- Tunnel Rat: 4 room(s)
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
| trap_tripwire_crossbow (crossbow + wire + peg) | new |  |
| mine_cart | exists |  |
| rail_lanes_3 + cart_stop + cart_release | new | 3 rails side by side, carts in a pattern; ragdoll on hit |
| floor_loose_stone + chest | exists |  |
| trap_drip_thin / trap_drip_fat / trap_drip_cluster | exists |  |
| wall_cracked / wall_broken | exists |  |
| floor_spike_holes | new | shoot the chest first: the spikes fire and pull back |
| trap_spikes | exists |  |
| trap_swing_boulder (+ beam/arch hook) | new | ragdoll on hit |
| trap_bear_jaw (open + shut) | new |  |
| cave boulder (Boulders.SHAPES) | exists |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| recipe_stand + recipe_scroll | exists |  |
| gate_round + lever | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
