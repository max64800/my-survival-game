# Swings from a phone video (F389, two-handed weapons)

The owner films himself swinging a taped stick; `swing_from_video.py` turns each video into key poses
(ready, wind-up top, hit, recovery) with timings, in numbers the dwarf can use. Plan: `docs/art/2H-ANIMATION-PLAN.md`.

## Filming (owner)
- **Gloves:** red on the LEFT hand, blue on the RIGHT (any two colours work; tell Claude which).
- **Stick:** a broom handle about 1 m long. Yellow tape round the **head end** (where the axe head would be),
  green tape round the **other end**. Tape 5–10 cm wide, wrapped all the way round.
- **Place:** plain wall behind you, bright even light, no red/blue/yellow/green things in the picture,
  clothes that show your elbows and knees (no baggy jumper).
- **Phone:** on a stand at waist height, about 3–4 m away, your whole body AND the stick in the picture at all times.
  60 fps if the phone has it. Back camera (not selfie: selfies are mirrored).
- **Each swing (chop, sweep back, slam):** stand still 1 second in the ready pose, swing, hold the end 1 second.
  Three tries **slow**, three tries at **real speed**. Film it all **from the side** (phone at your right), then
  again **from the front**.
- Name the files like `chop_side_slow_1.mp4`, `slam_front_fast_2.mp4`.
- **Never commit the videos** (the repo is public). They stay in `tools/mocap/videos/` (ignored by git).

## Running (Claude)
```
cd tools/mocap
python -m venv .venv && .venv/bin/pip install mediapipe opencv-python numpy   # Windows: .venv\Scripts\pip
mkdir models && curl -L -o models/pose_landmarker_heavy.task https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task
.venv/bin/python test_swing_tool.py                         # self-check, no person needed
.venv/bin/python swing_from_video.py videos/chop_side_*.mp4 --view side --out out/
```
Different colours: `--gloves LEFT RIGHT --tape HEAD GRIP` (red, orange, yellow, green, blue, pink).
Look at `out/<name>_sheet.png` first: if the white skeleton, the circles on the gloves or the yellow stick line are in the
wrong place, the numbers are wrong too.

## What comes out (`out/<name>.json`)
- `keys`: frame numbers of `ready`, `windup_top`, `hit`, `recovery`, and `timing_s` (wind-up, hold at the top, strike,
  recovery, in seconds). Found from the speed of the stick's head (yellow tape).
- `key_poses.<key>.body` (MediaPipe's 3D guess, rough for depth: the side and front videos together are better):
  - `left_fist`, `right_fist`, `left_elbow`, `right_elbow`: from the middle of the shoulders, **in arm lengths**
    (x = left-right, y = up, z = depth). Multiply by the dwarf's arm (27 cm shoulder to wrist) to get his spots.
  - `hand_gap` (arm lengths), `chest_twist_deg` (shoulders against hips), `lean_deg`, `knee_bend_deg`.
- `key_poses.<key>.handle_angle_deg`: the stick's angle in the picture (0 = pointing right, 90 = straight up).
  From the side video that's the chop's up-down arc; from the front video the sweep's left-right arc.
- `frames`: the same for every frame (`pixels` = joints in the picture).

The owner's arms are long and the dwarf's are short: copy **directions, angles, twist, lean and timing**, not
distances. The pose tuner (`great_pose_tuner.gd`) then nudges each pose until the handle clears his body.

Licences: MediaPipe and its pose model are Apache 2.0 (Google). Nothing from them ships in the game.
