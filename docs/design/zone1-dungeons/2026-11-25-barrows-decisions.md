# The Quiet Barrows (dungeon #6): decisions + map

Owner, Nov 25, 2026 (PC, F906). The room list is in `06-the-quiet-barrows.md`; this file overrides it where they differ.
Lessons from #1-#5: read the "Lessons" part of `2026-11-24-hald-decisions.md` first (they all still hold).

| Decision | Choice | Why |
|---|---|---|
| Material | Stonehold stone (`cut_stone`) | medium dungeon (DungeonList.SIZES) |
| Monsters | **Ghosts and spiders** (owner). Drifting Shades (`ghost_a`), Bearded Shades (`ghost_c`), Wrathful Shades (`ghost_b`) and Cave Spiders (many, in the dark corners) | owner |
| Final boss | **The Barrow Keeper, a rune ghost** (owner): a big Wrathful Shade that throws glowing rune bolts from a distance, so you must close in. Holds the **Barrow Key** (DungeonKeys.KEYS.key_barrow) that opens the King's Grave Chamber | owner |
| Look | **Older each floor** (owner): level 1 nearly whole stone; level 2 cracked, some ceilings gone, roots; level 3 half caved in, earth, rubble and fluffy moss | owner |
| Size | **3 levels as planned** (owner): level 1 at 0, level 2 at -8, level 3 at -16. Straight stair flights (no spiral pieces) wound round the old shaft: the Spiral Stair goes east, the Deep Stair comes back west under it | owner |
| Plan fix | The plan's "Second Ring: the gate down is locked (Barrow Key)" is dropped: the key is on level 3, so only the King's Grave Chamber is locked | Claude |
| 3D page | None: build in the game, then "go test it" | memory: artifact-before-building |

## Build steps (each playable before the next)
1. **Rooms, stairs, way out, ghosts, spiders, reused traps** (falling stones, bear jaws, spiked chest, dart wall,
   swinging boulders, spear walls, hidden boulder, cracked wall, loose stone, healing basin, recipe stand, Barrow
   Key door). The Barrow Keeper fights with the ghost boss moves for now. In the dev menu as "Dungeon 6".
2. **The Barrow Keeper's rune bolts** (new code, built from the snail's spit).
3. **The rolling boulder** in the Long Barrow (new: built from the mine cart's rolling lane) + the soft heap model.
4. **Older each floor** polish: roots on level 2, earth and fluffy moss on level 3.

## The map (2 m grid, x right, z toward the cave; [x0, z0, x1, z1, floor, height])
Every doorway is exactly 4 m (small `_door` spaces join rooms that a 2 m rock wall keeps apart).

Level 1 (floor 0), the newest barrows:
- entry [38,62,42,70] · **1 barrow_door** [36,54,44,62] h9 (the exit ledge's hole high in its west wall)
- exit_ledge [30,58,36,62] floor +6: where the Air Shaft comes out; you jump down onto the soft heap
- **2 long_barrow** [38,42,42,54] (the rolling boulder; side alcoves alcove_w [36,46,38,50], alcove_e [42,46,44,50])
- **3 first_ring** [34,30,46,42] Drifting Shades · smith_door [32,34,34,38] · **4 smith_barrow** [24,32,32,40] loose stone
- hunter_door [26,28,30,32] · **5 hunter_barrow** [24,20,32,28] spiders in the dark
- **6 spiral stair** east from the ring: spiral_a [46,34,48,38] -2, _b -4, _c -6, foot [52,34,56,38] -8 (falling stones)

Level 2 (floor -8):
- **7 second_ring** [56,28,68,40] Bearded Shades · twins_door [60,40,64,44] · **8 twins** [58,44,66,52] · **9 twins_vault** [60,52,64,56] behind the cracked wall
- **10 keepers_corridor** [60,16,64,28] bear jaws · shrine_door [64,20,66,24] · **13 shrine** [66,18,74,26] healing basin
- **11 keepers_barrow** [56,4,68,16] the pack and its leader · sunken_door [54,8,56,12] · **12 sunken_barrow** [42,4,54,16] spiked chest
- **14 deep stair** west from the ring: deep_a [54,28,56,32] -10, _b -12, _c -14, foot [46,28,50,32] -16

Level 3 (floor -16), the oldest:
- **15 hall_of_bones** [34,22,46,34] spiders + Drifting Shades, dart wall · mourning_niche (18) behind a boulder on its north wall
- bridge_door [32,26,34,30] · **16 ash_bridge** [18,24,32,32] slabs z26-30, chasm [22,24,30,32] 10 m down (deadly), swinging boulders, Wrathful Shades on the far (west) end
- **17 spear_gate** [18,32,22,42] spear walls · kings_door [18,42,22,44] (round door)
- **19 kings_barrow** [14,44,28,56] h6: the Barrow Keeper + 2 shades · grave_gate [28,48,30,52] locked (Barrow Key)
- **21 kings_grave** [30,48,38,56] recipe stand + big chest
- **20 air_shaft** [30,56,34,58] from -16 up to the exit ledge at +6 (a ladder)
