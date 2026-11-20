# Zone 1 dungeons: what's missing and the build order

*Draft, Nov 20 (Mac, overnight, F237). One file per dungeon sits next to this one (01 to 12). The pages "Small Wooden
Dungeons", "Medium Stone Dungeons" and "Big Clay Dungeons" draw the same maps.*

## What we already have
- **Building pieces in all three materials:** root wood 60, Stonehold stone 48, Hearthbrick clay brick 45 pieces
  (`assets/models/build/`).
- **Mossgate Hold's dungeon kit** (23 models, `assets/models/dungeon/`): darts (wall, plate), falling stalactites,
  spikes, breaking floor, crusher, plank bridges, broken railing, chain, doors and gates, lever, old/cracked/broken
  walls, loose floor stone, recipe stand + glowing scroll, entrance.
- **Props:** mine cart, rail track, rope ladder, copper and iron keys, anvil, bellows, lanterns, chests, furniture.
- **Code:** recipe pages that always teach the same recipe, and the 1-hour refill (`DungeonLoot`, Nov 20).
  Mossgate Hold's code (rooms in old dwarf stone, carving, placing) is on the PC.

## New 3D models (made in Blender on the PC, our style, MODEL-RULES.md checks)

> **Nov 20: the full, up-to-date asset list is in [traps-and-variety.md](traps-and-variety.md).** Fire jets, gas valve, pistons, bellows trap, swing hooks and the coin press are out; their rows were removed below.

| Model | Used in | Note |
|---|---|---|
| dungeon_entrance, stone and brick versions | #5-#12 | the round door in the cave wall |
| door_locked_round (stone, brick) with a keyhole | #5-#12 | the locked doors and gates |
| trap_ceiling_stones | #5 #6 #7 #8 #9 | stone version of the falling stalactites |
| trap_crusher_stone | #5 #6 #7 #8 #9 | stone/brick frame for the crusher |
| trap_crusher_great | #7 | bigger crusher that kills outright |
| bridge_stone_slab (+ cracked) | #5 #6 #8 #9 #12 | stone/brick bridge slabs that fall away |
| trap_press | #11 | the great press |
| molten_channel, mould_lid (+ cracked) | #10 #11 #12 | molten metal in stone: can never spill |
| bridge_chain_section | #12 | a bridge section that drops and rises |
| lift platform + winch, rope slide | #3 #4 #10 #11 | ways out |
| **Maybe:** stone/brick versions of wall_cracked, floor_loose_stone, floor_old | #5-#12 | if the root wood ones don't fit stone |
| **Check:** healing shrine | all | Mossgate has one; check the PC's kit |

About 20 new models in all. The small wooden dungeons need almost nothing new (only the rope lift and rope slide).

## New creature work (PC)
- KayKit Skeletons → dwarf versions, repainted: **Lost Miner, Tunnel Rat, Foreman** (small), **Bone Thrall, Bone
  Warden, Rune Caller, Grave Creeper** (medium and big). One rig and animation set for all of them.
- **Mini bosses** = bigger, named versions with more health and a special move (e.g. the Shield-Brother's shield bash,
  the Barrow Keeper's rune storm): 5 for medium, 4 for big.
- **Leaders** at the recipe stands: Foreman (small), named big Warden (medium and big).
- Rune Callers need a ranged attack (a glowing rune bolt): new code, like the snail's spit.

## New game code
1. **The 12 places in the world:** Mossgate's placing (PC) grown to all 12, in rings: small 40-100 m, medium
   100-170 m, big 170 m+ from the start, at least 40 m apart. Each new place keeps out of the others and gets the
   placement test (owner's Nov 17 rule).
2. **Building from a plan file** like `mossgate_hold.json` for each dungeon, plus a script per dungeon (like
   `tools/dungeons/make_mossgate.py`).
3. **Keys and locked doors:** a key item per dungeon, a door that opens only for it, shared in co-op (anyone in the
   group with the key opens it), the key goes back into the mini boss when the dungeon refills.
4. **Mini boss fights:** health bar with the name, one special move each.
5. **Trap code** (request → host decides → everyone sees, like every action):
   every trap in traps-and-variety.md (triple carts, push wall, swinging boulder/anvil/crucible, rolling boulder/anvil,
   tipping brazier, pendulum blades and bells, spear wall, tripwire crossbow, bear jaws, portcullis, collapsing stairs,
   spiked flail, trapped chest, great crusher and press, molten metal, dropping bridge). Ragdoll on big hits. Every trap: a clue (look or sound) and a safe way through.
6. **Things you can shoot:** crossbow bolts cut chains and ropes, set off trapped chests and bring down stalactites.
7. **Lamps you can light** (Lampwick Drift) and **ways out** (lever gates, rope lift, rope slide, lift, secret stair).
8. **Dungeon chests and the recipe stand** use `DungeonLoot` (built): 1-hour refill, same page again.
9. **A robot check** that all 12 exist in a new world, every room can be reached, and nothing grows inside.

## Build order (each step playable before the next)
1. **PC:** push Mossgate Hold; test it; swap its creatures for the first KayKit miners (Lost Miner, Tunnel Rat,
   Foreman). Its recipe stand hands out the dungeon's page through DungeonLoot.
2. **Small #2-#4** (Lampwick Drift, Old Pell's Diggings, Mossprop Workings): almost all models exist. Adds lamps to
   light, the rope lift and the rope slide. Placing 4 small ones in the ring.
3. **Keys and locked doors + mini bosses + the stone models** (entrance, locked door, ceiling stones, stone crusher,
   stone bridge). Then **medium #5** (Tomb of Hald Ironbrow) as the first, then #6-#9. Rune Callers' ranged attack.
4. **Forge traps** one by one (tipping braziers, swinging anvils, push walls, rolling anvil, press, molten channel, ore carts), each
   tried in a test room first. Then **big #10** (Emberdeep Forge), then #11 and #12.
5. **Robot check of all 12** and the placement tests.
