# Crossbow reload hands spread, sword hit 3 slower (chat 18, dwarf-animations)

**What we did:** Owner liked the crossbow direction but in reload both hands were piled on his chest. We tilted the lowered bow flatter and pushed it further out (LOW_W/LOW_F in `crossbow_ik_bake.gd`) and moved the left-hand spots further along the bow, then re-baked. Also made the sword's third hit (ual_3, jump and spin) 30% slower in `DwarfRig.attack_seconds` (x1/0.7); the fight code uses the same number, so the hit timing follows.

**Mistakes and hurdles:**
- The first Moves page had no crossbow at all: `one_swing_export.gd` still asked for the deleted clip c/Reload1H, which threw a script error and skipped the crossbow. Fixed by removing it from BOW_TRY.
- Moving the left-hand spots further out alone barely changed the picture (the arm is only about 26 cm long); the bow had to move out too. Worst left-hand miss is now 6.8 cm (aim) and 15.1 cm (reload), so the hands are still fairly close.
- Full test suite crashes out of memory in `cave_life.gd` (another chat's area); the dwarf group has 4 fails (armor, braid, aim-skip passes alone, great swings), none from this change.
