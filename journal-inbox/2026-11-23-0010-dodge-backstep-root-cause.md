# Dodge "backward then forward" — the real root cause (F702 follow-up)

## What happened
Earlier tonight I fixed a grace-buffer and a dash-speed ramp for the held dodge, called it fixed, and told the
owner to test. The owner came back: "No, still works exactly as before. I'm looking forward, I press Ctrl, I
dash backwards, then I press Ctrl again, I dash forward." Standing still, no movement key held.

## The real bug
`dwarf_fight.gd`'s dodge code had a line that, on purpose, made a standing-still dodge roll **backward**
(`Basis(...) * Vector3.BACK`). But the dwarf's body snaps to face whichever way it just rolled. So: roll 1 goes
backward, body now faces that way; roll 2's "backward" (relative to the new facing) is the opposite of roll 1's
world direction — which looks exactly like "dash backward, then dash forward," over and over.

Nobody ever asked for a backstep-by-default; it wasn't in FEEDBACK.md or FEEDBACK-done.md anywhere. Changed the
fallback to roll the way you're already facing instead.

## My mistake
My first round of automated tests for F702 all held a movement key (W) while testing dodge direction — none of
them tested "stand still, dodge, no keys held at all." That's the exact case the owner was hitting, so my tests
gave false confidence: they passed while the real bug was still there. Added a new test,
`test_dodging_with_no_movement_key_rolls_forward_not_backstep`, that covers exactly that case.

## A side mistake while testing
Checking just my new test file alone with `--check-only --script tests/test_dwarf.gd` failed with a wall of
unrelated "failed to compile depended scripts" errors. Chased it down to `src/player/camera_room.gd` — a new
file from another Claude session, not yet committed. Godot's single-file `--check-only` doesn't do a full
project scan, so it can't see a brand new global class yet; running the real test suite (which does a full
project load) compiled fine. Lesson: a single-file `--check-only` cascade can be a red herring when someone else
just added an uncommitted new script — the full test runner is the real check.

## Still open
The owner's other complaint — "if I press Ctrl and hold, I dodge the same short distance, then basically
sprints the rest of the way" — is NOT fixed yet. The code for a held dash (speed ramps up the longer you hold,
up to Combat.DASH_HOLD_MAX) looks right by reading it, and my simulated test for it passes, but I can't explain
why it would look right in simulation and not match the owner's real-hardware play. Needs real play-testing,
not more code reading, to pin down.

## What's committed
`src/combat/dwarf_fight.gd` (the direction fix) and the new test in `tests/test_dwarf.gd`, as commit
`216f6f66`. Left `src/player/dwarf.gd` and the rest of `tests/test_dwarf.gd` alone — another Claude session has
unrelated, uncommitted camera/sprint work in progress there.
