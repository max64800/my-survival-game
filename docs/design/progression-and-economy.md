# Progression and Economy — Design Doc

*Written: November 14, 2026. Covers Mossy Hollows + Fungal Jungle.*
*Builds on:* `docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md` (the approved plan, "the plan" below).
*Sister doc:* `docs/design/combat-and-monsters.md` owns weapon stats, armor stats, gems, monsters and bosses. This doc only points to it.

---

## 0. How to read this doc

**For the owner:** this is the "numbers book" of the game. It says what every item is, how long things take, and how your dwarf gets stronger. Every number is a **starting value**. We change them after playing ("tune in playtest").

**For the Claude session that builds it:**
- Put every number from this doc in **data files**, not inside code. Suggested: one Godot Resource (`.tres`) per item, station and recipe under `data/`, plus one `data/balance.tres` for the global numbers (drain rates, curves). Then tuning means editing data, not code.
- Every random roll (drops, quality, rune picks) happens on the **host**, then everyone is told the result. This follows the plan's "request → host approves → everyone updates" rule.
- Ids are `snake_case` and never change after release (saves use them). Display names can change any time.

**Words used in this doc (each defined once):**

| Word | Meaning |
|---|---|
| **Stack** | How many of the same item fit in one bag slot. |
| **Tier** | A "generation" of gear: Stone → Copper → Silver → Iron → Steel. |
| **Upgrade (+1..+3)** | Improving one tool you already own at the forge. |
| **Quality (Q1–Q5)** | How well a tool was made. Rolled once, when it's crafted. |
| **Buff** | A small, temporary boost (for example +20% max health for 30 min). |
| **XP** | "Experience points." You earn them by doing things. |
| **Skill level (0–100)** | How practiced you are at one kind of work. Goes up by **using** it. |
| **Character level (1–30)** | Your dwarf's overall level. Each level gives **perk points**. |
| **Perk** | One choice in a skill tree, bought with perk points. |
| **Rank** | Some perks can be bought more than once. Each buy is a rank. |
| **Prerequisite** | Something you need first (another perk, or a skill level). |
| **Station** | A crafting machine you build at your base (workbench, smelter…). |
| **Drop rate** | The chance (in %) that something falls out. |

---

## 1. Items master list

**Stack rule:** default stack is **100**. Tools, weapons, armor, waterskins and the lantern stack to **1**. Cooked dishes and drinks stack to **20** (so nobody carries 300 pies). Runes and rune shards stack to **100**.

**Where found:** "MH" = Mossy Hollows, "FJ" = Fungal Jungle.

### 1.1 Rock, soil and building stone (raw)

| id | Name | Stack | Where found | What it's for |
|---|---|---|---|---|
| `dirt` | Dirt | 100 | MH, FJ (everywhere soft) | Farm plots, filling holes, cheap building |
| `moss` | Moss Clump | 100 | MH walls and floors, FJ rare | Beds, farm plots, Spore Ward Stew |
| `stone` | Stone | 100 | MH, FJ (most common rock) | Stations, stone tools, cut stone |
| `clay` | Orange Clay | 100 | MH stream banks, FJ damp pockets | Smelter, clay bricks, mushroom bricks, lantern lens |
| `marble` | White Marble | 100 | MH rare pockets (deep floors) | Cut marble (fancy building style) |
| `sporestone` | Sporestone | 100 | FJ (replaces most stone) | Sporestone blocks (dark building style) |
| `amberrock` | Amberrock | 100 | FJ bands in cavern walls | Amber blocks (yellow building style) |
| `ancient_brick` | Ancient Brick | 100 | Old dwarf ruins (MH, FJ) | Ruin-style building pieces |

### 1.2 Ores and crystals (raw)

| id | Name | Stack | Where found | What it's for |
|---|---|---|---|---|
| `copper_ore` | Copper Ore | 100 | MH veins (common) | Smelt to copper ingots |
| `silver_ore` | Silver Ore | 100 | FJ veins (needs Copper pickaxe) | Smelt to silver ingots |
| `crystal_blue` | Blue Glow Crystal | 100 | MH walls (common), FJ (uncommon) | Lantern fuel, lantern lens, sconces |
| `crystal_green` | Green Glow Crystal | 100 | MH (uncommon, near streams) | Lantern fuel, +2 upgrades (Copper tier) |
| `crystal_violet` | Violet Glow Crystal | 100 | FJ (common) | Lantern fuel, +2 upgrades (Silver tier) |
| `crystal_amber` | Amber Glow Crystal | 100 | FJ (uncommon, near giant mushrooms) | Lantern fuel, Bright Lantern |
| `crystal_white` | White Glow Crystal | 100 | MH + FJ rare; side bosses; ruin chests | Best lantern fuel, +3 upgrades, respec |

### 1.3 Wood, plants and mushrooms (raw)

| id | Name | Stack | Where found | What it's for |
|---|---|---|---|---|
| `rootwood` | Rootwood | 100 | MH giant hanging roots (chop with axe) | Planks, fuel, stone tools |
| `mushroom_wood` | Mushroom Timber | 100 | FJ giant mushroom stalks (Copper axe+) | Mushroom planks, fuel |
| `fiber` | Cave Fiber | 100 | Vines and moss tufts (pick by hand), MH, FJ | Rope |
| `root_tuber` | Root Tuber | 100 | Dug from dirt near giant roots, MH | Cooking, brewing, farmable |
| `glowcap` | Glowcap | 100 | MH walls (blue glowing mushroom) | Snacks, tea, broth, farmable |
| `hollowcap` | Hollowcap | 100 | MH floors (brown mushroom) | Stews, ale, farmable |
| `bellcap` | Juicy Bellcap | 100 | MH near water, FJ common | Eat raw = food **and** drink, farmable |
| `firecap` | Firecap | 100 | MH rare (small red mushroom) | Damage dishes, cordial, farmable |
| `mushroom_flesh` | Giant Mushroom Flesh | 100 | FJ, drops when chopping giant mushrooms | Stalk steak, mushroom bricks |
| `spore_truffle` | Spore Truffle | 100 | FJ, dug from sporestone floors | Risotto, mead, farmable |
| `ember_morel` | Ember Morel | 100 | FJ near spore vents (red-orange) | Damage dishes, farmable |

### 1.4 Animal parts (raw)

Animal species and their stats live in the combat doc. This doc only names what they drop.

| id | Name | Stack | Where found | What it's for |
|---|---|---|---|---|
| `critter_meat` | Critter Meat | 100 | MH critters | Cooking |
| `critter_hide` | Critter Hide | 100 | MH critters | Leather, waterskin |
| `beetle_meat` | Beetle Meat | 100 | FJ beetles and bugs | Cooking |
| `chitin_plate` | Chitin Plate | 100 | FJ beetles and bugs | Silver-tier tools, chitin chest |

### 1.5 Water

| id | Name | Stack | Where found | What it's for |
|---|---|---|---|---|
| `waterskin_empty` | Waterskin (empty) | 1 | Crafted | Fill at any water |
| `waterskin_dirty` | Waterskin (still water) | 1 | Filled at a still pool | Drink (small risk) or boil |
| `waterskin_clean` | Waterskin (clean) | 1 | Filled at a stream or drip bucket, or boiled | Drink: 5 sips |
| `water_bucket` | Bucket of Clean Water | 20 | Drip bucket | Cooking ingredient ("1 water" in recipes) |

A waterskin holds **5 sips**. Recipes that say "1 water" use either 1 `water_bucket` or 1 sip from a clean waterskin.

### 1.6 Refined items

| id | Name | Stack | Made at | Recipe | What it's for |
|---|---|---|---|---|---|
| `plank_root` | Rootwood Plank | 100 | Workbench | 1 rootwood → 2 | Building, stations, tools |
| `plank_mushroom` | Mushroom Plank | 100 | Workbench | 1 mushroom_wood → 2 | FJ building style, silver tools |
| `rope` | Rope | 100 | Hand | 3 fiber → 1 | Tools, chests, ladders |
| `leather` | Leather | 100 | Tanning Rack | 1 critter_hide → 1 (60 s) | Tools, lantern, bed |
| `copper_ingot` | Copper Ingot | 100 | Smelter | 2 copper_ore + 1 fuel → 1 | Copper tier |
| `silver_ingot` | Silver Ingot | 100 | Smelter | 2 silver_ore + 1 fuel → 1 | Silver tier |
| `clay_brick` | Clay Brick | 100 | Smelter | 2 clay + 1 fuel → 2 | Orange building style |
| `lantern_lens` | Crystal Lens | 100 | Smelter | 3 crystal_blue + 1 clay + 1 fuel → 1 | Lantern upgrades |
| `cut_stone` | Cut Stone | 100 | Masonry Table | 2 stone → 1 | Grey building style, Rune Slab |
| `cut_marble` | Cut Marble | 100 | Masonry Table | 2 marble → 1 | White building style |
| `sporestone_block` | Sporestone Block | 100 | Masonry Table | 2 sporestone → 1 | Dark building style |
| `amber_block` | Amber Block | 100 | Masonry Table | 2 amberrock → 1 | Yellow building style |
| `mushroom_brick` | Mushroom Brick | 100 | Masonry Table | 2 mushroom_flesh + 1 clay → 2 | FJ building style |

### 1.7 Boss parts and rune items

| id | Name | Stack | Where found | What it's for |
|---|---|---|---|---|
| `boss_trophy_mossy` | (name set by combat doc) | 100 | Mossy Hollows main boss, 1 per nearby player | Copper pickaxe |
| `boss_trophy_fungal` | (name set by combat doc) | 100 | Fungal Jungle main boss, 1 per nearby player | Silver pickaxe |
| `rune_<branch>_<set><n>` | Rune (e.g. `rune_miner_m1`) | 100 | See section 8 | Carve on the Rune Slab |
| `rune_shard_<branch>` | Rune Shard (4 colours) | 100 | Duplicate runes turn into these | 3 shards → any missing rune of that colour |

### 1.8 Future placeholders (not built until those biomes exist)

So the pickaxe ladder has numbers. These get redesigned when biomes 3 and 4 are designed.

| id | Stack | Placeholder source | Placeholder use |
|---|---|---|---|
| `iron_ore` | 100 | Biome 3 | Iron ingots |
| `iron_ingot` | 100 | Smelter: 2 iron_ore + 1 fuel | Iron tier |
| `coal` | 100 | Biome 4 | Steel |
| `steel_ingot` | 100 | Smelter: 1 iron_ingot + 2 coal → 1 | Steel tier |
| `boss_trophy_biome3` / `boss_trophy_biome4` | 100 | Those bosses | Iron / Steel pickaxe |

### 1.9 Tools (stack 1)

Weapons and armor are listed in the combat doc. Tools are here.

| id pattern | Tiers | What it does |
|---|---|---|
| `pickaxe_<tier>` | stone, copper, silver, iron, steel | Digs rock (section 2) |
| `axe_<tier>` | stone, copper, silver, iron, steel | Chops giant roots and mushrooms. Also a weak weapon (combat doc) |
| `build_hammer` | one tier | Places and removes building pieces (Step 4) |
| `lantern_hand`, `lantern_back`, `lantern_bright`, `lantern_grand` | — | Light (section 5) |
| `waterskin_*` | — | Water (section 6) |

---

## 2. Rock hardness and digging

### 2.1 How it works (simple)

Every material has a **hardness** number. Every pickaxe has a **dig power** number. Each swing does "dig power" damage to the spot you aim at. When the damage reaches the hardness, that spot is dug out.

- **Hits needed = hardness ÷ dig power, rounded up.**
- Some materials have a **minimum tier**. A weaker pickaxe just bounces off (spark + "clink" sound + a tip: "Needs a Copper pickaxe").
- One "spot" = a round blob about **1.2 m across**, so holes look smooth.
- One swing takes **0.75 s** and costs **5 stamina**.
- Damage on a half-dug spot fades back after **10 s** of not hitting it (so you can't "pre-chip" walls).

### 2.2 Dig power per pickaxe tier

| Pickaxe | Dig power | Comes from |
|---|---|---|
| Stone | 10 | You start with one |
| Copper | 13 | Copper ore + Mossy boss part |
| Silver | 17 | Silver ore + Fungal boss part |
| Iron (future) | 22 | Biome 3 |
| Steel (future) | 28 | Biome 4 |

**Final dig power** = base × (1 + quality bonus) × (1 + upgrade bonus) × (1 + Mining skill bonus) × (1 + perk/rune bonuses).

### 2.3 Hits per material (base Q1, +0, skill 0)

| Material | Hardness | Min tier | Stone | Copper | Silver | Iron | Steel |
|---|---|---|---|---|---|---|---|
| Dirt | 10 | Stone | 1 | 1 | 1 | 1 | 1 |
| Moss | 10 | Stone | 1 | 1 | 1 | 1 | 1 |
| Clay | 15 | Stone | 2 | 2 | 1 | 1 | 1 |
| Glow crystal (any colour) | 18 | Stone | 2 | 2 | 2 | 1 | 1 |
| Stone | 20 | Stone | 2 | 2 | 2 | 1 | 1 |
| Amberrock | 25 | Stone | 3 | 2 | 2 | 2 | 1 |
| Marble | 30 | Stone | 3 | 3 | 2 | 2 | 2 |
| Sporestone | 30 | Stone | 3 | 3 | 2 | 2 | 2 |
| Ancient brick | 40 | Stone | 4 | 4 | 3 | 2 | 2 |
| Copper ore | 45 | Stone | 5 | 4 | 3 | 3 | 2 |
| Silver ore | 55 | Copper | — | 5 | 4 | 3 | 2 |
| Iron ore (future) | 70 | Silver | — | — | 5 | 4 | 3 |
| **Border rock 1** (MH → FJ) | 80 | Copper | — | 7 | 5 | 4 | 3 |
| **Border rock 2** (FJ → biome 3) | 100 | Silver | — | — | 6 | 5 | 4 |

This matches the owner's rule: with the starting pickaxe, dirt is 1 hit, stone 2–3, ore 4–5. Each new pickaxe also gets "ore 4–5 hits" on its own biome's ore (Copper pick on silver = 5).

**Border rock** is a band about **3 m thick** at every biome edge, dark with glowing cracks. Breaking through takes about 1 minute with the right pickaxe. That's the "door" moment.

### 2.4 Yield per dug spot

| Material | Drops | Notes |
|---|---|---|
| Dirt | 2 `dirt` | 5% chance of 1 `root_tuber` near giant roots (MH) |
| Moss | 1 `moss` + 1 `dirt` | |
| Clay | 2 `clay` | |
| Stone / sporestone / amberrock / marble | 2 of that stone | |
| Ancient brick | 2 `ancient_brick` | |
| Copper ore | 2 `copper_ore` + 1 `stone` | |
| Silver ore | 2 `silver_ore` + 1 `sporestone` | |
| Glow crystal | 2–4 of that colour (even odds) | Crystals regrow on the same wall after 60 min if the spot isn't built over |
| Border rock | nothing | It's a wall, not a mine |
| Any stone or ore spot | 0.15% (MH) / 0.2% (FJ) chance of a **rune pebble** | See section 8 |

So **1 ore spot = 1 ingot** (2 ore → 1 ingot). Easy to remember.

### 2.5 Chopping (axes)

Same math as digging. Axe "chop power" = same numbers as the pickaxe of that tier (Stone 10, Copper 13, Silver 17…).

| Wood source | Hardness | Min tier | Stone | Copper | Silver | Yield per chop-through |
|---|---|---|---|---|---|---|
| Giant root (MH) | 30 | Stone | 3 | 3 | 2 | 3 `rootwood` |
| Giant mushroom stalk (FJ) | 45 | Copper | — | 4 | 3 | 3 `mushroom_wood` + 1 `mushroom_flesh` |

A giant root or mushroom has **4 chop points** (so about 12 rootwood per root). Chopped roots and mushrooms **regrow after 90 minutes** of world time, unless something is built within 4 m of them. Wood never runs out.

---

## 3. Tool tiers, the pickaxe ladder, upgrades and quality

### 3.1 The ladder (owner rule)

> The next pickaxe needs **the biome's best ore** AND **a part from that biome's main boss**.

```
Stone pickaxe (start)
   └─ mine copper in Mossy Hollows, find 3 wall markings, beat the Mossy boss
Copper pickaxe  = copper + Mossy boss part  → breaks Border rock 1 → Fungal Jungle
   └─ mine silver, beat the Fungal boss
Silver pickaxe  = silver + Fungal boss part → breaks Border rock 2 → biome 3
Iron, Steel     = same pattern, later biomes
```

Only the **pickaxe** needs the boss part. Axes and other tools of a tier only need the ore. That way you can enjoy copper gear before the boss, but you can't leave the biome until you beat it.

### 3.2 Tool recipes

| Tool | Station | Recipe | Unlocks when |
|---|---|---|---|
| `pickaxe_stone` | Workbench | 4 stone, 2 rootwood, 2 rope | Start (you also spawn holding one) |
| `axe_stone` | Workbench | 3 stone, 2 rootwood, 2 rope | Start |
| `build_hammer` | Workbench | 3 stone, 2 rootwood | Workbench built |
| `axe_copper` | Anvil | 6 copper_ingot, 3 plank_root, 1 leather | First copper ingot |
| `pickaxe_copper` | Anvil | 8 copper_ingot, 4 plank_root, 2 leather, **1 boss_trophy_mossy** | Holding the Mossy boss part |
| `axe_silver` | Anvil | 6 silver_ingot, 3 plank_mushroom, 2 chitin_plate | First silver ingot |
| `pickaxe_silver` | Anvil | 8 silver_ingot, 4 plank_mushroom, 2 chitin_plate, **1 boss_trophy_fungal** | Holding the Fungal boss part |
| `axe_iron` *(future)* | Anvil | 6 iron_ingot, 3 plank_mushroom, 2 leather | First iron ingot |
| `pickaxe_iron` *(future)* | Anvil | 8 iron_ingot, 4 plank_mushroom, 2 leather, 1 boss_trophy_biome3 | Biome 3 boss part |
| `axe_steel` *(future)* | Anvil | 6 steel_ingot, 3 plank_mushroom, 2 leather | First steel ingot |
| `pickaxe_steel` *(future)* | Anvil | 8 steel_ingot, 4 plank_mushroom, 2 leather, 1 boss_trophy_biome4 | Biome 4 boss part |

**Tool durability: none.** Tools never break or wear out. Losing gear only happens at death (and you keep tools then too, see section 9). This keeps the game gentle and saves a whole "repair" system. (Open question 1.)

### 3.3 Upgrades (+1, +2, +3)

You upgrade a tool you already own at the **Anvil** (the plan calls this "the forge"; the Anvil must stand within 5 m of a Smelter). Upgrades keep the tool's quality. The same table works for weapons and armor; the combat doc decides what "main stat" means for those.

| Level | Main stat bonus | Cost (per tier) |
|---|---|---|
| +1 | +8% | 3 ingots of that tier + 1 leather |
| +2 | +16% | 5 ingots + 2 of the tier crystal |
| +3 | +25% | 8 ingots + 1 `crystal_white` |

| Tier | "Ingot" | "Tier crystal" |
|---|---|---|
| Stone | 4 `stone` (and `rope` instead of leather) | `crystal_blue` |
| Copper | `copper_ingot` | `crystal_green` |
| Silver | `silver_ingot` | `crystal_violet` |
| Iron / Steel (future) | that ingot | decided with those biomes |

- **Main stat** for pickaxe = dig power. Axe = chop power. Lantern = has its own upgrade line (section 5).
- Example: a Q3 +3 Copper pickaxe = 13 × 1.08 × 1.25 = **17.6** dig power. Copper ore drops from 4 hits to 3.
- Upgrading never lets a tool break a material above its **minimum tier**. A super Stone pickaxe still can't dig border rock.

### 3.4 Quality (Q1–Q5)

When you craft a tool, weapon or armor piece, the game rolls its quality once. The roll uses **the crafter's Smithing skill** (section 7). In co-op, whoever presses "craft" is the crafter.

| Quality | Name shown | Main stat bonus | Look |
|---|---|---|---|
| Q1 | Plain | +0% | Normal |
| Q2 | Fine | +4% | Small mark on the handle |
| Q3 | Sturdy | +8% | Engraved lines |
| Q4 | Superior | +13% | Engraved + faint shine |
| Q5 | Masterwork | +20% | Glowing runic engraving, crafter's name on it |

**Chance table** (each row adds up to 100%):

| Smithing skill | Q1 | Q2 | Q3 | Q4 | Q5 |
|---|---|---|---|---|---|
| 0–9 | 70% | 25% | 5% | 0% | 0% |
| 10–24 | 45% | 35% | 17% | 3% | 0% |
| 25–39 | 25% | 35% | 30% | 9% | 1% |
| 40–59 | 10% | 25% | 40% | 20% | 5% |
| 60–79 | 0% | 15% | 35% | 35% | 15% |
| 80–100 | 0% | 5% | 25% | 40% | 30% |

Perks and runes that say "+5 Smithing for quality" just move you down this table sooner (they only count for the quality roll).

Named items found in ruins have fixed stats set by hand (combat doc / loot tables), not this roll.

---

## 4. Crafting stations

### 4.1 Unlock order

A recipe "unlocks" (appears in the menu) the first time you pick up one of its key items. Nothing is hidden behind a menu you have to discover by accident.

| # | Station | Recipe | Unlocks when | Fuel | What it makes |
|---|---|---|---|---|---|
| 0 | **Hand** (bag menu) | — | Start | — | Rope, campfire, workbench, waterskin |
| 1 | **Campfire** | 5 stone, 3 rootwood | Start | Wood: 1 piece burns 4 min | Simple cooked food, boils water |
| 2 | **Workbench** | 10 rootwood, 6 stone | Start | — | Stone tools, planks, chests, bed, farm plot, drip bucket |
| 3 | **Bed** | 6 plank_root, 4 moss, 2 leather | Workbench | — | Your wake-up point |
| 4 | **Tanning Rack** | 6 plank_root, 4 rope | First `critter_hide` | — | Leather |
| 5 | **Smelter** | 20 stone, 15 clay | First `copper_ore` | Any wood | Ingots, clay bricks, crystal lens |
| 6 | **Anvil** | 10 stone, 6 copper_ingot | First `copper_ingot` | — | Metal tools, upgrades, lantern upgrades |
| 7 | **Cooking Pot** | 4 copper_ingot, 4 stone | First `copper_ingot` | Needs a lit Campfire under it | Dishes, teas, boiled water |
| 8 | **Farm Plot** | 10 dirt, 5 moss, 4 plank_root | First mushroom picked | — | Grows mushrooms and tubers |
| 9 | **Drip Bucket** | 4 plank_root, 1 rope | First water drunk | — | Clean water (section 6.4) |
| 10 | **Masonry Table** | 10 stone, 6 plank_root, 2 copper_ingot | First `copper_ingot` | — | Cut stone, blocks, mushroom bricks |
| 11 | **Brewing Barrel** | 10 plank_root, 2 copper_ingot, 2 rope | First `root_tuber` + Cooking Pot built | — | Ales and meads |
| 12 | **Rune Slab** | 15 stone, 5 cut_stone | First rune picked up | — | Carve runes, respec |
| 13 | **Chests** | see section 10 | Workbench | — | Storage |

**Stations use nearby chests.** When you craft at a station, it can take materials from your bag **and** any chest within **10 m** of it. (This saves a lot of walking back and forth. If it causes co-op bugs, it can wait until Step 4.)
### 4.2 Smelter details

| Input | Output | Time | Fuel |
|---|---|---|---|
| 2 copper_ore | 1 copper_ingot | 20 s | 1 wood |
| 2 silver_ore | 1 silver_ingot | 30 s | 1 wood |
| 2 clay | 2 clay_brick | 10 s | 1 wood per 2 batches |
| 3 crystal_blue + 1 clay | 1 lantern_lens | 30 s | 1 wood |
| 2 iron_ore *(future)* | 1 iron_ingot | 40 s | 1 wood |

- "Wood" = `rootwood` or `mushroom_wood`. Planks are **not** fuel (stops accidents).
- The smelter holds up to **20 ore** and **20 fuel**. It keeps working while you're away (host keeps the clock).
- Output piles up inside (max 50) until someone takes it.

### 4.3 Other station timings

| Station | Job | Time |
|---|---|---|
| Workbench, Anvil, Masonry Table | Any craft | Instant (with a short 0.5 s hammer animation) |
| Tanning Rack | 1 hide → 1 leather | 60 s, holds 10 |
| Campfire | Cook a simple dish | 10 s |
| Campfire | Boil 1 waterskin | 10 s |
| Cooking Pot | Cook a pot dish | 20 s |
| Brewing Barrel | Brew a drink | 15 min, makes 3 at once |

---

## 5. The lantern

### 5.1 How fuel works

- The lantern has **one fuel slot** that holds up to **20 pieces** of one fuel type.
- It burns one piece at a time. When a piece runs out, the next one starts.
- Press **R** to fill the slot from your bag (it takes the fuel type already in the slot, or the best one you have).
- You can **turn it off** (key **L**) to save fuel at base. Off still shows the dim glow.
- It only burns while it's on. 1 minute of play = 1 minute of fuel.

### 5.2 Fuel values and colours

| Fuel | Burn time per piece | Light colour | Effect while burning |
|---|---|---|---|
| `rootwood` / `mushroom_wood` | 2 min | Flickering orange | Radius ×0.85 (smoky, cheap) |
| `crystal_blue` | 8 min | Cool blue | Normal. The "default" light. |
| `crystal_green` | 8 min | Soft green | Mushrooms, tubers and fiber within the light get a soft outline |
| `crystal_violet` | 10 min | Violet | Rune pebbles, hidden wall markings and ruin secrets within the light sparkle |
| `crystal_amber` | 10 min | Warm gold | Radius ×1.15 |
| `crystal_white` | 20 min | Bright white | Radius ×1.25, brightness ×1.2 |

So wood is a cheap backup and crystals are the "good" fuel, which fits the cave.

### 5.3 The dim glow when empty

- When the slot is empty (or the lantern is off), a **dim glow stays**: radius **3 m**, **15%** brightness, pale yellow.
- It never goes fully dark. This is a rule, and an auto-check tests it.

### 5.4 Lantern upgrades

| Lantern | Where it sits | Light radius | Brightness | Fuel use | Recipe (station) | Unlocks when |
|---|---|---|---|---|---|---|
| `lantern_hand` | Left hand | 8 m | 100% | ×1.0 | Start item | Start |
| `lantern_back` | On your back, glowing above your head. **Hands free** | 10 m | 100% | ×1.0 | 4 copper_ingot, 2 leather, 1 lantern_lens, 2 rope (Anvil) | First copper ingot |
| `lantern_bright` | Back | 13 m | 120% | ×0.85 | 6 silver_ingot, 2 chitin_plate, 2 lantern_lens, 5 crystal_amber (Anvil) | First silver ingot |
| `lantern_grand` *(future)* | Back | 16 m | 140% | ×0.75 | 6 iron_ingot, 3 lantern_lens, 3 crystal_white (Anvil) | First iron ingot |

- The new lantern **replaces** the old one, and its fuel moves over.
- While the hand lantern is out, you can only use one-handed tools and weapons (no shield, no two-handers). The combat doc confirms this. This makes the back lantern a big, exciting upgrade.
- Lanterns don't use quality or +1..+3 upgrades. Each lantern is its own step.

---

## 6. Survival: hunger, thirst, health, stamina, food and water

### 6.1 Base numbers

| Stat | Max | Regen | Notes |
|---|---|---|---|
| Health | 100 | 1.0 per second after 5 s without taking damage | Food buffs raise max |
| Stamina | 100 | 20 per second after 1 s of not using it | Food buffs raise max |
| Hunger | 100 (full) | — | Drains 2.5 per minute |
| Thirst | 100 (full) | — | Drains 2.8 per minute |

That means: full → "Peckish" (25) in **30 min**, full → empty in **40 min**. Thirst runs a bit faster: full → "Thirsty" in **27 min**, empty in **36 min**. Matches the owner's "eat and drink every 30–40 min."

Hunger and thirst drain at **half speed** while you stand near a lit campfire or lie in your bed (resting at base feels cosy).

### 6.2 What happens when meters get low

| Meter level | Name | Effect |
|---|---|---|
| 75–100 (both) | Well Fed | Health regen +20% |
| 26–74 | Normal | Nothing |
| 1–25 | Peckish / Thirsty | Health regen −25% |
| 0 | Starving / Parched | Health regen −60%. "Tired": max stamina −20%, stamina regen −30% |

The effects of hunger and thirst don't stack on top of each other, the worse one counts. **You never take damage and never die from hunger or thirst.** This is a fixed rule.

### 6.3 Stamina costs (non-combat)

Combat costs (attacks, block, parry, dodge) are in the combat doc.

| Action | Stamina |
|---|---|
| Run | 8 per second |
| Jump | 10 |
| Pickaxe or axe swing | 5 |
| Climbing a rope ladder | 4 per second |

### 6.4 Water sources

| Source | Where | How it works |
|---|---|---|
| Stream (moving water) | MH small streams, FJ | Fill a waterskin: **clean**. Or drink straight: +35 thirst per sip |
| Still pool | MH, FJ | Fill: **dirty**. Drinking dirty water: +25 thirst, 30% chance of "Upset Belly" (stamina regen −25% for 3 min). Boil it to make it clean |
| Drip Bucket | Your base, placed under a dripping stalactite (dripping spots are marked by little falling drops) | Makes 1 `water_bucket` every 4 min, holds 5 |
| Juicy Bellcap | Wild or farmed | Eat raw: +15 hunger and +25 thirst |
| Boiling | Campfire or Cooking Pot | 1 dirty waterskin → clean, 10 s |

A clean sip = **+35 thirst**. A full waterskin (5 sips) covers about 1.5 hours.

Waterskin recipe (Hand): 2 critter_hide, 1 rope.

### 6.5 Plain food (no buff, just hunger)

| Item | Hunger | Thirst | How |
|---|---|---|---|
| Raw glowcap / hollowcap | +8 | 0 | Raw |
| Raw bellcap | +15 | +25 | Raw |
| Raw meat (critter or beetle) | +10 | 0 | 30% chance of Upset Belly |
| Roasted Tuber | +25 | 0 | Campfire: 1 root_tuber |
| Clean water sip | 0 | +35 | — |

### 6.6 Buff food: the 3 slots

- You have **3 buff slots**. Eating a dish or a brewed drink puts its buff in a free slot.
- **The same dish can't be in two slots.** Different dishes stack (add up).
- When all 3 are full, eating a 4th dish replaces the one with the **least time left**.
- Every buff dish also fills hunger (and drinks fill thirst), so a good meal does both jobs.
- Buffs end when you die.
- **Missing buff food is never a disaster.** The biggest single buff is +25%.

**Recipe sources:** "Known" = you know it from the start. "Ruin" = found as a recipe scroll in old ruins. "Rune" = unlocked by a Survivor & Cook rune (section 8).

#### Dishes (15)

| id | Dish | Biome | Station | Ingredients | Buff | Duration | Hunger | Recipe source |
|---|---|---|---|---|---|---|---|---|
| `dish_glowcap_skewer` | Glowcap Skewer | MH | Campfire | 2 glowcap | +10% max stamina | 25 min | +20 | Known |
| `dish_seared_critter` | Seared Critter | MH | Campfire | 1 critter_meat | +10% max health | 25 min | +30 | Known |
| `dish_firecap_skewer` | Firecap Skewer | MH | Campfire | 1 critter_meat, 1 firecap | +8% damage | 25 min | +25 | Ruin |
| `dish_tuber_mash` | Tuber Mash | MH | Cooking Pot | 3 root_tuber, 1 water | +15% max stamina | 30 min | +45 | Known |
| `dish_hollowcap_stew` | Hollowcap Stew | MH | Cooking Pot | 2 hollowcap, 1 critter_meat, 1 water | +20% max health | 30 min | +50 | Known |
| `dish_glow_broth` | Glow Broth | MH | Cooking Pot | 3 glowcap, 1 water | +20% stamina regen | 30 min | +35 | Rune |
| `dish_miners_pie` | Miner's Pie | MH | Cooking Pot | 2 critter_meat, 2 root_tuber, 1 hollowcap | +12% max health, +5% dig power | 35 min | +60 | Ruin |
| `dish_hearth_stew` | Old Hearth Stew | MH | Cooking Pot | 2 critter_meat, 1 hollowcap, 1 firecap, 1 root_tuber, 1 water | +15% max health, +10% stamina regen | 40 min | +60 | Ruin |
| `dish_beetle_roast` | Beetle Roast | FJ | Campfire | 1 beetle_meat | +12% max health | 25 min | +30 | Known |
| `dish_stalk_steak` | Stalk Steak | FJ | Campfire | 2 mushroom_flesh | +15% max stamina | 25 min | +30 | Known |
| `dish_ember_skewer` | Ember Skewer | FJ | Campfire | 1 beetle_meat, 2 ember_morel | +10% damage | 25 min | +30 | Known |
| `dish_truffle_risotto` | Truffle Risotto | FJ | Cooking Pot | 2 spore_truffle, 1 root_tuber, 1 water | +20% max stamina | 35 min | +50 | Ruin |
| `dish_chitin_crunch` | Shell Crunch | FJ | Cooking Pot | 2 beetle_meat, 1 spore_truffle, 1 moss | −10% damage taken | 30 min | +45 | Ruin |
| `dish_spore_ward_stew` | Spore Ward Stew | FJ | Cooking Pot | 2 bellcap, 1 ember_morel, 1 moss, 1 water | −50% spore-cloud effects | 30 min | +40 | Rune |
| `dish_bug_hotpot` | Bug Hotpot | FJ | Cooking Pot | 2 beetle_meat, 1 ember_morel, 1 mushroom_flesh, 1 water | +12% damage | 35 min | +55 | Ruin |
| `dish_jungle_pie` | Jungle Pie | FJ | Cooking Pot | 2 beetle_meat, 2 root_tuber, 1 spore_truffle | +25% max health | 40 min | +65 | Rune |

(16 rows: one bonus. If the owner wants exactly 15, drop the Firecap Skewer.)

#### Drinks (6)

Brewed drinks use a buff slot, same as dishes.

| id | Drink | Biome | Station | Ingredients (makes) | Buff | Duration | Thirst | Recipe source |
|---|---|---|---|---|---|---|---|---|
| `drink_bellcap_juice` | Bellcap Juice | MH/FJ | Hand | 2 bellcap (1) | none | — | +60 | Known |
| `drink_glowcap_tea` | Glowcap Tea | MH | Cooking Pot | 2 glowcap, 1 water (1) | +10% stamina regen | 25 min | +40 | Known |
| `drink_firecap_cordial` | Firecap Cordial | MH | Cooking Pot | 1 firecap, 2 water (1) | +6% damage, +5% max stamina | 25 min | +40 | Ruin |
| `drink_moss_ale` | Moss Ale | MH | Brewing Barrel | 3 root_tuber, 1 hollowcap, 2 water (3) | +10% max stamina, +5% max health | 30 min | +50 | Rune |
| `drink_spore_mead` | Spore Mead | FJ | Brewing Barrel | 2 spore_truffle, 1 ember_morel, 2 water (3) | +15% max health | 35 min | +50 | Rune |
| `drink_deep_stout` | Deep Stout | FJ | Brewing Barrel | 3 mushroom_flesh, 2 root_tuber, 2 water (3) | −8% damage taken | 35 min | +50 | Ruin |

### 6.7 Mushroom farming

- A **Farm Plot** is 2 m × 2 m and has **4 planting spots**.
- To plant: put 1 of the mushroom (or tuber) into a spot. That's your "seed."
- It grows on the world clock, even while you're away (the host calculates it from timestamps when the area loads).
- When ripe, it glows a little brighter. Harvest = **3** of that item.
- Mushrooms grow anywhere (no light needed, they're mushrooms). Plots must sit on dirt, moss or a built floor.

| Crop | Grow time | Harvest | Biome needed to get the seed |
|---|---|---|---|
| `glowcap` | 20 min | 3 | MH |
| `hollowcap` | 15 min | 3 | MH |
| `bellcap` | 25 min | 3 | MH or FJ |
| `root_tuber` | 30 min | 3 | MH |
| `firecap` | 40 min | 3 | MH (rare) |
| `spore_truffle` | 35 min | 3 | FJ |
| `ember_morel` | 40 min | 3 | FJ |

Meat can't be farmed. You hunt for it (combat doc has the animals).

---

## 7. Levels and skills

### 7.1 Two kinds of growing (simple)

Your dwarf grows in **two ways at once**:

1. **Skills (0–100), by using them.** There are 4 skills, one per branch: **Mining**, **Fighting**, **Smithing** (includes building), **Survival** (includes cooking). Each goes up when you do that kind of work. Each skill level gives a small **automatic bonus**. You don't choose anything.
2. **Character level (1–30), from everything.** All XP you earn also counts toward your character level. Each level gives **perk points** to spend in the skill trees. Here you **do** choose.

**How they combine:** a perk costs points, and deep perks also need a **minimum skill level** in that branch. So you can't buy "master miner" perks without having actually mined. Points are your choices. Skill level is your practice. You need both.

**One XP, two places:** every action's XP goes to **its skill** and to **your character level**. Example: digging a copper ore spot gives 6 XP to Mining **and** 6 XP to your character level. Discoveries, bosses and runes only give character XP (they aren't one skill).

### 7.2 XP sources

| Action | XP | Goes to skill |
|---|---|---|
| Dig dirt / moss / clay spot | 1 | Mining |
| Dig stone-type spot | 2 | Mining |
| Dig glow crystal spot | 4 | Mining |
| Dig copper ore spot | 6 | Mining |
| Dig silver ore spot | 8 | Mining |
| Break through border rock | 50 | Mining |
| Chop a giant root / mushroom point | 3 | Survival |
| Pick fiber, wild mushroom, tuber | 1 | Survival |
| Harvest a farm spot | 2 | Survival |
| Cook a campfire dish | 5 | Survival |
| Cook a pot dish / brew a batch | 10 | Survival |
| Drink, eat (no XP) | 0 | — |
| Smelt 1 ingot | 4 | Smithing |
| Craft a stone tool or station | 10 | Smithing |
| Craft a metal tool | 25 | Smithing |
| Upgrade +1 / +2 / +3 | 15 / 25 / 40 | Smithing |
| Masonry craft (per output) | 1 | Smithing |
| Place a building piece by hand | 2 | Smithing |
| Blueprint chest finishes a piece | 1 (to the player who filled the chest) | Smithing |
| Hit an enemy | 1 per hit | Fighting |
| Perfect parry | 3 | Fighting |
| Kill a critter / beetle | 10 | Fighting |
| Kill a monster | 20–60 (combat doc sets it) | Fighting |
| Kill a pack leader | 100 | Fighting |
| Side boss | 300 | Fighting |
| Main boss: Mossy / Fungal | 1,000 / 2,000 | Character only |
| Discover a big cavern | 150 | Character only |
| Find a wall marking | 100 | Character only |
| Discover a ruin | 75 | Character only |
| Pick up a new rune (not a duplicate) | 50 | Character only |

**Co-op sharing:** dig, craft, chop and cook XP go only to the player who did it. **Kills, bosses and discoveries give full XP to every player within 30 m.** This means playing together never feels like "stealing" XP.

### 7.3 Character level curve

**Formula:** XP to go from level L to L+1 = `600 + 45 × L^1.3`, rounded to the nearest 10.
**Level cap:** 30 for now (raised when new biomes arrive).

**Perk points:** 1 per level gained, **plus 1 bonus point** at levels 5, 10, 15, 20, 25 and 30. At level 30 you have **35 points**. Maxing one branch costs about 22–25 points, so at level 30 you can master one branch and dip into another. That makes co-op roles matter.

| Level | XP to next | Total XP to reach | Points total | | Level | XP to next | Total XP to reach | Points total |
|---|---|---|---|---|---|---|---|---|
| 1 | 640 | 0 | 0 | | 16 | 2,250 | 19,670 | 18 |
| 2 | 710 | 640 | 1 | | 17 | 2,390 | 21,920 | 19 |
| 3 | 790 | 1,350 | 2 | | 18 | 2,530 | 24,310 | 20 |
| 4 | 870 | 2,140 | 3 | | 19 | 2,670 | 26,840 | 21 |
| 5 | 960 | 3,010 | 5 | | 20 | 2,810 | 29,510 | 23 |
| 6 | 1,060 | 3,970 | 6 | | 21 | 2,960 | 32,320 | 24 |
| 7 | 1,160 | 5,030 | 7 | | 22 | 3,100 | 35,280 | 25 |
| 8 | 1,270 | 6,190 | 8 | | 23 | 3,250 | 38,380 | 26 |
| 9 | 1,380 | 7,460 | 9 | | 24 | 3,400 | 41,630 | 27 |
| 10 | 1,500 | 8,840 | 11 | | 25 | 3,550 | 45,030 | 29 |
| 11 | 1,620 | 10,340 | 12 | | 26 | 3,710 | 48,580 | 30 |
| 12 | 1,740 | 11,960 | 13 | | 27 | 3,870 | 52,290 | 31 |
| 13 | 1,860 | 13,700 | 14 | | 28 | 4,020 | 56,160 | 32 |
| 14 | 1,990 | 15,560 | 15 | | 29 | 4,180 | 60,180 | 33 |
| 15 | 2,120 | 17,550 | 17 | | 30 | (cap) | 64,360 | 35 |

Target: about **level 10** when you beat the Mossy boss and **level 20** when you beat the Fungal boss (solo). Levels 21–30 belong to biomes 3–4.

### 7.4 Skill curve (0–100)

**Formula:** XP to go from skill n to n+1 = `75 + 3 × n^1.2`, rounded.

| Skill level | Total skill XP | | Skill level | Total skill XP |
|---|---|---|---|---|
| 5 | 412 | | 50 | 11,043 |
| 10 | 943 | | 60 | 15,433 |
| 15 | 1,614 | | 70 | 20,636 |
| 20 | 2,439 | | 80 | 26,681 |
| 25 | 3,426 | | 90 | 33,589 |
| 30 | 4,586 | | 100 | 41,384 |
| 40 | 7,439 | | | |

Target: a player who mostly mines has Mining around **50** at the end of Fungal Jungle, and their other skills around 20–30.

### 7.5 Automatic skill bonuses (per skill level)

| Skill | Bonus per level | At skill 100 |
|---|---|---|
| Mining | +0.3% dig power, −0.2% swing stamina | +30% dig power, −20% stamina |
| Fighting | +0.2% weapon damage, −0.2% attack/block stamina | +20% damage, −20% stamina |
| Smithing | Quality chance table (3.4); +0.2% smelting speed | Best quality odds, +20% smelt speed |
| Survival | −0.15% hunger/thirst drain, +0.2% buff food duration | −15% drain, +20% duration |

### 7.6 Skill trees

How to read: **Ranks** = how many times you can buy it. **Cost** = points per rank. **Needs** = minimum skill level in that branch + any perk you must own first (at least rank 1). Each tree has one **capstone** (the big final perk).

#### Miner tree (11 perks, 23 points to max)

| Perk | Ranks | Cost | Needs | Effect per rank |
|---|---|---|---|---|
| Strong Swing | 3 | 1 | Mining 0 | +5% dig power |
| Light Arms | 2 | 1 | Mining 5 | −15% swing stamina |
| Magnet Pockets | 1 | 1 | Mining 5 | Auto-pickup radius +50% |
| Lucky Strike | 3 | 1 | Mining 10, Strong Swing | +5% chance a dug ore spot gives double ore |
| Crystal Ear | 2 | 1 | Mining 10 | Crystal spots give +1 crystal; crystals burn 10% longer in your lantern |
| Wide Bite | 2 | 1 | Mining 15, Strong Swing | Dug spot size +15% (bigger, faster tunnels) |
| Prospector's Eye | 2 | 2 | Mining 20, Lucky Strike | Ore within 6 m (rank 2: 12 m) shows a faint shimmer through rock |
| Mole Stride | 1 | 1 | Mining 20 | +10% run speed while holding a pickaxe |
| Rock Sense | 1 | 1 | Mining 25 | Warning rumble 2 s before a cave-in near you (Step 4) |
| Hard Rock Hands | 1 | 2 | Mining 35, Wide Bite | Border rock and ancient brick take 1 fewer hit (min 1) |
| **Vein Breaker** (capstone) | 1 | 3 | Mining 50, Prospector's Eye | Every 8th hit on ore instantly breaks that spot and every ore spot touching it |

#### Warrior tree (11 perks, 24 points to max)

Exact combat numbers (parry window, stun meter) live in the combat doc. These perks change them by a percentage.

| Perk | Ranks | Cost | Needs | Effect per rank |
|---|---|---|---|---|
| Thick Skin | 3 | 1 | Fighting 0 | +5% max health |
| Second Wind | 2 | 1 | Fighting 5 | +10% stamina regen |
| Heavy Hand | 3 | 1 | Fighting 10 | +6% heavy-attack damage |
| Steady Guard | 2 | 1 | Fighting 10, Thick Skin | Parry window +15% |
| Shield Wall | 2 | 1 | Fighting 15, Steady Guard | −15% stamina for blocking |
| Roll Master | 2 | 1 | Fighting 15, Second Wind | −15% dodge-roll stamina |
| Combo Keeper | 2 | 1 | Fighting 20, Heavy Hand | Combo timing window +0.15 s |
| Stunner | 2 | 2 | Fighting 25, Steady Guard | Parries fill the stun meter +10% more |
| Pack Breaker | 1 | 2 | Fighting 30 | +25% damage to pack leaders |
| Last Stand | 1 | 2 | Fighting 35, Thick Skin 3 | Below 20% health, take 20% less damage |
| **Executioner** (capstone) | 1 | 3 | Fighting 50, Stunner | Dazed enemies take +30% damage |

#### Smith & Builder tree (10 perks, 20 points to max)

| Perk | Ranks | Cost | Needs | Effect per rank |
|---|---|---|---|---|
| Steady Hammer | 3 | 1 | Smithing 0 | +5 Smithing for the quality roll |
| Hot Hearth | 2 | 1 | Smithing 5 | Smelting 15% faster |
| Fuel Saver | 1 | 1 | Smithing 10, Hot Hearth | Smelter uses 1 wood per 2 ingots |
| Thrifty Smith | 2 | 1 | Smithing 15, Steady Hammer | 10% chance to get 1 ingot back when crafting a metal item |
| Quick Mason | 2 | 1 | Smithing 15 | Masonry crafts: +1 bonus output per 4 made |
| Long Reach | 1 | 1 | Smithing 20 | Building range +3 m |
| Blueprint Foreman | 2 | 1 | Smithing 20, Long Reach | Blueprint chests you fill build 25% faster |
| Strong Beams | 2 | 1 | Smithing 25 | Support beams you place hold 25% more rock (Step 4) |
| Upgrade Expert | 1 | 2 | Smithing 35, Thrifty Smith | Upgrades cost 25% fewer ingots (rounded down, min 1) |
| **Reforge** (capstone) | 1 | 3 | Smithing 50, Steady Hammer 3 | Once per item, re-roll its quality at the Anvil for half its ingot cost. Keeps the better result. |

#### Survivor & Cook tree (11 perks, 22 points to max)

| Perk | Ranks | Cost | Needs | Effect per rank |
|---|---|---|---|---|
| Iron Belly | 2 | 1 | Survival 0 | Hunger drains 10% slower |
| Camel Throat | 2 | 1 | Survival 0 | Thirst drains 10% slower |
| Good Cook | 3 | 1 | Survival 5 | Your dishes and drinks last 10% longer (for whoever eats them) |
| Forager | 1 | 1 | Survival 5 | Wild mushrooms, tubers and fiber give +1 |
| Green Thumb | 2 | 1 | Survival 10 | Farm plots you plant grow 15% faster |
| Big Harvest | 2 | 1 | Survival 15, Green Thumb | 25% chance per rank for +1 on each farm harvest |
| Hunter | 2 | 1 | Survival 15 | 25% chance per rank for +1 meat/hide/chitin from animals |
| Deep Pockets | 2 | 1 | Survival 20 | +3 bag slots |
| Hearty | 2 | 2 | Survival 25, Good Cook | Buff food you eat is 10% stronger (+20% max health → +22%) |
| Way Home | 1 | 1 | Survival 30 | After dying, run 20% faster for 3 min and your grave shows through walls from 60 m |
| **Fourth Plate** (capstone) | 1 | 3 | Survival 50, Hearty | A 4th buff food slot |

#### Respec (re-picking your perks)

At the Rune Slab: pay **5 crystal_blue + 1 crystal_white** to refund **all** perk points. Skill levels don't change. (Cheap on purpose, so trying things is fine.)

---

## 8. Runes

### 8.1 The basics

- You find **runes** at random while exploring (they look like small carved stones).
- Bring them to the **Rune Slab** at your base and carve them in. Carving takes 3 s.
- Each rune **colour** belongs to one branch:

| Colour | Branch |
|---|---|
| **Ochre** (earthy yellow-brown) | Miner |
| **Crimson** | Warrior |
| **Cobalt** (deep blue) | Smith & Builder |
| **Verdant** (leaf green) | Survivor & Cook |

- Each rune unlocks **one step**: a recipe or a small bonus.
- Each biome has **one set per colour**. Finish a set → a **set perk** (big, special bonus).
- **Mossy Hollows sets have 5 runes. Fungal Jungle sets have 6 runes.** Total: 20 + 24 = **44 runes**.
- **Co-op:** the whole world shares one slab state. If you build several slabs, they all show the same runes. A rune carved by anyone helps **everyone**, including friends who join later.
- Runes are items until carved, so a rune in your bag goes into your grave if you die.

### 8.2 Drop sources and rates

| Source | Rate | Notes |
|---|---|---|
| Rune pedestal in an old ruin | 100% (1 rune) | Mossy has about 6 ruins, Fungal about 7. One pedestal each. |
| Side boss | 100% (1 rune per nearby player) | |
| Main boss | 100% (2 runes per nearby player) | |
| Ruin chest | 8% | |
| Pack leader | 10% | |
| Normal monster | 0.5% | Critters and beetles never drop runes |
| Digging a stone or ore spot | 0.15% MH / 0.2% FJ ("rune pebble") | Violet crystal light makes them sparkle |

**Which rune drops:**
1. A source drops a rune from **its own biome's** sets. Colour is random (even odds).
2. **Bad-luck protection:** 75% of the time, the game picks a rune your world doesn't have yet (if that colour still has missing ones in that biome). Otherwise it's fully random.
3. In Fungal Jungle, 20% of drops are a **missing Mossy rune** instead, until all Mossy sets are done.

Expected solo haul in Mossy Hollows (~8 hours): about **15–17 of the 20 runes**. The rest come from shards and Fungal backfill.

### 8.3 Duplicates

- Picking up a rune your world has already carved turns it into **1 Rune Shard** of that colour (automatic, with a little "crumble" sound).
- At the slab: **3 shards of one colour → carve any missing rune of that colour**, from any biome you've entered. You choose which.
- In 4-player co-op, boss drops create lots of duplicates. That's fine: shards turn them into choices.

### 8.4 The rune sets

#### Ochre (Miner)

| Rune | Mossy set "Delver" (5) | | Rune | Fungal set "Sporecutter" (6) |
|---|---|---|---|---|
| m1 | Recipe: **Crystal Sconce** (wall light, burns 1 crystal per 40 min) | | f1 | Recipe: **Blasting Pod** (throwable, digs a 2 m hole, Copper-tier strength) |
| m2 | Lantern fuel lasts +10% | | f2 | +5% dig power |
| m3 | Recipe: **Rope Ladder** (build piece for shafts) | | f3 | Recipe: **Glow Marker** (placeable flag, shows on map) |
| m4 | Auto-pickup radius +2 m | | f4 | Silver ore spots: +10% double-ore chance |
| m5 | Stone and dirt spots: 10% chance of +1 item | | f5 | Crystal spots give +1 crystal |
| | | | f6 | Recipe: **Prospector's Lens** (hand item: aim at rock to see its hardness and what's 3 m behind it) |
| **Set perk** | **Hollow Sense:** press **G** to make ore within 15 m flash for 3 s (60 s cooldown) | | **Set perk** | **Vein Follower:** after digging an ore spot, the touching ore spots of that vein need 1 fewer hit (min 1) |

#### Crimson (Warrior)

| Rune | Mossy set "Guardian" (5) | | Rune | Fungal set "Bugbane" (6) |
|---|---|---|---|---|
| m1 | Recipe: **Training Dummy** (hit it for Fighting XP at 25% rate) | | f1 | Recipe: **Spore Bomb** (throwable poison cloud) |
| m2 | +5 max health | | f2 | +5% heavy-attack damage |
| m3 | Recipe: **Whetstone** (weapon +5% damage for 10 min) | | f3 | Recipe: **Bugbane Oil** (weapon coating: +15% damage to bugs, 10 min) |
| m4 | +5% stamina regen | | f4 | +5 max health |
| m5 | Dodge-roll costs 5% less stamina | | f5 | Parries fill the stun meter +5% more |
| | | | f6 | Recipe: **War Horn** (allies within 15 m get +10% damage for 60 s, 5 min cooldown) |
| **Set perk** | **Hollow Guard:** the first hit you take every 30 s does 30% less damage | | **Set perk** | **Leader's Fall:** killing a pack leader gives you and allies within 15 m 30% stamina and 15% health back |

#### Cobalt (Smith & Builder)

| Rune | Mossy set "Hearthsmith" (5) | | Rune | Fungal set "Jungle Mason" (6) |
|---|---|---|---|---|
| m1 | Recipe: **Ruin style** building pieces (old dwarf arches, pillars) | | f1 | Recipe: **Mushroom style** building pieces |
| m2 | Smelting 10% faster | | f2 | Upgrade costs −10% ingots (rounded down, min 1) |
| m3 | Recipe: **Copper-bound Chest** (36 slots) | | f3 | Recipe: **Twin Smelter** (smelts 2 items at once) |
| m4 | +5 Smithing for the quality roll | | f4 | Building range +2 m |
| m5 | Recipe: **Ore Crate** (60 slots, ores and stone only) | | f5 | +5 Smithing for the quality roll |
| | | | f6 | Blueprint chests build 25% faster |
| **Set perk** | **Bonus Bar:** every 10th ingot from any smelter in the world is free (an 11th pops out) | | **Set perk** | **Master's Mark:** Q4 and Q5 crafts come with a free +1 upgrade |

#### Verdant (Survivor & Cook)

| Rune | Mossy set "Forager" (5) | | Rune | Fungal set "Spore-Eater" (6) |
|---|---|---|---|---|
| m1 | Recipe: **Glow Broth** | | f1 | Recipe: **Spore Ward Stew** |
| m2 | Hunger drains 5% slower | | f2 | Thirst drains 5% slower |
| m3 | Recipe: **Copper Drip Basin** (holds 15, fills every 2 min) | | f3 | Recipe: **Spore Mead** |
| m4 | Farm plots grow 10% faster | | f4 | Recipe: **Spore Mask** (worn: spore clouds affect you half as much; armor slot rules in combat doc) |
| m5 | Recipe: **Moss Ale** | | f5 | Farm harvests: 20% chance of +1 |
| | | | f6 | Recipe: **Jungle Pie** |
| **Set perk** | **Long Meals:** all buff food lasts +20% | | **Set perk** | **Second Helping:** eating a dish you already have active refreshes it to full time and makes it 10% stronger (once per buff) |

Rune bonuses and set perks apply to **every player** in the world (it's a shared slab).

---

## 9. Death and graves

### 9.1 What happens

1. You fall down. After 3 s, you **wake at your bed** (or at the world start point in Mossy Hollows if you have no bed).
2. A **grave** (a small stone cairn with your beard colour on a cloth) appears where you died.
3. You come back with **full health, full stamina**, and hunger/thirst set to **at least 50**.

### 9.2 What stays on you, what goes into the grave

| Stays on you | Goes into the grave |
|---|---|
| Worn armor | Everything in your **bag** (all 30+ slots) |
| Your lantern **and the fuel inside it** | **Stackable** things on your hotbar (food, bombs, runes, materials) |
| **Tools and weapons on your hotbar** (anything with stack size 1) | |

Buff food ends. XP and skills are **not** lost.

**Why keep hotbar tools?** Underground, the walk back can mean digging. With no pickaxe you'd be stuck at home, and with no weapon you'd be helpless against whatever killed you. Keeping tools makes the trip back a fun little mission instead of a dead end. What you lose (for a while) is your **haul**: ore, crystals, food. That's still a real reason to be careful. (Open question 3.)

### 9.3 Grave rules

| Rule | Value |
|---|---|
| Timeout | **None.** A grave never disappears until it's empty. |
| Map | A grave icon on the map page of its floor, with your name. Several graves are numbered (1, 2, 3). |
| In the world | A soft beam of light rises from it, visible **through rock within 30 m** (60 m with the Way Home perk). |
| Who can open it | You **and** your co-op friends (so a friend can bring it home). Monsters can't touch it. |
| Recovering | "Take all" puts every item back in its old slot if free. Overflow goes to free slots, then stays in the grave. |
| Safety | Graves can't be dug, buried by cave-ins or carved by blueprints. If rock collapses on one, it moves up to the nearest open air. |
| Empty grave | Crumbles away after you empty it. |

---

## 10. Inventory

### 10.1 Your bag and hotbar

| Part | Size | Notes |
|---|---|---|
| Bag | **30 slots** | +3 per rank of Deep Pockets (max 36) |
| Hotbar | **8 slots** | Separate from the bag. Keys 1–8 or mouse wheel |
| Lantern slot | 1 + its fuel slot (20) | Doesn't use bag space |
| Armor slots | Set by combat doc | Don't use bag space |

- **Stacks:** 100 default (section 1). A full stack starts a new slot.
- **No weight limit.** Only slots matter. (Simple, and fits "big auto-pickup radius" from the plan.)
- **Bag full:** items stay on the ground and blink. A "Bag full!" note shows.
- **Buttons:** "Sort" (by type), "Stack to nearby chests" (puts items into chests within 10 m that already hold that item).

### 10.2 Chests

| Chest | Slots | Recipe | Station | Unlocks when |
|---|---|---|---|---|
| `chest_small` | 12 | 8 plank_root, 2 rope | Workbench | Workbench built |
| `chest_stone` | 24 | 10 cut_stone, 2 copper_ingot | Workbench | First cut_stone |
| `chest_copper` | 36 | 10 plank_root, 6 copper_ingot | Anvil | Cobalt rune m3 |
| `chest_chitin` | 48 | 12 plank_mushroom, 8 chitin_plate, 4 silver_ingot | Anvil | First silver ingot |
| `crate_ore` | 60 (ores, stone types, clay, crystals only) | 12 plank_root, 4 copper_ingot | Anvil | Cobalt rune m5 |
| Blueprint chest | 24 (building materials only) | Comes with each blueprint | — | Step 4 (building doc) |

Chests are shared in co-op: first come, first served (from the plan).

---

## 11. Pacing

"Hours" = real play time. **4-player** is faster because work splits up (one mines, one smelts, one cooks…). Monsters get tougher with more players (combat doc), so it's not 4× faster.

| Milestone | Solo (hours) | 4-player (hours) | Character level (solo) |
|---|---|---|---|
| Campfire + workbench | 0.25 | 0.25 | 1 |
| First copper ingot (smelter built) | 1.0 | 0.75 | 2 |
| Anvil, cooking pot, copper axe | 1.5–2 | 1–1.25 | 3 |
| Back lantern (hands free) | 2.5 | 1.5 | 4 |
| First buff dishes, farm plot running | 2.5–3 | 1.5–2 | 4–5 |
| Copper weapons and armor (combat doc) | 3–4 | 2–2.5 | 5–6 |
| All 3 Mossy wall markings found | 5–6 | 3–4 | 7–8 |
| **Mossy boss beaten, Copper pickaxe** | **7–8** | **4.5–5.5** | **~10** |
| Through Border rock 1 into Fungal Jungle | 8 | 5.5 | 10 |
| First silver ingot | 9.5 | 6.5 | 11–12 |
| Bright lantern, silver axe | 11–12 | 7.5–8 | 13 |
| Silver weapons and armor | 13–14 | 9 | 14–15 |
| Copper gear at +3 / silver at +2 | 15–16 | 10–11 | 16–17 |
| All 3 Fungal wall markings found | 17–18 | 11–12 | 18–19 |
| **Fungal boss beaten, Silver pickaxe** | **19–21** | **13–14** | **~20** |

**XP rate these numbers assume:** solo about 1,100 XP/hour in Mossy and 1,700 XP/hour in Fungal. If playtest shows players are much faster or slower, change the **XP rewards**, not the level curve.

**Rune pacing:** most Mossy runes by the time you cross into Fungal; Mossy sets finished early in Fungal; Fungal sets around the Fungal boss.

**Resource budget check (copper era, solo):** about 100 copper ingots for everything (pickaxe 8, axe 6, anvil 6, pot 4, lantern 4, masonry 2, chests ~10, weapons and armor ~30 (combat doc), upgrades ~30). 100 ingots = 100 ore spots ≈ 450 swings ≈ 6 minutes of pure swinging, spread over a few hours of exploring for veins. Finding veins is the real work, not hitting them.

---

## 12. Open questions for the owner

Each has my pick marked ★ (what this doc already assumes).

1. **Tools wearing out?** ★ A) Never wear out. B) Slowly wear out, repair at the Anvil for a few ingots.
2. **Do brewed drinks use one of the 3 buff slots?** ★ A) Yes, same slots as dishes. B) Separate: 3 food slots + 1 drink slot.
3. **What stays on you when you die?** ★ A) Armor, lantern and hotbar tools/weapons stay; everything else goes in the grave. B) Everything goes in the grave (harder). C) Only materials go in the grave; all food and gear stay (easier).
4. **Ore to ingot:** ★ A) 2 ore → 1 ingot (each ore spot = 1 ingot). B) 1 ore → 1 ingot (half the mining).
5. **Stations take materials from nearby chests?** ★ A) Yes, within 10 m. B) No, only from your bag.
6. **Rune set sizes:** ★ A) Mossy 5 per colour, Fungal 6. B) 6 everywhere. C) 4 everywhere (quicker to finish).
7. **Changing your perks (respec):** ★ A) Cheap, at the Rune Slab. B) Free, any time. C) Never.
8. **Max character level for the first release:** ★ A) 30 (matches the two biomes). B) 50 (room to grow, slower levels).
