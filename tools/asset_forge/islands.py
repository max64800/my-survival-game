"""Floating-part check for any .glb (same rule as the game's PieceMesh.islands, owner notes F34-F62):
triangles sharing a corner form a part; parts whose boxes touch (within 1 cm) join. One part = it holds
together; more = something floats.  python islands.py <file.glb or folder> [...]"""
import json
import struct
import sys
from pathlib import Path

import numpy as np

CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def _acc(g, binb, i):
	a = g["accessors"][i]
	bv = g["bufferViews"][a["bufferView"]]
	off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
	n, c = a["count"], NC[a["type"]]
	dt = np.dtype(CT[a["componentType"]])
	stride = bv.get("byteStride", 0)
	if stride and stride != dt.itemsize * c:
		raw = np.frombuffer(binb, np.uint8, count=stride * n, offset=off).reshape(n, stride)[:, :dt.itemsize * c]
		return np.frombuffer(raw.tobytes(), dt).reshape(n, c)
	return np.frombuffer(binb, dt, count=n * c, offset=off).reshape(n, c)


def islands(path, tol=0.01):
	d = Path(path).read_bytes()
	n = struct.unpack("<I", d[12:16])[0]
	g = json.loads(d[20:20 + n])
	binb = d[20 + n + 8:]
	boxes = []
	for m in g["meshes"]:
		for p in m["primitives"]:
			v = _acc(g, binb, p["attributes"]["POSITION"]).astype(np.float64)
			idx = _acc(g, binb, p["indices"]).ravel() if "indices" in p else np.arange(len(v))
			keys = np.round(v * 1000).astype(np.int64)
			_, inv = np.unique(keys, axis=0, return_inverse=True)
			inv = inv.ravel()
			parent = np.arange(inv.max() + 1)

			def root(a):
				while parent[a] != a:
					parent[a] = parent[parent[a]]
					a = parent[a]
				return a
			t = inv[idx].reshape(-1, 3)
			for a, b, c in t:
				ra = root(a)
				for x in (b, c):
					rx = root(x)
					if rx != ra:
						parent[rx] = ra
			roots = np.array([root(i) for i in range(len(parent))])
			for r in np.unique(roots):
				pts = v[np.isin(inv, np.where(roots == r)[0])]
				boxes.append([pts.min(0), pts.max(0)])
	merged = True
	while merged:
		merged = False
		for i in range(len(boxes)):
			for j in range(i + 1, len(boxes)):
				a, b = boxes[i], boxes[j]
				if np.all(a[0] - tol <= b[1]) and np.all(b[0] <= a[1] + tol):
					boxes[i] = [np.minimum(a[0], b[0]), np.maximum(a[1], b[1])]
					del boxes[j]
					merged = True
					break
			if merged:
				break
	return boxes


if __name__ == "__main__":
	files = []
	for a in sys.argv[1:]:
		p = Path(a)
		files += sorted(p.glob("*.glb")) if p.is_dir() else [p]
	bad = 0
	for f in files:
		b = islands(f)
		if len(b) > 1:
			bad += 1
			# the main body is the biggest box; list the others (centre, size)
			b.sort(key=lambda x: -np.prod(x[1] - x[0] + 1e-3))
			extra = ", ".join("at (%.2f, %.2f, %.2f)" % tuple((x[0] + x[1]) / 2) for x in b[1:4])
			print(f"FLOAT {f.stem}: {len(b)} parts; loose: {extra}")
	print(f"{len(files)} checked, {bad} with floating parts")
