"""Face track for the cut (faces.json): [t, cx, cy, w, h] in 1080x1920 coords, 10 samples a second (YuNet)."""
import json, subprocess, sys
import cv2, numpy as np
SRC = "../../editor/motion/public/v4334/cut.mp4"
MODEL = "../../video-research/models/face_yunet.onnx"
det = cv2.FaceDetectorYN.create(MODEL, "", (540, 960), 0.7)
p = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-i", SRC, "-vf", "fps=10,scale=540:960", "-f", "rawvideo", "-pix_fmt", "bgr24", "-"], stdout=subprocess.PIPE)
out, i = [], 0
while True:
    buf = p.stdout.read(540 * 960 * 3)
    if len(buf) < 540 * 960 * 3: break
    img = np.frombuffer(buf, np.uint8).reshape(960, 540, 3)
    _, f = det.detect(img)
    if f is not None and len(f):
        x, y, w, h = f[0][:4]
        out.append([round(i / 10, 2), int((x + w / 2) * 2), int((y + h / 2) * 2), int(w * 2), int(h * 2)])
    else:
        out.append([round(i / 10, 2), None, None, None, None])
    i += 1
json.dump(out, open("faces.json", "w"))
ok = [o for o in out if o[1] is not None]
print(len(out), "samples,", len(out) - len(ok), "missed")
for k in ("cx", "cy", "w", "h"):
    j = ["t", "cx", "cy", "w", "h"].index(k); v = [o[j] for o in ok]
    print(k, "min", min(v), "median", int(np.median(v)), "max", max(v))
