# Progression, exploration and dungeon design for survival-crafting games

Research notes, 2026-11-22. Scope: how games guide players without holding their hand, how to pace progression, how dungeons are built, how many places to put in a world, and co-op design. The first hours and quit reasons are already covered in `docs/research/players-first-hours-and-why-they-quit.md`. I skimmed it and did not repeat it. It does not cover: guidance tools (landmarks, breadcrumbs), tier pacing after hour 2, loot tuning, dungeon layout, point-of-interest density, or progression in co-op.

**Words used here**
- **Weenie:** a big, easy-to-see landmark that pulls a player toward it (term from Sucker Punch).
- **Breadcrumb:** a small marker on the ground that leads from one place to the next.
- **Key-and-lock:** a dungeon where a found item (key) opens a door or path later in the same dungeon.
- **Loop / shortcut:** a route that brings the player back to a known spot, or a door that skips a long walk.
- **Pity timer:** a rule that makes a rare drop more likely the longer you go without it.

**How sure is this?** Most sources are game-press articles and fan guides. Several claims below come from search-result summaries that I could not open in full. Those are marked "(summary only)". The GDC talks I could find (Valheim 2024, Subnautica 2019, Breath of the Wild 2017) are listed with their GDC Vault links, but I could not read their contents (members-only pages or no transcript). Nothing here is a number I could not source; where I found no number, I say so in Gaps.

---

## Key Question 1: How do games guide players without hand-holding?

### Takeaway
Good games give the player one visible thing to walk toward (a tall landmark, a glowing marker, a raven hint) and then let them go. Guidance is spread out in the world instead of written in a quest list.

### Cited Findings
- Sucker Punch's landmark system ("weenies", GDC 2021 as cited by secondary coverage) splits landmarks into **Flags** (tall visual landmarks seen across the map) and **Breadcrumbs** (ground-level markers spaced so they can be found inside dense forest) — [Game Developer, "A taxonomy of weenies"](https://gamedeveloper.com/design/a-taxonomy-of-weenies-the-landmarks-that-define-i-ghost-of-tsushima-i-)
- Their density rule: the player should see something that draws them "every 30 seconds or less" while travelling. The player does not have to reach it in that window; they only have to see "something calling to them" — [same article](https://gamedeveloper.com/design/a-taxonomy-of-weenies-the-landmarks-that-define-i-ghost-of-tsushima-i-)
- Breath of the Wild's developers used the biggest triangle-shaped terrain pieces as "visual markers" to orient players, so players could navigate without a map tool — [Game Developer, "5 design lessons" from Breath of the Wild](https://gamedeveloper.com/design/5-design-lessons-learned-from-i-the-legend-of-zelda-breath-of-the-wild-i-)
- In the same article, towers were moved off straight routes "to pull players off the beaten path" — [same](https://gamedeveloper.com/design/5-design-lessons-learned-from-i-the-legend-of-zelda-breath-of-the-wild-i-)
- Subnautica (first game) did not use a quest list. The player was pointed at a beacon and left to work things out. Lead designer Anthony Gallegos called the first game a "masterclass" in player-driven discovery — [PC Gamer on Subnautica 2 designers](https://www.pcgamer.com/games/survival-crafting/subnautica-2-devs-say-its-an-exploration-game-first-expanding-on-the-first-games-masterclass-in-designing-player-driven-discovery/)
- Valheim: one talking raven gives sparse, occasional tips when you find a new landmark or material; achievements are hidden with the text "Only Odin knows what is hidden here" (summary only, from multiple guide sites in search results, e.g. [Twinfinite](https://twinfinite.net/pc/4-features-that-set-valheim-apart-from-other-survival-games/3/)). The raven is the main "guide" and it is deliberately not step-by-step.
- Valheim ties each boss to a material unlock: after you beat a boss, its trophy unlocks a power and the next material (e.g. iron after The Elder). One reviewer says this gives players a reason to explore and guidance for players who get overwhelmed — [Twinfinite](https://twinfinite.net/pc/4-features-that-set-valheim-apart-from-other-survival-games/3/); summon items per boss from [Windows Central boss guide](https://www.windowscentral.com/valheim-boss-guide-how-find-summon-and-defeat-every-boss)
- Dark Souls-style worlds teach the map through repeated routes, landmarks and shortcuts that open slowly, so the layout's logic emerges over time (commentary, summary only) — [Dark Souls design analysis](https://freedom251.com/dark-souls-level-design-how-tight-routes-create-constant-pressure/) (secondary; the Design Works interview is the primary source and was not read)
- Core Keeper guides say the game "never tells you where to go next", and that this is why many new players stall — [XGamingServer](https://xgamingserver.com/blog/?p=21852) (already in the existing research file)

### Inferences
- **For us:** A "weenie" plan fits underground. There is no sky to put a tower against, so use light and tall stone shapes instead. Two rules to test:
  1. From any spot in a cave zone, the player should be able to see something that draws them every ~30 seconds of walking.
  2. Breadcrumbs = wall markings and small glowing marks at each turn, so a player in a dark tunnel always has a next thing to find.
- **For us:** Wall markings that lead to the boss are a Breadcrumb system. Make the first marking appear before the player needs it (for example near the copper vein), not after they are already lost.
- **For us:** Valheim's "boss unlocks material" link is a good model for Orrumhal: beating it should unlock the next material the player is already short of (copper / the next zone's ore). That gives a reason to go, without a quest log.
- **Avoid:** A written quest list. The Subnautica and Core Keeper evidence points to a visible landmark plus freedom, not a checklist.

### Gaps
- No primary source for Valheim's raven design text. The raven details above are from guide summaries; the GDC 2024 Valheim talk ([GDC Vault](https://www.gdcvault.com/play/1034494/Independent-Games-Summit-Valheim-Vikings), members-only) could not be read.
- The Subnautica GDC 2019 talk "The Design of Subnautica" (Charlie Cleveland) exists ([GDC Vault](https://gdcvault.com/play/1026273/contactUs)) but I could not read its content. Its navigation details are not confirmed here.
- Breath of the Wild shrine/curiosity details: the GDC 2017 talk "Change and Constant: Breaking Conventions" exists ([GDC Vault](https://gdcvault.com/play/1024562/Change-and-Constant-Breaking-Conventions)); I could not read it. A single secondary source says orange highlights marked unsolved shrines and that almost nothing is required to progress ([Zelda Universe](https://zeldauniverse.net/features/ocarinas-image-freedom-in-breath-of-the-wild/)). Not confirmed against the talk.

---

## Key Question 2: How should progression be paced and gated (materials, tools, power curve)?

### Takeaway
Gate each new tier with one thing you must find or beat (a boss, a material, a tool). Valheim's order of biome, boss, material is the clearest public example. I found no sourced timing figures for how long each tier should last.

### Cited Findings
- Valheim's boss order (Eikthyr, The Elder, Bonemass, Moder, Yagluth, ...) is tied to biomes and materials. Summon items: Eikthyr = 2 deer trophies; The Elder = 3 Ancient Seeds; Bonemass = 10 Withered Bones; Moder = 3 Dragon Eggs; Yagluth = 5 Fuling Totems — [Windows Central](https://www.windowscentral.com/valheim-boss-guide-how-find-summon-and-defeat-every-boss); order also in [PC Gamer Valheim 1.0 progression guide](https://www.pcgamer.com/games/survival-crafting/valheim-biome-order/)
- Sources disagree about how far the progression goes past the current content (Mobalytics says the Deep North will be added after 1.0). Check the current patch before relying on exact requirements — [Mobalytics Valheim progression](https://mobalytics.gg/gamebase/guides/valheim-progression-guide-for-all-biomes)
- Core Keeper and Subnautica: the existing research file already notes "No tutorial" and early-stall complaints. This is about the first hours, so I did not repeat it.

### Inferences
- **For us:** Use the Valheim shape for the tier ladder: stone tools → bat-fang pickaxe → copper in far caverns → Orrumhal → next zone. Each step should unlock the next material, not only a stronger number.
- **Pacing check to test in play:** each tier should take roughly one play session. This is my own rule of thumb, not a sourced number. Mark it as a guess when the owner reads it.
- Keep tier gates to one clear "must" item each, so a player never has to guess which of several things blocks them.

### Gaps
- No sourced figures for how many hours each tier should last. The best-known guides list steps, not durations.
- No source on how big the power jump between tiers should be. Valheim's material ladder is the only concrete public example I found.

---

## Key Question 3: Loot economy and over-rewarding

### Takeaway
Keep the best items scarce by putting them in the hardest places, and use smart (not pure random) drop tables. Fully random drops feel bad; drops that are too easy spoil the reason to go deeper.

### Cited Findings
- Scarcity is usually set by an item's in-game value. More powerful items either appear later or drop with a much lower chance — [Game Developer, "Emotions and randomness in loot drops"](https://www.gamedeveloper.com/design/emotions-and-randomness-loot-drops) (summary only)
- The same source argues that designing only for the average player hides the experience of the rest — [same](https://www.gamedeveloper.com/design/emotions-and-randomness-loot-drops) (summary only)
- A Bunker Punks developer says pure random drops included gear the player already had or health when full. They added logic to the loot table. They also warn that if every drop is exactly what you need, the game becomes predictable — [Game Developer, Bunker Punks loot](https://gamedeveloper.com/design/making-loot-drops-more-engaging-in-bunker-punks) (summary only)
- Very low odds frustrate players, so designers often add pity rules or make rare items optional — [TV Tropes, "Rare Random Drop"](https://tvtropes.org/pmwiki/pmwiki.php/Main/RareDrop) (summary only; a wiki, weak source)
- Displayed drop chances can be misleading when loot is picked in two steps (a slot roll, then an item roll). Palworld's wiki gives a worked example: a 50% slot chance × 20% item chance = 10% real chance — [Palworld wiki, Treasure Chest](https://palworld.wiki.gg/wiki/Treasure_Chests) (game wiki, not a design source)

### Inferences
- **For us (chests):** Keep dungeon chests to ordinary materials and small gear. Put top gear and recipe pages in the large dungeons and in ruins, behind a key or boss.
- **For us (rarity):** Use logic in the drop table, not only chance. Example: a small dungeon never drops a tier item the player already has. Add a pity rule for the single item that blocks progress (for example a recipe page), so a player is never stuck for an hour.
- **For us (recipe pages):** Treat a recipe page as a key for a tier, not a random chest find. It is a clear "gate" item and players will know when they have it.
- Test the drop table with the owner's rule "too much loot": count the valuable items per dungeon and cut any dungeon that gives more than its share of the tier's gear.

### Gaps
- No source found on over-rewarding chests in a survival game specifically. The "too generous" side is not sourced.
- No source on how many chests a dungeon should have. This is a gap to fill by play testing.

---

## Key Question 4: Dungeon and level design (pacing, loops, keys, traps, sizes, reuse)

### Takeaway
A dungeon works best as a key-and-lock chain: each room teaches or uses one thing, one item opens the next part, and the player can see the way back. Make the layout readable first, big second.

### Cited Findings
- Mark Brown's "Boss Keys" series analyses Zelda dungeons through "keys, doors, and special items". Some Oracle dungeons "set up a clear and functional pattern of exploration that can be subverted, built on, and explored fully" — [Game Developer, "Take a close look at the level design of some exceptional Zelda games"](https://gamedeveloper.com/design/take-a-close-look-at-the-level-design-of-some-exceptional-i-zelda-i-games)
- Jabu Jabu's Belly is mapped by the order of obstacles (water level gating keys and objects), not by its physical rooms. It is "far easier for the player to navigate" than the Water Temple, which uses similar puzzles in a 3D space — [same](https://gamedeveloper.com/design/take-a-close-look-at-the-level-design-of-some-exceptional-i-zelda-i-games)
- The Boss Keys episode on the original NES Zelda argued that the small-key counts per dungeon were poorly balanced and that players often skipped required items (summary only) — [Zelda Dungeon](https://www.zeldadungeon.net/?p=27509)
- Breath of the Wild's developers moved towers off linear routes to make exploring optional and personal — [Game Developer, BotW lessons](https://gamedeveloper.com/design/5-design-lessons-learned-from-i-the-legend-of-zelda-breath-of-the-wild-i-)
- Dark Souls: each level has one main path with detours, secret areas and shortcuts (commentary; summary only) — [TheGamer, "Dark Souls 1 interconnected level design"](https://www.thegamer.com/dark-souls-1-fromsoftwares-magnum-opus-of-interconnected-level-design/). Miyazaki says he takes heavy involvement in stage and level design — [Game Informer 2024 interview](https://gameinformer.com/interview/2024/06/24/from-softwares-hidetaka-miyazaki-discusses-the-studios-approach-to-difficulty)
- Deep Rock Galactic mixes hand-made cave pieces with random ones so caves don't feel the same. This is carried over from the existing research file (Unreal Engine spotlight); I did not re-check it. A designer note says the most surprising results are "huge, 100 metre drops" where designed pieces join into caves nobody planned — [PCGamesN](https://www.pcgamesn.com/deep-rock-galactic/deep-rock-galactic-unreal-engine-4) (summary only)

### Inferences
- **Key-and-lock per dungeon:** one key item found in the dungeon opens the boss door (or the exit). Keep each dungeon's obstacles in a clear order, as Jabu Jabu does.
- **Loops and shortcuts:** each dungeon gets one loop back to the entrance and one shortcut that opens after the key. This lets the player leave and come back without a long walk, which is what the Dark Souls commentary describes.
- **Tension and release:** I did not find a sourced rule for this. My proposal: one quiet room (ore, a ruin, a recipe page) after every tense room. Mark as my suggestion.
- **Sizes (proposal, not sourced):**
  - Small: one room chain, one mechanic, no key item, cheap loot.
  - Medium: two mechanics, one key, one loop.
  - Large: all of the zone's mechanics, one key chain, one loop plus one shortcut, the best loot.
- **Reuse without repetition (for 12 dungeons per zone):** build the 3 sizes from a small kit of rooms, then change the order of obstacles and the placement of the key. This matches the Jabu Jabu lesson: the order matters more than the room shape.
- **Traps:** make each trap visible before it hurts (a changed colour, a sound). The Zelda analysis treats obstacles as readable teaching tools; I did not find a separate trap source.
- **Procedural vs hand-made:** the Deep Rock Galactic approach (hand-made pieces, random joins) fits our cave build. Keep dungeons hand-made in layout, with random decorations and loot.

### Gaps
- No source on procedural dungeon generation rules or on key-and-lock numbers. The size and loop proposals above are my own and need play testing.
- The Mark Brown Boss Keys video transcripts were not read. I only saw summaries of episodes. Use the videos directly before writing a rule from them.
- No source found on trap readability specifically.
- Deep Rock Galactic's GDC cave talk: I found no session. The Ghost Ship Games cave write-ups (2018 Unreal blog; 2024 Steam post "Below Decks") exist, but I could not open them.

---

## Key Question 5: Point-of-interest density and spacing; making underground places discoverable

### Takeaway
Put something interesting within sight about every 30 seconds of walking (Sucker Punch's rule), and avoid a place every few steps (Assassin's Creed Shadows aimed for no point of interest every 50 m, which shows the pushback against too much density). Underground, sight lines are short, so the rule should be "within the next turn".

### Cited Findings
- Sucker Punch: the 30-second rule and the "something calling to them" standard — [Game Developer, weenies](https://gamedeveloper.com/design/a-taxonomy-of-weenies-the-landmarks-that-define-i-ghost-of-tsushima-i-)
- Sucker Punch's stated design goal: "We wanted to create a game where players could get lost exploring Feudal Japan." — [same](https://gamedeveloper.com/design/a-taxonomy-of-weenies-the-landmarks-that-define-i-ghost-of-tsushima-i-)
- Ubisoft's open worlds drew criticism for density and icon-heavy maps; the developers of Assassin's Creed Shadows aimed for no point of interest every 50 metres (GamesRadar, summary) — [GamesRadar](https://www.gamesradar.com/games/assassin-s-creed/assassins-creed-shadows-forced-ubisoft-to-craft-the-crap-out-of-its-new-style-open-world-ensuring-you-wont-have-points-of-interest-every-50-meters)
- Ubisoft's tower-viewpoint approach was made popular by Far Cry 3 and later criticised for the same formula (PC Gamer / USgamer, summary only) — [USgamer](https://www.usgamer.net/articles/exploring-the-dreaded-ubisoft-tower?ref=dtf.ru)
- Obsidian's Outer Worlds 2 POI design session is listed on [gamedev.net](https://gamedev.net/news/5308-designing-pois-points-of-interest-for-the-outer-worlds-2-clip-1/); I did not read it.

### Inferences
- **For us:** Use Flags and Breadcrumbs in caves: a glowing crystal or tall column (Flag) you can see from the next cave room; a wall marking or small light (Breadcrumb) at every fork. This matches the owner's "world too small" complaint only if the places are spread out and reachable; density alone will not fix a small feel.
- **For us, world size:** A bigger feel comes from more loops, more forks and places seen from far, not from more empty rooms. Rule to test: no more than ~30 seconds of walking without something to look at.
- **Placement rule already in the project:** nothing the world grows may stand inside a built place or on its paths. The weenie/breadcrumb plan must keep to that rule (the project already has an automatic test for this).

### Gaps
- No Ubisoft GDC talk on POI density found. Figures above are from press coverage.
- No sourced numbers for dungeon or POI count per square metre in an underground world.
- Cameron Williams' GDC 2025 talk "Exploration by Design" was named in one secondary article as relevant to curiosity-driven open worlds. I did not confirm the talk or read it.

---

## Key Question 6: Co-op design (shared progression, roles, keeping 1–4 players engaged)

### Takeaway
Co-op works when each player's role matters and solo play still works. The public sources here are mostly from the existing research file (Deep Rock Galactic designer interview). I found no new sourced co-op progression rules this round.

### Cited Findings
- Deep Rock Galactic: co-op was the first design choice, and every player should feel equally important — carried over from the existing research file ([Co-Optimus interview](https://www.co-optimus.com/editorial/1978/page/1/indie-ana-co-op-and-the-deep-rock-galactic-interview.html)); not re-checked here
- Deep Rock Galactic's "Rock and Stone" button was made for players who do not use a microphone, and helped build a friendly community — carried over from the existing research file ([PC Gamer](https://www.pcgamer.com/meet-one-of-the-last-positive-communities-left-in-gaming))
- Grounded: opening hours alone felt like "a chore"; with friends it was much better — carried over from the existing research file ([VGChartz](https://www.vgchartz.com/article/455294/grounded-xs/))
- Deep Rock Galactic live-service: community events and timed rewards outside the paid economy kept regular play between updates — [Game Developer, live game article](https://www.gamedeveloper.com/marketing/developing-a-live-game-that-never-truly-left-early-access-with-deep-rock-galactic)

### Inferences
- **For us:** Keep each player's bed or spawn as the personal anchor (already done in the game). Shared goals (the boss, the zone gate) should not need everyone online at once to make progress; a solo player should still reach the next tier.
- **For us:** Give roles through the tools, not classes: one player can be the digger (fast ore), one the guard. The sources here don't prove this; it is an idea to test.
- Timed events between updates (the Deep Rock Galactic example) can refill interest without new content, but they are not a progression tool.

### Gaps
- No new source on co-op progression split (shared vs personal loot, role design) in this round.
- No sourced number on how many players a survival co-op keeps engaged past the first week.

---

## Summary of actions to test (for the report writer)
1. Landmarks: one visible draw every ~30 seconds of cave walking; wall markings and small lights as breadcrumbs. Test in the first zone.
2. Boss-to-material gate: Orrumhal unlocks the next material (Valheim model).
3. Loot: top gear and recipe pages only in large dungeons or ruins; logic in drop tables; pity rule on any single blocking item.
4. Dungeons: one key per dungeon, ordered obstacles, one loop plus one shortcut in large ones; build the 12 dungeons per zone from a small room kit.
5. Keep solo play working in co-op progression.

## Sources not read in full (to check before a final design rule)
- Valheim GDC 2024 talk (members-only): https://www.gdcvault.com/play/1034494/Independent-Games-Summit-Valheim-Vikings
- Subnautica GDC 2019 talk: https://gdcvault.com/play/1026273/contactUs
- Breath of the Wild GDC 2017 talk: https://gdcvault.com/play/1024562/Change-and-Constant-Breaking-Conventions
- Mark Brown Boss Keys episodes (videos; only summaries read)
- Deep Rock Galactic cave write-ups (Ghost Ship blog 2018; Steam post "Below Decks", 2024)
