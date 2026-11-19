# Where the 223 kept models go (Nov 19, 2026)

The owner kept 223 models from the 12 free CC0 packs (picking page:
https://claude.ai/artifact/UnJFF5E9ZUAUDCr19oBUi3). Files: `Downloads/dwarf-asset-kept/` on the PC (not in the repo yet).
Every model is reshaped and repainted in our hand-painted style by a build script before it goes in (MODEL-RULES,
rule 1 as bent by the owner for free packs). Names below are the packs' own model names.

## Where each kind goes

| Kept models | Goes to | In the game today |
|---|---|---|
| **Swords** (6), **shields** (4), **great axes** (3), **hammers/mauls** (3), **spears** (2), **dagger** | Weapons: `sword_*`, `shield_*`, `axe_2h_*`, `mace_*`/`mace_2h_*`, `spear_*` (stone, copper, silver tiers) | Our own hand-built models. The tournament winner becomes the shape for all three tiers (stone, copper, silver look). |
| **Crossbows** (2), **arrows/bolts/dart** (6) | `crossbow_*` and the 8 kinds of bolts (`bolt_stone`, `bolt_metal`, `bolt_ember`...) | Ours |
| **Pickaxe** (KayKit) | A shape reference for the pickaxes | Ours (4 pickaxes) |
| **Bags** (4: Bag, Pouch Large, Bag, Backpack) | `satchel` (Leather Satchel), plus a "dropped bag" when you die | Ours |
| **Chests** (2) | `chest_small` and the ruin loot chests | Ours (4 chests) |
| **Beds** (2) | `bed` station | Ours |
| **Workbench, Workbench Drawers** | Shapes for new stations (carpenter's bench, the gem bench's shelf) | Our workbench stays: it is the style the owner chose |
| **Anvil Log, Whetstone, Cauldron, Dummy** | Ideas for `anvil`, `whetstone`, `cooking_pot`, `training_dummy` | Ours |
| **Torch Metal, Candles (5), Chandelier** | New light pieces: wall torch, candles, a hanging chandelier for halls | Crystal torch/sconce only |
| **Tables, chairs, stools, bench, cabinet, bookcase, shelves (4), nightstand, peg rack, weapon stand, banners (3), vases (2), book stand** | **Furniture: a new "Furnish" tab in the build menu** (players furnish their homes, BLUEPRINT-RECIPE rule) | Nothing yet |
| **Barrel, Barrel Holder, crates (3), buckets (2)** | Storage props (barrels are already storage), ruin and outpost dressing | Ours |
| **Books, book stacks and groups (14), scrolls (2), maps (2), spellbooks (2)** | Shelf filler; `recipe_page`, `blueprint_page`, `watchtower_plans` pickups; a map item later | Pages only |
| **Potions and bottles** (6 + 18 filled/empty) | `bugbane_oil` and new tonics; shelf and alchemy-table dressing | 2 tonics |
| **Mugs (3), chalices (2), plate, fork, knife, spoon** | Tavern and kitchen dressing; a mug for drinks | Nothing |
| **Coins, coin piles, keys (2), bag of coins** | Treasure in ruin chests; keys for locked doors later | Nothing |
| **Fish bone** | Cave floor clutter near water | Nothing |
| **Spider** (Easy Enemies) | A small cave pest (with the bat, snail, beetle) | 3 monsters |
| **Rocks (21) and pebbles (11)** | More boulder and floor-pebble shapes | Ours (5 boulder shapes) |
| **Rock paths (10)** | Stepping stones and paths in camps and ruins | Nothing |
| **Grass (6), clover (2), fern, plants (4), flower bush** | Ground cover near light and water (F188) | Ours (cave_cover) |
| **Mushrooms (2: Laetiporus shelf fungus, flo-bit mushroom 5)** | Shelf fungi on walls (F190), giant mushroom shapes | Ours |
| **Dead and twisted trees (16)** | Dead trees in big caverns (no sun underground), petrified trees | Root Trees only |
| **Common trees (5) and pines (5)** | Only fit somewhere with light: a glowing grove or a surface level. **Question for the owner.** | Nothing |

## Clashes: the tournament

Where several kept models would be the same one thing in the game, the owner picks one, two at a time, winner moves
on (like a championship). Groups: swords, shields, great axes, hammers, spears, arrows/bolts, crossbows, bags,
chests, mugs, chalices, beds, workbenches, dead trees. Books, potions, rocks, grass and furniture are not clashes:
variety is good there, so all of them are used.

## Animations

The owner picked none and asked Claude to choose: 74 moves for the medium body (closest to a dwarf), listed in
`dwarf-asset-kept/kaykit_character_animations/picked_animations.json`: mining, chopping, hammering, sawing, working,
picking up, using, throwing, getting hit, dying, rising from the ground, sitting on chairs and the floor, lying in bed,
blocking, one- and two-hand attacks, crossbow aim/reload/shoot, crouch/sneak/crawl, jumps, dodges, strafing, cheering
and waving. The whole pack is saved next to it.

## Results (owner, Nov 19)

| Group | Result |
|---|---|
| Swords | **Modular Weapons "Sword 2"** (runner-up: Ultimate RPG "Sword") |
| Shields | **Props MegaKit "Shield Wooden"** (runner-up: Modular Weapons "Shield Round 2") |
| Arrows / bolts | **Ultimate RPG "Dart"** (runner-up: KayKit "arrow A") |
| Great axe (2-handed) | **Modular Weapons "Axe Double"** |
| Mace (1-handed) | **KayKit "hammer B"**, the spiked morning star (owner: one-handed) |
| Great maul / warhammer (2-handed) | **Ultimate RPG "Hammer Double"**, the cup winner (owner: the darker two-handed one) |
| Spear | **Modular Weapons "Spear"** |
| Crossbow | **KayKit "crossbow 1handed"** |
| Chest | **Props MegaKit "Chest Wood"** |
| Bags | **Keep them all** (owner): satchel, backpack, pouch, dropped bag |
| Beds | **Keep both** |
| Work benches | **Keep both, as furniture props**, not crafting stations (one is a table, one has drawers) |
| Mugs | **Keep both** |
| Chalices | **Keep both** |
| Dead and twisted trees | **Keep all 16** for variety |

## Owner's decisions (Nov 19, multiple choice)

- **Weapons:** our stone, copper and silver stay. The cup winners become the **Iron tier** (later Steel, repainted darker).
- **Trees:** they glow, and are sometimes the main light of a cave. **Glow groves**: 1-2 special caverns per zone. The
  **leaves glow** (soft, one colour per grove); trunks stay dark. The 16 dead and twisted trees stand between them as
  an old half-dead forest, some with a faint glow in their cracks.
- **Spider:** a **Zone 1 pest** (Mossy Hollows), in small groups, pouncing from walls, leaving webs; rebuilt the Rock
  Beetle way, keeping its 5 moves (walk, attack, jump, idle, death).
- **Furniture:** mostly looks, but **some pieces do something**: chairs, benches and stools let you sit (rest faster);
  beds set where you wake up; shelves, cabinets and nightstands store items; candles light the room.
- **Lights** (candles, chandelier, metal wall torch): **craftable, burn forever**.
- **Rocks, pebbles, grass, ferns, plants:** **added alongside ours** for more variety (repainted to match).
- **Potions, books, scrolls, maps:** **decoration now, real items later** (tonics, recipe books, a cave map).
- **Order:** glow trees and the cave look first.

## The plan: six batches, one at a time

Every model gets a build script that reshapes and repaints it in our hand-painted style and passes the model rules;
the owner sees each batch (about 4 pieces per round) on a 3D page before it goes in. Each pack goes in CREDITS.md when
its first model enters the game. Every new placement keeps clear of built things (placement rule) and gets a test.

1. **Glow groves** (first): 10 glowing trees, 16 dark trees, the shelf fungus and mushroom, the new rocks, pebbles,
   grass, ferns and plants. A grove cavern is lit mainly by its trees; one or two per zone, each with its own leaf colour.
2. **The cave spider** (Zone 1): rebuilt and painted, its 5 moves kept, small groups, pounce from walls, webs.
3. **The Furnish tab**: tables, chairs, stools, bench, beds, shelves, cabinet, bookcase, nightstand, peg rack, weapon
   stand, banners, vases, book stand, barrels, crates, buckets, the two work benches as props, candles, chandelier and
   wall torch (burn forever). Sitting and lying use the picked moves (Sit_Chair, Sit_Floor, Lie_Down).
4. **Ruin dressing and treasure**: books, potions, scrolls, maps, coins, chalices, mugs, keys, the cutlery, candles and
   crates in the ruins and the Fallen Outpost; the winning chest as a loot chest.
5. **Iron tier** (with the zone that brings iron): sword, morning star (1-handed mace), great axe, the dark great maul,
   spear, crossbow, wooden shield shape as the iron shield, dart as the iron bolt. Bags as satchel and backpack.
6. **Items later**: potions as tonics, books that teach recipes, a cave map; the other picked moves for the dwarf where
   they help (tools, crossbow, block, dodges, cheer and wave).
