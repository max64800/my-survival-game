# Abilities, quality, levels and the waiting perks (owner, Nov 27, Mac planning chat)

Build list for the PC. Every choice below is the owner's. Do the steps in this order; each one is playable on its own.

## 1. Active abilities (the 7 diamond perks)
- **Keys Q / R / T** (were Z / G / T). `src/player/controls.gd` `ability_1..3`.
  - Q still rotates a building piece **while the build hammer is out**; otherwise Q = ability 1.
  - Q over a bag slot still drops the item (bag open = no ability).
  - **Lantern refill moves from R to L:** tap L = put away / take out (as now), hold L ~0.5 s = refill.
- **You choose:** in the perk window, drag an owned ability onto the Q / R / T boxes. Any time, anywhere.
  A swapped-in ability starts its full recharge (no swapping to skip waits). Saved per player.
  Replaces `Progression.ability_slots()` "first 3 in tree order" (keep that only as the default for old saves).
- **Still 3 keys, still the same 7 abilities** (owner: no new ones).
- **Make the 3 sound-only abilities real:**
  - **Whirlwind:** a real spin animation with the weapon in hand; hits everything around once.
  - **Healing Brew:** throw a small flask (arc like a crossbow bolt, short range); it splashes where it lands and
    heals everyone within 5 m of the splash (15 per rank). Needs a flask model + splash effect.
  - **Clan Banner:** plant a banner in the ground in front of you for 60 s; friends within 10 m **of the banner**
    resist poison / chill / burn by 50%. Needs a banner model (our style, MODEL-RULES.md). Host owns the banner.
- **Later, not now:** weapon special moves (spear throw, shield charge, hammer slam…) on their own key.

## 2. Levels and death
- **Max dwarf level 91** (was 30) = 90 perk points = the whole tree, slowly. `Progression.MAX_LEVEL`.
  Re-check the XP curve so level 91 is a long-term goal (measure with the robots, then tune).
- **Skill loss on death, like Valheim:** every skill loses 5% of its level (60 → 57). No loss again for 10 min after
  a death (show a small icon with the timer). **Grave Walker** (-25% loss per rank) now works.

## 3. Quality: grey → green → blue → purple → gold
| Colour | Name | Bonus (main stat AND durability) | Look |
|---|---|---|---|
| Grey | Plain | +0% | normal |
| Green | Fine | +4% | small mark on the handle |
| Blue | Sturdy | +8% | engraved lines |
| Purple | Superior | +13% | engraved + faint shine |
| Gold | Masterwork | +20% **and 1 extra gem socket** | glowing runes + crafter's name |

- Main stat = damage (weapons), armor (armor), dig / chop power (tools).
- **Crafting decides the starting colour, no luck:** Crafting 0-19 grey, 20-39 green, 40-59 blue, 60-79 purple,
  80+ gold. The crafter is whoever presses Craft (so a clan smith can make gold gear for friends).
  **Crafting ★100 (owner, Nov 27): crafted gear comes out already fully upgraded (+3).** The per-level
  "better quality odds" text in `Progression.SKILLS` changes to "closer to the next colour".
- **Reforging (the other way up, for non-crafters):** upgrade an item to **+3**, then at the Anvil use **boss trophies**
  to reforge it: it goes back to **+0 and one colour higher**. Cost: grey→green 1 trophy, green→blue 2,
  blue→purple 3, purple→gold 4 (10 for a full climb). Any boss trophy counts.
- **Boss trophies are new items:** every boss (the 5 dungeon bosses now, more later) drops 1 per nearby player.
  Bosses come back with the 1-hour dungeon refill, so trophies can be farmed.
- Gold always has the extra socket, whether crafted or reforged.
- Shows as a coloured name + slot border everywhere items appear, and engravings / shine / glow on the model.

## 4. The waiting perks
- **Already work now** (built since the list was made): Thrifty, Quick Fix (wear and repairs exist).
- **Just build, no new decision needed:** Deep Pockets (+2 bag slots per rank), Chest Looter (roll extra loot
  when the chest is opened), Monster Lore (count kills per kind), Lantern Bearer (friends see your bigger light),
  Gathering 50 (drops glow), Gathering 75 (picked mushrooms regrow), Axe 25 (new **bleeding** ailment in
  `src/survival/ailments.gd`), Warhammer 75 (the slam digs rock).
- **Fallen friend (co-op only):** at 0 health you fall and crawl for 30 s; a friend holds E for 4 s to pick you up at
  low health. Nobody comes = you die and wake at your bed. Solo = you die at once, as now.
  Makes Quick Helper, Stand Over and Bond of the Clan work.
- **Cooking 75 = a 3rd food slot** (owner: 3 foods + 1 drink for master cooks; everyone else 2 foods + 1 drink).
- **Gathering 100 = rare finds +50%.** The only rare find for now is the **geode** (owner picked geodes only):
  about 1 in 150 rock digs; crack it at the Mason's Table for crystals, sometimes a Rough gem (Deep Onyx,
  Wind Amethyst, Edge Quartz, Storm Topaz). Sparkle + chime + "Rare find: Geode!". Master of Stone: geodes 2x.
- **Stay waiting (owner):** Running 50 (rubble / slopes), Jumping 50 (ledge climbing), Axe 75 (enemy shields come
  later), Spear 75 (spear throw comes with weapon special moves).
