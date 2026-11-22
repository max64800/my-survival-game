## Nov 22, 2026: the Drifting Shade gets its details, its float and its smooth swing (F642, Claude 3)

**What we did**
- The owner's second look at the first ghost: "we're on the right track". They liked the swing. They wanted a triangle hood
  opening, smaller eyes, no mace held up, lots more detail "like the mace", a button to watch it float towards you,
  moving hands while it floats, and no snap back to the T-pose after a swing.
- Model (`tools/asset_forge/builds/ghost_body.py`, look a):
  - a rounded-triangle face opening with a rolled rim around it;
  - smaller eyes;
  - a seam over the hood with cross-stitches, and creases fanning out from the opening;
  - 14 cape folds, 70 shallow dents and a fine lumpy surface;
  - loose threads at the cape tears;
  - stitched patches, a rune stone on a cord, a leather pouch, and his old pick tucked in at the back.
- 3D page (`tools/dungeon_pages/ghosts_page.html`):
  - a "Float to you" button: it fades in further back, glides slowly at you with a bob and a lean, then swings;
  - the arms and head sway while it floats;
  - after a swing it eases back to its pose over 0.6 s;
  - the mace is held low.
- Game: the new `ghost_a.glb` is in `assets/models/creatures/`. The ghost tests pass (5 checks).

**Mistakes and hurdles**
- The back patch was placed right on top of the pick head and made a messy lump. Fixed: the patch moved to the shoulder blade.
- The pick sat on the cape's edge and didn't show. Fixed: moved lower and made thicker.
- The first dents were too deep and looked like holes. Fixed: made them shallower.
- Claude's mistake: one update went to a **new** page link instead of the owner's page. Fixed: this round went back to the
  original link, and the owner was told.
- The browser tab Claude tested in was taken over by the owner's own search. Fixed: Claude opened its own background tab,
  closed it after the test, and left the owner's tabs alone.
