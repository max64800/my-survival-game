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
| `fungal-jungle` | + **the Fungal Jungle** (biome 2), poison/burn/chill, crystal monsters | Tested; **the newest everything** |

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
- Spore **clouds** that hang in the air, blinding, and the Gill Stalker's real hiding are simplified: a cloud is one big dose of poison on hit for now.
- Gems (and gem drops from crystal monsters), the crossbow and friendly fire still wait.
- The jungle's boss arena needs its "rooting" phase and spore sacs (Thallus fights with his normal attacks for now).
- Recipes for the new monster parts (needles, venom sacs, Sivix silk…) aren't designed yet; they're collectibles for now.

**Next (for you, on the gaming PC)**
1. `git pull --ff-only`, then `git switch fungal-jungle` for the newest everything (see `docs/GAMING-PC-START.md`).
2. To see the jungle quickly without beating Orrumhal: start a world, then look in the Mossy cave for the purple glowing arch (the gate). Or ask Claude for a "debug: give copper pickaxe" key.

