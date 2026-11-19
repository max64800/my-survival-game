# Zone 1 dungeons (owner, Nov 19, 2026; F237)

Goal: fill Mossy Hollows before any new zone. Today it has 2 real places (the start tower, the Fallen Outpost)
and ~3 one-chest ruins + ~4 camps. This plan adds **10 new dungeons** → **12 in total** with the 2 we have.
Status: step 1 built (Nov 20). **Changed by the owner on Nov 20, read this first:**
- The Fallen Outpost and the start tower are **ruins**, not dungeons: they give building plans (blueprints), recipe
  pages and tools, and stay as they are. Outposts and towers are a ruin kind only.
- The **12 dungeons are all new places** dug into the caves, in 3 sizes, each size its own building material so
  players see all three: **4 small (wood), 5 medium (Stonehold stone), 3 big (Hearthbrick clay)**.
  A run through one takes about **5 / 8 / 12 minutes** (small / medium / big).
- They sit in **rings by size**: small 40-100 m from the start, medium 100-170 m, big 170 m+; at least 40 m apart,
  never in the Fallen Outpost's or the start tower's cavern.
- **Monsters and loot come back 1 hour of play** after someone takes from a chest (the clock only runs while the
  world is played). The page always teaches the same recipe and its name says which ("Weaponsmith's Page: Copper Mace").
- **Each dungeon gets its own name** (our own lore, from a list, picked by the world seed).
- **Guards: wait for new monsters.** The places get built first; guards are chosen when new creatures exist.
- **Still open:** which kinds of dungeon (the owner has a different idea from mines / tombs / forges, to hear next) and
  which kind teaches which copper recipes. The table and build order below are from Nov 19 and will be redone then.

Built in step 1: `page_<recipe>` items (one per copper recipe, src/items/items.gd), reading one teaches exactly that
recipe (game_authority.gd _learn_from_page), `DungeonLoot` (src/world/dungeon_loot.gd: dungeon chests, the 1-hour
refill on `world_state.played`, and `recipes_for(seed, ...)` which shuffles a kind's recipes per world).
Test: tests/test_dungeons.gd.

## The owner's picks (Nov 19)
- **Mix of sizes:** 3 big, 9 medium, and the small one-chest ruins/camps stay as they are.
- **4 kinds of dwarf places:** old outposts, abandoned mines, old forges, old tombs.
- **Pages are themed:** each kind of place holds one kind of copper recipe.
- **Both come back:** monsters and common loot refill after a while. **Each dungeon always teaches the same copper
  recipe** (if it gave you the mace, it gives the mace again, e.g. for a friend). For other recipes, explore other dungeons.

## The 12 dungeons (Claude's draft, Nov 20, waiting for the owner's OK)
Dungeons teach recipes. Each size has its own building material: small = root wood (Shack pieces), medium = Stonehold
stone, big = Hearthbrick clay. Inside a size group, which dungeon teaches which of that group's recipes is shuffled
per world (DungeonLoot.recipes_for). #1 is the PC chat's Mossgate Hold (Nov 19, code still only on the PC).

| # | Name | Material, size, run | What it is | Teaches one of |
|---|---|---|---|---|
| 1 | Mossgate Hold (started) | wood, small, 5 min | root-wood rooms behind a round stone door: traps, chasm, pack leader | Copper Axe, Crossbow, Spear, Copper-shod Boots |
| 2 | Lampwick Drift | wood, small, 5 min | an old mine tunnel, timber props, its far end flooded | (same 4) |
| 3 | Old Pell's Diggings | wood, small, 5 min | a miner's hut on top, a short shaft with ladders below | (same 4) |
| 4 | Mossprop Workings | wood, small, 5 min | wooden walkways and ladders up a cliff face | (same 4) |
| 5 | Tomb of Hald Ironbrow | stone, medium, 8 min | a long hall to one warrior's stone coffin | Copper Helm, Mail, Greaves, Shield, Sword |
| 6 | The Quiet Barrows | stone, medium, 8 min | rows of small burial rooms off one corridor | (same 5) |
| 7 | Greywater Crypt | stone, medium, 8 min | a crypt half under a pool | (same 5) |
| 8 | Hall of the Shieldbearers | stone, medium, 8 min | a guard hall with shield racks and a gatehouse | (same 5) |
| 9 | Vigil of Orrin Stonejaw | stone, medium, 8 min | a lookout shrine up winding stairs | (same 5) |
| 10 | Emberdeep Forge | clay brick, big, 12 min | a great forge with bellows, 2 floors | Copper Mace, Two-handed Axe, Two-handed Mace |
| 11 | The Hammerfall Works | clay brick, big, 12 min | workshops round a broken anvil | (same 3) |
| 12 | Cinderhold Foundry | clay brick, big, 12 min | smelters and a brick bridge over a chasm | (same 3) |

Small 40-100 m from the start, medium 100-170 m, big 170 m+.

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

## One dungeon = one copper recipe (Nov 19 version, replaced by the table above)
There are 12 copper recipes and 12 dungeons. Which dungeon gets which recipe (within its kind) is picked from the
world seed, so every world is a bit different, but you need to visit all 12 to learn everything.

| Kind | Size | How many | Recipes they teach | Also |
|---|---|---|---|---|
| Old outposts (Fallen Outpost + 3 new) | 1 big, 3 medium | 4 | Copper Helm, Mail, Greaves, Boots | rebuild into a second base (blueprints) |
| Old forges | 1 big Forge Hall, 2 medium smithies | 3 | Copper Sword, Mace, Spear | a broken anvil/forge you can repair |
| Abandoned mines | 2 medium | 2 | Copper Axe, Copper Crossbow | rails and carts, old copper veins, cave-in danger |
| Old tombs | 1 big, 2 medium | 3 | Copper Shield, Two-handed Axe, Two-handed Mace | traps, a stone guardian, rare gems and runes |

The start tower keeps its job (first home + rune memory that starts the trail to the boss). Cook's Pages stay in
the small ruins and camps.

## What a medium dungeon is
A few rooms (3-6), guards that fit the place, one "page room" at the end with a locked or hidden chest, and
1-2 side chests with common loot (scrap, coins, seeds, rope). A big one has more rooms or floors and a tougher guard.

## Coming back
- Monsters return a few in-game days after the place is cleared. Common loot refills on the same clock.
- The page chest refills too, always with the **same** recipe.
- A place you have **rebuilt** (outposts) stops spawning monsters inside (it's your base now).

## Build order (each step playable)
1. Recipe pages that teach one fixed recipe (today a page teaches a random one of its kind) + the respawn clock.
2. Medium outpost (reuses the Fallen Outpost kit and the rebuild system) ×3.
3. Medium smithy, then the big Forge Hall.
4. Abandoned mine ×2 (rails, carts).
5. Tombs: 2 medium, then the big one (traps, guardian).
6. Placement test for every new place (the Nov 17 placement rule) and a robot that checks all 12 exist in a world.

## Still to decide
- Names for each place (original, our own lore).
- Guards per kind (beetles, bats, spiders, a new tomb guardian?).
- How far apart they sit, and whether the map hints at them (rune memories, wall markings).

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
