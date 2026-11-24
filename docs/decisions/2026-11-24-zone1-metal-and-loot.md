# Zone 1 metal + loot plan (Nov 24, 2026)

F697 (bronze) + F844 (copper in ruins, bronze in dungeons, skull signposts).
Owner decided the big picture and answered the 4 open questions on Nov 24 (all four "recommended" picks).
Plan only: nothing here is built yet. Build order is at the bottom.

## The big picture (owner)

| Where | What you find | Metal |
|---|---|---|
| Ruins | Copper recipes (armour + weapons) | Copper (Copper Deeps) |
| Zone 1 cave walls | Tin ore (new) | Tin |
| Smelter | Copper + tin = bronze | Bronze (new) |
| Dungeons | Bronze recipes (armour + weapons), bronze tools in big chests | Bronze |

Armour first, weapons later. Each ruin and each dungeon **always gives the same recipe** (no per-world shuffle).

## 1. Copper recipes: fixed, 1–2 per ruin

Today ruin chests drop random food and tool pages, and copper armour/weapons come from the dungeons (shuffled).
New: each ruin has one **named copper page** in its main chest. Smaller ruins teach armour; the grand ruins teach the big weapons.

| Ruin | Copper recipe(s) |
|---|---|
| Ruined Watchtower | Copper Helm |
| Outpost | Copper-shod Boots |
| Old Kiln | Copper Greaves |
| Brewhall | Copper Mail |
| Lantern Spire | Copper Crossbow + Copper Spear |
| Hearth Manor | Copper Shield + Copper Axe |
| Prow Hall | Copper Sword + Copper Mace |
| Twin Gate | Copper Great Axe + Copper Great Maul |

- 12 recipes over 8 ruins. When new ruins arrive (Cliff Watch, F740), they take over one of the doubles
  (e.g. Cliff Watch takes the Copper Spear from Lantern Spire), so most ruins end up with one.
- The other ruin chests keep dropping random food and tool pages, as now.
- **Copper Pickaxe stays free** (unlocks when you see heartwood): nobody can get stuck without a pickaxe.
- Copper-bound Chest stays a rune recipe (unchanged).
- Old saves: recipes already learned stay learned. A page for something you know says "You already know…" (already works).

## 2. Tin ore (new)

- Grey-silver specks in ordinary stone walls all around the Zone 1 caves (not one special area), a little rarer than copper.
- Needs the **Copper Pickaxe** to mine, so the order stays: copper first, then tin, then bronze.
- Its own vein look (MODEL-RULES: hand-painted, chunky; checks must pass).
- Placement rule: like every ore, never inside ruins, towers, dungeons or on their paths/stairs (+ test).

## 3. Bronze (new metal)

- **Bronze Ingot** at the smelter: 1 Copper Ingot + 1 Tin Ore → 1 Bronze Ingot (fuel 1, like copper).
- Bronze gear is about **1.3× copper** (damage, armour, mining power). Exact numbers set when building, next to copper's.
- New items, one per copper one: `helm_bronze`, `mail_bronze`, `greaves_bronze`, `boots_bronze`, `shield_bronze`,
  `crossbow_bronze`, `spear_bronze`, `axe_bronze`, `sword_bronze`, `mace_bronze`, `axe_2h_bronze`, `mace_2h_bronze`,
  plus the tool `pickaxe_bronze`.
- **Art, step 1:** reuse the copper models with a darker gold-brown bronze paint and trim, so bronze is playable fast.
  **Step 2 (later):** own bronze models, made by the MODEL-RULES way, in small batches the owner OKs.

## 4. Bronze recipes: fixed, one per dungeon (owner's order)

| Skulls | Dungeon | Bronze recipe on the stand |
|---|---|---|
| 💀 | Mossgate Hold | Bronze Helm |
| 💀 | Lampwick Drift | Bronze Boots |
| 💀 | Old Pell's Diggings | Bronze Greaves (legs) |
| 💀 | Mossprop Workings | Bronze Crossbow |
| 💀💀 | Tomb of Hald Ironbrow | Bronze Mail (chest) |
| 💀💀 | Hall of the Shieldbearers | Bronze Shield |
| 💀💀 | The Quiet Barrows | Bronze Spear |
| 💀💀 | Brassgate Vault | Bronze Axe |
| 💀💀 | Vigil of Orrin Stonejaw | Bronze Sword |
| 💀💀💀 | Emberdeep Forge | Bronze Mace |
| 💀💀💀 | The Hammerfall Works | Bronze Great Maul |
| 💀💀💀 | Cinderhold Foundry | Bronze Great Axe |

- The skulls match today's dungeon sizes exactly (small / medium / big), so no dungeon moves.
- The per-world shuffle (`DungeonLoot.recipes_for`) goes away; each dungeon in `dungeon_list.gd` names its own recipe.
- The dungeon scroll items (`scroll_mossgate`, …) teach the bronze recipe. A scroll already sitting in an old save's bag
  teaches the new bronze recipe when read (fine: it's a reward either way).
- **Bronze tools:** the **Bronze Pickaxe** page is in the **big chest of Mossgate Hold** (the first 1-skull dungeon),
  next to the gold, so the recipe stand keeps one clear prize. More bronze tools later go in other big chests.

## 5. Skull signposts at every dungeon entrance

- A chunky wooden post by the entrance with **1, 2 or 3 carved skulls** on top (small / medium / big).
- A painted board under the skulls shows a **picture of the recipe inside** (the bronze item's icon, painted on).
- Read from far away: skulls tell danger, the picture tells the prize. Short label on look: "Mossgate Hold: 💀, Bronze Helm".
- After the recipe is learned, the board gets a small tick so you know you've been there.
- Model made by Blender script in the workbench style (MODEL-RULES); placed by each dungeon's own build code, outside the door,
  never on the path (placement test).

## Co-op

Learning stays as now: the player reads the page → host checks it → the whole group learns it (`world_state.learned`).
Signposts are drawn from the world seed, so every player sees the same ones. Nothing new to sync except the tick on the board
(it reads `world_state.learned`, which everyone already has).

## Build order (each step playable before the next)

1. **Fixed bronze per dungeon (data only, copper stand-ins).** `dungeon_list.gd`: each dungeon names its recipe; drop the shuffle;
   test `test_each_dungeon_teaches_its_own_recipe`. Until bronze exists the stands still teach the copper version, in the new order.
2. **Copper pages in ruins.** 12 named copper pages; each ruin's main chest holds its page(s); other chests keep food/tool pages.
   Test: every copper armour/weapon recipe is taught by exactly one ruin and its chest really spawns.
3. **Tin ore.** New wall material + drop + vein look + placement + test (never in built places). Needs Copper Pickaxe.
4. **Bronze ingot + 13 bronze items** (recoloured copper models, ~1.3× stats), bronze recipes at the anvil (locked).
5. **Switch the dungeon stands to bronze** + Bronze Pickaxe page in Mossgate's big chest. Copper recipes now only from ruins.
6. **Skull signposts** (new model, art round, owner OK), with the recipe picture and the "learned" tick.
7. **Own bronze models** (later, small batches).
8. Add new ruins (F740) and move the doubled copper recipes onto them.
