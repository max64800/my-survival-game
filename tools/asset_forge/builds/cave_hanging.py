# Roots hanging from cave ceilings (F232, owner Nov 17, 2026; picture: assets/concepts/cave-decor/hanging_roots_moss_sheet.png).
# Hand-built and painted like the floor roots in cave_plants.py (same bark, MODEL-RULES Rule 1). NO rock chunk (owner,
# after the shelves: a separate piece of rock never blends with the cave wall): the roots come straight out of the real
# ceiling, their tops pushed a little into it.
#
#   blender --background --factory-startup --python builds/cave_hanging.py -- <out_dir> [only=hroot_a,...] [grey=1]
#
# The models grow along +Z away from the ceiling (z = 0 is the ceiling's surface; above that they're inside the rock),
# like cave_dripstone.py, so the game hangs them the same way:
#   hroot_a   a tangle: two thick twisted roots coming out of a crack, forking into thinner roots, hairy frayed tips
#   hroot_b   a root curtain: a fringe of thin roots side by side, uneven lengths, forked tips
#   hroot_c   one medium root, twisting, splitting into three, with hair roots
# Parts / materials: bark_<model>, rootlets_<model> (the hair roots).
import math
import random
import sys
from pathlib import Path

from mathutils import Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_plants as cp  # noqa: E402
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import kit  # noqa: E402

B = ((0.46, 0.3, 0.18), (0.2, 0.12, 0.07), (0.68, 0.5, 0.32))  # warm root brown (round 2: the picture, cleaner)
X = Vector((1, 0, 0))


def hang_path(top, length, seed, sway=0.12, n=16):
	"""From `top` (a little inside the ceiling) down along +Z, wandering a little: no straight sticks."""
	r = random.Random(seed)
	ctrl = [Vector(top)]
	for k in range(1, 5):
		u = k / 4
		ctrl.append(Vector(top) + Vector((r.uniform(-sway, sway) * u, r.uniform(-sway, sway) * u, length * u)))
	return cp.smooth_path(ctrl, n)


def forks(path, r0, count, seed, from_u=0.45):
	"""Thinner roots leaving a root partway down and hanging on, each tapering to a point."""
	r = random.Random(seed)
	out = []
	for k in range(count):
		i = int(len(path) * r.uniform(from_u, 0.85))
		p = path[i]
		ang = r.uniform(0, 2 * math.pi)
		side = Vector((math.cos(ang), math.sin(ang), 0))
		L = r.uniform(0.2, 0.45)
		ctrl = [p, p + side * 0.06 + Vector((0, 0, 0.06)), p + side * 0.12 + Vector((0, 0, L * 0.6)), p + side * r.uniform(0.1, 0.2) + Vector((0, 0, L))]
		pts = cp.smooth_path(ctrl, 10)
		out.append(cp.tube(f"fork{seed}_{k}", pts, [r0 * 0.45 * (1 - j / 9) + 0.004 for j in range(10)], sides=8, wobble=0.08, seed=seed + k))
	return out


def hairs(path, count, seed, tip_only=False):
	"""Hair roots: very thin wiggly strands, mostly at the tips (frayed ends)."""
	r = random.Random(seed)
	out = []
	for k in range(count):
		i = len(path) - 1 - r.randint(0, 3) if tip_only or k % 3 else r.randint(len(path) // 3, len(path) - 1)
		p = path[i]
		ang = r.uniform(0, 2 * math.pi)
		side = Vector((math.cos(ang), math.sin(ang), 0))
		L = r.uniform(0.08, 0.2)
		ctrl = [p, p + side * 0.03 + Vector((0, 0, L * 0.4)), p + side * r.uniform(0.04, 0.09) + Vector((0, 0, L))]
		out.append(cp.tube(f"hair{seed}_{k}", cp.smooth_path(ctrl, 6), [0.006 - 0.0009 * j for j in range(6)], sides=5, wobble=0.2, seed=seed + 50 + k))
	return out


def branch(name, top, direction, length, radius, depth, seed, parts, fine):
	"""A root that curves (an S, not a stick) and splits into 2-3 smaller roots, which split again, down to fine tips."""
	r = random.Random(seed)
	d = Vector(direction).normalized()
	side = d.cross(Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((1, 0, 0))).normalized()
	s2 = d.cross(side)
	bend = r.uniform(0.18, 0.32) * length
	ph = r.uniform(0, 2 * math.pi)
	ctrl = []
	for k in range(5):
		u = k / 4
		wob = side * math.sin(u * math.pi * 1.6 + ph) * bend * u + s2 * math.cos(u * math.pi * 1.3 + ph) * bend * 0.6 * u
		ctrl.append(Vector(top) + d * length * u + wob + Vector((0, 0, length * 0.35 * u * u)))  # sags downward (+Z)
	path = cp.smooth_path(ctrl, 14)
	rad = [radius * (1 - 0.6 * j / 13) + 0.003 for j in range(14)]
	parts.append(cp.tube(f"{name}", path, rad, sides=10 if radius > 0.03 else 7, wobble=0.07, seed=seed))
	if depth <= 0:
		fine += hairs(path, 3, seed + 7, tip_only=True)
		return
	kids = 2 if depth == 1 else r.randint(2, 3)
	for k in range(kids):
		i = int(13 * r.uniform(0.45, 0.85))
		p = path[i]
		tang = (path[min(13, i + 1)] - path[i - 1]).normalized()
		ang = r.uniform(0, 2 * math.pi)
		out = (side * math.cos(ang) + s2 * math.sin(ang))
		nd = (tang + out * r.uniform(0.5, 0.9)).normalized()
		branch(f"{name}_{k}", p, nd, length * r.uniform(0.45, 0.65), rad[i] * 0.62, depth - 1, seed * 3 + k + 1, parts, fine)
	end = path[-1]  # and the main root carries on a little past its last split, thinning to a tip
	fine += hairs(path, 2, seed + 9, tip_only=True)


def bark_fn(seed):
	def fn(p, n):  # cracked bark plates, chipped patches, fine grain (as the floor roots)
		q = p * 26 + Vector((seed, 0, 0))
		plates = -0.006 * (1 - abs(noise.noise(q)) ** 0.5)
		chipped = -0.006 if noise.noise(p * 6 + Vector((3, seed, 1))) > 0.42 else 0.0
		return plates + chipped + 0.0012 * noise.fractal(p * 90, 0.5, 2.0, 3)
	return fn


def finish(parts, fine, seed, moss=0.15):
	bark = cs.melt(parts, voxel=0.005, smooth=4, name="bark")
	cp.carve(bark, bark_fn(seed), soften=1)
	out = [(bark, 5000, 1024, lambda nm: cs.paint_material(nm, *B, moss=(0.36, 0.42, 0.2), moss_amount=moss, strokes=0.15, edge=0.5,
		scratches=0.0, grime=0.08, seed=1.0))]
	if fine:
		out.append((cp.join(fine, "rootlets"), 900, 256, lambda nm: cs.paint_material(nm, *B, grime=0.2, seed=4.0)))
	return out


def build_a(seed=131):
	"""A tangle: two thick curving roots out of the ceiling, splitting again and again into fine tips."""
	parts, fine = [], []
	branch("main", (-0.05, 0.0, -0.12), (0.15, 0.05, 1), 1.0, 0.09, 3, seed, parts, fine)
	branch("second", (0.1, 0.05, -0.12), (-0.25, -0.1, 1), 0.75, 0.065, 2, seed + 50, parts, fine)
	return finish(parts, fine, seed)


def build_b(seed=141):
	"""A curtain: a fringe of thin wavy roots side by side, uneven lengths, each splitting once or twice."""
	r = random.Random(seed)
	parts, fine = [], []
	for k in range(12):
		x = -0.45 + 0.9 * k / 11 + r.uniform(-0.02, 0.02)
		L = 0.5 + 0.6 * (0.5 + 0.5 * math.sin(k * 1.3 + 0.4)) * r.uniform(0.7, 1.0)
		branch(f"strand{k}", (x, r.uniform(-0.04, 0.04), -0.08), (r.uniform(-0.1, 0.1), r.uniform(-0.1, 0.1), 1), L, r.uniform(0.024, 0.034),
			1 if k % 2 else 2, seed + 10 * k, parts, fine)
	return finish(parts, fine, seed, moss=0.1)


def build_c(seed=151):
	"""One medium root splitting into three, which split again."""
	parts, fine = [], []
	branch("trunk", (0, 0, -0.1), (0.05, -0.05, 1), 0.85, 0.07, 2, seed, parts, fine)
	return finish(parts, fine, seed, moss=0.2)


BUILDS = {"hroot_a": build_a, "hroot_c": build_c}  # (the curtain, hroot_b, was dropped by the owner)

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
