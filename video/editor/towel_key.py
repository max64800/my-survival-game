"""Orange-towel key + RVM guard over a game shot with the logo (test 2026-11-18).
Usage: editor/.venv/bin/python editor/towel_key.py <dir with clip.mp4 (1080x1920) + rvm.mp4 from matte_rvm.py> <bg.jpg> <logo.png>
Towel hue 19 (OpenCV 0-180), towel sat 150-190 vs skin ~65: re-measure if the light or towel changes. Writes <dir>/preview.mp4."""
import subprocess, sys
import cv2, numpy as np

d, bg_path, logo_path = sys.argv[1:4]
W, H = 1080, 1920
SCALE = 0.86  # person size; anchored to the bottom so more game shows above

def frames(path, gray=False):
    p = subprocess.Popen(["ffmpeg", "-v", "error", "-i", path, "-f", "rawvideo", "-pix_fmt", "gray" if gray else "bgr24", "-"], stdout=subprocess.PIPE)
    n = W * H * (1 if gray else 3)
    while (b := p.stdout.read(n)) and len(b) == n:
        yield np.frombuffer(b, np.uint8).reshape((H, W) if gray else (H, W, 3))

# background: game shot cropped to 9:16, a touch of blur so the person pops
bg = cv2.imread(bg_path)
s = H / bg.shape[0]; bg = cv2.resize(bg, None, fx=s, fy=s)
x0 = int(bg.shape[1] * 0.62 - W / 2); x0 = max(0, min(x0, bg.shape[1] - W))
bg = np.clip(cv2.GaussianBlur(bg[:, x0:x0 + W], (0, 0), 3).astype(np.float32) * 1.35 + 8, 0, 255)
logo = cv2.imread(logo_path, cv2.IMREAD_UNCHANGED)
lw = 900; logo = cv2.resize(logo, (lw, int(logo.shape[0] * lw / logo.shape[1])))
if logo.shape[2] == 3:  # no alpha: treat black as clear
    a = np.clip(logo.max(2).astype(np.float32) / 40, 0, 1)
else:
    a = logo[:, :, 3].astype(np.float32) / 255
ly, lx = 60, (W - lw) // 2
roi = bg[ly:ly + logo.shape[0], lx:lx + lw]
roi[:] = roi * (1 - a[..., None]) + logo[:, :, :3] * a[..., None]

out = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgr24", "-s", f"{W}x{H}", "-r", "30", "-i", "-",
                        "-i", f"{d}/clip.mp4", "-map", "0:v", "-map", "1:a", "-c:v", "libx264", "-crf", "16", "-pix_fmt", "yuv420p",
                        "-c:a", "copy", "-shortest", f"{d}/preview.mp4"], stdin=subprocess.PIPE)
k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (41, 41))
for i, (fr, rvm) in enumerate(zip(frames(f"{d}/clip.mp4"), frames(f"{d}/rvm.mp4", True))):
    hsv = cv2.cvtColor(fr, cv2.COLOR_BGR2HSV).astype(np.float32)
    h, sat, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    hue_ok = np.clip(1 - (np.abs(h - 19) - 6) / 4, 0, 1)          # towel hue 19, full within ±6
    towel = hue_ok * np.clip((sat - 95) / 40, 0, 1) * (v > 50)    # skin sat ~65, towel 150-190
    alpha = 1 - towel
    guard = cv2.dilate(rvm, k).astype(np.float32) / 255           # removes the wall strip / edges the towel misses
    core = cv2.erode(rvm, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25))).astype(np.float32) / 255
    alpha = np.maximum(alpha * guard, cv2.GaussianBlur(core, (0, 0), 6))  # fill holes inside the person (shadowed arm, hair)
    alpha = cv2.GaussianBlur(alpha, (0, 0), 1.2)
    alpha = np.clip((alpha - 0.15) / 0.75, 0, 1)                 # firm up the edge
    f = fr.astype(np.float32)
    # spill: pull orange out of the edge pixels
    edge = (alpha < 0.98)[..., None] * hue_ok[..., None]
    grey = f.mean(2, keepdims=True)
    f = f * (1 - 0.6 * edge) + grey * 0.6 * edge
    sw, sh = int(W * SCALE), int(H * SCALE)
    fs = cv2.resize(f, (sw, sh)); as_ = cv2.resize(alpha, (sw, sh))[..., None]
    comp = bg.copy(); y = H - sh; x = (W - sw) // 2
    comp[y:, x:x + sw] = comp[y:, x:x + sw] * (1 - as_) + fs * as_
    if i == 150:
        cv2.imwrite(f"{d}/check_alpha.png", (alpha * 255).astype(np.uint8))
        cv2.imwrite(f"{d}/check_comp.png", comp.astype(np.uint8))
    out.stdin.write(comp.astype(np.uint8).tobytes())
out.stdin.close(); out.wait()
print("done")
