# Small pictures of the building pieces for the build menu (owner, Nov 15, F132: "pictures, I don't want
# to read everything"). Made from the preview each build script saves next to its model
# (journey/3d/v2_hand_built/build/<piece>__<family>.png): the grey background is cut away, the piece
# is cropped and shrunk to 96 px. Run again after models change:  python tools/model_check/make_piece_icons.py
from pathlib import Path

from PIL import Image

GAME = Path(__file__).resolve().parents[2]
SRC = GAME / "journey" / "3d" / "v2_hand_built" / "build"
MODELS = GAME / "assets" / "models" / "build"
OUT = GAME / "assets" / "icons" / "build"
SIZE = 96


def make(src: Path, out: Path) -> None:
    im = Image.open(src).convert("RGBA")
    bg = im.getpixel((2, 2))
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) < 18:
                px[x, y] = (0, 0, 0, 0)
    box = im.getbbox() or (0, 0, w, h)
    im = im.crop(box)
    side = max(im.size)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(im, ((side - im.size[0]) // 2, (side - im.size[1]) // 2))
    sq.resize((SIZE, SIZE), Image.LANCZOS).save(out)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for glb in sorted(MODELS.glob("*.glb")):
        src = SRC / (glb.stem + ".png")
        if src.exists():
            make(src, OUT / (glb.stem + ".png"))
            n += 1
    print(f"made {n} piece pictures in {OUT}")


main()
