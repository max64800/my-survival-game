# 2026-11-22 — Dungeon 3 boss & knockdown fixes (F659, F660, F661, F662)

## What we did

Fixed four problems the owner found while playtesting Old Pell's Diggings.

---

### F659 — Can't hit knocked-down skeletons; medium ones teleport

**Root cause 1 (small skeletons couldn't be hit after knockdown):**  
Small skeletons (Bone Rot, 26 HP) could die from a single finisher blow. The
code called `start_knockdown` AFTER `_hurt_monster` — but `_hurt_monster` had
already killed the monster and removed it from the dictionary. The monster's
animation fell to the floor (the death-fall anim), but `is_alive()` was `false`,
so the player could never land another hit on it. It looked alive but was
effectively a ghost.

Fix: added `m.is_alive()` guard before `start_knockdown` in `monster_manager.gd`
(line ~594). Dead monsters skip knockdown entirely — no confusing floor pose.

**Root cause 2 (medium skeletons teleport):**  
Every hit called `m.knock()` (a physics push) even when the monster was already
knocked down. While knocked down, `collision_layer = 0`, so the player could walk
right into the monster. When the daze expired and `collision_layer` was restored,
physics shoved the player out instantly — this was the "teleport" look.

Also, `creature_rig.hit()` could play the flinch animation on a knocked-down
skeleton: `knocked_down=true` sets `_busy_kind="hit"`, which passed the old guard
`_busy_kind != "hit"` → false → flinch ran, snapping the skeleton back to a
standing pose for one frame.

Fixes:
- `_hurt_monster` skips `m.knock()` when `m.rig.knocked_down` is true.
- `creature_rig.hit()` early-returns when `knocked_down` is true.

---

### F660 & the spin-push — Boss spin too fast and pushes the player

`whirl_speed = 2.6 m/s` during the spin chain. That's nearly as fast as a walking
dwarf (3 m/s). The boss would drift into the player quickly, pushing them with his
collision capsule. Felt frantic, not menacing.

Fix: `whirl_speed` reduced from `2.6` to `1.5 m/s`. The boss now drifts toward the
player slowly during the spin — the player can step aside comfortably — and the
collision push is small enough to not throw the player off.

---

### F661 — Sci-fi clink still during spin

The earlier F647 fix changed the clink *pitch* from 2.3 to 1.0 (natural), but the
underlying `clink_*.ogg` audio files were still the original Kenney synthesizer
pings. Even at pitch 1.0, a synth ping still sounds like a beep.

The `block_*.ogg` files had also never been regenerated (the original
`make_combat_sounds.py` only covered hit / hit_heavy / parry / swing).

Fix: added `clink` and `block` sound generators to `tools/art/make_combat_sounds.py`:
- **clink**: very brief inharmonic metal tap (5 partials, fastest decay ≤ 14 ms,
  noise-modulated sine waves so no pure beep quality, plus a 3 ms transient click).
- **block**: dense wood-and-leather thud (120–500 Hz main body, 500–1800 Hz leather
  snap, no long ring — a plank shield absorbs, not resonates).
Ran the script; all 6 × 4 ogg files written.

---

## Mistakes and hurdles

- **F659 root cause 2 had two parts**: I initially only planned the `m.knock()` skip,
  but then noticed the `creature_rig.hit()` flinch guard would also fire (the
  `_busy_kind="hit"` set by `knock_down()` was the same tag used to allow flinches).
  Added the `knocked_down` early-return in `hit()` as well.

- **Clink sound**: spent time looking at `sfx.gd` and `monster_manager.gd` to find
  the sci-fi source. The actual culprit was simply that the .ogg files had never
  been regenerated — only the pitch changed. Should have checked the audio
  generation script first (took two hunts to get there).

---

## Files changed

- `src/combat/monster_manager.gd` — `is_alive()` guard before `start_knockdown`; skip `m.knock()` when knocked down
- `src/combat/creature_rig.gd` — `knocked_down` guard in `hit()`
- `src/combat/monsters.gd` — `whirl_speed` 2.6 → 1.5
- `tools/art/make_combat_sounds.py` — added `clink` and `block` sound generators
- `assets/sfx/clink_0–3.ogg` — regenerated (organic inharmonic tap)
- `assets/sfx/block_0–3.ogg` — regenerated (wood-and-leather thud)
- `FEEDBACK.md` — added F659, F660, F661 (all fixed)
