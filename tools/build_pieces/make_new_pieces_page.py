# Packs the 3D page for the proposed new building pieces (owner, Nov 21): the sketch GLBs from
# tools/asset_forge/builds/new_pieces_sketch.py plus the real pieces they stand beside, each turned into a .json
# glTF with its buffer inside (artifact pages can't fetch .glb or blob: URLs), next to new_pieces_page.html.
#   python tools/build_pieces/make_new_pieces_page.py <sketch glb folder> <page folder>
import base64
import json
import shutil
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
REAL = ["wall__cut_stone", "floor__cut_stone", "stairs__cut_stone", "railing__cut_stone", "sloped_wall__cut_stone",
	"wall__clay_brick", "roof_45_outer__clay_brick", "wall__plank_root", "floor__plank_root"]


def pack(src: Path, dst: Path):
	dat = src.read_bytes()
	n = struct.unpack("<I", dat[12:16])[0]
	g = json.loads(dat[20:20 + n])
	b = dat[20 + n + 8:]
	g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
	dst.write_text(json.dumps(g, separators=(",", ":")))


if __name__ == "__main__":
	sketches, page = Path(sys.argv[1]), Path(sys.argv[2])
	(page / "m").mkdir(parents=True, exist_ok=True)
	for f in sketches.glob("*__sketch.glb"):
		pack(f, page / "m" / (f.stem + ".json"))
	for k in REAL:
		pack(GAME / "assets/models/build" / f"{k}.glb", page / "m" / f"{k}.json")
	shutil.copy(Path(__file__).with_name("new_pieces_page.html"), page / "index.html")
	print("page packed:", len(list((page / "m").glob("*.json"))), "models")
