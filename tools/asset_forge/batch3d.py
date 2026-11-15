"""Turn the icon sheets into 3D models, many at once (free, TripoSR on this PC).

    python batch3d.py            -> every item that should be 3D, skipping ones already made
    python batch3d.py anvil bed  -> only these item ids (always remade)

For each item it cuts the full-size picture out of its ChatGPT icon sheet (sharper than the
128 px icon), then runs forge.py on it. Results:
    stations + chests -> assets/models/stations/<id>.glb  (placed in the world)
    everything else   -> assets/models/items/<id>.glb     (lying on the ground)
Tools and weapons use their own sheets (tool_batches.json, tool_sheetNN.png) drawn standing
straight up, so the model's handle runs along +Y with the grip end at the origin.
Run with the "venv-web" Python.
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
GAME = HERE.parent.parent
AI3D = Path(os.environ.get("AI3D_HOME", Path.home() / "ai3d"))
SHEETS = AI3D / "work" / "icon_sheets"
CROPS = AI3D / "work" / "crops"
TOOL_KINDS = {"pickaxe", "axe", "weapon", "shield", "ammo", "hammer"}


def tool_height(item_id):
	"""Real height in meters of a tool standing on its grip end."""
	if item_id.startswith("bolt_"):
		return 0.4
	if "_2h_" in item_id or item_id.startswith("spear_"):
		return 1.4
	if item_id.startswith("shield_"):
		return 0.7
	if item_id.startswith("crossbow_"):
		return 0.8
	return 0.75
# kind -> (forge kind, size in meters). Forge kind "station" saves into stations/, "item" into items/.
PLACE = {"station": ("station", None), "chest": ("station", 1.0)}


def main():
	batches = json.loads((HERE / "icon_batches.json").read_text(encoding="utf-8"))
	items = {x["id"]: x for x in json.loads((HERE / "icon_items.json").read_text(encoding="utf-8"))}
	where = {i: (f"sheet{n + 1:02d}.png", k + 1) for n, b in enumerate(batches) for k, i in enumerate(b)}
	tools = json.loads((HERE / "tool_batches.json").read_text(encoding="utf-8"))
	where.update({i: (f"tool_sheet{n + 1:02d}.png", k + 1) for n, b in enumerate(tools) for k, i in enumerate(b)})
	only = sys.argv[1:]
	todo = only or list(where)
	CROPS.mkdir(parents=True, exist_ok=True)
	done, failed, t0 = 0, [], time.time()
	for item_id in todo:
		kind = items.get(item_id, {}).get("kind", "material")
		forge_kind, size = PLACE.get(kind, ("item", None))
		out = GAME / "assets" / "models" / f"{forge_kind}s" / f"{item_id}.glb"
		if out.exists() and not only:
			continue
		sheet, cell = where[item_id]
		im = Image.open(SHEETS / sheet).convert("RGB")
		w = im.width / 4
		c, r = (cell - 1) % 4, (cell - 1) // 4
		crop = im.crop((int(c * w), int(r * w), int((c + 1) * w), int((r + 1) * w))).resize((512, 512), Image.LANCZOS)
		pic = CROPS / f"{item_id}.png"
		crop.save(pic)
		cmd = [sys.executable, str(HERE / "forge.py"), str(pic), "--name", item_id, "--kind", forge_kind, "--engine", "triposr"]
		if kind in TOOL_KINDS:
			cmd += ["--size", str(tool_height(item_id)), "--fit", "height", "--crumbs", "0.005"]
		elif size:
			cmd += ["--size", str(size)]
		res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
		if res.returncode == 0 and out.exists():
			done += 1
			print(f"[{done}] {item_id} ok ({time.time() - t0:.0f} s)", flush=True)
		else:
			failed.append(item_id)
			print(f"FAILED {item_id}: {res.stderr[-400:]}", flush=True)
	print(f"BATCH DONE: {done} made, {len(failed)} failed {failed}, {time.time() - t0:.0f} s")


if __name__ == "__main__":
	main()
