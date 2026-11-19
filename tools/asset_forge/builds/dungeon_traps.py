# Dungeon traps, batch 1 (owner, Nov 19, 2026: dungeons, docs/decisions/2026-11-19-dungeons.md): falling stalactites
# and floor spikes. Hand-built, sculpted and painted the Rock Beetle way, from the same helpers as the ceiling dripstone
# (cave_dripstone.py), so they match the caves (MODEL-RULES Rule 1: every shape comes from this script).
#
#   blender --background --factory-startup --python builds/dungeon_traps.py -- <out_dir> [only=trap_drip_thin,...] [grey=1]
#
# Falling stalactites grow along +Z away from the chunk of ceiling rock they hang from (z = 0 is the ceiling's surface),
# like the cave dripstone. Two parts: "rock" (stays on the ceiling) and "stone" (the stalactite: the part that falls).
# Their clue: a jagged crack round the stalactite just under the ceiling rock, with small chips missing.
#   trap_drip_thin     one long thin stalactite (1.6 m)
#   trap_drip_fat      one fat ringed stalactite (1.5 m, 0.7 m wide)
#   trap_drip_cluster  three big ones and two small ones from one rock; each its own part (stone0..stone4), so
#                      they fall one by one, biggest first
# Floor spikes (the bottom of the chasm and the spike pit): sharpened root wood stakes in a slab of rubbly rock, on a
# 2 x 2 m grid square, origin bottom-centre. Parts: "rock", "stake" (bark shafts), "tip" (pale axe-cut points).
#   trap_spikes
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector, noise

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import cave_dripstone as cd  # noqa: E402  (stalactite, rock_chunk, drip_skin, colours)
import cave_plants as cp  # noqa: E402
import creature_kit as ck  # noqa: E402
import creature_sculpt as cs  # noqa: E402
import kit  # noqa: E402

BARK = ((0.4, 0.26, 0.15), (0.2, 0.12, 0.06), (0.6, 0.42, 0.26))      # root wood (the Delver's Shack family)
FRESH = ((0.72, 0.56, 0.36), (0.42, 0.29, 0.16), (0.9, 0.78, 0.58))  # (round 2: less white)   # pale axe-cut wood


def cracked_skin(p, n):
	"""The dripstone skin plus the warning crack: a jagged groove round the stalactite near its root."""
	z0 = 0.11 + 0.03 * noise.noise(Vector((p.x * 9, p.y * 9, 0.3)))
	crack = -0.05 * max(0.0, 1 - abs(p.z - z0) / 0.02) ** 1.2  # (round 2: deeper, so it reads from the floor)
	chips = -0.025 * max(0.0, noise.noise(p * 14) - 0.2) * (1.0 if abs(p.z - z0) < 0.07 else 0.0)
	return cd.drip_skin(p, n) + crack + chips


def drip_parts(sts, rock, tris=3500, weights=None):
	"""sts: one list of stalactites per falling part. One part -> "stone"; several -> "stone0", "stone1"... (they
	fall one by one, owner Nov 19: the cluster's five drop with a tiny delay between them)."""
	cs.carve_stone(rock, seed=7, grain=0.002, crack=0.004, chips=0.01)
	out = [(rock, 2000, 512, lambda nm: cs.paint_material(nm, *cd.ROCK, moss=(0.4, 0.48, 0.2), moss_amount=0.3,
		scratches=0.8, scratch_width=1.6, grime=0.35, edge=0.55, seed=3.0))]
	for k, group in enumerate(sts):
		name = "stone" if len(sts) == 1 else f"stone{k}"
		stone = cs.melt(group, voxel=0.008, smooth=3, name=name)
		cp.carve(stone, cracked_skin, soften=1)
		share = tris if len(sts) == 1 else max(500, int(tris * weights[k] / sum(weights)))
		out.append((stone, share, 1024 if len(sts) == 1 else 512, lambda nm, k=k: cs.paint_material(nm, cd.DRIP_BASE, cd.DRIP_DARK,
			cd.DRIP_LIGHT, strokes=0.28, grime=0.6, edge=0.75, top_light=0.1, seed=4.0 + k)))
	return out


def build_thin(seed=201):
	rock = cs.melt(cd.rock_chunk(seed, 0.34, 0.3), voxel=0.008, smooth=3, name="rock")
	st = cd.stalactite("st", (0, 0, -0.04), 1.6, 0.14, seed, lean=(0.04, -0.03), ridges=0.08, n=28)
	return drip_parts([[st]], rock)


def build_fat(seed=211):
	rock = cs.melt(cd.rock_chunk(seed, 0.5, 0.46, h=0.16), voxel=0.009, smooth=3, name="rock")
	st = cd.stalactite("st", (0, 0, -0.05), 1.5, 0.34, seed, lean=(-0.03, 0.02), ridges=0.14, n=34)
	return drip_parts([[st]], rock, tris=4500)


def build_cluster(seed=221):
	r = random.Random(seed)
	rock = cs.melt(cd.rock_chunk(seed, 0.62, 0.4, h=0.15), voxel=0.009, smooth=3, name="rock")
	spec = [(0.0, 0.0, 1.35, 0.2), (0.3, 0.08, 1.05, 0.17), (-0.3, -0.06, 0.85, 0.16), (0.14, -0.2, 0.42, 0.1), (-0.12, 0.2, 0.36, 0.09)]
	sts = [cd.stalactite(f"st{k}", (x, y, -0.04), L, rad, seed + k, lean=(r.uniform(-0.05, 0.05), r.uniform(-0.05, 0.05)), ridges=0.1)
		for k, (x, y, L, rad) in enumerate(spec)]
	return drip_parts([[st] for st in sts], rock, tris=5000, weights=[L * rad for _, _, L, rad in spec])


def spike_bed_rock(seed, half=0.98, h=0.16):
	"""A low slab of rubbly rock filling the grid square (kept 2 cm inside it), lumpy on top."""
	r = random.Random(seed)
	parts = [cp.lump("slab", (0, 0, h * 0.45), (half, half, h * 0.5), seed, jitter=0.12, detail=4)]
	for k, (cx, cy) in enumerate([(1, 1), (1, -1), (-1, 1), (-1, -1)]):  # (round 2: fill the corners, so beds tile)
		parts.append(cp.lump(f"cor{k}", (cx * half * 0.72, cy * half * 0.72, h * 0.45), (half * 0.42, half * 0.42, h * 0.5), seed + 30 + k, jitter=0.15, detail=4))
	for k in range(22):
		x, y = r.uniform(-half * 0.8, half * 0.8), r.uniform(-half * 0.8, half * 0.8)
		s = r.uniform(0.14, 0.3)
		parts.append(cp.lump(f"rub{k}", (x, y, h * 0.8), (s, s * r.uniform(0.7, 1.0), s * 0.45), seed + 3 + k, jitter=0.3, detail=3))
	rock = cs.melt(parts, voxel=0.012, smooth=3, name="rock")
	for v in rock.data.vertices:  # flat bottom on the floor, nothing past the square
		v.co.z = max(v.co.z, 0.0)
		v.co.x = max(-half, min(half, v.co.x))
		v.co.y = max(-half, min(half, v.co.y))
	return rock


def build_spikes(seed=231):
	r = random.Random(seed)
	rock = spike_bed_rock(seed)
	shafts, tips = [], []
	k = 0
	for gx in range(4):
		for gy in range(4):
			x = -0.72 + gx * 0.48 + r.uniform(-0.09, 0.09) + (0.12 if gy % 2 else 0.0)
			y = -0.72 + gy * 0.48 + r.uniform(-0.09, 0.09)
			if abs(x) > 0.85:
				x = math.copysign(0.82, x)
			h = r.uniform(0.55, 0.9)
			rad = r.uniform(0.045, 0.062)
			lean = Vector((r.uniform(-0.1, 0.1), r.uniform(-0.1, 0.1), 1.0)).normalized()
			foot = Vector((x, y, 0.06))
			top = foot + lean * (h - 0.2)
			n = 8
			pts = [foot.lerp(top, i / (n - 1)) for i in range(n)]
			rads = [rad * (1.08 - 0.12 * i / (n - 1)) for i in range(n)]
			shafts.append(cp.tube(f"sh{k}", pts, rads, sides=9, wobble=0.06, seed=seed + k))
			# the axe-cut point: 5 flat facets from the shaft's end to a sharp tip
			t0 = top - lean * 0.035  # (starts inside the shaft and thinner than it: no two surfaces together, Rule 2)
			tip_len = r.uniform(0.17, 0.24)
			tp = [t0 + lean * (tip_len * i / 4) for i in range(5)]
			tr = [rad * 0.84 * (1 - i / 4) ** 1.1 + 0.004 for i in range(5)]
			tips.append(cp.tube(f"tp{k}", tp, tr, sides=5, wobble=0.12, seed=seed + 50 + k))
			k += 1
	stake = cs.melt(shafts, voxel=0.006, smooth=2, name="stake")
	tip = cp.join(tips, "tip")
	cs.carve_stone(rock, seed=9, grain=0.002, crack=0.005, chips=0.012)
	return [
		(rock, 2500, 1024, lambda nm: cs.paint_material(nm, *cd.ROCK, moss=(0.4, 0.48, 0.2), moss_amount=0.15,
			scratches=0.8, scratch_width=1.6, grime=0.5, edge=0.55, seed=6.0)),
		(stake, 3500, 1024, lambda nm: cs.paint_material(nm, *BARK, strokes=0.35, grime=0.45, edge=0.6, top_light=0.12, seed=7.0)),
		(tip, None, 512, lambda nm: cs.paint_material(nm, *FRESH, strokes=0.45, grime=0.4, edge=0.9, top_light=0.05, seed=8.0)),
	]


BUILDS = {"trap_drip_thin": build_thin, "trap_drip_fat": build_fat, "trap_drip_cluster": build_cluster, "trap_spikes": build_spikes}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if cp.ONLY and name not in cp.ONLY:
			continue
		kit.reset()
		ck.reset()
		objs = cp.finish(name, fn())
		cp.export(name, objs)
		cp.pictures(name, objs)
