# Two-handed swings: the plan (F389, Nov 20, 2026)

Goal: the great axe's stance + chop, sweep back, slam look right to the owner, then the great maul, then sword + shield.
Rules for doing it: `docs/art/ANIMATION-RULES.md`. Chance of success with all of this: ~80% (Claude's guess, not measured).

**Why the old way kept failing:** Claude invented each pose as bone-angle numbers and only learnt it was wrong when the
owner looked. No pack has two-handed moves that fit his short arms and big belly.
**The new way:** the owner's own swing (video) gives the motion and timing, the PC's pose tuner fits it onto the
dwarf's body, checks catch the handle going through him, and the owner picks from picture sheets.

| # | Step | Who | Status |
|---|------|-----|--------|
| 0 | Save + push chats 5-7's unsaved code (`dwarf_great_swing.gd`, `great_pose_tuner.gd`, `twohand_preview.gd` changes, `DwarfFist._great_hold`) | PC Claude | **first thing** |
| 1 | Animation rules file | Mac Claude | done (Nov 20) |
| 2 | Video → key poses tool `tools/mocap/` (+ self-check) | Mac Claude | done (Nov 20) |
| 3 | Reference pictures: `docs/art/2h-reference/great_axe_poses_side.jpg` (rows chop / sweep back / slam, columns ready / wind-up top / hit / recovery; made from a render of our dwarf). Good for stance, slant and bent knees; some poses have the hands closer than the rules: the owner's video wins. Behind view (prompt 2) not made yet | Mac Claude | done (Nov 20) |
| 4 | Film chop, sweep back, slam (side + front, slow + fast); guide in `tools/mocap/README.md` | owner | to do |
| 5 | Run the tool, check the sheets, turn the numbers into his key poses (scale by arm length, keep angles/twist/timing) | PC Claude | after 4 |
| 6 | Tuner fits each pose to his body; add middle keys where the handle passes through him; checks in `test_dwarf_fist` | PC Claude | after 5 |
| 7 | Picture sheet (front, side, behind) for the owner; 3 versions where a pose is unsure; owner picks | PC Claude + owner | after 6 |
| 8 | Swoosh trail behind the axe head during the strike (only looks; hit freeze and screen shake already exist) | PC Claude | after 7 |
| 9 | Great maul (slam + low sweep), then sword + shield, same way | PC Claude | later |

**Backup if this fails too:** the owner's other idea: great weapons become heavy one-handers (held near the end of
the handle, slow wind-up, big hit) with a free off hand (shield, torch or nothing). Last resort: pay an animator
for just the 3 swings.

Not chosen for now: text-to-motion AI (NVIDIA Kimodo / ARDY, Tencent HY-Motion; licences not checked yet), Mixamo
(can't go in the public repo), Cascadeur (free version bans commercial use).

## ChatGPT prompts for step 3 (attach a screenshot of the dwarf in game so the style matches)
1. *Pose sheet:* "Animation key-pose reference sheet for my game's dwarf (picture attached): very short arms, big round
   belly, long thick beard, chunky hand-painted style. He swings a two-handed great axe (handle about as long as he is
   tall). 3 rows: CHOP (right to left), SWEEP BACK (left to right, low), SLAM (straight down). 4 columns: ready,
   top of the wind-up, the hit, recovery. Side view. Left hand at the very end of the handle, right hand high up the
   handle, hands wide apart (closer only in the slam), elbows out, handle never through his belly or beard. Hips turn
   before the chest. Plain light background, no text."
2. *Same sheet seen from behind* (the game camera), same rows and columns.
3. *Filming test picture:* "Realistic photo, side view, plain white wall: a man in a fitted grey t-shirt, red glove on
   his left hand, blue glove on his right, swinging a 1 m broom handle like an overhead axe chop at the top of the
   wind-up. Yellow tape round the stick's top end, green tape round the bottom end. Whole body in the picture."
   Use it to test that `tools/mocap/swing_from_video.py` finds the body (it was only tested without a person).
These pictures are targets to copy, never models in the game.
