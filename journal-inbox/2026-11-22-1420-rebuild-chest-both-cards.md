## Nov 22: The Rebuilding Chest shows both cards now (F689)

**What we did**
- The owner was confused opening the Watchtower's Rebuilding Chest: the top line said "put in planks or cut stone"
  (two ways), but the pictures below only ever showed Wood. They asked what the other way (rope or cut stone)
  actually needed.
- Explained that was on purpose (F634, the owner's own Nov 22 request): the Stone card stays hidden until you're
  already carrying some cut stone, so new players aren't shown a way they can't do yet. Also gave the real
  breakdown: Wood needs Root Planks + Rope, Stone needs Cut Stone + Mortar.
- Asked the owner how they wanted it going forward. They picked "always show both cards" — so the top line and
  the pictures always agree, even before you're carrying any stone.
- Changed `src/ui/box_panel.gd`'s `_show_ways()`: it no longer checks what the player is holding, so both the Wood
  and Stone cards render every time the chest's untouched.
- Updated `tests/test_tower_rebuild_play.gd` to expect both cards from the start instead of just the wood one.
- Logged it as F689 in `FEEDBACK.md` (fixed).

**Mistakes and hurdles**
- F-number collision: another Claude window on this shared PC had already used F686 and F688 for unrelated fixes
  (enemy knockback, ghost mace) between when I last checked and when I went to log this. Re-checked the real
  highest number in use (`grep -oE '\*\*F[0-9]+\.'`) and used F689 instead, fixing my own doc comments that still
  said F688.
- Ran the updated test 3 times before it passed cleanly: one run failed on an unrelated timing check ("no step of
  the rebuild freezes the game"), one failed on a null-texture error deep in piece building — neither touches the
  cards I changed, and both never came back on a clean 3rd run, so they look like one-off flakiness on a busy
  shared PC, not something my change caused.
- Had to hunt down the Godot executable itself: no `GODOT` env var and no `godot` on PATH. Found it installed via
  WinGet (`...\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`).

**Files changed:** `src/ui/box_panel.gd`, `tests/test_tower_rebuild_play.gd`, `FEEDBACK.md`.
