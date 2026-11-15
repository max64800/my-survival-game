"""Cuts the approved creature pictures into one picture per variant, with the background removed.

    <AI3D_HOME>/venv-web/Scripts/python tools/asset_forge/creature_sources.py

Reads assets/concepts/creatures/<creature>.png (the main picture = the "mossy" variant) and
<creature>_variants.png (a 2x2 grid: mossy, frost / ember, spore). Writes, in <AI3D_HOME>/work/creatures/:
  <creature>_<variant>.png      the picture to forge
  <creature>_<variant>_cut.png  the same with a see-through background (its outline is used to line up
                                the 3D model with the picture when painting the colours back on)
"""
import os
from pathlib import Path

from PIL import Image
from rembg import new_session, remove

GAME = Path(__file__).resolve().parents[2]
SRC = GAME / "assets" / "concepts" / "creatures"
OUT = Path(os.environ.get("AI3D_HOME", Path.home() / "ai3d")) / "work" / "creatures"
CREATURES = ["rock_snail", "cave_bat", "rock_beetle"]
GRID = {"frost": (1, 0), "ember": (0, 1), "spore": (1, 1)}  # (column, row) in the 2x2 grid; mossy = the main picture


def pad(img, margin=0.08):
	"""Put the picture on a slightly bigger light-grey canvas so nothing touches the edges."""
	w, h = img.size
	m = int(max(w, h) * margin)
	c = Image.new("RGB", (w + 2 * m, h + 2 * m), (200, 200, 200))
	c.paste(img, (m, m))
	return c


def main():
	OUT.mkdir(parents=True, exist_ok=True)
	session = new_session("isnet-general-use")  # Apache-2.0 background cutter (BRIA's isn't free for games)
	for c in CREATURES:
		pics = {"mossy": Image.open(SRC / f"{c}.png").convert("RGB")}
		grid = Image.open(SRC / f"{c}_variants.png").convert("RGB")
		gw, gh = grid.size[0] // 2, grid.size[1] // 2
		for name, (col, row) in GRID.items():
			pics[name] = pad(grid.crop((col * gw, row * gh, (col + 1) * gw, (row + 1) * gh)))
		for name, im in pics.items():
			base = OUT / f"{c}_{name}"
			im.save(f"{base}.png")
			cut = remove(im, session=session)
			cut.save(f"{base}_cut.png")
			print("made", base.name, im.size)


if __name__ == "__main__":
	main()
