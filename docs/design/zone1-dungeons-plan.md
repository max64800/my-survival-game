# Zone 1 dungeons (owner, Nov 19, 2026; F237)

Goal: fill Mossy Hollows before any new zone. Today it has 2 real places (the start tower, the Fallen Outpost)
and ~3 one-chest ruins + ~4 camps. This plan adds **12 new dungeons** (the start tower and the Fallen Outpost are ruins).
Status: step 1 built (Nov 20). **Changed by the owner on Nov 20, read this first:**
- The Fallen Outpost and the start tower are **ruins**, not dungeons: they give building plans (blueprints), recipe
  pages and tools, and stay as they are. Outposts and towers are a ruin kind only.
- The **12 dungeons are all new places** dug into the caves, in 3 sizes, each size its own building material so
  players see all three: **4 small (wood), 5 medium (Stonehold stone), 3 big (Hearthbrick clay)**.
  A run through one takes about **8-10 / 12-15 / 20-25 minutes** (small / medium / big; owner grew them on Nov 20).
- They sit in **rings by size**: small 40-100 m from the start, medium 100-170 m, big 170 m+; at least 40 m apart,
  never in the Fallen Outpost's or the start tower's cavern.
- **Monsters and loot come back 1 hour of play** after someone takes from a chest (the clock only runs while the
  world is played). The page always teaches the same recipe and its name says which ("Weaponsmith's Page: Copper Mace").
- **Each dungeon gets its own name** (our own lore, from a list, picked by the world seed).
- **Guards:** dungeon creatures from the KayKit Skeletons pack (CC0), made into dwarf skeletons on the PC.
- **Kinds (Nov 20):** small = old wooden mines, medium = stone tombs, vault, barracks and a rune temple, big = clay
  brick forge halls. The build order is in `docs/design/zone1-dungeons/00-missing-and-build-order.md`.

Built in step 1: `page_<recipe>` items (one per copper recipe, src/items/items.gd), reading one teaches exactly that
recipe (game_authority.gd _learn_from_page), `DungeonLoot` (src/world/dungeon_loot.gd: dungeon chests, the 1-hour
refill on `world_state.played`, and `recipes_for(seed, ...)` which shuffles a kind's recipes per world).
Test: tests/test_dungeons.gd.

## The 12 dungeons (owner liked the small and medium drafts, Nov 20; big ones drafted overnight)
Full maps, room sizes, creatures, loot and model lists: **`docs/design/zone1-dungeons/`** (one file each, plus
`00-missing-and-build-order.md`). The maps live in `tools/dungeon_pages/` (also the owner's pages "Small Wooden
Dungeons", "Medium Stone Dungeons", "Big Clay Dungeons"); `gen_docs.js` writes the files, `check.js` checks the rules.
The list in code: `src/world/dungeon_list.gd` (`DungeonList.recipe_of(seed, id)`).

| # | Name | Size, material | Spaces | Deadly traps | Teaches one of (shuffled per world) |
|---|---|---|---|---|---|
| 1 | Mossgate Hold (PC) | small, wood | 15 | chasm, spike pit | Copper Axe, Crossbow, Spear, Copper-shod Boots |
| 2 | Lampwick Drift | small, wood | 13 | the Old Shaft | (same 4) |
| 3 | Old Pell's Diggings | small, wood | 13 | Rotten Gallery | (same 4) |
| 4 | Mossprop Workings | small, wood | 14 | Plank Bridge | (same 4) |
| 5 | Tomb of Hald Ironbrow | medium, stone | 20 | Broken Stair, Bridge of Oaths | Copper Helm, Mail, Greaves, Shield, Sword |
| 6 | The Quiet Barrows | medium, stone | 20 | Sunken Barrow, Ash Bridge | (same 5) |
| 7 | Brassgate Vault | medium, stone | 20 | Coin Chute, Great Crusher | (same 5) |
| 8 | Hall of the Shieldbearers | medium, stone | 20 | Practice Pit, Shield Bridge | (same 5) |
| 9 | Vigil of Orrin Stonejaw | medium, stone | 20 | Hall of Echoes, Broken Bridge | (same 5) |
| 10 | Emberdeep Forge | big, clay brick | 30 | Quench Hall, Rolling Ingot Ramp, Crucible Bridge | Copper Mace, Two-handed Axe, Two-handed Mace |
| 11 | The Hammerfall Works | big, clay brick | 30 | Molten Channel, Great Press, Rolling Anvil | (same 3) |
| 12 | Cinderhold Foundry | big, clay brick | 28 | First Bridge, Casting Floor, Chain Bridge | (same 3) |

Owner's rules for all of them (Nov 20): small 8-10 min, medium 12-15 min (a key, a locked door, a mini boss), big
20-25 min. Every trap has a clue and a safe way through (time it, bait it and step back, or shoot its switch with a
crossbow). Molten metal only in stone channels that can't spill (it kills like spikes). No water. Inside live the
KayKit skeleton dwarves (Lost Miner, Tunnel Rat, Foreman; Bone Thrall, Bone Warden, Rune Caller, Grave Creeper);
bats, snails and beetles stay outside. Rings: small 40-100 m from the start, medium 100-170 m, big 170 m+.
Still open: a real boss in the big ones, lever puzzles, spiders inside or not.

## Ruins (Claude's draft, Nov 20, waiting for the owner's OK)
Ruins teach buildings: put materials in the Rebuilding Chest, rebuild it, learn its blueprint (ruin-rebuild-plan.md).
Their chests hold tools and building plans. No dungeon-style traps; a few creatures at most. Three of each material.

| # | Name | Material | What it is | Rebuilding teaches | Also inside |
|---|---|---|---|---|---|
| 1 | Delver's Lodge | wood | a fallen-in two-room hut by a stream (sloped roof) | Delver's Hut | tools (stone pickaxe, axe), rope |
| 2 | Rope Bridge Camp | wood | a broken bridge across a gap, a tent and a lookout | Root-wood Bridge | crossbow bolts, rope, a Toolmaker's page |
| 3 | Rootmill | wood | a wooden sawmill round a big root tree | Root-wood Workshop | planks, a saw, an Old Blueprint |
| 4 | The start tower (exists) | stone | the ruined watchtower in the first cave | Stone Watchtower | its 4 chests |
| 5 | Fallen Outpost (exists) | stone | the big ruined fort, 160 m out | Stone Outpost | its chests and Outpost Plans |
| 6 | Waygate | stone | a gatehouse across a tunnel, with a round door (flat roof) | Stone Gatehouse | copper tools, a lever |
| 7 | Hearthstead | clay brick | a brick family home with a chimney (sloped roof) | Hearthbrick House | a Cook's page, pots, food |
| 8 | Kiln Yard | clay brick | brick kilns and a drying shed | Brick Kiln Yard | clay, bricks, a furnace |
| 9 | Old Brewhouse | clay brick | a brick brewhouse with cracked vats | Hearthbrick Brewhouse | a drink recipe, barrels |

## 📌 For the PC (owner, Nov 20): do these next
1. **Push Mossgate Hold.** Its code (`src/world/dungeon_map.gd`, `blueprints/dungeons/mossgate_hold.json`,
   `src/debug/dungeon_test_start.gd`, cave_maker hooks) is only on the PC. Commit and push it first.
2. **Dungeon monsters from a pack** (Blender work, PC only). Owner picked **KayKit Skeletons** (CC0,
   https://kaylousberg.itch.io/kaykit-skeletons) + **KayKit Character Animations** (CC0,
   https://kaylousberg.itch.io/kaykit-character-animations). Read every file before using it (global rule).
   Make them ours: old dwarf miners who never left. Dwarf-sized (scale bones a little), repainted hand-painted
   (aged bone, moss, dirt, faint glowing eyes), our own helmets/picks/root-wood bits; keep KayKit's animations.
   Ideas: **Lost Miner** (slow, tough), **Tunnel Rat** (small, fast, groups), **Foreman** (big armoured leader at the
   recipe stand). Bats, snails and rock beetles stay outside the dungeons. Picture of the 4 as they come, then a first
   Lost Miner; at most 2 picture rounds before asking. MODEL-RULES.md + CREATURE-STYLE.md; log both in CREDITS.md.
3. The 3 new small dungeons (#2 Lampwick Drift, #3 Old Pell's Diggings, #4 Mossprop Workings) are drawn on the Mac
   page "Small Wooden Dungeons" (owner liked them): 13-14 spaces, 1 deadly trap + 4-5 others, 3 hidden things each,
   no water. Build after Mossgate Hold, with Mossgate's kit and `DungeonLoot` (recipe page + 1-hour refill).
