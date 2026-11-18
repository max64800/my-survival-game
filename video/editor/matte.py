"""Person matte for a 1080x1920 video: white = person, black = background.
Used to put graphics *behind* the speaker (text between him and the wall).

Usage: editor/.venv/bin/python editor/matte.py out/IMG_3760_cut.mp4 work/IMG_3760/matte.mp4
"""
import subprocess, sys
from pathlib import Path

import cv2
import numpy as np
import mediapipe as mp
from mediapipe.tasks.python import BaseOptions, vision

MODEL = Path(__file__).resolve().parent / "models" / "selfie_multiclass_256x256.tflite"
W, H = 1080, 1920
SW, SH = 540, 960          # run the model at half size, then upscale the mask
SMOOTH = 0.55              # temporal smoothing (0 = none): stops the edge from flickering
import os
FIRM = os.environ.get("MATTE_FIRM") == "1"   # MATTE_FIRM=1: crisper edge


def main(src, dst, fps=30):
    seg = vision.ImageSegmenter.create_from_options(vision.ImageSegmenterOptions(
        base_options=BaseOptions(model_asset_path=str(MODEL)),
        running_mode=vision.RunningMode.VIDEO, output_confidence_masks=True))
    reader = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-i", str(src), "-vf", f"scale={SW}:{SH}",
                               "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    writer = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "gray",
                               "-s", f"{W}x{H}", "-r", str(fps), "-i", "-", "-c:v", "libx264", "-crf", "12",
                               "-pix_fmt", "yuv420p", str(dst)], stdin=subprocess.PIPE)
    prev, n = None, 0
    while True:
        buf = reader.stdout.read(SW * SH * 3)
        if len(buf) < SW * SH * 3:
            break
        frame = np.frombuffer(buf, np.uint8).reshape(SH, SW, 3)
        res = seg.segment_for_video(mp.Image(image_format=mp.ImageFormat.SRGB, data=frame), int(n * 1000 / fps))
        person = 1.0 - res.confidence_masks[0].numpy_view()          # class 0 = background
        person = person if prev is None else SMOOTH * prev + (1 - SMOOTH) * person
        prev = person
        m = cv2.resize(person, (W, H), interpolation=cv2.INTER_LINEAR)
        if FIRM:   # crisper edge (behind-head words: a soft halo made letters look "clipped", Max 2026-10-18)
            m = cv2.GaussianBlur(np.clip((m - 0.45) / 0.16, 0, 1), (0, 0), 1.1)
        else:
            m = cv2.GaussianBlur(np.clip((m - 0.35) / 0.3, 0, 1), (0, 0), 2.0)   # firm but soft edge
        writer.stdin.write((m * 255).astype(np.uint8).tobytes())
        n += 1
    writer.stdin.close(); writer.wait()
    print(f"matte: {n} frames -> {dst}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
