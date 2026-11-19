# Food and healing (owner, Nov 19)

Draft food plan (zone 1 recipes, kitchen steps, effects): `tools/craft_wiki/food_plan.json`, shown in the Crafting Book.

## Healing
- On your own you heal **1 health every 5 s**. Every food and drink adds a little healing speed.
- **2 foods + 1 drink** work at the same time.
- Each zone has a top healing speed. Zone 1: **1 health every 2 s** (the best 2 foods + the best drink reach it).
  Later zones raise the cap (numbers picked when each zone is built).

## How healing is shown: half hearts, 5 hearts max for the whole game
Players never see "1 health every 3.9 s" on a card. They see hearts; hovering shows the exact speed.

| Zone | Basic food | Best food |
|---|---|---|
| 1 | ½ ♥ | ♥ |
| 2 | ♥ | ♥½ |
| 3 | ♥½ | ♥♥ |
| 4 | ♥♥ | ♥♥♥ |
| 5 | ♥♥½ | ♥♥♥½ |
| 6 | ♥♥♥ | ♥♥♥♥½ |
| 7 | ♥♥♥♥ | ♥♥♥♥♥ |

- Zone 1: ½♥ = campfire one-ingredient meals, Bellcap Juice, Glowcap Tea. ♥ = stews, Glow Broth, Firecap Skewer,
  Firecap Cordial, Moss Ale, Miner's Pie, Old Hearth Stew. (`heart_scale` in food_plan.json: +0.04 health/s or more = ♥.)
- Every food card lists its effects as bullets, always in this order: healing hearts first, then the other buffs,
  then how long it lasts.

## The kitchen (owner, Nov 20): 3 levels
| Level | Build | Cook | Effects last |
|---|---|---|---|
| 1 | Campfire | one-ingredient meals | 15 min |
| 2 | Cooking Pot placed **on** the campfire | stews, broth, tea, cordial, ale, tuber mash, firecap skewer | 25 min |
| 3 | + **Stone Oven** within 10 m | Miner's Pie, Old Hearth Stew | 35 min |

Station helpers count from **10 m** (was 4 m). Holding a station, a helper or the build hammer shows glowing lines
from each helper to the station it counts for (gold = counts now, green = where the one in your hand would connect).

## Still to build
The food plan isn't in the game yet (today's foods keep their old effects and don't speed up healing). Building it:
new healing numbers in Vitals, 2 foods + 1 drink slots, the guards and other new effects, the pot-on-the-fire kitchen and the Stone Oven model, and the hearts + bullet list on the in-game food cards and bag tooltips.
