# Dripstone for cave ceilings (F232, owner Nov 17, 2026: "something on the walls and the roof besides crystals and water
# droplets"; picture: assets/concepts/cave-decor/dripstone_sheet.png). Hand-built, sculpted and painted the Rock Beetle
# way, like cave_plants.py (MODEL-RULES Rule 1: every shape comes from this script).
#
#   blender --background --factory-startup --python builds/cave_dripstone.py -- <out_dir> [only=drip_a,...] [grey=1]
#
# The models grow along +Z away from the chunk of ceiling rock they hang from (z = 0 is the ceiling's surface), so the
# game can stick them on a ceiling the same way it sticks crystals on rock (the model's up = away from the rock):
#   drip_a   a cluster of six stalactites of different lengths, wide at the top, tapering to rounded tips, small
#            ones round the big ones
#   drip_b   one big thick stalactite with ring-like ridges and a wet tip with a hanging drop
#   (drip_c, a flowstone curtain, was dropped by the owner, round 2)
#   drip_d   a short wide cluster of stubby stalactites, with moss on the ceiling rock
# Each has a chunk of grey-brown ceiling rock at its root (it touches the dripstone: Rule 3, every part touching).
# Parts / materials: rock_<model>, stone_<model> (the dripstone), drop_<model>.
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_plants as cp  # noqa: E402  (its helpers: tube, smooth_path, lump, carve, join, finish, pictures, export)
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import kit  # noqa: E402

DRIP_BASE = (0.76, 0.6, 0.43)  # warm orange-tan (the picture; owner round 2: "make the texture better")
DRIP_DARK = (0.4, 0.28, 0.18)
DRIP_LIGHT = (0.94, 0.81, 0.6)
ROCK = ((0.5, 0.44, 0.38), (0.24, 0.2, 0.17), (0.68, 0.6, 0.52))  # the cave's own stone colour, so it blends in


def rock_chunk(seed, w, d, h=0.12):
	"""The slab of ceiling rock the dripstone hangs from (its face toward the cave at z = 0)."""
	r = random.Random(seed)
	parts = [cp.lump("slab", (0, 0, -h * 0.45), (w, d, h), seed, jitter=0.3, detail=4)]
	for k in range(5):
		a = k * 1.3 + r.uniform(0, 0.6)
		parts.append(cp.lump(f"knob{k}", (math.cos(a) * w * 0.7, math.sin(a) * d * 0.7, -h * 0.35),
			(w * 0.4, d * 0.4, h * 0.75), seed + 1 + k, jitter=0.32, detail=3))
	return parts


def stalactite(name, foot, length, radius, seed, lean=(0.0, 0.0), ridges=0.0, n=16):
	"""One stalactite from `foot` along +Z: wide at the root, tapering to a rounded tip, a little crooked."""
	r = random.Random(seed)
	pts, rad = [], []
	for i in range(n):
		u = i / (n - 1)
		bend = Vector((lean[0], lean[1], 0)) * u * u * length + Vector((math.sin(u * 3 + seed) * 0.02, math.cos(u * 2.6 + seed) * 0.02, 0))
		pts.append(Vector(foot) + Vector((0, 0, u * length)) + bend)
		taper = (1 - u) ** 0.85
		tip = 0.18 * math.sin(math.pi * min(1.0, u / 0.96) * 0.5) if u > 0.9 else 0.0
		rr = radius * (0.12 + 0.88 * taper) + radius * tip * 0.2
		if ridges > 0:
			rr *= 1 + ridges * max(0.0, math.sin(u * 22 + r.uniform(0, 1))) ** 3
		rad.append(max(rr, radius * 0.1))
	rad[-1] = radius * 0.05  # closed, rounded tip
	return cp.tube(name, pts, rad, sides=14, wobble=0.05, seed=seed)


def drip_skin(p, n):
	"""Bands round the dripstone (growth rings), small runnels down it, fine grain."""
	bands = -0.013 * max(0.0, math.sin(p.z * 34 + noise.noise(p * 3) * 2.0)) ** 2  # (round 3: deeper, they paint dark)
	runnels = -0.004 * abs(noise.noise(Vector((p.x * 30, p.y * 30, p.z * 2.5))))
	return bands + runnels + 0.002 * noise.fractal(p * 45, 0.5, 2.0, 3)


def finish_parts(stone, rock, drop=None, moss=0.0):
	cs.carve_stone(rock, seed=7, grain=0.002, crack=0.004, chips=0.01)
	cp.carve(stone, drip_skin, soften=1)
	out = [
		(rock, 2000, 512, lambda nm: cs.paint_material(nm, *ROCK,
			moss=(0.4, 0.48, 0.2), moss_amount=moss, scratches=0.8, scratch_width=1.6, grime=0.35, edge=0.55, seed=3.0)),
		(stone, 3500, 1024, lambda nm: cs.paint_material(nm, DRIP_BASE, DRIP_DARK, DRIP_LIGHT, strokes=0.28, grime=0.45,
			edge=0.75, top_light=0.1, seed=4.0)),  # (no scratches: they read as worms on dripstone)
	]
	if drop is not None:
		out.append((drop, 300, 128, lambda nm: cs.paint_material(nm, (0.82, 0.86, 0.88), (0.5, 0.56, 0.6), (1.0, 1.0, 1.0), edge=0.8, seed=5.0)))
	return out


def build_a(seed=51):
	"""A cluster of six stalactites of different lengths round one long one."""
	r = random.Random(seed)
	rock = cs.melt(rock_chunk(seed, 0.36, 0.28), voxel=0.008, smooth=3, name="rock")
	spec = [(0.0, 0.0, 0.95, 0.16), (0.15, 0.06, 0.62, 0.12), (-0.14, 0.05, 0.7, 0.125), (0.05, -0.14, 0.48, 0.1),
		(-0.09, -0.11, 0.36, 0.09), (0.21, -0.07, 0.28, 0.075), (-0.21, -0.04, 0.22, 0.07)]  # (round 2: fatter, like the picture)
	sts = []
	for k, (x, y, L, rad) in enumerate(spec):
		sts.append(stalactite(f"st{k}", (x, y, -0.04), L, rad, seed + k, lean=(r.uniform(-0.06, 0.06), r.uniform(-0.06, 0.06))))
	stone = cs.melt(sts, voxel=0.006, smooth=3, name="stone")
	return finish_parts(stone, rock)


def build_b(seed=61):
	"""One big ridged stalactite with a wet tip and a drop about to fall."""
	rock = cs.melt(rock_chunk(seed, 0.3, 0.27), voxel=0.008, smooth=3, name="rock")
	big = stalactite("big", (0, 0, -0.04), 1.05, 0.2, seed, lean=(0.03, -0.02), ridges=0.17, n=30)  # (round 3: stronger rings)
	stone = cs.melt([big], voxel=0.006, smooth=3, name="stone")
	tip = Vector((0.03 * 1.05, -0.02 * 1.05, 1.05 - 0.04))
	drop = cp.lump("drop", tuple(tip + Vector((0, 0, 0.03))), (0.024, 0.024, 0.036), seed + 9, jitter=0.05, detail=2)  # touching the tip
	drop.name = "drop"
	return finish_parts(stone, rock, drop)


def build_d(seed=81):
	"""A short wide cluster of stubby stalactites under a mossy rock."""
	r = random.Random(seed)
	rock = cs.melt(rock_chunk(seed, 0.42, 0.33), voxel=0.008, smooth=3, name="rock")
	sts = []
	for k in range(9):
		a = k * 2.4 + r.uniform(-0.3, 0.3)
		d = 0.06 + 0.24 * ((k * 0.37) % 1.0)
		sts.append(stalactite(f"st{k}", (math.cos(a) * d, math.sin(a) * d * 0.8, -0.04), r.uniform(0.18, 0.4),
			r.uniform(0.09, 0.14), seed + k, lean=(r.uniform(-0.05, 0.05), r.uniform(-0.05, 0.05)), n=10))
	stone = cs.melt(sts, voxel=0.006, smooth=3, name="stone")
	return finish_parts(stone, rock, moss=0.9)  # (round 3: the moss shows, like the picture)


BUILDS = {"drip_a": build_a, "drip_b": build_b, "drip_d": build_d}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
