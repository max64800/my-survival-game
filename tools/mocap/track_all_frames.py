"""Run MediaPipe Pose on every extracted frame; save pixel + world joints, plus glove/handle colour blobs."""
import json, sys
from pathlib import Path
import cv2, numpy as np
import mediapipe as mp
from mediapipe.tasks.python import BaseOptions, vision

S = Path(sys.argv[1])
MODEL = sys.argv[2]
opts = vision.PoseLandmarkerOptions(base_options=BaseOptions(model_asset_path=MODEL),
                                    running_mode=vision.RunningMode.VIDEO)
lm = vision.PoseLandmarker.create_from_options(opts)
COL = {"blue": [((95, 120, 50), (128, 255, 255))], "orange": [((5, 130, 120), (20, 255, 255))],
       "green": [((38, 60, 40), (88, 255, 255))]}

def blob(hsv, name, min_area=40):
    mask = None
    for lo, hi in COL[name]:
        m = cv2.inRange(hsv, np.array(lo), np.array(hi)); mask = m if mask is None else mask | m
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, _, st, c = cv2.connectedComponentsWithStats(mask)
    if n < 2: return None
    i = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    if st[i, cv2.CC_STAT_AREA] < min_area: return None
    return [float(c[i][0]), float(c[i][1]), int(st[i, cv2.CC_STAT_AREA])]

def line(hsv):
    """Green handle: fit a line through all green pixels -> two end points."""
    mask = cv2.inRange(hsv, np.array(COL["green"][0][0]), np.array(COL["green"][0][1]))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    ys, xs = np.nonzero(mask)
    if len(xs) < 80: return None
    pts = np.stack([xs, ys], 1).astype(np.float32)
    m = pts.mean(0); u, s, vt = np.linalg.svd(pts - m, full_matrices=False); d = vt[0]
    t = (pts - m) @ d
    a, b = m + d * np.percentile(t, 2), m + d * np.percentile(t, 98)
    return [float(a[0]), float(a[1]), float(b[0]), float(b[1]), int(len(xs))]

out = []
files = sorted((S / "frames").glob("f*.jpg"))
for k, f in enumerate(files):
    img = cv2.imread(str(f)); rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    r = lm.detect_for_video(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb), int(k * 1000 / 29.97))
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    rec = {"i": k + 1, "blue": blob(hsv, "blue"), "orange": blob(hsv, "orange"), "handle": line(hsv)}
    if r.pose_landmarks:
        h, w = img.shape[:2]
        rec["px"] = [[round(p.x * w, 1), round(p.y * h, 1), round(p.visibility, 2)] for p in r.pose_landmarks[0]]
        rec["w"] = [[round(p.x, 4), round(p.y, 4), round(p.z, 4)] for p in r.pose_world_landmarks[0]]
    out.append(rec)
    if k % 200 == 0: print(k, flush=True)
(S / "track.json").write_text(json.dumps(out))
print("done", len(out))
