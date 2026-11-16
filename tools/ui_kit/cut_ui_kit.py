"""Cuts the "dwarf workshop" UI kit sheet (ChatGPT, owner-approved, F187) into pieces.

Magenta background -> see-through; each piece is cropped by its box on the sheet and saved
as assets/ui/kit/<name>.png. src/ui/ui_kit.gd turns them into stretchable 9-slice styles.

Usage:  python3 tools/ui_kit/cut_ui_kit.py
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SHEET = os.path.join(ROOT, "assets", "concepts", "ui", "ui_kit_sheet_v1.png")
OUT = os.path.join(ROOT, "assets", "ui", "kit")
SCALE = 0.5  # the sheet is drawn big: at half size the frames and brackets match the game's slots and text

# name: (x0, y0, x1, y1) on the 1672x941 sheet (found by tracing the non-magenta blobs).
PIECES = {
    "panel": (77, 58, 444, 401),
    "panel_title": (522, 26, 939, 401),
    "slot": (1027, 127, 1256, 352),
    "slot_selected": (1365, 127, 1598, 352),
    "button_gold": (52, 452, 427, 542),
    "button_gold_hover": (464, 452, 826, 542),
    "button_gold_pressed": (869, 452, 1232, 542),
    "button_dark": (1268, 448, 1622, 544),
    "tab": (75, 583, 404, 682),
    "tab_selected": (447, 583, 781, 682),
    "divider": (872, 600, 1608, 639),
    "card": (814, 673, 1063, 910),
    "tooltip": (1150, 701, 1568, 879),
    "slider": (140, 758, 667, 849),
}


def main():
    a = np.asarray(Image.open(SHEET).convert("RGB")).astype(np.float32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    # How magenta a pixel is: 0 = not at all, 1 = pure background (soft edge in between).
    magenta = np.clip(((np.minimum(r, b) - g) - 60.0) / 80.0, 0.0, 1.0)
    alpha = 1.0 - magenta
    # Take the pink tint out of edge pixels (they were blended with the background).
    keep = np.clip(alpha, 1e-3, 1.0)[..., None]
    pink = np.array([255.0, 0.0, 255.0])
    rgb = np.clip((a - pink * magenta[..., None]) / keep, 0, 255)
    rgba = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    os.makedirs(OUT, exist_ok=True)
    for name, (x0, y0, x1, y1) in PIECES.items():
        piece = Image.fromarray(rgba[y0 - 2:y1 + 3, x0 - 2:x1 + 3])
        piece = piece.resize((round(piece.width * SCALE), round(piece.height * SCALE)), Image.LANCZOS)
        piece.save(os.path.join(OUT, name + ".png"))
    print("cut", len(PIECES), "pieces into", OUT)


if __name__ == "__main__":
    main()
