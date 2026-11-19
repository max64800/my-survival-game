# Mushroom grass (owner, Nov 18, 2026: "a small mushroom grass just in the first cave on most of the surfaces";
# picture: docs/design/pictures/cave-grass-6-ideas.png, "Mushroom grass"). Hand-built (MODEL-RULES Rule 1): a tuft of
# tiny thin mushrooms, each a slightly bent stem with a little cap; their feet reach 3 cm below z = 0 and the game sinks
# them into the cave floor, so each one grows out of the real ground (round 2: a soil crumb under them read as a pale
# plate). Light: the game draws thousands of them.
#
#   blender --background --factory-startup --python builds/cave_mushgrass.py -- <out_dir> [only=mushgrass_a,...]
#
#   mushgrass_a  a round tuft of 11 mushrooms, a few taller in the middle
#   mushgrass_b  a long thin strip of 9, leaning one way
#   mushgrass_c  a loose tuft of 7, two tall ones and small ones round them
#   mushgrass_d  bells: 8 mushrooms with tall bell-shaped caps (owner, Nov 19: "different shapes... more of them")
#   mushgrass_e  needles: 6 very thin tall stems with small pointed caps
#   mushgrass_f  a carpet: 15 tiny short ones close together
#   *_far        the same tuft with about a quarter of the detail, for further than 9 m
import math
import random
import sys
from pathlib import Path

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_plants as cp  # noqa: E402
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import kit  # noqa: E402

# a small cap: (height along the stem, width) as parts of the cap's radius
CAP = [(-0.05, 0.25), (-0.12, 0.7), (-0.1, 1.0), (0.05, 1.02), (0.25, 0.85), (0.42, 0.55), (0.5, 0.2)]
BELL = [(-0.05, 0.3), (-0.3, 0.85), (-0.25, 0.95), (0.1, 0.9), (0.45, 0.75), (0.75, 0.45), (0.9, 0.12)]
POINT = [(-0.05, 0.3), (-0.1, 0.8), (0.0, 0.85), (0.35, 0.55), (0.7, 0.25), (1.0, 0.05)]


def one(name, foot, lean, h, cr, seed, cap=None):
	r = random.Random(seed)
	up = Vector((lean[0], lean[1], 1.0)).normalized()
	side = up.cross(Vector((0, 0, 1)) if abs(up.z) < 0.95 else Vector((1, 0, 0)))
	side = side.normalized() if side.length > 0.01 else Vector((1, 0, 0))
	top = foot + up * h
	mid = (foot + top) / 2 + side * h * 0.08 * r.uniform(-1, 1)
	path = cp.smooth_path([foot - Vector((0, 0, 0.03)), mid, top], 8)
	sr = max(0.0016, cr * 0.18)
	stem = cp.tube(f"{name}_stem", path, [sr * (1.35 - 0.4 * i / 7) for i in range(8)], sides=6, seed=seed)
	cap = ck.loft(f"{name}_cap", [(top + up * cr * hh, cr * w, cr * w) for hh, w in (cap or CAP)], cp.grey(), sides=10, subsurf=0,
		wobble=0.06, seed=seed + 1, up=side)
	return [stem, cap]


def tuft(seed, spots, cap=None, tris=420):
	r = random.Random(seed)
	parts = []
	for k, (x, y, h, cr) in enumerate(spots):
		lean = (x * 1.8 + r.uniform(-0.15, 0.15), y * 1.8 + r.uniform(-0.15, 0.15))
		parts += one(f"m{k}", Vector((x, y, 0.0)), lean, h, cr, seed + 10 * k, cap)
	whole = cs.melt(parts, voxel=0.0012, smooth=2, name="mushgrass")
	return [(whole, tris, 256, lambda n: cs.paint_material(n, (0.86, 0.82, 0.72), (0.42, 0.36, 0.28), (0.98, 0.95, 0.88),
		strokes=0.15, grime=0.45, edge=0.4, key=0.3, top_light=0.3, seed=seed * 0.1))]


def ring(seed, n, rad, hs, crs):
	r = random.Random(seed)
	out = []
	for k in range(n):
		a = k * math.tau / n + r.uniform(-0.3, 0.3)
		d = rad * math.sqrt(r.uniform(0.05, 1.0))
		out.append((math.cos(a) * d, math.sin(a) * d * 0.8, r.uniform(*hs), r.uniform(*crs)))
	return out


def mushgrass_a(seed=601):
	return tuft(seed, [(0.0, 0.0, 0.11, 0.014), (0.02, -0.015, 0.09, 0.012)] + ring(seed, 9, 0.075, (0.04, 0.08), (0.008, 0.012)))


def mushgrass_b(seed=611):
	r = random.Random(seed)
	spots = [((k - 4) * 0.016 + r.uniform(-0.004, 0.004), r.uniform(-0.02, 0.02), r.uniform(0.04, 0.1), r.uniform(0.008, 0.013)) for k in range(9)]
	return tuft(seed, spots)


def mushgrass_c(seed=621):
	return tuft(seed, [(0.01, 0.0, 0.13, 0.016), (-0.03, 0.02, 0.1, 0.013)] + ring(seed, 5, 0.08, (0.03, 0.06), (0.007, 0.01)))


def mushgrass_d(seed=631, tris=420):
	return tuft(seed, ring(seed, 8, 0.08, (0.05, 0.1), (0.012, 0.017)), BELL, tris)


def mushgrass_e(seed=641, tris=420):
	return tuft(seed, ring(seed, 6, 0.06, (0.1, 0.16), (0.006, 0.009)), POINT, tris)


def mushgrass_f(seed=651, tris=420):
	return tuft(seed, ring(seed, 15, 0.1, (0.015, 0.035), (0.006, 0.01)), CAP, tris)


BUILDS = {"mushgrass_a": mushgrass_a, "mushgrass_b": mushgrass_b, "mushgrass_c": mushgrass_c, "mushgrass_d": mushgrass_d,
	"mushgrass_e": mushgrass_e, "mushgrass_f": mushgrass_f}
# The far versions: the same tufts (same seeds), a quarter of the detail
for _n in list(BUILDS):
	BUILDS[_n + "_far"] = (lambda f=BUILDS[_n], n=_n: (f(tris=110) if n in ("mushgrass_d", "mushgrass_e", "mushgrass_f")
		else tuft_far(f)))


def tuft_far(f):
	out = f()
	return [(o, 110, 128, paint) for o, _t, _tex, paint in out]

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
