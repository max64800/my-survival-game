"""Recipe page icons (owner, Nov 19: "pages should look different"): one page kind per thing it teaches.
Cook's Page = the Old Recipe Page picture (it already shows a cooking pot) with an amber seal. The Armourer's, Weaponsmith's and
Toolmaker's pages reuse its parchment: the pot sketch is painted out with the paper's own colour, the paper is tinted,
and the item's own icon is drawn on as a brown ink sketch, plus a coloured wax seal. Run from the game folder."""
import sys
from PIL import Image, ImageFilter, ImageOps, ImageDraw, ImageChops

ICONS = "assets/icons/"
base = Image.open(ICONS + "recipe_page.png").convert("RGBA")
W, H = base.size

# Paint the drawings out: everything darker than the paper becomes blurred paper.
rgb = base.convert("RGB")
lum = ImageOps.grayscale(rgb)
ink = lum.point(lambda v: 255 if v < 150 else 0).filter(ImageFilter.MaxFilter(5))
paper_only = Image.composite(Image.new("RGB", base.size, (0, 0, 0)), rgb, ink)
blur = paper_only.filter(ImageFilter.GaussianBlur(6))
weight = Image.composite(Image.new("L", base.size, 0), Image.new("L", base.size, 255), ink).filter(ImageFilter.GaussianBlur(6))
# normalised blur = average of nearby paper only
def norm(c_img, w_img):
    c = c_img.load(); w = w_img.load(); out = Image.new("RGB", c_img.size); o = out.load()
    for y in range(c_img.size[1]):
        for x in range(c_img.size[0]):
            k = max(w[x, y], 1) / 255.0
            o[x, y] = tuple(min(255, int(v / k)) for v in c[x, y])
    return out
filled = norm(blur, weight)
# keep the edges/curl/holes (outer 14%) as they were, paint out only the inner drawings
inner = Image.new("L", base.size, 0)
ImageDraw.Draw(inner).rounded_rectangle([W * 0.14, H * 0.16, W * 0.86, H * 0.9], 18, fill=255)
mask = ImageChops.multiply(ink, inner.filter(ImageFilter.GaussianBlur(4)))
clean = Image.composite(filled, rgb, mask)
clean.putalpha(base.getchannel("A"))


def tint(img, color, amount):
    t = Image.new("RGBA", img.size, color + (255,))
    mixed = Image.blend(img, t, amount)
    mixed.putalpha(img.getchannel("A"))
    return mixed


def ink_sketch(icon_id, size):
    ic = Image.open(ICONS + icon_id + ".png").convert("RGBA").resize((size, size), Image.LANCZOS)
    g = ImageOps.grayscale(ic.convert("RGB"))
    edges = g.filter(ImageFilter.FIND_EDGES).point(lambda v: min(255, v * 3))
    shade = ImageOps.invert(g).point(lambda v: int(v * 0.55))
    a = ImageChops.lighter(edges, shade)
    a = ImageChops.multiply(a, ic.getchannel("A"))
    out = Image.new("RGBA", (size, size), (70, 42, 22, 0))
    out.putalpha(a.point(lambda v: int(v * 0.9)))
    return out


def seal(img, color):
    d = ImageDraw.Draw(img)
    cx, cy, r = int(W * 0.78), int(H * 0.8), int(W * 0.085)
    d.ellipse([cx - r - 2, cy - r + 1, cx + r + 1, cy + r + 2], fill=tuple(int(c * 0.55) for c in color) + (255,))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (255,))
    d.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55], outline=tuple(min(255, int(c * 1.35)) for c in color) + (255,), width=2)
    return img


PAGES = {  # id: (paper tint, amount, icon drawn on, seal colour)
    "armour_page": ((150, 160, 170), 0.35, "helm_copper", (70, 90, 150)),
    "weapon_page": ((185, 120, 100), 0.30, "sword_copper", (150, 35, 30)),
    "tool_page": ((150, 160, 105), 0.30, "pickaxe_copper", (60, 110, 50)),
}
seal(base.copy(), (200, 120, 30)).save(ICONS + "cook_page.png")
for pid, (paper, amt, icon_id, seal_c) in PAGES.items():
    page = tint(clean, paper, amt)
    sk = ink_sketch(icon_id, int(W * 0.62))
    page.alpha_composite(sk, (int(W * 0.19), int(H * 0.2)))
    seal(page, seal_c)
    page.save(ICONS + pid + ".png")
print("ok")
