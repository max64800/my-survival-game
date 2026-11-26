## 2026-11-26: F869 follow-up: doors saved open shut too

- Closed the gap from the first F869 entry: a door that was open when the world was saved now also gets its 30 s timer when the world loads (`builder.gd` load_snapshot). Test: extra check in `test_doors_open_and_ladders_climb`.
- Hurdle found by reading: the `tower_walk` robot opens every door and needs them to stay open. With the new load timer, doors the save had open would have shut in the middle of its walk, so it now clears the timers after opening. `buildcheck`/`kitcheck` open doors directly (no timer), so they're unaffected.
- Still not run: no Godot on the Mac.
