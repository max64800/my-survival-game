# Dwarf Survival Game — Design Plan

*Written: November 14, 2026. Updated: November 14, 2026 (big Q&A session on the MacBook).*
*Game name: not picked yet (working name "Dwarf Game").*

This is our big plan. It says **what** we're making and **in what order**.
Everything is written so a 5th grader can follow it.

---

## 1. The dream (the whole game, someday)

You are a **dwarf**. The whole game happens **underground**. There is no sky, and no day or night.

- **Dig anywhere.** Every wall, floor, and ceiling can be dug away. Digging leaves smooth, natural-looking holes (not Minecraft squares).
- **Explore.** A huge underground world shaped like a star (see section 2). Each biome (a "zone" with its own look, creatures, and loot) has big caverns to discover.
- **Survive.** Gentle hunger and thirst, food that gives small boosts, a stamina bar, and monsters.
- **Grow.** Your dwarf levels up, gets better at what they do, and collects **runes** that power up their skill trees.
- **Build.** Snap-together pieces (walls, floors, beams, doors) in many materials.
- **Blueprints (our special feature).** Place a see-through "ghost" plan of a building. A chest comes with it. Put the materials in the chest and the building **builds itself, piece by piece**. If the ghost sits inside solid rock, it **carves the rock out first**, then builds.
- **Fight.** 8 weapon types, light and heavy attacks that chain into **combos**, **parries** on every enemy attack, a stun meter, a dodge-roll, and **gems** you put in your gear.
- **Bosses.** Every biome has one hidden main boss and a few side bosses.
- **Friends.** Up to **4 players** together through **Steam**.
- **Sell it.** The goal is that it could be sold on Steam one day.

**Look:** a mix of Valheim and Grounded. Chunky low-poly shapes, warm glowing colors, a bit of cartoon charm. Moody, but **never too dark**: lots of glowing things, like a big old dwarf hall lit by your lantern.
**Camera:** behind the dwarf (third-person).
**Inspiration (ideas only, never copied):** Valheim, Conan Exiles, 7 Days to Die, Grounded, and the idea of a dwarf-mining game done *well*. We never copy any game's names, characters, art, maps, or music.

---

## 2. The world: a star of biomes

```
Seen from above:                 Seen from the side:

          [ NORTH ]                     [ UP ]
              |                           |
[ WEST ] — [ MOSSY ] — [ EAST ]   ... — [ MOSSY ] — ...
              |                           |
          [ SOUTH ]                    [ DOWN ]  (last one)

MOSSY = Mossy Hollows, the start, in the middle of everything.
```

- **7 biomes:** the starting biome in the middle, 4 around it (north, south, east, west), 1 above it, 1 below it.
- **Each biome is big: about 400 m across** (about 5 minutes to walk through).
- **Each biome has 2–5 big open caverns** to discover. They hold things like monster nests, old dwarf ruins, and side-boss lairs. Twisty tunnels join them.
- **Border rock:** between biomes there is a special rock your pickaxe can't dig yet. You need a better pickaxe to break through.
- **Set order:** the biomes open one after another, from easiest to hardest. Each new pickaxe opens the next border.
- **Random every game:** a "seed" number decides the whole layout. Same seed = same world (great for testing).
- **No day/night.** Time doesn't change underground. Beds are only for "this is where I wake up after dying."

### Biomes we've decided so far
| # | Biome | What it's like | Main ore |
|---|---|---|---|
| Start | **Mossy Hollows** | Soft green moss, blue glowing mushrooms, small streams, old dwarf ruins, weak critters | Copper |
| 2 | **Fungal Jungle** | Giant mushrooms, spore clouds, beetles and bug packs | Silver |
| 3–7 | *Not decided yet.* Ideas list: Frozen Depths, Magma Forge, Sunken Lake, Bone Pits, Crystal Caverns, Ancient Dwarf City (good "Up" biome), The Abyss (good "Down" / final biome). | | |

We design one biome at a time, when we get to it.

---

## 3. Tools we use

| Thing | What we picked | Why (simple) |
|---|---|---|
| Game engine | **Godot 4.7.2** official (free, no fees ever) | Almost everything is saved as text, so Claude can build it and you just press Play. |
| Dig-anywhere world | **Voxel Tools 1.7, GDExtension edition** (free, MIT) | It already does the "sugar-cube world" trick with smooth walls. Saves months. The GDExtension edition plugs into normal Godot. |
| Steam co-op (later) | **GodotSteam, GDExtension edition** (free) | Lets friends click "Join" through Steam. Also plugs into normal Godot. |
| Code language | **GDScript** (Godot's own language) | Simple, made for Godot. |

**Checked on Nov 14, 2026:** both add-ons come as "GDExtension" plug-ins for the *official* Godot (Voxel Tools needs 4.5+, GodotSteam needs 4.4+). We still test them together for real early in Step 1. (The GDExtension edition of Voxel Tools leaves out "FastNoise2", a faster noise maker. We use Godot's built-in noise instead.)

**Where we work:** we plan on the MacBook and build on the gaming PC. GitHub is the shared notebook between them. Always `git pull` before starting on either computer.

**Claude's helper tools (on the gaming PC):** Godot MCP (start the game, read errors), GodotPrompter skills (Godot know-how), Superpowers skills (planning, debugging, testing), Context7 (up-to-date docs).

---

## 4. Free stuff (assets) we use

Only assets that are clearly allowed in a **game you sell** (best: "CC0" = free for anything, no strings).

- **Characters, props, tools:** Kenney, Quaternius, KayKit
- **Rock and stone textures:** Poly Haven, ambientCG
- **Animations** (walking, swinging): Mixamo
- **Sounds and music:** Freesound (CC0 only), OpenGameArt (CC0 only), Sonniss GDC packs

**Picking the art style:** in Step 1, Claude tries 2 free art packs in the game and takes screenshots. You pick the one closer to Valheim + Grounded.
Every asset goes in `CREDITS.md` with: name, where it came from, its license, and the date we got it.

---

## 5. Game systems (the full design)

Each system says which roadmap step it's built in.

### 5.1 Digging and rock (Step 1, cave-ins in Step 4)
- **Rock hardness matters.** Dirt and moss: 1 hit. Stone: 2–3 hits. Ore: 4–5 hits. Better pickaxes dig faster.
- **Mined stuff falls out** as little chunks, and you pick them up automatically from a **big radius** around you (walk near them and they fly into your bag).
- **Cave-ins (Step 4):** rock only falls when nothing holds it up. The limit is **large**, so builders aren't punished. Example: a hanging rock "icicle" about 20 blocks long falls. Smaller overhangs stay. This arrives together with support beams in Step 4.

### 5.2 The lantern (Step 1, upgrades in Step 3)
- You start holding a lantern in your hand.
- It burns **fuel**: **wood** or **crystals**. Different crystals give **different light colors**.
- When fuel runs out, a **small dim glow stays**, so it's never pitch black.
- **Upgrades:** move the lantern to your back (glowing above you, hands free), then make the light bigger and brighter.
- Step 1 uses glow crystals as fuel (they're already in the cave). Wood arrives with crafting in Step 3.

### 5.3 Bag and items (Step 1)
- **Bag:** about 30 slots. Each slot holds up to **100** of the same thing.
- **Hotbar:** 8 slots for tools and items you use.

### 5.4 Hunger, thirst, food and stamina (Step 3)
- **Hunger and thirst** drain **slowly** (eat and drink about every 30–40 minutes). At zero you just heal slower and get tired. **You never die from it.**
- **3 food slots** for "buff food." Each dish gives a **small** boost that lasts **25+ minutes**, for example:
  - +20% max health, or +15% max stamina, or
  - extra damage, or extra resistance (protection), instead.
- Missing buff food is **never a disaster** (on purpose, unlike games where bad food ruins you).
- **Food comes from:** mushroom farming at your base, hunting cave animals, cooking recipes at a cooking pot, and loot in ruins (ruins give **new recipes** and sometimes cooked food).
- **Water comes from:** underground pools and streams (fill a waterskin), buckets under dripping stalactites at your base, and juicy mushrooms (count as food and drink).
- **Stamina** is used by **everything**: running, jumping, swinging, dodging, blocking.

### 5.5 Your dwarf grows: levels, skills and runes (Step 3)
- **Skills get better as you use them.** Mining a lot makes you a better miner.
- You **also earn levels**, and each level gives **points** to spend in the skill tree.
- **Skill branches:** **Miner**, **Warrior**, **Smith & Builder**, **Survivor & Cook**. More can come later.
- **Runes (our spin):** you find small runes at random while exploring. You **carve each rune onto a big stone slab** (a Rune Slab) at your base.
  - Each rune **color** belongs to a skill branch (for example, one color for Miner, another for Warrior).
  - Each rune unlocks a step: a new recipe or a small bonus. Finishing a full set gives a big special perk.
  - In co-op, everyone in the world shares the slab.

### 5.6 The map (Step 3)
- The map **starts blank and fills in** where you've been. You can place your own pins.
- **Old parchment look, one page per "floor."** The cave is cut into layers like a building's floors (about 20 m tall each). The map shows the page for your current floor. You can flip pages up and down. Small ▲ / ▼ marks show where tunnels climb or drop.
- **Boss clues** show up on the map (see 5.9).
- We test this in play and change it if it's confusing.

### 5.7 Building and blueprints (Step 4)
- **Snap pieces:** walls, floors, beams, doors, stairs, and more.
- **Materials:** wood (cave trees, giant mushrooms), cut stone, metal, crystal and decorations, mushroom bricks, vines, and many rock colors (white marble, orange clay, brown, dark, yellow…). About **3 building styles per biome**.
- **Blueprints come from:** saving something you built by hand, finding ancient blueprints in ruins, and sharing with friends.
- **The chest builds piece by piece** (about 1 piece per second) once materials are in it, so you can watch it grow. It carves rock first, and it pauses if materials run out.
- **Support beams** and **cave-ins** both arrive here (see 5.1).

### 5.8 Fighting (Step 5)
- **Weapons (8):** sword, shield (parry or big block), axe, mace, two-handed axe, two-handed mace, spear, crossbow.
- **Light and heavy attacks** chain into **combos**.
- **Every** enemy attack can be **parried**. A perfect parry means **no damage**. Each parry fills the enemy's **stun meter**: a shield parry fills it a lot, a weapon parry fills it less. Full meter = enemy dazed and open.
- **Short dodge-roll** (costs stamina) as a backup. Parry stays the best move.
- **Friendly fire is ON by default.** The host can turn it off in world settings.

### 5.9 Gear: tiers, quality and gems (Step 3 tiers, Step 5 gems)
- **Tool tiers:** Stone → Copper → Silver → Iron → Steel → more later. Each tier can also be **upgraded** at the forge.
- **Quality:** crafted items have fixed stats, but a better Smith makes better **quality (Q1–Q5)**. Special named items can be found in ruins.
- **Gems** go into tools and weapons for fire, frost, poison, and more:

| Tier | Gem sockets |
|---|---|
| Stone | 0 |
| Copper | 1 |
| Silver | 1 |
| Iron | 2 |
| Steel | 2 + 1 **epic** gem |

- **Epic gems** do something unique, for example: a fire trail that burns enemies chasing you while you run, or every 5th hit makes a small frost blast around you.
- **Words to keep straight:** **runes** = carved on the slab (skills). **Gems** = put into gear (powers). **Crystals** = lantern fuel and crafting.

### 5.10 Monsters and bosses (Step 5 monsters, Step 6 bosses)
- **Pack leaders (our powered-up monster idea):** some monsters lead a pack. While the leader lives, the pack is **stronger**. Kill the leader and the pack **loses the boost** (they keep fighting, they don't run).
- **Crystal variants:** some monsters come in crystal-colored versions with matching powers (red = fire, blue = frost, and so on).
- **Main boss (one per biome):** hides in a secret lair. Old **wall markings** in places you discover give clues: the 1st marking shows a big circle on the map, the 2nd a smaller one, and after the **3rd** you know the exact spot.
- **Side bosses:** guard some of the big caverns (treasure, rare ore, blueprints).
- **Moving on:** the next pickaxe needs **both** the biome's best ore **and** a part from the main boss.
- **Boss drops:** every nearby player gets their own copy.
- **Raids:** when you discover a side-boss cavern, monsters sometimes raid your base. Kill that side boss and its raids stop. Kill the **biome boss** and **all** raids in that biome stop. If you summon the boss again and don't kill it, raids come back.

### 5.11 Your dwarf, death and saving (death in Step 3, the rest in Step 7)
- **Simple looks:** beard style, hair and beard color, skin tone, a few faces.
- **Your dwarf lives inside one world.** A new world means a new dwarf.
- **Dying:** you wake up at your bed. Your bag stays in a **grave** where you died, and you go back to get it.
- **Saving:** autosaves every 5 minutes and when you quit, plus a few backup saves.

### 5.12 Co-op (Step 2)
- Up to 4 players. **The world runs on the host's PC.** When the host leaves, everyone leaves. (A always-on server might come after release.)
- **Chests and ore:** first come, first served. **Boss drops:** one for each player nearby.
- **Controls:** mouse and keyboard first. Gamepad (and Steam Deck) in Step 7.

---

## 6. The roadmap (7 steps, each one playable)

| Step | Name | When it's done you can… |
|---|---|---|
| 1 | **First Tunnel** | Walk as a dwarf through Mossy Hollows, dig anywhere, mine stone & copper, see glowing caves, use the lantern |
| 2 | **Friends** | Up to 4 players digging in the same world over Steam |
| 3 | **Survive & Grow** | Hunger, thirst, buff food, stamina, crafting, tool tiers, levels + skills + Rune Slab, map, death & grave |
| 4 | **Build** | Snap pieces, blueprint-and-chest building (and carving), support beams, cave-ins |
| 5 | **Fight** | 8 weapons, combos, parry + stun meter, dodge, gems, first monsters, pack leaders |
| 6 | **Deeper** | Fungal Jungle, border rock, main boss + side bosses, wall-marking clues, raids |
| 7 | **Steam Ready** | Saving, menus, dwarf looks, settings, gamepad, polish, store page |

**Why co-op is Step 2:** adding co-op at the very end is the most common big mistake in survival games. It's like trying to slide a basement under a finished house. So Step 1 is built "co-op ready" in secret, and Step 2 turns it on before the game gets big.

Each step gets its **own** detailed build list right before we build it. This document only plans Step 1 in detail.

---

## 7. Step 1 "First Tunnel" — the details

### What the player sees
1. A **dwarf** (from the art pack you pick) standing in Mossy Hollows, camera behind them.
2. **Mossy Hollows**, about 400 m across: **2 big caverns** joined by twisty tunnels, green moss, blue glowing mushrooms, small streams.
3. The world is **random every time** (seed number: same seed = same cave).
4. **Border rock** at the edges of Mossy Hollows that the pickaxe can't dig. It's the hint that more is out there.
5. The dwarf **holds a lantern** that lights a circle around them. It burns glow crystals. When it's empty, a dim glow stays.
6. **Glowing crystals and mushrooms** on walls give soft colored light. The cave is moody, but never too dark.
7. **Pickaxe:** aim at rock and swing. Dirt and moss break in 1 hit, stone in 2–3, copper ore in 4–5. The rock is dug away smoothly.
8. Dug chunks **fall out** and get **picked up automatically** from a big radius.
9. An **item bar** at the bottom shows the hotbar (8 slots), and the bag holds ~30 slots of up to 100 each.
10. A small **frame-rate counter** (how many pictures per second the game draws) so we can check it runs smoothly on the gaming PC.

### Controls
- **W A S D** walk, **Space** jump, **Shift** run, **mouse** look around
- **Left click** swing pickaxe / dig
- **R** refill lantern with a crystal
- **Tab** open bag
- **Esc** pause and free the mouse

### The pieces of the game (each piece does one job)

| Piece | Its one job |
|---|---|
| **Cave Maker** | Uses the seed to decide where rock, air, caverns, tunnels, ore, border rock, and glow things go. |
| **World** | Holds the sugar-cube world (via Voxel Tools) and redraws chunks after digging. |
| **Dwarf** | Walking, jumping, running, camera. |
| **Pickaxe** | Finds the rock you're aiming at, counts hits by hardness, asks the World to dig it. |
| **Drops** | The little chunks that fall out, and the big auto-pickup radius. |
| **Inventory** | Keeps track of the bag and hotbar (stone: 12, copper ore: 3…). |
| **Item Bar** | Shows the hotbar and bag on screen. |
| **Lantern** | The light around the dwarf, its fuel, and the dim glow when empty. |
| **Glow Placer** | Puts crystals, mushrooms, and moss on cave walls. |

### "Co-op ready" rule for Step 1
Digging, picking up items, and refilling the lantern all go through one "**request → approve → everyone updates**" path, even with one player. In Step 2 the "approve" part moves to the host's computer, and nothing else has to be rebuilt.

### How we check it works
- **Auto-checks** (little tests the computer runs by itself), for example:
  - Same seed → same cave every time.
  - After digging a spot enough times, that spot is air.
  - Stone takes more hits than dirt. Border rock can't be dug.
  - Digging copper drops copper, and walking near it puts it in the bag.
  - A full stack (100) starts a new slot.
  - The lantern uses fuel and never goes fully dark.
  - The dwarf can't fall through the floor.
- **You play it** and say if digging feels fun, if it's too dark or too bright, and if it runs smoothly.

### Step 1 is done when
- You can play for 10 minutes, dig a tunnel between the two caverns, collect stone + copper, and refill your lantern.
- It runs smoothly on your gaming PC (the frame-rate counter stays high).
- You've picked the art pack.
- All auto-checks pass.
- `JOURNAL.md` and `CREDITS.md` are up to date.

### Not in Step 1 (on purpose)
Hunger/thirst, stamina, crafting, wood, building, cave-ins, monsters, fighting, co-op, map, saving, menus. They come in later steps.

---

## 8. Our two rules

1. **Journal everything.** `JOURNAL.md` records each work session: what we did, what went wrong, and how we fixed it, including Claude's own mistakes.
2. **Keep it simple.** Every explanation is 5th-grade level or below.

---

## 9. Known risks (things that could go wrong)

| Risk | What we'll do |
|---|---|
| Voxel Tools + GodotSteam might not work together | Smaller risk now (both plug into official Godot). Still test both together in Step 1. |
| Smooth digging can be slow on big worlds | Keep chunks small, only redraw what changed, show the frame rate from day one. |
| We don't know the gaming PC's power | The frame-rate counter in Step 1 tells us. Then we tune lights and world size. |
| Many glowing lights can be slow | Use lots of "fake glow" (shiny materials) and only a few real lights near the player. |
| Cave-ins on smooth walls are tricky | Wait until Step 4, and test it on its own first. |
| Saving dug-out worlds can be big | Plan the save format early (only save the changes from the seed), build it in Step 7. |
| The "floors" map might confuse players | Test it in Step 3 and change it if needed. |
| Free assets may not match each other's style | Pick one main art pack and fill gaps carefully; adjust colors to match. |
| Co-op "my friend sees something different" bugs | The one "request → approve → update" path from day one. |
| The whole dream is very big | One playable step at a time. Only Mossy Hollows + Fungal Jungle are planned now. |
