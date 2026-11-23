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

## Built (Nov 20, Mac)
- Zone 1 foods have their plan effects (`Foods.DISHES`), healing 1 health / 5 s sped up by food up to 1 / 2 s
  (`Vitals.regen_per_second`), 2 food slots + 1 drink slot, each food effect stops at 50%, creature guards on
  monster hits, lose food/water slower, digging and extra drops (host boosts).
- Crafting window: healing hearts (hover = exact speed) and bullet effects under the ingredients; bag tooltips too.

## Kitchen built (Nov 20, Mac)
All cooking happens at the **campfire** now. A Cooking Pot placed on (or right next to) a campfire snaps on top of
it and makes the fire level 2; a Stone Oven (stone 20, clay 10, 2 planks, Workbench) within 10 m makes level 3.
Pressing E on the pot opens the fire's cooking. Because it's all one station, the dwarf's auto-crafting now roasts
the bug meat by himself when you make a Miner's Pie.

## Food slots on the screen (Nov 23, PC)
Right of the health and stamina bars: 2 food slots (3 with Cooking ★75), a small gap, 1 drink slot
(`src/ui/food_slots.gd`). Each shows the meal's picture with a ring that empties as it wears off (gold = food,
blue = drink) and the minutes left under it; empty slots stay faded ("food" / "drink"). Hover (bag open) = effects.
The old text lines for foods in the bottom-left corner are gone. The Stone Oven has its own model now
(`tools/asset_forge/builds/stone_oven.py`: stone base, clay barrel roof, round stone mouth, chimney, bread paddle).

## Still to build
- Old saves: a Cooking Pot standing away from a fire no longer cooks; put a new pot on a campfire.
- Zone 2+ foods keep their old effects.
