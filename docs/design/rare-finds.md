# Rare finds (idea, Nov 20, 2026: brainstorm with the owner, nothing built yet)

Rule from the owner: decide what a rare find is **for** before adding it. Each one feeds a system that exists.

## The four ideas (Claude's suggestion, waiting for the owner's pick)

| Rare find | Where | What it's for |
|---|---|---|
| **Geode** (lumpy stone) | ~1 in 150 rock digs | Crack at the Mason's Table: mostly crystals, sometimes a gem, very rarely an epic gem. The miner's own gem source (today gems come almost only from fighting). Suggested zone 1 geode gems: Swift, Keen, Bulwark, Burrow; elemental gems (Ember, Rime, Blight) stay with creatures. |
| **Pure copper nugget** | ~1 in 40 copper ore digs | Smelts into 3 bars at once (copper gear costs 15-30 bars). |
| **Ancestor relics** (~8 in zone 1: ring, carved mug, old helm…) | A few hidden at POIs + a tiny chance from digging, chopping, chests | Placed on an **Ancestor Shrine**: each new relic = a small permanent bonus for the whole clan (+5 max health, +1 bag slot…) and a lore line. Duplicates melt into gold coins at the Anvil (gold today: only chests, only used for perk resets). Needs a relic list + a shrine model (PC). |
| **Golden plants** (glowcap, firecap) | ~1 in 30 harvests | The same meal but it lasts twice as long (doesn't heal more: zone 1 stays at one heart). |

- How often: all together about **every 20 min** of normal play.
- How it shows: sparkle on the ground + a small chime + "Rare find: Geode!"; friends nearby see the sparkle.
- Co-op: drops on the ground like everything else.
- Perks that finally get a job: **Gathering ★100** (rare finds +50%), **Master of Stone** (geodes 2x, always at least a gem),
  **Chest Looter** (nuggets and relics in chests).
- Suggested order: geodes + nuggets first (small, only icons), then relics + shrine.

## Gems today (from `src/combat/gems.gd`)

Sockets: stone 0, copper 1, silver 1, iron 2, steel 2 + 1 epic. **Armor and clothes have no sockets.** Set at the Gem
Bench; removing costs 5 blue crystals; a 2nd copy of the same gem in one item works at half strength.

| Gem | Weapon | Shield | Pickaxe | Zone 1 source today |
|---|---|---|---|---|
| Ember | +5 fire, burn | parry burns attacker | – | red crystal creatures (~1 in 550 kills), ruin chests 3%, statues |
| Rime | +5 frost, chill | parry chills attacker | – | blue crystal creatures (~1 in 550), statues |
| Blight | +3 poison, poisons | block poisons attacker | – | green creatures are zone 2 only; statues |
| Leech | heal 5% of damage dealt | parry heals 4 | – | zone 2 ruin chests 4%; statues |
| Jolt | +30% stun | parry stun +30% | – | statues only |
| Swift | attacks −15% stamina | blocks −20% stamina | mining −25% stamina | violet creatures (~1 in 1,700), statues |
| Bulwark | −10% damage taken while swinging | blocks 8% more | – | amber creatures (~1 in 550), statues |
| Keen | +8% damage | bash +25% | – | ruin chests 3%, statues |
| Burrow | – | – | +20% dig power, +10% extra ore | 1 in 200 ore digs, statues |

Statues: every kill turns to stone; mining it gives a gem 1 in 20 (any of the 9, ~1 in 180 kills for one kind).
So a fighter finds a gem about every 20 kills; miners have almost only Burrow; Jolt, Leech, Blight barely exist in zone 1.

## Open questions for the owner
1. Should **armor** get sockets (e.g. 1 on copper armor, gems that resist fire / cold / poison)?
2. Geode gems: the calm four above, or any gem?
3. Which of the four rare finds to build, and in which order?
