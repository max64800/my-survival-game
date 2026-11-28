## Nov 28 (night): bare dwarf, shorter fingers, beard top, shirt back (F943)

**What the owner asked (3 pictures):** the fingers are too long; the top part of the beard braids still hardly moves;
black spots on the back of the T-shirt when he runs.

**What we did:**
- **Fingers:** each finger is 20% shorter past its knuckle (`FINGER_LEN = 0.8` in `dwarf_body.py`). The thumb stays as it was.
- **Beard top:** the braids now switch from "glued to the face" to "swinging" over 5 cm instead of 7 cm
  (`BRAID_BLEND`), and the braid chain is 95% free right at the top (`hair_swing.gd`, `loose_min 0.95`).
  A new check in `test_braid_tufts_swing_when_moving` makes sure the braid's upper part moves too, not only its end.
- **Black spots:** the painted-in shadows were made with every part in the scene. So the shirt shaded the body and
  shorts under it almost black, and the hair left dark smudges on the shirt. When the shirt moved, those black bits
  showed. Now each part only shades itself (`ao_local=True`).
- **Skin poking through the back:** after the black spots were gone, little pink slits of skin showed through the
  loose shirt when he ran.

**Mistakes and hurdles (including Claude's):**
- **The skin cut never worked.** `DwarfRig._hide_skin_under_shirt` stores the shirt's points in a dictionary of
  small boxes. In Godot a packed array read out of a dictionary is a *copy*, so `(cells[k] as PackedVector3Array).append(p)`
  added to the copy and every box stayed empty. It cut 0 triangles. Claude first made the cut "deeper" twice and
  saw no change before printing the count and finding it was 0. Fix: read the box out, add the point, put it back.
  It now hides about 11,000 skin triangles.
- **Once the cut worked, you could see into the sleeves** (empty inside). Fix: keep the skin within 7 cm of the shirt's
  openings: sleeve ends, collar and hem (`SKIN_KEEP_AT_OPENINGS`).
- **The deeper cut (8 cm) covers only the belly and back** (`SKIN_COVER_LOW`, below 0.9 m and within 28 cm of the middle,
  since the body is built with the arms straight out). The neck and arms keep 4.5 cm.
- Claude first tried `AABB.expand` from an empty box to find the shirt's edges. It kept only the last point, so
  nothing was cut. Switched to a plain min/max.
- An export with `--headless` skips the skin cut (it only runs with a screen). The page export must run without it.
- Blender check renders with a relative path landed in `C:\shots`. Always give Blender absolute paths.
- Claude guessed the bake's ray reach (ext 0.025) caused the black spots. That changed nothing and was undone. The real
  cause was the shared shadows.

**Tests:** test_dwarf: the new beard-top check and the armour fit pass. The failures left (back-hair tip, aim_skips,
stun meter, camera slide, fist swings) were already written down as old or flaky by other chats.

**Page:** https://claude.ai/artifact/U4SNDGrwwpTHBuhrqfVaCp (version 2). Waiting for the owner's look.
