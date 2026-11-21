# Crossbow reload: the hand goes around the belly (chat 18)

**What we did:** The owner said the reload was okay, but the left hand must not go through his body.
The hand's path from the belt pouch to the bow's end was a straight line, and his big belly was in the way.
We moved the pouch spot forward and added a waypoint out in front of the belly (`FRONT` in `crossbow_ik_bake.gd`).
Top-view pictures now show the hand staying in front of him. Re-baked, re-exported, localhost page updated.

**Hurdles:** The localhost server had stopped, so it was restarted. Hand reach is short (arms ~26 cm), so the spots are close to the limit (worst miss still 6.8 cm).
**Still open:** "huge hands" question (shrink for crossbow only or everywhere?) and whether the jumping spin is the spear's or sword's third hit.
