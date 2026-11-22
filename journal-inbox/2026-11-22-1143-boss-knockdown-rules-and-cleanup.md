# 2026-11-22 — Boss knockdown hard rules and mine 3 cleanup (F645–F653)

## What we did

Continuing from the previous session (knockdown system, sci-fi sounds, foreman fixes). The owner tested mine 3 again and found eight more issues. We fixed six of them in this session.

### F645 — Remove the Pit Boss's Great Chop

Deleted the `{name = "Great Chop", anim = "2H_Melee_Attack_Chop", ...}` entry from the foreman's `attacks` array in `src/combat/monsters.gd`. The boss now only has Pick Whirl. Updated the comment block to reflect the new design.

### F646 — Red outline gap during multi-spin

The `_red_outline()` method in `monster.gd` creates a timer to clear the outline after `seconds + 0.1`. On the second follow spin, it called `_red_outline(0.9)` again, but all meshes already had `material_overlay` set, so no new mesh was collected — and the first timer at t=1.07s fired and cleared the outline. The second call collected nothing, leaving a gap.

**Fix:** Added `var _outline_gen := 0` as a member variable. Each `_red_outline` call increments the generation counter. The clear callback only fires if `gen == _outline_gen` — so old timers are silently cancelled when a newer call takes over. Also changed the apply loop to set `material_overlay` unconditionally (re-applying to already-set meshes) so follow turns collect all visible meshes.

### F647 — Sci-fi clink sound

`creature_rig._glint_later()` was playing `Sfx.play("clink", at, -3.0, 2.3)` — 2.3× pitch sounds like an electronic beep. Changed to `1.0` (natural pitch).

### F649 — Exit lever works while boss alive

`dungeon_keys.request_pull_lever()` had no boss check. Added a loop over `auth.monsters.monsters` looking for any monster where `data.get("boss", false)` and `dungeon.get("id", "") == dungeon_id`. Returns "The boss still lives." if one is found.

### F651 — Can't walk through knocked-down enemy

The `CharacterBody3D` capsule stays at standing height even when the visual falls to the floor. Fix:
- In `start_knockdown()`: `collision_layer = 0` after `rig.knock_down()`.
- In `think()` stun block: `collision_layer = 0` when `rig.knock_down()` is called.
- In both `get_up()` call sites (`_kd_daze` end and `State.STUNNED` end): `collision_layer = MONSTER_LAYER` to restore after the creature gets up.

### F652 — Boss attacks/spins while knocked down

Two hard guards added:
1. `creature_rig.attack()`: `if knocked_down: return` right after the `dead` check. This blocks the animation on ALL clients including the host.
2. `monster._start_attack()`: `if rig != null and rig.knocked_down: return` at the very start. This stops the host from even sending the attack RPC, so no damage registers either.

### F653 — Skeleton rock burst too big

`Statue.remove()` calculated `size = clampf(dims[1] / 1.6, 0.3, 1.3)`. A lying skeleton spans ~1.9m → `size ≈ 1.19`, near-maximum. Added:
```gdscript
var max_size := 0.4 if c.has_meta("bone_box") else 1.3
```
Skeleton miners set `has_meta("bone_box")` via `Statue.from_rig`, so they now produce small rocks (capped at 0.4). Other creatures (beetles, etc.) keep the old 1.3 maximum.

## Still open (needs in-game investigation)

- **F648** — Boss stuck in elevator: nav mesh around the shaft opening.
- **F650** — Exit lever floats when elevator goes up: can't determine root cause from code alone; lever blueprint pos [41.2, 0, 46.15] is a separate node from the platform.

## Mistakes and hurdles

- Spent time searching for how the lever floats — read through mine_traps, dungeon_build, blueprint JSON. The lever is definitely a separate StaticBody3D child of DungeonBuild, not parented to the platform. Couldn't find the bug without running the game. Marked for in-game investigation.
- The `_red_outline` generation counter approach required understanding why the second `_red_outline` call collected an empty mesh list (meshes already had the overlay). Root cause: the original code only collected meshes where `material_overlay == null`. Fixed by removing that filter and collecting all visible meshes every time.
