## Nov 27 — Copper armour, round 13 (F914)

**What we did.** The owner looked at round 12 on the 3D page and sent two pictures with four notes: dark curves
under the armpits, eye holes too deep, odd hair at the back, and braids that stand still while their rings move.
- **Braids:** the helmet's hair copy (with the braids) had been tied fully to the head bone, so it could never swing.
  The rings are a separate piece that still swung, which made the mismatch easy to see. Now the hair keeps its own
  swing bones. Only the hair inside the helmet stays on the head, fading back over 5 cm below the edge, and the hair
  hidden under the back plate moves with the chest so it can't poke out. I checked the recording: the braid bones turn
  during the walk.
- **Eye holes:** 4 mm deep instead of 12 mm.
- **Back hair:** the owner chose a neck guard (a multiple-choice question). The helmet's back edge now comes down to
  0.9 m, over the collar and the back plate's top, and the back hair is hidden inside.
- **Armpits:** the breastplate and back plate are 30% wider at their top corners only (a new `top_wide` setting in
  `plate()`), and the waist stays narrow.

**Mistakes and hurdles.**
- Two armpit tries failed: a separate plate over each shoulder top, then bigger side plates. Both stuck out like flaps,
  because a stiff plate fitted over the round shoulder lifts 8–11 cm. The log line "rigid ... lift 0.108" warned me
  before the picture did. Lesson: watch the lift number, since anything over ~4 cm will stick out. After 2 photo rounds
  I asked the owner, and they picked "wider at the top corners".
- My first neck-hair fix pressed the hair between the guard and the plate into a flat sheet, which looked torn. Lowering
  the guard further (0.925 → 0.9 m) left less hair to press.
- I froze my own shell with `cat > file` with no input (it waited forever) and had to stop it.
- The browser tool wouldn't connect, so I couldn't check the 3D page myself this time. The owner checks it.
