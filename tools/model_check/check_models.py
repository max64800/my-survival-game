# Model checks from docs/art/MODEL-RULES.md, run on real model surfaces (not rough boxes).
#   blender --background --factory-startup --python tools/model_check/check_models.py -- [what ...]
# what = a folder (build, decor, items, stations, creatures), a model name (build/wall__cut_stone or
# wall__cut_stone) or nothing (= every model). Add "report=<file.md>" to also write a Markdown report.
#
# Checks, per model:
#   FLOAT    every part touches the rest (ropes, straps, symbols, leaves count as parts) or stands on the
#            ground. A "part" = one connected piece of surface; two parts touch when they are within 1 cm.
#   SHIMMER  two surfaces facing the same way in the same place (closer than 1.5 mm): the game can't
#            decide which to draw, so it flickers (rule 2).
#   OUTLINE  building pieces only: nothing past the piece's box (squares: the 2 m grid) or triangle (rule 3).
#   ROOF     sloped roof pieces only: a thin panel (15-25 cm, up to 30 allowed), open underneath, no holes.
#   SCRIPT   the model's name appears in a build script in tools/asset_forge (rule 1: hand-built, no Play-Doh).
# The 3D Claudes: run this on your models before saving; anything listed is a rule broken.
import math
import re
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

GAME = Path(__file__).resolve().parents[2]
MODELS = GAME / "assets" / "models"
TOUCH = 0.01  # parts closer than this touch
SAME = 0.0015  # faces closer than this are "in the same place"
SHIMMER_MIN = 0.0004  # m² (4 cm²): smaller overlaps are ignored
OUT_MIN = 0.005  # m: sticking out less than 5 mm is ignored
TRI_IN, TRI_OUT = 0.57735027, 1.1547005
ROOFS = {"roof_26": (1.0, 2.0), "roof_45": (2.0, 2.0), "roof_26_ridge": (0.5, 1.0), "roof_45_ridge": (1.0, 1.0),
	"roof_26_outer": (1.0, 2.0), "roof_26_inner": (1.0, 2.0), "roof_45_outer": (2.0, 2.0), "roof_45_inner": (2.0, 2.0)}


# ---------------- piece sizes from the game's own list ----------------
def piece_sizes():
	src = (GAME / "src" / "build" / "pieces.gd").read_text(encoding="utf-8").replace("TRI_DEPTH", "1.7320508")
	out = {}
	starts = list(re.finditer(r'^	"(\w+)": \{name =', src, re.M))
	for i, m in enumerate(starts):
		body = src[m.end():starts[i + 1].start() if i + 1 < len(starts) else len(src)]
		s = re.search(r"size = Vector3\(([^)]*)\)", body)
		if not s:
			continue
		size = [float(v) for v in s.group(1).split(",")]
		shape = re.search(r'shape = "(\w+)"', body)
		out[m.group(1)] = (size, shape.group(1) if shape else "")
	return out


def script_text():
	parts = []
	for p in (GAME / "tools" / "asset_forge").rglob("*.py"):
		parts.append(p.read_text(encoding="utf-8", errors="replace"))
	return "\n".join(parts)


# ---------------- loading ----------------
def load(path):
	"""All triangles of the model in GAME space (x right, y up, z front), each with its material name."""
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=str(path))
	tris = []
	dg = bpy.context.evaluated_depsgraph_get()
	for o in bpy.context.scene.objects:
		if o.type != "MESH":
			continue
		me = o.evaluated_get(dg).to_mesh()
		bm = bmesh.new()
		bm.from_mesh(me)
		bmesh.ops.triangulate(bm, faces=bm.faces[:])
		mw = o.matrix_world
		names = [s.material.name if s.material else "?" for s in o.material_slots]
		for f in bm.faces:
			vs = []
			for v in f.verts:
				w = mw @ v.co
				vs.append(Vector((w.x, w.z, -w.y)))  # Blender z-up -> Godot y-up
			tris.append((vs, names[f.material_index] if f.material_index < len(names) else "?"))
		bm.free()
		o.evaluated_get(dg).to_mesh_clear()
	return tris


def key(v):
	return (round(v.x * 1000), round(v.y * 1000), round(v.z * 1000))


def find(par, k):
	while par[k] != k:
		par[k] = par[par[k]]
		k = par[k]
	return k


class Part:
	def __init__(self, tris):
		self.tris = tris
		vs = [v for t, _ in tris for v in t]
		self.lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
		self.hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
		uniq = {}
		polys = []
		for t, _ in tris:
			polys.append([uniq.setdefault(key(v), len(uniq)) for v in t])
		self.verts = [None] * len(uniq)
		for t, _ in tris:
			for v in t:
				self.verts[uniq[key(v)]] = v
		self.bvh = BVHTree.FromPolygons(self.verts, polys, epsilon=0.0)
		mats = {}
		for _, m in tris:
			mats[m] = mats.get(m, 0) + 1
		self.mat = max(mats, key=mats.get)
		self.area = sum(((t[1] - t[0]).cross(t[2] - t[0])).length / 2 for t, _ in tris)

	def near(self, other, d):
		return all(self.lo[i] - d <= other.hi[i] and other.lo[i] - d <= self.hi[i] for i in range(3))


def split_parts(tris):
	par = {}
	for t, _ in tris:
		ks = [key(v) for v in t]
		for k in ks:
			par.setdefault(k, k)
		r0 = find(par, ks[0])
		for k in ks[1:]:
			r = find(par, k)
			if r != r0:
				par[r] = r0
	groups = {}
	for t, m in tris:
		groups.setdefault(find(par, key(t[0])), []).append((t, m))
	return [Part(g) for g in groups.values()]


def touching(a, b):
	if not a.near(b, TOUCH):
		return False
	if a.bvh.overlap(b.bvh):
		return True
	small, big = (a, b) if len(a.verts) <= len(b.verts) else (b, a)
	for v in small.verts:
		hit = big.bvh.find_nearest(v, TOUCH)
		if hit[0] is not None:
			return True
	for v in big.verts:
		if small.lo.x - TOUCH <= v.x <= small.hi.x + TOUCH and small.lo.y - TOUCH <= v.y <= small.hi.y + TOUCH \
				and small.lo.z - TOUCH <= v.z <= small.hi.z + TOUCH:
			if small.bvh.find_nearest(v, TOUCH)[0] is not None:
				return True
	return False


# ---------------- checks ----------------
def whole(parts):
	return BVHTree.FromPolygons(*_flat(parts))


def _flat(parts):
	verts, polys = [], []
	for p in parts:
		for t, _ in p.tris:
			o = len(verts)
			verts += list(t)
			polys.append([o, o + 1, o + 2])
	return verts, polys


def check_float(parts):
	n = len(parts)
	par = list(range(n))

	def f(i):
		while par[i] != i:
			par[i] = par[par[i]]
			i = par[i]
		return i
	for i in range(n):
		for j in range(i + 1, n):
			if f(i) != f(j) and touching(parts[i], parts[j]):
				par[f(i)] = f(j)
	groups = {}
	for i in range(n):
		groups.setdefault(f(i), []).append(parts[i])
	if len(groups) <= 1:
		return []
	main = max(groups.values(), key=lambda g: sum(p.area for p in g))
	floor = min(p.lo.y for p in parts)
	out = []
	for g in groups.values():
		if g is main or min(p.lo.y for p in g) <= floor + TOUCH:  # touches the rest, or stands on the ground
			continue
		lo = Vector((min(p.lo.x for p in g), min(p.lo.y for p in g), min(p.lo.z for p in g)))
		hi = Vector((max(p.hi.x for p in g), max(p.hi.y for p in g), max(p.hi.z for p in g)))
		mats = sorted({p.mat for p in g})
		gap = min_gap(g, [p for p in parts if p not in g])
		out.append((sum(p.area for p in g), "%s at (%.2f, %.2f, %.2f), %.0fx%.0fx%.0f cm, %s from the rest" % (
			"/".join(mats), *((lo + hi) / 2), *((hi - lo) * 100), "%.1f cm" % (gap * 100) if gap < 1 else "far")))
	out.sort(reverse=True)
	return [t for _, t in out]


def min_gap(g, rest):
	best = 9.9
	for p in g:
		for q in rest:
			if not p.near(q, 0.3):
				continue
			for v in p.verts[:: max(1, len(p.verts) // 40)]:
				hit = q.bvh.find_nearest(v, best)
				if hit[0] is not None:
					best = min(best, hit[3])
	return best


def hidden(bvh, s, n, floor):
	"""True when nobody can see this spot: it faces the ground at the bottom, or other parts cover it."""
	if n.y < -0.9 and s.y < floor + 0.01:
		return True
	t = n.orthogonal().normalized()
	b = n.cross(t)
	for d in (n, (n + t).normalized(), (n - t).normalized(), (n + b).normalized(), (n - b).normalized()):
		if bvh.ray_cast(s + n * 0.004, d, 0.3)[0] is None:
			return False
	return True


def check_shimmer(parts):
	found = []
	every = whole(parts)
	floor = min(p.lo.y for p in parts)
	for i, a in enumerate(parts):
		for b in parts[i + 1:]:
			if not a.near(b, SAME):
				continue
			area = 0.0
			where = None
			for t, _ in a.tris:
				n = (t[1] - t[0]).cross(t[2] - t[0])
				ar = n.length / 2
				if ar < 1e-6:
					continue
				n.normalize()
				c = (t[0] + t[1] + t[2]) / 3
				hits = 0
				for s in (c, c.lerp(t[0], 0.8), c.lerp(t[1], 0.8), c.lerp(t[2], 0.8)):
					loc, nb, _, d = b.bvh.find_nearest(s, SAME)
					if loc is not None and nb.dot(n) > 0.995 and abs((s - loc).dot(n)) < SAME:
						hits += 1
				if hits and not hidden(every, c, n, floor):
					area += ar * hits / 4
					where = where or c
			if area >= SHIMMER_MIN:
				found.append((area, "%s on %s at (%.2f, %.2f, %.2f), %.0f cm²" % (a.mat, b.mat, *where, area * 1e4)))
	found.sort(reverse=True)
	return [t for _, t in found]


# Pieces allowed to stand higher than their game size (the part over it has no bumping box, like a railing):
# the spiral stairs' rail and post rise 1 m over the 2 m landing (F716).
OVER_TOP = {"stairs_spiral": 1.0}


VARIANT_OF = {"stairs_spiral_stacked": "stairs_spiral"}   # a model the game swaps in for a piece (F780: one with a flight on top)


def check_outline(name, tris, sizes):
	piece = name.split("__")[0]
	piece = VARIANT_OF.get(piece, piece)
	if piece not in sizes:
		return ["no piece called '%s' in pieces.gd" % piece]
	size, shape = sizes[piece]
	worst = {}

	def note(side, d, v):
		if d > worst.get(side, (OUT_MIN, None))[0]:
			worst[side] = (d, v)
	for t, _ in tris:
		for v in t:
			note("below the bottom", -v.y, v)
			note("above the top", v.y - size[1] - OVER_TOP.get(piece, 0.0), v)
			if shape == "tri":
				# edges: front z = +TRI_IN, and the two slanted sides through the point (0, -TRI_OUT)
				note("past the front edge", v.z - TRI_IN, v)
				for sx in (-1, 1):
					nx, nz = sx * math.sqrt(3) / 2, -0.5
					note("past the %s slanted edge" % ("left" if sx < 0 else "right"), v.x * nx + v.z * nz - TRI_OUT / 2, v)
			else:
				note("past the left side (x-)", -size[0] / 2 - v.x, v)
				note("past the right side (x+)", v.x - size[0] / 2, v)
				note("past the back (z-)", -size[2] / 2 - v.z, v)
				note("past the front (z+)", v.z - size[2] / 2, v)
	out = sorted(((d, "%.1f cm %s at (%.2f, %.2f, %.2f)" % (d * 100, side, v.x, v.y, v.z)) for side, (d, v) in worst.items()), reverse=True)
	return [t for _, t in out]


def check_roof(name, tris):
	piece = name.split("__")[0]
	rise, run = ROOFS[piece]
	cos = math.cos(math.atan2(rise, run))
	uniq = {}
	polys = []
	for t, _ in tris:
		polys.append([uniq.setdefault(key(v), len(uniq)) for v in t])
	verts = [None] * len(uniq)
	for t, _ in tris:
		for v in t:
			verts[uniq[key(v)]] = Vector((v.x, v.y, v.z))
	bvh = BVHTree.FromPolygons(verts, polys)
	thick = []
	holes = 0
	low = 0
	g = [-0.8 + 0.05 * i for i in range(33)]  # 5 cm apart, so rafters are always measured
	for x in g:
		for z in g:
			top = bvh.ray_cast(Vector((x, 10, z)), Vector((0, -1, 0)))
			bot = bvh.ray_cast(Vector((x, -5, z)), Vector((0, 1, 0)))
			if top[0] is None:
				holes += 1
				continue
			if bot[0] is not None:
				thick.append((top[0].y - bot[0].y) * cos)
				if bot[0].y < 0.02 and top[0].y > 0.4:
					low += 1  # filled down to the floor here
	out = []
	spots = len(g) * len(g)
	if holes:
		out.append("%d of %d spots you can see the sky through (holes)" % (holes, spots))
	if thick:
		# Layered roofs (rafters under boards under shingles) are thin between the rafters, so:
		# too thick = the usual spot (median) is over 30 cm; too thin = even the thickest spots
		# (top 5%, where the rafters are) are under 8 cm.
		thick.sort()
		med = thick[len(thick) // 2]
		top5 = thick[min(len(thick) - 1, int(len(thick) * 0.95))]
		if med > 0.30:
			out.append("panel is %.0f cm thick (should be 15-25 cm)" % (med * 100))
		elif top5 < 0.08:
			out.append("panel is only %.0f cm thick even at the rafters (should be 15-25 cm)" % (top5 * 100))
	if low > spots // 10:
		out.append("filled underneath (%d of %d spots solid down to the floor), should be open" % (low, spots))
	return out


def model_list(args):
	every = sorted(p for p in MODELS.rglob("*.glb"))
	if not args:
		return every
	out = []
	for a in args:
		if a.endswith(".glb"):   # a test model outside the game (e.g. journey/hearthbrick_v2/glb/x.glb)
			out.append(Path(a).resolve())
			continue
		hit = [p for p in every if p.parent.name == a or f"{p.parent.name}/{p.stem}" == a or p.stem == a]
		if not hit:
			print(f"?? nothing called {a}")
		out += hit
	return out


def has_script(name, scripts):
	"""Rule 1: a build script makes this model. Names are often put together in a loop
	(f"gem_{kind}", "axe_2h" + tier, piece + "__" + family), so the two halves may be found apart."""
	if (GAME / "tools" / "asset_forge" / "builds" / (name + ".py")).exists():
		return True

	def said(w):
		e = re.escape(w)
		return re.search(r"[\"'{]%s[\"'}]" % e, scripts) or re.search(r"[\"']%s_?\{" % e, scripts)
	if said(name) or re.search(r"\b%s\b" % re.escape(name), scripts):
		return True
	bits = re.split(r"(__|_)", name)
	for i in range(1, len(bits), 2):
		left, right = "".join(bits[:i]), "".join(bits[i + 1:])
		if said(left) and said(right):
			return True
	return False


def main():
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	report = None
	for a in list(args):
		if a.startswith("report="):
			report = GAME / a[7:]
			args.remove(a)
	sizes = piece_sizes()
	scripts = script_text()
	results = []
	for path in model_list(args):
		name = path.stem
		folder = path.parent.name
		probs = []
		if not has_script(name, scripts):
			probs.append(("SCRIPT", ["no build script mentions it (rule 1)"]))
		try:
			tris = load(path)
			parts = split_parts(tris)
			fl = check_float(parts)
			if fl:
				probs.append(("FLOAT", fl))
			sh = check_shimmer(parts)
			if sh:
				probs.append(("SHIMMER", sh))
			if folder == "build" or "__" in name:   # test models named <piece>__<family> count as building pieces
				ol = check_outline(name, tris, sizes)
				if ol:
					probs.append(("OUTLINE", ol))
				if name.split("__")[0] in ROOFS:
					rf = check_roof(name, tris)
					if rf:
						probs.append(("ROOF", rf))
		except Exception as e:  # a broken file is a problem too, not a crash
			probs.append(("BROKEN", [repr(e)]))
		results.append((f"{folder}/{name}", probs))
		if probs:
			print(f"MODEL {folder}/{name}:")
			for kind, lines in probs:
				print(f"  {kind}: " + lines[0] + (f"  (+{len(lines) - 1} more)" if len(lines) > 1 else ""))
				for ln in lines[1:4]:
					print(f"  {' ' * len(kind)}  {ln}")
		else:
			print(f"MODEL {folder}/{name}: ok")
	bad = [r for r in results if r[1]]
	kinds = {}
	for _, probs in bad:
		for k, _ in probs:
			kinds[k] = kinds.get(k, 0) + 1
	summary = "CHECKED %d models: %d ok, %d with problems (%s)" % (len(results), len(results) - len(bad), len(bad),
		", ".join(f"{k} {n}" for k, n in sorted(kinds.items())) or "none")
	print(summary)
	if report:
		lines = ["# Model check results", "", "Made by `tools/model_check/check_models.py` (rules: `docs/art/MODEL-RULES.md`).", "",
			summary, "", "| Model | Problem | Details |", "|---|---|---|"]
		for name, probs in bad:
			for kind, ls in probs:
				lines.append(f"| {name} | {kind} | " + " · ".join(ls[:3]).replace("|", "/") + (f" (+{len(ls) - 3} more)" if len(ls) > 3 else "") + " |")
		ok = [n for n, p in results if not p]
		lines += ["", f"**OK ({len(ok)}):** " + ", ".join(ok)]
		report.write_text("\n".join(lines) + "\n", encoding="utf-8")


main()
