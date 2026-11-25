## Nov 25: progression map, Tin Bar, bronze at the anvil (F894)

**What we did**
- Made a picture map page of the whole metal road (first camp → bats → Fanged Pickaxe → copper → ruins → tin → bronze → dungeons), with what's built and what's missing.
- The owner corrected the road: leather armour comes before the ruins, tin is smelted into bars, and bronze is mixed at the anvil. Armour should get its own bench (Armoury Bench); the anvil keeps weapons and tools.
- Owner's picks: the Armoury Bench comes early (planks + leather), shields go on it, 3 copper + 1 tin = 4 bronze, 2 tin ore = 1 tin bar.
- Built step 1: Tin Bar item, made from silver paint turned dull blue-grey by `make_bronze.py tin`, with a Blender model from the ingot builder. The bronze recipe moved from the smelter to the anvil.

**Mistakes and hurdles**
- Claude's map missed the leather armour (Cap, Tunic, Trousers, Boots), which was already in the game at the workbench. Lesson: grep the recipe list for each tier before drawing a map, not only the metal items.
- The first tin paint came out too dark, like lead or stone. One brighter round fixed it.
- `test_item_sources.test_only_the_five_creatures_are_left` fails (16 monsters, expects 8). Another chat added the dungeon monsters; not this change.

**Next:** step 2, the Armoury Bench (new chat, Opus: new model + new station).
