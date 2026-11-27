## 2026-11-27: Copper gauntlets, built the F914 way (F914)

**What we did:** The copper helmet and chest were OK'd, so the gloves came next. Before this, the hands still wore the
old gauntlets from the first hand-built set. Now `tools/asset_forge/builds/copper_plate_armor.py` builds new ones the
same way as the chest:
- hammered copper with black edges and copper rivets
- three forearm bands that flare out at the cuff
- a round elbow plate
- a plate on the back of the hand, plus a knuckle plate
- a small plate on every finger joint
- under the plates, a brown leather glove and a leather sleeve (copies of the hand and forearm skin, pushed out a few
  millimetres)

The gauntlets travel inside `armor_copper_plate.glb` (`armor_chest_gauntlet_*`). The game now takes them from there
(`dwarf_rig.gd:_wear_armor`), and the old helper `_add_built_meshes` is gone. The gauntlets are built after the helmet,
so the random numbers for the helmet and chest don't change. Their face counts match exactly, so the OK'd pieces stayed
the same.

Checks:
- `test_hand_built_armor_fits_the_body` passes.
- `test_dwarf` has 48 checks: 43 pass and 5 fail. The 5 failures were already known and have nothing to do with the
  gloves (braids, aim, stun meter, camera, fists).

The 3D page (v23) now shows old vs new gauntlets, with a "Hands close" view.

**Mistakes and hurdles:**
- **A Python edit failed on line endings.** The files on disk use Windows line endings (CRLF), so the search text
  didn't match. Fix: change them to LF, edit, then write CRLF back.
- **Stretched copper picture on the bands.** The band's length was measured in radians (angle units), not metres, so
  the hammered picture was pulled into stripes. Fix: measure around the arm in metres (2π × 5 cm).
- **Pink skin at the elbows and under the arms.** The plates left gaps when the arm bent. Fix: a leather sleeve copy of
  the forearm skin.
- **The hands looked tiny next to the picture.** Fix: a puffier glove (4 mm), and wider, thicker finger plates.
- **Too many faces (61k).** Fix: fewer rings on the small plates, which brought it down to 52k.
- **The page check failed.** The test browser wouldn't connect (it timed out twice), so I couldn't screenshot the page
  myself. The model had already passed two rounds of game screenshots.

**Next:** the owner's verdict on the gauntlets, then the bronze set, made the same way.
