# Decor for OLD PELL'S DIGGINGS (Nov 21): the private diggings of Old Pell, a stubborn, clever, half-mad old miner who
# lived down here alone and booby-trapped everything. Small dungeon = root wood (Delver's Shack paintings) + iron/copper.
#   blender --background --factory-startup --python builds/decor_nov21_op.py -- [id ...]   (none = all)
# Output: assets/models/decor/<id>.glb (origin bottom-centre, front faces -Y in Blender = +Z in Godot).
# Wall pieces have a flat back at +Y so they sit flush on a wall. Brief: docs/art/DECOR-BRIEF-NOV21.md.
#
# Wall pieces (8)
#   op_rock_shelf        two shelves of Pell's odd rocks, each on a log-slice stand with an inked tag (geode, crystal, fossil...)
#   op_bone_board        his bone collection: a beast jaw with fangs, four rat skulls on pegs, two crossed long bones wired on
#   op_madness_board     diary pages nailed over each other, red cord strung between copper tacks, a knife pinning one page
#   op_trap_parts_rack   spare trap parts on pegs: two toothed jaw halves, a coiled spring, a tripwire spool, a chain, a spike strip
#   op_key_board         a framed key board, keys of every size on iron hooks, one hook empty with a clean key-shaped dent
#   op_warning_plank     a thick plank nailed up with a carved skull, crossed bones, zigzag teeth and slashes, a little bell hanging
#   op_map_rack          a pigeon-hole rack of rolled maps with ties, one map unrolled and hanging down with a red X
#   op_pipe_rack         Pell's smoking pipes standing in a holed rack, a tobacco pouch on a peg, a tinder box on the ledge
# Pell's living, tinkering and collecting (12)
#   op_still             his still: stone firebox with iron door, riveted copper pot, swan neck into a coiled worm barrel, a cup
#   op_tinker_bench      tinkering bench: iron vise holding a gear, gear train on a frame, springs, magnifier arm, drawer box
#   op_trapmaker_table   trap-making table: a bear trap half put together, the other jaw beside it, stake bundle, hammer, sketch
#   op_cot               his bare root-wood cot with rope webbing, plank headboard, boots under it, a candle stump beside
#   op_root_armchair     a crooked armchair grown from bent roots, spectacles on the arm, a book face-down by its foot
#   op_tumbler           hand-crank rock-polishing barrel on A-frames, hatch and latch, a tray of polished pebbles under it
#   op_sieve_stack       stacked ore sieves with iron mesh, a sorting tray of coarse/medium/fine chips, a copper scoop
#   op_hearth_tripod     cold fire ring of stones, charred logs and coal, iron tripod with chain and a lidded kettle
#   op_signpost          a root signpost in a stone cairn, three pointing boards with carved warnings, rat skull on top
#   op_spike_crate       slatted crate full of fire-hardened stakes, one dropped, a hatchet in a chopping stump
#   op_wire_spools       a sled stand with three spools of tripwire on an axle, wire running down to a loose coil, snips
#   op_ore_scale         a balance scale on a stump, one copper pan down with a nugget, graded iron weights in a row
# Story scenes (10)
#   op_caught_boot       a bear trap snapped shut on an empty boot (the foot got out), a snapped walking stick, a lantern on its side
#   op_diary_table       his last entry: open diary on a stump table, quill dropped, ink pot tipped and spilled, stool knocked over
#   op_x_marks_dig       a dig patch in a board frame, spoil heap with the shovel stuck in, tipped bucket, a map on a stake with an X
#   op_bell_tripwire     his alarm: a cord between two stakes with little copper bells, a big bell on a bracket at one end
#   op_barricade         planks nailed across two posts, sharpened stakes pointing out, a peephole with its cover swung aside
#   op_decoy_chest       a chest thrown open: no gold, just a spring that shot up a spiked iron plate
#   op_hat_on_pick       his pick buried in a stump, his battered candle hat hung on the handle, a little cairn at the foot
#   op_rat_traps         a row of rat traps on a plank: two set, one sprung empty, one sprung on a rat; a gnawed crate behind
#   op_strongbox_pried   an iron-banded strongbox pried open with the crowbar still wedged in, broken padlock on the floor
#   op_watch_post        a plank screen with a peephole and slide cover, a crossbow leaning on it, a stool and bolt quiver behind
import math
import sys
from pathlib import Path

import bpy
from mathutils import Euler, Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from night_stations import B, GAME, J, kit, log, mesh, rng  # noqa: E402
from night_materials import C, lump, sphere, _cm  # noqa: E402
from decor_nov21_c import chain, slab_xz  # noqa: E402
from decor_nov21_d import tube, glass  # noqa: E402
from decor_nov21_f import lathe as flathe  # noqa: E402
from decor_nov21_mp import place, t_axe  # noqa: E402

# ---- one wood family per model: the Delver's Shack paintings (root wood) ----
BARK = lambda: kit.tex_mat("shackbark", f"v{rng.randrange(4)}")  # noqa: E731
PLANK = lambda: kit.tex_mat("shackplank", f"v{rng.randrange(8)}")  # noqa: E731
DARKW = lambda: kit.tex_mat("shackdark", rng.choice("abc"))  # noqa: E731
LOGEND = lambda: kit.tex_mat("shacklogend", f"v{rng.randrange(4)}")  # noqa: E731
SSTONE = lambda: kit.tex_mat("shackstone", rng.choice("abc"))  # noqa: E731
IRON = lambda v="a": kit.tex_mat("iron", v)  # noqa: E731
CU = lambda v="b": kit.tex_mat("copper", v)  # noqa: E731
LEATHER = lambda v="dark": kit.tex_mat("leather", v)  # noqa: E731
ROPE = lambda: kit.tex_mat("rope", rng.choice("abc"))  # noqa: E731
BONE = lambda: C((0.66, 0.6, 0.47), 0.8)  # noqa: E731
GROOVE = lambda: C((0.09, 0.065, 0.05), 0.95)  # noqa: E731
PALE = lambda: C((0.55, 0.42, 0.27), 0.9)  # noqa: E731
PARCH = lambda: C((0.66, 0.56, 0.38), 0.95)  # noqa: E731
INK = lambda: C((0.14, 0.1, 0.07), 0.9)  # noqa: E731
RED = lambda: C((0.4, 0.08, 0.06), 0.9)  # noqa: E731
CHAR = lambda: C((0.06, 0.055, 0.05), 0.5)  # noqa: E731
GOLD = lambda: C((0.8, 0.56, 0.18), 0.3, metal=0.85)  # noqa: E731
WAX = lambda: C((0.82, 0.74, 0.55), 0.85)  # noqa: E731
ROCK = lambda v=None: kit.tex_mat("brownrock", v or rng.choice("abc"))  # noqa: E731


# ================= helpers =================
def group(build, at=(0, 0, 0), rot=(0, 0, 0)):
	"""Build parts around the origin, turn them by rot (degrees), move them to `at`; returns the new objects."""
	before = set(bpy.data.objects[:])
	build()
	bpy.context.view_layer.update()
	M = Matrix.Translation(Vector(at)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
	new = [o for o in bpy.data.objects[:] if o not in before]
	for o in new:
		o.matrix_world = M @ o.matrix_world
	bpy.context.view_layer.update()
	return new


def low_z(objs):
	return min((o.matrix_world @ v.co).z for o in objs if o.type == "MESH" for v in o.data.vertices)


def settle(objs, z=0.0):
	"""Drop a group so its lowest point sits at z (presses 3 mm in so it touches)."""
	dz = z - low_z(objs) - 0.003
	for o in objs:
		o.location.z += dz
	bpy.context.view_layer.update()


def turn(objs, axis, deg, pivot):
	R = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-Vector(pivot))
	for o in objs:
		o.matrix_world = R @ o.matrix_world
	bpy.context.view_layer.update()


def carve(target, build_cutters):
	"""Cut grooves INTO a part (boolean difference); the groove walls and floor take the cutters' dark colour."""
	before = set(bpy.data.objects[:])
	build_cutters()
	cuts = [o for o in bpy.data.objects[:] if o not in before]
	for o in cuts + [target]:
		bpy.ops.object.select_all(action="DESELECT")
		o.select_set(True)
		bpy.context.view_layer.objects.active = o
		for md in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=md.name)
	for cut in cuts:  # one cutter at a time: joined overlapping cutters self-intersect and wipe the target
		md = target.modifiers.new("carve", "BOOLEAN")
		md.operation = "DIFFERENCE"
		md.object = cut
		md.solver = "EXACT"
		try:
			md.material_mode = "TRANSFER"
		except (AttributeError, TypeError):
			pass
		bpy.ops.object.select_all(action="DESELECT")
		target.select_set(True)
		bpy.context.view_layer.objects.active = target
		bpy.ops.object.modifier_apply(modifier=md.name)
		bpy.data.objects.remove(cut, do_unlink=True)
	assert len(target.data.vertices) > 8, "carve wiped the part"
	return target


def groove(p0, p1, y, w=0.016, depth=0.024, m=None):
	"""A cutter stroke on a face at y (front faces -Y)."""
	(x0, z0), (x1, z1) = p0, p1
	ln = math.hypot(x1 - x0, z1 - z0)
	ang = math.degrees(math.atan2(z1 - z0, x1 - x0))
	return B((ln + w * 0.5, depth, w), ((x0 + x1) / 2, y, (z0 + z1) / 2), m or GROOVE(), bevel=0, rot=(0, -ang, 0))


def ink(p0, p1, y, w=0.008, m=None):
	"""An ink stroke on paper whose front is at y (half sunk in, 1.5 mm proud)."""
	(x0, z0), (x1, z1) = p0, p1
	ln = math.hypot(x1 - x0, z1 - z0)
	ang = math.degrees(math.atan2(z1 - z0, x1 - x0))
	B((ln + w * 0.4, 0.0032, w), ((x0 + x1) / 2, y - 0.0014, (z0 + z1) / 2), m or INK(), bevel=0, rot=(0, -ang, 0))


def rlog(p0, p1, r, **kw):
	"""A root-wood log with pale chopped ends."""
	kw.setdefault("end_m", LOGEND())
	if kw.get("ends", True) and min(r, kw.get("r1") or r) > 0.03:  # chopped end caps stick out 12 mm: keep them above the floor
		d = Vector(p1) - Vector(p0)
		cz = abs(d.z) / d.length
		lift = 0.013 * cz + 0.8 * r * math.sqrt(max(0.0, 1 - cz * cz))  # the cap disc dips when the log leans
		p0, p1 = [(p[0], p[1], max(p[2], lift)) if p[2] < lift else p for p in (p0, p1)]
	return log(p0, p1, r, kw.pop("m", None) or BARK(), **kw)


def board(w, h, d=0.05, z0=0.0, battens=True):
	"""Wall backing: upright split planks (each its own painting), flat back at y = d, front at y = 0,
	two dark battens with wooden pegs."""
	n = max(2, round(w / 0.21))
	planks = [B((w / n - 0.008, d, h + J(0.015)), (-w / 2 + w / n * (i + 0.5), d / 2, z0 + h / 2), PLANK(), bevel=0.008) for i in range(n)]
	if battens:
		for z in (z0 + 0.07, z0 + h - 0.07):
			B((w + 0.03, 0.03, 0.055), (0, -0.012, z), DARKW(), bevel=0.007)
			for i in range(n):
				peg((-w / 2 + w / n * (i + 0.5) + J(0.02), -0.027, z))
	return planks


def peg(loc, face="y"):
	"""A domed wooden peg head on a face (face y: front -Y, z: on top)."""
	s = (1, 0.55, 1) if face == "y" else (1, 1, 0.55)
	sphere(loc, 0.014, LOGEND(), scale=s, seg=10, rings=6)


def nail(x, y, z, m=None):
	kit.cylinder(0.011, 0.008, (x, y - 0.002, z), m or IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)


def hpeg(x, z, ln=0.09, y=0.0):
	"""A hanging peg driven into the board, tilted up a little."""
	log((x, y + 0.015, z), (x, y - ln, z + 0.016), 0.013, DARKW(), seg=6, rings=1, ends=False, bend=0)
	sphere((x, y - ln, z + 0.016), 0.017, DARKW(), seg=8, rings=5)


def shelf(w, z, depth=0.18):
	"""A plank shelf on two dark brackets, back pressed 4 mm into the board. Returns the top height."""
	B((w, depth, 0.035), (0, -depth / 2 + 0.004, z), PLANK(), bevel=0.008)
	for x in (-w / 2 + 0.07, w / 2 - 0.07):
		B((0.035, depth * 0.7, 0.1), (x, -depth * 0.35 + 0.004, z - 0.065), DARKW(), bevel=0.006)
		peg((x, -depth * 0.55, z + 0.0175), "z")
	return z + 0.0175


def tag(x, y, z, w=0.09):
	"""A small parchment tag on a shelf front (y = shelf front) with an inked word-scratch."""
	B((w, 0.004, 0.03), (x, y - 0.0015, z), PARCH(), bevel=0.001)
	B((w * 0.6, 0.003, 0.005), (x - w * 0.08, y - 0.0035, z + 0.003), INK(), bevel=0)
	B((w * 0.35, 0.003, 0.004), (x - w * 0.2, y - 0.0035, z - 0.007), INK(), bevel=0)


def arc_pts(R, a0, a1, n=12):
	return [(R * math.cos(math.radians(a0 + (a1 - a0) * i / n)), 0, R * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def jaw(R=0.12, teeth="in", skip=0.0, m=None):
	"""A bear-trap jaw: an iron half ring in the local XZ plane (centre at origin), teeth pointing in or up (+Y)."""
	m = m or IRON("dark")
	tube(arc_pts(R, 0, 180, 14), 0.012, 0.012, m, seg=7)
	for k in range(9):
		a = math.radians(14 + k * 19)
		if abs(math.degrees(a) - 90) < skip:
			continue
		P = Vector((R * math.cos(a), 0, R * math.sin(a)))
		ln = 0.035
		if teeth == "in":
			d = -P.normalized()
			kit.cone(0.011, 0.001, ln, tuple(P + d * (0.006 + ln / 2)), m, rot=(0, math.degrees(math.atan2(d.x, d.z)), 0), verts=4, bevel=0)
		else:
			kit.cone(0.011, 0.001, ln, tuple(P + Vector((0, 0.006 + ln / 2, 0))), m, rot=(-90, 0, 0), verts=4, bevel=0)


def helix(r, wire, turns, h, m, n_per=10):
	"""A coil spring along local +Z from 0 to h."""
	N = int(turns * n_per)
	pts = [(r * math.cos(2 * math.pi * i / n_per), r * math.sin(2 * math.pi * i / n_per), h * i / N) for i in range(N + 1)]
	return tube(pts, wire, wire, m, seg=6)


def gear(c, r, t, m, rot=(0, 0, 0), n=8):
	def build():
		kit.cylinder(r, t, (0, 0, 0), m, verts=16, bevel=0.003)
		for k in range(n):
			a = 2 * math.pi * k / n
			B((r * 0.35, r * 0.3, t * 0.9), (math.cos(a) * r * 1.08, math.sin(a) * r * 1.08, 0), m, bevel=0.002, rot=(0, 0, math.degrees(a)))
		kit.cylinder(r * 0.3, t + 0.008, (0, 0, 0), IRON("dark"), verts=8, bevel=0.002)
		for k in range(4):
			a = 2 * math.pi * k / 4 + 0.4
			kit.cylinder(r * 0.12, t + 0.004, (math.cos(a) * r * 0.62, math.sin(a) * r * 0.62, 0), CU("dark"), verts=6, bevel=0)
	return group(build, c, rot)


def lantern(c=(0, 0, 0), rot=(0, 0, 0), lit=False):
	def build():
		kit.cylinder(0.07, 0.025, (0, 0, 0.0125), IRON("dark"), verts=10, bevel=0.004)
		for sx in (-1, 1):
			for sy in (-1, 1):
				B((0.014, 0.014, 0.17), (sx * 0.05, sy * 0.05, 0.105), IRON("dark"), bevel=0.003)
		B((0.092, 0.092, 0.15), (0, 0, 0.1), glass(), bevel=0)
		for z in (0.06, 0.13):
			kit.ring(0.068, 0.005, (0, 0, z), IRON("a"), seg=4, rot=(0, 0, 45))
		kit.cylinder(0.07, 0.02, (0, 0, 0.19), IRON("dark"), verts=10, bevel=0.004)
		kit.cone(0.065, 0.018, 0.06, (0, 0, 0.225), IRON("dark"), verts=10, bevel=0.004)
		kit.ring(0.028, 0.006, (0, 0, 0.27), IRON("a"), rot=(90, 0, 0), seg=10)
		kit.cylinder(0.018, 0.05, (0, 0, 0.05), WAX(), verts=8, bevel=0.003)
		if lit:
			kit.flame((0, 0, 0.075), 0.012, 0.04, C((1.0, 0.7, 0.3), 0.3, glow=2.0))
	return group(build, c, rot)


def boot(c, rotz=0.0, lying=False):
	"""An old leather boot (toe toward local -Y)."""
	def build():
		B((0.115, 0.25, 0.022), (0, -0.05, 0.011), LEATHER("dark"), bevel=0.008)  # sole
		B((0.11, 0.06, 0.04), (0, 0.04, 0.03), LEATHER("dark"), bevel=0.008)  # heel
		B((0.105, 0.2, 0.085), (0, -0.05, 0.062), LEATHER("b"), bevel=0.03)  # foot
		sphere((0, -0.14, 0.05), 0.055, LEATHER("b"), scale=(1, 0.9, 0.8))  # toe
		kit.cylinder(0.058, 0.24, (0, 0.03, 0.17), LEATHER("b"), verts=12, bevel=0.01)  # shaft
		kit.ring(0.06, 0.012, (0, 0.03, 0.285), LEATHER("dark"), seg=14)  # folded cuff
		for k in range(3):
			kit.rivet((0, -0.026, 0.12 + k * 0.045), CU("dark"), r=0.008)
		kit.cylinder(0.003, 0.11, (0.0, -0.03, 0.09), LEATHER("dark"), rot=(60, 0, 0), verts=5, bevel=0)  # lace
	return group(build, c, (0, 90, rotz) if lying else (0, 0, rotz))  # lying: on its side, toe sideways


def stump(r, h, c=(0, 0)):
	return rlog((c[0], c[1], 0), (c[0], c[1], h), r, seg=12, rings=3, bend=0.0)


def stool3(c=(0, 0, 0), rot=(0, 0, 0)):
	def build():
		kit.cylinder(0.17, 0.06, (0, 0, 0.42), LOGEND(), verts=12, bevel=0.01)
		kit.cylinder(0.182, 0.04, (0, 0, 0.405), BARK(), verts=12, bevel=0.008)
		for k in range(3):
			a = 2 * math.pi * k / 3
			rlog((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.41), (math.cos(a) * 0.17, math.sin(a) * 0.17, 0.0), 0.035, seg=6, rings=2, ends=False)
		kit.ring(0.115, 0.012, (0, 0, 0.2), ROPE(), seg=14)
	return group(build, c, rot)


def page(cx, cz, w, h, y0, tilt=0.0, thick=0.002, m=None):
	"""A ragged paper sheet in the wall plane, back at y0, tilted `tilt` degrees. Returns (front y, point fn)."""
	ca, sa = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))
	P = lambda x, z: (cx + x * ca - z * sa, cz + x * sa + z * ca)  # noqa: E731
	pts = []
	for i in range(6):
		pts.append(P(-w / 2 + w * i / 5 + J(0.006), -h / 2 + J(0.008)))
	for i in range(1, 5):
		pts.append(P(w / 2 + J(0.006), -h / 2 + h * i / 5))
	for i in range(6):
		pts.append(P(w / 2 - w * i / 5 + J(0.006), h / 2 + J(0.008)))
	for i in range(1, 5):
		pts.append(P(-w / 2 + J(0.006), h / 2 - h * i / 5))
	slab_xz(pts, y0 - thick, y0, m or PARCH())
	return y0 - thick, P


def tack(x, z, yfront, m=None):
	kit.cylinder(0.004, abs(yfront) + 0.006, (x, yfront / 2 + 0.001, z), IRON("dark"), rot=(90, 0, 0), verts=5, bevel=0)
	kit.cylinder(0.011, 0.004, (x, yfront - 0.001, z), m or CU("dark"), rot=(90, 0, 0), verts=8, bevel=0.001)


def bell(c, s=1.0):
	"""A small copper bell hanging from its loop at c."""
	x, y, z = c
	kit.ring(0.012 * s, 0.004 * s, (x, y, z - 0.01 * s), CU("dark"), rot=(90, 0, 0), seg=8)
	kit.cone(0.036 * s, 0.016 * s, 0.05 * s, (x, y, z - 0.043 * s), CU("b"), verts=12, bevel=0.003)
	kit.ring(0.034 * s, 0.005 * s, (x, y, z - 0.067 * s), CU("b"), seg=14)
	kit.cylinder(0.003 * s, 0.04 * s, (x, y, z - 0.058 * s), IRON("dark"), verts=5, bevel=0)
	sphere((x, y, z - 0.078 * s), 0.009 * s, IRON("dark"), seg=8, rings=5)


def barrel(c, r, h, open_top=True, n=14, axis="z"):
	"""A staved barrel (staves = split planks), three iron hoops, dark inside."""
	def build():
		for k in range(n):
			a = 2 * math.pi * (k + 0.5) / n
			B((2 * math.pi * r / n * 1.02, 0.03, h), (math.cos(a) * (r - 0.015), math.sin(a) * (r - 0.015), h / 2), PLANK(), bevel=0.005,
				rot=(0, 0, math.degrees(a) + 90))
		for z in (0.1, h / 2, h - 0.1):
			kit.ring(r + 0.004, 0.011, (0, 0, z), IRON("dark"), seg=20)
		kit.cylinder(r - 0.02, 0.03, (0, 0, h - 0.07 if open_top else h - 0.02), CHAR() if open_top else DARKW(), verts=n, bevel=0)
		kit.cylinder(r - 0.02, 0.03, (0, 0, 0.03), DARKW(), verts=n, bevel=0)
	return group(build, c, (0, 90, 0) if axis == "x" else (0, 0, 0))


def coal_bits(xc, yc, z, w, d, n, seed):
	import random
	r = random.Random(seed)
	for k in range(n):
		s = r.uniform(0.6, 1.2)
		lump((xc + r.uniform(-w / 2, w / 2), yc + r.uniform(-d / 2, d / 2), z + 0.012 * s), (0.035 * s, 0.028 * s, 0.022 * s), CHAR(), seed=k + seed, rough=0.004)


def spectacles(c, rotz=0.0):
	def build():
		for s_ in (-1, 1):
			kit.ring(0.022, 0.0035, (s_ * 0.028, 0, 0.004), CU("dark"), seg=14)
			kit.cylinder(0.02, 0.002, (s_ * 0.028, 0, 0.004), glass(), verts=12, bevel=0)
			B((0.07, 0.004, 0.004), (s_ * 0.05, 0.035, 0.004), CU("dark"), bevel=0, rot=(0, 0, s_ * 80))
		tube([(-0.01, 0, 0.005), (0, 0, 0.012), (0.01, 0, 0.005)], 0.003, 0.003, CU("dark"), seg=5)
	return group(build, c, (0, 0, rotz))


# ================= Wall pieces =================
def op_rock_shelf():
	W = 1.0
	board(W, 0.8)
	gems = (C((0.45, 0.2, 0.55), 0.2, glow=0.25), C((0.25, 0.6, 0.55), 0.2, glow=0.3))
	for i, z in enumerate((0.12, 0.46)):
		top = shelf(W + 0.04, z)
		for k in range(5):
			x = -0.38 + k * 0.19
			y = -0.085
			kit.cylinder(0.055, 0.03, (x, y, top + 0.012), LOGEND(), verts=11, bevel=0.004)
			kit.ring(0.056, 0.005, (x, y, top + 0.026), BARK(), seg=12)
			s = top + 0.027
			kind = (k + i * 2) % 5
			if kind == 0:  # banded rock with copper vein
				lump((x, y, s + 0.04), (0.06, 0.05, 0.05), ROCK("b"), seed=k + i, rough=0.008)
				for q in range(3):
					kit.gem((x - 0.03 + q * 0.03, y - 0.035, s + 0.03 + q * 0.012), (0.018, 0.014, 0.012), CU("b"), seed=q)
			elif kind == 1:  # geode, opened, standing on its edge
				kit.cylinder(0.06, 0.05, (x, y + 0.005, s + 0.058), ROCK("c"), rot=(90, 0, 0), verts=12, bevel=0.012)
				kit.cylinder(0.044, 0.02, (x, y - 0.018, s + 0.058), C((0.2, 0.1, 0.25), 0.4), rot=(90, 0, 0), verts=12, bevel=0)
				for q in range(6):
					a = q * 1.05
					kit.crystal((x + math.cos(a) * 0.022, y - 0.022, s + 0.058 + math.sin(a) * 0.022), 0.009, 0.03, gems[0],
						tilt=(90 + math.sin(a) * 25, 0, -math.cos(a) * 25))
			elif kind == 2:  # crystal cluster on a stone
				lump((x, y, s + 0.025), (0.055, 0.045, 0.03), ROCK("a"), seed=k + 7, rough=0.006)
				kit.crystal_cluster((x, y, s + 0.035), 0.3, gems[1], seed=k + i)
			elif kind == 3:  # fossil shell: a stone disc with a spiral carved in
				o = kit.cylinder(0.06, 0.04, (x, y + 0.005, s + 0.058), ROCK("b"), rot=(90, 0, 0), verts=14, bevel=0.01)
				yf = y - 0.015

				def spiral(x=x, s=s, yf=yf):
					for q in range(11):
						a0, a1 = q * 0.75, (q + 1) * 0.75
						r0, r1 = 0.008 + 0.004 * a0, 0.008 + 0.004 * a1
						groove((x + math.cos(a0) * r0, s + 0.058 + math.sin(a0) * r0), (x + math.cos(a1) * r1, s + 0.058 + math.sin(a1) * r1), yf, w=0.007, depth=0.012)
				carve(o, spiral)
			else:  # gold nugget on a darker stone
				lump((x, y, s + 0.022), (0.05, 0.042, 0.026), ROCK("dark"), seed=k + 11, rough=0.006)
				lump((x + 0.008, y - 0.005, s + 0.05), (0.03, 0.026, 0.022), GOLD(), seed=k + 3, rough=0.005)
			tag(x, -0.176, z, w=0.09)


def op_bone_board():
	W, H = 0.9, 0.76
	board(W, H)
	# beast jaw over the top (an upside-down U), fangs pointing in
	cz, R = 0.43, 0.3
	pts = [(R * math.cos(math.radians(a)) * 1.0, -0.035, cz + R * 0.75 * math.sin(math.radians(a))) for a in range(10, 171, 16)]
	tube(pts, 0.024, 0.024, BONE(), seg=8)
	for i, p in enumerate(pts[1:-1]):
		P = Vector(p)
		d = (Vector((0, -0.035, cz)) - P).normalized()
		ln = 0.08 if i in (0, len(pts) - 3) else 0.04 + 0.01 * (i % 2)
		kit.cone(0.013, 0.002, ln, tuple(P + d * (0.012 + ln / 2)), BONE(), rot=(0, math.degrees(math.atan2(d.x, d.z)), 0), verts=6, bevel=0)
	for x in (-0.24, 0.24):  # copper wire staples holding the jaw
		zz = cz + R * 0.75 * math.sin(math.acos(x / R))
		B((0.012, 0.04, 0.07), (x, -0.025, zz), CU("dark"), bevel=0.003)
	# four rat skulls, each sitting on a peg
	for k, x in enumerate((-0.3, -0.1, 0.1, 0.3)):
		z = 0.31 + J(0.01)
		hpeg(x, z - 0.045, ln=0.06)
		sphere((x, -0.06, z), 0.034, BONE(), scale=(1, 1.25, 0.85))
		kit.cone(0.026, 0.011, 0.055, (x, -0.11, z - 0.008), BONE(), rot=(90, 0, 0), verts=8, bevel=0.003)
		for s_ in (-1, 1):
			sphere((x + s_ * 0.019, -0.083, z + 0.008), 0.011, GROOVE(), seg=8, rings=5)
			kit.cone(0.004, 0.0, 0.016, (x + s_ * 0.008, -0.132, z - 0.022), BONE(), rot=(180, 0, 0), verts=4, bevel=0)
		B((0.06, 0.004, 0.025), (x, -0.0015, z - 0.09), PARCH(), bevel=0.001)
		B((0.035, 0.003, 0.005), (x, -0.0035, z - 0.09), INK(), bevel=0)
	# two long bones crossed, wired at the middle
	for k, (s_, y) in enumerate(((1, -0.024), (-1, -0.052))):
		a = math.radians(22 * s_)
		dx, dz = math.cos(a) * 0.27, math.sin(a) * 0.27
		log((-dx, y, 0.17 - dz), (dx, y, 0.17 + dz), 0.017, BONE(), seg=7, rings=3, ends=False, bend=0.03)
		for e in (-1, 1):
			for q in (-1, 1):
				sphere((e * dx * 1.02 - q * math.sin(a) * 0.016, y, 0.17 + e * dz * 1.02 + q * math.cos(a) * 0.016), 0.022, BONE(), seg=8, rings=6)
	kit.ring(0.04, 0.005, (0, -0.038, 0.17), CU("dark"), rot=(0, 45, 0), seg=12)
	kit.ring(0.04, 0.005, (0, -0.038, 0.17), CU("dark"), rot=(0, -45, 0), seg=12)


def op_madness_board():
	W, H = 1.1, 0.82
	board(W, H)
	heads = []
	layout = ((-0.35, 0.56, 0.22, 0.27, -4), (-0.08, 0.6, 0.2, 0.25, 3), (0.24, 0.55, 0.24, 0.28, -2), (0.42, 0.3, 0.16, 0.22, 6),
		(-0.4, 0.25, 0.2, 0.24, 5), (-0.16, 0.33, 0.22, 0.2, -6), (0.12, 0.25, 0.22, 0.26, 2), (-0.02, 0.45, 0.14, 0.16, 12))
	for k, (cx, cz, w, h, t) in enumerate(layout):
		yf, P = page(cx, cz, w, h, -0.002 - 0.0065 * k, t)
		y = yf
		if k in (0, 4, 6):  # writing rows
			for r in range(6):
				ln = w * (0.75 if r < 5 else 0.4) + J(0.02)
				ink(P(-w / 2 + 0.02, h / 2 - 0.04 - r * 0.033), P(-w / 2 + 0.02 + ln * 0.85, h / 2 - 0.04 - r * 0.033), y, w=0.006)
		elif k in (1, 3):  # trap sketch: a jaw circle with teeth
			for q in range(10):
				a0, a1 = 2 * math.pi * q / 10, 2 * math.pi * (q + 1) / 10
				rr = min(w, h) * 0.3
				ink(P(math.cos(a0) * rr, math.sin(a0) * rr), P(math.cos(a1) * rr, math.sin(a1) * rr), y, w=0.006)
				ink(P(math.cos(a0) * rr, math.sin(a0) * rr), P(math.cos(a0) * rr * 0.7, math.sin(a0) * rr * 0.7), y, w=0.005)
		elif k in (2, 5):  # tunnel map with a red ring
			path = [(-0.09, -0.08), (-0.04, -0.02), (0.0, -0.05), (0.05, 0.03), (0.08, 0.06)]
			for a, b in zip(path, path[1:]):
				ink(P(*a), P(*b), y, w=0.01)
			for q in range(8):
				a0, a1 = 2 * math.pi * q / 8, 2 * math.pi * (q + 1) / 8
				ink(P(0.05 + math.cos(a0) * 0.03, 0.03 + math.sin(a0) * 0.03), P(0.05 + math.cos(a1) * 0.03, 0.03 + math.sin(a1) * 0.03), y - 0.0033, w=0.006, m=RED())
		else:  # a page scratched over again and again
			for q in range(5):
				ink(P(-w / 2 + 0.02, -h / 2 + 0.03 + q * 0.025), P(w / 2 - 0.02, -h / 2 + 0.05 + q * 0.025), y, w=0.007)
		tk = P(0, h / 2 - 0.018)
		tack(tk[0], tk[1], y)
		heads.append((tk[0], y - 0.003, tk[1]))
		tk2 = P(-w / 2 + 0.02, -h / 2 + 0.02)
		tack(tk2[0], tk2[1], y)
	# red cord strung from tack to tack (sagging a little)
	for a, b in ((0, 5), (5, 3), (3, 2), (2, 7), (7, 4)):
		p0, p1 = Vector(heads[a]), Vector(heads[b])
		mid = (p0 + p1) / 2 + Vector((0, -0.01, -0.03))
		tube([tuple(p0), tuple((p0 + mid) / 2 + Vector((0, 0, -0.008))), tuple(mid), tuple((mid + p1) / 2 + Vector((0, 0, -0.008))), tuple(p1)], 0.004, 0.004, RED(), seg=5)
	# a knife stabbed through the bottom-right page
	kx, kz = 0.18, 0.16
	B((0.012, 0.03, 0.024), (kx, -0.04, kz), IRON("a"), bevel=0.002)
	B((0.07, 0.012, 0.02), (kx, -0.058, kz), IRON("dark"), bevel=0.003)
	kit.cylinder(0.016, 0.1, (kx, -0.11, kz), DARKW(), rot=(90, 0, 0), verts=8, bevel=0.004)
	kit.ring(0.017, 0.004, (kx, -0.13, kz), CU("dark"), rot=(90, 0, 0), seg=10)
	sphere((kx, -0.162, kz), 0.018, CU("dark"), seg=8, rings=5)


def op_trap_parts_rack():
	W, H = 1.2, 0.86
	board(W, H)
	# two jaw halves hanging on pegs
	for x in (-0.42, -0.12):
		hpeg(x, 0.6, ln=0.08)
		group(lambda: jaw(0.12, "in", skip=25), (x, -0.06, 0.6 - 0.105), (0, 0, 0))
	# coiled spring hanging by its hook
	hpeg(0.14, 0.66, ln=0.08)
	group(lambda: helix(0.034, 0.007, 7, 0.22, IRON("a")), (0.14, -0.06, 0.36), (0, 0, 0))
	tube([(0.174, -0.06, 0.58), (0.17, -0.06, 0.63), (0.14, -0.066, 0.67), (0.12, -0.064, 0.655)], 0.006, 0.006, IRON("a"), seg=6)
	# tripwire spool on a peg (axle along y)
	sx, sz = 0.4, 0.58
	log((sx, 0.015, sz), (sx, -0.13, sz), 0.016, DARKW(), seg=6, rings=1, ends=False, bend=0)
	kit.cylinder(0.04, 0.09, (sx, -0.07, sz), LOGEND(), rot=(90, 0, 0), verts=12, bevel=0.004)
	for y in (-0.025, -0.115):
		kit.cylinder(0.07, 0.012, (sx, y, sz), PLANK(), rot=(90, 0, 0), verts=14, bevel=0.003)
	for k in range(6):
		kit.ring(0.046 + (k % 2) * 0.003, 0.004, (sx, -0.04 - k * 0.012, sz), IRON("a"), rot=(90, 0, 0), seg=14)
	tube([(sx + 0.048, -0.07, sz), (sx + 0.06, -0.07, sz - 0.1), (sx + 0.05, -0.075, sz - 0.2), (sx + 0.065, -0.08, sz - 0.26)], 0.003, 0.003, IRON("a"), seg=5)
	# a chain hanging from a peg, hook at the end
	hpeg(0.54, 0.7, ln=0.07)
	chain((0.54, -0.07, 0.7), (0.54, -0.07, 0.36), R=0.02, wire=0.006)
	tube([(0.54, -0.07, 0.36), (0.54, -0.07, 0.31), (0.565, -0.07, 0.3), (0.575, -0.07, 0.33)], 0.008, 0.005, IRON("dark"), seg=6)
	# a strip of sharpened iron spikes standing in a drilled batten
	top = shelf(1.0, 0.16, depth=0.14)
	for k in range(11):
		x = -0.42 + k * 0.084
		kit.cylinder(0.008, 0.14, (x, -0.07, top + 0.06), IRON("dark"), verts=6, bevel=0)
		kit.cone(0.009, 0.0, 0.05, (x, -0.07, top + 0.155), IRON("a"), verts=4, bevel=0)
		kit.ring(0.014, 0.004, (x, -0.07, top + 0.002), IRON("dark"), seg=8)
	tag(0.0, -0.136, 0.16, w=0.14)


def op_key_board():
	W, H = 0.64, 0.76
	planks = board(W, H, battens=False)
	for s_ in (-1, 1):  # frame
		B((W + 0.04, 0.035, 0.05), (0, -0.012, 0.025 if s_ < 0 else H - 0.025), DARKW(), bevel=0.008)
		B((0.05, 0.035, H - 0.08), (s_ * (W / 2 - 0.005), -0.012, H / 2), DARKW(), bevel=0.008)
	for (x, z) in ((-W / 2, 0.02), (W / 2, 0.02), (-W / 2, H - 0.02), (W / 2, H - 0.02)):
		B((0.06, 0.012, 0.06), (x, -0.032, z), IRON("dark"), bevel=0.004)
		nail(x, -0.036, z)
	cols = (-0.21, -0.07, 0.07, 0.21)
	empty = (1, 2)  # row, col: the missing key

	def key(x, z, size, m):
		kit.ring(0.02 * size, 0.0055, (x, -0.05, z - 0.016 * size), m, rot=(90, 0, 0), seg=12)
		ln = 0.1 * size
		B((0.011, 0.011, ln), (x, -0.05, z - 0.034 * size - ln / 2), m, bevel=0.002)
		for q in range(2 + int(size > 1)):
			B((0.024, 0.009, 0.012), (x + 0.015, -0.05, z - 0.034 * size - ln + 0.012 + q * 0.018), m, bevel=0.0015)

	for r, z in enumerate((0.64, 0.44, 0.24)):
		for c, x in enumerate(cols):
			kit.cylinder(0.006, 0.065, (x, -0.025, z), IRON("dark"), rot=(90, 0, 0), verts=6, bevel=0)
			kit.cone(0.007, 0.004, 0.022, (x, -0.055, z + 0.009), IRON("dark"), verts=6, bevel=0)
			nail(x, -0.002, z)
			if (r, c) == empty:
				continue
			size = (0.8, 1.0, 1.3, 0.9)[(r + c) % 4]
			key(x, z - 0.003 + 0.016 * size - 0.02 * size + 0.0, size, CU("dark") if (r + c) % 3 == 0 else IRON("a"))
			if (r + c) % 2:  # wooden tag tied on
				B((0.04, 0.008, 0.055), (x - 0.03, -0.045, z - 0.06), PLANK(), bevel=0.003, rot=(0, -12, 0))
				kit.ring(0.008, 0.002, (x - 0.017, -0.047, z - 0.03), ROPE(), rot=(90, 0, 0), seg=6)
	# the missing key: a clean, unweathered key shape pressed into the board under the empty hook
	x, z = cols[empty[1]], 0.44
	def ghost():
		kit.cylinder(0.022, 0.006, (x, 0.0, z - 0.02), PALE(), rot=(90, 0, 0), verts=12, bevel=0)
		B((0.013, 0.006, 0.1), (x, 0.0, z - 0.09), PALE(), bevel=0)
		B((0.026, 0.006, 0.014), (x + 0.015, 0.0, z - 0.125), PALE(), bevel=0)
	carve(min(planks, key=lambda o: abs(o.location.x - x)), ghost)


def op_warning_plank():
	W, H, D = 1.1, 0.34, 0.06
	main = B((W, D, H), (0, D / 2, 0.06 + H / 2), PLANK(), bevel=0.012)
	zc = 0.06 + H / 2

	def cuts():
		# skull: head ring, eye pits, nose, teeth, jaw line
		kit.ring(0.075, 0.011, (0, 0, zc + 0.03), GROOVE(), rot=(90, 0, 0), seg=20)
		for s_ in (-1, 1):
			kit.cylinder(0.02, 0.03, (s_ * 0.03, 0, zc + 0.035), GROOVE(), rot=(90, 0, 0), verts=10, bevel=0)
			groove((s_ * 0.18, zc - 0.11), (s_ * 0.07, zc + 0.11), 0.0, w=0.016)  # crossed bones behind
			groove((s_ * 0.07, zc - 0.11), (s_ * 0.18, zc + 0.11), 0.0, w=0.016)
		B((0.016, 0.03, 0.016), (0, 0, zc), GROOVE(), bevel=0, rot=(0, 45, 0))
		groove((-0.045, zc - 0.03), (0.045, zc - 0.03), 0.0, w=0.01)
		for q in range(4):
			groove((-0.03 + q * 0.02, zc - 0.045), (-0.03 + q * 0.02, zc - 0.015), 0.0, w=0.006)
		# zigzag teeth along both ends
		for s_ in (-1, 1):
			for q in range(5):
				x0 = s_ * (0.27 + q * 0.05)
				groove((x0, zc - 0.07), (x0 + s_ * 0.025, zc + 0.07), 0.0, w=0.013)
				groove((x0 + s_ * 0.025, zc + 0.07), (x0 + s_ * 0.05, zc - 0.07), 0.0, w=0.013)
		for q in range(3):  # three slashes: "turn back"
			groove((0.12 + q * 0.035, zc - 0.13), (0.15 + q * 0.035, zc - 0.08), 0.0, w=0.01)
	carve(main, cuts)
	for (x, z) in ((-0.5, 0.11), (0.5, 0.11), (-0.5, 0.35), (0.5, 0.35), (-0.25, 0.37), (0.25, 0.08)):
		nail(x, 0.0, z)
	# iron straps at both ends
	for s_ in (-1, 1):
		B((0.04, 0.008, H + 0.02), (s_ * 0.44, -0.003, zc), IRON("dark"), bevel=0.002)
		for z in (zc - 0.12, zc + 0.12):
			kit.rivet((s_ * 0.44, -0.007, z), IRON("a"), r=0.009)
	# a small bell hanging under the right end on a bent iron hook
	tube([(0.44, -0.004, 0.08), (0.44, -0.03, 0.06), (0.44, -0.05, 0.035), (0.44, -0.055, 0.01)], 0.005, 0.005, IRON("dark"), seg=6)
	bell((0.44, -0.055, 0.0), s=1.0)


def sheet(x0, x1, prof, t, m):
	"""A bent paper sheet: its middle line `prof` [(y, z)] in the YZ plane, pushed from x0 to x1, t thick."""
	v = []
	for x in (x0, x1):
		for i, (y, z) in enumerate(prof):
			pa, pb = prof[max(i - 1, 0)], prof[min(i + 1, len(prof) - 1)]
			ty, tz = pb[0] - pa[0], pb[1] - pa[1]
			ln = math.hypot(ty, tz)
			ny, nz = -tz / ln, ty / ln
			v += [(x, y + ny * t / 2, z + nz * t / 2), (x, y - ny * t / 2, z - nz * t / 2)]
	n = len(prof)
	A = lambda side, i, o: side * 2 * n + 2 * i + o  # noqa: E731
	f = []
	for i in range(n - 1):
		for o in (0, 1):
			f.append((A(0, i, o), A(0, i + 1, o), A(1, i + 1, o), A(1, i, o)))
		for side in (0, 1):
			f.append((A(side, i, 0), A(side, i, 1), A(side, i + 1, 1), A(side, i + 1, 0)))
	for i in (0, n - 1):
		f.append((A(0, i, 0), A(1, i, 0), A(1, i, 1), A(0, i, 1)))
	return mesh(v, f, m)


def op_map_rack():
	W, H, D = 0.84, 0.62, 0.22
	board(W, H, d=0.03, battens=False)
	for z in (0.015, H / 2, H - 0.015):  # shelves of the cubbies
		B((W, D, 0.025), (0, -D / 2 + 0.003, z), PLANK(), bevel=0.005)
	for x in (-W / 2 + 0.02, -W / 6, W / 6, W / 2 - 0.02):
		B((0.025, D - 0.01, H - 0.03), (x, -D / 2 + 0.008, H / 2), DARKW(), bevel=0.005)
	for (x, z) in ((-W / 2, 0.0), (W / 2, 0.0), (-W / 2, H), (W / 2, H)):
		B((0.07, 0.012, 0.07), (x * 0.985, -D - 0.002, z + (0.02 if z == 0 else -0.02)), CU("dark"), bevel=0.003)
		kit.rivet((x * 0.985, -D - 0.008, z + (0.02 if z == 0 else -0.02)), CU("b"), r=0.008)
	cw = W / 3 - 0.03

	def scroll(x, z, r, ln, tie=True, caps=True):
		z -= 0.002  # pressed 2 mm into the shelf: a flat side of the 12-sided roll would shimmer on it
		kit.cylinder(r, ln, (x, -D / 2 - 0.005, z + r), PARCH(), rot=(90, 0, 0), verts=12, bevel=0.004)
		kit.ring(r * 0.5, 0.002, (x, -D / 2 - 0.005 - ln / 2, z + r), INK(), rot=(90, 0, 0), seg=10)
		if tie:
			kit.ring(r + 0.002, 0.004, (x, -D / 2 - 0.005, z + r), RED() if rng.random() < 0.4 else LEATHER("b"), rot=(90, 0, 0), seg=12)
		if caps:
			for s_ in (-1, 1):
				kit.cylinder(r * 0.45, 0.02, (x, -D / 2 - 0.005 + s_ * (ln / 2 + 0.008), z + r), DARKW(), rot=(90, 0, 0), verts=8, bevel=0.002)

	fl = (0.0275, H / 2 + 0.0125)
	for row, zf in enumerate(fl):
		for col in range(3):
			cx = -W / 3 + col * W / 3
			if (row, col) == (0, 2):
				continue  # the map that hangs out comes from here
			if (row + col) % 2 == 0:  # pyramid of three
				for k in range(2):
					scroll(cx - 0.034 + k * 0.068, zf, 0.033, 0.18 + J(0.01))
				scroll(cx, zf + 0.055, 0.03, 0.19)
			else:
				for k, r in enumerate((0.035, 0.028, 0.03)):
					scroll(cx - cw / 2 + 0.04 + k * 0.073, zf, r, 0.17 + J(0.015), tie=k != 1)
	# one map pulled out and hanging down the front, a red X on it
	cx = W / 3
	# one unbroken sheet (owner: the fallen map must join): flat on the shelf, bent over its front edge, hanging down
	# into the roller at the bottom
	t = 0.003
	ys = 0.0275 + t / 2 - 0.0005  # sheet middle on the shelf top
	yfr = -D + 0.003  # the shelf's front edge
	prof = [(-0.1, ys), (yfr + 0.004, ys), (yfr - 0.004, ys - 0.003), (yfr - 0.01, ys - 0.011), (yfr - 0.013, ys - 0.025),
		(yfr - 0.0145, -0.06), (yfr - 0.015, -0.16), (yfr - 0.015, -0.27)]  # hangs 1+ cm off the shelf front (no shimmer)
	sheet(cx - 0.1, cx + 0.09, prof, t, PARCH())
	kit.cylinder(0.022, 0.24, (cx, yfr - 0.0165 - 0.022 + 0.002, -0.27), PARCH(), rot=(0, 90, 0), verts=12, bevel=0.004)
	for s_ in (-1, 1):
		kit.cylinder(0.01, 0.025, (cx + s_ * 0.13, yfr - 0.0165 - 0.022 + 0.002, -0.27), DARKW(), rot=(0, 90, 0), verts=8, bevel=0.002)
	yf = yfr - 0.0148 - t / 2
	for a, b in (((-0.07, -0.05), (-0.02, -0.1)), ((-0.02, -0.1), (0.03, -0.08)), ((0.03, -0.08), (0.06, -0.15)), ((-0.06, -0.2), (0.0, -0.17))):
		ink((cx + a[0], a[1]), (cx + b[0], b[1]), yf, w=0.008)
	ink((cx + 0.04, -0.2), (cx + 0.08, -0.16), yf - 0.0033, w=0.012, m=RED())
	ink((cx + 0.04, -0.16), (cx + 0.08, -0.2), yf - 0.0066, w=0.012, m=RED())


def op_pipe_rack():
	W, H = 0.52, 0.46
	board(W, H, battens=False)
	B((W + 0.04, 0.03, 0.04), (0, -0.012, H - 0.03), DARKW(), bevel=0.006)
	for x in (-0.18, 0.0, 0.18):
		peg((x, -0.027, H - 0.03))
	low = shelf(W - 0.04, 0.07, depth=0.13)
	up = B((W - 0.08, 0.1, 0.03), (0, -0.046, 0.3), PLANK(), bevel=0.006)
	xs = (-0.18, -0.06, 0.06, 0.18)

	def holes():
		for x in xs:
			kit.cylinder(0.014, 0.06, (x, -0.06, 0.3), GROOVE(), verts=10, bevel=0)
	carve(up, holes)
	for x in (-0.2, 0.2):
		B((0.03, 0.08, 0.07), (x, -0.04, 0.255), DARKW(), bevel=0.005)
	for k, x in enumerate(xs):
		if k == 2:
			continue  # his favourite pipe is gone
		bz = low + 0.022
		kit.cylinder(0.022, 0.045, (x, -0.075, bz), DARKW(), verts=12, bevel=0.005)
		kit.cylinder(0.017, 0.006, (x, -0.075, bz + 0.021), CHAR(), verts=10, bevel=0)
		kit.ring(0.022, 0.003, (x, -0.075, bz + 0.012), CU("dark"), seg=12)
		tube([(x, -0.06, bz - 0.005), (x, -0.06, 0.18), (x + 0.004, -0.06, 0.33), (x + 0.004, -0.06, 0.36)], 0.006, 0.005, LOGEND(), seg=6)
	# tobacco pouch on a peg at the right top
	hpeg(0.2, 0.39, ln=0.06)
	sphere((0.2, -0.07, 0.31), 0.045, LEATHER("b"), scale=(1, 0.8, 1.05))
	kit.cone(0.026, 0.016, 0.035, (0.2, -0.07, 0.365), LEATHER("b"), verts=8, bevel=0.003)
	kit.ring(0.02, 0.005, (0.2, -0.07, 0.36), ROPE(), seg=8)
	tube([(0.2, -0.075, 0.38), (0.2, -0.09, 0.405), (0.2, -0.085, 0.41)], 0.004, 0.004, ROPE(), seg=5)
	# tinder box with flint on the ledge
	B((0.09, 0.06, 0.04), (-0.17, -0.07, low + 0.02), IRON("dark"), bevel=0.004)
	B((0.095, 0.065, 0.01), (-0.17, -0.07, low + 0.044), IRON("a"), bevel=0.002)
	lump((-0.08, -0.07, low + 0.014), (0.022, 0.018, 0.014), CHAR(), seed=3, rough=0.003)


# ================= Pell's living, tinkering, collecting =================
def op_still():
	# firebox of stones with an iron door
	B((0.56, 0.56, 0.36), (0, 0, 0.18), kit.mat("charcoal", 0.4), bevel=0)
	for r in range(2):
		z = 0.09 + r * 0.18
		for s_ in (-1, 1):
			for k in range(2):
				off = (k - 0.5) * 0.29 + (0.06 if r else 0)
				B((0.28, 0.1, 0.17), (off, s_ * 0.27, z), SSTONE(), bevel=0.025, rot=(J(2), J(2), J(3)))
				B((0.1, 0.28, 0.17), (s_ * 0.27, off * 0.95, z), SSTONE(), bevel=0.025, rot=(J(2), J(2), J(3)))
	B((0.24, 0.02, 0.17), (0, -0.33, 0.13), IRON("dark"), bevel=0.006)
	for z in (0.07, 0.19):
		B((0.06, 0.03, 0.025), (-0.12, -0.335, z), IRON("a"), bevel=0.003)
	kit.ring(0.02, 0.005, (0.08, -0.345, 0.13), IRON("a"), rot=(90, 0, 0), seg=10)
	for x in (-0.08, 0.0, 0.08):
		B((0.012, 0.024, 0.1), (x, -0.336, 0.13), IRON("a"), bevel=0.002)
	# copper pot with riveted bands and a domed lid
	kit.cylinder(0.27, 0.3, (0, 0, 0.5), CU("b"), verts=20, bevel=0.01)
	sphere((0, 0, 0.64), 0.272, CU("b"), scale=(1, 1, 0.55), seg=20, rings=10, cut=0.0)
	for z in (0.38, 0.56):
		kit.ring(0.273, 0.009, (0, 0, z), CU("dark"), seg=24)
		for k in range(12):
			a = 2 * math.pi * k / 12
			kit.rivet((math.cos(a) * 0.282, math.sin(a) * 0.282, z), CU("dark"), r=0.007)
	kit.cylinder(0.07, 0.15, (0, 0, 0.84), CU("b"), verts=14, bevel=0.006)
	kit.ring(0.072, 0.01, (0, 0, 0.86), CU("dark"), seg=14)
	# swan neck over to the worm barrel
	bx = 0.68
	tube([(0, 0, 0.88), (0.05, 0, 0.98), (0.2, 0, 1.03), (0.4, 0, 0.98), (0.56, 0, 0.88), (bx - 0.04, 0, 0.78), (bx, 0, 0.7)], 0.026, 0.02, CU("b"), seg=9)
	kit.ring(0.03, 0.006, (0.2, 0, 1.03), CU("dark"), rot=(0, 80, 0), seg=10)
	barrel((bx, 0, 0), 0.22, 0.72)
	group(lambda: helix(0.12, 0.012, 1.5, 0.035, CU("b"), n_per=14), (bx, 0, 0.678), (0, 0, 0))
	# outlet tap low on the barrel front, a copper cup under it
	tube([(bx, -0.2, 0.2), (bx, -0.27, 0.2), (bx, -0.3, 0.17)], 0.014, 0.012, CU("b"), seg=8)
	B((0.012, 0.04, 0.012), (bx, -0.255, 0.225), CU("dark"), bevel=0.002)
	kit.cylinder(0.05, 0.1, (bx, -0.31, 0.05), CU("b"), verts=12, bevel=0.006)
	kit.ring(0.05, 0.006, (bx, -0.31, 0.1), CU("dark"), seg=12)
	kit.ring(0.025, 0.006, (bx + 0.055, -0.31, 0.055), CU("dark"), rot=(90, 0, 0), seg=10)
	# a ladle hooked on the pot rim and split firewood beside the firebox
	tube([(-0.2, -0.18, 0.66), (-0.23, -0.2, 0.68), (-0.27, -0.22, 0.6), (-0.29, -0.23, 0.42)], 0.008, 0.008, CU("dark"), seg=6)
	sphere((-0.29, -0.235, 0.4), 0.035, CU("b"), scale=(1, 1, 0.6), cut=-0.01)
	for k in range(3):
		B((0.11, 0.42, 0.09), (-0.5 + (k % 2) * 0.12, 0.0, 0.045 + (k // 2) * 0.09), LOGEND() if k == 2 else BARK(), bevel=0.02, rot=(0, 0, J(4)))


def op_tinker_bench():
	W, D, H = 1.1, 0.6, 0.78
	for x in (-W / 2 + 0.07, W / 2 - 0.07):
		for y in (-D / 2 + 0.07, D / 2 - 0.07):
			rlog((x, y, 0), (x + J(0.01), y, H - 0.04), 0.045, seg=7, rings=2, bend=0.04)
		rlog((x, -D / 2 + 0.07, 0.2), (x, D / 2 - 0.07, 0.2), 0.03, seg=6, rings=2)
	B((W - 0.14, D - 0.1, 0.03), (0, 0, 0.23), PLANK(), bevel=0.006)  # low shelf
	for k in range(4):
		B((W, D / 4 - 0.008, 0.05), (0, -D / 2 + D / 4 * (k + 0.5), H - 0.025), PLANK(), bevel=0.008)
	# iron vise on the left front, clamping a gear
	vx = -0.35
	B((0.14, 0.12, 0.08), (vx, -0.22, H + 0.035), IRON("dark"), bevel=0.008)
	for y in (-0.31, -0.25):
		B((0.16, 0.025, 0.1), (vx, y, H + 0.12), IRON("a"), bevel=0.004)
	kit.cylinder(0.012, 0.22, (vx, -0.34, H + 0.1), IRON("a"), rot=(90, 0, 0), verts=8, bevel=0)
	kit.cylinder(0.008, 0.18, (vx, -0.44, H + 0.1), IRON("dark"), rot=(0, 90, 0), verts=6, bevel=0)
	for s_ in (-1, 1):
		sphere((vx + s_ * 0.09, -0.44, H + 0.1), 0.015, IRON("dark"))
	gear((vx, -0.28, H + 0.2), 0.07, 0.016, CU("b"), rot=(90, 0, 0), n=10)
	# little gear train on a frame in the middle
	fx = 0.02
	for y in (0.02, 0.12):
		B((0.3, 0.02, 0.2), (fx, y, H + 0.1), PLANK(), bevel=0.004)
	B((0.32, 0.14, 0.02), (fx, 0.07, H + 0.01), DARKW(), bevel=0.004)
	for (x, z, r) in ((-0.07, 0.11, 0.055), (0.06, 0.13, 0.04)):
		kit.cylinder(0.007, 0.14, (fx + x, 0.07, H + z), IRON("dark"), rot=(90, 0, 0), verts=6, bevel=0)
		gear((fx + x, 0.0, H + z), r, 0.012, IRON("a") if r > 0.05 else CU("b"), rot=(90, 0, 0), n=10 if r > 0.05 else 7)
	# loose gears stacked, springs lying
	for k, r in enumerate((0.05, 0.04, 0.028)):
		gear((0.3 + k * 0.006, -0.12, H + 0.008 + k * 0.016), r, 0.014, CU("b") if k % 2 else IRON("a"), n=8 + k)
	for k in range(2):
		group(lambda: helix(0.014, 0.003, 7, 0.1, IRON("a")), (-0.12 + k * 0.05, -0.18, H + 0.017), (0, 90, 20 * k))
	# magnifier on a jointed arm, back right
	mx = 0.42
	kit.cylinder(0.06, 0.02, (mx, 0.2, H + 0.01), IRON("dark"), verts=12, bevel=0.004)
	tube([(mx, 0.2, H + 0.01), (mx, 0.2, H + 0.25)], 0.009, 0.009, CU("dark"), seg=6)
	sphere((mx, 0.2, H + 0.25), 0.016, CU("b"))
	tube([(mx, 0.2, H + 0.25), (mx - 0.06, 0.08, H + 0.22)], 0.007, 0.007, CU("dark"), seg=6)
	kit.ring(0.045, 0.007, (mx - 0.08, 0.05, H + 0.2), CU("b"), rot=(60, 0, 0), seg=16)
	kit.cylinder(0.042, 0.004, (mx - 0.08, 0.05, H + 0.2), glass(), rot=(60, 0, 0), verts=16, bevel=0)
	# drawer box at the back left
	B((0.3, 0.16, 0.18), (-0.3, 0.19, H + 0.09), DARKW(), bevel=0.008)
	for r in range(2):
		for c in range(2):
			B((0.125, 0.012, 0.07), (-0.37 + c * 0.14, 0.106, H + 0.05 + r * 0.085), PLANK(), bevel=0.003)
			kit.rivet((-0.37 + c * 0.14, 0.098, H + 0.05 + r * 0.085), CU("b"), r=0.008)
	# hammer and tweezers lying
	B((0.025, 0.2, 0.02), (0.17, -0.2, H + 0.01), PLANK(), bevel=0.004, rot=(0, 0, 70))
	B((0.07, 0.03, 0.03), (0.08, -0.17, H + 0.015), IRON("dark"), bevel=0.004, rot=(0, 0, 70))
	for s_ in (-1, 1):
		B((0.11, 0.006, 0.004), (0.12, 0.2 + s_ * 0.006, H + 0.002), IRON("a"), bevel=0, rot=(0, 0, s_ * 3))
	# a box of scrap on the low shelf
	B((0.3, 0.25, 0.12), (0.25, 0.0, 0.305), PLANK(), bevel=0.008)
	for k in range(3):
		gear((0.18 + k * 0.07, 0.0, 0.375), 0.025, 0.01, IRON("dark"), rot=(J(15), J(15), 0), n=6)


def op_trapmaker_table():
	W, D, H = 1.3, 0.72, 0.74
	for x in (-W / 2 + 0.09, W / 2 - 0.09):
		for y in (-D / 2 + 0.09, D / 2 - 0.09):
			rlog((x, y, 0), (x, y, H - 0.06), 0.06, seg=8, rings=2, bend=0.03)
		rlog((x, -D / 2 + 0.09, 0.22), (x, D / 2 - 0.09, 0.22), 0.035, seg=6, rings=2)
	rlog((-W / 2 + 0.09, 0, 0.22), (W / 2 - 0.09, 0, 0.22), 0.035, seg=6, rings=3)
	for k in range(3):
		B((W, D / 3 - 0.008, 0.07), (0, -D / 2 + D / 3 * (k + 0.5), H - 0.035), PLANK(), bevel=0.01)
	for x in (-W / 2 + 0.09, W / 2 - 0.09):
		for y in (-0.24, 0.0, 0.24):
			peg((x, y, H), "z")
	# bear trap being put together: base bar, pan, one jaw in place (open, flat), springs
	tx, ty = -0.2, -0.05
	B((0.5, 0.05, 0.02), (tx, ty, H + 0.01), IRON("dark"), bevel=0.004)
	kit.cylinder(0.05, 0.012, (tx, ty, H + 0.022), IRON("a"), verts=12, bevel=0.002)
	group(lambda: jaw(0.15, "up"), (tx, ty - 0.004, H + 0.014), (90, 0, 0))
	for s_ in (-1, 1):
		B((0.2, 0.04, 0.012), (tx + s_ * 0.3, ty, H + 0.018), IRON("a"), bevel=0.003, rot=(0, s_ * 6, 0))
		kit.ring(0.03, 0.007, (tx + s_ * 0.4, ty, H + 0.03), IRON("a"), rot=(90, 0, 0), seg=10)
		kit.ring(0.018, 0.005, (tx + s_ * 0.155, ty, H + 0.016), IRON("dark"), rot=(0, 90, 0), seg=8)
	# the second jaw lying beside it, turned
	group(lambda: jaw(0.15, "up"), (tx + 0.05, ty + 0.17, H + 0.014), (90, 0, 160))
	# bundle of fire-hardened stakes at the back, roped
	for k in range(5):
		y, z = 0.24 + (k % 3) * 0.04 - 0.04, H + 0.03 + (k // 3) * 0.045
		rlog((-0.55, y, z), (0.15, y + J(0.01), z), 0.022, seg=6, rings=2, bend=0.01)
		kit.cone(0.022, 0.0, 0.09, (0.195, y, z), CHAR(), rot=(0, 90, 0), verts=6, bevel=0)
	for x in (-0.4, -0.05):
		kit.ring(0.07, 0.01, (x, 0.24, H + 0.06), ROPE(), rot=(0, 90, 0), seg=14)
	# hammer, whetstone, sketch, coil of wire
	B((0.03, 0.26, 0.026), (0.36, -0.12, H + 0.013), PLANK(), bevel=0.005, rot=(0, 0, 20))
	B((0.1, 0.045, 0.045), (0.31, -0.24, H + 0.0225), IRON("dark"), bevel=0.006, rot=(0, 0, 20))
	B((0.16, 0.05, 0.035), (0.48, 0.18, H + 0.0175), SSTONE(), bevel=0.01, rot=(0, 0, -10))
	B((0.26, 0.2, 0.003), (0.42, -0.02, H + 0.0015), PARCH(), bevel=0, rot=(0, 0, 8))
	for q in range(10):
		a0, a1 = 2 * math.pi * q / 10, 2 * math.pi * (q + 1) / 10
		x0, y0 = 0.42 + math.cos(a0) * 0.06, -0.02 + math.sin(a0) * 0.06
		x1, y1 = 0.42 + math.cos(a1) * 0.06, -0.02 + math.sin(a1) * 0.06
		B((math.hypot(x1 - x0, y1 - y0) + 0.004, 0.006, 0.003), ((x0 + x1) / 2, (y0 + y1) / 2, H + 0.003), INK(), bevel=0,
			rot=(0, 0, math.degrees(math.atan2(y1 - y0, x1 - x0))))
	B((0.16, 0.005, 0.003), (0.42, -0.02, H + 0.0035), INK(), bevel=0, rot=(0, 0, 8))
	for k in range(4):
		kit.ring(0.06 - k * 0.003, 0.0045, (0.1 + k * 0.004, 0.12, H + 0.005 + k * 0.008), IRON("a"), seg=16)


def op_cot():
	W, L = 0.85, 1.85
	xs, ys = (-W / 2 + 0.06, W / 2 - 0.06), (-L / 2 + 0.06, L / 2 - 0.06)
	for x in xs:
		for y in ys:
			rlog((x, y, 0), (x, y, 0.85 if y > 0 else 0.5), 0.05, seg=8, rings=3, bend=0.03)
		rlog((x, -L / 2 + 0.02, 0.36), (x, L / 2 - 0.02, 0.36), 0.036, seg=8, rings=4, bend=0.02)
	for y in ys:
		rlog((-W / 2 + 0.02, y, 0.32), (W / 2 - 0.02, y, 0.32), 0.032, seg=7, rings=2)
	# rope webbing: long ropes on top, cross ropes woven under them
	for k in range(5):
		x = -0.26 + k * 0.13
		log((x, -L / 2 + 0.06, 0.375), (x, L / 2 - 0.06, 0.375), 0.009, ROPE(), seg=5, rings=6, ends=False, bend=0.15)
	for k in range(11):
		y = -0.78 + k * 0.156
		log((-W / 2 + 0.06, y, 0.358), (W / 2 - 0.06, y, 0.358), 0.008, ROPE(), seg=5, rings=3, ends=False, bend=0.1)
		for x in xs:
			kit.ring(0.05, 0.007, (x, y, 0.36), ROPE(), rot=(0, 90, 0), seg=10)
	# headboard of split planks with a carved crest groove, footboard rail
	hb = []
	for k in range(4):
		hb.append(B((0.17, 0.035, 0.38), (-0.27 + k * 0.18, L / 2 - 0.06, 0.6 + J(0.01)), PLANK(), bevel=0.008))
	rlog((-W / 2 + 0.02, L / 2 - 0.06, 0.8), (W / 2 - 0.02, L / 2 - 0.06, 0.8), 0.04, seg=7, rings=2)
	carve(hb[1], lambda: [groove((-0.13, 0.62), (-0.04, 0.7), L / 2 - 0.0775, w=0.012), groove((-0.13, 0.7), (-0.04, 0.62), L / 2 - 0.0775, w=0.012)])
	for x in xs:
		peg((x, L / 2 - 0.105, 0.8))
	rlog((-W / 2 + 0.02, -L / 2 + 0.06, 0.47), (W / 2 - 0.02, -L / 2 + 0.06, 0.47), 0.035, seg=7, rings=2)
	# his boots under the side, a candle stump bedside
	boot((-0.12, -0.4, 0), rotz=-80)
	settle(boot((0.02, -0.55, 0), lying=True, rotz=-150))
	sx, sy = W / 2 + 0.11, L / 2 - 0.25
	stump(0.15, 0.45, (sx, sy))
	kit.cylinder(0.06, 0.012, (sx, sy, 0.462), CU("b"), verts=12, bevel=0.003)
	kit.ring(0.02, 0.004, (sx + 0.065, sy, 0.465), CU("dark"), rot=(90, 0, 0), seg=8)
	kit.cylinder(0.022, 0.04, (sx, sy, 0.485), WAX(), verts=8, bevel=0.004)
	B((0.004, 0.004, 0.012), (sx, sy, 0.508), CHAR(), bevel=0)
	kit.cylinder(0.04, 0.08, (sx - 0.06, sy + 0.06, 0.495), IRON("a"), verts=10, bevel=0.004)


def op_root_armchair():
	S = 0.44
	for k in range(3):
		B((0.58, 0.16, 0.04), (0, -0.17 + k * 0.17, S), PLANK(), bevel=0.008)
	for s_ in (-1, 1):
		x = s_ * 0.27
		tube([(x * 1.15, -0.26, 0), (x * 1.05, -0.24, 0.2), (x, -0.22, S - 0.01), (x, -0.22, 0.6), (x * 1.02, -0.2, 0.64)], 0.045, 0.035, BARK())  # front leg + arm post
		tube([(x * 1.15, 0.28, 0), (x * 1.05, 0.25, 0.25), (x, 0.24, S), (x * 1.0, 0.28, 0.8), (x * 0.95, 0.34, 1.02)], 0.05, 0.035, BARK())  # back leg + post
		tube([(x * 1.02, -0.27, 0.62), (x * 1.06, -0.1, 0.665), (x * 1.04, 0.1, 0.66), (x, 0.27, 0.66)], 0.035, 0.03, BARK())  # arm rest
		tube([(x, -0.2, 0.15), (x * 1.0, 0.0, 0.13), (x, 0.24, 0.16)], 0.025, 0.025, BARK())  # side stretcher
		B((0.05, 0.42, 0.04), (x, 0.01, S - 0.04), DARKW(), bevel=0.006)  # seat rail
	for k, z in enumerate((0.58, 0.72, 0.87)):  # woven back of bent roots
		y = 0.28 + (z - 0.44) * 0.17
		tube([(-0.28, y, z), (-0.12, y + 0.04, z + 0.03), (0.0, y + 0.05, z + 0.05 * (k % 2)), (0.12, y + 0.04, z + 0.03), (0.28, y, z)], 0.022, 0.022, BARK())
	for s_ in (-1, 1):
		tube([(s_ * 0.27, 0.26, 0.5), (s_ * 0.12, 0.33, 0.75), (s_ * -0.05, 0.36, 0.95)], 0.018, 0.012, BARK())
	tube([(-0.27, 0.2, S + 0.02), (0.27, 0.2, S + 0.02)], 0.02, 0.02, BARK())
	# spectacles on the right arm, a book face down by the left foot, a stick leaning on it
	spectacles((0.28, -0.02, 0.69), rotz=88)
	def book():
		for s_ in (-1, 1):
			B((0.012, 0.22, 0.16), (s_ * 0.06, 0, 0.065), LEATHER("b"), bevel=0.004, rot=(0, -s_ * 55, 0))
			B((0.008, 0.2, 0.14), (s_ * 0.05, 0, 0.058), PARCH(), bevel=0.002, rot=(0, -s_ * 55, 0))
		B((0.03, 0.22, 0.02), (0, 0, 0.122), LEATHER("dark"), bevel=0.006)
	settle(group(book, (-0.5, -0.15, 0), (0, 0, 20)))
	rlog((0.4, -0.35, 0.0), (0.315, -0.22, 0.66), 0.018, seg=6, rings=3, bend=0.05, ends=False)
	sphere((0.312, -0.218, 0.67), 0.026, LOGEND())


def op_tumbler():
	L, R, AZ = 0.56, 0.21, 0.58
	for s_ in (-1, 1):
		x = s_ * 0.38
		for y in (-0.3, 0.3):
			rlog((x, y, 0), (x, 0, AZ + 0.06), 0.04, seg=7, rings=2, bend=0.02)
		rlog((x, -0.24, 0.18), (x, 0.24, 0.18), 0.03, seg=6, rings=2)
		B((0.1, 0.12, 0.06), (x, 0, AZ + 0.05), DARKW(), bevel=0.008)
		kit.ring(0.03, 0.008, (x, 0, AZ), IRON("dark"), rot=(0, 90, 0), seg=12)
	rlog((-0.38, 0.27, 0.12), (0.38, 0.27, 0.12), 0.03, seg=6, rings=3)
	kit.cylinder(0.016, 0.93, (0, 0, AZ), IRON("dark"), rot=(0, 90, 0), verts=8, bevel=0)
	# barrel lying along x
	def bar():
		n = 12
		for k in range(n):
			a = 2 * math.pi * (k + 0.5) / n
			B((L, 2 * math.pi * R / n * 1.02, 0.03), (0, math.cos(a) * (R - 0.015), math.sin(a) * (R - 0.015)), PLANK(), bevel=0.005, rot=(math.degrees(a) - 90, 0, 0))
		for x in (-L / 2 + 0.06, 0, L / 2 - 0.06):
			kit.ring(R + 0.004, 0.011, (x, 0, 0), IRON("dark"), rot=(0, 90, 0), seg=20)
		for s_ in (-1, 1):
			kit.cylinder(R - 0.01, 0.03, (s_ * (L / 2 - 0.01), 0, 0), LOGEND(), rot=(0, 90, 0), verts=n, bevel=0.004)
			for d in (0, 90):
				B((0.012, 0.03, R * 1.7), (s_ * (L / 2 + 0.008), 0, 0), IRON("a"), bevel=0.002, rot=(d, 0, 0))
		# hatch with hinges and latch on top
		B((0.2, 0.14, 0.02), (0.08, 0, R + 0.005), DARKW(), bevel=0.004)
		for x in (0.02, 0.14):
			B((0.03, 0.17, 0.008), (x, 0, R + 0.016), IRON("a"), bevel=0.002)
		kit.ring(0.015, 0.004, (0.08, -0.075, R + 0.012), IRON("dark"), rot=(0, 90, 0), seg=8)
	group(bar, (0, 0, AZ), (12, 0, 0))
	# crank
	B((0.02, 0.025, 0.2), (0.46, 0, AZ - 0.08), IRON("dark"), bevel=0.003)
	kit.cylinder(0.014, 0.12, (0.52, 0, AZ - 0.17), IRON("dark"), rot=(0, 90, 0), verts=6, bevel=0)
	kit.cylinder(0.022, 0.09, (0.55, 0, AZ - 0.17), PLANK(), rot=(0, 90, 0), verts=8, bevel=0.004)
	# tray of polished pebbles sorted by size
	B((0.5, 0.26, 0.02), (0, -0.05, 0.01), DARKW(), bevel=0.004)
	for s_ in (-1, 1):
		B((0.5, 0.02, 0.05), (0, -0.05 + s_ * 0.12, 0.025), PLANK(), bevel=0.004)
		B((0.02, 0.26, 0.05), (s_ * 0.24, -0.05, 0.025), PLANK(), bevel=0.004)
	for x in (-0.08, 0.08):
		B((0.015, 0.22, 0.04), (x, -0.05, 0.022), PLANK(), bevel=0.003)
	cols = (C((0.42, 0.28, 0.18), 0.15), C((0.3, 0.22, 0.17), 0.15), C((0.5, 0.4, 0.28), 0.15))
	for c in range(3):
		r = (0.03, 0.022, 0.015)[c]
		for k in range(4 + c):
			sphere((-0.16 + c * 0.16 + (k % 2) * r * 2.1 - r, -0.12 + (k // 2) * r * 2.3, 0.02 + r * 0.55), r, cols[(k + c) % 3], scale=(1.15, 1, 0.65), seg=10, rings=6)


def op_sieve_stack():
	def sieve(R=0.22, h=0.07):
		n = 14
		for k in range(n):
			a = 2 * math.pi * (k + 0.5) / n
			B((2 * math.pi * R / n * 1.04, 0.018, h), (math.cos(a) * R, math.sin(a) * R, h / 2), PLANK(), bevel=0.003, rot=(0, 0, math.degrees(a) + 90))
		kit.ring(R + 0.012, 0.006, (0, 0, h - 0.015), IRON("dark"), seg=24)
		kit.ring(R + 0.012, 0.006, (0, 0, 0.015), IRON("dark"), seg=24)
		for q in range(-6, 7):
			c = q * 0.032
			ln = 2 * math.sqrt(max(0.0, (R - 0.005) ** 2 - c * c))
			B((ln, 0.004, 0.004), (0, c, 0.016), IRON("a"), bevel=0)
			B((0.004, ln, 0.004), (c, 0, 0.02), IRON("a"), bevel=0)
	group(sieve, (-0.15, 0.05, 0))
	group(lambda: sieve(0.2, 0.065), (-0.15, 0.05, 0.066))
	group(sieve, (-0.17, 0.06, 0.128), (0, 0, 20))
	# a few rocks caught in the top sieve
	for k in range(5):
		lump((-0.2 + (k % 3) * 0.06, 0.02 + (k // 3) * 0.08, 0.172), (0.03, 0.025, 0.02), ROCK(), seed=k, rough=0.005)
	# sorting tray with three bins: coarse, medium, fine
	tx = 0.32
	B((0.48, 0.3, 0.02), (tx, -0.05, 0.01), DARKW(), bevel=0.004)
	for s_ in (-1, 1):
		B((0.48, 0.02, 0.08), (tx, -0.05 + s_ * 0.14, 0.04), PLANK(), bevel=0.004)
		B((0.02, 0.3, 0.08), (tx + s_ * 0.23, -0.05, 0.04), PLANK(), bevel=0.004)
	for x in (-0.075, 0.075):
		B((0.015, 0.26, 0.07), (tx + x, -0.05, 0.035), PLANK(), bevel=0.003)
	import random
	r = random.Random(4)
	for c, (sz, n) in enumerate(((0.04, 6), (0.026, 10), (0.016, 16))):
		bx = tx - 0.15 + c * 0.15
		for k in range(n):
			m = CU("b") if k % 5 == 0 else ROCK()
			lump((bx + r.uniform(-0.04, 0.04), -0.05 + r.uniform(-0.09, 0.09), 0.02 + sz * 0.4 + (k % 3) * 0.006), (sz, sz * 0.8, sz * 0.6), m, seed=k + c * 20, rough=0.004)
		B((0.06, 0.004, 0.025), (bx, -0.192, 0.05), PARCH(), bevel=0.001)
	# copper scoop resting across the tray
	sphere((tx + 0.18, 0.04, 0.09), 0.05, CU("b"), scale=(1.3, 1, 0.6), cut=-0.02)
	tube([(tx + 0.12, 0.04, 0.085), (tx + 0.02, 0.06, 0.09), (tx - 0.06, 0.07, 0.092)], 0.01, 0.01, DARKW(), seg=6)


def op_hearth_tripod():
	import random
	r = random.Random(9)
	for k in range(10):
		a = 2 * math.pi * k / 10
		hh = 0.12 + r.uniform(0, 0.05)
		B((0.2, 0.15, hh), (math.cos(a) * 0.36, math.sin(a) * 0.36, hh / 2 + 0.002), SSTONE(), bevel=0.03,
			rot=(r.uniform(-2, 2), r.uniform(-2, 2), math.degrees(a) + 90 + r.uniform(-8, 8)))
	B((0.6, 0.6, 0.016), (0, 0, 0.012), CHAR(), bevel=0.0)
	for k in range(3):  # charred logs leaning into the middle
		a = 2 * math.pi * k / 3 + 0.4
		log((math.cos(a) * 0.27, math.sin(a) * 0.27, 0.06), (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.14), 0.045, CHAR(), seg=7, rings=2, ends=False, bend=0.04)
	coal_bits(0, 0, 0.02, 0.36, 0.36, 9, 5)
	# iron tripod, chain and kettle
	top = (0, 0, 1.05)
	for k in range(3):
		a = 2 * math.pi * k / 3 + 1.0
		tube([(math.cos(a) * 0.55, math.sin(a) * 0.55, 0.012), (math.cos(a) * 0.03, math.sin(a) * 0.03, 1.04)], 0.016, 0.014, IRON("dark"), seg=6)
		kit.cylinder(0.03, 0.012, (math.cos(a) * 0.55, math.sin(a) * 0.55, 0.006), IRON("dark"), verts=8, bevel=0.002)
	kit.ring(0.04, 0.012, top, IRON("a"), seg=12)
	chain((0, 0, 1.03), (0, 0, 0.6), R=0.02, wire=0.006)
	kz = 0.3
	kit.cylinder(0.15, 0.17, (0, 0, kz + 0.085), IRON("dark"), verts=16, bevel=0.012)
	sphere((0, 0, kz + 0.01), 0.138, IRON("dark"), scale=(1, 1, 0.45), seg=16, rings=8)
	kit.ring(0.152, 0.008, (0, 0, kz + 0.165), IRON("a"), seg=18)
	kit.cylinder(0.145, 0.02, (0, 0, kz + 0.18), IRON("a"), verts=16, bevel=0.004)
	sphere((0, 0, kz + 0.2), 0.02, IRON("dark"))
	tube([(0.155 * math.cos(math.radians(a)), 0, kz + 0.15 + 0.43 * math.sin(math.radians(a)) * 0.33) for a in range(0, 181, 15)], 0.006, 0.006, IRON("a"), seg=6)
	for s_ in (-1, 1):
		kit.ring(0.014, 0.005, (s_ * 0.152, 0, kz + 0.15), IRON("dark"), rot=(90, 0, 0), seg=8)
	# split firewood stacked outside the ring
	for k in range(3):
		B((0.36, 0.1, 0.085), (0.0, -0.6 + ((-0.056 + (k % 2) * 0.112) if k < 2 else 0.0), 0.0425 + (k // 2) * 0.082), BARK() if k != 1 else LOGEND(), bevel=0.02, rot=(0, 0, 8 + J(4)))


def op_signpost():
	import random
	r = random.Random(2)
	# cairn of angular stones round the foot, settling in tiers
	for tier, (rad, n, zz, s) in enumerate(((0.26, 9, 0.07, 0.17), (0.17, 6, 0.19, 0.13), (0.08, 4, 0.29, 0.1))):
		for k in range(n):
			a = 2 * math.pi * (k + tier * 0.5) / n
			B((s * r.uniform(0.9, 1.3), s * r.uniform(0.8, 1.1), s * r.uniform(0.75, 0.95)), (math.cos(a) * rad, math.sin(a) * rad, zz), SSTONE(), bevel=0.025,
				rot=(r.uniform(-12, 12), r.uniform(-12, 12), r.uniform(0, 90)))
	rlog((0, 0, 0.0), (0.01, 0.0, 1.55), 0.07, seg=9, rings=4, bend=0.03)
	# three boards pointing three ways, each with a carved warning
	marks = ("skull", "x", "pick")
	for k, (z, yaw) in enumerate(((1.35, 15), (1.12, 160), (0.88, -35))):
		def bd(k=k):
			b = B((0.56, 0.035, 0.13), (0.3, -0.06, 0), PLANK(), bevel=0.008)
			slab_xz([(0.575, -0.065), (0.665, 0.0), (0.575, 0.065)], -0.0755, -0.0445, PLANK())
			yf = -0.0775
			if marks[k] == "skull":
				cutters = lambda: [kit.ring(0.04, 0.008, (0.32, yf, 0.005), GROOVE(), rot=(90, 0, 0), seg=16),
					kit.cylinder(0.011, 0.02, (0.305, yf, 0.012), GROOVE(), rot=(90, 0, 0), verts=8, bevel=0),
					kit.cylinder(0.011, 0.02, (0.335, yf, 0.012), GROOVE(), rot=(90, 0, 0), verts=8, bevel=0),
					groove((0.3, -0.018), (0.34, -0.018), yf, w=0.008, depth=0.02),
					groove((0.14, -0.04), (0.2, 0.04), yf, w=0.01, depth=0.02), groove((0.44, -0.04), (0.5, 0.04), yf, w=0.01, depth=0.02)]
			elif marks[k] == "x":
				cutters = lambda: [groove((0.22, -0.04), (0.32, 0.04), yf, w=0.016, depth=0.02), groove((0.22, 0.04), (0.32, -0.04), yf, w=0.016, depth=0.02),
					groove((0.36, -0.04), (0.46, 0.04), yf, w=0.016, depth=0.02), groove((0.36, 0.04), (0.46, -0.04), yf, w=0.016, depth=0.02)]
			else:
				cutters = lambda: [groove((0.2, -0.04), (0.36, 0.03), yf, w=0.012, depth=0.02), groove((0.28, 0.03), (0.33, 0.045), yf, w=0.012, depth=0.02),
					groove((0.33, 0.045), (0.4, 0.03), yf, w=0.012, depth=0.02), groove((0.4, 0.03), (0.44, 0.0), yf, w=0.012, depth=0.02)]
			carve(b, cutters)
			nail(0.06, -0.077, 0.0)
		group(bd, (0, 0, z), (0, 0, yaw))
	# rat skull nailed on top
	sphere((0.0, -0.02, 1.6), 0.034, BONE(), scale=(1, 1.25, 0.85))
	kit.cone(0.026, 0.011, 0.055, (0.0, -0.07, 1.592), BONE(), rot=(90, 0, 0), verts=8, bevel=0.003)
	for s_ in (-1, 1):
		sphere((s_ * 0.019, -0.043, 1.608), 0.011, GROOVE(), seg=8, rings=5)
	kit.cylinder(0.012, 0.01, (0.0, 0.0, 1.63), IRON("dark"), verts=8, bevel=0.002)


def op_spike_crate():
	W, D, H = 0.62, 0.46, 0.4
	B((W - 0.04, D - 0.04, 0.03), (0, 0, 0.02), DARKW(), bevel=0.006)
	for s_ in (-1, 1):
		for k in range(2):
			zz = H * (0.27 + 0.48 * k)
			B((W, 0.025, H * 0.42), (0, s_ * (D / 2 - 0.0125), zz), PLANK(), bevel=0.006)
			B((0.025, D - 0.05, H * 0.42), (s_ * (W / 2 - 0.0125), 0, zz), PLANK(), bevel=0.006)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.05, 0.05, H), (cx * (W / 2 - 0.02), cy * (D / 2 - 0.02), H / 2), DARKW(), bevel=0.006)
			for z in (0.08, H - 0.08):
				kit.rivet((cx * (W / 2 + 0.006), cy * (D / 2 - 0.05), z), IRON("dark"), r=0.009)
	import random
	r = random.Random(6)
	for k in range(13):
		bx, by = -0.2 + (k % 5) * 0.1, -0.13 + (k // 5) * 0.13
		tx, ty = bx * 1.25 + r.uniform(-0.03, 0.03), by * 1.25 + r.uniform(-0.03, 0.03)
		ln = r.uniform(0.62, 0.8)
		rlog((bx, by, 0.03), (tx, ty, ln), 0.024, seg=6, rings=3, bend=0.02, ends=False)
		d = Vector((tx - bx, ty - by, ln - 0.03)).normalized()
		kit.cone(0.024, 0.0, 0.1, tuple(Vector((tx, ty, ln)) + d * 0.045), CHAR(), rot=tuple(math.degrees(v) for v in Vector((0, 0, 1)).rotation_difference(d).to_euler()), verts=6, bevel=0)
	# one stake dropped on the floor in front
	rlog((-0.3, -0.38, 0.024), (0.35, -0.42, 0.024), 0.024, seg=6, rings=3, bend=0.01, ends=False)
	kit.cone(0.024, 0.0, 0.1, (0.4, -0.423, 0.024), CHAR(), rot=(0, 90, -4), verts=6, bevel=0)
	# chopping stump with the hatchet still in it
	stump(0.17, 0.38, (0.62, 0.05))
	B((0.1, 0.012, 0.07), (0.62, 0.05, 0.4), IRON("dark"), bevel=0.003, rot=(0, -20, 0))
	rlog((0.65, 0.05, 0.43), (0.8, 0.05, 0.62), 0.016, seg=6, rings=2, ends=False, bend=0.02)
	for k in range(3):
		kit.ring(0.02, 0.0035, (0.5 + k * 0.08, -0.18 + J(0.03), 0.0225), kit.tex_mat("shacklogend", "v1"), rot=(75, 0, r.uniform(0, 180)), seg=10)


def op_wire_spools():
	# sled stand: two skids, cross boards, two posts, axle
	for y in (-0.2, 0.2):
		B((1.0, 0.08, 0.07), (0, y, 0.035), DARKW(), bevel=0.01)
	for x in (-0.38, 0.0, 0.38):
		B((0.12, 0.5, 0.035), (x, 0, 0.085), PLANK(), bevel=0.006)
	for s_ in (-1, 1):
		B((0.08, 0.1, 0.55), (s_ * 0.44, 0, 0.37), PLANK(), bevel=0.01)
		for y in (-1, 1):
			rlog((s_ * 0.44, y * 0.2, 0.1), (s_ * 0.44, y * 0.04, 0.4), 0.025, seg=6, rings=2, ends=False)
		peg((s_ * 0.44, -0.05, 0.6))
	kit.cylinder(0.015, 0.98, (0, 0, 0.55), IRON("dark"), rot=(0, 90, 0), verts=8, bevel=0)
	for k, x in enumerate((-0.25, 0.0, 0.25)):
		kit.cylinder(0.05, 0.18, (x, 0, 0.55), LOGEND(), rot=(0, 90, 0), verts=12, bevel=0.004)
		for s_ in (-1, 1):
			kit.cylinder(0.11, 0.02, (x + s_ * 0.095, 0, 0.55), PLANK(), rot=(0, 90, 0), verts=16, bevel=0.003)
		for q in range(8):
			kit.ring(0.06 + 0.012 * (k % 2) + (q % 2) * 0.004, 0.006, (x - 0.07 + q * 0.02, 0, 0.55), IRON("a"), rot=(0, 90, 0), seg=16)
	# wire from the middle spool running down to a loose coil on the floor
	tube([(0.0, -0.064, 0.55), (0.02, -0.12, 0.4), (0.06, -0.24, 0.2), (0.12, -0.36, 0.03), (0.2, -0.42, 0.012)], 0.004, 0.004, IRON("a"), seg=5)
	for q in range(4):
		kit.ring(0.11 + q * 0.008, 0.004, (0.28 + q * 0.012, -0.44 + J(0.01), 0.005 + q * 0.0085), IRON("a"), rot=(0, 0, 0), seg=18)
	# snips hanging on the right post
	nx = 0.44
	kit.cylinder(0.006, 0.04, (nx, -0.065, 0.48), IRON("dark"), rot=(90, 0, 0), verts=6, bevel=0)
	for s_ in (-1, 1):
		B((0.016, 0.01, 0.2), (nx + s_ * 0.015, -0.08, 0.38), IRON("dark"), bevel=0.002, rot=(0, s_ * 8, 0))
	kit.rivet((nx, -0.088, 0.44), IRON("a"), r=0.01)
	tube([(nx, -0.07, 0.484), (nx, -0.08, 0.475)], 0.004, 0.004, IRON("dark"), seg=5)


def op_ore_scale():
	stump(0.2, 0.5)
	T0 = 0.512
	B((0.12, 0.12, 0.02), (0, 0.06, T0 + 0.005), IRON("dark"), bevel=0.003)
	for (x, y) in ((-0.045, 0.015), (0.045, 0.015), (-0.045, 0.105), (0.045, 0.105)):
		kit.rivet((x, y, T0 + 0.015), IRON("a"), r=0.007)
	kit.cylinder(0.014, 0.5, (0, 0.06, T0 + 0.25), IRON("dark"), verts=8, bevel=0)
	PZ = T0 + 0.5
	tilt = math.radians(7)
	ex, ez = 0.3 * math.cos(tilt), 0.3 * math.sin(tilt)
	B((0.62, 0.016, 0.022), (0, 0.06, PZ), IRON("a"), bevel=0.003, rot=(0, math.degrees(tilt), 0))
	kit.cylinder(0.022, 0.04, (0, 0.06, PZ), CU("dark"), rot=(90, 0, 0), verts=10, bevel=0.003)
	kit.cone(0.012, 0.0, 0.1, (0, 0.06, PZ + 0.06), CU("b"), verts=4, bevel=0)
	for s_, (m, z) in ((-1, (GOLD, 0.0)), (1, (None, 0.0))):
		hx, hz = s_ * ex, PZ - s_ * ez
		kit.ring(0.014, 0.004, (hx, 0.06, hz - 0.012), IRON("dark"), rot=(90, 0, 0), seg=8)
		pz = hz - 0.33
		for d in ((-1, 0), (1, 0), (0, 1)):
			tube([(hx, 0.06, hz - 0.02), (hx + d[0] * 0.085, 0.06 + d[1] * 0.085, pz + 0.025)], 0.003, 0.003, IRON("dark"), seg=4)
		kit.cylinder(0.1, 0.02, (hx, 0.06, pz + 0.01), CU("b"), verts=16, bevel=0.004)
		kit.ring(0.1, 0.007, (hx, 0.06, pz + 0.022), CU("dark"), seg=16)
		if s_ < 0:
			lump((hx, 0.06, pz + 0.04), (0.04, 0.035, 0.028), GOLD(), seed=5, rough=0.006)
	# graded weights on the stump front
	for k, r in enumerate((0.035, 0.028, 0.022, 0.016)):
		x = -0.11 + k * 0.07
		kit.cylinder(r, r * 1.4, (x, -0.1, T0 + r * 0.7), IRON("dark"), verts=12, bevel=0.003)
		sphere((x, -0.1, T0 + r * 1.4 + 0.006), r * 0.35, IRON("a"), seg=8, rings=5)


# ================= Story scenes =================
def op_caught_boot():
	# the boot lies on its side, its shaft clamped in the closed jaws
	settle(boot((0, 0, 0), lying=True, rotz=0))  # shaft along +x at y 0.03, toe toward -y
	# bear trap: base bar along y under the shaft, two jaws snapped shut round it (in the y-z plane)
	jx, jy = 0.2, 0.03
	B((0.08, 0.42, 0.02), (jx, jy, 0.01), IRON("dark"), bevel=0.004)
	for s_ in (-1, 1):
		group(lambda: jaw(0.13, "in"), (jx + s_ * 0.013, jy, 0.03), (0, 0, 90))
		B((0.05, 0.16, 0.012), (jx, jy + s_ * 0.27, 0.012), IRON("a"), bevel=0.003)
		kit.ring(0.028, 0.007, (jx, jy + s_ * 0.35, 0.03), IRON("a"), rot=(0, 90, 0), seg=10)
	chain((jx + 0.02, jy + 0.2, 0.015), (0.36, 0.46, 0.015), R=0.018, wire=0.006)
	log((0.37, 0.48, 0.0), (0.37, 0.48, 0.07), 0.016, IRON("dark"), seg=6, rings=1, ends=False, bend=0)
	kit.ring(0.024, 0.006, (0.37, 0.48, 0.06), IRON("a"), seg=10)
	# his walking stick, snapped in two
	rlog((-0.2, -0.3, 0.02), (0.18, -0.36, 0.02), 0.02, seg=6, rings=3, bend=0.02, ends=False)
	rlog((0.24, -0.38, 0.02), (0.55, -0.22, 0.02), 0.02, seg=6, rings=3, bend=0.02, ends=False)
	for (p, ax) in (((0.185, -0.361, 0.02), (1, -0.15, 0)), ((0.235, -0.378, 0.02), (-1, -0.3, 0))):
		ax = Vector(ax).normalized()
		for k in range(3):
			c = Vector(p) + Vector((0, 0, (k - 1) * 0.008)) + ax * 0.015
			o = kit.cone(0.008, 0.0, 0.04, tuple(c), LOGEND(), verts=4, bevel=0)
			o.rotation_euler = Vector((0, 0, 1)).rotation_difference(ax).to_euler()
	sphere((0.56, -0.215, 0.022), 0.028, LOGEND())
	# lantern knocked over on its side
	settle(lantern((-0.3, 0.25, 0.2), (90, 0, 30)))


def op_diary_table():
	stump(0.22, 0.56)
	kit.cylinder(0.36, 0.05, (0, 0, 0.58), PLANK(), verts=18, bevel=0.01)
	kit.ring(0.36, 0.008, (0, 0, 0.58), IRON("dark"), seg=24)
	T0 = 0.605
	# open diary: leather cover, two page blocks, writing that trails off
	B((0.4, 0.27, 0.012), (-0.05, -0.02, T0 + 0.006), LEATHER("b"), bevel=0.004, rot=(0, 0, 8))
	for s_ in (-1, 1):
		def half(s_=s_):
			B((0.18, 0.25, 0.022), (s_ * 0.095, 0, 0.011), PARCH(), bevel=0.004, rot=(0, -s_ * 3, 0))
			for r in range(7):
				ln = 0.14 if not (s_ > 0 and r > 3) else (0.06 if r == 4 else 0.0)
				if ln:
					B((ln, 0.005, 0.003), (s_ * 0.095 - (0.14 - ln) / 2, 0.09 - r * 0.028, 0.023 + s_ * -0.0), INK(), bevel=0)
			if s_ > 0:  # the last stroke, a long scrawl down the page
				B((0.12, 0.006, 0.003), (0.1, -0.06, 0.023), INK(), bevel=0, rot=(0, 0, -35))
		group(half, (-0.05, -0.02, T0 + 0.011), (0, 0, 8))
	B((0.02, 0.25, 0.026), (-0.05, -0.02, T0 + 0.013), LEATHER("dark"), bevel=0.004, rot=(0, 0, 8))
	# quill dropped across the table edge
	log((0.12, -0.2, T0 + 0.004), (0.32, -0.12, T0 + 0.006), 0.004, C((0.85, 0.82, 0.74), 0.8), seg=5, rings=1, ends=False, bend=0)
	B((0.16, 0.035, 0.004), (0.25, -0.15, T0 + 0.008), C((0.78, 0.74, 0.66), 0.8), bevel=0, rot=(0, 0, 22))
	# tipped ink pot and its spill
	kit.cylinder(0.035, 0.06, (0.2, 0.12, T0 + 0.035), C((0.12, 0.11, 0.14), 0.35), rot=(90, 0, 60), verts=12, bevel=0.006)
	kit.cylinder(0.018, 0.02, (0.2346, 0.1, T0 + 0.035), C((0.12, 0.11, 0.14), 0.35), rot=(90, 0, 60), verts=10, bevel=0.002)
	pts = [(0.27 + math.cos(a) * 0.07 * (0.7 + 0.3 * math.sin(3 * a)), 0.07 + math.sin(a) * 0.05) for a in [2 * math.pi * k / 12 for k in range(12)]]
	mesh([(x, y, T0 + 0.001) for x, y in pts] + [(x, y, T0 + 0.004) for x, y in pts],
		[tuple(range(12)), tuple(range(12, 24))] + [(i, (i + 1) % 12, (i + 1) % 12 + 12, i + 12) for i in range(12)], C((0.06, 0.05, 0.08), 0.15))
	# candle burnt down to a stub, empty plate and spoon, folded spectacles
	kit.cylinder(0.055, 0.012, (-0.22, 0.2, T0 + 0.006), CU("b"), verts=12, bevel=0.003)
	kit.cylinder(0.02, 0.025, (-0.22, 0.2, T0 + 0.024), WAX(), verts=8, bevel=0.004)
	sphere((-0.205, 0.19, T0 + 0.014), 0.012, WAX(), scale=(1.4, 1, 0.5))
	kit.cylinder(0.11, 0.012, (0.05, 0.22, T0 + 0.006), IRON("a"), verts=16, bevel=0.003)
	kit.ring(0.105, 0.006, (0.05, 0.22, T0 + 0.013), IRON("a"), seg=16)
	B((0.12, 0.012, 0.006), (0.06, 0.21, T0 + 0.016), IRON("dark"), bevel=0.002, rot=(0, 0, 30))
	sphere((0.0, 0.18, T0 + 0.017), 0.016, IRON("dark"), scale=(1.3, 1, 0.4))
	spectacles((-0.25, -0.2, T0), rotz=30)
	# his stool, knocked over behind the table
	settle(stool3((0.1, 0.62, 0.17), (0, 82, 20)))


def op_x_marks_dig():
	import random
	r = random.Random(11)
	# the dug hole (owner: really hollow): a round pit with a thrown-up earth rim, sloping walls, a dark floor
	EARTH = ROCK("dark")  # the same brown rock-earth as the spoil heap
	prof = [(0.0, 0.0), (0.54, 0.0), (0.48, 0.08), (0.41, 0.17), (0.355, 0.21), (0.315, 0.195), (0.275, 0.13), (0.23, 0.06),
		(0.17, 0.02), (0.0, 0.012)]
	pit = flathe(prof, (0, 0), EARTH, seg=24)
	for v in pit.data.vertices:  # dug by hand: a wobbly rim, never a perfect circle
		rr = math.hypot(v.co.x, v.co.y)
		if rr > 0.01:
			a = math.atan2(v.co.y, v.co.x)
			k = 1 + 0.06 * math.sin(3 * a + 0.7) + 0.035 * math.sin(7 * a + 2.1)
			v.co.x *= k
			v.co.y *= k
			if v.co.z > 0.05:
				v.co.z *= 1 + 0.18 * math.sin(5 * a + 1.3)
	# clods of dug earth on the rim and stones on the pit floor
	for k in range(14):
		a = 2 * math.pi * k / 14 + r.uniform(-0.15, 0.15)
		rr = 0.36 * (1 + 0.06 * math.sin(3 * a + 0.7)) + r.uniform(-0.02, 0.02)
		sz = r.uniform(0.03, 0.05)
		lump((math.cos(a) * rr, math.sin(a) * rr, 0.2 + sz * 0.2), (sz, sz * 0.85, sz * 0.6), ROCK("dark" if k % 3 == 0 else None), seed=60 + k, rough=0.008)
	for k in range(4):
		a = 2 * math.pi * k / 4 + 0.4
		sz = r.uniform(0.03, 0.045)
		lump((math.cos(a) * 0.08, math.sin(a) * 0.08, 0.012 + sz * 0.3), (sz, sz * 0.8, sz * 0.6), ROCK("dark"), seed=80 + k, rough=0.006)
	# spoil heap beside it: angular chunks, big at the bottom, settled into each other
	hx, hy = 0.85, 0.05
	for tier, (n, rad, z, s) in enumerate(((14, 0.27, 0.0, 0.09), (11, 0.19, 0.08, 0.085), (7, 0.11, 0.17, 0.075), (4, 0.05, 0.25, 0.06), (1, 0.0, 0.31, 0.05))):
		for k in range(n):
			a = 2 * math.pi * k / n + r.uniform(-0.2, 0.2) + tier
			rr = rad * r.uniform(0.5, 1.0)
			sz = s * r.uniform(0.7, 1.3)
			o = lump((hx + math.cos(a) * rr, hy + math.sin(a) * rr, z + sz * 0.55), (sz, sz * 0.85, sz * 0.7), ROCK("dark" if k % 4 == 0 else None), seed=tier * 20 + k, rough=0.01)
			if tier == 0:
				bpy.context.view_layer.update()
				o.location.z -= min((o.matrix_world @ v.co).z for v in o.data.vertices) + 0.003
	# shovel stuck in the heap
	B((0.17, 0.02, 0.2), (hx - 0.02, hy - 0.02, 0.22), IRON("dark"), bevel=0.006, rot=(0, -18, 0))
	rlog((hx + 0.01, hy - 0.02, 0.32), (hx + 0.2, hy - 0.02, 0.92), 0.022, seg=6, rings=3, ends=False, bend=0.02)
	B((0.14, 0.035, 0.03), (hx + 0.205, hy - 0.02, 0.935), DARKW(), bevel=0.006, rot=(0, -18, 0))
	# pick lying on the floor
	rlog((0.3, -0.75, 0.025), (0.95, -0.6, 0.025), 0.022, seg=6, rings=3, ends=False, bend=0.01)
	tube([(0.82, -0.86, 0.02), (0.86, -0.72, 0.035), (0.885, -0.62, 0.04), (0.9, -0.5, 0.035), (0.92, -0.38, 0.02)], 0.022, 0.01, IRON("dark"), seg=7)
	# a bucket tipped over, stones spilling out
	group(lambda: [kit.cylinder(0.13, 0.26, (0, 0, 0.13), PLANK(), verts=12, bevel=0.01),
		kit.ring(0.133, 0.008, (0, 0, 0.05), IRON("dark"), seg=14), kit.ring(0.133, 0.008, (0, 0, 0.21), IRON("dark"), seg=14),
		kit.cylinder(0.115, 0.02, (0, 0, 0.255), CHAR(), verts=12, bevel=0),
		tube([(0.133 * math.cos(math.radians(a)), 0, 0.2 + 0.12 * math.sin(math.radians(a))) for a in range(0, 181, 20)], 0.005, 0.005, IRON("a"), seg=5)],
		(-0.75, -0.55, 0.13), (90, 0, 115))
	for k in range(4):
		ground = lump((-0.62 + k * 0.055 + J(0.01), -0.47 + k * 0.026 + J(0.01), 0.04), (0.04, 0.034, 0.028), ROCK(), seed=k + 40, rough=0.006)
		bpy.context.view_layer.update()
		ground.location.z -= min((ground.matrix_world @ v.co).z for v in ground.data.vertices) + 0.003
	# a stake with his map nailed on, a red X
	rlog((-0.62, 0.55, 0.0), (-0.62, 0.55, 0.8), 0.035, seg=7, rings=3, bend=0.01)
	yf, P = page(-0.62, 0.58, 0.22, 0.2, 0.515, tilt=3)
	for a, b in (((-0.08, -0.06), (-0.02, 0.0)), ((-0.02, 0.0), (0.03, -0.03)), ((0.03, -0.03), (0.08, 0.04))):
		ink(P(*a), P(*b), yf, w=0.007)
	ink(P(0.02, 0.03), P(0.06, 0.07), yf - 0.0033, w=0.012, m=RED())
	ink(P(0.02, 0.07), P(0.06, 0.03), yf - 0.0066, w=0.012, m=RED())
	kit.cylinder(0.011, 0.04, (-0.62, 0.51, 0.66), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)


def round_bell(s=1.0):
	"""A proper hollow bell (curved waist, flared lip, a raised band), its crown loop at the origin, mouth down."""
	S = lambda v: v * s  # noqa: E731
	z0 = -S(0.074)
	prof = [(0, z0 + S(0.064)), (S(0.012), z0 + S(0.062)), (S(0.019), z0 + S(0.056)), (S(0.021), z0 + S(0.045)), (S(0.024), z0 + S(0.03)),
		(S(0.03), z0 + S(0.014)), (S(0.037), z0 + S(0.004)), (S(0.036), z0), (S(0.03), z0 + S(0.004)), (S(0.023), z0 + S(0.02)),
		(S(0.018), z0 + S(0.04)), (S(0.015), z0 + S(0.052)), (0, z0 + S(0.055))]
	flathe(prof, (0, 0), CU("b"), seg=16)
	kit.ring(S(0.0235), max(0.002, S(0.003)), (0, 0, z0 + S(0.028)), CU("dark"), seg=16)
	kit.ring(S(0.012), max(0.003, S(0.004)), (0, 0, -S(0.004)), CU("dark"), rot=(0, 90, 0), seg=8)


def op_bell_tripwire():
	# the tripwire has snapped: both halves fell off their stakes' ties to the floor, the bells lie where they dropped
	for x in (-0.7, 0.7):
		rlog((x, 0, -0.0), (x, 0, 0.42), 0.035, seg=7, rings=2, bend=0.02)
		kit.cone(0.035, 0.0, 0.07, (x, 0, 0.455), LOGEND(), verts=7, bevel=0)
		for k in range(3):
			a = 2 * math.pi * k / 3 + x
			B((0.09, 0.07, 0.06), (x + math.cos(a) * 0.07, math.sin(a) * 0.07, 0.027), SSTONE(), bevel=0.018, rot=(J(8), J(8), math.degrees(a)))
		kit.ring(0.04, 0.008, (x, 0, 0.32), ROPE(), seg=10)
	sb = 0.85
	zr = 0.037 * sb - 0.003  # a bell lying on its side: its loop's middle is this high
	bells = (-0.46, -0.27, 0.22, 0.42)
	for sx in (-1, 1):
		xs = sorted([b for b in bells if b * sx > 0], key=abs, reverse=True)
		# from the tie straight down the stake, then along the floor to a frayed end
		pts = [(sx * 0.655, 0, 0.32), (sx * 0.652, 0, 0.1), (sx * 0.645, 0, 0.03), (sx * 0.62, -0.01, 0.0055)]
		for b in xs:
			pts += [(b + sx * 0.05, -0.02, 0.0055), (b, -0.02, zr), (b - sx * 0.05, -0.02, 0.0055)]
		end = sx * 0.12  # a clear gap where it snapped
		pts.append((end, -0.035, 0.0055))
		tube(pts, 0.006, 0.006, ROPE(), seg=5)
		for k in range(3):
			kit.cone(0.004, 0.0, 0.03, (end - sx * 0.012, -0.035 + (k - 1) * 0.004, 0.0055), ROPE(), rot=(0, -sx * 90, (k - 1) * 25), verts=4, bevel=0)
		for b in xs:
			objs = group(lambda: round_bell(sb), at=(b, -0.02, zr), rot=(-90, 0, J(15)))
			settle(objs)
	# the bigger warning bell still hangs straight down on its iron bracket at the right stake
	tube([(0.7, -0.03, 0.4), (0.7, -0.1, 0.42), (0.7, -0.16, 0.41)], 0.007, 0.007, IRON("dark"), seg=6)
	B((0.03, 0.012, 0.06), (0.7, -0.03, 0.39), IRON("dark"), bevel=0.002)
	group(lambda: round_bell(1.6), at=(0.7, -0.16, 0.404), rot=(0, 0, 90))


def op_barricade():
	H = 1.3
	for s_ in (-1, 1):
		x = s_ * 0.75
		rlog((x, 0, 0), (x, 0, H), 0.07, seg=9, rings=4, bend=0.02)
		rlog((x, 0.45, 0.0), (x, 0.03, H * 0.62), 0.045, seg=7, rings=3)
		for k in range(3):
			a = k * 2.1 + s_
			B((0.13, 0.1, 0.09), (x + math.cos(a) * 0.12, math.sin(a) * 0.12 - 0.02, 0.04), SSTONE(), bevel=0.02, rot=(J(6), J(6), math.degrees(a)))
	planks = []
	for k, (z, h) in enumerate(((0.22, 0.2), (0.45, 0.2), (0.7, 0.21), (0.95, 0.2), (1.18, 0.18))):
		planks.append(B((1.66, 0.04, h - 0.02), (J(0.02), -0.083, z), PLANK(), bevel=0.01, rot=(0, J(2.5), 0)))
		for x in (-0.75, 0.75):
			nail(x, -0.112, z + 0.03)
			nail(x + 0.03, -0.112, z - 0.04)
	# peephole bored through the fourth plank, cover swung aside on its nail
	px, pz = 0.25, 0.95
	carve(planks[3], lambda: kit.cylinder(0.035, 0.1, (px, -0.09, pz), GROOVE(), rot=(90, 0, 0), verts=14, bevel=0))
	kit.cylinder(0.055, 0.015, (px + 0.075, -0.118, pz - 0.05), DARKW(), rot=(90, 0, 0), verts=12, bevel=0.003)
	nail(px + 0.075 + 0.035, -0.125, pz - 0.05 + 0.02)
	# a skull mark carved in the middle plank
	carve(planks[2], lambda: [kit.ring(0.06, 0.009, (-0.3, -0.11, 0.72), GROOVE(), rot=(90, 0, 0), seg=18),
		kit.cylinder(0.014, 0.03, (-0.322, -0.11, 0.725), GROOVE(), rot=(90, 0, 0), verts=8, bevel=0),
		kit.cylinder(0.014, 0.03, (-0.278, -0.11, 0.725), GROOVE(), rot=(90, 0, 0), verts=8, bevel=0),
		groove((-0.33, 0.69), (-0.27, 0.69), -0.11, w=0.008)])
	# sharpened stakes pointing out, lashed to the bottom plank
	for k in range(5):
		x = -0.6 + k * 0.3
		rlog((x, -0.12, 0.18), (x + J(0.03), -0.6, 0.55), 0.03, seg=6, rings=2, ends=False, bend=0.01)
		d = Vector((0, -0.48, 0.37)).normalized()
		kit.cone(0.03, 0.0, 0.12, tuple(Vector((x, -0.6, 0.55)) + d * 0.055), CHAR(), rot=(math.degrees(math.atan2(0.48, 0.37)), 0, 0), verts=6, bevel=0)
		rlog((x, -0.14, 0.2), (x, -0.32, 0.0), 0.025, seg=6, rings=2, ends=False)
		kit.ring(0.04, 0.009, (x, -0.13, 0.2), ROPE(), rot=(60, 0, 0), seg=10)


def op_decoy_chest():
	W, D, H = 0.72, 0.46, 0.4
	B((W - 0.04, D - 0.04, 0.03), (0, 0, 0.02), CHAR(), bevel=0)
	for s_ in (-1, 1):
		for k in range(3):
			B((W, 0.03, H / 3 - 0.008), (0, s_ * (D / 2 - 0.015), H / 6 + k * H / 3), PLANK(), bevel=0.006)
			B((0.03, D - 0.06, H / 3 - 0.008), (s_ * (W / 2 - 0.015), 0, H / 6 + k * H / 3), PLANK(), bevel=0.006)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.06, 0.06, H + 0.01), (cx * (W / 2 - 0.01), cy * (D / 2 - 0.01), H / 2), IRON("dark"), bevel=0.006)
	for x in (-0.18, 0.18):
		B((0.05, D + 0.012, 0.02), (x, 0, H - 0.005), IRON("dark"), bevel=0.003)
		for y in (-1, 1):
			B((0.05, 0.012, H), (x, y * (D / 2 + 0.002), H / 2), IRON("dark"), bevel=0.003)
			for z in (0.08, 0.2, 0.32):
				kit.rivet((x, y * (D / 2 + 0.01), z), IRON("a"), r=0.009)
	B((0.08, 0.015, 0.1), (0, -D / 2 - 0.006, H - 0.07), IRON("a"), bevel=0.003)
	kit.ring(0.022, 0.006, (0, -D / 2 - 0.02, H - 0.1), IRON("a"), rot=(90, 0, 0), seg=10)
	# the lid, thrown back on its hinges
	def lid():
		for k in range(3):
			B((W, D / 3 - 0.006, 0.04), (0, -D / 2 + D / 6 + k * D / 3, 0.02), PLANK(), bevel=0.006)
		for x in (-0.18, 0.18):
			B((0.05, D + 0.01, 0.012), (x, 0, 0.045), IRON("dark"), bevel=0.003)
		B((0.08, 0.012, 0.09), (0, -D / 2 - 0.004, -0.02), IRON("a"), bevel=0.003)
	objs = group(lid, (0, 0, H + 0.002))
	turn(objs, "X", -110, Vector((0, D / 2, H + 0.002)))
	for x in (-0.25, 0.25):
		kit.cylinder(0.018, 0.08, (x, D / 2 + 0.005, H + 0.005), IRON("dark"), rot=(0, 90, 0), verts=8, bevel=0.002)
	# inside: no gold, just a big spring that shot up a spiked plate
	group(lambda: helix(0.08, 0.012, 6, 0.42, IRON("a"), n_per=12), (0, 0, 0.035))
	B((0.24, 0.24, 0.02), (0, 0, 0.035), IRON("dark"), bevel=0.004)
	kit.cylinder(0.15, 0.025, (0, 0, 0.47), IRON("dark"), verts=16, bevel=0.005)
	for k in range(9):
		a = 2 * math.pi * k / 8
		rr = 0.0 if k == 8 else 0.1
		kit.cone(0.018, 0.0, 0.08, (math.cos(a) * rr, math.sin(a) * rr, 0.52), IRON("a"), verts=5, bevel=0)
	kit.rivet((0.0, 0.0, 0.452), IRON("dark"), r=0.02)


def op_hat_on_pick():
	stump(0.22, 0.46)
	T0 = 0.46
	# his axe chopped into the stump top (owner: an axe, not a bent pick): the blade edge sunk 4 cm into the wood
	L, b = 0.7, 0.16
	Z = Vector((0.819, 0, -0.574))  # handle: from the butt (up, left) to the head
	X = Vector((0.574, 0, 0.819))  # the blade points along -X (down into the stump)
	edge = X * (-b) + Z * (L - 0.06)
	at = Vector((-0.12, 0.0, T0 - 0.04)) - edge
	place(lambda: t_axe(L), at=tuple(at), basis=(tuple(X), tuple(Z.cross(X)), tuple(Z)))

	# his battered candle hat, sitting still on the floor beside the stump
	def hat():
		sphere((0, 0, 0.0), 0.11, LEATHER("b"), scale=(1, 1.1, 0.85), seg=16, rings=8, cut=0.0)
		kit.cylinder(0.135, 0.014, (0, 0, 0.005), LEATHER("dark"), verts=18, bevel=0.004)
		kit.ring(0.112, 0.008, (0, 0, 0.018), LEATHER("dark"), seg=18)
		B((0.04, 0.012, 0.06), (0, -0.115, 0.05), IRON("dark"), bevel=0.003, rot=(-20, 0, 0))
		kit.cylinder(0.02, 0.012, (0, -0.13, 0.085), IRON("a"), verts=8, bevel=0.002)
		kit.cylinder(0.012, 0.03, (0, -0.13, 0.105), WAX(), verts=8, bevel=0.003)
		B((0.05, 0.004, 0.03), (0.06, -0.09, 0.05), LEATHER("dark"), bevel=0.001, rot=(0, 30, 10))
	settle(group(hat, (0.38, -0.12, 0.0), (0, 0, -25)))
	# tin cup turned upside down on the stump, a little cairn of three stones at the foot
	kit.cylinder(0.04, 0.08, (-0.1, 0.12, T0 + 0.036), IRON("a"), verts=12, bevel=0.004)
	kit.ring(0.04, 0.005, (-0.1, 0.12, T0 + 0.0), IRON("a"), seg=12)
	for k, (s, z) in enumerate(((0.12, 0.045), (0.09, 0.12), (0.06, 0.18))):
		B((s * 1.1, s, s * 0.75), (0.0 + J(0.01), -0.35, z), SSTONE(), bevel=0.02, rot=(J(5), J(5), k * 25))


def op_rat_traps():
	B((1.1, 0.24, 0.035), (0, 0, 0.0175), PLANK(), bevel=0.008)
	for x in (-0.45, 0.45):
		peg((x, 0.0, 0.035), "z")

	def trap(state):
		B((0.2, 0.09, 0.018), (0, 0, 0.009), PLANK(), bevel=0.004)
		for s_ in (-1, 1):
			kit.ring(0.012, 0.0035, (0.0, s_ * 0.03, 0.026), IRON("a"), rot=(0, 90, 0), seg=8)
		kit.cylinder(0.003, 0.08, (0, 0, 0.026), IRON("dark"), rot=(90, 0, 0), verts=5, bevel=0)
		B((0.04, 0.03, 0.004), (-0.04, 0, 0.02), CU("dark"), bevel=0.001)  # bait pedal
		sign = -1 if state == "set" else 1  # where the bow lies
		tube([(0.0, -0.035, 0.022), (sign * 0.07, -0.035, 0.022), (sign * 0.08, 0.0, 0.022), (sign * 0.07, 0.035, 0.022), (0.0, 0.035, 0.022)], 0.0035, 0.0035, IRON("a"), seg=5)
		if state == "set":
			B((0.08, 0.004, 0.004), (0.035, 0, 0.022), IRON("a"), bevel=0)
		B((0.012, 0.012, 0.012), (0.09, 0, 0.024), IRON("dark"), bevel=0.002)

	for k, (x, state) in enumerate(((-0.4, "set"), (-0.14, "sprung"), (0.12, "set"), (0.38, "rat"))):
		group(lambda state=state: trap("set" if state == "set" else "sprung"), (x, -0.01, 0.035), (0, 0, J(6)))
		if state == "rat":  # a rat skull under the bow, spine bones trailing
			sphere((x + 0.075, -0.01, 0.06), 0.022, BONE(), scale=(1.25, 1, 0.8))
			kit.cone(0.017, 0.007, 0.035, (x + 0.105, -0.01, 0.056), BONE(), rot=(0, 90, 0), verts=8, bevel=0.002)
			for q in range(5):
				sphere((x + 0.045 - q * 0.022, -0.01 + q * 0.004, 0.05), 0.008, BONE(), scale=(1, 1.4, 0.8), seg=8, rings=5)
			tube([(x - 0.06, -0.006, 0.05), (x - 0.11, 0.02, 0.041), (x - 0.16, 0.0, 0.038)], 0.0035, 0.0015, BONE(), seg=5)
	# empty bait dish
	kit.cylinder(0.04, 0.01, (0.0, 0.08, 0.04), CU("b"), verts=12, bevel=0.002)
	kit.ring(0.04, 0.004, (0.0, 0.08, 0.045), CU("dark"), seg=12)
	# a crate behind with a gnawed hole in its corner
	cx, cy = 0.2, 0.32
	box = B((0.5, 0.36, 0.3), (cx, cy, 0.15), PLANK(), bevel=0.012)
	carve(box, lambda: [sphere((cx - 0.16, cy - 0.18, 0.06), 0.06, GROOVE(), scale=(1, 1, 0.9)),
		sphere((cx - 0.12, cy - 0.18, 0.045), 0.045, GROOVE())])
	for k in (1, 2):
		B((0.504, 0.364, 0.012), (cx, cy, 0.3 * k / 3), DARKW(), bevel=0.002)
	for (sx, sy) in ((-1, -1), (1, -1), (-1, 1), (1, 1)):
		B((0.04, 0.04, 0.31), (cx + sx * 0.25, cy + sy * 0.18, 0.155), IRON("dark"), bevel=0.004)


def op_strongbox_pried():
	W, D, H = 0.58, 0.4, 0.3
	B((W - 0.03, D - 0.03, 0.02), (0, 0, 0.012), CHAR(), bevel=0)
	for s_ in (-1, 1):
		for k in range(2):
			B((W, 0.03, H / 2 - 0.008), (0, s_ * (D / 2 - 0.015), H / 4 + k * H / 2), DARKW(), bevel=0.006)
			B((0.03, D - 0.06, H / 2 - 0.008), (s_ * (W / 2 - 0.015), 0, H / 4 + k * H / 2), DARKW(), bevel=0.006)
	for x in (-0.2, 0.0, 0.2):
		for y in (-1, 1):
			B((0.045, 0.012, H), (x, y * (D / 2 + 0.002), H / 2), IRON("dark"), bevel=0.003)
			for z in (0.05, 0.15, 0.25):
				kit.rivet((x, y * (D / 2 + 0.01), z), IRON("a"), r=0.008)
	for cx in (-1, 1):
		for cy in (-1, 1):
			B((0.05, 0.05, H + 0.008), (cx * (W / 2 - 0.008), cy * (D / 2 - 0.008), H / 2), IRON("dark"), bevel=0.005)
	# splinters where the bar bit in
	for k in range(4):
		kit.cone(0.008, 0.0, 0.05, (-0.06 + k * 0.035, -D / 2 - 0.008, H - 0.02), LOGEND(), rot=(-60, 0, J(20)), verts=4, bevel=0)

	def lid():
		B((W - 0.012, D, 0.05), (0, -D / 2, 0.025), DARKW(), bevel=0.008)
		for x in (-0.2, 0.0, 0.2):
			B((0.045, D + 0.012, 0.012), (x, -D / 2, 0.054), IRON("dark"), bevel=0.003)
		B((0.07, 0.012, 0.08), (0.12, -D - 0.004, -0.015), IRON("a"), bevel=0.003, rot=(0, 25, 0))  # broken hasp hanging crooked
	objs = group(lid, (0, D / 2, H + 0.003))
	turn(objs, "X", -28, Vector((0, D / 2, H + 0.003)))
	for x in (-0.18, 0.18):
		kit.cylinder(0.016, 0.07, (x, D / 2 + 0.004, H + 0.006), IRON("dark"), rot=(0, 90, 0), verts=8, bevel=0.002)
	# the crowbar still wedged under the lid, its end on the floor
	tube([(0.0, -D / 2 + 0.03, H + 0.01), (0.0, -D / 2 - 0.03, H + 0.005), (0.0, -D / 2 - 0.07, H - 0.03), (0.02, -0.55, 0.012)], 0.013, 0.013, IRON("dark"), seg=7)
	kit.cone(0.014, 0.004, 0.035, (0.0, -D / 2 + 0.05, H + 0.012), IRON("dark"), rot=(-90, 0, 0), verts=6, bevel=0)
	# the padlock lying broken on the floor
	B((0.06, 0.03, 0.07), (0.22, -0.4, 0.016), IRON("a"), bevel=0.008, rot=(90, 0, 30))
	tube([(0.2, -0.43, 0.03), (0.19, -0.46, 0.04), (0.2, -0.49, 0.03), (0.215, -0.5, 0.012)], 0.006, 0.006, IRON("dark"), seg=6)


def op_watch_post():
	H = 1.25
	for s_ in (-1, 1):
		x = s_ * 0.72
		rlog((x, 0, 0), (x, 0, H), 0.06, seg=8, rings=3, bend=0.02)
		rlog((x, 0.4, 0.0), (x, 0.04, 0.7), 0.04, seg=7, rings=2)
	for z in (0.12, H - 0.15):
		rlog((-0.72, 0.065, z), (0.72, 0.065, z), 0.04, seg=7, rings=3)
	planks = []
	for k in range(6):
		x = -0.55 + k * 0.22
		planks.append(B((0.205, 0.035, H - 0.05 + J(0.04)), (x, 0.12, H / 2), PLANK(), bevel=0.008))
		for z in (0.12, H - 0.15):
			kit.cylinder(0.011, 0.008, (x, 0.027, z), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
	# peephole and its sliding cover on the front
	px, pz = 0.11, 1.0
	carve(planks[3], lambda: kit.cylinder(0.035, 0.1, (px, 0.12, pz), GROOVE(), rot=(90, 0, 0), verts=14, bevel=0))
	B((0.1, 0.014, 0.1), (px + 0.09, 0.0955, pz - 0.02), DARKW(), bevel=0.003, rot=(0, 15, 0))
	kit.cylinder(0.01, 0.01, (px + 0.12, 0.088, pz + 0.01), IRON("dark"), rot=(90, 0, 0), verts=8, bevel=0.002)
	# carved tally on the left post's front face of plank 0
	carve(planks[0], lambda: [groove((-0.6 + q * 0.025, 0.95), (-0.6 + q * 0.025, 1.05), 0.1025, w=0.008, depth=0.012) for q in range(4)] +
		[groove((-0.615, 0.96), (-0.52, 1.04), 0.1025, w=0.008, depth=0.012)])
	# crossbow leaning on the front of the screen
	def xbow():
		B((0.05, 0.04, 0.62), (0, 0, 0.31), DARKW(), bevel=0.008)
		tube([(-0.26, 0.0, 0.5), (-0.12, -0.02, 0.56), (0.0, -0.025, 0.58), (0.12, -0.02, 0.56), (0.26, 0.0, 0.5)], 0.012, 0.012, PLANK(), seg=6)
		tube([(-0.26, 0.0, 0.5), (0.0, 0.0, 0.42), (0.26, 0.0, 0.5)], 0.003, 0.003, ROPE(), seg=4)
		tube([(-0.035, -0.02, 0.62), (-0.05, -0.02, 0.68), (0.0, -0.02, 0.71), (0.05, -0.02, 0.68), (0.035, -0.02, 0.62)], 0.007, 0.007, IRON("dark"), seg=5)
		B((0.012, 0.02, 0.06), (0, 0.03, 0.22), IRON("dark"), bevel=0.002)
		for z in (0.15, 0.4):
			B((0.054, 0.044, 0.02), (0, 0, z), IRON("a"), bevel=0.002)
	group(xbow, (-0.3, -0.07, 0.0), (-14, 0, 0))
	# behind: his stool and a quiver of bolts on a peg
	stool3((0.2, 0.55, 0))
	hq = (0.45, 0.14, 0.95)
	log((hq[0], 0.137, hq[2]), (hq[0], 0.21, hq[2] + 0.012), 0.012, DARKW(), seg=6, rings=1, ends=False, bend=0)
	kit.cylinder(0.05, 0.32, (hq[0], 0.22, hq[2] - 0.15), LEATHER("b"), verts=12, bevel=0.008)
	kit.ring(0.052, 0.006, (hq[0], 0.22, hq[2] - 0.01), LEATHER("dark"), seg=12)
	for k in range(4):
		a = k * 1.6
		kit.cylinder(0.005, 0.12, (hq[0] + math.cos(a) * 0.025, 0.22 + math.sin(a) * 0.025, hq[2] + 0.04), PLANK(), verts=5, bevel=0)
		kit.cone(0.012, 0.0, 0.025, (hq[0] + math.cos(a) * 0.025, 0.22 + math.sin(a) * 0.025, hq[2] + 0.11), C((0.5, 0.45, 0.38), 0.8), verts=3, bevel=0)
	tube([(hq[0], 0.18, hq[2] + 0.005), (hq[0], 0.175, hq[2] - 0.06)], 0.004, 0.004, LEATHER("dark"), seg=4)


MODELS = {k: v for k, v in globals().items() if k.startswith("op_") and callable(v)}

if __name__ == "__main__":
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	outdir = GAME / "assets" / "models" / "decor"
	jdir = GAME / "journey" / "3d" / "v2_hand_built" / "decor"
	outdir.mkdir(parents=True, exist_ok=True)
	jdir.mkdir(parents=True, exist_ok=True)
	for name in args or list(MODELS):
		rng.seed(sum(map(ord, name)))
		kit.reset()
		_cm.clear()
		try:
			MODELS[name]()
			kit.save(str(outdir / f"{name}.glb"), str(jdir / f"{name}.png"), tex_size=256)
			print(f"MODEL_OK {name}")
		except Exception as e:
			import traceback
			traceback.print_exc()
			print(f"MODEL_FAILED {name}: {e!r}")
