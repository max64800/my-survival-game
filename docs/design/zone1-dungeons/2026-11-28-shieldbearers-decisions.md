# Hall of the Shieldbearers (dungeon #8): decisions

Owner, Nov 28, 2026 (PC, F977). The room list is in `08-hall-of-the-shieldbearers.md`; this file overrides it where they differ.
Lessons from #1-#7: read the "Lessons" part of `2026-11-24-hald-decisions.md` first (they all still hold).

| Decision | Choice | Why |
|---|---|---|
| Material | Stonehold stone (`cut_stone`) | medium dungeon (DungeonList.SIZES) |
| Monsters | **Skeleton soldiers** (owner): the skeleton miners (Hollow Miners `lost_miner` = the plan's Bone Wardens, Bone Rots `tunnel_rat` = its Thralls and Grave Creepers). Their soldier look (shields, spears, helmets) is step 4 | owner, nothing new to build first |
| Rune Callers | dropped: the skeletons don't shoot, so the Sentry Walk is a side corridor with guards and a chest (no balcony) | follows the monster choice |
| Final boss | **Sergeant Halfhelm, a shield-bash sergeant** (owner): a big skeleton soldier with a tower shield. Blocks from the front, then charges and bashes with the shield; dodge the charge and hit his back while he turns. Holds the **Armoury Key** (`DungeonKeys.KEYS.key_armoury`) that opens the Captain's Armoury | owner |
| Bodyguard (Sergeant's Quarters) | a bigger skeleton leader (`shield_guard`) and two Hollow Miners; the portcullis drops behind you | Claude, follows the monster choice |
| New traps | **Spinning spiked ball** (Shield Bridge: a spiked iron ball on a chain spins round a post and knocks you off; clue: a scrape circle; safe: run in behind it, or shoot the chain), **arrow holes in the ceiling** (murder holes over a doorway drop a rain of arrows when you stop under them; clue: holes and old arrows on the floor) | owner (picked 2 of 4) |
| Reused traps | spear wall (Barracks Row), bear jaws (Training Yard), tripwire crossbow (Drill Cellar), fake floor over spikes (Practice Pit, keep to the edge), portcullis (Sergeant's Quarters), spike-hole chest behind a hidden boulder (Armoury), cracked bridge slabs over the chasm, cracked wall, loose stone | already exist |
| Look | **Lived-in barracks** (owner): neat Stonehold stone, mostly whole, full of soldiers' things: bunks, weapon racks, shields on walls, banners, training gear. Messy, like the soldiers just left | owner |
| Recipe | Bronze Shield (`shield_bronze`, DungeonList) on the recipe stand: `scroll_shieldbearers` | DungeonList |
| 3D page | None: build in the game, then "go test it" | memory: artifact-before-building |
| Real worlds | `since = 99`: only its test world has it until the owner says it's done (layout 20+ belongs to the zone-1 shrink, F969-F974) | other chat, Nov 28 |

## The map (2 m grid, map metres; level 1 floor 0, level 2 (drill cellars) floor -8)
Level 1 runs north from the way in: Muster Gate, Parade Ground (Sentry Walk east), Mess Hall (Kitchens east), Barracks Row west
(Bunk Rooms and the Deserter's Stash south), Training Yard north, the Armoury Door hall west of it, the Armoury, the Shield
Bridge south over a 10 m chasm, the Banner Hall, the Captain's Hall, the Captain's Armoury; its back way (the bolt-hole) runs
east to the barred gate in the Muster Gate's west wall. Level 2: the Cellar Stair down east of the Training Yard, Drill Cellar,
Practice Pit, Sergeant's Quarters, Infirmary, the Back Stair up into the Armoury Door hall. (The cellars are a side loop: the
yard also opens straight into the Armoury Door hall.)

## Build steps (each playable before the next)
1. **Rooms, stairs, way out, skeletons, reused traps**, Armoury Key door, recipe stand. Halfhelm fights like the Vault Captain
   for now (shield in front, charge). In the dev menu as "Dungeon 8".
2. **Halfhelm's shield bash** (blocks from the front, charge + bash, slow turn: hit his back) + his own soldier look.
3. **The two new traps**: the spinning spiked ball on the Shield Bridge, the arrow holes over a doorway.
4. **Lived-in barracks**: bunks, weapon racks, shields, banners, training dummies, skeleton soldiers' gear look, junk.
