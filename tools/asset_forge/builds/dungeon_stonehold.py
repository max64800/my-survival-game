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
#   floor_loose_flagstone   the Scribe's Niche loose stone (F856): a Stonehold floor with a loose square stone in it
#                           (the buried chest under it). Parts "frame" and "stone" (like dungeon_rootwood.floor_loose_stone)
#   recipe_stand_stone      Hald's recipe stand (F856): a stone lectern, the scroll at the wooden stand's spot
#   trap_tripwire_wall_stone the dart wall (F853, owner Nov 25: "it's still wooden"): a Stonehold wall, a small round
#                           hole drilled through one stone at hip height with an iron ring round it, a green poison stain
#                           under it and an iron eye low down for the wire. Parts "frame" and "bolt" (same hole spot and
#                           bolt as dungeon_mine.trap_tripwire_wall, so the game fires it the same way)
#   tripwire_iron           its wire (F853): a thin rusty iron wire instead of the white string, same size and halves
#                           ("wire_l", "wire_r") as dungeon_mine.tripwire
#   trap_crossbow_wall_stone the Brassgate Vault's tripwire crossbow (F975 step 3, owner Nov 28): a Stonehold wall with
#                           a low wide guard slot cut through one course, dark behind, an iron-framed crossbow in it
#                           (wooden stock, iron bow, string) and an iron bolt on it. Parts "frame" and "bolt" (the
#                           bolt lies on the game's MineTraps.DART_HOLE line, so the game fires it like the dart wall)
#   trap_push_wall_stone    the Brassgate Vault's push wall (F975 step 3): a Stonehold wall with one big ashlar block
#                           set in a dark gap (the clue), 2 m deep into the rock. Parts "frame" and "block" (the same
#                           opening as dungeon_pell.trap_push_wall, so the game slams it out the same way)
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
	# three runes cut into the middle stone (F871, owner Nov 25: "far too faint"): twice as big, a wide dark groove
	# with a warm glowing inlay in it, so they read from across the cave even in the dark
	before = meshes()
	for rx, strokes in ((-0.3, [(0, 0, 90), (0.08, 0.08, 35), (0.08, -0.08, -35)]), (0.0, [(-0.08, 0, 90), (0.08, 0, 90), (0, 0, 0)]),
			(0.3, [(0, 0, 90), (0.07, 0.1, -40), (0.07, -0.1, 40)])):
		for k, (dx, dy, ang) in enumerate(strokes):   # (each stroke 4 mm further out: crossing strokes never share a face)
			ln = 0.34 if ang in (0, 90) else 0.21
			K.blk((rx + dx, 2.725 + dy, 0.306 + 0.004 * k), (ln, 0.075, 0.03), kit.mat("charcoal"), bevel=0.006, rz=ang)
	tag(meshes() - before, "rune")
	before = meshes()
	for rx, strokes in ((-0.3, [(0, 0, 90), (0.08, 0.08, 35), (0.08, -0.08, -35)]), (0.0, [(-0.08, 0, 90), (0.08, 0, 90), (0, 0, 0)]),
			(0.3, [(0, 0, 90), (0.07, 0.1, -40), (0.07, -0.1, 40)])):
		for k, (dx, dy, ang) in enumerate(strokes):   # the glowing inlay, 1.2 cm in front of its groove
			ln = 0.3 if ang in (0, 90) else 0.17
			K.blk((rx + dx, 2.725 + dy, 0.318 + 0.004 * k), (ln, 0.036, 0.03), kit.glow("crystal_amber", 1.4), bevel=0.004, rz=ang)
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
	"""A Stonehold wall that is about to give: one stone knocked out of it (F857 🔁, owner Nov 25: "an open hole so
	players can see the chest"; then 3rd time: "this hole is too big, it's too obvious: fill it, only one part open"),
	three stones bulging out of line, chips on the floor in front."""
	ya_h, yb_h = 0.66, 0.9    # one course only: a peep hole at knee height (you crouch a little to see the chest)
	half = {}                 # each row through it stops at a different place (ragged): (ya, yb) -> (left, right)

	def hole(ya, yb):
		if not (ya_h <= (ya + yb) / 2 <= yb_h):   # (only the one course whose middle is in the band)
			return None
		r = (round(ya, 3), round(yb, 3))
		if r not in half:   # about one stone wide (36-42 cm), a little off centre
			half[r] = (0.1 - 0.18 - K.rng.uniform(0.0, 0.03), 0.1 + 0.18 + K.rng.uniform(0.0, 0.03))
		return half[r]
	before = set(bpy.data.objects)
	S.courses(w, h, d, hole=hole, back=False)
	# The dark backing (layer 1) follows the hole row by row, 1 cm back from the stones' ends, so the hole is open
	# right through and no joint between stones is see-through.
	bx0, bx1, by0, by1 = -w / 2 + E + 0.01, w / 2 - E - 0.01, E + 0.004, h - E - 0.01
	rows = sorted(half.items())
	# (no shimmer: each row's strips reach 1 cm into the next ones and are a little thinner than them, every other
	# row thinner again, so no two strip faces ever lie in the same place)
	# (and their ends stay 3 cm off the stones' joints, or they show through the joint beside a stone's face)
	strips = [(bx0, bx1, by0, rows[0][0][0] - 0.03, 0.62), (bx0, bx1, rows[-1][0][1] + 0.03, by1, 0.62)]
	for i, ((ya, yb), (hl, hr)) in enumerate(rows):
		dd = 0.56 if i % 2 == 0 else 0.5
		strips += [(bx0, hl - 0.01, ya - 0.04, yb + 0.04, dd), (hr + 0.01, bx1, ya - 0.04, yb + 0.04, dd)]
	fr = K.Frame()
	for (a, b, c, e, dd) in strips:
		if b - a > 0.01 and e - c > 0.01:
			fr.box(((a + b) / 2, (c + e) / 2, 0.0), (b - a, e - c, d * dd), S.mortar_m(), bevel=0)
	for o in bpy.data.objects:
		if o not in before and o.type == "MESH" and o.get("role") is None:
			o["role"] = "mortar"
	made = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
	stones = [o for o in made if o.get("role") == "stone"]
	frame = {o.name for o in made if o.get("role") != "stone"}

	def mid(o):
		vs = [o.matrix_world @ v.co for v in o.data.vertices]
		return (sum(v.x for v in vs) / len(vs), sum(v.z for v in vs) / len(vs))   # (game x, game y)
	for o in sorted(stones, key=lambda o: abs(mid(o)[0] + 0.55) + abs(mid(o)[1] - 0.5))[:3]:  # bulging out of line
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


# ---------------------------------------------------------------- the Scribe's Niche loose stone (F856 🔁)
def floor_loose_flagstone(w=2.0, h=0.25, dd=2.0):
	"""The stone twin of dungeon_rootwood.floor_loose_stone (that one is a Shack board floor, made for wooden
	Mossgate): a Stonehold floor (stone band round the edge, dark stone bed, chisel-cut flagstones) with a big
	square stone in its middle that sits loose: a dark gap all round, one corner rocked up a finger high (the clue).
	Parts "frame" (the floor, stays) and "stone" (lifts off; the buried chest is under it). No wood at all."""
	jh, rd = 0.13, 0.16
	x0, x1, z0, z1 = -w / 2 + E, w / 2 - E, -dd / 2 + E, dd / 2 - E
	outer = [(x0, z1), (x1, z1), (x1, z0), (x0, z0)]
	inner = [(x0 + rd, z1 - rd), (x1 - rd, z1 - rd), (x1 - rd, z0 + rd), (x0 + rd, z0 + rd)]
	S.floor_rim(outer, inner, E, E + jh, per_side=max(2, round(max(w, dd) / 0.6)))
	before = meshes()   # the dark stone bed inside the band (in place of the normal floor's timber joists)
	K.blk((0, E + jh / 2 + 0.003, 0), (w - 2 * E - 2 * rd - 0.01, jh - 0.006, dd - 2 * E - 2 * rd - 0.01), dark_stone(), bevel=0)
	tag(meshes() - before, "mortar")
	hx, hz = 0.45, 0.4    # the loose stone's opening
	fy0, fy1 = E + jh + 0.004, h - E
	for (a, b, c, e) in ((x0, x1, z0, -hz), (x0, x1, hz, z1), (x0, -hx, -hz, hz), (hx, x1, -hz, hz)):
		S.flagstones(a, b, c, e, fy0, fy1)
	# the loose stone: 4.5 cm of dark gap all round, resting on the bed, one corner up (round 2 of the wooden one:
	# a thin gap and a low corner didn't read as loose)
	stone = S.block((J(0.01), (fy0 + 0.006 + fy1 + 0.008) / 2, J(0.01)), (2 * hx - 0.09, fy1 + 0.008 - fy0 - 0.006, 2 * hz - 0.09),
		cut=0.04, tilt=0.0, dent=0.014, free="y")
	stone.rotation_euler.x += math.radians(2.6)
	stone.rotation_euler.y += math.radians(2.0)
	stone.location.z += 0.012   # (Blender z = up: the raised corner a finger high, the low one still on the bed)
	frame = meshes() - {stone.name}
	return {"frame": frame, "stone": {stone.name}}


# ---------------------------------------------------------------- Hald's recipe stand (F856 🔁: no wood by a chest)
STAND_TILT = math.radians(20)        # = dungeon_rootwood.STAND_TILT: the scroll lies at the same spot and slant
STAND_PIVOT = (0.0, 0.90, -0.11)     # (= the wooden one's pivot after its STAND_DY drop)


def tilt_x(objs, theta, pivot):
	"""Turn finished parts about the game's x axis through `pivot` (game coords): + tips the top toward the front
	(= dungeon_rootwood.rot_x)."""
	from mathutils import Matrix
	piv = Vector(K.G(pivot))
	m = Matrix.Rotation(theta, 4, "X")
	for o in objs:
		o.data.transform(o.matrix_basis)
		o.matrix_basis = Matrix.Identity(4)
		for v in o.data.vertices:
			v.co = piv + (m @ (v.co - piv))


def recipe_stand_stone():
	"""The stone twin of dungeon_rootwood.recipe_stand, for the Tomb of Hald: a wide foot stone and a step, a square
	shaft of two cut stones, a head stone, and a slanted reading slab with a stone lip at its front. Its top is where
	the wooden one's is (the game lays the scroll at (0, 0.90, 0.007), tilted 20 degrees)."""
	S.block((0, 0.08, 0), (0.62, 0.16, 0.5), dark_stone(), cut=0.035, tilt=0.0, free="xz")
	S.block((J(0.005), 0.195, J(0.005)), (0.42, 0.08, 0.36), cut=0.03, tilt=0.0, free="xz")       # (5 mm into the foot)
	S.block((J(0.006), 0.39, J(0.006)), (0.22, 0.32, 0.22), cut=0.03, tilt=0.3, free="xz")         # the shaft
	S.block((J(0.006), 0.68, J(0.006)), (0.21, 0.27, 0.21), cut=0.03, tilt=0.3, free="xz")
	before = meshes()
	S.block((0, 0.832, -0.01), (0.32, 0.075, 0.24), dark_stone(), cut=0.025, tilt=0.0, free="xz")  # the head stone
	S.block((0, 0.90, 0.0), (0.6, 0.08, 0.44), cut=0.035, tilt=0.0, dent=0.01, free="xz")          # the reading slab, top at 0.94
	S.block((J(0.005), 0.962, 0.195), (0.56, 0.05, 0.05), dark_stone(), cut=0.015, tilt=0.0, free="xyz")  # the lip (5 mm into the slab)
	tilt_x([bpy.data.objects[n] for n in meshes() - before], STAND_TILT, STAND_PIVOT)


# ---------------------------------------------------------------- the dart wall and its wire (F853)
DART_HOLE = (0.12, 0.95)   # = dungeon_mine's hole = the game's MineTraps.DART_HOLE (x, y)


def bore_z(target, x, y, r, depth=0.8):
	"""Drill a round hole straight through `target` front to back (game z) at (x, y)."""
	bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=r, depth=depth, location=K.G((x, y, 0.0)),
		rotation=(math.radians(90), 0, 0))
	cut = bpy.context.object
	m = target.modifiers.new("bore", "BOOLEAN")
	m.operation, m.object, m.solver = "DIFFERENCE", cut, "EXACT"
	bpy.ops.object.select_all(action="DESELECT")
	target.select_set(True)
	bpy.context.view_layer.objects.active = target
	bpy.ops.object.modifier_apply(modifier=m.name)
	bpy.data.objects.remove(cut, do_unlink=True)


def trap_tripwire_wall_stone(w=2.0, h=2.0, d=0.3):
	"""Owner, Nov 20: no crossbow, just a small dark hole a poison bolt shoots out of. Nov 25: "it's still wooden":
	now the Tomb's own stone wall, the hole drilled through a stone and ringed with iron."""
	hx, hy = DART_HOLE
	before = set(bpy.data.objects)
	S.courses(w, h, d)
	made = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
	for o in made:
		if o.get("role") is None:
			o["role"] = "mortar"
	for o in made:   # drill every stone the hole passes through (the dark mortar sheet behind shows as the hole's dark)
		if o.get("role") != "stone":
			continue
		vs = [o.matrix_world @ v.co for v in o.data.vertices]
		if min(v.x for v in vs) - 0.04 < hx < max(v.x for v in vs) + 0.04 and min(v.z for v in vs) - 0.04 < hy < max(v.z for v in vs) + 0.04:
			bore_z(o, hx, hy, 0.026)
	front = d / 2 - E
	kit.ring(0.04, 0.011, K.G((hx, hy, front)), iron(), rot=(90, 0, 0), seg=14)   # the iron ring round the hole
	for a in (40, 160, 280):   # three rivets holding it
		kit.rivet(K.G((hx + 0.04 * math.cos(math.radians(a)), hy + 0.04 * math.sin(math.radians(a)), front + 0.012)), iron(), r=0.01)
	# the clue: a dark green poison stain run down the stone under the ring
	K.blk((hx + J(0.004), hy - 0.105, front - 0.002), (0.026, 0.09, 0.012), kit.mat("sprout", -0.25, rough=0.3), bevel=0.004)
	kit.ring(0.022, 0.006, K.G((hx, 0.15, front)), iron("a"), rot=(0, 90, 0), seg=10)  # the wire's eye, low down
	frame = {o.name for o in bpy.data.objects if o not in before and o.type == "MESH"}
	# the poison bolt waiting deep in the hole (the player's blight bolt from items_tools.py, its shape code only)
	from mathutils import Matrix
	path = Path(__file__).resolve().parent / "items_tools.py"
	src = path.read_text(encoding="utf-8")
	ns = {"__file__": str(path), "__name__": "items_tools_borrowed"}
	exec(compile(src[:src.index("ids = sys.argv")], str(path), "exec"), ns)
	b0 = meshes()
	ns["bolt"]("blight")
	new = [bpy.data.objects[n] for n in meshes() - b0]
	for o in new:
		o.data.transform(o.matrix_basis)
		o.matrix_basis = Matrix.Identity(4)
	M = Matrix.Translation(K.G((hx, hy, 0.09 - 0.6))) @ Matrix.Rotation(math.pi, 4, "Z") @ Matrix.Rotation(-math.pi / 2, 4, "X")
	for o in new:
		o.data.transform(M)
	return {"frame": frame, "bolt": {o.name for o in new}}


def tripwire_iron():
	"""The dart wall's wire in rusty iron: 1 m along x, origin in its middle (the game stretches it), two halves."""
	m = iron("a")
	groups = {}
	for name, a, b in (("wire_l", -0.5, 0.008), ("wire_r", -0.008, 0.5)):
		b0 = meshes()
		kit.cylinder(0.002, b - a, K.G(((a + b) / 2, 0.12, 0.0)), m, rot=(0, 90, 0), verts=6, bevel=0.0)
		groups[name] = meshes() - b0
	return groups



# ---------------------------------------------------------------- the Brassgate Vault's crossbow and push wall (F975)
def _cut_courses(w, h, d, x0, x1, keep):
	"""Stone courses with a rectangular opening x0..x1 through every row that `keep(ya, yb)` picks (rows stay whole
	stones; the opening's top and bottom follow the rows). Returns the opening (x0, x1, bottom, top) and the new parts.
	The dark backing sheet is cut 1 cm wider than the stones (no shimmer on the cut faces)."""
	rows = []

	def hole(ya, yb):
		if keep(ya, yb):
			rows.append((ya, yb))
			return (x0, x1)
		return None
	before = set(bpy.data.objects)
	S.courses(w, h, d, hole=hole, back=False)
	hb, ht = min(r[0] for r in rows), max(r[1] for r in rows)
	S.backing(K.Frame(oz=0.0), -w / 2 + E, w / 2 - E, E, h - E, d, hole=(x0 - 0.01, x1 + 0.01, hb - 0.01, ht + 0.01))
	made = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
	for o in made:
		if o.get("role") is None:
			o["role"] = "mortar"
	return (x0, x1, hb, ht), made


def trap_crossbow_wall_stone(w=2.0, h=2.0, d=0.3):
	"""Owner, Nov 28 (F975): "a thin wire across a hall; touching it fires a bolt from the wall". A guard slot (one
	course cut out, 0.5 m wide) at the dart hole's height, a dark hollow behind it, a crossbow in it aimed out."""
	hx, hy = DART_HOLE
	(x0, x1, hb, ht), made = _cut_courses(w, h, d, hx - 0.25, hx + 0.25, lambda ya, yb: ya < hy < yb)
	back = -d / 2 + E
	# the dark hollow behind the slot (the guard's room), its front 4 mm inside the stones' backs
	K.blk((hx, (hb + ht) / 2, back - 0.13 + 0.004), (x1 - x0 + 0.06, ht - hb + 0.06, 0.26), kit.mat("charcoal", -0.6), bevel=0.0)
	# the crossbow: a wooden stock on two iron cradles, its iron bow across near the front, the string drawn back
	wood = kit.tex_mat("wood", "dark")
	stock_y = hy - 0.035
	K.blk((hx, stock_y, back + 0.07), (0.05, 0.045, 0.24), wood, bevel=0.006)            # (its back in the hollow)
	for zz in (back + 0.02, back + 0.14):                                                  # cradles down to the slot's floor
		K.blk((hx, (hb + stock_y - 0.022) / 2, zz), (0.07, stock_y - 0.022 - hb + 0.004, 0.025), iron(), bevel=0.003)
	bz = back + 0.185
	for sgn in (-1, 1):   # the bow: two iron arms swept back from the stock's nose
		bar((hx, stock_y, bz), (hx + sgn * 0.2, stock_y, bz - 0.05), 0.016, iron(), deep=0.012)
		bar((hx + sgn * 0.2, stock_y, bz - 0.05), (hx, stock_y + 0.006, back + 0.03), 0.004, kit.mat("bone", -0.35), bevel=0.0)
	frame = {o.name for o in bpy.data.objects if o.type == "MESH"}
	# the bolt on the stock, its iron head just inside the slot (a plain iron crossbow bolt, no poison)
	b0 = meshes()
	L = 0.32
	tip_z = d / 2 - E - 0.03
	kit.cylinder(0.008, L, K.G((hx, hy, tip_z - 0.05 - L / 2)), kit.tex_mat("wood", "c"), rot=(90, 0, 0), verts=8, bevel=0.0)
	kit.cone(0.014, 0.002, 0.06, K.G((hx, hy, tip_z - 0.03)), iron("a"), rot=(90, 0, 0), verts=8, bevel=0.0)
	for fw, fh in ((0.05, 0.004), (0.004, 0.05)):   # two stiff crossed fins at its back
		K.blk((hx, hy, tip_z - 0.05 - L + 0.05), (fw, fh, 0.07), kit.mat("bone", 0.0), bevel=0.0)
	return {"frame": frame, "bolt": meshes() - b0}


PUSH_HOLE = (0.69, 0.23, 1.52)   # = dungeon_pell.PUSH_HOLE (half width, bottom, top), so MineTraps fits it
PUSH_DEPTH = 2.0                 # = dungeon_pell.PUSH_DEPTH: it slams out 1.8 m, its back stays in the rock


def trap_push_wall_stone(w=2.0, h=2.0, d=0.3):
	"""The stone twin of dungeon_pell.trap_push_wall: the rows round a 1.4 m opening, one huge ashlar block in it with
	a dark finger-wide gap all round (the only clue: owner, Nov 20, no scrape marks), 2 m deep into the rock."""
	hw, b0, b1 = PUSH_HOLE
	(x0, x1, hb, ht), made = _cut_courses(w, h, d, -hw, hw, lambda ya, yb: yb > b0 + 0.05 and ya < b1 - 0.05)
	front = d / 2 - E
	for sgn in (-1, 1):   # dark runners down the opening's sides, set back (what the block slides on)
		K.blk((sgn * (hw - 0.012), (hb + ht) / 2, -0.35), (0.024, ht - hb - 0.004, 0.6), kit.mat("charcoal", -0.6), bevel=0.002)
	frame = {o.name for o in bpy.data.objects if o.type == "MESH"}
	b4 = meshes()
	g = 0.022   # the gap round it
	core = S.block((0.0, (hb + ht) / 2, front - 0.01 - PUSH_DEPTH / 2), (2 * hw - 2 * g, ht - hb - 2 * g, PUSH_DEPTH - 0.02),
		cut=0.05, tilt=0.0, dent=0.02, free="")
	core["role"] = "stone"
	return {"frame": frame, "block": meshes() - b4}


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
	"wall_cracked_stone": wall_cracked_stone, "trap_chest_spikes_stone": trap_chest_spikes_stone,
	"floor_loose_flagstone": floor_loose_flagstone, "recipe_stand_stone": recipe_stand_stone,
	"trap_tripwire_wall_stone": trap_tripwire_wall_stone, "tripwire_iron": tripwire_iron,
	"trap_crossbow_wall_stone": trap_crossbow_wall_stone, "trap_push_wall_stone": trap_push_wall_stone}

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
