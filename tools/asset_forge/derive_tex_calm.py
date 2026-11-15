# Calm kit colours (owner F73/F74, Nov 15): recolour our own hand-painted stone texture.
#   greystone_a/b/c/dark = the Stonehold main stones (one grey family), warmstone_a/b/c = the ~1 in 8 warm accent.
# python tools/asset_forge/derive_tex_calm.py   (writes into assets/textures/kit)
from pathlib import Path
from PIL import Image, ImageEnhance, ImageOps
D = Path(__file__).resolve().parents[2] / "assets" / "textures" / "kit"
def load(n): return Image.open(D / f"{n}.png").convert("RGB")
def tint(im, rgb, keep):
    g = ImageOps.grayscale(im)
    col = ImageOps.colorize(g, tuple(int(c * 0.3) for c in rgb), rgb)
    return Image.blend(col, im, keep)
def save(im, n): im.save(D / f"{n}.png"); print("made", n)
greys = {"a": ((150, 148, 144), 1.0), "b": ((138, 140, 142), 0.93), "c": ((160, 156, 150), 1.04)}
for v, (rgb, br) in greys.items():
    s = load(f"stone_{v}")
    save(ImageEnhance.Brightness(tint(s, rgb, 0.25)).enhance(br), f"greystone_{v}")
    save(ImageEnhance.Brightness(tint(s, (172, 150, 118), 0.3)).enhance(0.97), f"warmstone_{v}")
save(ImageEnhance.Brightness(load("greystone_b")).enhance(0.62), "greystone_dark")
save(ImageEnhance.Brightness(load("warmstone_c")).enhance(0.65), "warmstone_dark")
