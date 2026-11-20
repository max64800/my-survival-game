"""Turn a phone video of the owner swinging a taped stick into key poses for the dwarf (F389, great axe).

What it finds in every frame:
  * the body joints (Google MediaPipe Pose, Apache 2.0): shoulders, elbows, wrists, hips, knees, feet
  * the two gloves by colour (left / right hand) and the two tape marks on the stick (head end / grip end)
Then it picks the key poses on its own: ready, wind-up top, hit, recovery, from how fast the stick's head moves.

Output (in --out):
  <name>.json        every frame + the key poses, in body-relative numbers (see README.md)
  <name>_sheet.png   the key frames side by side with the joints, gloves and stick drawn on

Run:  .venv/bin/python swing_from_video.py chop_side.mp4 --view side --out out/
The videos stay on the PC: never commit them (the repo is public).
"""
import argparse
import json
import math
from pathlib import Path

import cv2
import numpy as np

HERE = Path(__file__).parent
MODEL = HERE / "models" / "pose_landmarker_heavy.task"

# Colour name -> list of HSV ranges (OpenCV hue 0-179). Red wraps round, so it has two.
COLORS = {
    "red": [((0, 120, 70), (8, 255, 255)), ((170, 120, 70), (179, 255, 255))],
    "orange": [((9, 140, 120), (20, 255, 255))],
    "yellow": [((21, 100, 120), (34, 255, 255))],
    "green": [((40, 80, 60), (85, 255, 255))],
    "blue": [((95, 120, 60), (128, 255, 255))],
    "pink": [((140, 80, 120), (169, 255, 255))],
}
JOINTS = {"nose": 0, "l_shoulder": 11, "r_shoulder": 12, "l_elbow": 13, "r_elbow": 14, "l_wrist": 15,
          "r_wrist": 16, "l_hip": 23, "r_hip": 24, "l_knee": 25, "r_knee": 26, "l_ankle": 27, "r_ankle": 28}
BONES = [("l_shoulder", "r_shoulder"), ("l_hip", "r_hip"), ("l_shoulder", "l_hip"), ("r_shoulder", "r_hip"),
         ("l_shoulder", "l_elbow"), ("l_elbow", "l_wrist"), ("r_shoulder", "r_elbow"), ("r_elbow", "r_wrist"),
         ("l_hip", "l_knee"), ("l_knee", "l_ankle"), ("r_hip", "r_knee"), ("r_knee", "r_ankle")]


def find_color(hsv, name, min_area):
    """Centre (x, y) in pixels of the biggest blob of this colour, or None."""
    mask = None
    for lo, hi in COLORS[name]:
        m = cv2.inRange(hsv, np.array(lo), np.array(hi))
        mask = m if mask is None else mask | m
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, _, stats, cents = cv2.connectedComponentsWithStats(mask)
    if n < 2:
        return None
    i = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    if stats[i, cv2.CC_STAT_AREA] < min_area:
        return None
    return [float(cents[i][0]), float(cents[i][1])]


def make_pose():
    from mediapipe.tasks.python import BaseOptions, vision
    opts = vision.PoseLandmarkerOptions(base_options=BaseOptions(model_asset_path=str(MODEL)),
                                        running_mode=vision.RunningMode.VIDEO)
    return vision.PoseLandmarker.create_from_options(opts)


def body_numbers(world):
    """Body-relative numbers from MediaPipe's 3D joints (metres, hips at 0). y is flipped so up is +."""
    p = {k: np.array([world[i].x, -world[i].y, world[i].z]) for k, i in JOINTS.items()}
    sh = (p["l_shoulder"] + p["r_shoulder"]) / 2
    hip = (p["l_hip"] + p["r_hip"]) / 2
    arm = (np.linalg.norm(p["r_shoulder"] - p["r_elbow"]) + np.linalg.norm(p["r_elbow"] - p["r_wrist"])
           + np.linalg.norm(p["l_shoulder"] - p["l_elbow"]) + np.linalg.norm(p["l_elbow"] - p["l_wrist"])) / 2
    flat = lambda v: math.degrees(math.atan2(v[2], v[0]))  # direction of a left-right line seen from above
    twist = (flat(p["r_shoulder"] - p["l_shoulder"]) - flat(p["r_hip"] - p["l_hip"]) + 180) % 360 - 180
    spine = sh - hip
    return {
        "arm_length_m": round(float(arm), 3),
        # each fist from the middle of the shoulders, in arm lengths (x = his left-right, y = up, z = depth)
        "left_fist": [round(float(v), 3) for v in (p["l_wrist"] - sh) / arm],
        "right_fist": [round(float(v), 3) for v in (p["r_wrist"] - sh) / arm],
        "left_elbow": [round(float(v), 3) for v in (p["l_elbow"] - sh) / arm],
        "right_elbow": [round(float(v), 3) for v in (p["r_elbow"] - sh) / arm],
        "hand_gap": round(float(np.linalg.norm(p["l_wrist"] - p["r_wrist"]) / arm), 3),
        "chest_twist_deg": round(twist, 1),  # shoulders turned against the hips, seen from above
        "lean_deg": round(math.degrees(math.atan2(math.hypot(spine[0], spine[2]), spine[1])), 1),
        "knee_bend_deg": round(float(np.mean([180 - math.degrees(math.acos(np.clip(np.dot(
            (p[h] - p[k]) / np.linalg.norm(p[h] - p[k]), (p[a] - p[k]) / np.linalg.norm(p[a] - p[k])), -1, 1)))
            for h, k, a in [("l_hip", "l_knee", "l_ankle"), ("r_hip", "r_knee", "r_ankle")]])), 1),
    }


def pick_keys(frames, fps):
    """Key frames from the stick head's speed: ready, wind-up top (the slow moment before the fastest bit),
    hit (where it slows down again after), recovery (the end)."""
    pts = [f["stick_head"] for f in frames]
    known = [i for i, q in enumerate(pts) if q is not None]
    if len(known) < 5:
        return None
    speed = [0.0] * len(frames)
    for a, b in zip(known, known[1:]):
        speed[b] = math.dist(pts[a], pts[b]) / (b - a)
    speed = np.convolve(speed, np.ones(3) / 3, mode="same")  # calm the jitter
    fast = int(np.argmax(speed))
    # wind-up top: walk back from the fastest bit while the stick keeps getting slower (small jitter allowed)
    top = fast
    while top > 0 and speed[top - 1] <= speed[top] + 0.03 * speed[fast]:
        top -= 1
    # the hold at the top ends at the last still-slow frame before the strike
    held = max(i for i in range(top, fast + 1) if speed[i] <= speed[top] + 0.05 * speed[fast])
    hit = next((i for i in range(fast, len(frames)) if speed[i] < 0.3 * speed[fast]), len(frames) - 1)
    keys = {"ready": known[0], "windup_top": held, "hit": hit, "recovery": known[-1]}
    keys["timing_s"] = {"windup": round((top - known[0]) / fps, 3), "hold_at_top": round((held - top) / fps, 3),
                        "strike": round((hit - held) / fps, 3), "recovery": round((known[-1] - hit) / fps, 3)}
    return keys


def draw(img, f):
    j = f.get("pixels")
    if j:
        for a, b in BONES:
            cv2.line(img, tuple(map(int, j[a])), tuple(map(int, j[b])), (255, 255, 255), 3)
    for key, col in (("left_glove", (0, 0, 255)), ("right_glove", (255, 0, 0))):
        if f.get(key):
            cv2.circle(img, tuple(map(int, f[key])), 14, col, 3)
    if f.get("stick_head") and f.get("stick_grip"):
        cv2.line(img, tuple(map(int, f["stick_head"])), tuple(map(int, f["stick_grip"])), (0, 255, 255), 5)
        cv2.circle(img, tuple(map(int, f["stick_head"])), 10, (0, 200, 255), -1)


def run(video, view, out, gloves=("red", "blue"), tape=("yellow", "green"), pose=True):
    cap = cv2.VideoCapture(str(video))
    if not cap.isOpened():
        raise SystemExit(f"Can't open {video}")
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    marker = make_pose() if pose else None
    frames, images, i = [], [], 0
    while True:
        ok, img = cap.read()
        if not ok:
            break
        h, w = img.shape[:2]
        min_area = max(12, w * h // 20000)
        hsv = cv2.cvtColor(cv2.GaussianBlur(img, (5, 5), 0), cv2.COLOR_BGR2HSV)
        f = {"frame": i, "t": round(i / fps, 4), "left_glove": find_color(hsv, gloves[0], min_area),
             "right_glove": find_color(hsv, gloves[1], min_area), "stick_head": find_color(hsv, tape[0], min_area),
             "stick_grip": find_color(hsv, tape[1], min_area)}
        if f["stick_head"] and f["stick_grip"]:  # handle angle in the picture: 0 = pointing right, 90 = straight up
            dx, dy = f["stick_head"][0] - f["stick_grip"][0], f["stick_grip"][1] - f["stick_head"][1]
            f["handle_angle_deg"] = round(math.degrees(math.atan2(dy, dx)), 1)
        if marker:
            import mediapipe as mp
            res = marker.detect_for_video(mp.Image(image_format=mp.ImageFormat.SRGB,
                                                   data=cv2.cvtColor(img, cv2.COLOR_BGR2RGB)), int(i * 1000 / fps))
            if res.pose_landmarks:
                lm = res.pose_landmarks[0]
                f["pixels"] = {k: [lm[n].x * w, lm[n].y * h] for k, n in JOINTS.items()}
                f["body"] = body_numbers(res.pose_world_landmarks[0])
        frames.append(f)
        images.append(img)
        i += 1
    cap.release()
    keys = pick_keys(frames, fps)
    out.mkdir(parents=True, exist_ok=True)
    name = Path(video).stem
    data = {"video": Path(video).name, "view": view, "fps": fps, "frames_total": len(frames), "keys": keys,
            "key_poses": {k: frames[n] for k, n in (keys or {}).items() if k != "timing_s"}, "frames": frames}
    (out / f"{name}.json").write_text(json.dumps(data, indent=1))
    if keys:
        tiles = []
        for k in ("ready", "windup_top", "hit", "recovery"):
            img = images[keys[k]].copy()
            draw(img, frames[keys[k]])
            img = cv2.resize(img, (480, int(480 * img.shape[0] / img.shape[1])))
            cv2.putText(img, f"{k}  ({frames[keys[k]]['t']:.2f}s)", (12, 34), cv2.FONT_HERSHEY_SIMPLEX, 0.9,
                        (0, 0, 0), 5)
            cv2.putText(img, f"{k}  ({frames[keys[k]]['t']:.2f}s)", (12, 34), cv2.FONT_HERSHEY_SIMPLEX, 0.9,
                        (255, 255, 255), 2)
            tiles.append(img)
        cv2.imwrite(str(out / f"{name}_sheet.png"), np.hstack(tiles))
    return data


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("videos", nargs="+")
    ap.add_argument("--view", choices=["side", "front"], required=True)
    ap.add_argument("--out", default="out")
    ap.add_argument("--gloves", nargs=2, default=["red", "blue"], metavar=("LEFT", "RIGHT"), choices=COLORS)
    ap.add_argument("--tape", nargs=2, default=["yellow", "green"], metavar=("HEAD", "GRIP"), choices=COLORS)
    a = ap.parse_args()
    for v in a.videos:
        d = run(v, a.view, Path(a.out), tuple(a.gloves), tuple(a.tape))
        k = d["keys"]
        seen = sum(1 for f in d["frames"] if f.get("body"))
        print(f"{d['video']}: {d['frames_total']} frames, body found in {seen}, keys: "
              + (json.dumps(k) if k else "NONE (stick tape not found: check --tape colours and the light)"))
