# Skills (owner, Nov 19, 2026)

Like Valheim: **you get better at what you do.** Hitting with a sword trains Sword, running trains Running.
This replaces the old 4 big skills (Mining, Fighting, Smithing, Survival) in `progression-and-economy.md` section 7.

## The skills (14 now, Swimming later)

| Group | Skills |
|---|---|
| Body | Running, Jumping (Swimming later, when there is water to swim in) |
| Work | Mining (digging caves), Woodcutting, Gathering (picking things up off the ground) |
| Making | Crafting, Cooking |
| Weapons | Sword, Axe (two-handed), Mace (one-handed), Warhammer (two-handed, "double hammer"), Spear, Shield, Crossbow |

Not skills (owner, Nov 19): Carrying, Sneaking.

## Levels 0–100 and how long they take

Hours of doing mostly that one thing (the XP curve is tuned to match):

| Levels | 0→10 | 10→20 | 20→30 | 30→40 | 40→50 | 50→60 | 60→70 | 70→80 | 80→90 | 90→100 | Total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Hours | 0.5 | 1 | 1.5 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | ~40 h |

## Bonuses

- **A tiny bit every level** (owner's pick). The "per 10 levels" column below is what 10 levels add up to
  (e.g. +2% per 10 = +0.2% per level).
- **A special perk at 25, 50, 75 and 100** (★). These come automatically from the skill level.

| Skill | Per 10 levels | ★ 25 | ★ 50 | ★ 75 | ★ 100 |
|---|---|---|---|---|---|
| Running | +2% run speed, −3% run stamina | Quick burst of speed when you start running | Rubble and slopes don't slow you | Running past enemies makes them miss more | **Second Wind:** at 0 stamina, get 25% back (every 2 min) |
| Jumping | +3% jump height, −3% jump stamina (fall damage: when it exists) | Jumping uses less stamina | Climb up ledges a bit higher | **Jump attack:** hits while in the air do +20% damage | No fall damage up to 8 m |
| Mining | +3% dig power, −2% swing stamina | Pickaxe swings 10% faster | +10% chance of double ore | Crystal spots give +1 crystal | **Lucky hit:** 1 in 10 hits digs twice as hard |
| Woodcutting | +3% chop power, −2% stamina | Axe swings 10% faster when chopping | +1 wood per Root Tree | Chopped roots grow back faster | 15% chance of double wood |
| Gathering | +3% chance of an extra item | Pick things up from a bit further away | Things on the ground glow from further away | Mushrooms and plants regrow faster near you | Rare finds turn up more often |
| Crafting | −3% craft time, better quality odds | Upgrades cost 10% less (repairs are free, F568) | Chance to save 1 material | Craft several at once with no extra wait | Best quality possible on anything |
| Cooking | −3% cook time, +2% food buff time | Cooking pots make 1 more dish at a time | Chance of a double dish | You can eat a 4th buff food | Your cooked food also heals a little |
| Sword | +2% damage, −2% attack stamina | Quick step forward on the first swing | Parry window 20% bigger | 3rd hit of a combo does extra damage | Perfect parry gives a free critical hit back |
| Axe (2-handed) | +2% damage, −2% stamina | Hits make enemies bleed a little | Hits 3 enemies instead of 2 | Heavy hits break enemy shields faster | Heavy sweep gives stamina back for each enemy hit |
| Mace | +2% damage, +3% armor piercing | Hits crack rock-shelled enemies faster | Stuns build up 15% faster | Hits on armored enemies make them stagger | Stunned enemies take extra damage |
| Warhammer | +2% damage, +3% stun | Heavy swings can't be interrupted | Ground slam reaches 25% wider | Slam breaks rock and digs a little | Ground slam knocks enemies down |
| Spear | +2% damage, +1.5% reach (2.6 m → 3.0 m) | A poke pushes enemies back | Thrust goes through 1 extra enemy | Throw your spear (pick it up again) | **Sweet spot:** hits at the very tip of your reach do +30% |
| Shield | +2% block strength, −2% block stamina | Walk faster while blocking | Shield bash stuns more | After a perfect parry, your next hit does +25% | +30% parry window; perfect parries give stamina |
| Crossbow | +2% damage, −3% reload time | Walk faster while aiming | Reload 15% faster | 30% chance the bolt comes back to you | Bolts ignore 30% of armor |

New things these need (not built yet): Axe bleeding (★25), Spear throw (★75), a 4th buff food slot (Cooking ★75).

## Fixed rules (owner, Nov 19)
- **Every tree always drops seeds** (for everyone, not a perk).
- **Food never spoils.**

## Built (Nov 19, Mac Claude) — `src/progress/progression.gd`
- All 14 skills, the ~40-hour curve (`XP_PER_HOUR` is a guess: measure with the robots, then retune), the skills
  window (K: level, bar, next ★ perk, hover for all four) and the top-3 skills on the HUD.
- XP: Mining (digging), Woodcutting (chopping roots, mushrooms, Root Trees), Gathering (picking up, farm harvest),
  Crafting (crafting, upgrades, building), Cooking (campfire, pot), each weapon by the weapon you hold (hits, kills,
  training dummy), Running (1 per 1.2 s), Jumping (3 per jump), Shield (4 per blocked hit). Running, jumping and
  blocks are counted on the player's computer and checked by the host (can't send more than the time allows).
- Tiny bonus every level: run speed and stamina, jump height and stamina, dig power, chop power, swing stamina,
  weapon damage, Gathering extra item, Cooking food time, Crafting quality.
- ★ perks working: Jumping 25, Mining 50 / 75 / 100, Woodcutting 50 / 100.
- Old saves: Fighting → Sword, Smithing → Crafting, Survival → Cooking + Gathering + Woodcutting.
- **Not built yet:** the other ★ perks and the per-level bonuses that need systems we don't have yet (armor piercing,
  spear reach, reload time, block strength, craft/cook time, parry window), and a "★ perk unlocked!" pop-up.

## Perk tree (owner, Nov 19) — built, `Progression.PERKS`
- Draft page to explore and edit: https://claude.ai/artifact/UTLcKhgPsVEZiubPB2dfWP
- **1 perk point per level.** 4 branches around the dwarf (names picked Nov 19): **Bones** (top, grey: toughness),
  **Fists** (right: fighting), **Hands** (bottom: mining, crafting, cooking), **Heart** (left: friends and support).
- Planned window layout (mock-up: https://claude.ai/artifact/MBTFW9LdXc4mA3jNNpvYWR): skills list on the left
  (click one to see its ★ perks, only one open at a time, never scrolls), the tree in the middle on the carved hall
  (the Level circle sits in the carved ring), perk details on the right. A perk opens once the one before it has a point.
- Mostly passive perks. **Active perks** (diamonds on the page) go on keys **Q / R / T** (you drag them there, owner
  Nov 27: see `abilities-quality-perks-plan.md`) and recharge: Stone Stance, Whirlwind, Rapid Volley, Quick Fix, War Horn, Healing Brew, Clan Banner.
- **Resetting perk points costs gold coins** (5 per level). Gold is found in old ruin chests; later monsters drop it too.
- Old saves: perks from the old 4 trees are dropped and their points come back.
- Rules: torches never go out. Total points to fill the tree: 90; max level 91 (owner, Nov 27), so the whole tree fills slowly.

### Waiting on systems we don't have yet
Deep Pockets (bag can't grow), Thrifty and Quick Fix (no tool wear / repairs), Chest Looter (chests are filled when
the world is made, not when opened), Grave Walker (no skill loss on death), Monster Lore (no kill counts),
Quick Helper and Stand Over (no "fallen friend" state), Lantern Bearer (only your own screen would see it).
Placeholders: Whirlwind/Healing Brew/Clan Banner have sounds only (no spin, throw or banner model); Healing Brew heals
around you instead of being thrown; Shoulder to Shoulder only helps the player who has it; the gold coin icon.

## ★ perks and skill bonuses built (Nov 20, Mac, overnight)
- **Per-level bonuses now working:** Sword/Axe attack stamina, Mace armor piercing, Warhammer stun, Spear reach,
  Shield block strength + block stamina, Crossbow reload, Crafting craft time, Cooking cook time.
- **★ perks now working:** Running 25 (burst), 75 (enemies miss 20% on the run), 100 (Second Wind) · Jumping 25, 75 (jump
  attack) · Mining 25, 50, 75, 100 · Woodcutting 25, 50, 75 (roots regrow 25% faster), 100 · Gathering 25 (pick up from
  further) · Crafting 25 (upgrades 10% cheaper), 50 (save a material), 75 (several at once, no extra wait) ·
  Cooking 25 (pot makes 1 more), 50 (double dish 10%), 100 (cooked food heals 10) · Sword 25 (quick step), 50, 75, 100 ·
  Axe 50 (3 targets), 100 (stamina back) · Mace 25, 50, 75, 100 · Warhammer 25 (heavy swings can't be knocked out of),
  50 (wider slam), 100 (slam stuns) · Spear 25 (poke pushes back), 50, 100 · Shield 25, 50, 75, 100 · Crossbow 25, 50,
  75 (30% the bolt comes back to your bag), 100.
- **Not built (needs a new system or the owner's call):** Running 50 (nothing slows you on rubble or slopes yet),
  Jumping 50 (no ledge climbing; ★100 no fall damage was built Nov 20), Gathering 50 (drops don't glow), 75 (mushrooms don't regrow)
  and 100 (no "rare finds" in gathering), Crafting 100 (no item quality yet), Cooking 75 (a 4th food clashes with the
  2 foods + 1 drink rule), Axe 25 (no bleeding) and 75 (enemies have no shields), Warhammer 75 (slam digging), Spear 75
  (no spear throw). Crafting 25 only shows on bigger upgrade costs (2 → 2 after rounding).

## Still to plan
- Decided Nov 27 (max level, ability keys, skill loss on death, the waiting perks): `abilities-quality-perks-plan.md`.
- Gold from monsters. Exact XP per action for each skill (measure with the robots).
