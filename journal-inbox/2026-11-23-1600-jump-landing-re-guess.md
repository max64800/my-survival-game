## Nov 23 — The jump animation fix wasn't actually fixed (F798, F807)

**What we did**
- F798 came back: the owner said "still the same thing... he jumps lands and if it a long jump he just sprints to
  the next stop." The earlier fix (stretch the jump pose to a predicted hang time) only guessed once, at the moment
  he left the ground, assuming he'd land back at the exact same height — true on flat ground, wrong for a real
  running jump across a dip or up onto a rise.
- New fix in `src/player/dwarf.gd`: every physics tick he's airborne, cast a ray straight down to find the real
  ground below him right now, and re-work out how much longer the fall will take from there (`_jump_hang_guess`).
  So the guess keeps catching up to reality instead of being stuck with the first guess.
- Built a new debug robot, `src/debug/jumpcheck.gd`: makes the dwarf sprint and jump, prints the guessed hang time
  every tick next to where he actually is, and takes real screenshots at launch/mid-air/landing so the pose can be
  checked by eye, not just by numbers. Ran it (`jumpcheck claude=... seed=42 shots=...`) and confirmed the live
  guess stayed within about a tenth of a second of the real landing time for the whole flight.
- New test: `test_jump_hang_guess_accounts_for_landing_lower_than_launch` (checks the ray-based guess against a
  real 4 m drop, and that it's longer than the old flat up-and-down guess).

**Hurdles and mistakes**
- First hand-written patch to split my change out of `src/player/dwarf.gd` (see below) failed with
  "corrupt patch" — I miscounted which line a variable actually sat on by hand. Fixed by never hand-counting again:
  pulled the committed version with `git show HEAD:<file> > base.gd`, made a copy, applied my edit to the copy with
  the normal editor, then let `diff -u` work out the line numbers for real.
- Another Claude session had been working in the same two files (`src/player/dwarf.gd`, `tests/test_dwarf.gd`) at
  the same time, on a different, unrelated feature (sprint feel and camera collision, F775/F766), not yet
  committed. Committing those files whole would have swept up their unfinished work under my commit. Used
  `git apply --cached <patch>` to stage only my own hunks into the index, leaving their changes untouched and
  unstaged in the working tree for them to commit separately.
- While isolating my test, found a small pre-existing bug already sitting in the committed code: the test right
  before mine ended with `root.queue_free()` written twice in a row (harmless, just redundant). Fixed it in passing
  since I was already editing that exact spot.
- The debug robot's own first diagnostic print line looked wrong ("expected hang 0.00 s" right at takeoff) — turned
  out to be the print reading the value one tick too early, not a real gameplay bug (it recovered within a tick or
  two, and later runs with a per-tick printout the whole way showed it was never actually wrong). Left as is since
  it's only a debug tool, not something players see.

**Play-test:** a running jump across a real gap — the character should keep moving (legs still mid-air, not
snapped to a running pose) until he actually lands on the far side, however long that jump really takes.
