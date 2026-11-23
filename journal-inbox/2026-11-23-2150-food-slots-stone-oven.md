## 2026-11-23 (PC) — Food slots on the screen + the Stone Oven's own model (F426)
- **Found first:** the owner's prompt asked to build F426 from the plan, but almost all of it was already in the game
  (Nov 20, Mac: food effects, healing hearts, 2 foods + 1 drink, the 3 kitchen levels). Only two things were left:
  how eaten foods show on the screen, and the Stone Oven still borrowing the kiln's model. Asked the owner instead of
  rebuilding: they picked "3 slot icons" and "make the oven now".
- **Built:** `src/ui/food_slots.gd`: 2 food slots (3 with Cooking ★75) + 1 drink slot right of the health bar, the
  meal's picture inside a ring that empties as it wears off (gold food, blue drink), minutes under it, faded empty
  slots, hover = effects. Foods are no longer text lines in the bottom-left corner. Co-op: the HUD only reads the
  synced buffs, the host still applies every effect. Test: `tests/test_food_slots.gd`. Photo tool: `tools/shot_food.gd`.
- **Stone Oven model:** `tools/asset_forge/builds/stone_oven.py` (stone base in 3 shifted courses, clay barrel roof
  with ribs, round stone face and round mouth with coals + fire spot, stone ledge, back chimney, bread paddle).
  `Station.model_id` no longer swaps it for the kiln. Model rule checks pass.
- **Hurdles (Claude's own):** (1) first HUD photo was all black: the loading screen covers a fresh HUD, the photo tool
  now turns it off. (2) First spot (above the hunger/thirst dials) touched the lantern bar, and a 3rd food slot would
  cover it: moved the row right of the health bar, where the screen was empty. (3) First oven: the clay roof was
  invisible (I flattened half a cylinder and its faces pointed inward) and the front was a flat slab like a gravestone.
  Fixed by sinking a whole clay barrel into the base and using a round stone front. (4) I first drew emoji in the
  empty slots; the game font has none, so they say "food" / "drink" instead.
- Talked with the carry-weight chat (F793) before editing hud.gd: no clash.
