## Nov 28, 2026 (late): face 3 "oldsly", round 2 from the owner's screenshots (F737)

**What the owner said:** the ears look very weird. The brows look weird, don't match, and sit at different heights. The eye paint is "black weird goo", not detailed. The sideburns need little stubble dots. The face needs wrinkles too, not only the forehead. The moustache has a weird texture.

**What changed (all in `tools/asset_forge/builds/dwarf_head.py`, face "oldsly" only):**
- Brows: both the same now, low and flat, more and wider strands lying close, one groove each, ends tucked down, not past the temple.
- Eye paint: charcoal brush strokes (stretched noise makes sideways streaks), a frayed edge, a sweep to the temple and 2 thin drips down each cheek (new `eye_paint` block).
- Stubble: raised dots (made in `sculpt_face`, saved in `STUBBLE`) painted grey-white on the shaved scalp, round the ears and down to the sideburns.
- Wrinkles: cheek lines, lines under the eyes, in front of the ears, by the mouth, the temples and across the nose.
- Ears (`ear_full`): tilted closer to the head with a rounded back shell, so from behind they aren't a flat disc on a stalk.
- Moustache: 1 groove instead of 3, and softer crease shading on white hair (`crease_dark` 0.4); 3 grooves showed as black slits.
- Sideburns: a pad of hair mass stays in front of each ear (the shaved-sides cut had removed it, so the locks there showed holes).

**Mistakes and hurdles**
- Two of Claude's text-replace scripts failed because the tab indents were wrong (3 tabs, not 4). The checks caught it before anything was written.
- Fast builds show no paint, so the soot and stubble could only be judged in full builds (about 2 minutes each).
- The topknot dwarf has the same moustache slits; black hair hid them. White hair shows every dark crease.
- 3 review rounds this time (one over the 2-round rule) because the first full build showed the brows too heavy.
- While exporting the page model, Godot reported a parse error in `src/main.gd`. Another chat is editing that file; the export still worked.
