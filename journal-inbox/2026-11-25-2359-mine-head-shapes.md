## Nov 25: Ruin 12 Mine-head Works, the idea round and the shape page (F899)

**What the owner chose (multiple-choice round):**
- Layout "ledge + trestle": the stone engine house with its back in the rock, the wooden headframe over the shaft in
  front of it, cart rails on a tall wooden bridge (trestle) over a dip to an ore shed on a lower ledge.
- A shaft you can climb down: about 8 m, ladders, a mine room at the bottom with the best chest.
- A new building piece, the **Head Wheel** (Shack wood), so players can use it too. Looks only for now (no working lift).

**What we did:**
- Found that rails and carts already exist as decor models (`rail_track`, `mine_cart`, a derailed cart), so only the
  wheel needs a new piece.
- Made the simple shape page `docs/design/ruin12/minehead_shapes.html` (copied from Brickcrown's): plain blocks,
  buttons for the views, "See underground" (the ground turns see-through to show the mine room) and "Rock wall off".
  The headframe changes shape 3 times on the way up (wide base with a loading deck, thinner braced middle, wide top
  deck on brackets, then the wheel under a small sloped roof), so it is never a plain square tower (F656).
  Built into the cave (F657): backs in the rock, two floor levels plus the mine room, a bridge over a dip, stairs cut
  into the slope.
- Page: https://claude.ai/artifact/G8K4FjTZYpdf6xPypeXUoW

**Mistakes and hurdles:**
- The F899 line in FEEDBACK.md had never been committed (it was only in the working copy), and another chat had its
  own staged FEEDBACK edit. I committed the F899 line through a separate scratch index from HEAD and then put the same
  line into the real index too, so the other chat's staged work stayed untouched.
- Python printing the 🛠 emoji crashed on Windows (cp1252); fixed with `PYTHONIOENCODING=utf-8`.
- My first "Down the shaft" camera was too close to see the room; moved it back after the first photo.

**Next:** the owner's OK on the shapes, then the Head Wheel piece (Blender, MODEL-RULES), then the blueprint.
