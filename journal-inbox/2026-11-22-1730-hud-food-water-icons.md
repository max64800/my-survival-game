## Nov 22, 2026 (PC, icons chat): painted hunger and thirst signs (F638)

- **What the owner asked:** new icons for food and water, the hunger and thirst signs on the screen.
- **What I found:** the two round dials next to the hotbar (`src/ui/vital_dial.gd`) drew a flat dark mushroom and
  a flat dark drop with code shapes, while everything around them (hotbar, status badges) is hand-painted.
  The food and drink items' own pictures were already painted ChatGPT icons and matched, so I left them alone.
- **What we did:** in my own ChatGPT tab (the owner's Chrome) I asked for one 3 x 2 sheet: 3 food ideas (mushroom,
  drumstick, stew bowl) and 3 water ideas (drop, tankard, waterskin), thick dark outlines so they read at 40 px.
  Prompt: "a sheet of 6 small HUD icons for a cozy-but-rough underground dwarf survival game ... top row = hunger
  ideas, bottom row = thirst ideas ... hand-painted, chunky, thick dark-brown outline, plain light-grey background".
  Cut and background removed with rembg + ISNet (`tools/art/cut_hud_vitals.py`), then made a preview that copies the
  dial (bronze ring, orange/blue liquid) at real size and 3x. Owner picked the **stew bowl** and the **water drop**
  in round 1. They live in `assets/icons/hud/`; the dial now draws the picture at about two thirds of its size.
  New test `test_hunger_and_thirst_dials_show_painted_pictures`. Checked in a muted test game: both read well.
- **Mistakes and hurdles (mine):**
  - Chrome's helper timed out twice at first, then connected on the third try (nothing changed; it was just slow).
  - ChatGPT's "image is ready" text didn't match what I waited for, so I waited the full 4 minutes; checking for a
    big picture on the page worked instead. Saved it by drawing it on a page canvas and reading it out.
  - `tools/run_tests.sh` couldn't find Godot (not on PATH in this shell); fixed by setting `GODOT` to the WinGet path.
  - `only=<test name>` ran 0 checks: `only=` filters by file name (`only=vitals`), `fn=` by test name.
  - Another chat had already committed my new F638 line together with theirs, and other chats had unfinished lines in
    FEEDBACK.md and CREDITS.md, so I applied my edits to the committed copies and staged those, leaving theirs alone.
