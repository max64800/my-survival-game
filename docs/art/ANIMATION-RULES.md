# Animation rules (read before changing any dwarf move)

Like `MODEL-RULES.md`, but for moves. Written Nov 20, 2026 from the 7 dwarf-animation chats (F282, F389).
When a rule changes, delete the old text that disagrees. Chat 11 (Nov 20): the great axe uses the Lampwick Foreman's
KayKit moves (owner OK'd); next job: sword and mace from the same pack.

## 1. Know his body (measured, not guessed)
- Arm: **27 cm** shoulder to wrist. Left arm reaches ~33 cm. Beard sticks out **48 cm**, belly **38 cm**.
- Numbers from another rig (KayKit, Quaternius, a human) are wrong for him: measure on his own skeleton
  (`twohand_preview.gd markers=1`, `great_pose_tuner.gd`).
- His belly is bound to the low spine bones: chest twist must go mostly there, or it won't show.
- Elbows **out to the sides**, fists **in front of the shoulders**. Elbows that keep the idle bend fold the arms into
  his belly (chat 6: the real reason "the axe can't be held in front of him").

## 2. Don't search again (already checked)
- Quaternius UAL 1 + 2 (his own pack): no two-handed weapon moves.
- KayKit Character Animations (CC0): tried in chat 5 with a weaker copy (hands bunched, head and mirror wrong):
  owner said no. The **KayKit Skeletons pack** (`tools/asset_forge/packs/kaykit_skeletons/`, the Foreman's) has the
  same kind of moves: 1H chop, slash diagonal/horizontal, jump chop, stab, block/blocking/block attack, dual-wield,
  dodges, hits, deaths. Copied the chat 11 way, the owner liked them.
- Kevin Iglesias melee (no stated licence), KinemIQ, Modular RPG Characters: not usable in a public repo.
- Mixamo: fine in a sold game but its files can't go in the public repo. Cascadeur free: no commercial use.
- MoCap Online free T.C. Sword pack: its licence forbids any AI use (AI retargeting named) and sharing the files: not usable (chat 14).
- The owner's own filmed videos (chat 13-14, `one_hand_*.py`): too hard to read from one front camera; owner: "still really bad".
- **Godot's import retarget renames every bone** and breaks his other moves: retarget in code.

## 2b. How to copy a pack move onto him (chat 11, works: `tools/asset_forge/great_kaykit_bake.gd`)
- Both rigs stand in a T pose facing the same way: give each dwarf bone the KayKit bone's turn away from its rest in
  **whole-skeleton space**, set parents first (the squashed dwarf bones skew local turns). Bake to JSON in `assets/anim/`.
- **Mirror** left/right when the pack holds the weapon in the other hand than the owner wants.
- **Neck and head follow the HIPS' turn**, none of the pack's own head nods: his belly and shirt bend with the hips;
  a head following the chest stays behind the shirt's neck hole (owner said "head not moving" 3 times).
- The game's hit is at 0.40 of a swing: time-warp each clip so its strike (the fastest frames) lands there.
- Our code then puts the fists on the handle (left at the end, right GAP up), keeps it out of his body, and lays the
  blade by the pack's hand-slot frame (the edge = the way it moves). A double-bit head: find the blade by its main
  spread, not a plain sum (it cancels out and shows the flat side).
- The 3D page recorder must save **every bone's place every frame** (head and hair hang on root helper bones), and
  check the page itself in a browser before telling the owner it's fixed.

## 2c. How to copy the owner's own videos (one-handed, chat 13: `tools/mocap/one_hand_*.py`, `one_video_bake.gd`)
- Track every frame (`track_all_frames.py`), then `one_hand_scan.py` (mends lost frames, finds the white stick with
  `stick_finder.py`), `one_hand_targets.py` (bone directions), `one_video_bake.gd` -> `assets/anim/one_video.json`,
  pictures with `one_video_preview.gd` (front with the shield hidden + behind, next to his frames).
- Measure only round the combo (his first seconds walking in are tracked wildly). Bone lengths and the picture-plane
  directions come from the pixels; the tracker's depth only gives the sign. Body turn = middle of the tracker's guess and
  the shoulder width in the picture.
- **The hit = where the weapon is stretched out furthest**, not the fastest frame (owner, Nov 20).
- His long arm carries the fist far out; the dwarf's can't: the weapon's tip aims at the filmed tip spot measured
  against the body (side-to-side in shoulder widths, up-down in shoulder heights), only for low swings.
- Raised: a short-looking stick leans back; the sword never cuts through his big head (`_clear_head`).
- The shield fist reaches a guard spot in front of his chest (`_guard`), never the filmed arm directions (his chest
  and belly are much wider than the owner's: the fist ended at his side).
- The pale blue glove reads as white: use the tracker's hand points, not colour.

## 3. What the owner wants (two-handed)
- Great axe and great maul (done, chat 11): the Foreman's **2H stance**, **light = Chop**, **heavy = Spin**. Left fist
  at the end of the handle, right fist slid high up it (46 cm). Never invent poses: copy pack moves (2b).
- Walking and running (not swinging): the great weapon rests on his right shoulder in **one** hand (approved, round 3).
- Next: sword and mace from the same pack, a 3D page with 2-3 moves per weapon first, the owner picks.

## 4. How a heavy swing moves (so it reads as heavy)
- **Wind-up:** slow and clear, 0.3–0.5 s. The player must see it coming.
- **Hold at the top:** a short still moment, 0.05–0.15 s.
- **Strike:** fast, 0.1–0.2 s. Heavy means a longer wind-up and recovery, **not** a slower strike.
- **Contact:** the game already freezes both fighters (`HIT_STOP` 0.06 / 0.11 s) and shakes the screen. Don't add more.
- **Recovery:** 0.3–0.5 s, the weapon's weight pulls him a little past the hit.
- **Hips lead:** hips start turning before the chest, the chest before the arms. Knees bend at the hit.
- **Arcs:** the axe head follows one smooth curve. If it wobbles or cuts a corner, add a middle key.
- Copy **directions, angles, twist, lean and timing** from the owner's video; never his distances (his arms are long).

## 5. Checks (a move isn't done until they pass)
- Both fists on the handle (within 2 cm of their spots) at every key **and** in between: check about one moment per
  game frame (`great_pose_tuner.gd check=1`: 120 per swing; the test: 60). 10 moments missed real touches (chat 8):
  the strike crosses most of its arc in 2% of the swing.
- Handle at least **3 cm clear** of his body (belly, beard, chest) at every key and in between. The keep-out guard
  (`DwarfFist._keep_out`, small balls on his skin) slides the handle out every frame; key poses still matter (the
  guard moves the axe head away from its target when it has to push hard).
- Axe head ends **in front** of him at the hit (never sticking out to his side or behind).
- Tuner tip: polish each key pose from its **own** best start. Starting from the pose before makes it get stuck.
- Test: `test_dwarf_fist` (+ any new check goes there).

## 6. Working with the owner
- Show a **picture sheet** before building into the game: each key pose from the front, the side and from behind
  (the game camera), the handle and fists marked.
- For a new pose: **3 versions side by side**, the owner picks one. Picking is faster than fix-and-look rounds.
- At most 2 rounds of pictures before asking the owner what's wrong.
- The owner looks at moves mostly **from behind** (game camera): that view matters most.

## 7. Mistakes not to repeat
- Swing clock must count **game time** (`delta`), not real time: slow frames skipped key poses in the preview.
- Never stop all Godot programs (other chats' games run too): stop only your own.
- Untyped `:=` from Arrays and a function named `convert` broke the build for every chat: type everything, run the
  file's test before pushing.
- Preview pages may show cached files: load with `no-cache`.
- A long Python edit inside a shell command broke the quoting: save scripts as files.
- **Push the work at the end of every chat.** Chats 6-7 (great swing + tuner) were left unsaved on the PC.
- Use `/effort high` for animation chats: normal thinking failed this job many times.
- `pass` is a GDScript keyword; `Basis.get_column` doesn't exist (use `basis[i]`); a Packed array read out of a
  Dictionary is a copy (appending to it does nothing). Check-compile `dwarf_fist.gd` before every run: a parse error
  there breaks the game for every chat.
- One shape per bone is far too fat for his body (the head bone carries the beard): use many small balls.
