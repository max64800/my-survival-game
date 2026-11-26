"""Cut the ChatGPT bronze armour sheet (2 x 2: helm, mail / greaves, boots) into the 4 bronze icons (F697 step 7).

Usage: <AI3D_HOME>/venv-web/Scripts/python tools/art/cut_bronze_armour_icons.py
Sheet: tools/art/sheets/bronze_armour_sheet_nov26.png (owner picked look "Option B", Nov 26).
Writes assets/icons/<helm|mail|greaves|boots>_bronze.png (128 px). Background removal: rembg with ISNet (Apache-2.0).
make_bronze.py no longer writes these 4 icons.
"""
from pathlib import Path
from PIL import Image
from rembg import new_session, remove

GAME = Path(__file__).resolve().parents[2]
NAMES = ["helm_bronze", "mail_bronze", "greaves_bronze", "boots_bronze"]
sheet = Image.open(GAME / "tools/art/sheets/bronze_armour_sheet_nov26.png").convert("RGB")
w, h = sheet.size
cw, ch = w / 2, h / 2
s = new_session("isnet-general-use")
for i, n in enumerate(NAMES):
	c, r = i % 2, i // 2
	pad = 0.01
	cell = remove(sheet.crop((int((c + pad) * cw), int((r + pad) * ch), int((c + 1 - pad) * cw), int((r + 1 - pad) * ch))), session=s)
	cell = cell.crop(cell.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox())
	side = int(max(cell.size) / 0.92)
	sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
	sq.paste(cell, ((side - cell.width) // 2, (side - cell.height) // 2))
	sq.resize((128, 128), Image.LANCZOS).save(GAME / "assets/icons" / f"{n}.png")
	print(n, "ok")
