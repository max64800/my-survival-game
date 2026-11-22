# Nov 22 — Dungeon 2 (Old Pell's Diggings) combat fixes

After fixing Dungeon 3 and 4 issues earlier today, the owner playtested Dungeon 2 and reported several new problems
with the Foreman boss and the tunnel rats. This session fixed the ones that had clear solutions.

## What we fixed

**F674 — Tunnel rats standing at the hallway entrance (not rushing)**
The `landing` room (X 24–30) and `dig` boss room (X 36–50) had no named room between them — the gap at X 30–36
was unnamed space. The `may_step` function blocks monsters from stepping into unnamed space even when `chase_out=true`,
so the rats reached the room boundary and stopped there. Fixed by adding a `pell_passage` room (X 30–38, Z 38–48) in
`dungeon_map.gd` that bridges the gap.

**F675 — Foreman shoves the player without attacking**
The boss runs at 3.6 m/s and had no approach-distance limit, so he'd barrel into the player and keep pushing with his
collision shape. Fixed by adding `no_push = true` to the foreman entry in `monsters.gd` — the same flag the game
already uses for the Prop Warden boss. It makes him stop ~1.5 m away and wait for an attack window.

**F677 — Stun lasts too long (player helpless 2 seconds)**
`take_stun()` called `knock_down()` and left the stagger timer at the default 2 s, meaning the player lay on the ground
playing the full fall+rise animation before they could act. Fixed by setting `stagger = 1.2` right after `knock_down()` in
`dwarf_fight.gd` — the player now rises in ~1.2 s. Still a noticeable penalty, but not frustrating.

**F678 — Can't hit the Foreman while he's lying down**
Same root cause as F665 (Dungeon 3): `_impact` in `dwarf_fight.gd` used the arc check and standard reach for knocked-down
targets, but the collision shape is disabled during knockdown so `global_position` doesn't reflect where the body
visually is. Fixed by extending the fix already applied for F665: arc check skipped entirely for knocked-down targets,
reach extended by `height * 0.5`.

## What is NOT fixed yet

- **F676 — Foreman teleports back near the lift:** when the boss gets stuck on lift geometry for 3 s, the `no_progress`
  guard fires and he snaps home. Needs investigation — the threshold or path near the lift needs tuning.
- **F679 — Foreman should do other attacks:** F645 removed all non-spin attacks at the owner's request; now the owner
  wants variety back. Waiting for owner OK before reversing that decision.
- **F680 — Foreman turns red but doesn't spin:** mid-chain spins may be interrupted, leaving red on with no attack.
  Needs investigation of the generation counter and chain-interrupt path.

## Mistakes and hurdles

- The pass room fix required reading dungeon_map.gd carefully to pick coordinates that actually bridge landing→dig
  without overlapping dig_door or seam rooms.
- Early in the session (before summary) the arc-check edit had two matches in dwarf_fight.gd (monster check and
  furniture check have the same shape). Needed more surrounding context to target only the monster check line.
- F-number collision: FEEDBACK-done.md already had an F659 from an earlier chat, and the previous session also
  logged a different F659. Skipped to F665+ to avoid the collision zone.
