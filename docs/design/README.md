# Design docs: index and open questions

*Written: November 14, 2026 (after the review that made the three docs agree).*

The big plan is `docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md` ("the spec"). The owner
approved it, so it always wins. The three docs below add the details and numbers.

## The docs

| Doc | What it covers (one line) | Built in |
|---|---|---|
| [`armor.md`](armor.md) | **Proposal**: armor pieces, 5 material sets, numbers, 6 questions for the owner (the look is already built). | When the owner answers |
| [`combat-and-monsters.md`](combat-and-monsters.md) | Fighting rules, weapons, gems, every monster, pack leaders, bosses, raids, co-op scaling. | Steps 5–6 |
| [`progression-and-economy.md`](progression-and-economy.md) | Every item, digging hardness, tools and tiers, stations, lantern, food and water, levels, skills, runes, death, bag, pacing. | Step 3 (some Step 1) |
| [`ai-art-pipeline.md`](ai-art-pipeline.md) | Using ChatGPT + "image → 3D" tools to make props, textures and icons, and getting them into the game. | Visual steps V3+ |
| [`visuals-plan.md`](visuals-plan.md) | How the game gets its look: light, fog, rock textures, shapes, the dwarf model, animations, where to get assets. | Visual steps V0–V5 |
| [`world-and-building.md`](world-and-building.md) | The star of 7 biomes, how caves are made, special places, the map, building pieces, cave-ins, blueprints, co-op world edits. | Steps 1, 3, 4, 6 |

**Who owns what** (if two docs ever disagree again, this decides):
- **Item ids, recipes, stations, hardness, yields, lantern, food, runes, XP:** progression doc.
- **Health and stamina numbers, weapons, monsters, bosses, drops, gems, raids:** combat doc.
- **Rock materials and where they are, caves, places, map, building pieces, cave-ins, blueprints:** world doc.
- **Anything already in the Step 1 code** (`src/world/mat.gd`, `src/items/items.gd`, `src/player/lantern.gd`): the code is the truth until a doc says "change it in Step X".

## Not designed yet (gaps found in the review)

1. **Armor and weapon recipes.** The combat doc says "the crafting doc" makes them; the progression doc says "the combat doc" does. Neither has them yet. Write them before Step 5.
2. **Special monster materials** (Glitter dust, Venom sac, Queen's carapace…): they drop, but no recipe uses them yet. Same time as item 1.
3. **Biomes 3–7:** only placeholders (spec: "we design one biome at a time").

## Open questions for the owner

Each question has a default marked ★. The docs already use the ★ answer. If you like it, do nothing. If not,
tell Claude the number and the letter (for example "7B").

### Controls and fighting
1. **Heavy attack button:** (A) ★ hold left click 0.3 s, (B) a separate key (middle mouse or Q), (C) Shift + left click.
2. **Dodge-roll button:** (A) ★ Left Ctrl + direction, (B) double-tap a direction, (C) Alt.
3. **Aiming in fights:** (A) ★ soft aim help only (turns you up to 30°), (B) a lock-on key that keeps the camera on one enemy, (C) both, player chooses in settings.
4. **Friendly fire damage:** (A) ★ half damage, (B) full damage, (C) quarter damage.
5. **Hand lantern and two hands:** while you hold the hand lantern (first ~2.5 hours), (A) ★ no shield, no two-handed weapons, no crossbow, so the back lantern feels like a big upgrade, (B) no limits.

### Monsters, bosses and raids
6. **Big monsters and tunnels:** (A) ★ Large and Huge monsters can't follow you into dug tunnels (digging is an escape), (B) some monsters can burrow after you, (C) they wait outside forever.
7. **Raids when nobody is home:** (A) ★ no raids unless a player is within 40 m of the base, (B) raids happen anyway and can damage buildings.
8. **Boss clue markings:** (A) ★ 3 per biome, you need all 3, (B) 5 per biome, any 3 are enough (easier to find).
9. **Main boss lair:** (A) ★ sealed in rock, you dig in after the 3rd clue, (B) behind a hidden breakable wall at the end of a tunnel, (C) behind a door that only opens after the 3rd clue.
10. **Epic gems from the first two bosses** (you can't use them until Steel): (A) ★ you choose 1 of 2 on first kill, (B) random, (C) no epic gems until the Steel biome.
11. **Taking a gem out of gear:** (A) ★ the gem is kept, costs 5 blue glow crystals, (B) free, (C) the gem breaks.

### Tools, items and crafting
12. **Tools wearing out?** (A) ★ never, (B) slowly wear out, repair at the Anvil for a few ingots.
13. **Ore to ingot:** (A) ★ 2 ore → 1 ingot (about one ingot per ore dig), (B) 1 ore → 1 ingot (half the mining).
14. **Stations take materials from nearby chests?** (A) ★ yes, within 10 m, (B) no, only from your bag.
15. **Do brewed drinks use one of the 3 buff slots?** (A) ★ yes, same slots as dishes, (B) separate: 3 food slots + 1 drink slot.

### Growing your dwarf
16. **Rune set sizes:** (A) ★ Mossy 5 per colour, Fungal 6, (B) 6 everywhere, (C) 4 everywhere (quicker to finish).
17. **Changing your perks (respec):** (A) ★ cheap, at the Rune Slab, (B) free, any time, (C) never.
18. **Max character level for the first release:** (A) ★ 30 (fits two biomes), (B) 50 (room to grow, slower levels).
19. **What stays on you when you die?** (A) ★ armor, lantern and hotbar tools/weapons stay; everything else goes in the grave, (B) everything goes in the grave (harder), (C) only materials go in the grave; food and gear stay (easier).

### World and map
20. **Which way is the Fungal Jungle?** (A) ★ East, (B) North, (C) West, (D) South (only changes how the map looks).
21. **Border gates:** (A) ★ gate tunnels leave a thin 4 m plug to dig, (B) no gates, the whole 20 m wall is the same everywhere, (C) gates only, the rest of the border can never be dug.
22. **Is the map shared in co-op?** (A) ★ one shared map for everyone, (B) each player has their own map, (C) own map, but you can "copy map" at a map table.

### Building and cave-ins
23. **Building grid size:** (A) ★ 2 m, chunky dwarf blocks, (B) 1 m, finer detail but more pieces to place, (C) 2 m with free 1 m half-pieces everywhere.
24. **May you carve rock when placing pieces by hand?** (A) ★ no, only blueprints carve, (B) yes, holding a key carves the spot (takes digging time), (C) only after a Smith & Builder skill.
25. **Builder's Chest is out of one material. What should it do?** (A) ★ keep building other pieces it can afford, bottom-up, (B) stop completely until that material arrives.
26. **How much do cave-ins hurt?** (A) big damage (real danger), (B) ★ light damage + knockback, (C) no damage, just a scare.
