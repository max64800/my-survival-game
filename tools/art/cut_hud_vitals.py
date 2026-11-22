"""Cut the ChatGPT hunger/thirst sheet (3 x 2: food ideas on top, water ideas below) into 128 px pictures (F638).

Usage: <AI3D_HOME>/venv-web/Scripts/python tools/art/cut_hud_vitals.py tools/art/sheets/hud_vitals_sheet_nov22.png <out_dir> name1 ... name6
The owner picked the stew (cell 3) and the drop (cell 4): copied to assets/icons/hud/hunger.png and thirst.png.
Background removal: rembg with ISNet (Apache-2.0), same as tools/asset_forge/icons.py.
"""
import sys
from PIL import Image
from rembg import new_session, remove
sheet = Image.open(sys.argv[1]).convert("RGB"); out = sys.argv[2]; names = sys.argv[3:]
w, h = sheet.size; cw, ch = w / 3, h / 2
s = new_session("isnet-general-use")
for i, n in enumerate(names):
    c, r = i % 3, i // 3; pad = 0.02
    cell = remove(sheet.crop((int((c+pad)*cw), int((r+pad)*ch), int((c+1-pad)*cw), int((r+1-pad)*ch))), session=s)
    cell = cell.crop(cell.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox())
    side = int(max(cell.size) / 0.92)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0)); sq.paste(cell, ((side-cell.width)//2, (side-cell.height)//2))
    sq.resize((128, 128), Image.LANCZOS).save(f"{out}/{n}.png"); print(n, "ok")
