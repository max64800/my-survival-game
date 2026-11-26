## Nov 26 — F914: the copper helmet and chest, hand-built as real metal plates

**What we did:** The picture-made copper armour (from ChatGPT pictures turned into 3D by Hunyuan3D) can't ship,
because its licence bans the EU, the UK and South Korea. So Claude built a new helmet and chest by hand (by
script, in Blender) that copies the pictures' look.
- **New builder:** `tools/asset_forge/builds/copper_plate_armor.py` → `assets/characters/dwarf/armor_copper_plate.glb`.
  Each plate is a thin, stiff sheet laid on the dwarf. Rays shoot in from outside to find his body. The sheet
  rests on the highest bumps and is smoothed, so it never dips in. Then it gets real thickness, a small polished
  bevel on every edge, a raised polished border, and domed rivets. No soft "clay" shapes this time.
- **Pieces:** a breastplate with a pointed bottom, tucked behind the beard, and the back in two layers. Side plates
  reach up into the armpits. A collar, a leather belt with a copper buckle, and three rows of skirt plates that
  overlap like roof tiles. Shoulder caps with three plates down each arm. Under all of it, a dark leather layer:
  a copy of his shirt, 4 mm bigger, so no cream shirt shows anywhere.
- **Helmet:** one shell turned round his head, so both sides are always the same. It has a slightly pointed top,
  a flared neck guard, a face opening, two eye holes, a nose bar, a riveted brow band, a riveted ridge over the
  top, and a band round the bottom edge.
- **New picture:** `tools/art/make_hammered_copper.py` draws a hammered copper texture: round dents in a
  honeycomb, each a little different, lit from the top left. The tile covers 32 cm of armour.
- **Game:** `DwarfRig.armor_look` (`plate` / `pic3d` / `old`) replaces the old on/off test switch.
  `tools/shot_armor.gd` now shows the picture-made dwarf beside the plate dwarf. The animation exporter takes `look=`.
  The comparison page (v3) now shows the picture-made armour vs the new plates.

**Mistakes and hurdles:**
- **Plates floating up to 60 cm away (Claude).** Claude guessed his middle line from the middle value of the shirt
  points at each height. At some heights most points were on his back, so the "middle" jumped to his back, and
  the plates were laid out from the wrong spot. Fix: use halfway between his front and his back.
- **Grey patches on the chest (Claude).** The leather under the plates showed up shiny light grey in the game.
  Claude made it bright green as a test, which proved the grey was the leather itself. The cause: Blender colour
  numbers are "linear", so 0.17 looks like a light greyish brown on screen, not dark. Fix: 0.03 (properly dark).
  Removing the shirt's vertex colours didn't change it. That was a wrong first guess.
- **Blotchy leather (Claude).** The quilted-leather picture laid on the shirt's picture layout came out as random
  blotches. Fix: plain dark leather.
- **Shoulder plates buried (Claude).** Two plates over the shoulder blades sat inside the back plate. Fix: the back
  became two overlapping layers (upper outside, 1.4 cm apart, so no shimmer).
- **Wings (Claude).** A plate across the top of each shoulder stuck up like wings, because its front and back ends
  found no body under them. It was taken out, and the dark leather shows there for now.
- **Page check:** the browser tool didn't connect, so Claude couldn't screenshot the page itself. The owner said it
  "couldn't load" at first, but later it loaded fine (the owner sent a screenshot).
- **Tests:** the quick suite showed 17 failed checks, but Claude only kept the last lines, so only one was seen: the
  old, unrelated `test_skeleton_miners.test_miner_numbers`. Lesson: save the whole test output to a file. The next
  chat re-runs the suite.

**Owner on round 6 (page v3):** "I like picture made more but we need texture of #2 on picture made." Asked which
parts: "everything, shape, color, details, just texture needs to be adjusted". Chose: copy its shapes by hand (it can't
ship), keep the hammered texture.

**Left (old line):** the owner's look at the page. When the owner OKs it, remove the picture-made pieces, their CREDITS rows
and the `pic3d` look.
