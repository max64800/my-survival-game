# F782: the new dungeon healing fountain (owner picked design 1, Nov 22): a rune-carved stone dwarf face pours
# glowing green water into a round stone basin. Mine-timber posts with copper straps hold the head, old roots
# wind down the sides, moss on top. Built from assets/concepts/healing-fountain/fountain_turnaround.png
# (the TRELLIS shape in journey/3d/trellis_f706/ was only a shape guide, model rule 1).
# NOT in the game yet: the owner wants to see it first. Same floor spot as decor/mushroom_fountain (about 1 m round).
#   blender --background --factory-startup --python builds/healing_fountain.py -- [out.glb] [preview.png]
# Origin bottom-centre, front faces -Y in Blender (= +Z in Godot).
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, T, kit, log, rng, stone  # noqa: E402
from night_materials import C, lump, _cm  # noqa: E402
from decor_nov21_a import floor_cut  # noqa: E402
from decor_nov21_mg import carve  # noqa: E402

CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
WOOD = lambda: T("wood")  # noqa: E731
BARK = lambda: T("bark")  # noqa: E731
GREY = lambda: T("stone")  # noqa: E731
MOSS = lambda: kit.mat("moss", -0.25)
FACE = lambda: T("limestone", "b")  # noqa: E731
DARK = lambda: C((0.07, 0.06, 0.05), 0.9)  # noqa: E731
WATER_DEEP = lambda: C((0.01, 0.16, 0.07), 0.15, glow=0.4)  # noqa: E731
WATER_TOP = lambda: C((0.03, 0.5, 0.17), 0.1, glow=0.9)  # noqa: E731
WATER_POUR = lambda: C((0.12, 0.75, 0.3), 0.1, glow=1.1)  # noqa: E731

BX, BY = 0.0, -0.12      # basin centre
R_OUT, R_IN = 0.37, 0.25  # basin stone ring
TOP = 0.44               # basin rim height
WATER = 0.39             # water surface


def basin():
	n = 11
	for k in range(n):
		a = 2 * math.pi * (k + 0.5) / n - math.pi / 2   # k = 5 sits right at the front (-Y)
		rm = (R_OUT + R_IN) / 2
		h = TOP + J(0.025)
		o = stone((2 * math.pi * rm / n + 0.035, R_OUT - R_IN, h), (BX + math.cos(a) * rm, BY + math.sin(a) * rm, h / 2),
			tone=GREY(), rotz=math.degrees(a) + 90, bevel=0.025)
		if k == 5:   # front stone: a carved rune (two crossing strokes through a tall one)
			fy = BY - R_OUT + 0.005
			for rot in (0, 32, -32):
				carve(o, (0.022, 0.05, 0.19), (BX, fy, 0.22), rot=(0, rot, 0))
	# basin floor (inside the ring) and the water, in layers so they never share a surface (rule 2)
	kit.cylinder(R_IN + 0.03, 0.30, (BX, BY, 0.15), GREY(), verts=14, bevel=0.01)
	kit.cylinder(R_IN + 0.02, WATER - 0.012 - 0.30, (BX, BY, (0.30 + WATER - 0.012) / 2), WATER_DEEP(), verts=16, bevel=0)
	kit.cylinder(R_IN + 0.015, 0.012, (BX, BY, WATER - 0.006), WATER_TOP(), verts=16, bevel=0)
	# copper band round the front half, in short riveted plates pressed into each stone
	for k in (1, 2, 3, 4, 6, 7, 8, 9):
		a = 2 * math.pi * (k + 0.5) / 11 - math.pi / 2
		rr = R_OUT - 0.012
		c = (BX + math.cos(a) * rr, BY + math.sin(a) * rr, 0.2)
		B((0.17, 0.03, 0.07), c, CU("b"), bevel=0.006, rot=(0, 0, math.degrees(a) + 90))
		for s in (-0.055, 0.055):
			t = a + math.pi / 2
			kit.rivet((c[0] + math.cos(t) * s + math.cos(a) * 0.016, c[1] + math.sin(t) * s + math.sin(a) * 0.016, 0.2),
				CU("dark"), r=0.016)


def head():
	# the big stone the face is cut from, with rough boulders round its sides and back
	core = B((0.6, 0.3, 1.0), (0, 0.27, 0.5), GREY(), bevel=0.04)
	kit.roughen(core, 0.01, 1, seed=3)
	for i, (x, y, z, s) in enumerate(((-0.3, 0.32, 0.18, 0.2), (0.3, 0.3, 0.2, 0.21), (-0.27, 0.36, 0.55, 0.18),
			(0.28, 0.35, 0.58, 0.18), (-0.2, 0.36, 0.9, 0.17), (0.2, 0.35, 0.92, 0.17), (0.0, 0.42, 0.35, 0.22),
			(0.0, 0.43, 0.75, 0.2), (-0.36, 0.12, 0.12, 0.13), (0.37, 0.1, 0.12, 0.13))):
		lump((x, y, z), (s, s * 0.85, s * 0.9), T("stone"), seed=10 + i, rough=0.015)
	fy = 0.12   # front face of the core stone
	B((0.5, 0.1, 0.19), (0, fy - 0.03, 0.92), FACE(), bevel=0.03)                      # forehead
	B((0.4, 0.06, 0.07), (0, fy - 0.02, 0.775), DARK(), bevel=0.0)                     # shadow under the brow
	for sx in (-1, 1):
		B((0.24, 0.13, 0.09), (sx * 0.12, fy - 0.09, 0.83), FACE(), bevel=0.025, rot=(0, sx * 16, 0))   # heavy brow
		B((0.13, 0.06, 0.04), (sx * 0.12, fy - 0.07, 0.76), FACE(), bevel=0.012, rot=(0, -sx * 6, 0))  # shut eyelid
		lump((sx * 0.19, fy - 0.05, 0.68), (0.08, 0.06, 0.07), FACE(), seed=20 + sx)       # cheek
		B((0.2, 0.11, 0.07), (sx * 0.1, fy - 0.11, 0.6), FACE(), bevel=0.02, rot=(0, -sx * 24, 0))  # moustache
	kit.taper(0.15, 0.16, 0.07, 0.09, 0.2, (0, fy - 0.1, 0.62), FACE(), bevel=0.02)    # nose
	# mouth: a round stone lip with a dark hole, the spout
	kit.ring(0.05, 0.022, (0, fy - 0.15, 0.53), FACE(), rot=(90, 0, 0), seg=10)
	kit.cylinder(0.045, 0.14, (0, fy - 0.08, 0.53), DARK(), rot=(90, 0, 0), verts=10, bevel=0)
	# beard: three rows of chunky plates down to the water
	for row, (z, n, w) in enumerate(((0.49, 4, 0.12), (0.43, 5, 0.105), (0.38, 4, 0.11))):
		for i in range(n):
			x = (i - (n - 1) / 2) * w * 0.92
			if row == 0 and abs(x) < 0.07:
				continue   # the mouth's spout comes out here
			kit.taper(w, 0.1, w * 0.55, 0.06, 0.12, (x, fy - 0.05 - row * 0.015, z - 0.06), FACE(), bevel=0.015)
	# rune stone on top of the head (arrow rune cut in)
	rs = B((0.24, 0.14, 0.2), (0, fy + 0.02, 1.07), GREY(), bevel=0.03, rot=(0, 0, 0))
	kit.roughen(rs, 0.006, 1, seed=5)
	ry = fy - 0.05
	carve(rs, (0.022, 0.04, 0.14), (0, ry, 1.07))
	for sx in (-1, 1):
		carve(rs, (0.02, 0.04, 0.08), (sx * 0.03, ry, 1.105), rot=(0, sx * 45, 0))
	# the pour: from the mouth into the basin, with a bright splash ring on the water
	log((0, fy - 0.17, 0.53), (0, BY + 0.02, WATER + 0.004), 0.028, WATER_POUR(), seg=8, rings=3, ends=False, bend=0.12)
	kit.ring(0.05, 0.008, (0, BY + 0.02, WATER + 0.004), WATER_POUR(), seg=14)
	kit.ring(0.11, 0.006, (0, BY + 0.02, WATER + 0.006), WATER_POUR(), seg=18)


def timbers():
	for sx in (-1, 1):
		x = sx * 0.44
		B((0.13, 0.12, 1.0), (x, 0.2, 0.5), WOOD(), bevel=0.015, rot=(0, sx * 2, J(3)))
		for z in (0.42, 0.93):   # copper straps round the post and onto the head stone
			B((0.15, 0.14, 0.075), (x, 0.2, z), CU("b"), bevel=0.006)
			B((0.2, 0.03, 0.075), (sx * 0.32, 0.135, z), CU("b"), bevel=0.006)
			for dx in (-0.06, 0.06):
				kit.rivet((sx * 0.32 + dx, 0.118, z), CU("dark"), r=0.017)
			kit.rivet((x, 0.128, z), CU("dark"), r=0.017)


def roots():
	"""Old roots come down over the head stone, wrap the outside of each post and spread onto the floor:
	thin at the top, thick where they meet the ground."""
	for sx in (-1, 1):
		pts = [(sx * 0.3, 0.36, 1.02), (sx * 0.44, 0.31, 0.86), (sx * 0.52, 0.22, 0.66), (sx * 0.5, 0.12, 0.45),
			(sx * 0.53, 0.04, 0.24), (sx * 0.5, -0.06, 0.06), (sx * 0.45, -0.2, 0.025)]
		rs = [0.022, 0.027, 0.033, 0.038, 0.044, 0.05, 0.04]
		for k in range(len(pts) - 1):
			log(pts[k], pts[k + 1], rs[k], BARK(), seg=7, rings=2, bend=0.05, r1=rs[k + 1])
		log((sx * 0.52, 0.06, 0.2), (sx * 0.58, 0.2, 0.03), 0.035, BARK(), seg=6, rings=3, bend=0.08, r1=0.03)   # back foot
		log((sx * 0.5, 0.12, 0.45), (sx * 0.4, -0.05, 0.28), 0.022, BARK(), seg=6, rings=2, bend=0.1, r1=0.014)  # small runner


def moss_and_rocks():
	for i, (x, y, z, s) in enumerate(((-0.2, 0.3, 1.0, 0.11), (0.1, 0.33, 1.02, 0.12), (0.27, 0.3, 0.96, 0.09),
			(-0.34, 0.24, 0.72, 0.07), (0.34, 0.28, 0.7, 0.07), (-0.3, -0.33, 0.42, 0.06), (0.0, 0.15, 1.17, 0.08))):
		lump((x, y, z), (s, s, s * 0.3), MOSS(), seed=40 + i, rough=0.01)
	for i, (x, y) in enumerate(((-0.33, -0.43), (0.36, -0.41), (-0.47, -0.2), (0.48, -0.22), (0.1, -0.52), (-0.15, -0.51))):
		lump((x, y, 0.04), (0.07 + J(0.015), 0.06, 0.05), T("stone"), seed=60 + i)


def build():
	basin()
	head()
	timbers()
	roots()
	moss_and_rocks()


if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	jdir.mkdir(parents=True, exist_ok=True)
	out = Path(args[0]).resolve() if args else jdir / "healing_fountain.glb"
	prev = Path(args[1]).resolve() if len(args) > 1 else jdir / "healing_fountain.png"
	rng.seed(sum(map(ord, "healing_fountain")))
	kit.reset()
	_cm.clear()
	build()
	floor_cut()
	kit.save(str(out), str(prev), tex_size=256)
	print(f"MODEL_OK healing_fountain {out}")
