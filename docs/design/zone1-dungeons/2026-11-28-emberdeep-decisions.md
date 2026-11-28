# Emberdeep Forge (dungeon #10): decisions

Owner, Nov 28, 2026 (PC, F982). The room list is in `10-emberdeep-forge.md`; this file overrides it where they differ.
Lessons from #1-#9: read the "Lessons" part of `2026-11-24-hald-decisions.md` first (they all still hold), and copy
`tools/dungeons/make_orrin.py` (the newest make script: 3 levels, named deadly places at any height).
Owner's words: "plan the next dungeon, dungeon 10" and, on traps, "feel free to use ChatGPT or anything else to generate
new traps". #9-#12 are all brick (`00-missing-and-build-order.md`, "Materials of the last four").

| Decision | Choice | Why |
|---|---|---|
| Material | **Hearthbrick clay brick** (`clay_brick`) all through, no Stonehold stone | owner (#9-#12 all brick) |
| Look | **Sooty but solid** (owner): brick mostly whole, blackened by soot, cracked here and there (`ruin_wall_worn` about 1 in 5, no collapsed tops, no fallen ceilings). Ash and coal dust on the floors. The top two levels are cold; the deep furnace (level 3) still glows orange | owner |
| Monsters | **Skeletons + a NEW Slag Thrower** (owner): Bone Rots (`tunnel_rat`) = the plan's Bone Thralls and Grave Creepers, Hollow Miners (`lost_miner`) = its Bone Wardens. The **Slag Thrower** (`slag_thrower`) is a skeleton smith that lobs glowing lumps of hot slag from far away: the Rune Caller's throw (`rune_caller`, Orrin step 2) with a new look and a fire hit. Slag Throwers replace the plan's Rune Callers (Cooling Room, Furnace Gallery). The Foreman's Office pack is led by a **Forge Guard** (`forge_guard`, a big Hollow Miner like `vault_guard`) | owner |
| Final boss | **The Forge Foreman** (`forge_foreman`, Pit Boss body, bigger, a smith's hammer). Normal moves: hammer chop, hammer sweep. **Special: Molten Pour** (owner): he walks to the great furnace and pulls its chain (a long wind-up, a loud clank and a hiss); glowing metal runs out into the floor grooves of the Heart. It burns hard (not instant death) for about 6 s while it glows, then cools dark. Safe: jump onto one of the 4 raised anvil blocks. After the pour he stands tired for about 4 s: hit him. Holds the **Forge Key** (`DungeonKeys.KEYS.key_forge`, new) to the Forge Treasury | owner |
| New traps | All six from the plan (owner): **rolling anvil**, **molten channel**, **swinging crucible over a molten pit** (big ones) and **tipping braziers**, **swinging anvils**, **push wall into slag** (smaller ones). Not picked: forge press, runaway ore carts (keep them for #11 or #12) | owner |
| Where the new traps go | As the plan: tipping braziers in the Soot Corridor and the Furnace Gallery; push wall in the Bellows Walk (shoves you into the 1 m slag trough: hurts, never kills); swinging anvils in Hammer Row; molten channel across the Quench Hall (deadly; 1 m beams + a plank bridge on a chain you shoot down); rolling anvil down the Ingot Ramp (safe in the Ramp Alcove); swinging crucible over the Crucible Pit (deadly; shoot its chain to stop it) | plan |
| Reused traps | bear jaws in the coal dust (Coal Store), dart wall (Collapsed Tunnel), loose floor stone + buried chest (Apprentices' Dorm), cracked wall (Hidden Smithy), hidden boulder + chest (Coal Store nook), secret lever + spike-hole chest (Master's Study) | already exist |
| Way out | **The Ember Lift** (owner): from the Forge Treasury a short walk to an old ore lift that rises 20 m to a small room behind the barred gate in the Ember Gate. Pull the lever: the gate opens, you're at the door. The lever refuses while the Foreman lives | owner |
| Levels | **0, -10, -20** (not the plan's -8 / -16): with 10 m between levels a room up to 7 m tall can sit under a room above and still have 3 m of rock between them (Hald and Brassgate already stack rooms like this). The stairs are 5 steps of 2 m. Big halls that are taller (the Heart, 9 m) sit where nothing is above them | Claude |
| Coal Chute | A 4 x 4 shaft in the Coal Store's north wall: step in, drop 10 m onto a heap of coal (no fall damage, like Orrin's rags). One way only; the Back Stair is the way back up | Claude |
| Recipe | **Bronze Mace** (`mace_bronze`, DungeonList) on the recipe stand: `scroll_emberdeep`. (The plan's copper weapon list is older; DungeonList wins) | DungeonList |
| 3D page | None: build in the game, then "go test it" | memory: artifact-before-building |
| Real worlds | `since = 99`: only its test world has it until the owner says it's done. It goes 20 m DOWN from its door and spreads about 92 x 72 m: the world-placing chat must check the rock below and around | Claude |

## The map (2 m grid, map metres; level 1 floor 0, level 2 (cooling halls) COOL = -10, level 3 (deep furnace) FURNACE = -20)
Level 1 runs north from the way in (the mouth at x 38, z 90): the Ember Gate (the barred gate in its east wall, the lift
room behind it), Ash Hall north of it, the Coal Store east (bear jaws; the boulder nook; the Coal Chute in its north
wall), the Soot Corridor west (braziers) to the Tool Hall, the Apprentices' Dorm south of that (the Hidden Smithy behind
its cracked east wall), the Bellows Walk north (push wall, slag trough on its east side) to the Great Door, the Hall of
Anvils north of it, then east: the Ingot Ramp (rolling anvil, the alcove on its south side, the deep alcove on its
north side), the Crucible Bridge over the pit, and the Deep Stair down 20 m (two flights with a landing at -10).
Level 2 lies under the south half: the Coal Chute drops into the Coal Cellar, west is the Cooling Room (Slag Throwers on
a ledge), the Ore Sorting room north of it and the Collapsed Tunnel east from there (darts, a chest at its blocked end);
Hammer Row west to the Quench Hall (molten channel across its middle), the Foreman's Office south of its west part, the
Smelters' Rest west of that, and the Back Stair up north into the Great Door. Level 3 lies east: the Deep Stair's foot,
the Furnace Gallery, the Slag Pits, the Master's Study east (secret lever), the Shrine of the Anvil west, the Heart of
Emberdeep south (the Foreman), its locked round door west to the Forge Treasury, and the Ember Lift up.

Paste into `src/world/dungeon_map.gd` as `const COOL := -10.0`, `const FURNACE := -20.0`, `const EMBERDEEP := {...}`
(id `emberdeep`, mouth `Vector2(38, 90)`, since 99, `deadly = ["crucible_pit", "quench_channel"]`):
```
["entry", 36, 82, 40, 90, 0, 3.5],                 # the way in
["ember_gate", 34, 74, 42, 82, 0, 6],              # 1 the round brick door; the barred gate in the east wall
["lift_top", 42, 74, 46, 78, 0, 3.5],              # 30 the lift comes up here, behind the barred gate (lever)
["ash_door", 36, 72, 40, 74, 0, 3.5],
["ash_hall", 30, 60, 46, 72, 0, 6],                # 2 grey ash; Bone Rots; a chest
["coal_door", 46, 64, 48, 68, 0, 3.5],
["coal_store", 48, 60, 56, 68, 0, 4.5],            # 9 coal heaps, bear jaws in the dust
["coal_nook", 56, 62, 58, 66, 0, 3],               #   behind the hidden boulder: a chest
["coal_chute", 52, 56, 56, 60, COOL, 13],          # 10 the shaft: drop 10 m onto the coal heap (open to the store and the cellar)
["soot_corridor", 16, 64, 30, 68, 0, 4.5],         # 3 tipping braziers
["tool_hall", 0, 60, 16, 72, 0, 6],                # 4 tool racks; Hollow Miners; a chest
["dorm_door", 2, 72, 6, 74, 0, 3.5],
["dorm", 0, 74, 8, 82, 0, 4],                      # 7 Bone Rots in the bunks; the loose stone (buried chest)
["hidden_smithy", 8, 74, 16, 82, 0, 4],            # 8 behind the dorm's cracked east wall: a little forge, the vault chest
["bellows_walk", 0, 46, 4, 60, 0, 4.5],            # 5 the push wall (west wall) shoves you east into the trough
["slag_trough", 4, 48, 6, 58, -1, 5.5],            #   1 m deep: hurts, never kills; walk out at either end
["great_door", 0, 38, 12, 46, 0, 6],               # 6 the huge broken round door; the Back Stair comes up here
["anvils_door", 4, 36, 8, 38, 0, 3.5],
["hall_of_anvils", 0, 24, 16, 36, 0, 7],           # 20 rows of anvils: Hollow Miners + Bone Rots (the big fight)
["ingot_ramp", 16, 26, 30, 30, 0, 4.5],            # 21 the rolling anvil (its hole in the west end, a groove down the middle)
["ramp_alcove", 20, 30, 24, 34, 0, 3],             #   the safe side alcove
["deep_alcove", 24, 18, 28, 26, 0, 3],             # 22 the alcove that goes deeper: a chest at the back
["crucible_bridge", 30, 26, 44, 30, 0, 6],         # 23 the bridge, the swinging crucible over it
["crucible_pit", 32, 22, 42, 34, COOL, 10.5],      #   10 m down into glowing metal (falling in kills); 10 m wide = no jumping it
["bridge_end", 44, 24, 48, 32, 0, 5],
["deep_a" .. "deep_e"]: x 48-58 (2 m each), z 26-30, floors -2, -4, -6, -8, COOL   # 24 the Deep Stair, first flight, down east
["deep_landing", 58, 24, 62, 32, COOL, 6],
["deep_f" .. "deep_j"]: x 62-72 (2 m each), z 26-30, floors COOL-2 .. FURNACE      #    second flight
["deep_foot", 72, 24, 76, 32, FURNACE, 6],
["coal_cellar", 52, 48, 60, 56, COOL, 5],          # 11 Bone Rots in the dark
["cool_door", 50, 50, 52, 54, COOL, 3.5],
["cooling_room", 42, 48, 50, 56, COOL, 7],         # 12 racks of blades; Slag Throwers on a ledge along the west wall
["sort_door", 44, 46, 48, 48, COOL, 3.5],
["ore_sorting", 42, 38, 50, 46, COOL, 4.5],        # 18 sorting tables, a chest, Bone Rots
["collapsed_tunnel", 50, 40, 64, 44, COOL, 3.5],   # 19 the dart wall; blocked by rubble at the far end, a chest there
["hammer_row", 30, 50, 42, 54, COOL, 5],           # 13 swinging anvils
["quench_hall", 14, 44, 30, 56, COOL, 6],          # 14 the molten channel across the middle (beams + the plank bridge)
["quench_channel", 20, 44, 24, 56, COOL - 1.5, 1.5], #  falling in kills
["office_door", 16, 56, 20, 58, COOL, 3.5],
["foremans_office", 14, 58, 22, 66, COOL, 5],      # 15 the Forge Guard and his pack
["rest_door", 12, 62, 14, 66, COOL, 3.5],
["smelters_rest", 4, 60, 12, 68, COOL, 4.5],       # 16 the healing shrine
["back_foot", 8, 56, 12, 60, COOL, 6],             # 17 the Back Stair: 10 m up north in five steps into the Great Door
["back_a" .. "back_e"]: x 8-12, z 54-56 .. 46-48 (2 m each, going north), floors COOL, -8, -6, -4, -2
["gallery_door", 72, 32, 76, 34, FURNACE, 3.5],
["furnace_gallery", 66, 34, 82, 46, FURNACE, 7],   # 25 cold furnaces, tipping braziers, Slag Throwers
["slag_door", 72, 46, 76, 48, FURNACE, 3.5],
["slag_pits", 66, 48, 82, 60, FURNACE, 6],         # 26 shallow pits of cold slag (not deadly); Bone Rots
["study_door", 82, 52, 84, 56, FURNACE, 3.5],      #   opens with the secret lever
["masters_study", 84, 50, 92, 58, FURNACE, 4.5],   # 27 the chest on the spike holes
["shrine_door", 64, 52, 66, 56, FURNACE, 3.5],
["anvil_shrine", 56, 50, 64, 58, FURNACE, 4.5],    # 28 the healing shrine before the last fight
["heart_door", 68, 60, 72, 62, FURNACE, 3.5],      #   a round door (boss room rule)
["heart_of_emberdeep", 60, 62, 76, 78, FURNACE, 9], # 29 the great furnace (south wall), floor grooves, 4 raised anvil blocks; the Foreman
["forge_lock", 58, 72, 60, 76, FURNACE, 3.5],      #   the treasury's round door: locked (the Forge Key)
["forge_treasury", 50, 70, 58, 78, FURNACE, 4.5],  # 31 the recipe stand, the big chest
["lift_walk", 46, 74, 50, 78, FURNACE, 3.5],       # 30 to the Ember Lift
["lift_shaft", 42, 74, 46, 78, FURNACE, 23.5],     #    the lift platform rises 20 m to lift_top
```
Checked with a small script: no two spaces on the same level overlap, and every room under another has at least 3 m of
rock between (except the pit, the channel, the chute and the lift shaft, which are meant to open into their rooms).
The make script must still check the sides: the Back Stair runs 2 m from the slag trough and the Quench Hall.

## Build steps (each playable before the next)
1. **Rooms, stairs, coal chute, the lift way out, skeletons, reused traps**, Forge Key door, recipe stand. Slag Throwers
   fight up close for now (like Orrin's Rune Callers in step 1); the Forge Foreman fights like the Pit Boss (pick crack,
   whirl). The molten channel and the crucible pit are plain deadly places for now (glowing, with the beams and the
   bridge). In the dev menu as "Dungeon 10".
2. **The forge traps, one by one, each in a test room first** (build-order step 4): tipping brazier, push wall + slag
   trough, swinging anvil, rolling anvil, swinging crucible, the molten channel's plank bridge on a chain. ChatGPT
   pictures of each trap first (OK from the owner). Bolts cut every chain (add them to the bolt's list).
3. **The Slag Thrower's throw** (reuse Orrin step 2's rune bolt: a glowing slag lump with a fire hit; dodge it or block
   with a shield) + **the Foreman's Molten Pour** (the chain pull, the grooves, the raised blocks, the tired pause) + their looks.
4. **Forge look**: soot, ash and coal on the floors, cold furnaces, anvils, tool racks, bellows, the deep furnace's glow,
   junk on both sides (junk.py / decor.py).
