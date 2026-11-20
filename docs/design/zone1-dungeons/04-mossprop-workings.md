# #4 Mossprop Workings

> **Traps changed Nov 20:** see [traps-and-variety.md](traps-and-variety.md). It wins over the trap notes below.

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

Wooden walkways and ladders bolted up the wall of one tall cave. This one is about climbing, with a long drop always beside you.

| | |
|---|---|
| Size | small, 14 spaces, 3 level(s), 8-10 min |
| Built from | root wood (Delver's Shack pieces, `plank_root`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 4 m in rooms, more in tall halls |
| Teaches one of | Copper Axe, Crossbow, Spear, Copper-shod Boots (shuffled per world) |
| Way out | From the Top Hall, a rope slide takes you straight down onto Base Camp. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Base Camp | Level 1 (cave floor) | 6 x 6 | Entrance. An old tent and a chest at the foot of the cliff. | loot: chest |
| 2 | Lower Walkway (corridor) | Level 1 (cave floor) | 2 x 10 | A broken railing. Lost Miners shove you off: a short fall, not deadly. | mob: lost miners |
| 3 | Rockfall Ledge | Level 1 (cave floor) | 6 x 6 | Stalactites fall when you step onto the ledge. A ladder goes up. Clue: cracks and trickling dust. Safe: shoot them down with a crossbow first, or run through fast. | trap: falling stalactites |
| 4 | Tool Niche | Level 1 (cave floor) | 4 x 4 | Behind a boulder at the foot of the ladder: a chest of old tools. | hid: hidden boulder; loot: chest |
| 5 | Prop Room | Level 2 (5 m up) | 6 x 6 | Inside the cliff, behind the props. Darts from holes in the wall. Clue: rows of small holes. Safe: the darts fire in bursts; run in the gap, or hold up a shield. | trap: dart wall |
| 6 | Store Shed | Level 2 (5 m up) | 6 x 6 | Supplies and a chest. One wall is cracked. | loot: chest |
| 7 | Hidden Vault | Level 2 (5 m up) | 4 x 4 | Behind the Store Shed's cracked wall. Gold and a chance of a gem. | hid: cracked wall; loot: vault chest |
| 8 | Plank Bridge | Level 2 (5 m up) | 4 x 14 (bridge), gap 10 deep | Across the chasm. Cracked planks break, and the spikes far below mean instant death. Lost Miners wait on the far side. Safe: step only on the whole slabs, along the railing side. | **deadly: chasm + spikes**; mob: lost miners |
| 9 | Far Ledge (corridor) | Level 2 (5 m up) | 4 x 8 stair, 7 m between levels | A thin ledge. A cracked plate fires darts at you. Clue: a cracked floor plate. Safe: step round it, or shoot or throw something onto it to use it up. | trap: dart plate |
| 10 | Climbers' Rest | Level 2 (5 m up) | 6 x 6 | A healing shrine before the top. | heal: healing shrine |
| 11 | Upper Ladder (corridor) | Level 3 (10 m up) | 2 x 2 shaft, 7 m between levels | The last long climb. |  |
| 12 | Crusher Gallery (corridor) | Level 3 (10 m up) | 2 x 10 | A narrow passage with a crusher. Clue: a heavy thud and grooves in the floor. Safe: watch its rhythm and run while it rises. | trap: crusher |
| 13 | Bat Roost | Level 3 (10 m up) | 6 x 6 | Side cave full of Tunnel Rats. A loose floor stone hides a buried chest. | mob: tunnel rats; hid: buried chest |
| 14 | Top Hall | Level 3 (10 m up) | 10 x 10 | Tunnel Rats, then the Foreman and his Lost Miners. The recipe stand. | mob: Foreman + miners; page: recipe stand; out: rope slide to room 1 |

Paths: 1-2, 2-3, 3-4, 3-5, 5-6, 6-7, 5-8, 8-9, 9-10, 9-11, 11-12, 12-13, 12-14, 14 → 1 (way out).

## Creatures

- Lost Miner: 2 room(s)
- Tunnel Rat: 1 room(s)
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
| trap_drip_thin / trap_drip_fat / trap_drip_cluster | exists |  |
| cave boulder (Boulders.SHAPES) | exists |  |
| trap_dart_wall | exists |  |
| wall_cracked / wall_broken | exists |  |
| bridge_plank / bridge_plank_broken / bridge_posts | exists |  |
| trap_spikes | exists |  |
| trap_dart_plate | exists |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| trap_crusher | exists |  |
| floor_loose_stone + chest | exists |  |
| recipe_stand + recipe_scroll | exists |  |
| rope slide | new |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
