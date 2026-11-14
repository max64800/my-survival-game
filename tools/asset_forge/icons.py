"""Item icons: make ChatGPT prompts, and cut ChatGPT's icon sheets into one picture per item.

    python icons.py prompts items.json        -> writes icon_batches.json + ICON_PROMPTS.md
    python icons.py cut 3 sheet.png           -> cuts batch 3's 4x4 sheet into assets/icons/<id>.png
    python icons.py contact                   -> makes a contact sheet of all icons (to check them)

items.json comes from Godot (every id, name, kind). Each batch is 16 items = one 4x4 ChatGPT sheet.
Background removal uses rembg with ISNet (Apache-2.0), never rembg's default (BRIA, not free to sell).
Run with the "venv-web" Python (it has Pillow + rembg).
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parent.parent
ICONS = GAME / "assets" / "icons"
BATCHES = HERE / "icon_batches.json"
PROMPTS = HERE / "ICON_PROMPTS.md"
SIZE = 128
GRID = 4

# Kinds that should sit together on one sheet (similar things in one picture keep the style tight).
KIND_ORDER = ["material", "fuel", "food", "drink", "pickaxe", "axe", "tool", "lantern", "weapon", "shield",
	"ammo", "station", "placeable", "gem", "rune"]

STYLE = """Create ONE square image: a sprite sheet of 16 inventory icons for a cozy-but-rough underground dwarf survival game,
arranged in a perfectly even 4 x 4 grid (4 columns, 4 rows), every icon centered in its own equal square cell.

STYLE (same for all 16): hand-painted stylized game icons, chunky and slightly exaggerated shapes with bold, simple
silhouettes, a little cartoony and charming but worn and hand-made (chips, scratches, visible brush strokes). Earthy,
slightly muted colors (browns, stone greys, moss green, rust, dull iron); bright colors only for glowing crystals,
fire, gems and magic. Soft light from the top-left, a thin dark outline around each object, three-quarter view.

RULES: plain flat light-grey background everywhere, no frames, no borders, no grid lines, no slot boxes, no text,
no numbers, no labels, no shadows on the ground. Each object fills about 75% of its cell and never touches the
cell edges. Keep the order exactly as listed, left to right, top to bottom.

The 16 icons, in order:
"""


def make_prompts(items_json):
	items = json.loads(Path(items_json).read_text(encoding="utf-8"))
	order = {k: i for i, k in enumerate(KIND_ORDER)}
	items.sort(key=lambda x: (order.get(x["kind"], len(KIND_ORDER)), x["id"]))
	batches = [items[i:i + GRID * GRID] for i in range(0, len(items), GRID * GRID)]
	BATCHES.write_text(json.dumps([[x["id"] for x in b] for b in batches], indent=1), encoding="utf-8")
	out = ["# Item icon prompts for ChatGPT", "",
		f"{len(items)} items in {len(batches)} sheets. Paste one block per ChatGPT message. Save each result and",
		"tell Claude which sheet number it is. If a sheet comes out with the wrong order or a missing icon, ask",
		"ChatGPT: \"Same sheet, keep everything, but fix icon N\".", ""]
	for n, b in enumerate(batches, 1):
		lines = [f"{i + 1}. {x['name']}" + (f" ({x['kind']})" if x["kind"] not in ("material",) else "")
			for i, x in enumerate(b)]
		while len(lines) < GRID * GRID:
			lines.append(f"{len(lines) + 1}. (leave this cell empty)")
		out += [f"## Sheet {n}", "", "```", STYLE + "\n".join(lines), "```", ""]
	PROMPTS.write_text("\n".join(out), encoding="utf-8")
	print(f"{len(items)} items -> {len(batches)} sheets. Prompts: {PROMPTS}")


def cut(batch_no, sheet_path):
	from PIL import Image
	from rembg import new_session, remove
	ids = json.loads(BATCHES.read_text(encoding="utf-8"))[batch_no - 1]
	sheet = Image.open(sheet_path).convert("RGB")
	w, h = sheet.size
	cw, ch = w / GRID, h / GRID
	session = new_session("isnet-general-use")
	ICONS.mkdir(parents=True, exist_ok=True)
	for i, item_id in enumerate(ids):
		col, row = i % GRID, i // GRID
		# Cut a little inside the cell so neighbours never bleed in.
		pad = 0.03
		box = (int((col + pad) * cw), int((row + pad) * ch), int((col + 1 - pad) * cw), int((row + 1 - pad) * ch))
		cell = remove(sheet.crop(box), session=session)
		bbox = cell.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
		if not bbox:
			print(f"  {item_id}: EMPTY cell, skipped")
			continue
		cell = cell.crop(bbox)
		# Fit into a square with a small margin, keep proportions.
		side = int(max(cell.size) / 0.88)
		square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
		square.paste(cell, ((side - cell.width) // 2, (side - cell.height) // 2))
		square.resize((SIZE, SIZE), Image.LANCZOS).save(ICONS / f"{item_id}.png")
		print(f"  {item_id}: ok")
	print(f"Sheet {batch_no}: {len(ids)} icons -> {ICONS}")


def contact():
	from PIL import Image
	files = sorted(ICONS.glob("*.png"))
	cols = 12
	rows = (len(files) + cols - 1) // cols
	sheet = Image.new("RGBA", (cols * SIZE, max(1, rows) * SIZE), (40, 36, 32, 255))
	for i, f in enumerate(files):
		im = Image.open(f).convert("RGBA")
		sheet.alpha_composite(im, ((i % cols) * SIZE, (i // cols) * SIZE))
	import os
	out = Path(os.environ.get("AI3D_HOME", Path.home() / "ai3d")) / "work" / "icons_contact.png"
	out.parent.mkdir(parents=True, exist_ok=True)
	sheet.save(out)
	print(out)


if __name__ == "__main__":
	cmd = sys.argv[1] if len(sys.argv) > 1 else ""
	if cmd == "prompts":
		make_prompts(sys.argv[2])
	elif cmd == "cut":
		cut(int(sys.argv[2]), sys.argv[3])
	elif cmd == "contact":
		contact()
	else:
		print(__doc__)
