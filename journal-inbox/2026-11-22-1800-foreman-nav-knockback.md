# Nov 22 — Foreman navigation fix, other attacks, player knockback

Second round of Dungeon 2 (Old Pell's Diggings) fixes from the owner's second playtest session.

## What we fixed

**F682 — Boss stuck in entrance wall, can't get home when player returns**
Two-part fix in monster.gd:
1. The CHASE no-progress threshold was raised from 3 s to 8 s for bosses. The old 3 s limit made the boss
   give up chasing if it got briefly snagged on a doorway or geometry edge, sending it into RETURN state
   before it could fight back. 8 s gives a boss plenty of time to slide past the obstacle.
2. The RETURN teleport-home threshold was reduced from 5 s to 2 s for bosses. If the boss is in RETURN
   state and can't navigate back (stuck in a doorway), it snaps home in 2 s instead of 5 s. By then the
   player has already left the room and won't see the teleport.

**F679 — Foreman should do attacks besides spinning**
The owner previously asked to remove all non-spin attacks (F645). After another playtest, the owner
confirmed they want variety back. Added "Pick Crack" (2H overhead chop, 18 blunt damage, 2.2 m reach,
5 s rest, parry=any) to the foreman attack list. The boss will mix chops between spin cycles.

**F686 — Enemy attacks should push the player back (new feature)**
Added `knock` field to monster attacks (default 1.5 for any attack without it). On a landed hit:
`dwarf.shove(away * knock)` — the same `shove()` function beetle charges already use, but with
smaller magnitudes for regular hits.

Knock values set:
- Foreman Pick Whirl (5-hit chain): 2.0 (first hit), 2.5 (hits 2–4), 3.5 (final knockdown hit)
- Foreman Pick Crack: 2.5
- Prop Warden Plank Sweep: 3.5 (biggest push — the sweep already knocks you down)
- Prop Warden Axe Chop: 2.5
- Everything else: 1.5 (default, a small nudge)

The `knock` value is passed through the monster_manager `send_tell` RPC and stored in `_incoming`
so the client's `_judge_incoming` can read it when the hit lands. Charges (beetles) continue using
the existing `charge_shove` path and are excluded from this new pushback.

## What is still open

- F683 (hits when not spinning): timing seems correct per IMPACT dict; may be perception of the wind-up
- F684 (legs slide during spin): needs Blender animation work — the spin animation has no walk cycle
- F685 (spin should only hit when pickaxe connects): IMPACT dict already places the blow at 0.8 s mid-spin
- F676 (arena too small): design decision pending
- F680 (red but no spin): still investigating

## Mistakes and hurdles

- The CHASE no-progress edit failed on first try because the grep match text had slightly different
  indentation than expected. Fixed by reading the exact lines first.
- Initially considered removing the "lift" named room from PELL spaces, thinking it was triggering
  `gives_up` via the room-check path. After careful re-reading of the logic (foreman has chase_out=true,
  which makes the room check always false), the actual trigger was the no_progress guard, not the room
  name. Kept the lift room definition untouched.
