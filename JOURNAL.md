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
