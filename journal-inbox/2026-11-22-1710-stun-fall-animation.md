# 2026-11-22 — Stun now falls down instead of freezing (F663)

## What we did

Fixed the dwarf's stun animation. When the stun meter filled, the dwarf
played "b/Idle_Shield_Break" — a brief guard-broken pose — and then resumed
normally. No fall, no lying on the floor. The user described it as "just
freezing, and then the animation of standing up works."

## Root cause

`take_stun()` in `dwarf_fight.gd` called `dwarf.model.react("stunned", STUN_TIME)`,
which played the Shield_Break one-shot animation for 1.5 s. The `knock_down()`
function (which does fall → lie → get_up) was never called from the stun path.

The "animation of standing up works" the owner saw was from a SEPARATE knockdown
trigger (boss spin's last hit has `kd=true`, which calls `dwarf.knock_down()` after
`take_stun`). But `knock_down()` checks `stagger > 0.5: return`, so when stun set
stagger=1.5 first, the knockdown was blocked and NO get_up timer fired. The only
"standing up" they saw was the natural end of the Shield_Break one-shot blending
back to idle — not a real get_up animation.

## Fix

In `take_stun()`, replaced `react("stunned")` + `stagger = maxf(...)` with:
1. `stagger = 0.0` — clears any brief stagger so `knock_down()` doesn't skip itself
2. `knock_down()` — plays the full fall → floor (0.85 s) → get-up sequence

`knock_down()` itself sets `stagger = KNOCK_DOWN_TIME` (2.0 s) and schedules
`react("get_up")` after 0.85 s, so the owner now sees: fall, lie, stand up.
The Warhammer ★25 heavy-swing immunity in `knock_down()` still applies.

## Files changed

- `src/combat/dwarf_fight.gd` — `take_stun` calls `knock_down()` instead of `react("stunned")`
- `FEEDBACK.md` — F663 added and fixed
