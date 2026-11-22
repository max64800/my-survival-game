## Nov 22 — Slimmer ghosts (F673)

**What we did:** The owner said the ghosts were "still very fat" and asked to fix the bodies before the maces (the
Bearded/boss mace is now too long with too small a head; that comes next).
- `tools/asset_forge/builds/ghost_body.py` got a "slimmer" step after the sculpt: the middle and the hood 20% narrower
  and 18% shallower, the sleeves 20% thinner and stretched a little so the wrists stay at the hands, the fists 15%
  smaller round their own middle. All three looks rebuilt in Blender, the page's copies remade from the new models.
- In the game the ghost no longer gets the dwarf's extra 20% width (`Ghost._dress` divides it out), so the game
  matches the 3D page.
- New test `test_the_ghosts_are_not_fat` (size limits the old bodies would fail).

**Hurdles:**
- The script that once turned the models into page files wasn't saved anywhere. Claude rebuilt it from how the page
  reads them (glTF text with the data in two base64 text files); the byte counts matched the old files exactly.
- Claude's first size limits in the test were wrong: the box includes the arms held straight out (the rest pose).
  The limits were set from the real numbers instead.
- Blender warns "mesh ghost_a_body is not valid" during export. The model still imports and shows fine; not looked into further.
