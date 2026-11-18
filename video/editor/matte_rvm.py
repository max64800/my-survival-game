"""Person matte with Robust Video Matting (RVM, MobileNetV3, ONNX): white = person.
Replaces matte.py for behind-head text. The mediapipe selfie model works at 256x256 and is
smoothed over time, so on full-body shots its head edge was blobby and lagged behind camera
moves, and letters showed through Max's head (Facebook ads review, 2026-10-25). RVM is a video
matting model with recurrent state: fine hair edges, no lag.

Usage: editor/.venv/bin/python editor/matte_rvm.py in_1080x1920.mp4 out_matte.mp4
Model: editor/models/rvm/rvm_mobilenetv3_fp32.onnx (github.com/PeterL1n/RobustVideoMatting v1.0.0)
"""
import subprocess, sys
from pathlib import Path

import numpy as np
import onnxruntime as ort

MODEL = Path(__file__).resolve().parent / "models" / "rvm" / "rvm_mobilenetv3_fp32.onnx"
W, H = 1080, 1920
DOWNSAMPLE = 0.375      # internal resolution 405x720: enough detail for a full-body presenter


def main(src, dst, fps=30):
    sess = ort.InferenceSession(str(MODEL), providers=["CPUExecutionProvider"])
    rec = [np.zeros((1, 1, 1, 1), np.float32)] * 4
    ratio = np.array([DOWNSAMPLE], np.float32)
    reader = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-i", str(src), "-vf", f"scale={W}:{H}",
                               "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    writer = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "gray",
                               "-s", f"{W}x{H}", "-r", str(fps), "-i", "-", "-c:v", "libx264", "-crf", "10",
                               "-pix_fmt", "yuv420p", str(dst)], stdin=subprocess.PIPE)
    n = 0
    while True:
        buf = reader.stdout.read(W * H * 3)
        if len(buf) < W * H * 3:
            break
        x = np.frombuffer(buf, np.uint8).reshape(H, W, 3).astype(np.float32) / 255
        out = sess.run(None, {"src": x.transpose(2, 0, 1)[None], "r1i": rec[0], "r2i": rec[1],
                              "r3i": rec[2], "r4i": rec[3], "downsample_ratio": ratio})
        pha, rec = out[1][0, 0], out[2:]
        writer.stdin.write((np.clip(pha, 0, 1) * 255).astype(np.uint8).tobytes())
        n += 1
    writer.stdin.close(); writer.wait()
    print(f"matte (rvm): {n} frames -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
