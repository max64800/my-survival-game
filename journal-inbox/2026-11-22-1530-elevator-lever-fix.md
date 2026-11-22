## 2026-11-22 — F648/F650: elevator and lever repositioned in Old Pell's arena

### What we did
Two leftover fixes from the mine-3 playtesting session that were still uncommitted:

**F648 — Boss stuck on the elevator platform.**  
The lift platform sat at the center of the boss arena (x=45). The boss is about 1.5 m wide and the shaft of the platform plus its railings filled the gap he needed to walk through. He kept running into it and stalling.

Fix: moved the platform 3 m toward the right wall — from `[45, −5.96, 47]` to `[48, −5.96, 47]` in `blueprints/dungeons/old_pells_diggings.json`. The deck is 1.5 m wide, so its edge is now at x=47.25; the boss has a clear 11 m path on the left side of the arena.

**F650 — Exit lever floats when the elevator rises.**  
The lever that calls the lift was at `[44, −6, 47]`. The platform spawns at `[45, −5.96, 47]` — same z, one unit over. They looked visually connected. When the platform rose to y=0.04, the lever stayed at y=−6 and appeared to be floating.

Fix: moved the lever to `[48, −6, 44]` yaw=270 (facing into the room from the right wall, 3 m away from the platform in z). It is now clearly attached to the wall rather than the platform, so when the platform rises the lever looks correct.

Also committed: a bat turn test added to `tests/test_monsters.gd` for F630. The test removes the cave bat from the shared turn loop (bats bank into curves, they don't stop-and-turn like beetles), then checks separately that a quarter-turn takes 0.4–1.2 s and that the bat accelerates gradually rather than snapping to full speed in one frame.

### Mistakes and hurdles
None. The fix was identified last session — the JSON was already edited. This session just verified it and committed.

### How it was fixed
Edited `blueprints/dungeons/old_pells_diggings.json` directly (two prop entries). No code changes needed: the platform's `AnimatableBody3D` collision is built at runtime from its blueprint position, so moving the pos in JSON is enough.
