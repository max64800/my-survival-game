"""Picture sheet of the great axe swings for the owner (F389): one row per key pose, columns = from behind (the game
camera, matters most), from the side, from the front. Made from twohand_preview.gd's pictures (markers=1: blue = left
fist's spot, yellow = right fist's spot, orange = the handle).
    python tools/asset_forge/swing_sheet.py <folder with the preview pictures> <out.png> [--moves Chop,Sweep,Slam]
By the dwarf-animations Claude, chat 8, Nov 20, 2026.
"""
import argparse
import pathlib
from PIL import Image, ImageDraw, ImageFont

CAMS = [("back", "From behind (game camera)"), ("side", "From his right side"), ("front", "From the front")]
KEYS = [("0lift", "0. lifting the axe"), ("1windup", "1. wind-up (top)"), ("2middle", "2. on the way down"), ("3hit", "3. the hit"),
        ("4recovery", "4. recovery")]
NAMES = {"Chop": "Chop", "Sweep": "Sweep back", "Slam": "Slam"}


def font(size):
    for name in ("arialbd.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def crop(img):
    w, h = img.size  # (the dwarf stands in the middle of the picture)
    cw, ch = int(h * 0.75), h
    return img.crop(((w - cw) // 2, 0, (w + cw) // 2, ch)).resize((300, 400))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("folder")
    ap.add_argument("out")
    ap.add_argument("--moves", default="Chop,Sweep,Slam")
    a = ap.parse_args()
    folder = pathlib.Path(a.folder)
    rows = [("stance", "Ready stance")]
    for mv in a.moves.split(","):
        rows += [(f"{mv}_{k}", f"{NAMES.get(mv, mv)}: {label}") for k, label in KEYS]
    rows = [r for r in rows if (folder / f"{r[0]}_back.png").exists() or (folder / f"{r[0]}_side.png").exists()]
    lw, cw, chh, top = 230, 300, 400, 40
    sheet = Image.new("RGB", (lw + cw * len(CAMS), top + chh * len(rows)), (40, 34, 30))
    d = ImageDraw.Draw(sheet)
    for c, (_, title) in enumerate(CAMS):
        d.text((lw + c * cw + 10, 10), title, fill=(255, 230, 180), font=font(18))
    for r, (name, label) in enumerate(rows):
        y = top + r * chh
        d.text((10, y + chh // 2 - 30), label.replace(": ", ":\n"), fill=(255, 255, 255), font=font(20))
        for c, (cam, _) in enumerate(CAMS):
            p = folder / f"{name}_{cam}.png"
            if p.exists():
                sheet.paste(crop(Image.open(p).convert("RGB")), (lw + c * cw, y))
        d.line((0, y, sheet.width, y), fill=(90, 80, 70), width=2)
    d.text((10, sheet.height - 26), "blue = left fist, yellow = right fist, orange = handle", fill=(200, 200, 200),
           font=font(14))
    sheet.save(a.out)
    print("sheet:", a.out, sheet.size)


if __name__ == "__main__":
    main()
