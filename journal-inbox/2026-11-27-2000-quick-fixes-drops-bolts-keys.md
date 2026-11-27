## Nov 27 — Quick fixes from the big play-session list (F921, F922, F923, F926, F938, F939)

**What we did**
- **F938 🔁 (crossbow reload on R):** the owner picked Q / T / G for the 3 abilities. R reloads again; clicking an
  empty crossbow still reloads too. `controls.gd` has a new "reload" key; the skills window's boxes now say Q, T, G.
- **F921 (dropped gear too big):** things held in the hand keep their real size, but a dropped mace was drawn
  1.75x to 2.2x bigger (the rock-chunk boost from F93/F153 hit everything). Now gear is hand-size on the floor;
  rock, ore, wood, food and gems keep the big chunky look. `Drop.look_scale_of`.
- **F922 (drops bounce like they weigh nothing):** drops were 0.3 kg with no grip. Now 4 kg, no bounce, rough,
  fall faster, stop rolling quickly. Rock chips were already heavy (Nov 18).
- **F926 (bolts way too big):** the flying bolt was a 50 cm glowing stick 4 cm thick → 32 cm, 2 cm. Bolts on the
  floor were about 1 m long (the 2x drop boost) → about 35 cm.
- **F923 (workbench cards spill out):** the card was one button with its own picture + text, so long names ran
  over the frame's border and tall pictures pushed into the name. Now a fixed picture box + a name that wraps onto
  2 lines, kept 11 px inside the frame. The `menucheck` robot now also photographs the Stations tab.
- **F939 (lantern message doesn't fit):** the frame's corners reach 30 px in, the text had only 18 px of room.
  Now 30 px top/bottom, 40 px sides.
- Test: `test_equipment.test_dropped_gear_is_hand_size_heavy_and_does_not_bounce`.

**Mistakes and hurdles**
- `run_tests.sh only=<test function name>` ran 0 checks: `only=` takes the test FILE, `fn=` the function.
- The first robot run timed out at 240 s before taking any pictures (loading took ~75 s, and every frame after
  loading took about 1 s of "game code" while other chats were busy on the PC). Gave it 400 s.
- Card fix took 3 photo rounds: first the names still touched the side borders (inset 9 → 11), then the 2 wrapped
  lines overlapped (line spacing -3 → 0, picture 40 → 35 px).
- While I was working, the bronze-armour chat committed FEEDBACK.md and FEEDBACK-done.md whole, which took my
  staged feedback edits into its commit. Nothing was lost (checked), but it's another reason to stage only your
  own hunks and commit feedback edits right away.
- test_dwarf: 5 old failures (braid tufts, stun meter, camera glide, great-swing fists, aim flakes) — already listed
  in earlier journal entries as not ours; not caused by this work.

**Noticed (not fixed):** in the robot runs, frames after loading took ~1 s of game code (5-20 FPS) — may be
related to F417 (9 FPS), or just other chats' Blender/Godot runs on the same PC. Needs its own look (Opus).
