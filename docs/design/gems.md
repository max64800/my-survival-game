# Gems (owner's plan, Nov 20, 2026)

Gems are the long grind: you farm dungeons for them, combine them, and move them to better gear.
Replaces the old gem numbers in `combat-and-monsters.md` section 4 where they disagree.

## Slots
| Gear | Stone / leather | Copper | Silver (later) | Iron (later) |
|---|---|---|---|---|
| Weapon, shield, pickaxe, wood axe, each armor piece (head, chest, legs, feet) | 0 | 1 | 1 | 2 |
| Highest gem level it holds | – | Polished (3) | Brilliant (4) | Ancestral (5) |

The two-handed war axe is a **weapon**; the wood-chopping axe is a **tool** (it uses the pickaxe column).

## Levels
3 of the same gem at the same level → 1 of the next level, at the Gem Bench. Never fails.

| Level | Name | Made from | Costs |
|---|---|---|---|
| 1 | Rough | found | – |
| 2 | Cut | 3 Rough | 10 gold |
| 3 | Polished | 3 Cut | 30 gold |

Taking a gem out: 5 gold (it comes back whole).

## The 9 gems (Rough / Cut / Polished)
Internal ids stay the old ones so saves keep working.

| Gem (id) | Weapon | Shield | Pickaxe / wood axe | Armor |
|---|---|---|---|---|
| Edge Quartz (keen) | +2/5/10% damage | parry window 2/5/10% longer | – | attackers take 2/5/10% of their hit back |
| Stone Amber (bulwark) | 2/5/10% less damage taken while swinging | blocks stop 2/5/10% more | – | 1/2/5% less damage from everything |
| Wind Amethyst (swift) | swings −2/5/10% stamina | blocks −2/5/10% stamina | dig / chop −2/5/10% stamina | stamina refills 2/5/10% faster |
| Deep Onyx (burrow) | – | – | dig / chop 2/5/10% faster, 2/5/10% extra ore | 2/5/10% chance of double ore and stone |
| Blood Ruby (leech) | heal 2/5/10% of damage dealt | parry heals 1/2/4 | – | healing 2/5/10% faster (natural healing and bandages) |
| Storm Topaz (jolt) | +5/15/25% stun power | parry stun +5/15/25% (the shield bash, once built) | – | 2/5/10% chance to stun what hits you |
| Bog Jade (blight) | 5/15/25% chance a hit adds a poison stack | 5/15/25% chance a block poisons the attacker | – | 5/15/25% less poison |
| Forge Garnet (ember) | 5/15/25% chance a hit sets it burning | 5/15/25% chance a parry burns the attacker | – | 5/15/25% less fire |
| Frost Sapphire (rime) | 5/15/25% chance a hit adds a frost stack | 5/15/25% chance a parry chills the attacker | – | 5/15/25% less frost |

## Poison, fire, frost (the effects themselves)
| | How | Shield |
|---|---|---|
| Poison | 1 damage/s per stack for 10 s, up to 3 stacks, each new stack restarts the 10 s (max 30 damage) | a block stops it |
| Fire | 3 damage/s for 5 s | **goes through a block** (a parry still stops it) |
| Frost | 10% slower per stack, up to 5; at 5 stacks frozen 1.5 s | half through a block |

Sources in zone 1: Rock Snail spit = 1 poison stack; cave spiders: 3 bites = 1 poison stack; red / blue creatures
burn / chill, and inside dungeons they're common (about 1 in 8).

## Where gems come from
| Source | Drop |
|---|---|
| End of every dungeon (last chest, refills after 1 h) | 1 Rough gem, 100%, one of that dungeon's 2 gems |
| Any boss | 50% a Rough gem |
| End of a big dungeon | 50% Cut, 50% Rough (the **only** place Cut gems drop) |
| Creature statues | 2%: half the time the creature's own gem (spider Bog Jade, snail Stone Amber, beetle Edge Quartz, bat Wind Amethyst, red Forge Garnet, blue Frost Sapphire), else random |
| Geodes, ore digs | see `rare-finds.md` (geodes: Deep Onyx, Wind Amethyst, Edge Quartz, Storm Topaz) |

## Shield bash
While blocking, press attack: shield shoves forward. ~5 damage, a big stun (about 40% of the stun meter),
costs stamina, 2 s wait between bashes. Storm Topaz in the shield adds bash stun.

## Built (Nov 20, Mac) / not yet
- Built: the 9 gems x 3 levels (`src/combat/gems.gd`, icons `assets/icons/gem_<id>[_2|_3].png`), combining and
  taking out for gold (`GameAuthority.request_combine` / `request_unsocket`, Gem Bench window), armor sockets and
  armor effects (`Gems.armor_bonus`, `Vitals.gear`, `MonsterManager.request_hit_back`), the new poison / fire /
  frost (`src/survival/ailments.gd`), snail and spider poison, fire / ice creatures in dungeons, the dungeon's last
  chest gem (`DungeonBuild.add_chests`, loot "big"), the boss gem (`DungeonKeys.drop_key`), statues 2%.
- Nov 21: boss gem in the statue (`MonsterManager._kill`, any `boss = true` creature, e.g. the Foreman); extra wood from Deep Onyx in a wood axe.
- Not yet: Storm Topaz bash stun (the bash exists now), geodes, the "highest level per metal" limit (only matters once Brilliant exists).
