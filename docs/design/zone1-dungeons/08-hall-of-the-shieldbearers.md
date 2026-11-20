# #8 Hall of the Shieldbearers

*Draft, Nov 20 (Mac, overnight). Generated from the dungeon pages; edit the page data and run gen_docs again.*

An old barracks where the shield wall soldiers lived and trained. Lots of fighting, and the training traps are still armed.

| | |
|---|---|
| Size | medium, 20 spaces, 2 level(s), 12-15 min |
| Built from | Stonehold stone (`cut_stone`), inside old dwarf stone (can't be dug) |
| Floor to ceiling | 5 m in rooms, more in tall halls |
| Teaches one of | Copper Helm, Copper Mail, Copper Greaves, Copper Shield, Copper Sword (shuffled per world) |
| Way out | A hidden door in the Captain's Hall opens onto the soldiers' old way back to the Muster Gate. |

## Rooms (sizes in metres on the 2 m grid, width x length)

| # | Space | Level | Size | What's there | Has |
|---|---|---|---|---|---|
| 1 | Muster Gate | Level 1 (barracks) | 8 x 8 | Entrance: a round door with two stone shield-bearers on guard. |  |
| 2 | Parade Ground | Level 1 (barracks) | 12 x 12 | A big open hall. Bone Wardens still drill here. | mob: wardens |
| 3 | Sentry Walk (corridor) | Level 1 (barracks) | 4 x 12 | A balcony above the parade ground. Rune Callers shoot down from it. | mob: rune callers |
| 4 | Mess Hall | Level 1 (barracks) | 12 x 12 | Long tables. Bone Thralls. | mob: thralls; loot: chest |
| 5 | Kitchens | Level 1 (barracks) | 8 x 8 | Old pots. A loose floor stone hides a buried chest. | loot: chest; hid: buried chest |
| 6 | Barracks Row (corridor) | Level 1 (barracks) | 4 x 12 | Spears stab out from the weapon racks. Clue: rows of holes behind the racks, a rusty tip. Safe: crawl low, or go when they pull back. | trap: spear wall |
| 7 | Bunk Rooms | Level 1 (barracks) | 8 x 8 | Grave Creepers in the bunks. One wall is cracked. | mob: creepers; hid: cracked wall |
| 8 | Deserter's Stash | Level 1 (barracks) | 4 x 4 | Behind the cracked wall: what a deserter hid. | loot: vault chest |
| 9 | Training Yard | Level 1 (barracks) | 12 x 12 | Thralls drilling. Bear jaw traps in the sand. Clue: a rusty glint. Safe: step round; a friend can pry one open. | trap: bear jaws; mob: thralls |
| 10 | Armoury Door | Level 1 (barracks) | 8 x 8 | Locked: it needs the Armoury Key. | lock: locked door |
| 11 | Cellar Stair (corridor) | Level 1 (barracks) | 4 x 8 stair, 8 m between levels | Down to the drill cellars. |  |
| 12 | Drill Cellar | Level 2 (drill cellars) | 8 x 8 | Wardens and Thralls. A thin wire fires a crossbow. Clue: a shiny wire at ankle height. Safe: step over it, or cut it. | mob: wardens; mob: thralls; trap: tripwire crossbow |
| 13 | Practice Pit | Level 2 (drill cellars) | 8 x 8 | Old boards over a spike pit break when you step on them. Clue: cracked boards and a creak. Safe: keep to the solid edge along the wall. | **deadly: pit + spikes** |
| 14 | Sergeant's Quarters | Level 2 (drill cellars) | 8 x 8 | Sergeant Halfhelm holds the key. A portcullis slams down behind you. Clue: gate grooves in the doorway. Safe: wedge it with a rock, or win the fight. | boss: Sergeant Halfhelm; key: Armoury Key; trap: portcullis |
| 15 | Infirmary | Level 2 (drill cellars) | 8 x 8 | A healing shrine. | heal: healing shrine |
| 16 | Back Stair (corridor) | Level 1 (barracks) | 4 x 8 stair, 8 m between levels | Up to the Armoury Door. |  |
| 17 | Armoury | Level 1 (barracks) | 8 x 8 | Racks of old shields. A boulder hides a niche; its chest sits on spike holes. Clue: holes in the floor. Safe: shoot the chest first. | loot: chest; hid: hidden boulder; trap: trapped chest |
| 18 | Shield Bridge | Level 1 (barracks) | 4 x 14 (bridge), gap 10 deep | A bridge over a chasm. A spiked iron ball on a chain spins round a post in the middle and knocks you off. Grave Creepers. Clue: a scrape circle on the floor. Safe: run past right behind the ball, or shoot the chain. | **deadly: spiked flail + chasm**; mob: creepers |
| 19 | Banner Hall (corridor) | Level 1 (barracks) | 4 x 12 | Old banners of the shieldbearers. A quiet walk before the end. |  |
| 20 | Captain's Hall | Level 1 (barracks) | 12 x 14 | The Shield Captain and his guard. The recipe stand. A hidden door leads home. | mob: pack + leader; page: recipe stand; out: hidden door |

Paths: 1-2, 2-3, 2-4, 4-5, 4-6, 6-7, 7-8, 6-9, 9-10, 9-11, 11-12, 12-13, 13-14, 14-15, 15-16, 16-10, 10-17, 17-18, 18-19, 19-20, 20 → 1 (way out).

## Creatures

- Bone Warden: 2 room(s)
- Rune Caller: 1 room(s)
- Bone Thrall: 3 room(s)
- Grave Creeper: 2 room(s)
- Sergeant Halfhelm: 1 room(s)
- a pack with its leader (end fight): 1 room(s)

## Loot

- Side chest: 3-6 Rusty Scrap, 5-10 gold, 1-3 Bandages or 5 Stone Bolts, 30% a cooked food
- Hidden chest: 12-20 gold, 2-3 Copper Ingots, 30% a rune, 5% a gem
- Mini boss: drops the key, 5-10 gold
- Recipe stand + big chest: this dungeon's page, 20-30 gold, 25% an Old Blueprint the group doesn't know yet, 8% a gem
- Everything refills 1 hour of play after it was taken (DungeonLoot).

## 3D models it needs

| Model | Status | Note |
|---|---|---|
| Stonehold stone building pieces (walls, floors, round doorways, stairs, pillars, beams, railings, ladders) | exists | |
| dungeon_entrance (stone/brick version) | new | the round door in the cave wall |
| floor_loose_stone + chest | exists |  |
| trap_spear_wall (iron spears) | new |  |
| wall_cracked / wall_broken | exists |  |
| trap_bear_jaw (open + shut) | new |  |
| door_locked_round (stone/brick, with a keyhole) | new |  |
| trap_tripwire_crossbow (crossbow + wire + peg) | new |  |
| trap_floor_break | exists |  |
| trap_spikes | exists |  |
| tr_key_copper / tr_key_iron (recoloured per key) | exists | key items are new code |
| portcullis (stone/brick frame) | new |  |
| healing shrine | check | Mossgate Hold has one: check the PC's kit |
| cave boulder (Boulders.SHAPES) | exists |  |
| floor_spike_holes | new | shoot the chest first: the spikes fire and pull back |
| bridge_stone_slab (+ cracked) | new | stone/brick bridge slabs that fall away |
| trap_flail (post + chain + spiked ball) | new | ragdoll on hit |
| recipe_stand + recipe_scroll | exists |  |
| lever + hidden door (wall piece) | exists |  |
| chests (chest_loot, chest_small), furniture, crystal torches, hanging_lantern | exists | |
