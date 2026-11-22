# Session: F624/F625 follow-up fixes + sci-fi sound removal + boss telegraph

**Date:** 2026-11-22  
**What we worked on:** Fixing everything the owner found while play-testing the knockdown system in Old Pell's mine 3.

---

## What we did

### Can't hit knocked-down enemies (the main blocker)
When the finisher combo sends an enemy flying (knock force 14.0 m/s), the physics body slides **7 metres** away before stopping.
The player only had a 2.5-second floor window, but the monster was halfway across the room.  
Fix: in `start_knockdown()`, cap `_knock` to 6.0 m/s. That limits the slide to **~1.3 metres** — still a satisfying thump, but the monster stays close enough to follow up on.

### Stars while knocked down
Added the `rig.knocked_down` check to `_daze_stars()` so stun-stars are hidden while the enemy is on the floor.  
*(Done in the previous half of this session — recap for completeness.)*

### Attacking while getting up
`creature_rig.attack()` now returns early when `_busy_kind == "rise"` — the monster finishes rising before it can swing.  
*(Also done in the previous half.)*

### Teleport after knockdown
Reset `_no_progress = 0.0` when `get_up()` is called, so the monster doesn't immediately hit the "making no progress → teleport home" timer right after standing up.  
*(Also done in the previous half.)*

### Boss "hip swing" — untelegraphed follow-spins
The Pick Whirl's follow hits had `tell = 0.5 s`. With `again=true`, the animation jumps straight to the spinning portion (WHIRL.x = 0.62 s). The pick glint only shows **0.1 s** before the blow — essentially no warning.  
Fix: raised all four follow tells from `0.5` to `0.9 s`. The glint now appears **0.5 s** before each blow — matching the first spin's 0.57 s warning. Total whirl duration goes from ~3 s to ~4.6 s (boss chases you for longer).  
Test updated: `check_near(total, 4.57, 0.5)` and the whirl_speed band widened from 0.8×WALK to 0.5×WALK (to tolerate future WALK_SPEED tuning).

### Boss not destroying furniture
Traced through `attack_smash_things`: the code is correct, but the nearest SMASH-list prop to the foreman is a **crate on a different floor** (y = 0.25 vs foreman y = −5.75 → 6 m above, fails the 2 m y-check). Same-floor crates are 7 m away (beyond his 2.3 m reach).  
Fix: added 4 breakable props to `blueprints/dungeons/old_pells_diggings.json` near the boss arena corners (keg, crate_stack × 1, barrel_rack, grain_sacks — all within 5 m of the arena centre, keeping paths clear).

### Sci-fi sounds removed
Removed three `Sfx.play("swing", ...)` calls from `dwarf_fight.gd` (player weapon swing, shield bash, crossbow).  
Regenerated `hit`, `hit_heavy`, `parry`, and `swing` as organic medieval sounds using `tools/art/make_combat_sounds.py` (bandpass noise + fast-decaying inharmonic resonances — no sustained pure tones).

---

## Mistakes and hurdles

**Slide distance miscalculation.** I capped `_knock` at 10.0 then changed it to 6.0, but I initially didn't realise the monster was physically sliding 7 metres because the `_knock` decay runs in `_move()` BEFORE `_kd_daze` returns early. Once I read how `_knock` integrates, the right cap was obvious.

**Test expected value was stale.** `test_foreman_whirl_chases_and_lost_miners_leap` checked `total ≈ 2.97 s` — exact for the old 0.5 s tells. After raising to 0.9 s the total is 4.57 s. The whirl_speed band was also written for the old `WALK_SPEED = 4.0` (would have been 2.6 > 3.2 → false). Both fixed.

**Furniture check hunt.** `attack_smash_things` is defined once and called once; the trace was fast. The real issue was dungeon layout data — needed to load the JSON and do maths on positions to find that the nearest smashable prop is on the wrong floor entirely.
