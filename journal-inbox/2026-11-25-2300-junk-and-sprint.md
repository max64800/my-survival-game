## Nov 25: F864 again (all ruin junk goes after a rebuild) and the stuck sprint (F494, 5th time)

**What we did**
- F864: the owner wanted everything gone after a rebuild (carts, coal places, crates). Claude had asked a question
  earlier, read the answer the wrong way and kept the "whole things". Now every junk piece and searchable prop goes.
- The real old bug: the Smeltery's ingot cart, coal scuttle, charcoal bay and ingot stack come from the ruin's own
  plan, and they were never marked as belonging to the ruin, so the clean-up always skipped them. `tidy_ruin` now
  removes every prop whose key starts with "r:<ruin>:".
- Stuck sprint: four earlier fixes each guessed one way the game misses Shift coming back up (Alt+Tab, menus, the
  Windows keyboard-language shortcut). The new fix doesn't guess. Every mouse click and key press carries
  Windows' real Shift state, so if it says "up" while run is still held, the dwarf stops running.

**Mistakes and hurdles**
- Claude misread the owner's F864 wish (kept the whole things). Lesson: when the owner's words could mean "it's
  gone, that's bad" or "it should be gone", repeat it back in plain words before building.
- `LootProps.new(null)` failed: LootProps takes no argument and makes its `_root` in `_ready`, so the test sets it.
- A python fix-up script broke on nested quotes. Writing the script to a file first worked.
- test_dwarf has 5 failures that were there before this change (checked with the new code switched off).
