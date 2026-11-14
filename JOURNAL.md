# Build Journal — Dwarf Game

Our diary of building the game: what we did, what went wrong, and how we fixed it.

---

## Day 1 — November 13–14, 2026: Planning

**What we did**
- Picked the idea: a 3D survival game where you play a dwarf, all underground.
- Answered lots of multiple-choice questions to decide the big stuff:
  - It might be sold on Steam one day, so all free art must be allowed in paid games.
  - The look is a Valheim + Grounded mix.
  - Up to 4 friends can play together through Steam.
  - The caves are new and random every game.
  - You can dig anywhere, and the walls stay smooth.
  - The camera sits behind the dwarf.
  - Building uses snap pieces, plus a special **blueprint + chest** idea.
  - Fighting has combos and parries, and shield parries stun enemies more.
  - Survival means hunger, thirst and monsters.
- Picked **Godot** as the game engine because Claude can build almost all of it as text files.
- Made a 7-step roadmap. Step 1 is "First Tunnel" (dig and explore).
- Wrote the plan: `docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md`

**Hurdles / mistakes**
- The project folder was empty, so Claude couldn't look at our older game "Deep Rise" for ideas. Not a real problem. We just started fresh.
- Big hurdle we saw coming: co-op is the hardest thing to add late. **Fix:** we moved "Friends" to Step 2 and will build Step 1 "co-op ready."

**Setting up the workshop (later on Day 1)**
- Turned on **git** "save points" and connected the project to GitHub (`max64800/my-survival-game`).
- Installed **Godot 4.7.2** (the official version).
- Gave Claude new helpers:
  - **Godot MCP** lets Claude start the game and read its error messages by itself.
  - **GodotPrompter** is a pack of Godot know-how.
- Good news: we checked, and both the digging add-on (Voxel Tools) and the Steam add-on (GodotSteam) now plug into the normal Godot. So the biggest risk in our plan got much smaller.

**Hurdles / mistakes**
- **Mistake caught:** the first time Claude connected Godot MCP, it saved a settings file *inside the project* that had your computer's username in it. Your GitHub repo is **public**, so that would have shown up online. **Fix:** Claude moved the setting to a private spot on your computer and deleted the file before saving to GitHub.
- Small one: Windows didn't create a short `godot` command, because that needs admin rights. Not a problem. Claude just uses the full path to Godot.
- Heads-up: the GitHub repo is **public**, so anyone can see the code. That's fine for now. If you want to sell the game later, we can switch it to private with one click.

**Next**
- You read the plan and say yes (or ask for changes).
- Claude writes the step-by-step build list for Step 1.

---

## Day 2 — November 14, 2026: Big planning Q&A (on the MacBook)

**What we did**
- Copied the project from GitHub onto the MacBook. Plan here, build on the gaming PC.
- Answered 13 rounds of multiple-choice questions and filled in almost the whole game:
  - **World:** a "star" of 7 biomes. Mossy Hollows in the middle, 4 around it, 1 above, 1 below. Each about 400 m wide with 2–5 big caverns. Border rock you can only dig with a better pickaxe. No day/night.
  - **Digging:** hard rock takes more hits. Chunks fall out and get picked up from a big radius.
  - **Lantern:** held in hand, burns wood or crystals (crystal = light color), keeps a dim glow when empty, upgrades to sit on your back.
  - **Survival:** slow, gentle hunger/thirst. 3 small food buffs that last 25+ min. Stamina for everything.
  - **Growing:** skills improve with use, plus levels and points. **Runes** get carved on a stone slab at your base, and each color helps a skill branch.
  - **Gear:** Stone → Copper → Silver → Iron → Steel. **Gems** go into gear (fire, frost, poison). Steel gets an epic gem.
  - **Fighting:** 8 weapons, dodge-roll, friendly fire on (can turn off).
  - **Monsters:** pack leaders make their pack stronger. Crystal variants. Hidden bosses found with 3 wall-marking clues. Side bosses guard caverns and send raids until you kill them.
  - **Building:** your own, found, and shared blueprints. The chest builds piece by piece. Cave-ins come with support beams in Step 4.
  - **Co-op:** host runs the world. Each world has its own dwarfs. Boss loot for everyone.
- Updated the plan with all of this. Step 1 is now "a slice of Mossy Hollows" with stone + copper (iron moved later).

**Hurdles / mistakes**
- **Underground maps are hard** because tunnels stack on top of each other. **Fix:** an old-parchment map with one page per "floor," flipping as you climb. We'll test it.
- **Two kinds of "runes" got mixed up** (skill runes and gear powers). **Fix:** runes = carved on the slab, **gems** = put in gear, **crystals** = lantern fuel.
- **Claude's mistake:** the first "star" drawing in the plan put North and South *under* the start biome. Fixed before saving.
- We don't know how strong the gaming PC is. **Fix:** Step 1 shows a frame-rate counter so we can tune it.

**Next**
- You read the updated plan and say yes (or ask for changes).
- Claude writes the Step 1 build list, saves it to GitHub, and you build on the gaming PC.

---

## Night 2 — November 14, 2026 (00:30 → morning): Claude's overnight build on the MacBook

You went to sleep and asked Claude to build, test and prepare as much as possible.

**The big picture: 7 "branches" (like parallel copies of the project, each built on the one before)**

| Branch | What's in it | Status |
|---|---|---|
| `main` | **Step 1, First Tunnel** + all design docs | Ready to play-test |
| `step-2-friends` | + **co-op** (play with friends) | Tested with two game windows |
| `step-3-survive` | + **survival, crafting, skills, map** | Tested; needs play-testing |
| `step-4-build` | + **building, blueprints, chests, cave-ins, dying & graves** | Tested; needs play-testing |
| `step-5-fight` | + **weapons, monsters, parry, dodge** (Mossy Hollows) | Tested; needs play-testing |
| `step-6-deeper` | + **ruins, rune shrines, boss clues, 3 bosses, raids, sounds** (Mossy Hollows finished) | Tested; needs play-testing |
| `step-7-ready` | + **save & continue**, art candidates (try `-- art=quaternius`) | Tested |
| `fungal-jungle` | + **the Fungal Jungle** (biome 2), poison/burn/chill, crystal monsters, cave animals, crossbow, friendly fire, spore clouds, gems, boss altars | Tested; **the newest everything** |

Why branches? Our rule says each step must be playable and approved before the next one. So `main` stays Step 1 until you've tried it. The later steps wait on their own branches, ready to merge when you say yes.

**What we did**
- Installed Godot 4.7.2 on the MacBook (in a temporary folder) so Claude could actually run the game, not just write it.
- **Step 1 (main):** random caves (2 big caverns, 7 small rooms, twisty tunnels), smooth digging, rock hardness (moss 1 hit, stone 3, copper 5), undiggable border rock, chunks that fly into your bag, 8-slot hotbar + 30-slot bag, a lantern you refill with glow crystals, glowing crystals and mushrooms, frame-rate counter, pause screen.
- **Checks:** a test robot (`tools/run_tests.sh` / `.bat`) runs auto-checks, plus an "autopilot" that plays the game by itself and takes screenshots. Claude looked at every screenshot.
- **Design docs** (`docs/design/`): combat & monsters, progression & economy, world & building. Then a review pass made all three agree. **26 open questions for you** are in `docs/design/README.md`. Each has a default (★); only answer the ones you want to change.
- **Steam check:** the Steam add-on and the digging add-on work together. (That was the biggest technical risk in our plan.)
- **Step 2 (branch `step-2-friends`):** co-op over IP address and Steam lobbies, a start menu, friends with names and shirt colors. Late joiners catch up on every hole already dug. The "netcheck" robot ran two game windows and checked both see the same cave.
- **Step 3 (branch `step-3-survive`):** health, stamina, hunger, thirst (never kills you), 3 food-buff slots, 16 dishes + 6 drinks, ~80 items, ~55 recipes, placeable stations (campfire, workbench, smelter, anvil…), hanging roots for wood, mushrooms, fiber, clay, levels + 4 skills + 43 perks (K screen), the Rune Slab rules, and a parchment map per floor (M screen).
- **Step 4 (branch `step-4-build`):** the Build Hammer with a green/red ghost, 11 kinds of pieces in 10 materials (B menu), steadiness (wood bridges sag and fall, metal reaches far), chests, **blueprints**: save your own (C), place one from the book (V), fill its Builder's Chest and it carves rock and builds itself piece by piece. A starter "Small Rootwood Lodge" blueprint ships with the game. **Cave-ins**: loose rock lumps and 20 m+ "icicles" fall, and mine props hold rock up. **Dying**: your haul goes into a grave (with a light beam so you can find it), you keep your hotbar tools, you wake at your bed.
- **Step 6 (branch `step-6-deeper`):** Mossy Hollows is finished. The cave now plans special places: 3 old ruins with loot chests and sleeping Rustwights, 5 rune shrines (2 sealed in rock), 4 abandoned camps, crystal geodes sealed in rock, 3 monster nests, a Great Hall, a Nest Cavern, and **Orrumhal's lair sealed in rock** far from the start. **3 wall carvings** (press E) draw shrinking circles on your map until you know exactly where to dig. **Bosses:** Orrumhal (3 phases: 4 Mossnippers crawl out in phase 2, his chest opens in phase 3), Skerra (calls her brood, stun her to stop it) and Brask (horn wakes 2 Rustwights). Orrumhal drops the **Keeper's Heartstone** for the Copper pickaxe, which breaks the border rock. **Raids** come to your base (bed + a station) while side bosses you've found are alive. The Rune Slab screen lets you carve runes. **Sounds** (free CC0 from Kenney): digging, crystals, chopping, building, hits, a bell-clang for perfect parries, footsteps, pickups.
- **Step 7 start (branch `step-7-ready`):** **saving**: autosave every 5 minutes, when you quit, and on F5, with 3 backups. "Continue" on the start menu. Plus the **art choice**: see `docs/art/ART-CHOICE.md`.
- **Step 5 (branch `step-5-fight`):** sword, mace, spear, shield, great axe, great maul (stone/copper/silver), light and heavy attacks, combos, block, **perfect parry** (stuns monsters), dodge-roll, the back lantern (frees your hand for a shield). The 6 Mossy Hollows monsters with their attacks and warnings, pack leaders with gold crowns, a spawner that fills caves near you, health bars and damage numbers. The damage math matches the combat doc's examples exactly.

**Hurdles / mistakes (including Claude's)**
- The test robot first said "PASS" even when a test crashed. **Fix:** it now catches every error, and Claude proved it by planting a broken test.
- Copper was 20% of all rock, far too much. The tests caught it. **Fix:** now about 5%.
- The first screenshots were too dark at a distance. **Fix:** brighter cave "bounce light", less fog.
- Crystals were too tiny to notice. **Fix:** 1.8× bigger.
- Roots hung at an angle from slanted ceilings, out of reach. **Fix:** they hang straight down now.
- Roots and brown mushrooms were invisible in the dark. **Fix:** a faint glow on every harvestable thing.
- The smelter needs clay, but the cave had none. **Fix:** clay patches in the lower cave.
- The progression doc measures hardness ×10 (stone 26, pickaxe 10), but Step 1 used small numbers. Same hit counts. **Fix:** Step 3 switches to the doc's ×10 scale.
- The three design docs disagreed with each other in places (the first boss needed ~370 sword hits!). **Fix:** a review pass; the boss now takes about 5 minutes.
- Some names were too close to other games' names. **Fix:** renamed (for example, "Warden" became "Keeper").
- Walls couldn't be placed on floors, and walls couldn't meet at corners (they "overlapped" by a few cm). **Fix:** pieces may touch.
- The Builder's Chest carved a bit too deep, so its floors weren't "touching rock" and nothing could be built. **Fix:** gentler carving, and the rock check looks a bit deeper (the cave is made of 1 m blocks).
- **Claude almost shipped a co-op bug:** friends' computers replayed the Builder's Chest's small carving scoops as big pickaxe holes, so caves would slowly differ between friends. **Fix:** every dig now carries its exact size to everyone.
- Cave-in checks silently didn't run near the top and bottom of the world (that part never loads). **Fix:** the check stays inside the world and retries if the area isn't loaded yet.
- Monster health bars showed as white boxes (the font has no block characters). **Fix:** real little bars.
- In the co-op fight test, the monster arrived too early and killed the friend before they could craft. (Good news: dying works in co-op.) **Fix:** the test waits until the friend is ready.
- The design docs had no weapon recipes at all. **Fix:** Claude added starting recipes, clearly marked "tune in play-testing".
- Tiny hidden pockets (geodes, shrines) could be closed up by the bumpy cave walls. **Fix:** bigger pockets (only 2–3 geodes fit now instead of 6).
- **A bug the screenshots caught:** every monster shrank back to normal size after its first attack, so the 3 m boss became 1 m and disappeared in his dark hall. **Fix:** the attack wobble keeps each monster's size. Bosses also glow a little now so you can read them.
- The sound script used a name Godot reserves (`_get`), so no sound played and 18 checks failed at once. **Fix:** renamed. (The test robot found it in seconds.)
- The test robot got slow (5 minutes) after caves started planning special places. **Fix:** the same seed's cave plan is reused: back to 2 minutes.
- The rigged art model came out 100× too big (its skeleton is stored scaled ×100). **Fix:** measure the real head height in the world.

**Not done yet / known limits**
- No art pack yet: the dwarf and stations are simple shapes. You pick the pack on the PC.
- No sounds yet.
- Steam lobbies are written but untested. They need Steam running and two accounts or PCs.
- Runes can only drop from pack leaders so far (ruins and shrines come with Step 6), and there's no Rune Slab screen yet. The map isn't shared between friends yet.
- Not built yet from the combat doc: crossbow, gems, friendly fire. Boss arenas don't seal shut yet, and boss altars (re-summoning) aren't built. (Poison/burn/chill and crystal monsters came later in the night: see below.)
- Friends' health/hunger aren't saved (their bag and skills are).
- A cave-in check takes ~17 ms after each dig on the host. Fine for now; it can move to a background thread later.

**Next (for you, on the gaming PC)**
1. `git pull --ff-only`, open in Godot, press F5. See `docs/GAMING-PC-START.md`.
2. Play Step 1 for 10 minutes and tell Claude how it feels.
3. To try a later step: `git switch step-5-fight` (or another branch name), then press F5 in Godot. `git switch main` goes back.
4. If you like a step: say "merge step 2" (then 3, 4, 5). Each branch already contains the ones before it.
5. Skim the 26 questions in `docs/design/README.md`.

---

## Night 2, later — November 14, 2026 (morning): a bug hunt, then the Fungal Jungle

**What we did**
- **A second pair of eyes:** Claude sent a separate "reviewer" helper through the finished code to hunt for bugs. It found real ones (list below). All fixed on `step-7-ready`, with a new test file (`tests/test_safety.gd`) so they can't come back.
- **The Fungal Jungle (new branch `fungal-jungle`):** the second biome, east of Mossy Hollows.
  - **The way in:** a 20 m wall of border rock between the two biomes, with **2 gate tunnels** dug most of the way through. Only a 4 m "plug" is left, and the stone pickaxe bounces off it ("Too hard!"). The **Copper pickaxe** (from Orrumhal's Heartstone) breaks through. A glowing carved arch marks each gate.
  - **New rock:** dark purple **sporestone** (the jungle's stone), pale **mycelium** floors, yellow **amberrock** bands, and **silver ore** (needs the copper pickaxe).
  - **New things growing:** **giant mushrooms** 3–6 m tall (the jungle's wood: needs a copper axe, gives timber and flesh), **spore truffles**, glowing **ember morels**, **amber crystals** (lantern fuel).
  - **5 new monsters** (combat doc 5.3): Wheezecap (walking mushroom, poison puffs), Needlemite (glassy mite packs, poison jabs), Husk Charger (huge horned beetle that charges 12 m), Gill Stalker (mantis that hides and lunges), Cap Spitter (rooted mushroom that lobs spore bombs from 20 m).
  - **4 new bosses:** **Thallus, the Grey Bloom** (main boss, 4400 HP, 3 phases, sealed lair found with 3 wall carvings, drops the Bloomheart Core for the Silver pickaxe), plus side bosses **Old Ironshell** (Silver Vault), **Sivix, Mother of Needles** (Brood Hollow) and **the Gloamstalker** (Lantern Grove). Each side boss sends raids once found.
  - Jungle ruins hold silver and jungle food; jungle shrines give jungle runes (and sometimes a missing Mossy rune, as the doc says). The map keeps separate pages for each biome. 3 new building styles: Sporestone, Amber, Silver.
  - **The world's edge** is now its own rock that **nothing** can ever dig. Before, the Copper pickaxe could have dug out of the world.
- **Poison, burn and chill** (combat doc 2.6): poisonous hits fill a meter. When it's full you're **Poisoned** (3 damage a second for 10 s, no healing). Burn is the same but hotter. Chill slows you, and getting chilled twice freezes you. Parrying stops the buildup and blocking halves it. Shown under your health bars.
- **Crystal monsters** (combat doc 7): about 1 in 25 Mossy monsters and 1 in 14 jungle monsters has glowing crystals on its back: red (fire), blue (frost), green (poison), violet (teleports next to you), amber (stone skin). They're tougher, give double XP and drop 4 crystals.
- **Faster:** the cave planner now uses a "lookup grid" (like an index in a book: it only checks the cave shapes near a spot instead of all of them). Planning both biomes takes **0.2 s instead of 4 s**, placing plants 0.5 s instead of 14 s, and the whole test robot runs in **~75 s** (was 123 s with one biome).

**Bugs the reviewer found (all fixed)**
- **A friend's bag could be copied or lost:** if a friend left and came back, they got their *old* bag from the save (so items they'd put in a chest existed twice), and a friend who was offline during a save lost their dwarf. **Fix:** the host keeps each friend's dwarf when they leave and puts it in every save.
- **Smelting and cooking were lost on save:** the ingredients were taken, but the job in the smelter wasn't saved. **Fix:** saved now.
- **Cheating holes:** a friend's computer could send "broken numbers" (NaN, "not a number") that slipped past every distance check, or a stretched aim direction that dug 20 m away. **Fix:** the host now refuses broken numbers and shortens aim directions to normal length. Only the right player can parry a monster's swing, and attack messages are cleaned up.
- **A half-empty waterskin refilled itself** when you put it in a chest and took it out. **Fix:** items keep their own data in chests.
- **An unknown rune vanished** when carved. **Fix:** it stays in your bag.
- **Build-site ghosts mixed up** for friends who joined late. **Fix:** chests load before build sites.
- **Pickups far from the host could fail** (the host's copy of a dropped item could fall through unloaded ground). **Fix:** where the item first appeared also counts.
- One reported issue was left on purpose: a friend could "die" on purpose to teleport home, but that only loses their own bag into a grave. In a friends-only game that's fine.

**Hurdles / mistakes (including Claude's)**
- The first jungle plan put some jungle shrines on the *Mossy* side, because the gate tunnels cross both biomes. **Fix:** jungle places only use jungle tunnels.
- Where a gate tunnel met the biome, a paper-thin wall of rock appeared (two "boxes" touching at exactly 0). **Fix:** the gate's box reaches 6 m into each biome.
- One jungle boss cavern was missing (the code skipped the first room of every biome, which is right for Mossy's start room but not the jungle). **Fix:** only Mossy skips it.
- Everything got 2.5× slower with two biomes (twice the shapes, asked twice as often). **Fix:** the lookup grid, which made it faster than before.
- Some hanging roots measured their length from a nearby wall instead of the floor (an old bug, found by a jungle test). **Fix:** roots need clear space below.
- Claude first invented 3 new items (horn, stalker meat, glow spores) that the combat doc says should be old items (chitin plate, beetle meat, glow slime). **Fix:** they follow the doc now.
- The world's-edge rock would have looked like jungle sporestone (wrong color number in the shader). Caught by reading the shader. **Fix:** its own dark look.
- The autopilot's first digging was eaten by random wickwings that came to say hello, and in the jungle the Gill Stalker knocked the robot out before its photo. **Fix:** the robot turns monsters off for its photos and spawns its own.
- A safety check stopped Claude from cleaning a log folder with a risky delete command. **Fix:** used a fresh folder instead.

**Not done yet / known limits**
- Blinding (Gill Hiss, Smoke Gill) and the Gill Stalker's real hiding are simplified.
- The jungle's boss arena needs its "rooting" phase and spore sacs (Thallus fights with his normal attacks for now).
- Recipes for the new monster parts (needles, venom sacs, Sivix silk…) aren't designed yet; they're collectibles for now.

**Next (for you, on the gaming PC)**
1. `git pull --ff-only`, then `git switch fungal-jungle` for the newest everything (see `docs/GAMING-PC-START.md`).
2. To see the jungle quickly without beating Orrumhal, start the game with `-- jungle` (see the PC guide): you appear next to the purple gate with a copper pickaxe, axe, sword and shield. Dig through the plug and you're in.

---

## Night 2, even later — November 14, 2026: animals, crossbow, gems, and more

**What we did (all on `fungal-jungle`)**
- **Cave animals** (combat doc 5.4), for hunting food: **Moss Shufflers** (roll into an armored ball when hit: use a mace!) and **Flitters** (little bats) in Mossy; **Truffle Hogs** (fight back until half hurt, then run), **Lampshell Snails** (glowing shells, drop lantern slime) and floating **Puffpods** (pop into a harmless puff) in the Jungle. They ignore you until you hit them, and come back 20 minutes after a hunt.
- **The crossbow** (combat doc 3.6): tap left click to shoot from the hip (a little wobbly), hold right click to aim (zooms in, dead straight, more damage), R to reload (running stops the reload). 3 crossbows (wood, copper, silver) and **7 kinds of bolts**: stone, metal, thumper (good on shells), ember, rime, blight, and glow bolts that light up a spot for a minute. Half your bolts can be picked up again.
- **Friendly fire** (doc 2.7): on by default. Your swings and bolts hurt friends for half damage (never stun them). The host can switch it off on the pause screen (Esc).
- **Spore clouds** that hang in the air for a few seconds: Wheezecaps puff them and burst into one when they die, Cap Spitter bombs leave one, Thallus breathes a big one, green crystal monsters leave a trail. Walk out of them! **Spore Ward Stew** halves them.
- **Monsters get poisoned, burned and chilled too** (from bolts and gems). Chilled monsters walk slower; bosses can't be frozen solid.
- **Gems** (combat doc 4): 9 gems (Ember, Rime, Blight, Leech, Jolt, Swift, Bulwark, Keen, Burrow) that go into copper and better weapons, shields, pickaxes and crossbows at a new **Gem Bench**. Each gem does something different in each kind of item (an Ember Gem in a sword adds fire; in a shield, your perfect parries set the attacker burning). Putting a gem in is free; taking it out costs 5 blue crystals. Gems drop from crystal monsters (15%), some monsters and bosses, old ruin chests, and ore veins. The 6 **epic gems** drop too (the first boss kill always gives one) but only fit Steel gear, which comes in a later biome: you carry them as a prize.
- **Boss altars**: once you've beaten a main boss, its altar can call it back for another fight (Orrumhal: 10 copper ingots, 5 blue crystals and a rune shard). And during a main boss fight the **lair walls can't be dug**, so nobody can tunnel around the fight.

**Hurdles / mistakes (including Claude's)**
- **Claude pushed a change before the co-op robot had finished**, and that robot run failed. Looking into it found a real old bug: **a friend who joined while dig sparkles were in the air was never let in** (the sparkles sat in the same folder as the players, and the host tripped over one). **Fix:** the host only counts dwarfs. Fixed on every branch from Step 2 up. Lesson: wait for the robot before pushing.
- A test expected 15 damage from a friend's blight bolt, but the right answer is 19 (the rounding happens before halving). The code was right; the test was fixed.
- A poison test broke when spore puffs became clouds (the poison moved from the hit into the cloud). **Fix:** the test counts both.
- The first spore cloud looked like a solid lavender ball. **Fix:** a soft bunch of see-through puffs that fade out.
- Several "this value has no type" errors (Godot's strict mode treats them as errors, which is good: they catch mistakes early). Each was fixed by writing the type.

**Not done yet / known limits**
- Crossbow bolts hit instantly (no flight time or drop yet) and there are no head-shots yet.
- Gems: the Ember Gem in a pickaxe (faster smelting) does nothing yet; epic gems have no effects until Steel exists.
- Thallus doesn't have his spore sacs or underground "rooting" phase yet; Orrumhal's heartstone weak spot isn't built yet.
- The lair's stone door doesn't grow shut (the locked walls do the same job for now).

---

## Night 2, last round — November 14, 2026: water, rune recipes, and a second bug hunt

**What we did (all on `fungal-jungle`)**
- **Water finally exists.** Before this, nothing in the game gave you water, so most cooking recipes couldn't be made. Now some ceilings have **dripping stalactites** (look for little falling drops). Put a **Drip Bucket** under one and it fills with 1 bucket of clean water every 4 minutes (holds 5). Press E on it: it fills your empty waterskins first, then gives buckets of water. The rune-taught **Copper Drip Basin** holds 15 and fills twice as fast. A bucket placed where nothing drips says so.
- **All 19 rune recipes now exist.** Before, carving those runes taught nothing. New things:
  - **Lights:** Crystal Sconce (a light post) and Glow Marker (a flag that shows on your map).
  - **Getting around:** Rope Ladder (place it and hold W to climb, 6 m).
  - **Throwables:** Blasting Pod (throw it to blow a 2 m hole) and Spore Bomb (a poison cloud for monsters).
  - **Tools:** Prospector's Lens (hold it and aim at rock: it shows how hard it is and what's 3 m behind) and Training Dummy (hit it to train Fighting).
  - **Fight boosts:** Whetstone (+5% damage, 10 min), Bugbane Oil (+15% against bugs) and War Horn (friends within 15 m hit 10% harder for a minute).
  - **Building:** ruin-style Ancient Brick and mushroom bricks.
  - **Storage:** Copper-bound Chest (36 slots) and Ore Crate (60 slots, ore only).
  - **Smelting:** Twin Smelter (smelts 2 things at once).
  - **Drinks:** Moss Ale and Spore Mead.
  - **Gear:** Spore Mask (keep it on your hotbar: spore clouds hurt half as much).
- **Old Recipe Pages:** every ruin chest holds 2. Using one teaches everybody a recipe that's "found in ruins" (7 recipes had no way to be learned before).
- **Food that adds damage now actually adds damage in fights.** The host does the fight math, and it couldn't see your food buffs before.

**Second bug hunt (a reviewer helper read all the new code)**
- **Claude's mistake:** the first reviewer got confused because Claude switched branches (to update the journal) while it was still reading the files. **Fix:** Claude saved a frozen copy of the new code for the reviewer to read instead.
- Found and fixed:
  - A cheating friend could spam friendly-fire hits; now they're limited to how fast the weapon really swings.
  - A broken number in a parry message could break a monster's stun.
  - Crossbow hits must now be on the bolt's actual line.
  - "I blocked" messages need a real swing that was aimed at you.
  - Stunned animals chased you; now they run.
  - The altar now checks it can call the boss *before* taking your offering.
  - Aiming at the altar said "Rune shrine".
  - Cave building got a bit faster.
- Leech healing could have "healed" a dwarf who had already fallen. **Fix:** it can't.
- The co-op robot failed once because the friend's XP report was a moment behind the host (XP travels in little batches twice a second). Ran it 3 more times: all passed. **Fix:** the robot now allows that small delay.

**Not done yet / known limits**
- **Older branches (`step-3` to `step-7`) still have no water source.** Only `fungal-jungle` has drips. Use `fungal-jungle` for play-testing survival.
- Streams and pools of water (doc 6.4) aren't in the cave yet; drips are the only source besides juicy bellcaps.
- The Crystal Sconce doesn't use up crystals over time yet (it shines forever).
- Rope ladders always stand 6 m tall.


---

## Day 3 — November 14, 2026: Back on the gaming PC

**What we did**
- Downloaded (pulled) all the MacBook work onto the gaming PC. Nothing clashed.
- Ran all 37 auto-checks on Windows: **all passed**. So the Windows digging add-on file works.
- Ran the autopilot on the PC (an RTX 3060 Ti graphics card). The cave loads in 4.3 seconds. Digging, walking and the lantern refill all work, and the screenshots look right.

**Hurdles / things to look into**
- **Frame rate is only about 50 FPS**, about the same as the MacBook. A 3060 Ti should do much better, so something is probably slowing it down that isn't the graphics card (maybe the lights, or the cave being rebuilt). The "lowest 1 FPS" was the moment the cave loaded. **Next:** find out what's slowing it down, after your play-test.

### Later on Day 3: the auto-recorder

**What we did**
- You asked for the game to be recorded **every time you play or test**, without pressing anything.
- Claude built a small helper (`tools/recorder/`). It starts when Windows starts and checks every 2 seconds whether the Dwarf Game window is open. When it is, OBS starts hidden in the tray and records **just the game window and the game's own sound**. When you close the game, it stops, saves the video and closes OBS.
- Videos go to **Videos → Dwarf Game Recordings**, named by date and time.
- Claude's robot test runs (autopilot) are skipped, so the folder only has *your* play sessions.
- It uses its own OBS setup called "Dwarf Game", so your normal OBS scenes stay the same.
- To switch it on or off, double-click `Turn On Auto-Recording.bat` or `Turn Off Auto-Recording.bat`.

**Hurdles / mistakes (including Claude's)**
- **Test 1:** OBS said "not ready yet" because it was still starting up. **Fix:** wait and ask again.
- **Test 2: OBS crashed.** Claude's script switched OBS to the Dwarf Game setup while OBS was still starting, and OBS can't handle that. The crash also left OBS set to the Dwarf Game setup instead of your own. **Fix:** Claude put your settings back from a backup it had made before testing. Now OBS *starts* in the Dwarf Game setup (no switching), and afterwards the script puts your normal setup back.
- **Test 3:** OBS said "OK, recording!" but it never really started. **Fix:** the script now checks that OBS is *really* recording, and tries again (up to 3 times) if not.
- **Claude's bug:** the "Turn Off" switch looked for the recorder by name and would have found *itself* too, so it could have stopped itself first. **Fix:** it skips itself. Tested on and off.
- Test 4 worked: a 1920×1080 video with the game in it.

**Small known limits**
- The first few seconds (while OBS starts, about 5–7 seconds) aren't recorded. That's mostly the cave loading.
- A thin strip of the window border shows at the top of the video.
- `main` has no game sounds yet, so the sound track is silent until we're on a branch with sounds.

---

## Day 3, later — November 14, 2026: Planning the new look (research only)

**What we did**
- The owner said the game looks "Roblox-y" and asked for a plan to make it feel more like Valheim, plus real animations (running, jumping, swinging).
- Claude studied our current look and did web research: how Valheim's style works, where to get free textures, models and animations, and which licences are safe.
- Wrote the plan: `docs/design/visuals-plan.md`. No game code changed.

**What we learned**
- Valheim's trick is "cheap stuff, expensive light": simple shapes and small rough textures, but fancy light, fog and shadows.
- Our toy look comes from: flat colors with no textures, a dwarf made of perfect balls and tubes, no walking animation, bright colors, and a cave that is lit everywhere.
- Best free source of animations: Quaternius (CC0), 250+ animations on one skeleton, made to work in Godot.

**Hurdles / mistakes**
- **Mixamo and Synty look tempting but are a trap for us:** our GitHub repo is public, so anything in it counts as "shared", and their licences don't allow sharing the raw files. Decision: CC0 only in the repo.
- Godot's automatic bounced light (SDFGI) is made for worlds that don't change. Ours changes with every dig, so the plan skips it.
- The PC only runs at ~50 FPS. Fancy light costs speed, so the plan fixes speed first (step V0).

---

## Day 3, later — November 14, 2026: Can AI make our 3D objects? (research only)

**What we did**
- The owner asked: can we ask ChatGPT for pictures of a thing (like a workbench) from all sides, and turn them into a real object in the game?
- Claude researched the tools and wrote `docs/design/ai-art-pipeline.md`. No game code changed.

**What we learned**
- Yes, it works, but ChatGPT only makes the *pictures*. A second tool ("image → 3D", like Meshy or Tripo) turns pictures into a 3D model. Then a cleanup step (a Blender script) makes the model small, matching our style, and the right size.
- Box-like things (workbench, chests, walls) come out better if Claude builds the simple shape and AI only paints the textures. AI 3D is best for lumpy natural things (mushrooms, crystals, rocks, monsters).
- Easiest AI win: inventory icons and textures (picture in, picture out).

**Hurdles / mistakes**
- Many "best AI 3D tool" articles are written by the tool makers themselves, so Claude treated their rankings as rough and used official pages for prices and licences where possible.
- Free plans are a trap for selling: Meshy free = must credit them, Tripo free = not for selling. Paid plans are fine.
- Hunyuan3D (a free tool) is not allowed in the EU, UK or South Korea, so we may not be able to use it.
- OpenAI's terms page blocked Claude's web reader, so the "we own the pictures" answer comes from summaries. The owner should read the terms once.
- Our graphics card (8 GB) is too small to run the best free tool (TRELLIS.2) comfortably.

### Later on Day 3: desktop icon + Claude looks at every play session

**What we did**
- **Desktop icons:** "Dwarf Game" starts the game straight away. "Dwarf Game Sessions" opens the folder of your play videos and reports.
- **Every play session now gets a report.** When you close the game:
  1. A box pops up: *"How was it?"* Type a few words, or press Skip.
  2. Its own folder gets made with the video, the game's log (its errors and warnings) and up to 60 snapshots.
  3. A Claude runs in the background, **read-only** (it can look but not change anything). It compares what you said with what it sees and writes `report.md`: bugs with proof, where in the code the cause probably is, and FPS.
  4. A little bubble near the clock says the report is ready.
- **Fixing rule (yours):** bugs you mentioned get fixed. Bugs Claude found that you didn't mention, it asks you about first.
- **Only your games count.** A game started from a script or terminal (that's how Claude runs it) is never recorded.
- **Test runs are muted now** (you asked). The rule is in `CLAUDE.md` for every Claude.

**Hurdles / mistakes (including Claude's)**
- **The feedback box was invisible.** The helper starts "hidden," and Windows makes a hidden program's first window hidden too. **Fix:** the script uses up that first "hide" on its own invisible console window, then shows the box. A screenshot proved it now appears.
- **The folder path got cut off** at the first space ("Videos\Dwarf"), because of quote marks in Claude's instructions. **Fix:** use single quotes.
- **The report had chatty text before the title.** **Fix:** the report must start with the title, and anything before it gets cut.
- **Claude's tool mistake:** Claude's command-line tool turned a `\a` in a Windows path into an invisible "beep" character, so the log path broke. It took 3 tries to notice. **Fix:** Claude edited it with PowerShell. Lesson: don't write Windows paths through that tool.
- **A tricky case found while testing:** another Claude was running the game at the same time. The recorder must never treat that as you playing. **Fix:** it checks *who* started the game. The desktop icon or the Godot editor means you; a script means a robot. Both were tested.
- The test report found two real things: the dwarf's own body blocks the lantern light (that's why it feels dim), and the dwarf can't step up small ledges. They're waiting for your OK.

### Later on Day 3: brighter lantern, stepping up ledges, better jump, and the feedback list

**What we did**
- **Lantern (F1):** it was dim because of 2 things blocking its own light: the dwarf's body *and* the lantern's little glass box (the light sits inside it). Now neither one blocks the lantern's light, and the light reaches a bit further. The screenshots show the tunnel walls lit up warm orange.
- **Ledges (F2):** the dwarf now steps up anything up to 50 cm by itself, like stairs. Taller walls still need a jump. The camera glides up smoothly, so stepping doesn't jolt.
- **Jump (F3):** Space already jumped, but on bumpy cave floors the game often wasn't sure the dwarf was standing, so jumps got "eaten." Now a jump still works a moment after you step off an edge, and when you press it just before landing. It's also a little higher, about 1.5 m.
- **5 new auto-checks** cover all three, in a simple test room: jump height, early jump press, stepping up a 35 cm ledge, *not* climbing a 1.2 m wall, and the lantern shadow rule. 42 checks in total, all passing.
- **`FEEDBACK.md`**, the master feedback list: everything you've said, with fixed items crossed out (never deleted), a count of how often you've said each one, and a "keeps coming back 🔁" section to catch fixes that didn't stick.
- **The feedback pop-up is off.** You give feedback in chat. The background Claude now also checks each session for open feedback items, and for fixed ones coming back.

**Hurdles / mistakes**
- All the new checks passed on the first try. That can mean a test doesn't really test anything, so Claude switched step-up off on purpose: the ledge test failed, as it should. Then Claude switched it back on.
- In the autopilot run, the robot still only walked 4.6 m. That's not a bug: it was standing in its own trench, which is deeper than a step, so it needs a jump.
- Two other Claudes were working at the same time. Claude checked with them first (they weren't touching the dwarf files), and saved only its own files.

### Later on Day 3: sound in Step 1

**What we did**
- You asked for the game to be muted only during Claude's tests, with sound when you play. That was already how it worked. The real reason you heard nothing: **Step 1 had no sounds at all.** They'd only been built on the Step 6 branch.
- Claude brought the sound helper and **11 sounds** (42 small files, free CC0 sounds by Kenney) over to Step 1: pickaxe swing, digging (soft for moss and dirt, hard for stone), rock breaking, a "clink" when rock is too hard, crystals breaking, footsteps (quicker when running), pickups, lantern refill, and opening and closing the bag.
- 2 new auto-checks: every sound loads, and every sound the code asks for really exists. 44 checks in total, all passing.
- Added Kenney's sound packs to `CREDITS.md`.

**Hurdles / mistakes**
- **The same backslash problem as before:** Claude's command-line tool ate the backslashes in a pattern in the new test, so the test didn't even load. **Fix:** Claude rewrote the pattern without backslashes, using the editor. Lesson (again): write code files with the editor, not through the command line.

---

## Day 3, later — November 14, 2026: Building the free "asset forge" (picture → 3D model)

**What we did**
- The owner wants free tools only. Claude set up a free pipeline on the gaming PC and tested it end to end:
  ChatGPT picture → 3D model → Blender cleanup → a `.glb` file Godot loads.
- Installed Blender 5.3 and TripoSR (a free AI that turns one picture into a 3D model in ~20 seconds on our graphics card).
  Connected to the free TRELLIS.2 website (better quality, but a small daily limit).
- Wrote `tools/asset_forge/forge.py` (one command does everything) and `blender_cleanup.py` (makes every model game-ready),
  plus a ChatGPT style prompt for our "between Valheim and Grounded" look in `tools/asset_forge/README.md`.
- Tested on a sample chair: picture → model in 22 seconds, 83,664 triangles cut to 2,500, right size, standing on the floor in Godot.

**Hurdles / mistakes (including Claude's)**
- **Only 40 GB free on C: at the start**, so the big local TRELLIS.2 install (~20 GB+, and too much for our 8 GB graphics card) was skipped; we use its free website instead.
- **TripoSR needed a compiler** for one part. Fix: swapped in a ready-made equivalent (scikit-image).
- **Old pinned versions** wouldn't install on our Python, and the newest `transformers` (v5) renamed its insides so TripoSR couldn't load its brain. Fix: unpinned, then `transformers<5`.
- **Two libraries fought** over a shared piece. Fix: two separate Python setups (one for TripoSR, one for the website).
- **Licence trap caught:** the background cutter (rembg) quietly switched its default to BRIA, which is *not* free for games we sell, and the TRELLIS website uses BRIA too. Fix: we force the free ISNet cutter and cut the background ourselves before sending anything.
- **Claude's bug 1:** the cleanup threw the whole model away as "crumbs", because model files store every triangle separately. Fix: weld matching corners first.
- **Claude's bug 2:** turning the model did nothing, because the importer stores turns in a different format ("quaternions"). Fix: turn the points directly. TripoSR models also come out lying on their back; the forge now stands them up automatically.
- **Claude's bug 3:** colors vanished in Godot (all white). Godot ignores "corner colors". Fix: bake them into a small 256-pixel texture, which suits our crunchy style anyway.
- **Website limit:** without an account the TRELLIS website gives only ~2 minutes a day; the shape got made but the download step ran out. A free Hugging Face account gives more.

**Known limits**
- TripoSR colors come out paler than the picture, and shapes are a bit soft. Fine for rocks/mushrooms; boxy things (workbench) are better built by Claude with AI textures.
- The test chair was deleted afterwards (it was TripoSR's example picture, not our art).

### Day 3, afternoon: everything merged into main (Claude 1)

**What we did**
- You played Step 1 and said the world felt empty, and listed a lot of things (F9–F17 in `FEEDBACK.md`). Many of them (crafting, enemies, ruins) were already built on the later branches, so you chose to **merge everything into main**.
- Claude merged all the steps plus the Fungal Jungle into main, in a separate copy of the folder (a "worktree"), so the other Claudes' work wasn't disturbed. Only 4 files clashed. Then today's lantern, ledge, jump and sound fixes were added back on top.
- **214 auto-checks pass**, and the autopilot played the whole game in one run: crafting, building a hut, fighting monsters, ruins, 4 bosses waking up, through the copper gate into the Jungle.
- The "no sound" you heard was because you were still playing the window opened *before* the sounds were added. Not a bug.

**Hurdles / mistakes (Claude's)**
- **Claude lost its own fixes during the merge.** It told git which version of `dwarf.gd` to keep, *then* re-added the ledge/jump/camera fixes, but never told git to save the file again. The tests passed because they read the unsaved file, so nobody noticed. Then Claude deleted that copy of the folder. git even warned "this folder has unsaved changes," and Claude forced it anyway. **Fix:** Claude noticed the warning right after, checked main (the fixes were missing), and redid them.
  **Lessons:** check that the saved version has the changes (`git show`), not just the files on disk. And a "you have unsaved changes" warning means stop and look, not force.
- Claude also saved before a test had finished. The test then "failed" only because Godot's list of code files was out of date after the merge (one import run fixed it). Nothing was broken, but saving should always wait for the tests.

---

## Day 3, later — November 14, 2026: Every item gets a picture (F17), plus the first AI workbench

**What we did**
- **Workbench test:** the owner made a workbench picture in ChatGPT; Claude turned it into a 3D model with TripoSR in 16 seconds.
  Result: right shape, but blobby and with wrong colors — "placeholder", not final art. Next: try the better TRELLIS.2 website (needs a free account) or build it in Blender.
- **Item icons:** Claude drove ChatGPT in the owner's Chrome and made **170 item pictures** in 12 picture sheets (16 per sheet, so the style matches).
  A script cuts each sheet into single pictures with see-through backgrounds: `assets/icons/<item id>.png`.
- Added `Items.icon(id)` so the game can find each item's picture (all runes of one colour share one picture), plus an auto-check (`tests/test_icons.gd`). Claude 1 hooks them into the bag/hotbar.

**Hurdles / mistakes (including Claude's)**
- **Pale colors on the AI workbench:** TripoSR stores colors in "screen" form but the file format expects "linear" form, so everything looked washed out. Fix: convert them back in the cleanup step.
- **The item list from Godot froze** (other Godot windows were open). Fix: read the list straight from the code files instead.
- **The ChatGPT page opened the old workbench chat** in the new tab. Fix: clicked "New chat" first; nothing was sent by mistake.
- **Waiting for pictures:** Claude's first "wait until done" timer ran out before the picture was ready. Fix: send, wait ~2 minutes, then check every sheet by looking at it before cutting.
- **Short descriptions help:** names like "Bloomheart Core" mean nothing to ChatGPT, so each item got a few words ("a large glowing boss heart-gem in stone").
- The new auto-check found one missing picture: the hand **Lantern** that Claude 1 had just added. Made it the same way.
