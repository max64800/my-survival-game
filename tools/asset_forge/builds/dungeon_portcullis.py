# The Tomb of Hald Ironbrow's portcullis (F843, Nov 25): the Honour Chapel's ambush gate. When you walk in on the
# Shield-Brother it slams down behind you; it lifts again when he dies (src/world/dungeon_build.gd, "portcullis").
#
#   blender --background --factory-startup --python builds/dungeon_portcullis.py -- [out=<folder>] [pics=<folder>] [grey=1]
#
# Two parts (game axes: x across, y up, z = front; origin bottom-centre, the same as the Stonehold doorway piece):
#   frame  the Stonehold round doorway itself (stonehold_v2.doorway: block courses cut round 13 wedge stones and the
#          keystone). It takes the plain doorway's place at that junction (tools/dungeons/make_hald.py), so there are
#          never two stone frames in the same spot (Rule 2).
#   gate   an old iron grille (F862: plain dark iron, no rust-brown, which read as wood) cut to the round hole (Rule 5): an iron rim round the arch, upright bars with spike
#          teeth at the bottom, flat straps riveted across both faces. Shut, the teeth stand on the floor; the game
#          lifts the whole part GATE_LIFT up into the wall's slot, where only the row of teeth shows under the arch
#          (the clue). Bar/rivet/rust look from decor_nov21_c.py:portcullis_rusted, made round and bigger.
# Depths (front faces, so nothing shares a plane): bars 2.2 cm, bottom rail 3.3 cm, rim 3.5 cm, straps 4.7 cm.
import math
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kit  # noqa: E402
import kit_zone1 as K  # noqa: E402
import stonehold_v2 as S  # noqa: E402  (sets K.S = "stone")

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OPTS = dict(a.split("=", 1) for a in ARGS if "=" in a)
OUT = Path(OPTS.get("out", str(K.GAME / "assets" / "models" / "dungeon")))
PICS = Path(OPTS["pics"]) if "pics" in OPTS else None
GREY = OPTS.get("grey") == "1"
J = K.J

R = S.DOOR_R + 0.01 - 0.012   # the gate's outer edge: 1.2 cm inside the ring stones (the hole is DOOR_R + 0.01)
CY = S.DOOR_CY
FLOOR = 0.16 + 0.012          # the dungeon's floor top in the doorway's own size (0.24 m at 1.5x), plus 1.2 cm
RAIL_Y = FLOOR + 0.1 + 0.035  # the bottom rail's middle: the teeth hang 10 cm under it
GATE_LIFT = 1.15              # how far up it hangs when open (the game's DungeonBuild.PORTCULLIS_LIFT)
RIM_W = 0.06


def meshes():
	return {o.name for o in bpy.data.objects if o.type == "MESH"}


def iron():
	return kit.tex_mat("iron", "dark")


def rust():
	"""A second, lighter iron (owner, Nov 25, F862: the rust-brown tint looked like wood, so the bars are all iron now)."""
	return kit.tex_mat("iron", "a")


def old_iron():
	return iron() if K.rng.random() < 0.72 else rust()


def half_w(y, r=R):
	return math.sqrt(max(0.0, r * r - (y - CY) ** 2))


def rim():
	"""One iron band round the arch (a single mesh: inner and outer arc, front and back), from the bottom rail on the
	left, over the top, to the bottom rail on the right."""
	ro, ri = R, R - RIM_W
	a0 = math.asin((RAIL_Y - 0.035 - CY) / ro)
	a1 = math.pi - a0
	n = 28
	d = 0.07
	pts = []
	for k in range(n + 1):
		t = a0 + (a1 - a0) * k / n
		pts.append(((math.cos(t) * ro, CY + math.sin(t) * ro), (math.cos(t) * ri, CY + math.sin(t) * ri)))
	v = []
	for (o, i) in pts:
		for (x, y) in (o, i):
			v += [(x, y, -d / 2), (x, y, d / 2)]
	f = []
	for k in range(n):
		a, b = 4 * k, 4 * (k + 1)   # per step: outer back, outer front, inner back, inner front
		f += [(a + 1, b + 1, b + 3, a + 3), (a, a + 2, b + 2, b), (a, b, b + 1, a + 1), (a + 2, a + 3, b + 3, b + 2)]
	last = 4 * n
	f += [(0, 1, 3, 2), (last, last + 2, last + 3, last + 1)]
	K.mesh(v, f, old_iron())


def gate():
	before = meshes()
	rim()
	# bottom rail between the rim's two ends (its ends sit 1 cm into the rim's ends)
	hw = half_w(RAIL_Y - 0.035, R - RIM_W / 2)
	K.blk((0, RAIL_Y, 0), (2 * hw, 0.07, 0.066), iron(), bevel=0.006)
	# upright bars, square, from the rail to 3 cm into the rim; a spike tooth under each
	xs = [-0.6 + 0.15 * i for i in range(9)]
	for i, x in enumerate(xs):
		top = CY + math.sqrt(max(0.0, (R - RIM_W / 2) ** 2 - x * x))
		bot = RAIL_Y - 0.03
		m = rust() if i in (2, 6) else old_iron()
		K.blk((x + J(0.004), (top + bot) / 2, 0), (0.05, top - bot, 0.044), m, bevel=0.006)
		tip = FLOOR + J(0.004)
		kit.cone(0.038, 0.0, RAIL_Y - 0.035 - tip + 0.02, K.G((x, (RAIL_Y - 0.035 + tip) / 2 - 0.01, 0)), old_iron(),
			rot=(180, 0, 45), verts=4, bevel=0)
	# flat straps across both faces, cut 1 cm short of the rim's outer edge, riveted where they cross a bar
	for y in (FLOOR + 0.42, CY + 0.12, CY + 0.5):
		hw = half_w(y, R - 0.012)
		for face in (1, -1):
			K.blk((0, y, face * 0.032), (2 * hw, 0.075, 0.03), old_iron(), bevel=0.005)
			for x in xs:
				if abs(x) < hw - 0.03:
					kit.rivet(K.G((x, y + J(0.006), face * 0.049)), rust() if K.rng.random() < 0.3 else iron(), r=0.014)
			for sx in (-1, 1):
				kit.rivet(K.G((sx * (hw - 0.035), y, face * 0.049)), iron(), r=0.014)
	return meshes() - before


def save(name, groups):
	objs = [o for o in bpy.data.objects if o.type == "MESH"]
	for o in objs:
		bpy.ops.object.select_all(action="DESELECT")
		o.select_set(True)
		bpy.context.view_layer.objects.active = o
		if not o.data.uv_layers:
			o.data.uv_layers.new(name="UVMap")
		for m in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=m.name)
	parts = []
	for part, names in groups.items():
		members = [bpy.data.objects[n] for n in names if n in bpy.data.objects]
		bpy.ops.object.select_all(action="DESELECT")
		for o in members:
			o.select_set(True)
		bpy.context.view_layer.objects.active = members[0]
		bpy.ops.object.join()
		ob = bpy.context.object
		ob.name = part
		bpy.ops.object.origin_set(type="ORIGIN_CURSOR")   # origin at the model's (0, 0, 0): the game moves "gate" by GATE_LIFT
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
	print(f"PORTCULLIS_DONE {path} {tris} triangles, parts {[o.name for o in parts]}")
	return parts


def pictures(parts):
	"""Review pictures: shut from the front and from the side, and lifted (the clue: teeth under the arch)."""
	import cave_plants as cp
	cp.OUT = PICS
	cp.pictures("portcullis_shut", parts)
	g = bpy.data.objects["gate"]
	g.location.z += GATE_LIFT   # (Blender z = up)
	cp.OUT = PICS
	scene = bpy.context.scene
	cam = scene.camera
	from mathutils import Vector
	cam.location = Vector((0.25, -3.6, 1.0))
	cam.rotation_euler = (Vector((0, 0, 1.0)) - cam.location).to_track_quat("-Z", "Y").to_euler()
	scene.render.filepath = str(PICS / "portcullis_raised.png")
	bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
	K.rng.seed(sum(map(ord, "portcullis_hald")))
	kit.reset()
	before = meshes()
	S.doorway()
	frame = meshes() - before
	gparts = gate()
	if GREY:
		S.make_grey()
	else:
		S.paint()
	parts = save("portcullis", {"frame": frame, "gate": gparts})
	if PICS:
		PICS.mkdir(parents=True, exist_ok=True)
		pictures(parts)
