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

**The big picture: 4 "branches" (like parallel copies of the project)**

| Branch | What's in it | Status |
|---|---|---|
| `main` | **Step 1, First Tunnel** + all design docs | Ready to play-test |
| `step-2-friends` | Step 1 + **co-op** (play with friends) | Tested with two game windows |
| `step-3-survive` | Step 2 + **survival, crafting, skills, map** | Tested; needs play-testing |
| (more may follow) | | |

Why branches? Our rule says each step must be playable and approved before the next one. So `main` stays Step 1 until you've tried it. The later steps wait on their own branches, ready to merge when you say yes.

**What we did**
- Installed Godot 4.7.2 on the MacBook (in a temporary folder) so Claude could actually run the game, not just write it.
- **Step 1 (main):** random caves (2 big caverns, 7 small rooms, twisty tunnels), smooth digging, rock hardness (moss 1 hit, stone 3, copper 5), undiggable border rock, chunks that fly into your bag, 8-slot hotbar + 30-slot bag, a lantern you refill with glow crystals, glowing crystals and mushrooms, frame-rate counter, pause screen.
- **Checks:** a test robot (`tools/run_tests.sh` / `.bat`) runs auto-checks, plus an "autopilot" that plays the game by itself and takes screenshots. Claude looked at every screenshot.
- **Design docs** (`docs/design/`): combat & monsters, progression & economy, world & building. Then a review pass made all three agree. **26 open questions for you** are in `docs/design/README.md`. Each has a default (★); only answer the ones you want to change.
- **Steam check:** the Steam add-on and the digging add-on work together. (That was the biggest technical risk in our plan.)
- **Step 2 (branch `step-2-friends`):** co-op over IP address and Steam lobbies, a start menu, friends with names and shirt colors. Late joiners catch up on every hole already dug. The "netcheck" robot ran two game windows and checked both see the same cave.
- **Step 3 (branch `step-3-survive`):** health, stamina, hunger, thirst (never kills you), 3 food-buff slots, 16 dishes + 6 drinks, ~80 items, ~55 recipes, placeable stations (campfire, workbench, smelter, anvil…), hanging roots for wood, mushrooms, fiber, clay, levels + 4 skills + 43 perks (K screen), the Rune Slab rules, and a parchment map per floor (M screen).

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

**Not done yet / known limits**
- No art pack yet: the dwarf and stations are simple shapes. You pick the pack on the PC.
- No sounds yet.
- Steam lobbies are written but untested. They need Steam running and two accounts or PCs.
- Step 3: no monsters yet (so no death or graves), runes can't be found yet (they come with ruins in Step 6), and the map isn't shared between friends yet.

**Next (for you, on the gaming PC)**
1. `git pull --ff-only`, open in Godot, press F5. See `docs/GAMING-PC-START.md`.
2. Play Step 1 for 10 minutes and tell Claude how it feels.
3. If you like it: say "merge step 2" (and later "merge step 3").
4. Skim the 26 questions in `docs/design/README.md`.
