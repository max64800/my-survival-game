## 2026-11-24 (PC) — Prow Hall rebuild no longer gets stuck (F819)
- **What we did:** found why the stone rebuild test stopped with "Waiting: something is in the way": 4 tower walls
  at 3.25 m (on the ring towers' odd sides) were never built, and the hall floors above waited for them.
- **The cause:** a ruin is placed all at once ("batch"). At the end of a batch the game only worked out how strong
  each piece is if something had been taken down. So every Prow Hall piece had strength 0. Normally that didn't show,
  because rebuilt pieces near the ground spread strength upwards. But these towers had nothing missing below 3.25 m,
  so no strength ever reached that wall, and a wall touching only "strength 0" pieces can't be built.
- **The fix:** `Builder.end_batch` now works the strength out once when pieces were added (nothing falls from it).
  New test `test_placed_ruin_has_its_strength` (no weak piece after placing, and the 4 walls can be built).
  Lesson written as RUIN-RULES 7.7.
- **Hurdles and mistakes:**
  1. My earlier offline copy of the rebuild said everything was fine, because it worked strength out piece by piece
     as it added them, unlike the game. Lesson: copy what the game really does, or print the real numbers in the game.
  2. The rebuild test takes about 35 minutes, so I wrote a 40-second probe that only places the ruin and prints the
     pieces round one stuck wall. All of them showed strength 0.00, which gave the answer.
  3. My first new test looked for the walls in the rebuild plan, which doesn't exist yet right after placing. I used
     the wall one storey up (same turn) instead.
  4. The full test run (54 min) showed a side effect of the Prow Hall's move to a natural cave (layout 19): one
     cave got 3 boulders. Two caves overlap there, and the shifted dice put a neighbour cave's boulder inside it. New
     worlds (layout 19) now skip a boulder spot that sits deeper inside another cave than its own; old worlds keep
     their boulders. `test_few_boulders_by_the_walls` passes again.
- **Full suite:** every Prow Hall test passes, including the 35-minute stone rebuild. Still failing, not ours: the
  sword-digs test (combat chats' unsaved work), the tower ground keep-clear test, robot saves, miner numbers, and one
  Jolt "too many bodies" error in the wood test.
