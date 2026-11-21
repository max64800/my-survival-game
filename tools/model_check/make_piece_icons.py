# Small pictures of the building pieces for the build menu (owner, Nov 15, F132: "pictures, I don't want
# to read everything"). Made from the preview each build script saves next to its model
# (journey/3d/v2_hand_built/build/<piece>__<family>.png): the grey background is cut away, the piece
# is cropped and shrunk to 96 px. Run again after models change:  python tools/model_check/make_piece_icons.py
import re
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


# Home decor pieces (Trophies, Living, Kitchen & Workshop, Lights & Plants tabs): one model for every material, its
# preview in journey/3d/v2_hand_built/decor/<model>.png. Read from pieces.gd: one picture per material it allows.
DECOR_SRC = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
PIECES = GAME / "src" / "build" / "pieces.gd"
NAMED = {"WOODS": ["plank_root", "plank_mushroom"]}


def home_decor() -> list:
    text = PIECES.read_text(encoding="utf-8")
    groups = re.search(r"const HOME_GROUPS := \[([^\]]*)\]", text).group(1)
    home = re.findall(r'"(\w+)"', groups)
    out = []
    for entry in re.split(r"\n(?=\t\")", text):  # one catalog entry: its first line and the lines under it
        m = re.match(r'\t"(\w+)": \{name = .*?group = "(\w+)".*?model = "decor/(\w+)", families = (\w+|\[[^\]]*\])', entry, re.S)
        if m and m.group(2) in home:
            pid, _group, model, fams = m.groups()
            out.append((pid, model, NAMED[fams] if fams in NAMED else re.findall(r'"(\w+)"', fams)))
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    n = 0
    for glb in sorted(MODELS.glob("*.glb")):
        src = SRC / (glb.stem + ".png")
        if src.exists():
            make(src, OUT / (glb.stem + ".png"))
            n += 1
    for pid, model, fams in home_decor():
        src = DECOR_SRC / (model + ".png")
        if src.exists():
            for fam in fams:
                make(src, OUT / ("%s__%s.png" % (pid, fam)))
                n += 1
    print(f"made {n} piece pictures in {OUT}")


main()
