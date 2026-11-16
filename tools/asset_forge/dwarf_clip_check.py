"""Does the dwarf's beard, hair or face go through his body while he moves? (owner, F183: "the beard clips through
the body"). The automatic check for the hand-built dwarf (MODEL-RULES Rule 2: nothing passes through anything).

    godot --audio-driver Dummy --path . --script res://tools/asset_forge/dwarf_pose_dump.gd -- <dump.bin>
    blender --background --factory-startup --python tools/asset_forge/dwarf_clip_check.py -- <dump.bin> [max_mm=5]

The dump is the head and torso exactly as the game bends them (Godot's own skinning) in every animation clip. Every
head point is tested against the torso (shirt + shorts seat): how deep inside is it? Points that already sit in the
collar in the pose the body was built in (the neck) are left out. Prints the worst depth per clip, where on the model it
is, and CLIP_CHECK PASS/FAIL (fails when any clip goes deeper than max_mm). (Claude, Nov 16, 2026)
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
	tree = BVHTree.FromPolygons([tuple(p) for p in torso], tris[:, ::-1].tolist() if flip else tris.tolist())
	out = np.full(len(pts), 1.0)
	for i, p in enumerate(pts):
		loc, nrm, _, _ = tree.find_nearest(Vector(p), 0.25)
		if loc is not None:
			out[i] = (Vector(p) - loc).dot(nrm)
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
worst_all, k = 0.0, 1
for name, frames in info["clips"][1:]:
	worst, bad, where, worst_beard = 0.0, 0, None, 0.0
	for f in range(k, k + frames):
		d = signed(data[f, nh:], data[f, :nh][test], flip)
		i = int(np.argmin(d))
		if d[i] < -0.002:
			bad += 1
		if d[i] < worst:
			worst, where = d[i], tuple(float(round(x, 2)) for x in built_h[test[i]])
		worst_beard = min(worst_beard, d[beard].min())
	k += frames
	print(f"CLIP_CHECK {name}: deepest {-worst * 1000:.1f} mm inside the body ({bad} of {frames} frames over 2 mm); "
		f"beard below the chin: {-worst_beard * 1000:.1f} mm" + (f"; worst point as built (x, height, z; front is -z): {where}" if where else ""))
	worst_all = min(worst_all, worst)
print(f"CLIP_CHECK {'PASS' if -worst_all * 1000 <= max_mm else 'FAIL'}: worst {-worst_all * 1000:.1f} mm (limit {max_mm:.0f} mm)")
