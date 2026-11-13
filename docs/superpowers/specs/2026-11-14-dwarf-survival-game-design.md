# Dwarf Survival Game — Design Plan

*Written: November 14, 2026. Game name: not picked yet (working name "Dwarf Game").*

This is our big plan. It says **what** we're making and **in what order**.
Everything is written so a 5th grader can follow it.

---

## 1. The dream (the whole game, someday)

You are a **dwarf**. The whole game happens **underground**. There is no sky.

- **Dig anywhere.** Every wall, floor, and ceiling can be dug away. Digging leaves smooth, natural-looking holes (not Minecraft squares).
- **Explore.** Huge caverns that glow with crystals and mushrooms, joined by twisty tunnels. The deeper you go, the more the world changes (new **biomes** = new "zones" with their own look, creatures, and loot).
- **Survive.** Watch your **hunger** and **thirst**. Fight **monsters**.
- **Build.** Snap-together pieces (walls, floors, beams, doors) like Valheim.
- **Blueprints (our special feature).** Place a see-through "ghost" plan of a building. A chest comes with it. Put the needed materials in the chest and the building **builds itself**. If the ghost is placed inside solid rock, it **carves the rock out first**, then builds.
- **Fight.** Different weapon types. Light and heavy attacks that chain into **combos**. **Every** enemy attack can be **parried**. A perfect parry = **no damage**. Each parry fills the enemy's **stun meter**; a **shield** parry fills it a lot, a **weapon** parry fills it less. Full stun meter = enemy is dazed and open.
- **Friends.** Up to **4 players** together, joining through **Steam**.
- **Sell it.** The goal is that it could be sold on Steam one day.

**Look:** a mix of Valheim and Grounded — chunky low-poly shapes, warm glowing colors, a bit of cartoon charm.
**Camera:** behind the dwarf (third-person).
**Inspiration (ideas only, never copied):** Valheim, Conan Exiles, 7 Days to Die, Grounded, and the idea of a dwarf-mining game done *well*. We never copy any game's names, characters, art, maps, or music.

---

## 2. Tools we use

| Thing | What we picked | Why (simple) |
|---|---|---|
| Game engine | **Godot 4.7.2** official (free, no fees ever) | Almost everything is saved as text, so Claude can build it and you just press Play. |
| Dig-anywhere world | **Voxel Tools 1.7 — GDExtension edition** (free, MIT) | It already does the "sugar-cube world" trick with smooth walls. Saves months. The GDExtension edition plugs into the normal Godot. |
| Steam co-op (later) | **GodotSteam — GDExtension edition** (free) | Lets friends click "Join" through Steam. Also plugs into the normal Godot. |
| Code language | **GDScript** (Godot's own language) | Simple, made for Godot. |

**Checked on Nov 14, 2026:** both add-ons come as "GDExtension" plug-ins for the *official* Godot (Voxel Tools needs 4.5+, GodotSteam needs 4.4+). That means we don't need a special custom Godot, so they should work together. We still test it for real early in Step 1. (Note: the GDExtension edition of Voxel Tools leaves out "FastNoise2", a faster noise maker. We'll use Godot's built-in noise instead.)

**Claude's helper tools (on this computer):**
- **Godot MCP** (Coding-Solo/godot-mcp): lets Claude start the game, read error messages, and stop it.
- **GodotPrompter** skills: Godot know-how for Claude (player controllers, multiplayer, procedural generation, and more).
- **Superpowers** skills: brainstorming, planning, debugging, testing.
- **Context7**: up-to-date docs for Godot and the add-ons.

---

## 3. Free stuff (assets) we use

Only assets that are clearly allowed in a **game you sell** (best: "CC0" = free for anything, no strings).

- **Characters, props, tools:** Kenney, Quaternius, KayKit
- **Rock and stone textures:** Poly Haven, ambientCG
- **Animations** (walking, swinging): Mixamo
- **Sounds and music:** Freesound (CC0 only), OpenGameArt (CC0 only), Sonniss GDC packs

Every asset goes in `CREDITS.md` with: name, where it came from, its license, and the date we got it.

---

## 4. The roadmap (7 steps, each one playable)

| Step | Name | When it's done you can… |
|---|---|---|
| 1 | **First Tunnel** | Walk as a dwarf in a random cave, dig anywhere, mine stone & ore, see glowing caves |
| 2 | **Friends** | Up to 4 players digging in the same cave over Steam |
| 3 | **Survive** | Hunger, thirst, food, crafting bench, better pickaxes |
| 4 | **Build** | Snap pieces + blueprint-and-chest building (and carving blueprints) |
| 5 | **Fight** | Weapons, light/heavy combos, parry + stun meter, first monsters |
| 6 | **Deeper** | New underground biomes and bosses |
| 7 | **Steam Ready** | Saving, menus, settings, polish, store page |

**Why co-op is Step 2:** adding co-op at the very end is the most common big mistake in survival games — like trying to slide a basement under a finished house. So Step 1 is built "co-op ready" in secret, and Step 2 turns it on before the game gets big.

Each step gets its **own** detailed plan right before we build it. This document only plans Step 1 in detail.

---

## 5. Step 1 "First Tunnel" — the details

### What the player sees
1. A **dwarf** (free low-poly model) standing in a dark cave, camera behind them.
2. The dwarf carries a **lantern** that lights a circle around them.
3. The cave is **random every time** (we use a "seed" number — same seed = same cave, which helps testing).
4. **Big caverns** joined by **tunnels**.
5. **Glowing crystals and mushrooms** on walls give soft colored light.
6. **Pickaxe:** aim at any rock and swing. Rock is dug away smoothly.
7. Digging gives **stone**. Digging shiny veins gives **copper ore** or **iron ore**.
8. An **item bar** at the bottom shows what you collected and how many.

### Controls
- **W A S D** walk, **Space** jump, **Shift** run, **mouse** look around
- **Left click** swing pickaxe / dig
- **Esc** pause and free the mouse

### The pieces of the game (each piece does one job)

| Piece | Its one job |
|---|---|
| **Cave Maker** | Uses the seed to decide where rock, air, ore, and glow-crystals go. |
| **World** | Holds the sugar-cube world (via Voxel Tools) and redraws chunks after digging. |
| **Dwarf** | Walking, jumping, running, camera. |
| **Pickaxe** | Finds what rock you're aiming at, asks the World to dig it, and reports what was dug. |
| **Inventory** | Keeps count of what you're carrying (stone: 12, copper ore: 3…). |
| **Item Bar** | Shows the Inventory on screen. |
| **Glow Placer** | Puts crystals and mushrooms on cave walls. |

### "Co-op ready" rule for Step 1
Digging and picking up items go through one "**request → approve → everyone updates**" path, even though there is only one player. In Step 2 the "approve" part moves to the host player's computer, and nothing else has to be rebuilt.

### How we check it works
- **Auto-checks** (little tests the computer runs by itself), for example:
  - Same seed → same cave every time.
  - After digging a spot, that spot is air.
  - Digging copper adds copper to the inventory.
  - The dwarf can't fall through the floor.
- **You play it** and say if digging feels fun, if it's too dark or too bright, and if it runs smoothly.

### Step 1 is done when
- You can play for 10 minutes, dig a tunnel between two caverns, and collect stone + both ores.
- It runs smoothly on your gaming PC.
- All auto-checks pass.
- `JOURNAL.md` and `CREDITS.md` are up to date.

### Not in Step 1 (on purpose)
Hunger/thirst, building, monsters, fighting, co-op, saving, menus. They come in later steps.

---

## 6. Our two rules

1. **Journal everything.** `JOURNAL.md` records each work session: what we did, what went wrong, and how we fixed it — including Claude's own mistakes.
2. **Keep it simple.** Every explanation is 5th-grade level or below.

---

## 7. Known risks (things that could go wrong)

| Risk | What we'll do |
|---|---|
| Voxel Tools + GodotSteam might not work together | Smaller risk now (both plug into official Godot). Still test both together in Step 1 before building lots on top. |
| Smooth digging can be slow on huge worlds | Keep chunks small; only redraw what changed; test speed early. |
| Free assets may not match each other's style | Pick one main art pack and fill gaps carefully; adjust colors so they match. |
| Co-op can cause "my friend sees something different than me" bugs | Use the one "request → approve → update" path from day one. |
| The whole dream is very big | Build one playable step at a time. Don't start a step until the one before it is fun. |
