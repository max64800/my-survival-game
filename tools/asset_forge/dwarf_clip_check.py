"""Does the dwarf's beard, hair or face go through his body while he moves? (owner, F183: "the beard clips through
the body"). The automatic check for the hand-built dwarf (MODEL-RULES Rule 2: nothing passes through anything).

    godot --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_pose_dump.gd -- <dump.bin>
    blender --background --factory-startup --python tools/asset_forge/dwarf_clip_check.py -- <dump.bin> [max_mm=5]

The dump is the head and torso exactly as the game bends them (Godot's own skinning) in every animation clip. Every
head point is tested against the torso (shirt + shorts seat): how deep inside is it? Points that already sit in the
collar in the pose the body was built in (the neck) are left out. Prints the worst depth per clip, where on the model it
is, and CLIP_CHECK PASS/FAIL (fails when any clip goes deeper than max_mm). Also per clip: the most stretched edge
(a "sheet"), and how far the back hair lifts off the back and opens away from it ("the visor", Nov 17).
(Claude, Nov 16, 2026)
"""
import json
import sys

import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

a = sys.argv[sys.argv.index("--") + 1:]
dump = a[0]
max_mm = float(next((x[7:] for x in a[1:] if x.startswith("max_mm=")), 5))
info = json.load(open(dump + ".json"))
nh, nt = info["head"], info["torso"]
tris = np.array(info["tris"], dtype=np.int64).reshape(-1, 3)
W = np.array(info["world"])
B, O = W[:9].reshape(3, 3), W[9:]
data = np.fromfile(dump, dtype=np.float32).reshape(-1, nh + nt, 3) @ B + O  # every frame, in the dwarf's space (y up)
print(f"CLIP_CHECK {len(data)} frames, {nh} head points, {nt} torso points")


def signed(torso, pts, flip):
	"""Signed distance (m) of each point to the torso's skin: negative = inside."""
	# (zero-size triangles have no real facing: one at the collar called a point 20 cm above it "inside", Nov 18)
	a, b, c = torso[tris[:, 0]], torso[tris[:, 1]], torso[tris[:, 2]]
	ok = tris[np.linalg.norm(np.cross(b - a, c - a), axis=1) > 2e-8]
	tree = BVHTree.FromPolygons([tuple(p) for p in torso], ok[:, ::-1].tolist() if flip else ok.tolist())
	out = np.full(len(pts), 1.0)
	for i, p in enumerate(pts):
		loc, nrm, _, _ = tree.find_nearest(Vector(p), 0.25)
		if loc is not None:
			out[i] = (Vector(p) - loc).dot(nrm)
	# A point the nearest triangle calls "inside" is confirmed by counting how often a ray from it crosses the skin (odd =
	# inside). (Nov 18: a folded pair of triangles on the shoulder, facing down, called head points 20 cm above it
	# "25 cm inside the body".)
	ray = Vector((0.31, 0.93, 0.19)).normalized()
	for i in np.nonzero(out < -0.002)[0]:
		q, hits = Vector(pts[i]), 0
		for _ in range(40):
			loc, _, _, d = tree.ray_cast(q, ray, 2.0)
			if loc is None:
				break
			hits += 1
			q = loc + ray * 1e-5
		if hits % 2 == 0:
			out[i] = -out[i]
	return out


# which way the torso's triangles face (Godot winds them the other way round from Blender): a point far above is outside
built_h, built_t = data[0, :nh], data[0, nh:]
probe = built_t[np.argmax(built_t[:, 1])] + np.array([0, 0.05, 0])  # 5 cm above the torso's top
flip = signed(built_t, probe[None, :], False)[0] < 0
# leave out what sits in or right against the collar in the built pose (the neck: inside on purpose)
d0 = signed(built_t, built_h, flip)
test = np.nonzero(d0 > 0.006)[0]
print(f"CLIP_CHECK testing {len(test)} head points (left out {nh - len(test)}: the neck in the collar); built pose: closest "
	f"{d0[test].min() * 100:.2f} cm")
beard = built_h[test][:, 1] < 0.95  # below the chin as built: beard, braids, tufts, the hair on the upper back
# stretching (owner, Nov 17: flat "sheets" between the hair and the body): every head edge, how many times longer than
# as built it gets; a sheet is an edge pulled to several times its length
ht = np.array(info.get("head_tris", []), dtype=np.int64).reshape(-1, 3)
edges = np.unique(np.sort(np.concatenate([ht[:, [0, 1]], ht[:, [1, 2]], ht[:, [2, 0]]]), axis=1), axis=0) if len(ht) else None
if edges is not None:  # (only edges you can see: both ends outside the body as built)
	seen = np.zeros(nh, bool)
	seen[test] = True
	edges = edges[seen[edges[:, 0]] & seen[edges[:, 1]]]
	rest_len = np.linalg.norm(built_h[edges[:, 0]] - built_h[edges[:, 1]], axis=1) + 1e-6
# the back hair (owner, Nov 17: "it lifts off the back like a stiff visor, the bare neck shows"): how far the hair that
# lies on the back as built gets off it, and how far the whole ponytail opens away from the upper back (its line from
# the top to the lowest tips, against how much the upper back itself leans)
behind_h = built_h[:, 2] > 0.05
lying = np.nonzero(behind_h[test] & (d0[test] < 0.03))[0]  # (indices into `test`)
mid = behind_h & (np.abs(built_h[:, 0]) < 0.05) & (built_h[:, 1] < 0.97)
hair_top = np.nonzero(mid & (built_h[:, 1] > 0.93))[0]
hair_low = np.nonzero(mid & (built_h[:, 1] < built_h[mid, 1].min() + 0.04))[0] if mid.any() else np.array([], int)
upper_back = np.nonzero((built_t[:, 1] > 0.72) & (built_t[:, 2] > 0.05))[0] + nh


def hair_angle(h):
	"""degrees the ponytail's line points from straight down toward the back"""
	v = h[hair_low].mean(0) - h[hair_top].mean(0)
	return np.degrees(np.arctan2(v[2], -v[1]))


def lean(f):
	"""degrees the upper back has turned since built (positive: leaning forward)"""
	a, b = data[0, upper_back], data[f, upper_back]
	a, b = a - a.mean(0), b - b.mean(0)
	u, _, vt = np.linalg.svd(a.T @ b)
	r = (u @ np.diag([1, 1, np.sign(np.linalg.det(u @ vt))]) @ vt).T
	return -np.degrees(np.arctan2(r[2, 1], r[1, 1]))


has_pony = len(hair_top) > 0 and len(hair_low) > 0 and len(upper_back) > 3
hang0 = hair_angle(built_h) if has_pony else 0.0
worst_all, worst_lift, worst_open, k = 0.0, 0.0, 0.0, 1
for name, frames in info["clips"][1:]:
	worst, bad, where, worst_beard = 0.0, 0, None, 0.0
	stretch, s_where, back_stretch, b_where = 1.0, None, 1.0, None
	lift, opens, hang = 0.0, -90.0, 0.0
	for f in range(k, k + frames):
		if edges is not None:
			h_ = data[f, :nh]
			ratio = np.linalg.norm(h_[edges[:, 0]] - h_[edges[:, 1]], axis=1) / rest_len
			j = int(np.argmax(ratio))
			if ratio[j] > stretch:
				stretch, s_where = float(ratio[j]), tuple(float(round(x, 2)) for x in built_h[edges[j, 0]])
			behind = built_h[edges[:, 0]][:, 2] > 0.05  # (the back hair: behind the neck)
			if behind.any():
				jb = int(np.argmax(np.where(behind, ratio, 0.0)))
				if ratio[jb] > back_stretch:
					back_stretch = float(ratio[jb])
					b_where = tuple(float(round(x, 2)) for x in built_h[edges[jb, 0]])
		d = signed(data[f, nh:], data[f, :nh][test], flip)
		i = int(np.argmin(d))
		if d[i] < -0.002:
			bad += 1
		if d[i] < worst:
			worst, where = d[i], tuple(float(round(x, 2)) for x in built_h[test[i]])
		worst_beard = min(worst_beard, d[beard].min())
		if len(lying):
			lift = max(lift, float(np.percentile(d[lying] - d0[test][lying], 95)))
		if has_pony:
			a = hair_angle(data[f, :nh])
			if a - hang0 - lean(f) > opens:
				opens, hang = a - hang0 - lean(f), a
	k += frames
	print(f"CLIP_CHECK {name}: deepest {-worst * 1000:.1f} mm inside the body ({bad} of {frames} frames over 2 mm); "
		f"beard below the chin: {-worst_beard * 1000:.1f} mm; most stretched edge x{stretch:.1f} at {s_where}; back hair x{back_stretch:.1f} at {b_where}"
		+ (f"; back hair lifts {lift * 100:.1f} cm off the back, opens {opens:.0f} deg away from it (hangs {hang:.0f} deg from down)"
			if has_pony else "")
		+ (f"; worst point as built (x, height, z; front is -z): {where}" if where else ""))
	worst_all = min(worst_all, worst)
	worst_lift, worst_open = max(worst_lift, lift), max(worst_open, opens)
print(f"CLIP_CHECK back hair as built: hangs {hang0:.0f} deg from down; worst lift {worst_lift * 100:.1f} cm, worst opening "
	f"{worst_open:.0f} deg")
print(f"CLIP_CHECK {'PASS' if -worst_all * 1000 <= max_mm else 'FAIL'}: worst {-worst_all * 1000:.1f} mm (limit {max_mm:.0f} mm)")
