## Nov 22 — Ghost maces: same length as the Wrathful Shade's, thicker stick, bigger head (F664)

**What we did:** The owner liked the Wrathful Shade's mace length, but wanted its stick thicker and its head bigger. The
Bearded Shade and the boss get exactly the same mace (theirs was "way too long, the end way too small").
- `Ghost.MACE_SHAPE` now has four numbers per ghost: length, stick thickness, head width, head length.
  `reshape_mace` sizes the fins and head on their own (before, the head shrank with the stick, which made it tiny).
  Wrathful, Bearded and boss: [1.6, 0.8, 1.35, 1.25]. Drifting unchanged.
- The page's `reshapeMace` matches. The mace test now checks that the Bearded Shade's mace is the same as the Wrathful
  Shade's, and that its head is big.
- The owner still finds the bodies "very, very fat" but wants to try them in the game first (F673).

**Hurdles:** none this round. The earlier mistake behind this round: Claude thinned the whole mace by one number, so the
head shrank along with the stick, and the longest mace ended up with the smallest-looking head.
