## 2026-11-28 · Bare dwarf, round 3: neck skin, posture, wrist wraps, loose braids (F943)

**What the owner asked (2 pictures):** still no neck skin by the shoulders; too straight now, head a bit forward;
feet are good; little black lines above the fists; braids glued together (only the middle tip bounces); a pause
button on the page; the neck sticks out when he runs.

**What we did**
- **Neck skin:** the owner picked "a gap under the ears". `dwarf_head.py` now cuts a smooth slot in the hair below
  each ear (`NECK_GAP`, `in_neck_gap`), and no hair locks grow inside it.
- **Posture:** `dwarf_rig.gd` stand-tall went from 10° to 7°, and the neck now turns the head half *forward*
  (was tipped back). In the run pose the neck no longer pokes out in front.
- **Wrist lines:** the owner picked a "leather wrist wrap". `dwarf_body.py` builds two chunky leather turns plus a tucked
  strap end on each forearm, painted leather and moving with the arm (not hidden under gauntlets).
- **Braids:** `hair_swing.gd` braids are softer (stiff 0.17, more bend), and the looseness now starts at 40% near
  the top instead of 0, so the whole braid swings, not only the tip.
- **Page:** a Pause/Play button (picking a move un-pauses). Also fixed the "Building the dwarf…" text that never went
  away: the page style shows it as a grid, which beats `hidden`, so it now uses `display: none`.

**Mistakes and hurdles**
- The black forearm line was two surfaces crossing (the hand piece meets the forearm), not a painted shadow. Two
  rounds of smoothing didn't hide it, so we asked the owner and covered the spot with a wrap instead.
- The first wrap was too thin and melted into the arm. Bigger lift and a smaller blend gave two clear turns.
- Last round's "stand tall" plus the head tipped back made him too stiff. Lesson: when the back straightens, the head
  must come forward a little, or he looks like a soldier.
- The braids were stiff because the top 20% of each braid had zero looseness and the rest ramped up slowly, so only
  the tip moved.
- Claude's own shot script showed stretched hair at run speed, so it was useless for checking the run. We checked the run on the
  real page in a browser instead (paused, from the side).
- The neck gap does show skin, but it sits in shadow, so it is subtle. If the owner still can't see it, the next step is a
  wider gap or a lighter neck.
- `test_braids…` was already failing before this round (not caused by these changes).

**Round 4, same evening (2 pictures):** "standing too forward", "I still don't see the cutout and the shirt", and the
whole braid (circled from the face down) must swing, not only the tips (circled red).
- Head straight on the neck again (stand-tall 8.5°, neck share 0).
- **Neck:** widening the hair gap alone did almost nothing. The real problem was that the jaw and the beard sides sat
  right on the shirt, so there was no neck to show. Asked the owner, who picked "longer neck + lower collar".
  The new `DwarfProportions.set_neck_lift` moves the head joint 2 cm farther up the neck (only for the hand-built
  body), so the head and helmets rise together and the neck skin stretches between them. The shirt's neck hole is
  2 cm wider and 1.5 cm lower.
- **Braids:** the top 70% free (was 40%), freeing up from the very top. On the page the whole braid now swings out.
- Mistake: Claude's comment lines in `dwarf_body.py` went in without the tab in front, so the first full build failed
  with an IndentationError and nothing was rebuilt. Caught by reading the build's output; fixed and rebuilt.
- The back-hair check in `test_braid_tufts_swing_when_moving` (12.4 cm in a dash) fails with and without the neck lift:
  it comes from earlier work, not from this round.
