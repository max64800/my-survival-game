## 2026-11-26 11:50 · Bronze set on the dwarf (F697 step 7, round 2)

**What we did**
- You asked to see the new bronze set on the dwarf in 3D. I made a 3D page (dwarf + helm, mail, greaves, boots).
- You said "not good". You picked three problems: blocky shapes, it didn't fit him, and the colour looked like lava.
- Colour: the painted bronze sheet had big glowing orange dents. `tools/art/cut_bronze_textures.py` now has a
  `calm()` step: mostly a calm brown-gold, softer light and dark. The knot bands and medallion are calmer too.
- Fit + shapes: I measured the dwarf body slice by slice (belly, beard, shorts, legs, feet). Then I rebuilt
  mail, greaves and boots round his real body in `items_gear.py`, then shrank them to half size for the item (`to_item`).
  Now the chest is round like his belly. The beard lies over the chest and the medallion sits under it. There is a
  belt with a buckle, a chain skirt and four hanging thigh plates. The legs are fat quilted padding with round
  knee cups, and the boots are round his real feet.
- `tools/asset_forge/bronze_tryon.py` builds the dwarf-wearing-bronze model for the 3D page.

**Mistakes and hurdles**
- My first try-on stretched each item's box over the dwarf. The mail was built taller than wide, but he is very
  wide and short, so it turned into a box. The greaves were stretched over his shorts and looked like stacked
  rings. Fix: build the pieces round his body, so they only need a 2x scale.
- The beard poked through the medallion because the beard hangs in front of his chest down to his belly.
  Fix: medallion moved down under the beard (like the picture).
- His shins are tiny and the boots cover them, so the "greaves" became padded legs over his shorts with knee cups.
- The first fix made the "dark" bronze as bright as the normal one (the calm step evened them out).
  Fix: calm the whole sheet first, then darken.
- The hanging thigh plates hid the knee cups. Fix: shorter plates, knee cups a bit lower.
- Left: a little white shirt still peeks out under the armpits; the helm (TRELLIS) is still fitted by stretching.
