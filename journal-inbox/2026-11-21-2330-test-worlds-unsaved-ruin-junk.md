## Nov 21 (Claude 2): rebuild prices checked, test worlds never save, rebuilt ruins tidy outside too

**What we did**
- The owner asked how big a grind rebuilding is. Claude measured every ruin's price (seed 42): Watchtower 79 planks + 10 rope
  (or 151 cut stone + 15 mortar), Outpost 253 planks, Brewhall 57 planks + 21 brick, Spire 314 planks. Rebuilds already cost
  30% of new and only the broken pieces count. The owner said that's fine: no change.
- F595: the menu's dev Dungeon and Ruin test worlds are never saved now (no autosave, nothing on Quit/Main Menu; Save says
  "Test world: never saved"). One check, `saves_world()` in main.gd, used by both the save button and the autosave.
- F596: when a ruin starts being rebuilt, all of its junk goes, inside AND outside (before, only the inside went), including
  the searchable barrels and crates outside.

**Mistakes and hurdles**
- Claude first also wrote a "clear the rubble round the ruin" sweep, then the test showed the rubble was already gone: the
  rebuild clears rubble floor by floor by itself. The extra sweep was taken out again (no doubled code).
- A test variable was named `r` twice in the same function (Godot refused to load the test). Renamed.
- The first version of the new save test used `_start_ruin_test`, which lives in another Claude's unsaved change to main.gd.
  Committing only Claude 2's part would have left a test that can't run, so the test was changed to stand on its own.
- main.gd and FEEDBACK-done.md had other Claudes' unsaved work in them: Claude 2's lines were put on top of the last saved
  version and committed alone (their work stays untouched in the folder).
