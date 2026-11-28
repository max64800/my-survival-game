# Vigil of Orrin Stonejaw (dungeon #9): decisions

Owner, Nov 28, 2026 (PC, F980). The room list is in `09-vigil-of-orrin-stonejaw.md`; this file overrides it where they differ.
Lessons from #1-#8: read the "Lessons" part of `2026-11-24-hald-decisions.md` first (they all still hold).
Owner's words: "Dungeon 9 should be very old brick. Most of it is old, some of it may be new, maybe a mix of stone here
and there, but not too much." and "The last 4 dungeons will be brick" (#9-#12, see `00-missing-and-build-order.md`).

| Decision | Choice | Why |
|---|---|---|
| Material | **Hearthbrick clay brick** (`clay_brick`), not the plan's Stonehold stone. Most pieces `ruin_wall_worn` / `ruin_wall_collapsed`, ceilings fallen in places, brick rubble. A few Stonehold stone (`cut_stone`) pieces "here and there": old stone stair treads and doorway arches, under 1 in 10 pieces | owner |
| Look | **Old all through, repaired tower top** (owner): worn, crumbling brick everywhere, some walls fallen, rubble, dust. Only the bell tower's top (Orrin's Vigil, the Rune Door to Orrin's Rest, Orrin's Rest) is newer, whole brick, as if someone kept it repaired | owner |
| Monsters | **Skeletons + Rune Callers** (owner): Bone Rots (`tunnel_rat`) = the plan's Bone Thralls and Grave Creepers, Hollow Miners (`lost_miner`) = its Bone Wardens, and a NEW skeleton **Rune Caller** (`rune_caller`) that throws glowing rune bolts from far away. A bigger **Rune Elder** (`rune_elder`) leads the Acolyte's Sanctum pack | owner |
| Final boss | **The Bell-Ringer** (`bell_ringer`, owner): a huge skeleton with a bell-hammer under the great bell. Sometimes he strikes the great bell: a ring wave knocks you flat unless you are behind a pillar. Hit him while the bell still hums. Holds the **Rune Key** (`DungeonKeys.KEYS.key_rune`) to Orrin's Rest | owner |
| New traps | **Toppling brick wall** (an old leaning wall falls flat across the path as you pass; clue: it leans, cracks, dust; safe: run, or knock it down from afar with a bolt), **Rolling bell** (a loose bell breaks free and rolls down the Bell Run at you; clue: a rumble and scrape marks; safe: duck into the side niche), **Crumbling brick floor** (old mortar gives way into a pit; clue: missing bricks, loose mortar; safe: keep to the solid edge). The plan's swinging bells: not picked | owner (picked 3 of 4) |
| Where the new traps go | Crumbling floor = the Hall of Echoes' deadly pit (in place of the plan's bell pendulums). Rolling bell = the Bell Run (in place of the plan's Crusher Steps; its niche is the safe spot). Toppling wall = the Acolytes' Cells corridor | Claude |
| Reused traps | dart wall (Hall of Pillars), falling stones (First Stair), dart plate (Rune Gallery), cracked wall (Carvers' Vault), loose stone (Robing Room), cracked bridge slabs over a 10 m chasm + spear wall (Broken Bridge), spike-hole chest behind a hidden boulder (Bellringer's Loft) | already exist |
| Way out | From Orrin's Rest the Pilgrims' Slide (worn stone steps for now) runs down to a ledge 8 m up in the Pilgrims' Door's east wall; jump down (no fall damage) onto the heap of old rags | plan |
| Recipe | Bronze Sword (`sword_bronze`, DungeonList) on the recipe stand: `scroll_orrin` | DungeonList |
| 3D page | None: build in the game, then "go test it" | memory: artifact-before-building |
| Real worlds | `since = 99`: only its test world has it until the owner says it's done. It climbs 24 m up from its door (levels 0, +8, +16): the world-placing chat must check the rock above | Claude |

## The map (2 m grid, map metres; level 1 floor 0, level 2 (rune halls) +8, level 3 (bell tower) +16)
Level 1 runs north from the way in: Pilgrims' Door (12 m tall, the exit ledge's hole 8 m up its east wall), Hall of
Pillars (Robing Room east), the First Stair west (8 m up). Level 2: Rune Gallery, the Acolytes' Cells corridor south,
the Carvers' Workshop east of it (Carvers' Vault behind its cracked wall), Hall of Echoes (crumbling floor over a pit),
Acolyte's Sanctum west, Quiet Shrine north of it, Rune Door hall south, the Tower Stair up (8 m). Level 3: Bell Walk,
Broken Bridge south over the chasm (Bellringer's Loft niche behind the boulder at its far end), the Bell Run east,
Antechamber, Orrin's Vigil (the Bell-Ringer), the locked Rune Door, Orrin's Rest, the Pilgrims' Slide down to the ledge.

## Build steps (each playable before the next)
1. **Rooms, stairs, way out, skeletons, reused traps**, Rune Key door, recipe stand. Rune Callers fight up close for now;
   the Bell-Ringer fights like the Pit Boss (pick crack, whirl). In the dev menu as "Dungeon 9".
2. **Rune Callers' rune bolt** (a glowing bolt you can dodge or block with a shield) + **the Bell-Ringer's bell strike**
   (ring wave, hide behind a pillar) + their looks.
3. **The three new traps**: crumbling brick floor, rolling bell, toppling brick wall (ChatGPT pictures first).
4. **Old temple look**: rune carvings, bells, robes, candles, junk.
