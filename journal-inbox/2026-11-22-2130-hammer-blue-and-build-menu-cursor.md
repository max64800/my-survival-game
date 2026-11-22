## Nov 22: the hammer's blue outlines (F567, 3rd time) and the B menu's vanishing cursor (F708)

- **F567 came back a 3rd time** ("I still see the blue outlines when I'm holding a hammer"). This time we measured first
  instead of guessing: a new test (`tests/test_hammer_no_blue.gd`) builds a half-rebuilt ruined tower and one of your
  own blueprint sites, holds the hammer, and lists every blue see-through thing on screen.
- **What it found:** 150 built pieces glowing blue + 36 blue plan pieces of your own blueprint site. The blue glow was
  the hammer's "strength colours" (strong = blue, good = green, weak = yellow, about to fall = red). Almost every piece of
  a rebuilt tower is "strong", so the whole tower turned blue.
- **Mistake (Claude, earlier chats):** both earlier fixes switched off the *ruin's plan* (the blue ghost of what is still
  to be built), which was a different blue thing. Nobody checked which blue thing the owner actually saw. Lesson: when a
  fix comes back, count what is really on screen before changing code.
- **Fix:** strong and good pieces no longer glow at all; only shaky pieces glow yellow/red as a warning
  (`BuildMode.warning_tint`). No build site shows its blue plan any more (ruin or your own). Only what you are placing
  right now shows. The "85% steady" line when you aim at a piece still tells you how strong it is.
- **Hurdle:** the test showed no glow at first. Its BuildMode had no dwarf, so every frame it decided "no hammer" and
  switched the glow back off. Paused it in the test.
- **Hurdle:** `godot` wasn't on the Bash PATH on the PC; the tests ran with `GODOT=` set to the WinGet Godot console exe.
- **F708 (cursor vanishes in the B menu):** two causes in `main.gd`. A click that missed the menu's buttons counted as
  "click back into the game" and hid the cursor (only the bag was protected), and coming back from Alt+Tab did the same.
  New `menu_wants_cursor()` protects every mouse menu. The build menu now also frees the cursor whenever it appears
  (like the chest menu's F633 fix). Test: `test_build_menu.test_build_menu_always_shows_the_cursor`.
- **Hurdle:** another chat was halfway through editing `blueprint_library.gd` (a parse error at line 1272), which broke
  one blueprint-book test while we ran ours. Not ours, left alone. `main.gd` and `FEEDBACK.md` also had another
  chat's unsaved edits, so only our own lines were committed.
