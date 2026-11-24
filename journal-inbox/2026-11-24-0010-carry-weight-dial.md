## 2026-11-24 (PC) — Carry weight dial, like Conan (F793 part 2)
- **Owner asked:** "overloaded is only on the stamina bar, needs another icon above food and water in the middle,
  for weight, similar to Conan Exiles: a weight that fills up, green ok, yellow heavy, red overloaded. Use GPT."
- **Picture:** one 3x2 ChatGPT sheet in the same chat as the hunger/thirst sheet, so the style matches (iron weight,
  anvil, sack of rocks, stone weight, backpack, stacked stones): `tools/art/sheets/hud_weight_sheet_nov23.png`.
  Cut with `tools/art/cut_hud_vitals.py`. Before picking, I put three of them on green / yellow / red mock dials:
  the dark iron weight got lost on the dark empty part, and the grey **stone weight with an iron handle** read best,
  so that's `assets/icons/hud/weight.png`. The other five stay on the sheet if the owner wants to swap. Logged in CREDITS (AI-made).
- **Built:** `src/ui/weight_dial.gd` grows from the hunger/thirst dial (same bronze ring). The fill rises with
  weight / overloaded line, green → yellow (heavy) → red pulsing (overloaded, always full), plus a thin mark where
  "heavy" starts, and a hover tip "Weight 252 / 300  Heavy: slower". hud.gd: built after the dials, centred above
  them in `_place_vitals`, fed in `_show_carry`. The old HEAVY/OVERLOADED word in the stamina bar is gone.
- **Robot photos:** new `carrycheck` (`-- carrycheck claude=carryweight shots=…`) adds 100, then 250, then 350 stone
  and takes a photo each time: green a third full, yellow, red. Looks right.
- **Tests:** 2 new in `tests/test_carry_weight.gd` (colours + fill; the dial sits centred above the dials in a real HUD). 11/11,
  and the other HUD tests (menu, food slots, combat HUD, edge flash, scripts load) pass.
- **Hurdles (Claude's own):** (1) I named a variable `load`, which hides Godot's own `load()`; a find-and-replace
  renamed it but also changed the dictionary key and two comments, so I fixed those by hand. (2) When the owner said
  "pause and commit", hud.gd and CREDITS.md also held the bag-UI chat's unsaved work, so I staged only my own lines
  (built from the last saved copy + my changes) and didn't sweep theirs into my commit. (3) My first photo crop
  missed the dial (wrong corner).
- Told the bag-UI chat and the Prow Hall chat before editing hud.gd; both said go ahead.
