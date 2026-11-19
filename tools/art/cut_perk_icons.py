"""Cut a ChatGPT perk sheet (4 x 3 grid of stone tiles) into one 128 px picture per perk.

Usage: python3 tools/art/cut_perk_icons.py <sheet.png> <perk_id> <perk_id> ...   ("-" skips a cell)
Writes assets/icons/perks/<perk_id>.png. Each cell is trimmed to its tile (what differs from the sheet's
dark background), squared, and shrunk to 128 x 128.
"""
import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[2] / "assets" / "icons" / "perks"
COLS, ROWS, SIZE = 4, 3, 128


def tile_box(cell: Image.Image) -> tuple:
    """Bounding box of the tile inside one grid cell (pixels brighter than the background)."""
    grey = cell.convert("L")
    bg = sorted(grey.getpixel(p) for p in [(1, 1), (cell.width - 2, 1), (1, cell.height - 2), (cell.width - 2, cell.height - 2)])[1]
    mask = grey.point(lambda v: 255 if abs(v - bg) > 18 else 0)
    box = mask.getbbox() or (0, 0, cell.width, cell.height)
    # square it around its centre so the picture isn't stretched
    cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
    half = max(box[2] - box[0], box[3] - box[1]) / 2
    return (int(cx - half), int(cy - half), int(cx + half), int(cy + half))


def main() -> None:
    sheet = Image.open(sys.argv[1]).convert("RGBA")
    names = sys.argv[2:]
    assert len(names) <= COLS * ROWS, "a sheet holds 12 pictures"
    OUT.mkdir(parents=True, exist_ok=True)
    cw, ch = sheet.width / COLS, sheet.height / ROWS
    for i, name in enumerate(names):
        if name == "-":
            continue
        c, r = i % COLS, i // COLS
        cell = sheet.crop((int(c * cw), int(r * ch), int((c + 1) * cw), int((r + 1) * ch)))
        tile = cell.crop(tile_box(cell)).resize((SIZE, SIZE), Image.LANCZOS)
        tile.save(OUT / f"{name}.png")
        print("wrote", name)


if __name__ == "__main__":
    main()
