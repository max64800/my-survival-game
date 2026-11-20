# Size of a .glb model (with its node moves/turns/scales): python tools/dungeons/glb_bounds.py <file.glb>...
import json, struct, sys
import numpy as np

def quat_m(q):
	x, y, z, w = q
	return np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)], [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)], [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])

def node_m(n):
	if "matrix" in n:
		return np.array(n["matrix"]).reshape(4, 4).T
	m = np.eye(4)
	s = np.diag(n.get("scale", [1, 1, 1]))
	m[:3, :3] = quat_m(n.get("rotation", [0, 0, 0, 1])) @ s
	m[:3, 3] = n.get("translation", [0, 0, 0])
	return m

def bounds(path):
	d = open(path, "rb").read()
	n = struct.unpack("<I", d[12:16])[0]
	g = json.loads(d[20:20 + n])
	lo, hi = np.full(3, 1e9), np.full(3, -1e9)
	def walk(i, parent):
		nonlocal lo, hi
		nd = g["nodes"][i]
		m = parent @ node_m(nd)
		if "mesh" in nd:
			for pr in g["meshes"][nd["mesh"]]["primitives"]:
				a = g["accessors"][pr["attributes"]["POSITION"]]
				for c in [[x, y, z] for x in (a["min"][0], a["max"][0]) for y in (a["min"][1], a["max"][1]) for z in (a["min"][2], a["max"][2])]:
					p = m @ np.array(c + [1.0])
					lo = np.minimum(lo, p[:3]); hi = np.maximum(hi, p[:3])
		for c in nd.get("children", []):
			walk(c, m)
	for r in g["scenes"][g.get("scene", 0)]["nodes"]:
		walk(r, np.eye(4))
	return lo, hi

if __name__ == "__main__":  # (also imported by junk.py)
	for f in sys.argv[1:]:
		lo, hi = bounds(f)
		print("%-28s min %s max %s size %s" % (f.split("/")[-1], np.round(lo, 2), np.round(hi, 2), np.round(hi - lo, 2)))
