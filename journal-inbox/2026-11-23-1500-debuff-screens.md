## 2026-11-23: Debuff screens (F799)

**What we did**
- Gave each ailment its own look at the screen edges (the middle stays clear):
  - Poison: green edges that creep in and out in slow, uneven waves, and "breathe" a little.
  - Burning: orange flames that flicker and lick upward, tallest along the bottom of the screen.
  - Chilled / frozen: white-blue frost crystals that grow in from the edges and twinkle now and then.
  - Hit: the thin red rim from F695, now drawn *on top* of the ailment look so you see both.
- Looks grow in (0.6 s) and melt away (0.9 s) instead of popping. More stacks make them a bit thicker and stronger
  (poison 1–3, chill 1–5, frozen = full frost). Switching ailments first melts the old look away.
- Files: `src/ui/screen_edge_flash.gdshader` (all four looks), `src/ui/screen_edge_flash.gd` (fades, stack strength),
  `src/ui/hud.gd` `_update_edge_status` (burn wins, then poison, then cold), 2 new tests in `tests/test_edge_flash.gd`.
- Made a 3D page for the owner with the same shader over a small cave, with buttons for each ailment.

**Mistakes and hurdles**
- Godot wasn't on the PATH in Git Bash. Found it in the WinGet folder and set `GODOT` for the test runner.
- My preview script called `_process` before `_ready` had run (the material was still empty). Fixed by waiting one frame.
  The effect also came out too small at first because a bare test window doesn't stretch it; set its size by hand.
- **Square patches** in the effect: the usual `fract(sin(...))` random helper loses precision on graphics cards. Swapped
  it for a hash without `sin()`. The pictures showed this; the tests could not.
- First fire was too yellow along the top and sides; made the top and sides thinner and the colour deeper orange.
- Chrome remote debugging wasn't on, so I checked the 3D page with headless Chrome's screenshot option instead.

**Round 2 (owner's notes on the 3D page, same day)**
- Owner: poison should be veins/roots that pump; burning is "too much"; chilled OK but should cover far more, like frost
  growing over the screen; and a new low-health screen (F802): dark red, much thicker left/right, blood splats.
- Built: pumping green veins (warped noise lines that thin out inward, a bright wave runs inward on each heartbeat),
  thick white frost with a jagged icy front reaching furthest into the corners (creeps in over 1.4 s), 3 calmer
  burning styles (A embers = default, B singed edges, C heat throb) for the owner to pick, and the low-health screen.
- The shader's shared part is now copied straight into the 3D page by `tools/make_edge_fx_page.py`
  (template `tools/edge_fx_page_template.html`), so the page can't drift from the game.
- Hurdles: the first frost was far too much and looked like lightning (too-strong ridge lines); calmed it down.
  Blood splats first looked like polka dots, then got cut off square: each splat was drawn only inside its own
  grid square. Fixed by checking the 9 squares around each spot.

**Round 3 (owner's notes on round 2, same day)**
- Owner: poison is good. Burning: "a lot more" embers, more detailed, plus black ones, rising from under the screen,
  mostly up the sides, a few in the middle that die out halfway. Frost: too many curves, real frost on windows is
  sharp straight needles (sent photos); nothing at top/bottom at 5 stacks; a bit more see-through. Blood splats
  too big and should be long like thrown paint. Hit is good.
- Built: 3 layers of rising sparks (glowing tails, flicker, cool as they rise) + 2 layers of tumbling, torn-edged
  black ash, some with a glowing rim; the A/B/C burning switch is gone. Frost is now "ferns": a straight spine with
  straight needles leaning to the tip, in little star bursts of 3, at 4 sizes, each growing out from a seed inside
  the frost. Blood is now small thrown-paint streaks (blob, thinning streak, strings with end drops, loose drops).
- Hurdles: (1) the frost was empty at top/bottom because its "how far from the edge" measure mixed in the distance
  to the side walls, so the middle of the top edge counted as far away. Now it uses the nearest edge, with a small
  boost in the corners. (2) The first fern version looked like scattered loose feathers (one fern per seed);
  bursts of 3 ferns plus a 4th, smaller size made it pack together like a frozen window. (3) Ash looked like little
  squares; switched to a torn round outline. (4) A bash heredoc with the GLSL broke on a quote, so Claude wrote
  the shader pieces as files instead.
- Owner, after round 3 screenshots: "blood is all the same, needs variety, frost needs variety, burning is good".
  Blood now has 3 kinds (thrown streak, spiky round splat, spray of drops), sizes 5-18 mm-ish, random string counts,
  and shades from dried dark to fresh bright. Frost bursts have 1-6 arms (mostly 1-3), different widths, needle
  angles and spacing, brightness, plus clear gaps. Hurdle: too many arms on the small crystals turned the frost
  into a field of little snowflake crosses; small ones are now single ferns, and the stars are rare and big.
- Commit: another chat had `src/player/dwarf.gd` staged; Claude unstaged it for this commit and staged it again after.
