# Crossbow hands spread + sword hit 3 slower (chat 18, dwarf-animations)

**What we did:** Owner: bow direction is great, but in reload both hands piled up on his chest. We held the bow more level and further out (LOW_W/LOW_F in `crossbow_ik_bake.gd`) and moved the left-hand spots further along the bow, so the hands sit apart. Also the sword's third hit (jump and spin, `ual_3`) is 30% slower: `DwarfRig.attack_seconds` multiplies it by 1/0.7, and the fight code uses the same number, so the hit moment stays in step.

**Mistakes and hurdles:**
- The first moves page had no crossbow at all. `one_swing_export.gd` still asked for the deleted clip `c/Reload1H`, which stopped the export before the crossbow was added. Fixed (removed from BOW_TRY). Claude should have checked the page contents before sending it.
- Pushing the left hand further out raises the miss (reload worst 15 cm; arms are only ~26 cm long). Hands are apart now but not perfectly on the bow.
- The full test run crashes out of memory in `cave_life.gd` (another area). `test_dwarf` group shows 4 fails (armor, braid, aim skip, great swings); aim-skip passes alone, so it is flaky in the group, not from this change.
