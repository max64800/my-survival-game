# #1 Mossgate Hold

*Built by the PC's dungeons chat (Nov 19). Its real files are on the PC: `src/world/dungeon_map.gd` (the rooms as 24
boxes on the 2 m grid), `blueprints/dungeons/mossgate_hold.json` (1,348 root wood pieces, 328 traps/doors/furniture,
24 creatures, 11 chests), `tools/dungeons/make_mossgate.py`. Decisions: `docs/decisions/2026-11-19-dungeons.md`.
This file is only a summary from the journal so the 12 can be compared; the PC's files win.*

| | |
|---|---|
| Size | small, 15 spaces (11 rooms, 4 corridors), about 84 x 56 m |
| Built from | root wood (Delver's Shack pieces) inside old dwarf stone (`Mat.DWARF`, can't be dug) |
| Teaches one of | Copper Axe, Crossbow, Spear, Copper-shod Boots (shuffled per world) |
| Way out | after the Loot Room, a one-way way out drops you back into the entrance room |

## Main path
Gate Hall → Pillar Hall (breaking floor over a 4 m spike pit) → Chasm Bridge (spikes, instant death, beetles around it)
→ hidden boulder (one of the cave boulders, 3x size, fills a 3 m tunnel) → Crusher Hall (5.5 m tall) → Pack Hall
(a big pack with a 1.5x leader) → Loot Room (recipe stand + glowing scroll) → Way Out.
Side wings: most random chests, a hidden vault behind a cracked wall, a buried chest, a healing shrine. Room 9 is a tall
natural cave with a stalactite ceiling (falling stalactites, 50 HP, a crossbow can shoot them down first).

## Models (all exist, `assets/models/dungeon/`)
trap_drip_thin/fat/cluster, trap_spikes, trap_floor_break, trap_crusher, trap_dart_wall, trap_dart_plate, bridge_plank
(+ broken), bridge_posts, railing_broken, chain_hanging, door_loot, dungeon_entrance, floor_loose_stone, floor_old,
gate_round, lever, recipe_stand, recipe_scroll, wall_old, wall_cracked, wall_broken.

## To change for the owner's Nov 20 choices
- Creatures: the 24 placed today are beetles, spiders, bats and snails. Inside they become the KayKit miners
  (Lost Miner, Tunnel Rat, the Foreman as the pack leader); spiders: owner to say.
- The Loot Room's big chest refills after 1 hour of play like everything else (Nov 19 said it stays empty; the owner
  chose refills on Nov 20). The recipe scroll hands out this dungeon's `page_<recipe>` (DungeonLoot).
