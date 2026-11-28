# The Hammerfall Works (dungeon #11): decisions

Owner, Nov 28, 2026 (PC, F984). The room list is in `11-the-hammerfall-works.md`; this file overrides it where they differ.
Lessons from #1-#10: read the "Lessons" part of `2026-11-24-hald-decisions.md` first (they all still hold), and copy
`tools/dungeons/make_emberdeep.py` (the newest make script: 3 levels, stairs of 5 steps, the lift, deadly places at any
height). #9-#12 are all brick (`00-missing-and-build-order.md`, "Materials of the last four").

| Decision | Choice | Why |
|---|---|---|
| Material | **Hearthbrick clay brick** (`clay_brick`) all through | owner (#9-#12 all brick) |
| Look | **Grand but wrecked** (owner): huge proud brick halls with giant machines (the broken giant anvil, big gears, the press) broken and rusted. More fallen than Emberdeep: `ruin_wall_worn` about 1 in 4, `ruin_wall_collapsed` tops in the big halls, a few fallen ceiling blocks (never in an arena middle), less soot. A giant factory that fell apart | owner |
| Monsters | **Skeletons + smith ghosts** (owner). The works (level 0) and the gear galleries (up): Bone Rots (`tunnel_rat`), Hollow Miners (`lost_miner`), Rune Callers (`rune_caller`), Slag Throwers (`slag_thrower`), a Forge Guard (`forge_guard`) leading the Proving Ground fight. The undercroft (down): the old smiths' ghosts, Drifting Shades (`ghost_a`), Wrathful Shades (`ghost_b`), Bearded Shades (`ghost_c`), plus a few Bone Rots | owner |
| Mini boss, up | **The Gearmaster** (`gearmaster`, new id): a big Rune Caller who throws spinning gear bolts (Orrin's rune bolt with a gear look). In the Gearmaster's Loft. Holds the **Gear Key** (`DungeonKeys.KEYS.key_gear`, already there) | owner |
| Mini boss, down | **The Smeltwarden** (`smeltwarden`, new id): a big skeleton smith (Forge Guard body, bigger) with a long ladle. Special: **ladle splash**, a wide sweep of hot metal in front of him (wind-up: he dips the ladle and it glows; safe: jump back out of reach). In the Smelter's Hall with 2 Bearded Shades; a portcullis drops behind you. Holds the **Hammer Key** (`key_hammer`, already there) | owner |
| Final boss | **The Master of the Works** (`master_of_works`, new id): a huge armoured skeleton smith with a giant hammer (Forge Foreman body, bigger, heavier armour). Normal moves: hammer chop, hammer sweep. **Special: Hammerfall** (owner): he leaps and slams down; a shock ring rolls out over the floor (jump over it) and stones fall from the ceiling (a shadow first, like Hald's ceiling stones). After the slam he is stuck for about 3 s: hit him. Not the Iron King (F981, kept for later) | owner |
| The two keys | **Two keys, two locks** (owner): the round gate in the Great Anvil Hall's north wall (`lock_gate`) has a Gear lock and a Hammer lock; each key opens its own lock and it stays open. Already built: `DungeonKeys.keys_of("the_hammerfall_works")` gives both keys and `is_open` needs every lock. In co-op two friends can open one each; alone you clear both wings | owner |
| New traps | **Great press** (owner, the star trap, new model) in the Press Hall. Plus **spiked flail** (Belt Walk) and **pendulum blades** (Bridge of Chains), shared with #8 and #7's later steps, and **Emberdeep's forge traps**: swinging anvil (Gatehouse Tunnel), push wall into the gear trough (Gear Walk; hurts, never kills), tipping braziers (Furnace Undercroft), molten channel with the plank bridge on a chain (Molten Hall, deadly). **No ore carts** (owner didn't pick them): the old Ore Cart Ramp is now the Ore Stair, rails and dead carts as junk only | owner |
| Reused traps | bear jaws (Yard), loose floor stone + buried chest (Clerk's Office), cracked wall (Oil Store -> Oil Vault), tripwire crossbow + hidden boulder + trapped chest (Slag Cellar), portcullis ambush (Smelter's Hall), ceiling stones (Ore Stair) | already exist |
| Treasury | A **portcullis** in the Masterwork Hall's east wall (`treasury_gate`) that starts down and lifts when the Master falls (Hald's portcullis lifts when its room is won: give it a "starts shut" flag). So the loot can't be grabbed by running past him | Claude |
| Way out | **The chain hoist** (owner): Emberdeep's lift (`DungeonBuild._build_lift` / `_host_lift`) in a new look: a big hoist with chains and a hammer-shaped counterweight. From the Treasury a short walk to the hoist; it rises 10 m to a small room behind the barred gate in the Works Gate's west wall. Pull the lever: the gate opens. The lever refuses while the Master lives | owner |
| Levels | **0 (the works), +10 (gear galleries), -10 (undercroft and the Master's halls)**, like Emberdeep's 10 m: rooms up to 7 m tall can sit over or under each other with 3 m of rock. The Great Anvil Hall (12 m), the Press Hall (8 m) and the Masterwork Hall (10 m) have nothing above them. Stairs are 5 steps of 2 m | Claude |
| Recipe | **Two-handed Bronze Mace** (`mace_2h_bronze`, DungeonList) on the recipe stand: `scroll_hammerfall` | DungeonList |
| 3D page | None: build in the game, then "go test it" | memory: artifact-before-building |
| Real worlds | `since = 99`: only its test world has it until the owner says it's done. It spreads about 120 x 98 m and 10 m up and down from its door: the world-placing chat must check the rock around | Claude |

## The way through
The Works Gate (barred gate west, the hoist room behind it) -> the Yard (Clerk's Office west, Toolroom east, Smithy
Nook behind it) -> the Gatehouse Tunnel (swinging anvil) -> the **Great Anvil Hall**, the hub, with three ways on:
- **West, up the Gear Stair (+10):** the Gear Landing, the Gearworks (the Oil Store west, the Oil Vault behind its
  cracked wall), the Gear Walk north (push wall into the gear trough), the Belt Walk (spiked flail), the Gearmaster's
  Loft east: **Gear Key**.
- **East, down the Undercroft Stair (-10):** the Furnace Undercroft (ghosts, tipping braziers; the Rest Shrine south),
  the Molten Hall north (molten channel across the middle), the Slag Cellar west of its far half, the Smelter's Hall
  east of it (portcullis ambush): **Hammer Key**.
- **North, the two-lock gate:** the Press Hall (great press; a deep alcove east), the Proving Ground west (the big
  fight), the Bridge of Chains west over a 10 m chasm (pendulum blades), the Pattern Room north of the bridge's end,
  then the Ore Stair down 10 m to the Antechamber (the Quiet Forge shrine west), the **Masterwork Hall** (the Master),
  the Treasury behind its portcullis, the hoist walk, and up the hoist to the Works Gate.

## The map (2 m grid, map metres; WORKS = 0, GEARS = +10, UNDER = -10)
Paste into `src/world/dungeon_map.gd` as `const GEARS := 10.0`, `const UNDER := -10.0`, `const HAMMERFALL := {...}`
(id `the_hammerfall_works`, mouth `Vector2(60, 104)`, since 99, `deadly = ["chain_chasm", "molten_channel"]`).
North = smaller z (as in Emberdeep).
```
["entry", 58, 96, 62, 104, 0, 3.5],                # the way in
["works_gate", 52, 84, 68, 96, 0, 7],              # 1 round brick gate, a hammer carved over it; the barred gate in the west wall
["hoist_top", 48, 84, 52, 88, 0, 3.5],             # 29 the hoist comes up here, behind the barred gate (lever)
["yard_door", 58, 82, 62, 84, 0, 3.5],
["yard", 52, 70, 68, 82, 0, 7],                    # 2 old carts and crates; Bone Rots; bear jaws
["clerk_door", 50, 74, 52, 78, 0, 3.5],
["clerks_office", 42, 72, 50, 80, 0, 4.5],         # 3 ledgers, a chest; the loose stone (buried chest)
["tool_door", 68, 74, 70, 78, 0, 3.5],
["toolroom", 70, 72, 78, 80, 0, 4.5],              # 4 tool racks; Hollow Miners; a chest
["smithy_nook", 78, 74, 82, 78, 0, 3],             # 30 a tiny forge, a chest
["gatehouse_tunnel", 58, 56, 62, 70, 0, 4.5],      # 5 the swinging anvil
["great_anvil_hall", 48, 34, 72, 56, 0, 12],       # 6 the broken giant anvil in the middle; Hollow Miners, Slag Throwers on the anvil
["gear_door", 46, 44, 48, 48, 0, 3.5],
["gear_a" .. "gear_e"]: x 44-46 .. 36-38 (2 m each, going west), z 44-48, floors 2, 4, 6, 8, GEARS   # 7 the Gear Stair
["gear_landing", 32, 40, 36, 52, GEARS, 6],
["gearworks", 20, 40, 32, 52, GEARS, 7],           # 8 broken giant gears; Bone Rots + Rune Callers
["gear_walk", 22, 26, 26, 40, GEARS, 4.5],         #   the push wall (west wall) shoves you east into the trough
["gear_trough", 26, 28, 28, 38, GEARS - 1, 5.5],   #   1 m deep, teeth of broken gears: hurts, never kills
["belt_walk", 18, 14, 30, 26, GEARS, 6],           # 9 the spiked flail round a post in the middle
["loft_door", 30, 16, 32, 20, GEARS, 3.5],         #   a round door (boss room rule)
["gearmasters_loft", 32, 10, 44, 22, GEARS, 7],    # 10 the Gearmaster: Gear Key
["oil_door", 18, 44, 20, 48, GEARS, 3.5],
["oil_store", 10, 42, 18, 50, GEARS, 4.5],         # 11 oil jars; Bone Rots; the cracked west wall
["oil_vault", 6, 44, 10, 48, GEARS, 3],            # 12 the vault chest
["under_door", 72, 44, 74, 48, 0, 3.5],
["under_a" .. "under_e"]: x 74-76 .. 82-84 (2 m each, going east), z 44-48, floors -2, -4, -6, -8, UNDER  # 13 the Undercroft Stair
["under_foot", 84, 40, 88, 52, UNDER, 6],
["furnace_undercroft", 88, 36, 100, 52, UNDER, 7], # 14 cold furnaces; Drifting Shades; tipping braziers
["rest_door", 92, 52, 96, 54, UNDER, 3.5],
["rest_shrine", 90, 54, 98, 62, UNDER, 4.5],       # 18 the healing shrine
["channel_door", 92, 34, 96, 36, UNDER, 3.5],
["molten_hall", 86, 18, 102, 34, UNDER, 6],        # 15 the channel across the middle (beams + the plank bridge); Wrathful Shades on the far side
["molten_channel", 86, 24, 102, 28, UNDER - 1.5, 1.5],  # falling in kills
["slag_door", 84, 18, 86, 22, UNDER, 3.5],
["slag_cellar", 76, 14, 84, 24, UNDER, 4.5],       # 17 the tripwire crossbow; Bone Rots
["slag_nook", 72, 16, 76, 20, UNDER, 3],           #   behind the hidden boulder: the chest on the spike holes
["smelt_door", 102, 18, 104, 22, UNDER, 3.5],      #   a round door + the portcullis that drops behind you
["smelters_hall", 104, 12, 120, 28, UNDER, 7],     # 16 the Smeltwarden + 2 Bearded Shades: Hammer Key
["lock_gate", 58, 32, 62, 34, 0, 3.5],             #   the round gate with two locks (Gear Key + Hammer Key)
["press_hall", 52, 18, 68, 32, 0, 8],              # 20 the great press across the middle (deadly when it comes down)
["press_alcove", 68, 22, 72, 26, 0, 3],            # 23 the deep alcove: a chest at the back
["prove_door", 50, 22, 52, 26, 0, 3.5],
["proving_ground", 34, 16, 50, 32, 0, 7],          # 21 the big fight: a Forge Guard, Hollow Miners, Bone Rots, Slag Throwers
["bridge_of_chains", 20, 22, 34, 26, 0, 6],        # 24 the bridge, pendulum blades
["chain_chasm", 22, 18, 32, 30, UNDER, 10.5],      #   10 m down (falling in kills); 10 m wide = no jumping it
["bridge_end", 16, 20, 20, 28, 0, 5],
["pattern_door", 16, 18, 20, 20, 0, 3.5],
["pattern_room", 12, 6, 24, 18, 0, 5],             # 25 casting patterns; Rune Callers; a chest
["ore_a" .. "ore_e"]: x 16-20, z 28-30 .. 36-38 (2 m each, going south), floors -2, -4, -6, -8, UNDER  # 22 the Ore Stair (old rails, dead carts, ceiling stones)
["ore_foot", 14, 38, 22, 42, UNDER, 6],
["antechamber", 10, 42, 26, 54, UNDER, 6],         # 26 Bone Rots in rows, 2 Drifting Shades
["quiet_door", 8, 46, 10, 50, UNDER, 3.5],
["quiet_forge", 0, 44, 8, 52, UNDER, 4.5],         # 27 the healing shrine before the last fight
["master_door", 16, 54, 20, 56, UNDER, 3.5],       #   a round door (boss room rule)
["masterwork_hall", 6, 56, 30, 78, UNDER, 10],     # 28 the Master of the Works; keep the middle clear
["treasury_gate", 30, 70, 32, 74, UNDER, 3.5],     #   the portcullis: lifts when the Master falls
["masterwork_treasury", 32, 68, 42, 78, UNDER, 4.5],  # 31 the recipe stand, the big chest
["hoist_door", 36, 78, 40, 84, UNDER, 3.5],
["hoist_walk", 36, 84, 48, 88, UNDER, 3.5],
["hoist_shaft", 48, 84, 52, 88, UNDER, 13.5],      # 29 the hoist platform rises 10 m to hoist_top
```
Checked with a small script (72 spaces): no two spaces on the same level overlap, and every room over or under another
has at least 3 m of rock between (except the chasm, the channel, the trough and the hoist shaft, which open into their
rooms). The make script must still check the sides: the Ore Stair runs 2 m from the chain chasm, and the Gear Stair's
top step sits beside the Gear Landing.

## Creatures (room: who)
yard: 4 Bone Rots · toolroom: 3 Hollow Miners · great_anvil_hall: 3 Hollow Miners + 2 Slag Throwers · gearworks: 3 Bone
Rots + 2 Rune Callers · oil_store: 2 Bone Rots · gearmasters_loft: the Gearmaster · furnace_undercroft: 3 Drifting
Shades · molten_hall (far side): 2 Wrathful Shades · slag_cellar: 2 Bone Rots · smelters_hall: the Smeltwarden + 2
Bearded Shades · proving_ground: Forge Guard + 3 Hollow Miners + 3 Bone Rots + 2 Slag Throwers · pattern_room: 3 Rune
Callers · antechamber: 4 Bone Rots + 2 Drifting Shades · masterwork_hall: the Master of the Works.

## Build steps (each playable before the next)
1. **Rooms, the three stairs, the hoist way out, skeletons + ghosts, reused traps, the two-lock gate, the treasury
   portcullis, recipe stand.** New `tools/dungeons/make_hammerfall.py` copied from `make_emberdeep.py`; tests
   `tests/test_hammerfall.gd` copied from `test_emberdeep.gd` (test world, plan, brick look, creatures in their rooms,
   the gate needs BOTH keys (one key opens one lock only), reused traps fire, walk every stair, a skeleton follows you
   down a stair, the hoist, only the chasm and the channel kill). Stand-ins for now: the Gearmaster fights like the
   Rune Elder, the Smeltwarden like a big Forge Guard, the Master like the Forge Foreman; the press is the existing
   crusher model; the chasm and the channel are plain deadly places. In the dev menu as **"Dungeon 11"**.
2. **Shared traps**, each reused from whoever builds it first (else built here, in a test room first): swinging anvil,
   push wall + gear trough, tipping braziers, the molten channel's plank bridge (Emberdeep step 2); spiked flail
   (Shieldbearers step 3); pendulum blades (Brassgate). Bolts cut every chain and rope.
3. **The great press** (the star trap): ChatGPT picture first, Blender model (MODEL-RULES checks), a dented floor and a
   slow hiss as the clue, a plate to bait it, deadly when it comes down.
4. **The mini bosses' moves and looks**: the Gearmaster's gear bolts, the Smeltwarden's ladle splash.
5. **The Master of the Works**: Hammerfall (leap, shock ring you jump over, falling ceiling stones with shadows, the
   3 s stuck pause) + his own look (hand-built armour, giant hammer).
6. **Grand-but-wrecked look**: the broken giant anvil (new model, split in two), broken giant gears, rusted machines,
   collapsed wall tops and fallen ceiling blocks, the hoist's hammer counterweight, junk on both sides (junk.py / decor.py).
