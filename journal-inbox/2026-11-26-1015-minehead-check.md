## 2026-11-26: Mine-head Works checked (F899 step 5)

**What we did**
- Reran test_ruin_minehead: all 7 checks pass, including the spot-search speed check that failed before.
- Ran a muted test game (claude=minehead ruintest=minehead): the ruin dug and built, and the chest rebuilt all 819 pieces in 2.5 s. No game errors.
- The owner chose: a mushroom (Fungal) cave is fine when no mossy one is free; keep the simple lift cage.

**Mistakes and hurdles**
- Rebuilding showed two "Blueprint learned" cards. The Mine-head uses one blueprint for both wood and stone, and the code teaches both. Fix: builder.gd teaches it once when the two are the same.
- The robot pictures came out too dark (the camera sat behind a hump of ground), so the looks wait for the owner's play test instead of more picture rounds.
- "RUIN_JUNK drawn: 0" looked like missing junk. It isn't: the newer ruins carry their junk as decor in the blueprint.

**Left:** the owner's play test, and the Brickcrown chat's commit (main needs it to compile).
