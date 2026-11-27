## 2026-11-27 · Copper armour: four changes toward the picture (F914, round 14b)

**What we did:** Claude listed what still differs from the ChatGPT picture, and the owner picked all four groups:
- **Shine and dents:** smoother metal, hammer dents a third smaller and shallower, a few green rust specks in the deepest dents.
- **Helmet face:** one solid face plate with two eye slits, plus a longer nose guard. It stands out 1.4 cm instead of 3, so the brow band no longer sticks out like a hat brim.
- **Shoulders:** rounder caps, and bigger arm plates stacked further out like roof tiles.
- **Belt, knees, rims:** a thicker belt, a big square buckle, wider and higher rims on every plate, and bigger knee plates (built in dwarf_armor.py, so armor_copper.glb was rebuilt too).

**Mistakes and hurdles:**
- The first try at shine (metal 0.85, roughness 0.2) mirrored the dark room, and the copper turned grey. Metal 0.72 with roughness 0.24 keeps the copper colour and still gives bright spots.
- A bigger shoulder cap (0.14 × 0.115 m) stood 9 cm off his shoulder like a wing, the same problem as round 13's flaps. The cap kept its size and only got rounder.
- In the dwarf test file, 5–6 checks failed (braid tufts on the bare dwarf, stun meter, camera, fists). They don't use the armour, and other chats had uncommitted game-code changes at the time. The armour fit test passes.
