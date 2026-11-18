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

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_hanging as ch  # noqa: E402
import cave_plants as cp  # noqa: E402
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


BUILDS = {"rpillar_a": build_a, "rpillar_b": build_b}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
