"""Hearth Manor's new Hearthbrick pieces on a 3D page (for the owner's OK before the manor is built):
station "alone" = each new piece on the ground; station "house" = a little Hearthbrick house that uses them all:
a balcony on brackets (corbel) with 1 m railing ends (railing_narrow), trim bands (cornice) with a corner block
on its side and back, and a roof window (dormer) on its steep roof.
	python tools/ruins/make_manor_pieces_page.py <page folder>   (writes scene.json and m/*.json next to the page)"""
import base64
import json
import shutil
import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
NEWDIR = GAME / "journey" / "hearthbrick_v2" / "glb"   # the new pieces (not in the game until the owner's OK)
B = "clay_brick"


def P(pid, x, y, z, rot=0, star=False):
	d = {"id": pid, "mat": B, "pos": [x, y, z], "rot": rot}
	if star:
		d["star"] = True
	return d


def alone():
	return [P("corbel", -3.8, 0.0, 0.0, star=True), P("cornice", -1.4, 0.0, 0.0, star=True),
		P("cornice_corner", -0.05, 0.0, 0.0, star=True), P("railing_narrow", 1.4, 0.0, 0.0, star=True),
		P("dormer", 3.8, -0.42, 0.0, star=True)]


def house():
	s = []
	# ground storey (y 0..2), upper floor at 2 (top 2.25), upper storey 2.25..4.25, steep roof 4.25..6.25
	s += [P("wall", -1, 0, 0), P("wall", 1, 0, 0)]                                            # front (z = 0): no door under the brackets
	s += [P("wall", -1, 0, -4, 2), P("wall", 1, 0, -4, 2)]                                    # back
	s += [P("doorway", 2, 0, -1, 1), P("wall", 2, 0, -3, 1), P("wall", -2, 0, -1, 3), P("wall", -2, 0, -3, 3)]
	s += [P("floor", x, 2, z) for x in (-1, 1) for z in (-1, -3)]
	s += [P("doorway", -1, 2.25, 0), P("wall", 1, 2.25, 0), P("wall", -1, 2.25, -4, 2), P("wall", 1, 2.25, -4, 2)]
	s += [P("wall", 2, 2.25, -1, 1), P("window_wall", 2, 2.25, -3, 1), P("wall", -2, 2.25, -1, 3), P("wall", -2, 2.25, -3, 3)]
	# the balcony: two half floors jutting 1 m out, brackets under them, railings round them.
	# Brackets snap to 3 spots on each 2 m wall: its two ends and its middle (where two walls meet, one bracket
	# covers both ends; at the house's corners it sits flush with the corner)
	s += [P("floor_half", x, 2, 0.5) for x in (-1, 1)]
	s += [P("corbel", x, 1.0, 0.57, star=True) for x in (-1.75, -1.0, 0.0, 1.0, 1.75)]
	s += [P("railing", x, 2.25, 1.0) for x in (-1, 1)]
	s.append(P("railing_narrow", 1.925, 2.25, 0.41, 1, star=True))   # (the left end is open: the stairs come up there)
	# outside stairs up to the balcony's open left end: a slab, then stairs climbing toward +x (foot away from walls)
	s += [P("floor", -3, 0, 1), P("stairs", -3, 0.25, 1, 3)]
	# trim bands at the upper floor line: both sides and the back, corner blocks where they meet
	s += [P("cornice", 2.245, 1.95, z, 1, star=True) for z in (-1, -3)]
	s += [P("cornice", x, 1.95, -4.245, 2, star=True) for x in (-1, 1)]
	s += [P("cornice", -2.245, 1.95, z, 3, star=True) for z in (-1, -3)]
	s += [P("cornice_corner", sx * 2.17, 1.95, -4.17, star=True) for sx in (-1, 1)]
	# the steep roof (ridge along x at z = -2), its gables, a roof window on the front slope
	s += [P("roof_45", x, 4.25, -1, 0) for x in (-1, 1)] + [P("roof_45", x, 4.25, -3, 2) for x in (-1, 1)]
	s += [P("gable_45", sx * 2, 4.25, -1, 1) for sx in (-1, 1)] + [P("gable_45", sx * 2, 4.25, -3, 3) for sx in (-1, 1)]
	s.append(P("dormer", 1, 4.25, -1, 0, star=True))
	return s


def main():
	page = Path(sys.argv[1])
	(page / "m").mkdir(parents=True, exist_ok=True)
	st = {"alone": alone(), "house": house()}
	json.dump(st, open(page / "scene.json", "w"), separators=(",", ":"))
	for v in st.values():
		for p in v:
			key = f"{p['id']}__{p['mat']}"
			f = page / "m" / f"{key}.json"
			if f.exists():
				continue
			src = GAME / f"assets/models/build/{key}.glb"
			if not src.exists():
				src = NEWDIR / f"{key}.glb"
			dat = src.read_bytes()
			n = struct.unpack("<I", dat[12:16])[0]
			g = json.loads(dat[20:20 + n])
			b = dat[20 + n + 8:]
			g["buffers"] = [{"byteLength": len(b), "uri": "data:application/octet-stream;base64," + base64.b64encode(b).decode()}]
			f.write_text(json.dumps(g, separators=(",", ":")))
	print("page files written:", {k: len(v) for k, v in st.items()})


if __name__ == "__main__":
	main()
