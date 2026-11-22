# The 3D page of the Cliff Watch blueprint (owner, Nov 22: ruin 8, F479), before its ruin exists: the stone one and
# the wooden one side by side, with a "storeys" cut-away so you can see every floor.
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- stonehold_cliff_watch <stone.json>
#   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- wooden_cliff_watch <wood.json>
#   python tools/ruins/make_cliff_watch_page.py <stone.json> <wood.json> <page folder>
# Then copy tools/ruins/cliff_watch_page.html into the folder as index.html.
import base64
import json
import shutil
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
stone, wood, page = json.load(open(sys.argv[1], encoding="utf-8")), json.load(open(sys.argv[2], encoding="utf-8")), Path(sys.argv[3])
(page / "m").mkdir(parents=True, exist_ok=True)
views = {k: [{"id": p["id"], "mat": p["mat"], "pos": [round(v, 4) for v in p["pos"]], "rot": p["rot"]} for p in b["pieces"]]
	for k, b in (("stone", stone), ("wood", wood))}
json.dump({"views": views, "cost": {"stone": stone["cost"], "wood": wood["cost"]}}, open(page / "bp.json", "w"), separators=(",", ":"))
for v in views.values():
	for p in v:
		key = f"{p['id']}__{p['mat']}"
		f = page / "m" / f"{key}.json"
		if f.exists():
			continue
		dat = (GAME / f"assets/models/build/{key}.glb").read_bytes()
		n = struct.unpack("<I", dat[12:16])[0]
		g = json.loads(dat[20:20 + n])
		b = dat[20 + n + 8:]
		g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
		f.write_text(json.dumps(g, separators=(",", ":")))
shutil.copy(GAME / "tools/ruins/cliff_watch_page.html", page / "index.html")
print("page files written:", {k: len(v) for k, v in views.items()}, "kinds:", len(list((page / "m").glob("*.json"))))
