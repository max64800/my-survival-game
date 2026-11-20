# #3 Old Pell's Diggings

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

A miner's hut at the top, then a shaft straight down into what he dug out below. This one is about going down.

| | |
|---|---|
| Size | small, 13 spaces, 2 level(s), 8-10 min |
| Built from | root wood (Delver's Shack pieces, `plank_root`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 4 m in rooms, more in tall halls |
| Teaches one of | Copper Axe, Crossbow, Spear, Copper-shod Boots (shuffled per world) |
| Way out | A rope lift in Pell's Last Dig pulls you up to the barred gate in Pell's Hut. A lever opens it from inside. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Pell's Hut | Level 1 (hut) | 6 x 6 | Entrance. Bed, table, a chest, a trapdoor in the floor. On the right, a barred gate with no handle on this side: the way out, opened later from the far side. | loot: chest; gate: exit gate (lever on the far side) |
| 2 | Winch Shed | Level 1 (hut) | 6 x 6 | Over the shaft. A thin wire fires a hidden crossbow. Clue: a shiny wire at ankle height. Safe: step over it, or cut it. | trap: tripwire crossbow |
| 3 | Pantry | Level 1 (hut) | 4 x 4 | Shelves of old jars. The back wall is cracked: Pell's stash is behind it. | hid: cracked wall; loot: stash |
| 4 | The Shaft (corridor) | Level 2 (6 m down) | 2 x 2 shaft, 7 m between levels | A long ladder down, with Tunnel Rats in the side holes. | mob: tunnel rats |
| 5 | Ladder Landing | Level 2 (6 m down) | 6 x 6 | The bottom of the shaft, thick with webs; Tunnel Rats. | mob: tunnel rats |
| 6 | Cave-in Tunnel (corridor) | Level 2 (6 m down) | 2 x 10 | Half fallen in. Sharp wooden stakes stab out of the wall and pull back. Clue: rows of holes, a stake tip poking out. Safe: crawl low, or go when they pull back. | trap: spear wall |
| 7 | Sorting Room | Level 2 (6 m down) | 6 x 6 | Old ore tables and a chest. Lost Miners still sorting ore. A cracked plate fires darts and bear jaws hide under the dust. Clue: a cracked floor plate, a rusty glint. Safe: step round them; shoot something onto the plate to use it up. | trap: dart plate; trap: bear jaws; loot: chest; mob: lost miners |
| 8 | Spoil Tunnel (corridor) | Level 2 (6 m down) | 2 x 10 | A side tunnel where they dumped the rubble. |  |
| 9 | Spider Den | Level 2 (6 m down) | 6 x 6 | Webs and a Tunnel Rat pack (or spiders, your call). A loose floor stone hides a buried chest. | mob: tunnel rat pack; hid: buried chest |
| 10 | Rotten Gallery | Level 2 (6 m down) | 10 x 8 | A wall block slams out and shoves you onto rotten boards over a spike pit. Clue: scrape marks on the floor and a gap round the block. Safe: walk along the block's own wall, or step on its plate and jump back to set it off. | **deadly: push wall + pit + spikes** |
| 11 | Deep Seam (corridor) | Level 2 (6 m down) | 2 x 10 | A narrow seam with a crusher. Clue: a heavy thud and grooves in the floor. Safe: watch its rhythm and run while it rises. | trap: crusher |
| 12 | Miner's Shrine | Level 2 (6 m down) | 6 x 6 | A healing shrine. A boulder in the wall hides a niche with a chest. | heal: healing shrine; hid: hidden boulder |
| 13 | Pell's Last Dig | Level 2 (6 m down) | 10 x 10 | The Foreman and his Lost Miners. The recipe stand. A rope lift pulls you up to the barred gate in Pell's Hut: pull the lever to open it. | mob: Foreman + miners; page: recipe stand; out: rope lift to room 1 |

Paths: 1-2, 2-3, 2-4, 4-5, 5-6, 6-7, 7-8, 8-9, 7-10, 10-11, 11-12, 11-13, 13 → 1 (way out).

## Creatures

- Tunnel Rat: 2 room(s)
- Lost Miner: 1 room(s)
- Tunnel Rat pack: 1 room(s)
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
| gate_round + lever (exit gate: lever only on the inside) | exists |  |
| trap_tripwire_crossbow (crossbow + wire + peg) | new |  |
| wall_cracked / wall_broken | exists |  |
| trap_spear_wall (wooden stakes) | new |  |
| trap_dart_plate | exists |  |
| trap_bear_jaw (open + shut) | new |  |
| floor_loose_stone + chest | exists |  |
| trap_floor_break | exists |  |
| trap_spikes | exists |  |
| trap_push_wall (wood) + floor scrape | new |  |
| trap_crusher | exists |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| cave boulder (Boulders.SHAPES) | exists |  |
| recipe_stand + recipe_scroll | exists |  |
| lift platform + winch | new |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
