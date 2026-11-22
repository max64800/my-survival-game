## Nov 22, night: spiral stairs stack into towers and climb smoothly (F780, F781)

**What we did**
- **F780, snapping.** Aim a spiral stair at the landing (or the top half of the side) of a built one, and the new
  one goes 2 m up, turned the same way. Nine steps plus the landing make one full turn, so the next flight's
  first step starts right where you step off the landing. Beside a floor, the spiral sits flush with the landing
  level with the floor's top. Q picks which corner the landing is on. Beside a foundation, it stands on the same ground.
- The red "can't place" ghost in the owner's screenshot came from "Someone is in the way": the owner stood on the
  landing below, inside the new flight's box. A spiral is mostly empty space, so now you only count as "in the way"
  if the steps would actually go through you.
- A flight with another one on top drops its landing rail (it blocked the way on up) and its post top (it would sit
  inside the next post: rule 2, no shimmer). New `stairs_spiral_stacked` models for all 3 kits (an option in
  `spiral_layout.py`). The game swaps them in automatically and swaps back when the top flight is taken down.
- **F781, smooth climbing.** Measured first: the dwarf's body was already climbing quite smoothly. The jitter you
  saw was mostly the **camera**. The post and rails passed between the camera and the dwarf, and it popped in and out
  5 to 14 times per climb. Also, the camera height was glided on every drawn frame while the body only moves 60 times a
  second, so they kept slipping against each other. Fixes:
  - The slope and landing are now one seamless smooth sheet (the owner's idea).
  - The thin parts (post, rails, pillars) are on their own body the camera ignores. You still bump into them.
  - The camera glide now follows the physics steps.
  - The last half step rises to meet the landing, so there's no lip.
  - A step-up now glides the dwarf's picture up over about a tenth of a second instead of popping.
  - Only a wall in front counts as a step. Brushing past the post used to lift you 11 cm.
- New `tests/test_spiral_stairs.gd`:
  - smooth climbing at 3 distances from the post and 2 speeds;
  - a calm camera with the real dwarf;
  - snap rules;
  - a 3-flight tower built in the real cave through the referee, walked to the top, then taken down again.

**Mistakes and hurdles**
- Claude's first test walker called a `Dwarf.step_up` that doesn't exist. Fix: copied the dwarf's step-up into the walker.
- One script edit mixed tabs and spaces in a test file. Godot refuses that. Fix: rewrote the function with tabs only.
- Claude's first "load the stacked model" code loaded the whole model scene and never freed it (a small memory leak).
  Fix: free it after taking its mesh.
- Making the slope one smooth sheet still left a hop at the top. The landing was a 25 cm thick box, and its side edge
  caught the dwarf's side on the last step. Fix: the landing's top became part of the same sheet.
- The tower test's walker first fell through the cave floor at the start (the rock under the stairs is rough there).
  Fix: start it on the first step.
- Another chat's half-done edit in `blueprint_library.gd` (`var corner_out :=`) stopped some scripts compiling during
  one test run. Claude told that chat and didn't touch its file.
