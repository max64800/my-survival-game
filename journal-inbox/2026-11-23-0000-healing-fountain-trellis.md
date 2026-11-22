## Nov 22, late: F782 healing fountain, round 3: the TRELLIS one wins

**What we did**
- The owner liked the TRELLIS fountain shape better than the one Claude built by hand, and asked for it to be fixed up
  instead: lighter, no water, crystals in the basin. That breaks model rule 1 (no picture-to-3D as the final model), so the
  owner made a one-time exception for F782. It is written into `docs/art/MODEL-RULES.md` rule 1.
- New script `tools/asset_forge/builds/healing_fountain_trellis.py` takes the TRELLIS model and:
  turns it to face the front, sizes it to 1.2 m tall, brightens its paint a lot, cuts out every water face (found by their
  minty colour), cuts it from 65k down to about 17k triangles, fills the basin with a pebble bed and our glowing green
  crystal clusters, and puts a small crystal in the mouth. Passes the model checks.
- The 3D page now shows: the old mushroom fountain, TRELLIS straight out of the box, and the reworked one.
  Still not in the game.

**Mistakes and hurdles**
- First build came out shredded like torn paper (1,569 loose scraps). Why: Blender loads the TRELLIS model cut apart along
  its paint seams, and the triangle-cutting step then tore every seam open. Fix: glue the seams back together first
  ("merge by distance", it removed 16k doubled points), then cut triangles. Now it is one piece.
- Some darker teal water low in the basin wasn't caught by the colour test. Fix: a second, darker colour test for the basin only.
- The model faced sideways. Claude's first fix (setting the object's turn to 180°) did nothing at all, because it replaced the
  turn Blender adds when loading instead of adding to it. Fix: turn the points themselves after loading.
- A dark hole was left at the back of the basin. Fix: made the crystal bed a bit wider than the old water.
