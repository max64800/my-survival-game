## Nov 26: copper armour round 2, real metal (F914)

**What we did**
- The owner said round 1 "looks like a recolor leather". So: a new ChatGPT picture first (closed copper helm with a nose
  guard and eye slits, plate bands on the belly, metal gloves, metal boots). The owner picked "build this".
- In `tools/asset_forge/builds/dwarf_armor.py` a set can now say `hard=True`. Then the plates are no longer soft domes that
  follow the leather. Each plate is its own stiff shell: flat face, sharp sides, a thin bright bevel on the edge, a dark
  line in every gap. Bronze and iron only need a new SETS entry to get the same look.
- New shapes: a closed helmet (dome halves, brow band, crest, face guard, nose plate, cheek guards, neck guard, eye slits,
  rivets), belly bands that overlap like roof tiles, a plate skirt, layered shoulder bands, metal boots made of bands,
  and **gauntlets** (a new piece: palm shell, back plate, 4 jointed fingers, thumb, flared cuff, rivets).
- Game: `src/player/dwarf_rig.gd` now hides the bare hands while gauntlets are worn (like the helmet already hides the
  normal head), and shows them again when they come off.
- Leg armour stays the old simple shape (owner: later).

**Mistakes and hurdles**
- Chrome would not let Claude drive ChatGPT until the owner allowed remote debugging ("try now"). An old half-typed
  prompt was still in the ChatGPT box and had to be cleared first.
- First try of the shoulder guards: three stacked balls. From the front they melted into one round blob. Fix: three
  flat bands (each a little further out than the one above), like the belly bands.
- The bake loop paints colour from one shape grid, but the hard plates are joined from many grids (helmet cells, crest,
  nose plate, boot rings, fingers). Fix: `hard_tint` looks each point up in every grid and takes the closest plate.
- Thumb and fingers in one shape would have glued together; the thumb got its own grid at a slightly bigger gap so the
  two surfaces never sit in the same place (no shimmer).
- Blender said "Mesh is not valid" on export for the joined plates. Fix: each piece is cleaned (`validate`) before export.
- First edit to the rig file failed: the file's tab depth was one less than it looked in the reader. Checked the real
  tabs and redid it.
