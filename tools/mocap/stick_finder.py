"""Finds a plain white stick held in the pale-gloved fist (F389 chat 13: the owner's sword/mace videos, no tape).
The stick is a thin bright line starting at the fist. A 'top-hat' filter keeps only thin bright things (it drops the
big white shirt and the wall). Then, from a few start points round the fist, every direction is walked outward and
the bright run is added up; the longest, brightest run wins.
Used by one_hand_targets.py. By the dwarf-animations Claude, chat 13, Nov 20, 2026."""
import math
import cv2
import numpy as np

ANGLES = np.radians(np.arange(0, 360, 2.0))
RADII = np.arange(14, 420, 2.0)  # (long enough for the whole stick: 260 cut it short at the hit, chat 13)
KERNEL = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))


def ridge_image(img):
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV).astype(np.float32)
    white = np.clip(hsv[:, :, 2] - 1.5 * hsv[:, :, 1], 0, 255).astype(np.uint8)
    return cv2.morphologyEx(white, cv2.MORPH_TOPHAT, KERNEL).astype(np.float32)


def find(img, hand, prev=None, spread=14, ridge=None):
    """img: BGR picture, hand: (x, y) of the fist (a guess). Returns dict(angle (deg, 0 = right, 90 = UP),
    length (px), start (x, y), score) or None. prev: last frame's angle (a small bonus near it)."""
    th = ridge_image(img) if ridge is None else ridge
    h, w = th.shape
    dx, dy = np.cos(ANGLES)[:, None], -np.sin(ANGLES)[:, None]
    best = None
    for ox in (-spread, 0, spread):
        for oy in (-spread, 0, spread):
            cx, cy = hand[0] + ox, hand[1] + oy
            xs = np.clip(cx + dx * RADII, 0, w - 1).astype(int)
            ys = np.clip(cy + dy * RADII, 0, h - 1).astype(int)
            v = th[ys, xs]  # angles x radii
            good = v > 14
            # the bright run from the start: stops at the first gap of 4+ samples
            gapc = np.zeros(good.shape[0]); alive = np.ones(good.shape[0], bool)
            run = np.zeros(good.shape[0]); end = np.zeros(good.shape[0])
            for i in range(good.shape[1]):
                g = good[:, i]
                gapc = np.where(g, 0, gapc + 1)
                alive &= gapc < 4
                run += np.where(alive & g, np.minimum(v[:, i], 60), 0)
                end = np.where(alive & g, RADII[i], end)
            score = run.copy()
            if prev is not None:
                dd = np.abs((np.degrees(ANGLES) - prev + 180) % 360 - 180)
                score *= 1.0 + 0.25 * np.clip(1.0 - dd / 40.0, 0, 1)
            k = int(np.argmax(score))
            if best is None or score[k] > best["score"]:
                best = {"angle": float(np.degrees(ANGLES[k])), "length": float(end[k]), "start": [float(cx), float(cy)],
                        "score": float(score[k])}
    return best
