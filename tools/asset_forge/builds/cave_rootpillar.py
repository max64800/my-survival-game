# Giant root pillars (F189, owner Nov 17, 2026: "huge twisted tree roots running floor to ceiling in some caverns, like
# the stone pillars but wood; you can chop bits for wood"). Hand-built and painted like the hanging roots in
# cave_hanging.py (same bark, same root shapes, MODEL-RULES Rule 1): no rock part, the roots go into the real rock.
#
#   blender --background --factory-startup --python builds/cave_rootpillar.py -- <out_dir> [only=rpillar_a,...]
#
# Like the hanging models, z = 0 is the ceiling and the model grows along +Z down to the floor at z = 1 (the game
# stretches it to the room's height). Its roots spread out and dive into the rock at both ends.
#   rpillar_a   five thick roots twisting round each other, a few side roots and hair roots
#   rpillar_b   three roots, a looser twist, one splitting off and rejoining
import math
import random
import sys
from pathlib import Path

from mathutils import Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_hanging as ch  # noqa: E402
import cave_plants as cp  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import creature_kit as ck  # noqa: E402
import kit  # noqa: E402


def twist_root(name, k, n, seed, turns, r_mid, thick, parts):
	"""One root of the pillar: round a vertical axis, `turns` times from ceiling to floor, wide at both ends."""
	r = random.Random(seed)
	a0 = 2 * math.pi * k / n + r.uniform(-0.2, 0.2)
	pts = []
	steps = 34
	for j in range(steps + 1):
		u = j / steps
		z = -0.08 + 1.16 * u  # a little into the rock at both ends
		e = 2 * u - 1
		spread = r_mid + 0.26 * e ** 4 + 0.015 * math.sin(u * 9 + seed)  # the feet spread out into the rock
		a = a0 + turns * 2 * math.pi * u + 0.25 * math.sin(u * 5 + k)
		pts.append(Vector((math.cos(a) * spread, math.sin(a) * spread, z)))
	rad = [thick * (1.0 + 0.6 * (2 * j / steps - 1) ** 4) * (1 + 0.12 * math.sin(j * 1.7 + k)) for j in range(steps + 1)]
	parts.append(cp.tube(name, pts, rad, sides=12, wobble=0.06, seed=seed))
	return pts


def build_a(seed=211):
	"""Round 2 (round 1 looked like sticks): a solid core and eight thick roots twisting tightly round it, wide feet."""
	parts, fine = [], []
	twist_root("core", 0, 1, seed, 0.2, 0.0, 0.07, parts)
	paths = [twist_root(f"r{k}", k, 8, seed + k, 0.9, 0.075, 0.042, parts) for k in range(8)]
	r = random.Random(seed)
	for k in range(2):  # a couple of side roots hanging off it, like the ceiling roots
		p = paths[k * 3][r.randint(12, 22)]
		out = Vector((p.x, p.y, 0)).normalized()
		ch.branch(f"side{k}", p, (out.x, out.y, r.uniform(0.4, 0.8)), r.uniform(0.16, 0.24), 0.018, 1, seed + 30 + k, parts, fine)
	return ch.finish(parts, fine, seed, moss=0.25)


def build_b(seed=233):
	parts, fine = [], []
	twist_root("core", 0, 1, seed, 0.15, 0.0, 0.06, parts)
	paths = [twist_root(f"r{k}", k, 6, seed + k, 0.6, 0.07, 0.045, parts) for k in range(6)]
	# one more root peeling away from the others in the middle and growing back in (an eye in the pillar)
	r = random.Random(seed)
	a = r.uniform(0, 2 * math.pi)
	ctrl = []
	for j in range(7):
		u = j / 6
		bulge = 0.16 * math.sin(math.pi * u)
		ctrl.append(Vector((math.cos(a) * (0.05 + bulge), math.sin(a) * (0.05 + bulge), 0.22 + 0.55 * u)))
	pts = cp.smooth_path(ctrl, 18)
	parts.append(cp.tube("eye", pts, [0.022 + 0.008 * math.sin(math.pi * j / 17) for j in range(18)], sides=10, wobble=0.06, seed=seed + 9))
	return ch.finish(parts, fine, seed, moss=0.3)


def build_braided(seed=301):
	"""Look A, the Braided Giant: ten thick roots twisting round a core like a rope, feet spreading wide."""
	parts, fine = [], []
	twist_root("core", 0, 1, seed, 0.25, 0.0, 0.09, parts)
	for k in range(10):
		twist_root(f"r{k}", k, 10, seed + k, 1.1, 0.1, 0.05, parts)
	return ch.finish(parts, fine, seed, moss=0.35)


BARK_PIC = str(Path(__file__).resolve().parents[3] / "assets" / "textures" / "kit" / "bark_vert.png")


def tree_bark_fn(seed):
	"""Old bark (owner, Nov 18: "all of them look like Play-Doh"): long deep furrows running down the trunk, bark plates
	between them, chipped patches, fine grain."""
	def fn(p, n):
		q = Vector((p.x * 16.0, p.y * 16.0, p.z * 3.2)) + Vector((seed * 0.37, 0.0, 0.0))
		furrow = -0.013 * max(0.0, 1.0 - abs(noise.noise(q)) * 3.2)
		plates = -0.004 * (1.0 - abs(noise.noise(p * 34.0 + Vector((0.0, seed, 0.0)))) ** 0.5)
		chipped = -0.005 if noise.noise(p * 7.0 + Vector((3.0, seed, 1.0))) > 0.45 else 0.0
		return furrow + plates + chipped + 0.001 * noise.fractal(p * 110.0, 0.5, 2.0, 3)
	return fn


def tree_finish(parts, seed):
	bark = cs.melt(parts, voxel=0.004, smooth=3, name="bark")
	cp.carve(bark, tree_bark_fn(seed), soften=1)
	return [(bark, 9000, 2048, lambda nm: cs.paint_material(nm, *ch.B, moss=(0.36, 0.42, 0.2), moss_amount=0.25, strokes=0.12,
		edge=0.6, grime=0.22, seed=1.0, picture=BARK_PIC, picture_scale=11.0, picture_amount=0.8))]


def build_trunk(seed=311, part="full"):
	"""Look B, the Ancient Trunk (owner's pick, Nov 18): one huge gnarled trunk, buttress roots fanning into the floor, a
	crown of roots spreading over the ceiling, a few root strands hanging from the crown. part = "full", or after it's
	chopped through: "stump" (the feet and a short piece of trunk) / "crown" (the ceiling roots and a short piece)."""
	r = random.Random(seed)
	parts, fine = [], []
	pts = []
	lean = r.uniform(0.02, 0.05)
	for j in range(21):
		u = j / 20
		pts.append(Vector((lean * math.sin(u * 5 + seed), lean * math.cos(u * 4 + seed), -0.05 + 1.1 * u)))
	base_r = r.uniform(0.15, 0.18)  # (round 2: one size for the whole trunk, swelling slowly: no caterpillar rings)
	rad = [base_r * (1 + 0.5 * (2 * j / 20 - 1) ** 4) * (1 + 0.06 * math.sin(j * 0.55 + seed)) for j in range(21)]
	if part == "stump":
		keep = [j for j in range(21) if pts[j].z >= 0.8]
	elif part == "crown":
		keep = [j for j in range(21) if pts[j].z <= 0.22]
	else:
		keep = list(range(21))
	parts.append(cp.tube("trunk", [pts[j] for j in keep], [rad[j] for j in keep], sides=16, wobble=0.08, seed=seed))
	for end, z0, dz in (("feet", 0.95, 1), ("crown", 0.05, -1)):
		n = r.randint(5, 7)
		for k in range(n):
			a = 2 * math.pi * k / n + r.uniform(-0.3, 0.3)
			out = Vector((math.cos(a), math.sin(a), 0))
			ctrl = [Vector((0, 0, z0)) + out * 0.08, Vector((0, 0, z0 + dz * 0.06)) + out * 0.22, Vector((0, 0, z0 + dz * 0.11)) + out * 0.38,
				Vector((0, 0, z0 + dz * 0.14)) + out * r.uniform(0.46, 0.58)]
			path = cp.smooth_path(ctrl, 12)
			rr = [r.uniform(0.07, 0.085) * (1 - 0.7 * j / 11) + 0.01 for j in range(12)]
			if (part == "stump" and end == "crown") or (part == "crown" and end == "feet"):
				continue
			parts.append(cp.tube(f"{end}{k}", path, rr, sides=10, wobble=0.07, seed=seed + 10 * k + (0 if dz > 0 else 5)))
	return tree_finish(parts, seed)  # (round 3: no little twig "trees"; bark carved and painted, not Play-Doh)


def build_cage(seed=321):
	"""Look C, the Glowing Root Cage: seven roots spiralling round a hollow heart you can see into, glowing fungus
	growing inside it."""
	parts, fine = [], []
	for k in range(7):
		twist_root(f"r{k}", k, 7, seed + k, 0.5, 0.17, 0.042, parts)
	# (the glowing fungus inside the hollow: added by the game, glowing like the crystals)
	return ch.finish(parts, fine, seed, moss=0.35)


BUILDS = {"rpillar_a": build_a, "rpillar_b": build_b, "rtree_braided": build_braided, "rtree_trunk": build_trunk, "rtree_cage": build_cage,
	# the owner's pick (Nov 18): three Ancient Trunks, and the first one's stump and crown for after it's chopped through
	"rtree_b1": lambda: build_trunk(311), "rtree_b2": lambda: build_trunk(337), "rtree_b3": lambda: build_trunk(359),
	"rtree_stump": lambda: build_trunk(311, "stump"), "rtree_crown": lambda: build_trunk(311, "crown")}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
