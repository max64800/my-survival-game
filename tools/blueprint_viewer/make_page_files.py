# Make the files the blueprint 3D page needs: bp.json (piece list) + m/<piece>.json (each kind of piece once).
#   python tools/blueprint_viewer/make_page_files.py <blueprint.json from dump_blueprint.gd> <page folder>
import base64, json, struct, sys
from pathlib import Path

bp = json.load(open(sys.argv[1], encoding="utf-8"))
out = Path(sys.argv[2])
(out / "m").mkdir(parents=True, exist_ok=True)
json.dump({"pieces": bp["pieces"]}, open(out / "bp.json", "w"), separators=(",", ":"))
for p in sorted({(p["id"], p["mat"]) for p in bp["pieces"]}):
	d = Path(f"assets/models/build/{p[0]}__{p[1]}.glb").read_bytes()
	n = struct.unpack("<I", d[12:16])[0]
	g = json.loads(d[20:20 + n])
	b = d[20 + n + 8:]
	g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
	(out / "m" / f"{p[0]}.json").write_text(json.dumps(g, separators=(",", ":")))
	print("wrote", p[0])
