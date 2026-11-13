# Combat and Monsters: Design Doc

*Written: November 14, 2026. Built in roadmap **Step 5 (Fight)** and **Step 6 (Deeper)**.*
*Builds on: `docs/superpowers/specs/2026-11-14-dwarf-survival-game-design.md` (sections 5.8, 5.9, 5.10). Those decisions are fixed. This doc only adds numbers and details.*

**Who this is for:**
- **The owner:** every rule is explained in plain words. Skim the tables and say what feels wrong.
- **A future Claude session:** every number here is a **starting value, tune in playtest**. Put all of them in data files (see section 10), never hard-coded in scripts.

**Words used in this doc (defined once):**

| Word | Simple meaning |
|---|---|
| **HP** | Health points. At 0 you (or the monster) go down. |
| **Tell** | The warning move a monster makes before it hits (raising its claw, a glow, a sound). "Tell time" = how long you have from the start of the warning until the hit lands. |
| **Parry** | Pressing block at the exact right moment. You take no damage and the attacker gets knocked off balance. |
| **Block** | Holding block early. You take less damage but pay stamina. |
| **Stun meter** | A hidden-then-shown bar on each enemy. Fill it up and the enemy is dazed for a few seconds. |
| **I-frames** | "Invincible frames": a short moment in a dodge-roll when nothing can hurt you. |
| **Armor** | A number that shrinks physical damage. More armor = less damage, but never zero. |
| **Buildup** | An invisible bar for fire, frost, or poison. Each elemental hit adds to it. When it fills to 100, the effect (burn, chill, poison) starts. |
| **Crushing attack (⛨)** | A very heavy hit. Only a **shield** can perfect-parry it. A weapon parry against it only counts as a block. |
| **Leash** | How far a monster will chase you before giving up and walking home. |
| **DPS** | Damage per second. Used only to compare weapons. |
| **Host** | The player whose PC runs the world in co-op. The host decides all damage (see "co-op ready" rule). |

---

## 1. Player base stats

The dwarf is short and tough. Base values below are before food buffs, skills, and runes.

### 1.1 Health and stamina

| Stat | Value | Notes |
|---|---|---|
| Max health | **100** | Buff food can add +20% (spec 5.4). |
| Health regen | **2 HP/s** | Starts after **6 s** without taking damage. |
| Health regen when hunger or thirst is 0 | **0.8 HP/s** | −60% (spec 5.4: "heal slower"). Same rule as progression doc 6.2. |
| Max stamina | **100** | Buff food can add +15%. |
| Stamina regen | **25 /s** | Starts **0.8 s** after you last spent stamina. |
| Stamina regen while holding block | **12 /s** | Half speed. |
| "Winded" (stamina hit 0) | Regen delay becomes **1.5 s** | You can still walk. Running, dodging, heavy attacks are locked until stamina is back to **20**. |
| Hunger/thirst at 0 | Stamina regen **×0.7**, max stamina **−20%** | Spec: "get tired." Same rule as progression doc 6.2. |
| Player armor | **0** at start | Armor pieces come from the crafting doc. The formula in section 2.2 works for them. |
| Player stun | Players have **no** stun meter | Instead: guard break (1.4) and knockdown (2.6). |

### 1.2 Stamina costs

| Action | Cost | Notes |
|---|---|---|
| Run (Shift) | **8 /s** | |
| Jump | **10** | |
| Dodge-roll | **20** | Needs the full 20 to start. |
| Light attack | per weapon (table 3.2) | If you have at least 1 stamina, the swing happens and stamina goes to 0. |
| Heavy attack | per weapon (table 3.2) | Needs the full cost to start. |
| Block a hit (shield) | **0.5 × the hit's damage before reduction** | Example: a 20-damage hit costs 10 stamina. |
| Block a hit (weapon, no shield) | **1.0 × the hit's damage before reduction** | Weapon blocks are worse. |
| Perfect parry | **0** | Parry is always the best move (spec 5.8). |
| Pressing block (nothing hits) | **0** | |
| Crossbow reload | **0** | |
| Mining swing (pickaxe or axe) | **5** | So mining also uses stamina (spec 5.4: "everything"). |

### 1.3 Dodge-roll

| Value | Number |
|---|---|
| Key | **Left Ctrl** + a direction (no direction = roll backward) |
| Distance | **3.0 m** |
| Total roll time | **0.45 s** |
| I-frames | From **0.05 s** to **0.30 s** into the roll (**250 ms** of safety) |
| Recovery after roll | **0.15 s** (can't attack or roll again) |
| Can cancel into roll from | The recovery part of any attack (not the wind-up) |

### 1.4 Guard break

If stamina hits **0** while you block a hit, your guard breaks: you stagger for **1.2 s** and can't block, attack, or roll. You take the rest of that hit's blocked damage as normal.

### 1.5 Controls (fight)

| Action | Input |
|---|---|
| Light attack | Left click (tap) |
| Heavy attack | Hold left click **0.3 s**, release |
| Block / parry | Right click (hold to block, tap at the right moment to parry) |
| Shield bash | Hold right click + left click |
| Dodge-roll | Left Ctrl + direction |
| Crossbow aim | Hold right click (crossbow has no block) |
| Crossbow reload | R (when holding the crossbow, R reloads instead of refilling the lantern) |

**Aim help:** attacks turn the dwarf up to **30°** toward the nearest enemy in front of you, within the weapon's reach + 1 m. No hard lock-on in this version.

---

## 2. Damage model

### 2.1 Damage types

| Type | Comes from | Good against |
|---|---|---|
| **Slash** | Sword, axe, two-handed axe | Soft, fleshy things (moss critters, fungus) |
| **Blunt** | Mace, two-handed mace, shield bash | Stone, shells, armor (golems, beetles) |
| **Pierce** | Spear, crossbow | Fast, thin things and weak spots (bugs, moths) |
| **Fire** | Ember gem, fire bolts, red crystal monsters | Fungus, frost things |
| **Frost** | Rime gem, frost bolts, blue crystal monsters | Fire things, fast things (slows them) |
| **Poison** | Blight gem, poison bolts, green crystal monsters, spores | Big HP things (damage over time) |

Each monster has a **type multiplier** for slash, blunt, and pierce (×0.5 to ×1.5) and a **resist %** for fire, frost, and poison. They are in the monster tables.

### 2.2 The damage formula

Physical damage (slash, blunt, pierce) goes through armor. Elemental damage skips armor and uses resist %.

```
physical = weapon_base × tier_mult × quality_mult × upgrade_mult × combo_mult × buff_mult
physical = physical × monster_type_mult            (slash/blunt/pierce weakness)
physical = physical × 100 / (100 + armor)          (armor; mace types ignore 30% of armor)
physical = physical × situation_mult               (stunned ×1.5, Crush ×2.0, sneak ×2.0, riposte ×1.3)
elemental = gem_or_bolt_elemental × (1 − resist%)  (resist capped at 75%; "immune" = 100%)
total = round(physical + elemental), minimum 1
friendly fire: total × 0.5
```

- **Armor rule in words:** 100 armor = half damage. 50 armor = two-thirds damage. It never reaches zero.
- Situation multipliers **don't stack with each other**: use the biggest one that applies.
- All rounding happens once, at the end.

**Worked example.** A Copper mace (Q1, no upgrades) does a heavy attack on a Cairnling (stone guardian).

| Step | Math | Result |
|---|---|---|
| Mace heavy base (Stone tier) | 25 | 25 |
| × Copper tier 1.30 | 25 × 1.30 | 32.5 |
| × Cairnling blunt weakness ×1.5 | 32.5 × 1.5 | 48.75 |
| Cairnling armor 40, mace ignores 30% → 28 | 48.75 × 100 / 128 | 38.1 |
| Not stunned, no gem | | **38 damage** |

Same hit with a sword (slash ×0.5, full 40 armor): 22 × 1.30 × 0.5 × 100/140 = **10 damage**. The mace is clearly the right tool. That's the point.

### 2.3 Critical hits

**No random critical hits.** Big damage comes from things you do on purpose:

| Situation | Multiplier | How |
|---|---|---|
| Sneak hit | **×2.0** | Hit an enemy that hasn't noticed you (state Idle or Wander). |
| Stunned enemy | **×1.5** | Any hit while its stun meter is full. |
| **Crush** | **×2.0** | The **first heavy attack** on a stunned enemy. (Replaces the ×1.5 for that hit.) |
| Riposte | **×1.3** | Your next attack within **1.0 s** after a perfect parry. |
| Weak spot | **×1.5** | Crossbow bolt to the head; boss weak spots listed per boss. |

### 2.4 Parry, block, and late block

The game checks when you pressed block compared to the moment the hit lands ("impact").

| You pressed block… | Result | Damage taken | Stamina | Enemy stun fill | Extra |
|---|---|---|---|---|---|
| Inside the **parry window** before impact | **Perfect parry** | **0** | 0 | Shield **40**, weapon **25**, crossbow stock **15** | Attacker staggers **0.6 s**. Your next attack gets Riposte ×1.3. Projectiles: shield reflects them back at full damage, weapon knocks them away. |
| Earlier than the window (already holding) | **Block** | Hit × (1 − block %) | 0.5× (shield) or 1.0× (weapon) of the hit | Shield **5**, weapon **0** | |
| After impact, or not at all | **Hit** | Full | 0 | 0 | |

**Parry windows (how early before impact the press may come):**

| Holding | Window | Block reduction |
|---|---|---|
| Shield (any tier) | **200 ms** | By tier: see 3.5 |
| Sword | **180 ms** | 35% |
| Axe, mace, spear (one-handed) | **150 ms** | 35% |
| Two-handed axe, two-handed mace | **150 ms** | 50% |
| Crossbow (stock parry) | **120 ms** | 20% |

- **Anti-spam rule:** after a tap of block, the parry window can't start again for **0.5 s**. Mashing block doesn't work; timing does.
- **Crushing attacks (⛨):** only a **shield** perfect parry counts. A weapon "parry" against them is treated as a block.
- **Area bursts (spore puffs, shockwaves):** they count as attacks too (spec: every attack can be parried). A perfect parry at the moment of the burst makes a gust that **pushes the cloud or wave away from you**. A block does nothing against clouds.
- **Readability help:** every enemy attack flashes a small gleam (weapon glint, eye glow) **250 ms** before impact. Attack sounds start at the beginning of the tell.

### 2.5 Stun meter (enemies)

| Rule | Value |
|---|---|
| Meter size | Per monster ("Stun max" in tables) |
| Shield perfect parry | **+40** |
| Weapon perfect parry | **+25** |
| Crossbow stock parry | **+15** |
| Shield block (not perfect) | **+5** |
| Your hits | The weapon's stun value (table 3.2) × tier stun multiplier (table 3.4) |
| Decay | **−8 per second**, starting **2.5 s** after the last fill |
| Stun duration | Regular monster **3.0 s**, side boss **4.0 s**, main boss **5.0 s** |
| Damage taken while stunned | **×1.5**; first heavy attack = **Crush ×2.0** |
| After stun | Meter resets to 0. Enemy can't gain stun for **2.0 s** (no stun-locking). |
| Bosses | Each time a boss is stunned, its stun max goes up **+30%** for the rest of the fight. |

### 2.6 Elemental effects (on monsters and on players)

| Effect | Buildup source | When buildup reaches 100 | Duration | Bosses |
|---|---|---|---|---|
| **Burn** (fire) | Per hit, listed on gem/bolt/monster | **5 damage/s**; stops health regen | **4 s** | Same |
| **Chill** (frost) | Per hit | Move and attack speed **−25%** | **4 s** | Same |
| **Frozen** (frost) | Getting chilled again while already chilled | Can't move or attack | **1.5 s** | Immune; they get Chill again (refresh) |
| **Poisoned** | Per hit / per second in a cloud | **3 damage/s**; stops health regen | **10 s** | Same |

- Buildup decays **−10 /s** after **3 s** with no new buildup.
- Effects refresh, they don't stack (poison stack: no).
- Fire removes Chill, and Chill removes Burn (they cancel).

### 2.7 Friendly fire

| Rule | Value |
|---|---|
| Default | **ON** (spec 5.8). Host can turn it off in world settings. |
| Damage to friends | **×0.5** of what it would do to a monster with 0 armor |
| Elemental buildup on friends | **×0.5** |
| Epic gem area effects on friends | **×0.25** |
| Stun, knockdown, stagger on friends | **None** |
| Crossbow bolts | Same ×0.5 (bolts hit the first body in line, friend or foe) |

### 2.8 Knockdown (players)

Some big monster attacks are marked **KD** (knockdown). If one hits you unblocked, you fall for **1.0 s** and then stand up with **0.5 s** of i-frames. A block or parry prevents knockdown.

---

## 3. Weapons

### 3.1 Roles at a glance

| Weapon | Hands | Damage type | Role (one line) | Can use shield? |
|---|---|---|---|---|
| Sword | 1 | Slash | All-rounder. Fast, safe, best weapon parry. | Yes |
| Shield | Off-hand | Blunt (bash) | Defense. Best parry, fills stun fastest. | — |
| Axe | 1 | Slash | Hits two enemies per swing. Good vs packs. | Yes |
| Mace | 1 | Blunt | Breaks armor and stuns. Good vs stone and shells. | Yes |
| Two-handed axe | 2 | Slash | Wide sweeps. Clears crowds, slow. | No |
| Two-handed mace | 2 | Blunt | Biggest stun. Ground slam. Slowest. | No |
| Spear | 1 | Pierce | Longest reach. Pokes through lines of bugs. | Yes |
| Crossbow | 2 | Pierce | Ranged. Strong shots, slow reload. | No |

### 3.2 Base numbers (Stone tier, Q1, no upgrades)

"Speed" = seconds from click until you can act again (wind-up + swing + recovery). Hits land at **40%** of that time.

| Weapon | Light dmg | Heavy dmg | Light speed (s) | Heavy speed (s) | Reach (m) | Light stamina | Heavy stamina | Light stun | Heavy stun |
|---|---|---|---|---|---|---|---|---|---|
| Sword | 10 | 22 | 0.55 | 1.10 | 1.8 | 8 | 18 | 6 | 18 |
| Shield bash | 5 | 12 | 0.60 | 1.00 | 1.4 | 6 | 16 | 10 | 30 |
| Axe | 12 | 26 | 0.70 | 1.30 | 1.7 | 10 | 20 | 8 | 22 |
| Mace | 11 | 25 | 0.75 | 1.35 | 1.6 | 10 | 20 | 12 | 35 |
| Two-handed axe | 22 | 48 | 1.10 | 1.90 | 2.2 | 16 | 32 | 14 | 40 |
| Two-handed mace | 24 | 52 | 1.20 | 2.10 | 2.0 | 18 | 36 | 22 | 60 |
| Spear | 11 | 24 | 0.60 | 1.20 | 2.6 | 9 | 18 | 6 | 16 |
| Crossbow | 24 (hip shot) | 34 (aimed shot) | 0.30 + reload | 0.40 aim + reload | 40 (range) | 4 | 4 | 15 | 20 |

Rough DPS check (light chain, Stone): sword 18, axe 17 (×2 targets), mace 15 (+armor break), 2H axe 20 (many targets), 2H mace 20, spear 18, crossbow 10 (but safe at range). They feel different without one being "best."

### 3.3 Combos and special traits

**Combo rule:** the next input must come within **0.5 s** after the current attack's recovery starts. A combo resets after its finisher or after 0.5 s with no input. Multipliers apply to that hit's own base (light base for L, heavy base for H).

| Weapon | Combo chain | Multipliers | Special trait |
|---|---|---|---|
| Sword | L-L-L | 1.0 / 1.0 / 1.25 (3rd is a thrust) | Best weapon parry window (**180 ms**). |
| | L-L-H "**Whirl**" | 1.0 / 1.0 / **H×1.3**, hits all around you (360°, 2 m) | |
| Shield | Block + L "**Bash**" | Bash light | After a perfect parry, Bash becomes "**Counter Bash**": ×2.0 damage and **+20** extra stun. |
| Axe | L-L-L | 1.0 / 1.1 / 1.3 | **Cleave:** each swing also hits a 2nd enemy within reach for **60%**. Chops wood **+50%** faster. |
| | L-H "**Hook**" | 1.0 / **H×1.25**, 2nd target takes 100% | |
| Mace | L-L | 1.0 / 1.2 | **Armor break:** ignores **30%** of armor. Stun values already high. |
| | L-L-H "**Bell-Ringer**" | 1.0 / 1.2 / **H×1.4**, this hit's stun **×2** | |
| Two-handed axe | L-L | 1.0 / 1.15, each a 160° sweep | **Sweep:** every swing hits **all** enemies in a 160° arc. |
| | L-L-H "**Reaper**" | 1.0 / 1.15 / **two spins, H×1.0 each** | |
| Two-handed mace | L-L | 1.0 / 1.2 | **Armor break 30%.** Heavy is a ground slam: **2.5 m** circle, knocks down Small/Tiny monsters for 1.0 s. |
| | L-H "**Groundbreaker**" | 1.0 / **H×1.5**, slam circle **3.5 m** | |
| Spear | L-L-L-L | 1.0 / 1.0 / 1.1 / 1.3 | **Pierce line:** pokes go through up to **2** enemies in a line. |
| | L-L-H "**Skewer**" | 1.0 / 1.0 / **H×1.4**, dash forward **3 m**, hits everything in line | **Brace:** hitting a monster **during its charge** = ×1.5 damage and **+20** stun. |
| Crossbow | No combo | Hip shot has **3°** spread. Aimed shot has none and zooms in. | **Weak spot:** head hits ×1.5. One bolt loaded at a time. |

### 3.4 Tier scaling (multiplier table)

Base numbers in 3.2 are Stone. Multiply for other tiers. Speed, reach, and stamina costs **do not change** with tier.

| Tier | Damage × | Stun × | Shield block reduction | Crossbow reload (s) | Gem sockets (fixed by spec) |
|---|---|---|---|---|---|
| Stone | 1.00 | 1.00 | 50% | 2.2 | 0 |
| Copper | 1.30 | 1.10 | 60% | 2.0 | 1 |
| Silver | 1.65 | 1.20 | 70% | 1.8 | 1 |
| Iron | 2.05 | 1.30 | 80% | 1.6 | 2 |
| Steel | 2.50 | 1.40 | 85% | 1.4 | 2 + 1 epic |

**Example:** Silver sword light = 10 × 1.65 = **16.5 → 17** (rounding happens at the end of the full formula).

**Quality (Q1–Q5, from the Smithing skill):** damage **+0% / +4% / +8% / +13% / +20%** (the same table as tools, progression doc 3.4). On shields: block reduction **+0 / +1 / +2 / +3 / +4** points.

**Anvil upgrades (+1 to +3 per item, progression doc 3.3):** damage **+8% / +16% / +25%** in total (shields: **+2 points** block reduction per level). Block reduction caps at **90%**.

**Hand lantern rule:** while you still carry the **hand lantern**, your off-hand is busy: no shield, no two-handed weapons, no crossbow. The **back lantern** (progression doc 5.4, about 2.5 hours in) frees both hands.

### 3.5 Shield details

| Value | Number |
|---|---|
| Block arc | **120°** in front of you. Hits from behind are not blocked. |
| Block reduction | By tier (table 3.4) |
| Block stamina | 0.5 × the hit's damage before reduction |
| Parry window | **200 ms** |
| Parry stun fill | **40** (weapon parry is 25). This is the "shield parry fills it a lot" rule from the spec. |
| Only shields can perfect-parry | Crushing attacks (⛨); reflecting projectiles back |
| Move speed while blocking | **−40%** |

### 3.6 Crossbow details

| Value | Number |
|---|---|
| Range | Full damage to **40 m**, then bolt drops and fades by **60 m** |
| Bolt speed | **55 m/s**, small drop (gravity × 0.3) |
| Reload | By tier (table 3.4). Moving at walk speed is allowed; running cancels the reload. |
| Bolts per craft | 10 (bolts stack to 100 like other items) |
| Bolt pickup | **50%** chance a bolt that hit something can be picked back up |

**Bolt types:**

| Bolt | Damage × | Type | Extra | Craft from (starting idea) |
|---|---|---|---|---|
| Stone-tip bolt | ×1.0 | Pierce | — | Wood + stone |
| Metal-tip bolt | ×1.2 | Pierce | — | Wood + any metal ingot of your crossbow's tier |
| Thumper bolt | ×1.1 | **Blunt** | +35 stun, ignores 30% armor | Wood + stone + rope |
| Ember bolt | ×0.9 | Pierce | +8 fire damage, +40 burn buildup | Metal-tip + red crystal |
| Rime bolt | ×0.9 | Pierce | +8 frost damage, +40 chill buildup | Metal-tip + blue crystal |
| Blight bolt | ×0.9 | Pierce | +6 poison damage, +50 poison buildup | Metal-tip + green crystal or venom sac |
| Glow bolt | ×0.5 | Pierce | Sticks where it lands and lights a **6 m** circle for **60 s** | Wood + glow crystal |

---

## 4. Gems

**Words:** gems go into **weapons and tools** (spec 5.9). Runes are for the skill slab; crystals are lantern fuel and crafting.

### 4.1 Socket counts (fixed by spec)

| Tier | Normal sockets | Epic sockets |
|---|---|---|
| Stone | 0 | 0 |
| Copper | 1 | 0 |
| Silver | 1 | 0 |
| Iron | 2 | 0 |
| Steel | 2 | 1 |

### 4.2 Normal gems

Values are per gem. Elemental damage is flat (it does not grow with tier, so it matters most early and stays useful later).

| Gem | Color | Effect in a weapon | Effect in a shield | Effect in a pickaxe | Where it drops |
|---|---|---|---|---|---|
| **Ember Gem** | Red | +5 fire damage per hit, +25 burn buildup | Perfect parries set the attacker's burn buildup +50 | Mined ore drops warm (smelts 20% faster) | Red crystal monsters (15%), ruin chests in Mossy (3%) |
| **Rime Gem** | Blue | +5 frost damage per hit, +25 chill buildup | Perfect parries add +50 chill buildup | — (no effect) | Blue crystal monsters (15%), stream caves |
| **Blight Gem** | Green | +3 poison damage per hit, +30 poison buildup | Blocking adds +20 poison buildup to the attacker | — | Green crystal monsters (15%), Wheezecaps (2%), Sivix, Mother of Needles (100%) |
| **Leech Gem** | Dark red | Heal **5%** of physical damage you deal | Heal **4 HP** per perfect parry | — | Rustwights (3%), Thane chest, Fungal Jungle ruin chests (4%) |
| **Jolt Gem** | Yellow | Your hits fill stun **+30%** | Your parries fill stun **+30%** | — | Cairnlings (4%), Rusted Thane (50%) |
| **Swift Gem** | Violet | Attack stamina cost **−15%** | Block stamina cost **−20%** | Mining stamina cost −25% | Violet crystal monsters (15%) |
| **Bulwark Gem** | Amber | Take **10%** less damage while attacking (during swing) | Block reduction **+8 points** (cap 90%) | — | Amber crystal monsters (15%), Old Ironshell (50%) |
| **Keen Gem** | White | Physical damage **+8%** | Bash damage +25% | — | Ruin chests (both biomes, 3%), Gill Stalkers (3%) |
| **Burrow Gem** | Brown | — | — | Dig speed **+20%**, 10% chance of 1 extra ore | Copper and silver ore veins (0.5% per ore block mined) |

### 4.3 Epic gems

Only fit the Steel **epic socket**. The first two are the owner's examples.

| Epic gem | Effect | Numbers | Where it drops |
|---|---|---|---|
| **Cinder Wake** | While you run, you leave a fire trail. Enemies chasing you walk through it and burn. | Trail lasts **4 s**, **0.8 m** wide. **8 fire damage/s** + **30 burn buildup/s** to enemies standing in it. Friends take ×0.25. | Main boss Orrumhal (Mossy): first-kill choice |
| **Hoarfrost Pulse** | Every 5th hit you land makes a small frost blast around you. | **3 m** circle, **20 frost damage**, **+60 chill buildup**. Counter resets if you don't hit for 5 s. | Main boss Orrumhal: first-kill choice |
| **Echoing Guard** | Each perfect parry sends out a shockwave. | **4 m** circle, **15 blunt damage**, **+20 stun** to every enemy in it. | Main boss Thallus (Fungal): first-kill choice |
| **Rootbound Heart** | When you drop below 25% health, you dig in. | **30%** less damage taken and **+3 HP/s** for **6 s**. Cooldown **90 s**. | Main boss Thallus: first-kill choice |
| **Bloomrot** | Enemies that die while poisoned burst into a poison cloud. | **3 m** cloud, **6 poison damage/s** + **40 buildup/s**, lasts **5 s**. | Fungal side bosses (5% each kill) |
| **Shiftstep** | Your dodge-roll becomes a short blink (teleport) that passes through enemies. | Blink **5 m**, i-frames for the whole **0.3 s**. Costs **+10** stamina (30 total). | Violet crystal monsters in Fungal Jungle (0.5%) |

Epic gems from the first two biomes drop **long before** you have Steel. That's on purpose: you carry the prize and look forward to it.

### 4.4 Socketing rules

| Rule | Value |
|---|---|
| Where | At a **Gem Bench** (crafted near the Anvil; recipe in progression doc 4.1) |
| Socketing cost | **Free** |
| Removing a gem | Gem comes back **intact**. Costs **5 blue glow crystals** (`crystal_blue`). |
| Same gem twice in one item | The 2nd copy works at **50%** strength |
| Two different elements in one item | Both work |
| Epic gem in a normal socket | Not allowed (and normal gem in an epic socket: not allowed) |
| Crossbow gems | Apply to every bolt you shoot, on top of bolt effects |
| Upgrading an item to a new tier | It's a new item. Move gems over at the Gem Bench (removal cost still applies) |
| Co-op | Gems are personal items. Dropped gems are first come, first served |

---

## 5. Monsters

### 5.1 Shared rules for all monsters

**Sizes (which tunnels they fit in).** The dwarf is **1.35 m** tall and **0.7 m** wide. One pickaxe dig scoops out a ball **2.7 m** across (Step 1 code: radius 1.35 m), so a hand-dug tunnel is about **2–2.5 m** high.

| Size | Needs an opening at least | Meaning for the player |
|---|---|---|
| Tiny | 0.6 m | Goes anywhere, even cracks you can't use |
| Small | 1.2 m | Follows you through any tunnel you dig |
| Medium | 2.0 m | Follows you through most dug tunnels |
| Large | 3.0 m | Can't follow into a dug tunnel. Only big tunnels and caverns |
| Huge | 5.0 m | Boss lairs and caverns only |

- **Monsters never dig** in this version. Digging a tunnel is a real escape from Large and Huge monsters. That's part of being a dwarf.
- If a monster can't reach you for **10 s**, it gives up and goes home (leash). Ranged monsters keep shooting while they can see you.

**AI states (every monster uses these; tables only list what is special):**

| State | What it does | Goes to next |
|---|---|---|
| Idle | Stands, sniffs, eats moss | Wander after 3–8 s (random) |
| Wander | Walks around within **15 m** of its home spot | Alert if it notices you |
| Alert | Turns to the noise or light, makes a sound for **0.8 s** | Chase |
| Chase | Runs toward you | Attack when in reach |
| Attack | Plays one attack (tell → hit → recovery) | Chase or Attack |
| Recover | Short pause after an attack (punish window) | Chase |
| Stunned | Dazed (section 2.5) | Chase |
| Return | Walks home, heals **10% max HP/s** | Idle. Happens when 40 m from home or can't reach you for 10 s |

**Noticing you:** sight **15 m** inside your lantern light (**8 m** if your lantern is empty), hearing: running **12 m**, walking **6 m**, digging **20 m**, fighting **20 m**.

**How each attack can be parried** (column "Parry"):
- **Any** = any weapon or shield.
- **⛨ Shield** = crushing: only a shield perfect parry works.
- **Reflect** = projectile: shield reflects it back, weapon knocks it away.
- **Gust** = area burst: perfect parry at the burst pushes it away.

### 5.2 Mossy Hollows monsters (start biome)

Player is expected to have **Stone → Copper** gear here. Hits are small. Monsters teach parrying.

**Stats:**

| Monster | Look (one line) | Size | HP | Armor | Stun max | Slash / Blunt / Pierce | Fire / Frost / Poison resist | Pack size | XP |
|---|---|---|---|---|---|---|---|---|---|
| **Mossnipper** | Fist-sized crab with a moss back and one oversized claw | Small | 30 | 0 | 30 | ×1.25 / ×1.0 / ×1.0 | 0 / 0 / 0 | 3–5 (start 4) | 5 |
| **Skitterling** | Quick six-legged cave lizard with pale glowing spots | Small | 40 | 0 | 35 | ×1.0 / ×1.0 / ×1.25 | 0 / 0 / 0 | 2–4 (start 3) | 7 |
| **Wickwing** | Moth the size of a hat, drawn to your lantern, glittery dust | Tiny | 25 | 0 | 20 | ×1.0 / ×0.75 / ×1.5 | −50% / 0 / 0 | 1–3 (start 2) | 5 |
| **Bogbelly** | Round stream toad with a sticky tongue and a big throat sac | Medium | 70 | 5 | 60 | ×1.0 / ×1.25 / ×1.0 | 0 / −25% / 25% | Alone | 12 |
| **Rustwight** | Rusty dwarf armor held together by moss, eyes of blue mushroom light | Small | 90 | 25 | 80 | ×0.75 / ×1.5 / ×0.75 | 25% / 0 / 100% (immune) | 1–2 | 20 |
| **Cairnling** | Squat stone guardian from the old ruins, runes glowing on its chest | Medium | 120 | 40 | 120 | ×0.5 / ×1.5 / ×0.75 | 50% / 50% / 100% (immune) | Alone | 30 |

Negative resist = weakness (takes more). Example: Wickwing −50% fire takes 1.5× fire damage.

**Attacks** (tell = seconds from start of warning to impact):

| Monster | Attack | Tell (s) | Damage | Parry | Notes |
|---|---|---|---|---|---|
| Mossnipper | Claw Pinch | 0.5 | 6 slash | Any | Raises big claw, it clicks |
| Mossnipper | Scuttle Snap (from the side) | 0.6 | 8 slash | Any | Circles to your side first |
| Skitterling | Bite | 0.4 | 8 pierce | Any | Fastest tell in the biome: the parry teacher |
| Skitterling | Pounce | 0.7 | 12 pierce | Any | Leaps from 4 m. Spear Brace works. |
| Wickwing | Dive | 0.6 | 7 pierce | Any | Hovers, then dives at the lantern |
| Wickwing | Dust Flutter | 0.8 | 0 | Gust | Blinds: your screen dims 50% for 3 s |
| Bogbelly | Tongue Lash | 0.7 | 10 blunt | Any | Reach 5 m. Pulls you 2 m toward it. |
| Bogbelly | Water Glob | 0.9 | 10 blunt | Reflect | Lobbed projectile, range 15 m |
| Bogbelly | Belly Flop | 1.1 | 16 blunt, KD | ⛨ Shield | Jumps onto you, 2 m circle |
| Rustwight | Rusty Chop | 0.7 | 14 slash | Any | Old dwarf axe swing |
| Rustwight | Two-Step (combo) | 0.6 then 0.4 | 10 + 12 slash | Any | Two hits, parry both |
| Rustwight | Shield Shove | 0.8 | 8 blunt | Any | Pushes you 1.5 m |
| Cairnling | Stone Fist | 0.9 | 18 blunt | Any | |
| Cairnling | Ruin Slam | 1.2 | 24 blunt, KD | ⛨ Shield | 2.5 m circle |
| Cairnling | Rune Flare | 1.0 | 12 fire | Gust | Chest runes glow orange first. Cone 4 m |

**Behavior and where they live:**

| Monster | Special behavior | Lives in | Drops (count, chance) |
|---|---|---|---|
| Mossnipper | Surrounds you: pack members spread out and attack from different sides | Moss floors everywhere | Nipper meat ×1 (80%), Moss chitin ×2 (60%) |
| Skitterling | Hit-and-run: attacks, backs off 3 m, attacks again | Narrow tunnels, walls (can climb walls, not ceilings) | Skitter hide ×1 (70%), Raw lizard meat ×1 (50%) |
| Wickwing | Attracted to lantern light from **25 m**. Ignores you if your lantern is empty. | Glow-mushroom groves | Glitter dust ×2 (70%), Wickwing wing ×1 (30%) |
| Bogbelly | Stays within 10 m of water. Retreats into water to heal 5 HP/s if under 30% HP | Streams and pools | Toad leg ×2 (90%, food), Throat sac ×1 (40%, waterskin upgrade) |
| Rustwight | Starts "asleep" as an armor pile. Wakes if you come within **4 m** or touch ruin loot. | Old dwarf ruins | Rusty scrap ×3 (80%, smelts to copper), Old rune ×1 (2%), Leech Gem (3%) |
| Cairnling | Slow (walk 2 m/s). Never leaves its ruin room. Doesn't chase past its doorway. | Ruin halls, guarding chests | Cut stone ×6 (100%), Rune shard ×1 (25%), Jolt Gem (4%) |

**Speeds (all Mossy monsters, m/s walk / run):** Mossnipper 2/5, Skitterling 3/7, Wickwing fly 6, Bogbelly 1.5/4 (hops), Rustwight 2/4.5, Cairnling 2/2. **Player:** walk 4.0, run 6.5 (same as Step 1 code).

### 5.3 Fungal Jungle monsters (biome 2)

Player arrives with **Copper** and moves to **Silver** gear. Hits hurt more. Spores and bugs in groups.

**Stats:**

| Monster | Look (one line) | Size | HP | Armor | Stun max | Slash / Blunt / Pierce | Fire / Frost / Poison resist | Pack size | XP |
|---|---|---|---|---|---|---|---|---|---|
| **Wheezecap** | Knee-high walking mushroom with a puffy cap that wheezes | Small | 80 | 0 | 50 | ×1.5 / ×1.0 / ×0.75 | −50% / 0 / 100% (immune) | 2–4 (start 3) | 15 |
| **Needlemite** | Dog-sized mite, glassy legs, long needle mouth | Small | 45 | 10 | 40 | ×1.0 / ×1.0 / ×1.5 | 0 / −25% / 50% | 4–7 (start 5) | 10 |
| **Husk Charger** | Horned beetle as big as a cart, shell like dark bronze | Large | 210 | 40 (front), 0 (back) | 160 | ×0.5 / ×1.5 / ×1.0 | 0 / 0 / 25% | Alone or 2 | 50 |
| **Gill Stalker** | Tall thin mantis-bug that hides under mushroom caps, scythe arms | Medium | 150 | 10 | 90 | ×1.0 / ×1.0 / ×1.25 | −25% / 0 / 50% | Alone | 40 |
| **Cap Spitter** | Rooted mushroom with a mouth-like gill that lobs spore bombs | Medium | 110 | 0 | 70 | ×1.5 / ×0.75 / ×0.5 | −50% / 0 / 100% (immune) | 1–3 (start 2) | 25 |

**Attacks:**

| Monster | Attack | Tell (s) | Damage | Parry | Notes |
|---|---|---|---|---|---|
| Wheezecap | Cap Butt | 0.6 | 12 blunt | Any | Headbutt |
| Wheezecap | Spore Puff | 1.0 | 0 + cloud | Gust | Cap swells. Cloud **3 m**, lasts **5 s**, **+25 poison buildup/s** |
| Wheezecap | Death Burst (on death) | 0.8 | Cloud as above | Gust | Shakes before popping. Fire kill = no cloud. |
| Needlemite | Needle Jab | 0.5 | 9 pierce + 20 poison buildup | Any | |
| Needlemite | Leap Bite | 0.7 | 14 pierce | Any | From 5 m. Spear Brace works. |
| Husk Charger | Horn Gore | 0.9 | 22 pierce | Any | |
| Husk Charger | Charge | 1.3 | 30 blunt, KD | ⛨ Shield | Scrapes foot 3 times. Runs **15 m** in a line. If it hits a wall or big mushroom stem, it **stuns itself** (stun meter fills). |
| Husk Charger | Shell Stomp | 1.1 | 18 blunt | Gust | 3 m circle shockwave |
| Gill Stalker | Scythe Pair | 0.6 then 0.4 | 14 + 14 slash | Any | |
| Gill Stalker | Ambush Lunge | 1.0 | 26 slash | Any | Only from hiding. Tell: rustle sound + cap shakes. |
| Gill Stalker | Gill Hiss | 0.8 | 0 | Gust | Cone 5 m, blinds 3 s |
| Cap Spitter | Spore Bomb | 1.2 | 15 blunt + 2 m cloud (25 buildup/s, 4 s) | Reflect | Range **20 m**, arcing |
| Cap Spitter | Root Snap | 0.7 | 12 pierce | Any | Only if you are within 2 m |

**Behavior and where they live:**

| Monster | Special behavior | Lives in | Drops (count, chance) |
|---|---|---|---|
| Wheezecap | Slow (1.5/3 m/s). Puffs first, then walks in. | Everywhere on fungus floors | Giant mushroom flesh ×2 (80%, food/cooking), Spore powder ×1 (50%), Blight Gem (2%) |
| Needlemite | Pack AI: 2 attack while the rest circle at 4 m, then swap. Fast (3/7.5 m/s) | Bug nests, mushroom roots | Needle ×2 (70%, bolt crafting), Venom sac ×1 (25%) |
| Husk Charger | Turns slowly (**90°/s**). Get behind it: back has 0 armor. Can't enter tunnels under 3 m. | Big caverns, wide tunnels | Husk plate ×2 (90%), Beetle meat ×3 (100%), Horn ×1 (30%) |
| Gill Stalker | Hides still under a cap. Revealed if you come within **6 m** with lantern lit, or within 3 m without. Flees to a new cap at 30% HP (the only monster that hides again). | Giant mushroom forests | Scythe blade ×1 (60%), Stalker meat ×2 (80%), Keen Gem (3%) |
| Cap Spitter | Can't walk. When you get within 3 m, it sinks into the floor (**1.5 s**) and pops up **8–12 m** away. | Cavern edges, high ledges | Spitter gill ×2 (70%), Glow spores ×3 (60%, lantern fuel) |

### 5.4 Passive and huntable cave animals (food)

These never start a fight (except where noted). Spec 5.4 says hunting is a food source.

| Animal | Biome | Look | Size | HP | Behavior | Drops |
|---|---|---|---|---|---|---|
| **Moss Shuffler** | Mossy | Slow pill-bug the size of a pig, grazes moss | Medium | 40 | Rolls into a ball when hit (blunt ×1.5 to break the ball). Never attacks. | Shuffler meat ×3, Shell plate ×1 |
| **Flitter** | Mossy | Small cave bat with blue ear tufts | Tiny | 10 | Flies in loops near ceilings, flees from light. Crossbow target. | Wing meat ×1, Leathery skin ×1 (50%) |
| **Pebblepinch** | Mossy | Crayfish in streams | Tiny | 15 | Hides under stones in water. Pinches for 3 if grabbed, then flees. | Tail meat ×1 |
| **Truffle Hog** | Fungal | Snouted, six-legged grazer with mushroom-cap ears | Medium | 90 | **Neutral:** fights back if hit (Tusk Shove: tell 0.8 s, 12 blunt, parry Any), runs after losing 50% HP. Digs up truffles: follow one to find truffle patches. | Hog meat ×4, Truffle ×1 (40%), Hide ×2 |
| **Lampshell Snail** | Fungal | Slow snail with a glowing green shell | Small | 30 | Never moves fast (1 m/s). Leaves a glowing trail for 30 s. | Snail meat ×2, Glow slime ×2 (lantern fuel) |
| **Puffpod Grazer** | Fungal | Floating jellyfish-like spore sack | Small | 20 | Drifts. Pops into a **harmless** spore cloud on death. | Puffpod jelly ×2 (counts as food and drink, like juicy mushrooms) |

Animals respawn in their area **20 minutes** after being killed, if no player is within 50 m.

### 5.5 Drop names → item ids

The drop tables above use fun names. In the game, many of them are the **same item** from the item list (progression doc section 1). This table says which.

| Drop names in this doc | Item id (progression doc) |
|---|---|
| Nipper meat, Raw lizard meat, Toad leg, Shuffler meat, Wing meat, Tail meat | `critter_meat` |
| Skitter hide, Leathery skin, Moss chitin, Shell plate, Hide (Truffle Hog) | `critter_hide` |
| Beetle meat, Stalker meat, Hog meat, Snail meat | `beetle_meat` |
| Husk plate, Horn | `chitin_plate` |
| Giant mushroom flesh | `mushroom_flesh` |
| Truffle | `spore_truffle` |
| Puffpod jelly | `bellcap` (food and drink) |
| Cut stone | `cut_stone` |
| Rusty scrap | `rusty_scrap` (smelts: 3 → 1 copper ingot) |
| Old rune, Rune, Random rune | a rune (progression doc 8) |
| Rune shard | `rune_shard_<colour>`, random colour |
| Red / Blue / Green / Violet / Amber / White crystal | `crystal_red` / `crystal_blue` / `crystal_green` / `crystal_violet` / `crystal_amber` / `crystal_white` |
| Glow spores, Glow slime | `glow_slime` (weak lantern fuel, burns like wood) |

Everything else (Glitter dust, Wickwing wing, Throat sac, Spore powder, Needle, Venom sac, Scythe blade, Spitter gill, and the boss materials like Queen's carapace) is a **special crafting item** owned by this doc. Their recipes (bolts, weapons, armor) are not designed yet; they get written before Step 5.

---

## 6. Pack leaders

Spec rule: while the leader lives, the pack is stronger. Kill the leader and the pack **loses the boost but keeps fighting** (they don't flee).

### 6.1 Which monsters have leaders

| Monster | Leader name | Chance a pack has a leader |
|---|---|---|
| Mossnipper | **Mossnipper Elder** | 25% |
| Skitterling | **Skitterling Ringleader** | 25% |
| Wickwing | **Wickwing Lamplady** | 15% |
| Rustwight | **Rustwight Captain** | 30% (always in ruin halls with 2+ Rustwights) |
| Wheezecap | **Wheezecap Grandcap** | 40% |
| Needlemite | **Needlemite Broodkeeper** | 40% (always in nests) |
| Cap Spitter | **Cap Spitter Oldgill** | 30% |

Solo monsters (Bogbelly, Cairnling, Husk Charger, Gill Stalker) never have leaders. Side bosses act as leaders for their own kind (section 8).

### 6.2 The leader itself

| Value | Leader vs normal member |
|---|---|
| Body size | **×1.3** bigger |
| HP | **×2.5** |
| Damage | **×1.3** |
| Stun max | **×1.5** |
| Armor | **+10** |
| Tells | **Same speed** (fair for parrying) |
| XP | **×3** |
| Drops | Normal drops **×2** + **1 rune** (10%) + 1 normal gem (10%) |

### 6.3 The pack boost

| Boost (while the leader lives, members within **15 m** of it) | Value |
|---|---|
| Damage | **+20%** |
| Move speed | **+15%** |
| Stun max | **+25%** |
| Stun meter decay | **×2** faster (harder to stun them) |
| Pack size | **+1** member compared to a leaderless pack |

**When the leader dies:** all boosts end **instantly**. Members keep fighting with normal stats. No flee, no fear. (The leader's death sound plays so players know.)

### 6.4 How to spot a leader

| Sign | Detail |
|---|---|
| Bigger | ×1.3 size |
| Crown mark | A glowing mark on head or back in the biome's color: **gold moss crown** (Mossy), **orange cap frill** (Fungal) |
| Health bar | Shows a small **crown icon** next to it |
| Sound | Calls the pack with a unique cry when it enters Alert |
| Boosted members | Have a faint gold shimmer at their feet while inside the 15 m boost circle |

---

## 7. Crystal variants

Spec rule: some monsters come in crystal-colored versions with matching powers. Crystals grow out of their backs and glow (they also light the cave around them, which helps you see them coming).

### 7.1 Variant list

| Variant | Color | Power added to every attack | Extra power | Resist | Weakness |
|---|---|---|---|---|---|
| **Ember-crested** | Red | +5 fire damage, +30 burn buildup | Leaves a burning patch (2 m, 3 s, 5 fire/s) where it dies | Fire **75%** | Frost **−50%** |
| **Rime-crested** | Blue | +5 frost damage, +30 chill buildup | Its hits that you block still add 15 chill buildup | Frost **75%** | Fire **−50%** |
| **Blight-crested** | Green | +4 poison damage, +35 poison buildup | Leaves a 2 m poison cloud for 4 s every 10 s | Poison **100%** | Fire **−25%** |
| **Shift-crested** | Violet | +0 | **Blink:** every **8 s** teleports to **6 m** behind or beside its target. Tell: violet shimmer **0.5 s** before. Can't blink while stunned. | All elements **25%** | Pierce **×1.25** |
| **Amber-crested** | Amber (gold-orange) | +0 | **Stone skin:** armor **+30**. Its heaviest attack becomes ⛨ crushing. | Physical (via armor) | Blunt **×1.25** |

### 7.2 Stat changes (on top of the normal monster)

| Value | Change |
|---|---|
| HP | **×1.4** |
| Damage | **×1.1** (before the elemental addition) |
| Stun max | **×1.2** |
| XP | **×2** |
| Size | Same |

### 7.3 Spawn chance

| Where | Chance any spawned monster is a crystal variant | Color split |
|---|---|---|
| Mossy Hollows | **4%** | Red 30%, Blue 30%, Amber 30%, Violet 10%, Green 0% |
| Fungal Jungle | **7%** | Green 35%, Red 20%, Violet 20%, Amber 15%, Blue 10% |
| Pack leaders | Can be crystal variants (stacks both buffs) | Same split |
| Passive animals, bosses | Never | — |

### 7.4 Drops (added to the monster's normal drops)

| Variant | Crystals (lantern fuel) | Gem chance |
|---|---|---|
| Red | Red crystal ×4 | Ember Gem 15% |
| Blue | Blue crystal ×4 | Rime Gem 15% |
| Green | Green crystal ×4 | Blight Gem 15% |
| Violet | Violet crystal ×3 | Swift Gem 15%, Shiftstep epic gem 0.5% (Fungal only) |
| Amber | Amber crystal ×4 | Bulwark Gem 15% |

---

## 8. Bosses and raids

### 8.1 How bosses fit the game (from the spec)

- **Main boss** (one per biome): hidden lair. Found with **3 wall markings**: 1st marking draws a big circle on the map (**radius 120 m**), 2nd a smaller circle (**radius 45 m**), 3rd shows the exact spot. The Cave Maker places exactly **3** per biome, all reachable without digging (one in the Great Hall, one in a small ruin or camp, one on a cavern wall). Rules and numbers: world doc 3.2.
- **Main boss drop:** the part needed for the next pickaxe (with the biome's best ore).
- **Side bosses:** guard big caverns (treasure, rare ore, blueprints). Discovering their cavern starts raids (8.6).
- **Boss drops:** every player within **60 m** gets their own copy.
- **Re-summoning:** each main boss lair has an **altar**. Placing an offering re-summons the boss (for more drops or another epic gem). Offering listed per boss.
- **Lair walls:** the lair is sealed inside normal rock, and you **dig your way in** after the 3rd marking (world doc 3.1). When the fight starts, the lair walls glow and **can't be dug until the fight ends** (win or reset), so nobody can tunnel around the fight. Side-boss caverns are normal rock.
- Bosses don't leash. They **reset to full HP** if every player is more than 60 m away or dead for **30 s**.

### 8.2 Mossy Hollows main boss: **Orrumhal, the Mossbound Keeper**

**Look:** a 5 m stone guardian the old dwarves carved to protect their deepest hall, now wrapped in moss and roots, blue mushrooms growing from its shoulders, a cracked glowing stone in its chest.

| Value | Number |
|---|---|
| Size | Huge |
| HP | **2000** |
| Armor | **30** (phase 3 heartstone: **0**) |
| Slash / Blunt / Pierce | ×0.75 / ×1.25 / ×0.75 |
| Fire / Frost / Poison | 25% / 25% / 100% (immune) |
| Stun max | **200** (+30% each stun) |
| Walk speed | 2.5 m/s |

**Phases:**

| Phase | HP range | What changes |
|---|---|---|
| 1 "Awakening" | 100% → 65% | Uses Fist Slam, Sweep, Rubble Toss |
| 2 "Rootbound" | 65% → 30% | Adds Moss Grasp and Hall Quake. Once, at the start, roars and **4 Mossnippers** crawl out of its moss. |
| 3 "Open Heart" | 30% → 0% | Chest cracks open: the **heartstone** is a weak spot (×1.5 damage, 0 armor, hit from the front). All tells **×0.85** (never under 0.5 s). Adds Heart Pulse. |

**Attacks:**

| Attack | Phase | Tell (s) | Damage | Parry | Tell you can see/hear |
|---|---|---|---|---|---|
| Fist Slam | 1+ | 1.1 | 35 blunt, KD | ⛨ Shield | Raises one fist high, dust falls from it. Smashes pillars it hits. |
| Sweep | 1+ | 0.9 | 25 blunt | Any | Pulls arm back low. 6 m, 180° arc |
| Rubble Toss | 1+ | 1.2 | 20 blunt | Reflect (shield reflect = **60** damage to boss) | Rips a chunk from the floor |
| Moss Grasp | 2+ | 0.8 | 10 + rooted 2 s | Any | Green glow on the floor under a player |
| Hall Quake | 2+ | 1.5 | 15 per ring, 3 rings | Gust (or jump/roll each ring) | Both fists raised, slams floor. Rings 1.0 s apart. |
| Heart Pulse | 3 | 1.5 | 30 fire, 6 m circle | ⛨ Shield + Gust | Chest glows brighter and brighter. Every **20 s** |

**Arena needs:** round hall **30 m** across, ceiling **12 m**, **4 stone pillars** (each breaks after 1 Fist Slam: cover that runs out), the hole you dug in is the only entrance: a stone door grows over it when the fight starts and opens on win or reset.

**Drops (each nearby player):**

| Drop | Count | Chance |
|---|---|---|
| **Keeper's Heartstone** (part for the **Copper Pickaxe**, which breaks the border into Fungal Jungle) | 1 | 100% |
| Copper ingot | 10 | 100% |
| Random rune | 2 | 100% |
| Epic gem: **choose Cinder Wake or Hoarfrost Pulse** | 1 | 100% first kill, 20% re-summons |
| Ancient blueprint "Keeper's Hall" (building style) | 1 | 100% first kill |
| Keeper trophy (wall decoration) | 1 | 100% |

**Re-summon offering:** 10 copper ingots + 5 blue glow crystals + 1 rune shard (any colour).

### 8.3 Mossy Hollows side bosses

**Skerra, the Nipper Queen** — a Mossnipper as big as a wagon, claw scarred, moss back covered in eggs. Guards the **Nest Cavern** (copper-rich).

| Value | Number |
|---|---|
| Size / HP / Armor | Large / **1000** / 15 |
| Slash / Blunt / Pierce | ×1.25 / ×1.0 / ×1.0 |
| Stun max | 120 |
| Pack leader for | Mossnippers (gives them the 6.3 boost) |

| Attack | Tell (s) | Damage | Parry | Tell |
|---|---|---|---|---|
| Great Pinch | 0.8 | 18 slash | Any | Claw opens wide, clicks twice |
| Burrow Strike | 1.0 | 22 slash, KD | ⛨ Shield | Sinks into the moss, the floor bulges under you |
| Mud Spit | 0.9 | 12 blunt + Chill buildup 30 (cold mud) | Reflect | Throat swells |
| Brood Call | 1.5 | Summons **4 Mossnippers** (every 40 s) | Interrupted if she takes **30 stun** during the call | Screeches, eggs glow |

Arena: cavern **25 m**, ceiling 8 m, soft moss floor (needed for Burrow Strike).
Drops (each player): Queen's carapace ×1 (shield upgrade material), Copper ore ×15, Random normal gem ×1 (50%), Rune ×1 (100%).

**Brask, the Rusted Thane** — the animated armor of a dwarf lord, taller than a dwarf, cloak of moss, a great rusty axe. Guards the **Thane's Hall**: the biome's Great Hall ruin (world doc 3.1, old dwarf treasure room and blueprints).

| Value | Number |
|---|---|
| Size / HP / Armor | Medium / **900** / 45 |
| Slash / Blunt / Pierce | ×0.75 / ×1.5 / ×0.75 |
| Fire / Frost / Poison | 25% / 0 / 100% |
| Stun max | 150 |
| Pack leader for | Rustwights (2 wake up with him) |

| Attack | Tell (s) | Damage | Parry | Tell |
|---|---|---|---|---|
| Greataxe Cleave | 1.0 | 30 slash | ⛨ Shield | Axe lifted behind his head, it creaks |
| Twin Chop | 0.7 then 0.5 | 18 + 18 slash | Any | Steps forward with each |
| Shield Charge | 1.2 | 25 blunt, KD | Any | Lowers shoulder, stamps twice |
| Rally Horn | 1.5 | Wakes **2 more Rustwights** (once at 50% HP) | Interrupted by 30 stun during it | Raises a horn |

Arena: hall **20 m**, ceiling 8 m, 2 rows of pillars, ruin decorations.
Drops (each player): Named weapon **"Brask's Rustbite"** (Copper-tier axe, Q4, Jolt Gem socketed), Ancient blueprint "Thane's Hall", Copper ingot ×6, Rune ×1 (100%), Jolt Gem (50%), Leech Gem (25%).

### 8.4 Fungal Jungle main boss: **Thallus, the Grey Bloom**

**Look:** a 6 m beast made of grey fungus grown over stolen beetle shells, four heavy legs like tree stumps, a crown of drooping caps, and **4 glowing spore sacs** on its back.

| Value | Number |
|---|---|
| Size | Huge |
| HP | **4400** |
| Armor | **20** |
| Slash / Blunt / Pierce | ×1.25 / ×1.0 / ×1.0 |
| Fire / Frost / Poison | **−50%** (weak) / 0 / 100% (immune) |
| Stun max | **260** (+30% each stun) |
| Spore sacs | **4**, each **250 HP**, take ×1.5 pierce (crossbow and spear shine here) |

**Phases:**

| Phase | HP range | What changes |
|---|---|---|
| 1 "Grazing" | 100% → 70% | Cap Crush, Tendril Lash, Spore Volley |
| 2 "Rooting" | 70% → 35% | Sinks into the arena's fungus floor, moves under it, and bursts up (Bloom Burst). Adds Choking Exhale. |
| 3 "Grey Fog" | 35% → 0% | Every **15 s** a grey fog patch (6 m) grows somewhere in the arena (blocks sight, 10 poison buildup/s). Tells **×0.85** (min 0.5 s). |

**Spore sacs:** destroying all 4 sacs removes Spore Volley and Grey Fog, and stuns Thallus instantly for **6 s**. This is the "smart" way to win.

**Attacks:**

| Attack | Phase | Tell (s) | Damage | Parry | Tell |
|---|---|---|---|---|---|
| Cap Crush | 1+ | 1.0 | 40 blunt, KD | ⛨ Shield | Rears up on hind legs |
| Tendril Lash (3 hits) | 1+ | 0.7, 0.5, 0.5 | 15 slash each | Any | Tendrils curl back from its shoulders |
| Spore Volley | 1+ (while a sac lives) | 1.2 | 15 blunt + 40 poison buildup, 3 bombs | Reflect (reflected bomb hits a sac for 100) | Sacs pulse, one per bomb |
| Bloom Burst | 2+ | 1.3 | 45 blunt, KD | ⛨ Shield | Glowing ring on the floor under a player, floor trembles |
| Choking Exhale | 2+ | 1.4 | Cone 8 m, cloud 6 s, 10 poison damage/s | Gust | Breathes in loudly, chest swells |
| Trample | 3 | 1.1 | 30 blunt, KD | Any | Lowers head, runs 12 m |

**Arena needs:** round cavern **40 m** across, ceiling **15 m**, floor of soft fungus mat (needed for Rooting), **6 giant mushroom stems** to hide behind (stems break after 2 Tramples), the hole you dug in is the only entrance, sealed by a wall of spore growth during the fight.

**Drops (each nearby player):**

| Drop | Count | Chance |
|---|---|---|
| **Bloomheart Core** (part for the **Silver Pickaxe**, which breaks the border into biome 3) | 1 | 100% |
| Silver ingot | 10 | 100% |
| Random rune | 2 | 100% |
| Epic gem: **choose Echoing Guard or Rootbound Heart** | 1 | 100% first kill, 20% re-summons |
| Ancient blueprint "Bloom Garden" (mushroom-brick style) | 1 | 100% first kill |
| Grey Bloom trophy | 1 | 100% |

**Re-summon offering:** 10 silver ingots + 5 green glow crystals + 3 giant mushroom flesh.

### 8.5 Fungal Jungle side bosses

**Old Ironshell** — a Husk Charger grown huge and ancient, shell scratched with old pick marks, one horn broken. Guards the **Silver Vault** cavern (big silver veins).

| Value | Number |
|---|---|
| Size / HP / Armor | Huge / **1600** / 70 front, 0 back |
| Slash / Blunt / Pierce | ×0.5 / ×1.5 / ×1.0 |
| Stun max | 200 |
| Pack leader for | Husk Chargers (1 joins at 50% HP) |

| Attack | Tell (s) | Damage | Parry | Tell |
|---|---|---|---|---|
| Juggernaut Charge | 1.3 | 40 blunt, KD | ⛨ Shield | Scrapes foot 3 times, snorts. Hitting a pillar = stuns itself for 4 s. |
| Horn Toss | 0.8 | 25 pierce, throws you 3 m | Any | Head dips low |
| Shell Quake | 1.2 | 20 blunt, 4 m circle | Gust | Rises on back legs |
| Roll Over | 1.0 | 25 blunt | Any | Only when you're behind it: tips sideways to crush you |

Arena: cavern **35 m**, ceiling 10 m, **5 rock pillars** (each takes 2 charges, then breaks).
Drops (each player): Ironshell plate ×3 (heavy shield and armor material), Silver ore ×20, Bulwark Gem (50%), Rune ×1 (100%).

**Sivix, Mother of Needles** — a Needlemite queen with a swollen glowing abdomen, six long glassy legs, webs everywhere. Guards the **Brood Hollow** (bug nests, rare venom and blueprints for traps).

| Value | Number |
|---|---|
| Size / HP / Armor | Large / **1600** / 15 |
| Slash / Blunt / Pierce | ×1.0 / ×1.0 / ×1.5 |
| Fire / Frost / Poison | −25% / −25% / 100% |
| Stun max | 140 |
| Pack leader for | Needlemites |

| Attack | Tell (s) | Damage | Parry | Tell |
|---|---|---|---|---|
| Stinger Lance | 0.9 | 25 pierce + 50 poison buildup | Any | Abdomen curls under her |
| Web Spray | 1.1 | 0, cone 6 m, slows **50%** for 3 s | Gust | Spinnerets glow white |
| Ceiling Drop | 1.4 | 35 blunt, KD, 3 m circle | ⛨ Shield | Climbs to ceiling, her shadow grows on the floor |
| Brood Swarm | 1.5 | Summons **6 Needlemites** (every 30 s, max 8 alive) | Interrupted by 30 stun during it | Screech, egg sacs on walls burst |

Arena: cavern **30 m**, ceiling **12 m** (she uses it), webbed walls (fire burns webs and the egg sacs: **burning all 6 sacs stops Brood Swarm**).
Drops (each player): Sivix silk ×5, Venom sac ×5, Blight Gem (100%), Rune ×1 (100%), Ancient blueprint "Web Trap" (100% first kill), Bloomrot epic gem (5%).

**The Gloamstalker** — a Gill Stalker three times normal size, nearly see-through, two glowing eyes. Guards the **Lantern Grove**, the biome's Giant Mushroom Grove cavern (world doc 3.1; rare glow crystals and the biome's best lantern upgrade recipe).

| Value | Number |
|---|---|
| Size / HP / Armor | Large / **1400** / 15 |
| Slash / Blunt / Pierce | ×1.0 / ×1.0 / ×1.25 |
| Fire / Frost / Poison | −25% / 0 / 50% |
| Stun max | 130 |
| Pack leader for | Gill Stalkers (2 hide in the grove) |

| Attack | Tell (s) | Damage | Parry | Tell |
|---|---|---|---|---|
| Scythe Pair | 0.6 then 0.4 | 20 + 20 slash | Any | Arms fold back |
| Shadow Lunge | 1.0 | 35 slash, KD | ⛨ Shield | Only from hiding: rustling, eyes flare |
| Smoke Gill | 1.0 | 0, cone 6 m, blinds 4 s | Gust | Gills flare out |
| Fade | 0.5 | Goes invisible for 8 s (every 25 s) | — (not an attack) | Shimmers. Lantern light reveals it within **6 m**; Glow bolts reveal it within their circle. |

Arena: grove **30 m**, ceiling 15 m, giant mushrooms to hide among, dim (few glow plants).
Drops (each player): Gloam scythe ×2 (spear upgrade material), Silver ingot ×6, White glow crystal ×5, Rune ×1 (100%), Keen Gem (50%), Bloomrot epic gem (5%).

### 8.6 Raids

**Spec rules:** discovering a side-boss cavern starts occasional raids on your base. Killing that side boss stops its raids. Killing the biome's main boss stops **all** raids in that biome, unless the main boss is re-summoned and left alive.

**Raid sources:**

| Situation | Raids active? |
|---|---|
| Side-boss cavern discovered, side boss alive | Yes (that side boss's raid type) |
| Side boss killed | That raid type stops forever (side bosses don't come back) |
| Main boss killed | All raids from that biome stop |
| Main boss re-summoned and **not** killed within 10 minutes (players leave or it resets) | All that biome's side-boss raid types start again (even for dead side bosses, using the same raid lists), until the main boss is killed |

**What counts as "your base":** any spot with a **bed** and at least **1 crafting station** within 20 m. If there are several, the raid goes to the base nearest the players.

**Timing and size:**

| Value | Number |
|---|---|
| Raid check | Every **30 minutes** of play |
| Chance per check | **35%** (only one raid at a time, even with several sources) |
| Minimum gap between raids | **20 minutes** |
| Only when | At least one player is within **40 m** of the base. No raids when nobody is home. |
| Never during | A boss fight, or the first **60 minutes** after a new raid source starts |
| Warning time | **60 s** before monsters arrive |
| Raid ends | All raiders dead, or **4 minutes** pass (survivors walk back into the tunnels) |
| Raiders enter by | The nearest tunnel opening to the base, at least 30 m away. Monsters never dig. |
| Built walls/doors | Raiders that can't reach a player attack the nearest built piece (damage numbers in the building doc) |
| Reward | Raiders drop their normal loot. Killing the whole raid gives +1 rune shard per player. |

**Warning signs (all at once, 60 s before):** rumbling sound from one direction, dust falls from the base ceiling, a distant cry of the raiding monster type, a message: *"Something is coming up the tunnels…"*, and a red arrow on the map edge pointing to where they'll come from.

**Raid lists (1 player; co-op adds raiders, see section 9):**

| Raid source | Raid makeup | Total |
|---|---|---|
| Skerra, Nipper Queen | 1 Mossnipper Elder + 4 Mossnippers + 2 Skitterlings | 7 |
| Brask, the Rusted Thane | 1 Rustwight Captain + 2 Rustwights + 1 Cairnling | 4 |
| Old Ironshell | 2 Husk Chargers + 3 Wheezecaps | 5 |
| Sivix, Mother of Needles | 1 Needlemite Broodkeeper + 6 Needlemites | 7 |
| The Gloamstalker | 2 Gill Stalkers + 2 Cap Spitters | 4 |

Each raider has the normal crystal variant chance for its biome.

---

## 9. Co-op scaling

Count = number of players within **60 m** when the fight starts (for bosses: inside the arena when the door seals). Regular monsters check when they enter Alert. Values don't change mid-fight.

| Players | Regular monster HP | Boss HP | Monster damage | Stun max | Extra pack members | Extra raiders |
|---|---|---|---|---|---|---|
| 1 | ×1.0 | ×1.0 | ×1.00 | ×1.00 | +0 | +0 |
| 2 | ×1.5 | ×1.7 | ×1.05 | ×1.25 | +1 | +2 |
| 3 | ×2.0 | ×2.4 | ×1.10 | ×1.50 | +1 | +4 |
| 4 | ×2.5 | ×3.1 | ×1.15 | ×1.75 | +2 | +6 |

- Boss summons (Brood Call, Brood Swarm, Rally Horn) add **+1 monster per extra player**.
- Stun max grows so four shields can't keep a boss stunned forever.
- Drops don't scale (each player already gets their own boss copy; regular loot is first come, first served, spec 5.12).
- **Co-op rule (from CLAUDE.md):** players send "I hit X with this attack" requests. The **host** checks it, does the math in section 2.2, and tells everyone the result. Parry timing is checked on the **attacked player's own PC** (so lag doesn't ruin parries), then sent to the host.

---

## 10. How to tune

**Where the numbers live.** Each weapon, monster, attack, gem, and boss gets a Godot **Resource file** (`.tres`: a small text file of settings). Example folders: `data/weapons/`, `data/monsters/`, `data/attacks/`, `data/gems/`. Scripts read these files. Changing a number never needs code.

**The tuning order** (change one thing at a time, then play 10 minutes):

| If playtest shows… | Change this first | Then this |
|---|---|---|
| Parrying feels impossible | Parry windows (2.4) +20 ms | Monster tell times +0.1 s |
| Parrying feels too easy, fights are boring | Monster tell times −0.1 s (never under 0.4 s) | Add a 2nd attack to the combo |
| Fights take too long | Monster HP −15% | Tier damage multipliers |
| You die too fast | Monster damage −15% | Health regen delay 6 s → 4 s |
| Stamina runs out all the time | Stamina regen 25 → 30 | Light attack costs −2 |
| One weapon is used by everyone | Lower its damage 10% | Raise the others' special trait |
| Shield makes every fight trivial | Shield parry stun 40 → 30 | Block reduction by tier −5 points |
| Raids are annoying | Chance per check 35% → 20% | Gap 20 → 30 min |
| Co-op is too easy | Co-op HP column +0.2 per row | Co-op damage column |

**Targets to aim for** (what "feels right" means in numbers):

| Fight | Target time | How many player hits (light) |
|---|---|---|
| Mossnipper with Stone sword | ~2 s | 3 |
| Rustwight with Copper mace | ~5 s | 5 |
| Husk Charger with Silver mace, from behind | ~15 s | 8–10 |
| Orrumhal, solo, Copper gear, good play | ~4–5 minutes | — |
| Thallus, solo, Silver gear, good play | ~6 minutes | — |

**Balance check (worked examples, Nov 14 review).** A real fight is not non-stop hitting: you wait for tells, dodge, and back off. So we guess you land hits about **40% of the time** ("uptime"). Fight time ≈ HP ÷ (damage per hit ÷ swing time × 0.4).

| Fight | Weapon (Q1, +0) | Damage per light hit | Result |
|---|---|---|---|
| Mossnipper (30 HP) | Stone sword | 10 × 1.25 slash = 12.5 | **3 hits** |
| Rustwight (90 HP, armor 25) | Copper mace | 11 × 1.3 × 1.5 blunt × 100/117.5 = 18.3 | **5 hits** |
| Cairnling (120 HP, armor 40) | Copper mace | 11 × 1.3 × 1.5 × 100/128 = 16.8 | **8 hits** (fewer with heavies) |
| Husk Charger (210 HP), from behind | Silver mace | 11 × 1.65 × 1.5 = 27.2 | **8 hits** |
| Skerra (1000 HP, armor 15) | Copper sword | 13 × 1.25 × 100/115 = 14.1 every 0.55 s → 10.3 per s at 40% | **~1.6 min** (+ her adds ≈ 2 min) |
| Brask (900 HP, armor 45) | Copper mace | 21.5 × 100/131.5 = 16.3 every 0.75 s → 8.7 per s | **~1.7 min** |
| Sivix (1600 HP, armor 15) | Silver spear | 18.2 × 1.5 × 100/115 = 23.7 every 0.6 s → 15.8 per s | **~1.7 min** (+ swarm) |
| Orrumhal (2000 HP, armor 30) | Copper sword | Phases 1–2: 13 × 0.75 × 100/130 = 7.5 → 5.5 per s. Phase 3 heartstone (0 armor, ×1.5): 14.6 → 10.6 per s | **~5 min** (mace: ~4 min) |
| Thallus (4400 HP, armor 20) | Silver sword | 16.5 × 1.25 × 100/120 = 17.2 → 12.5 per s | **~6 min** (~4 min with an Ember Gem) |

Before this review, Orrumhal had 2400 HP and 50 armor: a Copper sword needed about **370 light hits** (over 8 minutes). That was too long, so HP and armor came down.

**Auto-checks to write** (little tests the computer runs):
- Worked example in 2.2 returns 38.
- Perfect parry returns 0 damage and 0 stamina cost.
- Stun meter can't refill during the 2.0 s immunity after a stun.
- Pack boost disappears the same frame the leader dies.
- Killing a side boss removes its raid source; killing the main boss removes all biome raid sources.
- Co-op table: 4 players → boss HP ×3.1.

---

## 11. Open questions for the owner

Each has a **default** (marked ★) that the doc already uses. Change it if you like another answer. **All open questions from the three design docs are collected, numbered and de-duplicated in `docs/design/README.md`.** Answer them there.

1. **Heavy attack button:** (A) ★ hold left click 0.3 s, (B) a separate key (middle mouse or Q), (C) Shift + left click.
2. **Dodge-roll button:** (A) ★ Left Ctrl + direction, (B) double-tap a direction, (C) Alt.
3. **Friendly fire damage:** (A) ★ half damage (×0.5), (B) full damage, (C) quarter damage.
4. **Big monsters and small tunnels:** (A) ★ they can't follow you into tunnels smaller than them (digging is an escape), (B) some monsters can burrow after you, (C) they wait outside forever.
5. **Epic gems from the first two bosses** (you can't use them until Steel): (A) ★ you choose 1 of 2 on first kill, (B) random, (C) no epic gems until the Steel biome.
6. **Taking a gem out:** (A) ★ gem is kept, costs 5 blue glow crystals, (B) free, (C) the gem breaks.
7. **Raids when nobody is home:** (A) ★ no raids unless a player is within 40 m of the base, (B) raids happen anyway and can damage buildings.
8. **Aiming in fights:** (A) ★ soft aim help only (turns you up to 30°), (B) a lock-on key that keeps the camera on one enemy, (C) both, player chooses in settings.

---

## Review changes (Nov 14, 2026)

The three design docs were written at the same time, so they disagreed in places. This review made them match.

- **Boss fights were too long.** Orrumhal HP 2400 → **2000**, armor 50 → **30**. Thallus HP 5200 → **4400**. Skerra 700 → **1000** and Sivix 1300 → **1600** (they were too short). Cairnling 140 → **120** HP and Husk Charger 260 → **210** HP (to land in 3–8 hits). See the new balance check in section 10.
- **Names that were too close to other games:** "Warden" → **Keeper** (Orrumhal, Keeper's Heartstone), "Sporeling" → **Wheezecap**, "Brood Mother" → **Sivix, Mother of Needles**, "Glow Snail" → **Lampshell Snail**. "Delver Gem" → **Burrow Gem** (Delver is already a rune set name).
- **Crystal colours now match the item list:** purple → **violet**, and drops use the progression doc's crystal ids. "Bars" → **ingots** (`copper_ingot`, `silver_ingot`). Resin (not an item) → rope.
- **Wall markings:** 3 per biome (not 5), circles 120 m then 45 m, to match the world doc.
- **Boss lairs:** you dig into a sealed lair (world doc). The walls only become undiggable during the fight (they used to be border rock, which made digging in impossible).
- **Runes:** every side boss drops 1 rune, main bosses drop 2, pack leaders 10% (rune rules belong to the progression doc).
- **Matches the Step 1 code and the progression doc:** pickaxe swing stamina 4 → 5, player walk/run 4.0/6.5, dwarf height 1.35 m, dug tunnels are 2–2.5 m high (so Medium monsters can follow), hunger-at-zero effects, and quality/upgrade bonuses now use the same table as tools.
- **Added:** section 5.5 (drop names → item ids) and the hand-lantern rule (no shield or two-handers until the back lantern).
