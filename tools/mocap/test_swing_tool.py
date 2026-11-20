"""Self-check for swing_from_video.py without a real person: a made-up video of a taped stick doing a slow
wind-up, a pause at the top, a fast strike and a slow recovery, with two coloured 'gloves' on it.
Run: .venv/bin/python test_swing_tool.py"""
import math
import tempfile
from pathlib import Path

import cv2
import numpy as np

import swing_from_video as tool

FPS = 60
# (seconds, stick angle at the end of this part in degrees: 0 = pointing forward, 120 = up and back over the head)
PLAN = [(0.5, 0), (0.6, 120), (0.2, 120), (0.15, -40), (0.6, -30)]
BGR = {"red": (40, 30, 220), "blue": (220, 60, 30), "yellow": (40, 230, 240), "green": (60, 200, 40)}


def angles():
    a, out = 0.0, []
    for secs, to in PLAN:
        n = int(secs * FPS)
        out += [a + (to - a) * (k + 1) / n for k in range(n)]
        a = to
    return out


def make_video(path):
    vw = cv2.VideoWriter(str(path), cv2.VideoWriter_fourcc(*"mp4v"), FPS, (640, 480))
    pivot = np.array([320.0, 260.0])
    for deg in angles():
        img = np.full((480, 640, 3), 90, np.uint8)
        d = np.array([math.cos(math.radians(deg)), -math.sin(math.radians(deg))])
        grip, head = pivot - d * 40, pivot + d * 150
        cv2.line(img, tuple(map(int, grip)), tuple(map(int, head)), (120, 90, 60), 8)
        cv2.circle(img, tuple(map(int, head)), 10, BGR["yellow"], -1)
        cv2.circle(img, tuple(map(int, grip)), 10, BGR["green"], -1)
        cv2.circle(img, tuple(map(int, grip + d * 15)), 12, BGR["red"], -1)
        cv2.circle(img, tuple(map(int, grip + d * 90)), 12, BGR["blue"], -1)
        vw.write(img)
    vw.release()


def main():
    with tempfile.TemporaryDirectory() as tmp:
        vid = Path(tmp) / "fake_chop.mp4"
        make_video(vid)
        d = tool.run(vid, "side", Path(tmp) / "out", pose=False)
        k, n = d["keys"], d["frames_total"]
        assert k, "no key poses found"
        found = sum(1 for f in d["frames"] if f["stick_head"] and f["left_glove"] and f["right_glove"])
        assert found > n * 0.9, f"markers found in only {found}/{n} frames"
        top_from, top_to = int(1.1 * FPS) - 6, int(1.3 * FPS) + 2  # the pause at the top
        assert top_from <= k["windup_top"] <= top_to, f"wind-up top at frame {k['windup_top']}"
        strike_end = int(1.45 * FPS)
        assert strike_end - 4 <= k["hit"] <= strike_end + 8, f"hit at frame {k['hit']}, strike ends {strike_end}"
        assert 0.1 <= k["timing_s"]["strike"] <= 0.25, k["timing_s"]
        assert 0.1 <= k["timing_s"]["hold_at_top"] <= 0.3, k["timing_s"]
        top = d["frames"][k["windup_top"]]["handle_angle_deg"]
        assert 100 < top < 140, f"handle angle at the top {top}"
        assert (Path(tmp) / "out" / "fake_chop_sheet.png").exists()
        print("OK", k)


if __name__ == "__main__":
    main()
