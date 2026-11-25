# The Tomb of Hald Ironbrow's own stone and iron pieces (owner's play test, Nov 25: "it should look like a dark STONE
# dungeon"; F856, F857, F858, F859, F863). The wooden dungeons keep dungeon_rootwood.py's versions; these are the same
# size and shape, built from the Stonehold kit (stonehold_v2.py: chisel-cut blocks, dark mortar, iron), so the game
# moves them exactly like the wooden ones.
#
#   blender --background --factory-startup --python builds/dungeon_stonehold.py -- [out=<folder>] [pics=<folder>] [only=a,b] [grey=1]
#
# Game axes: x across, y up, z = front (+z faces the room). Origin bottom-centre.
#   entrance_stone          the way in (F859): the Stonehold round doorway, two big stone pillars on wide feet, a
#                           three-stone lintel with runes cut in its middle stone (same footprint as dungeon_entrance)
#   gate_iron               the barred way-out gate (F858): an iron rim round the round hole, upright iron bars, flat
#                           riveted straps across, hinge straps on its left (same shape and hinge as gate_round)
#   lever_iron              the way-out lever (F863): a stone plate on the wall, iron cheeks and pin, an iron handle with
#                           a stone knob. Parts "base" and "handle" (turns about LEVER_PIVOT, the same as the wooden lever)
#   wall_cracked_stone      the Ossuary stash's cracked wall (F857): stone courses with bulging stones,
#                           a hole knocked into it (dark behind), chips on the floor. Parts "frame" (the dark backing) and
#                           stone0..stone8 (each falls on its own when it breaks)
#   trap_chest_spikes_stone the Embalmers' spike floor (F856): 2 x 4 m of flagstones with iron-ringed spike holes.
#                           Parts "floor" and "spikes" (same holes and spikes as dungeon_mine.trap_chest_spikes)
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as S  # noqa: E402  (sets K.S = "stone")

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OPTS = dict(a.split("=", 1) for a in ARGS if "=" in a)
OUT = Path(OPTS.get("out", str(K.GAME / "assets" / "models" / "dungeon")))
PICS = Path(OPTS["pics"]) if "pics" in OPTS else None
ONLY = OPTS.get("only", "").split(",") if OPTS.get("only") else None
GREY = OPTS.get("grey") == "1"
J = K.J
E = S.E
LEVER_PIVOT = (0.0, 1.05, 0.13)   # = dungeon_rootwood.LEVER_PIVOT = the game's DungeonBuild.LEVER_PIVOT
SPIKE_HOLE = 0.042                # = dungeon_mine.SPIKE_HOLE


def meshes():
	return {o.name for o in bpy.data.objects if o.type == "MESH"}


def iron(v="dark"):
	return kit.tex_mat("iron", v)


def dark_stone():
	return kit.tex_mat("greystone", "dark")


def tag(names, role):
	for n in names:
		bpy.data.objects[n]["role"] = role


def bar(p0, p1, s, m, bevel=0.005, deep=None):
	"""A square iron bar from p0 to p1 (game axes), s thick (`deep` front to back, if it is flat)."""
	a, b = Vector(K.G(p0)), Vector(K.G(p1))
	o = K.blk((0, 0, 0), (s, (b - a).length, deep or s), m, bevel=bevel)   # (its length runs along Blender z)
	o.rotation_mode = "QUATERNION"
	o.rotation_quaternion = (b - a).normalized().to_track_quat("Z", "Y")
	o.location = (a + b) / 2
	return o


def bore(target, centre_blender, r, depth):
	"""Cut a round upright hole into `target` (a boolean difference with a cylinder)."""
	bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=r, depth=depth, location=centre_blender)
	cut = bpy.context.object
	m = target.modifiers.new("bore", "BOOLEAN")
	m.operation, m.object, m.solver = "DIFFERENCE", cut, "EXACT"
	bpy.ops.object.select_all(action="DESELECT")
	target.select_set(True)
	bpy.context.view_layer.objects.active = target
	bpy.ops.object.modifier_apply(modifier=m.name)
	bpy.data.objects.remove(cut, do_unlink=True)


# ---------------------------------------------------------------- the way in (F859)
def entrance_stone():
	"""The front door in the cave wall: the Stonehold round doorway, a big stone pillar either side (wide foot, four
	shaft stones, wide cap), a lintel of three heavy stones over it, runes cut into the middle one."""
	S.doorway(2.0, 2.0, 0.3)
	for sx in (-1, 1):
		cx = sx * 1.22
		before = meshes()
		K.blk((cx, 1.25, 0), (0.42, 2.3, 0.38), dark_stone(), bevel=0)   # the dark core: no joint is see-through
		tag(meshes() - before, "mortar")
		S.block((cx, 0.165, 0.02), (0.68, 0.33, 0.6), dark_stone(), cut=0.045, tilt=0.0, free="xz")   # (no dents underneath: they met the doorway's base)
		ys = [0.335, 0.85, 1.33, 1.86, 2.33]
		for i in range(4):
			S.block((cx + J(0.01), (ys[i] + ys[i + 1]) / 2, J(0.01)), (0.54 - K.rng.uniform(0, 0.03), ys[i + 1] - ys[i] - 0.004,
				0.5 - K.rng.uniform(0, 0.03)), cut=0.04, tilt=0.4, free="xz")
		S.block((cx, 2.415, 0.02), (0.66, 0.16, 0.58), cut=0.04, tilt=0.0, free="xyz")
		for k in range(2):  # chips of fallen stone at its foot
			S.block((cx + sx * (0.2 - 0.14 * k) + J(0.03), 0.04, 0.335 + J(0.01)), (0.12 + J(0.03), 0.08, 0.1 + J(0.02)),   # (leaning on the foot)
				cut=0.025, tilt=6.0, free="xyz")
	# the lintel: two long stones and a taller middle one, 3 mm apart, resting on the pillar caps
	for x0, x1, ya, yb in ((-1.6, -0.555, 2.49, 2.9), (-0.552, 0.552, 2.47, 2.98), (0.555, 1.6, 2.49, 2.9)):
		S.block(((x0 + x1) / 2, (ya + yb) / 2, 0.02), (x1 - x0, yb - ya, 0.6), cut=0.045, tilt=0.15, free="xyz")
	# three runes cut into the middle stone: dark strips set into its front face
	before = meshes()
	for rx, strokes in ((-0.3, [(0, 0, 90), (0.04, 0.04, 35), (0.04, -0.04, -35)]), (0.0, [(-0.04, 0, 90), (0.04, 0, 90), (0, 0, 0)]),
			(0.3, [(0, 0, 90), (0.035, 0.05, -40), (0.035, -0.05, 40)])):
		for k, (dx, dy, ang) in enumerate(strokes):   # (each stroke 4 mm further out: crossing strokes never share a face)
			K.blk((rx + dx, 2.725 + dy, 0.306 + 0.004 * k), (0.17 if ang in (0, 90) else 0.11, 0.028, 0.03), kit.mat("charcoal"), bevel=0.004, rz=ang)
	tag(meshes() - before, "rune")


# ---------------------------------------------------------------- the barred way-out gate (F858)
def rim(r_out, width, depth, zc, y_floor, m, n=28):
	"""One iron band round the round hole, from the floor on the left, over the top, to the floor on the right."""
	cy = S.DOOR_CY
	ri = r_out - width
	a0 = math.asin((y_floor - cy) / r_out)
	a1 = math.pi - a0
	v, f = [], []
	for k in range(n + 1):
		t = a0 + (a1 - a0) * k / n
		ti = math.asin(max(-1.0, (y_floor - cy) / ri)) if k == 0 else (math.pi - math.asin(max(-1.0, (y_floor - cy) / ri)) if k == n else t)
		for (x, y) in ((math.cos(t) * r_out, cy + math.sin(t) * r_out), (math.cos(ti) * ri, cy + math.sin(ti) * ri)):
			v += [(x, y, zc - depth / 2), (x, y, zc + depth / 2)]
	for k in range(n):
		a, b = 4 * k, 4 * (k + 1)   # per step: outer back, outer front, inner back, inner front
		f += [(a + 1, b + 1, b + 3, a + 3), (a, a + 2, b + 2, b), (a, b, b + 1, a + 1), (a + 2, a + 3, b + 3, b + 2)]
	last = 4 * n
	f += [(0, 1, 3, 2), (last, last + 2, last + 3, last + 1)]
	return K.mesh(v, f, m)


def gate_iron():
	"""The round gate in iron, the wooden gate_round's size and hinge (its left side): a rim, five upright bars,
	three flat straps across the front riveted where they cross, a floor bar, two hinge straps and their knuckles."""
	r, cy = S.DOOR_R - 0.012, S.DOOR_CY
	rw = 0.075
	rim(r, rw, 0.07, 0.035, E + 0.004, iron())
	ri = r - rw + 0.02   # the bars stop 2 cm inside the rim
	xs = (-0.48, -0.24, 0.0, 0.24, 0.48)
	for i, x in enumerate(xs):
		h = math.sqrt(max(0.0, ri * ri - x * x))
		y0, y1 = E + 0.06, cy + h
		K.blk((x + J(0.005), (y0 + y1) / 2, 0.032), (0.042, y1 - y0, 0.042), iron("a" if i % 2 else "dark"), bevel=0.006)
	hw0 = math.sqrt(max(0.0, (r - rw / 2) ** 2 - cy * cy))   # the floor bar between the rim's two feet
	K.blk((0, E + 0.045, 0.035), (2 * hw0, 0.07, 0.058), iron(), bevel=0.008)   # (thinner than the rim: no shared faces)
	for y in (cy - 0.36, cy, cy + 0.36):
		hw = math.sqrt(max(0.0, (r - 0.02) ** 2 - (y - cy) ** 2))   # each strap ends 2 cm inside the rim's outer edge
		K.blk((0, y + J(0.006), 0.083), (2 * hw, 0.065, 0.026), iron("b"), bevel=0.005)
		for x in xs:
			if abs(x) < hw - 0.04:
				kit.rivet(K.G((x, y, 0.097)), iron(), r=0.014)
		for sx in (-1, 1):
			kit.rivet(K.G((sx * (hw - 0.035), y, 0.097)), iron(), r=0.014)
	for y in (cy - 0.42, cy + 0.42):   # hinge straps on the left, wrapped round a knuckle
		hw = math.sqrt(max(0.0, (r - 0.02) ** 2 - (y - cy) ** 2))
		K.blk((-hw + 0.16, y, 0.083), (0.3, 0.075, 0.026), iron(), bevel=0.005)
		kit.cylinder(0.026, 0.12, K.G((-hw + 0.03, y, 0.083)), iron(), rot=(0, 0, 0), verts=10, bevel=0.003)
		kit.rivet(K.G((-hw + 0.22, y, 0.097)), iron(), r=0.013)


# ---------------------------------------------------------------- the way-out lever (F863)
def lever_iron():
	"""A stone plate pinned to the wall with two iron bolts, two iron cheeks with an iron pin through them, and an
	iron handle with a chunky stone knob, leaning up (off). Parts: "base" and "handle" (turns about LEVER_PIVOT)."""
	px, py, pz = LEVER_PIVOT
	before = meshes()
	S.block((0, 1.05, 0.045), (0.36, 0.7, 0.075), cut=0.025, tilt=0.0, free="xyz")
	for y in (0.78, 1.32):
		kit.rivet(K.G((0.0, y, 0.083)), iron(), r=0.022)
	for sx in (-1, 1):  # the cheeks either side of the handle
		K.blk((sx * 0.07, py, 0.115), (0.045, 0.16, 0.085), iron(), bevel=0.008)
	kit.cylinder(0.017, 0.2, K.G((0, py, pz)), iron(), rot=(0, 90, 0), verts=10, bevel=0.002)  # the pin
	base = meshes() - before
	before = meshes()
	a = math.radians(30)  # leaning up and out from the wall (off)
	tip = (0.0, py + 0.6 * math.cos(a), pz + 0.6 * math.sin(a))
	bar((0.0, py - 0.06, pz - 0.06 * math.tan(a) * 0), tip, 0.036, iron("a"))
	S.block(tip, (0.11, 0.11, 0.11), dark_stone(), cut=0.025, tilt=8.0, free="xyz")   # the knob
	handle = meshes() - before
	return {"base": base, "handle": handle}


# ---------------------------------------------------------------- the Ossuary stash's cracked wall (F857)
def wall_cracked_stone(w=2.0, h=2.0, d=0.3):
	"""A Stonehold wall that is about to give: a hole knocked into its middle (dark behind), three stones bulging out of line, chips on the floor in front."""
	before = set(bpy.data.objects)
	S.courses(w, h, d)
	made = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
	stones = [o for o in made if o.get("role") == "stone"]
	frame = {o.name for o in made if o.get("role") != "stone"}

	def mid(o):
		vs = [o.matrix_world @ v.co for v in o.data.vertices]
		return (sum(v.x for v in vs) / len(vs), sum(v.z for v in vs) / len(vs))   # (game x, game y)
	hole = sorted(stones, key=lambda o: math.hypot(mid(o)[0] - 0.15, mid(o)[1] - 1.05))[:2]
	for o in hole:  # knocked out: a smaller broken stone sits back in the gap, the rest is the dark hollow behind
		x, y = mid(o)
		stones.remove(o)
		bpy.data.objects.remove(o, do_unlink=True)
		stones.append(S.block((x + J(0.04), y - 0.07, -0.04), (0.2, 0.14, 0.12), cut=0.03, tilt=10.0, free="xyz"))
	for o in sorted(stones, key=lambda o: abs(mid(o)[0] + 0.45) + abs(mid(o)[1] - 0.7))[:3]:  # bulging out of line
		o.location.y -= K.rng.uniform(0.015, 0.03)   # (Blender -y = toward the room)
		o.rotation_euler.x += math.radians(J(3.0))
		o.rotation_euler.y += math.radians(J(3.0))
	# (no painted crack lines: as thin strips they looked like sticks lying on the wall, round 2)
	before = meshes()
	for k in range(5):  # chips on the floor in front, fresh from the hole
		S.block((-0.3 + 0.16 * k + J(0.04), 0.04, d / 2 + 0.1 + K.rng.uniform(0.0, 0.2)), (0.07 + J(0.02), 0.06, 0.07 + J(0.02)),
			cut=0.02, tilt=12.0, free="xyz")
	chips = meshes() - before
	frame |= chips
	groups = {"frame": frame}
	for o in stones:   # nine falling pieces: the stones grouped by where they sit (3 across, 3 up)
		x, y = mid(o)
		k = min(2, int((x + w / 2) / (w / 3))) + 3 * min(2, int(y / (h / 3)))
		groups.setdefault("stone%d" % k, set()).add(o.name)
	return groups


# ---------------------------------------------------------------- the Embalmers' spike floor (F856)
def spike_floor_stone(zc, holes, w=2.0, dd=2.0, t=0.25):
	"""One 2 x 2 m square of flagstones (centre z = zc) on a dark mortar bed, holes bored through for the spikes,
	an iron ring round each hole."""
	top = t - 0.015
	before = meshes()
	K.blk((0, 0.03, zc), (w - 0.06, 0.06, dd - 0.06), dark_stone(), bevel=0)
	bed = bpy.data.objects[(meshes() - before).pop()]
	bed["role"] = "mortar"
	flags = []
	xs = [-w / 2 + E, -0.28 + J(0.08), 0.36 + J(0.08), w / 2 - E]
	for i in range(3):
		zs = [-dd / 2 + E, -0.1 + J(0.25), dd / 2 - E]
		for j in range(2):
			a, b = xs[i] + (0.003 if i else 0.0), xs[i + 1] - (0.003 if i < 2 else 0.0)
			c0, c1 = zs[j] + (0.003 if j else 0.0), zs[j + 1] - (0.003 if j < 1 else 0.0)
			flags.append(S.block(((a + b) / 2, (0.06 + top) / 2, zc + (c0 + c1) / 2), (b - a, top - 0.06, c1 - c0),
				cut=0.03, tilt=0.0, dent=0.012, free="y"))
	for hx, hz in holes:
		p = Vector(K.G((hx, t / 2, zc + hz)))
		for o in flags + [bed]:
			bore(o, p, SPIKE_HOLE, 0.6)
		kit.ring(SPIKE_HOLE + 0.012, 0.011, K.G((hx, top + 0.004, zc + hz)), iron(), rot=(0, 0, 0), seg=14)


def trap_chest_spikes_stone():
	"""The stone twin of dungeon_mine.trap_chest_spikes: the chest's square (z = -1) and the square you stand on
	(z = +1), both full of spike holes, iron spikes waiting in them."""
	floor0 = meshes()
	chest_sq = []
	for k in range(12):  # round the chest (its 0.9 x 0.6 m spot stays clear)
		a = k * math.tau / 12 + math.radians(15)
		chest_sq.append((0.8 * math.cos(a), 0.8 * math.sin(a)))
	stand_sq = [(x, z) for x in (-0.72, -0.24, 0.24, 0.72) for z in (-0.72, -0.24, 0.24, 0.72)]
	spike_floor_stone(-1.0, chest_sq)
	spike_floor_stone(1.0, stand_sq)
	floor = meshes() - floor0
	before = meshes()
	for zc, holes in ((-1.0, chest_sq), (1.0, stand_sq)):
		for hx, hz in holes:  # iron spikes, up (tip 0.6 m above the floor); each shaft just fills its hole
			kit.cylinder(SPIKE_HOLE - 0.003, 0.3, K.G((hx, 0.1, zc + hz)), iron(), verts=10, bevel=0.003)
			kit.cone(SPIKE_HOLE - 0.003, 0.003, 0.62, K.G((hx, 0.25 + 0.31 - 0.002, zc + hz)), iron("a"), verts=10, bevel=0.0)
	spikes = meshes() - before
	return {"floor": floor, "spikes": spikes}


def save(name, groups=None):
	"""Apply modifiers, join each group into one named part (or everything into "model"), export .glb."""
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in objs:
		bpy.ops.object.select_all(action="DESELECT")
		o.select_set(True)
		bpy.context.view_layer.objects.active = o
		if not o.data.uv_layers:
			o.data.uv_layers.new(name="UVMap")
		for m in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=m.name)
	if not groups:
		groups = {"model": {o.name for o in objs}}
	parts = []
	for part, names in groups.items():
		members = [bpy.data.objects[n] for n in names if n in bpy.data.objects]
		if not members:
			continue
		bpy.ops.object.select_all(action="DESELECT")
		for o in members:
			o.select_set(True)
		bpy.context.view_layer.objects.active = members[0]
		bpy.ops.object.join()
		ob = bpy.context.object
		ob.name = part
		bpy.ops.object.origin_set(type="ORIGIN_CURSOR")   # (the game turns the lever's handle about LEVER_PIVOT)
		parts.append(ob)
	for img in bpy.data.images:
		if img.size[0] > 512:
			img.scale(512, 512)
	bpy.ops.object.select_all(action="DESELECT")
	for o in parts:
		o.select_set(True)
	OUT.mkdir(parents=True, exist_ok=True)
	path = str(OUT / f"{name}.glb")
	bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
		export_image_format="JPEG", export_image_quality=85)
	import glb_jpeg_fix
	glb_jpeg_fix.fix(path)
	tris = sum(len(p.vertices) - 2 for o in parts for p in o.data.polygons)
	print(f"STONEHOLD_DUNGEON_DONE {name} {tris} triangles, parts {[o.name for o in parts]}")
	return parts


BUILDS = {"entrance_stone": entrance_stone, "gate_iron": gate_iron, "lever_iron": lever_iron,
	"wall_cracked_stone": wall_cracked_stone, "trap_chest_spikes_stone": trap_chest_spikes_stone}

if __name__ == "__main__":
	for name, fn in BUILDS.items():
		if ONLY and name not in ONLY:
			continue
		for o in list(bpy.data.objects):
			bpy.data.objects.remove(o, do_unlink=True)
		K.rng.seed(sum(map(ord, name)))
		kit.reset()
		groups = fn()
		if GREY:
			S.make_grey()
		else:
			S.paint()
		parts = save(name, groups)
		if PICS:
			import cave_plants as cp
			PICS.mkdir(parents=True, exist_ok=True)
			cp.OUT = PICS
			cp.pictures(name, parts)
