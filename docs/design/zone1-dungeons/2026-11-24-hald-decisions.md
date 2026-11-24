# Tomb of Hald Ironbrow (dungeon #5): decisions + lessons

Owner, Nov 24, 2026 (PC, F843). The room list is in `05-tomb-of-hald-ironbrow.md`; this file overrides it where they differ.
Owner's words: "with stone. Again, some were destroyed. Maybe do half of the stone walls and ceilings and things with moss.
There should be ghosts now, because we have 4 types of ghosts. Final boss is a ghost, obviously. Medium size."

| Decision | Choice | Why |
|---|---|---|
| Material | Stonehold stone (`cut_stone`), the medium dungeons' material (DungeonList.SIZES) | owner |
| Ruined + moss | About half the walls/ceilings broken: `ruin_wall_collapsed` / `ruin_wall_worn` pieces, ceiling panels missing (the dark rock shows), fallen ceiling blocks and `ruin_rubble` on the floor. Moss = the caves' **fluffy moss** (cave_cover `moss` + `moss_shell.gdshader`) in the broken parts and along the floor edges. **No lumpy moss models** (owner deleted those Nov 22, "lumpy moss") | owner |
| Monsters | Bone Thralls -> Drifting Shade (`ghost_a`); Bone Wardens -> Bearded Shade (`ghost_c`); Rune Callers -> Wrathful Shade (`ghost_b`), swooping from the Hall of Names; Grave Creepers -> Drifting Shades waiting in the Ossuary's bone walls | owner OK'd |
| Mini boss | **The Shield-Brother**: a big Bearded Shade with a ghostly shield, blocks hits from the front (walk round him, like the Prop Warden). In the Honour Chapel (level 1, top of the Broken Stair). Drops the **Bronze Key** (DungeonKeys.KEYS.key_bronze) | owner OK'd |
| Final boss | **Hald Ironbrow** himself: the ghost boss (`ghost_lord` body + moves: all 4 mace moves, mist every quarter of health), named Hald Ironbrow. Rises out of his coffin in Hald's Tomb. The Bronze door behind his coffin opens the Grave Chamber (recipe stand) | owner OK'd |
| New models | Only the 2 star traps + 1 door: **collapsing stairs** (faint off-colour half -> slide into spikes), **cracked stone bridge slabs**, **locked round stone door** (keyhole). Everything else reuses working traps: dart wall, tripwire, falling stones (drips), rusted portcullis, spiked chest | owner OK'd |
| 3D page | None: build in the game, then "go test it" | memory: artifact-before-building |

## The map (2 m grid, map metres; level 1 floor 0, level 2 floor -8)
Level 1 (mourners' halls): entry, Mourners' Gate (1; barred gate east -> exit way), Hall of Candles (2, dart wall),
Offering Room (3), Scribe's Niche (4, loose stone), Statue Corridor (5, falling stones), Wardens' Hall (6), Ossuary (7,
cracked wall -> stash), Broken Stair (8, collapsing half, spike pit at its foot), Honour Chapel (9, 4 m up: Shield-Brother,
portcullis ambush), Grand Stair (10, 8 m down, 4 stair pieces).
Level 2 (deep burial): Hall of Names (11), Embalmers' Room (12, hidden boulder -> spiked chest), Quiet Chapel (13, healing
fountain), Bridge of Oaths (14, 10 m chasm, cracked slabs, deadly), Shield Hall (15), Grave Goods (19), Collapsed Tunnel
(20, tripwire), Antechamber (16), Hald's Tomb (17, boss, Bronze door), Grave Chamber (21, recipe stand, hidden lever),
Secret Stair (18, 8 m up to the exit way behind the barred gate).

## Lessons from #1-#4 to keep (from the journal, Nov 24 read)
Building
- Edit `tools/dungeons/make_hald.py` and regenerate; never hand-edit `blueprints/dungeons/*.json`.
- Key every cell by (level, x, z): two levels share x,z.
- Shared walls built once (by the taller room): no shimmer. Wall widths match their holes (no gaps beside a 2 m wall in a 4 m hole).
- Every opening 4 m with the 1.5x round doorway and 1 m narrow walls. Boss room: a round door (E) on every way in (`test_every_boss_room_has_a_door`).
- Every walkable space is a named room (unnamed space stops monsters). Enemies in their own room so they don't wake from another floor.
- 2 m clear in doorways, 1.5 m round doors/levers/chests/recipe stand. Narrowest path >= 0.72 m + margin.
- Something solid right behind every lever. Exit lever refuses while the boss lives.
- Only spaces in `deadly` kill; check `crushers_always`-style flags never depend on another dungeon's room names.
- Dark: light only the way in + working lights. Junk: go big (both sides, along walls), use junk.py/decor.py.
- Don't use `cave/boulder_*` as decor (the game makes them breakable boulders) unless it IS the hidden boulder.
- Breakables the boss can smash on his own floor; keep the arena middle clear.
Traps
- Every trap must really fire: a test sets it off. No show-only trap models. New props that bolts should hit go on the bolt's list.
- Every trap gets a clue and a safe way; falling stones only when you're right under them (0.9 m).
- Bridge chasm wider than a running jump (~7 m).
Ghosts
- Ghosts notice you at 7 m; no stone statue on death; loot falls where it died (F812 open).
- Bosses: `no_push` (stop 1.5 m away), 8 s chase guard, each attack its own wind-up >= 0.34 s (F743).
Process
- GODOT is not on PATH: export GODOT=... ; `only=` = test FILE, `fn=` = test name. One Godot game at a time.
- New .gd files: `--check-only` at once. One broken file elsewhere can stop the whole world loading: read Godot's first lines.
- Shared files: commit only your own lines; no git stash; journal inbox entry committed with the work.
