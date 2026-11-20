class_name DwarfGreatSwing
extends RefCounted
## How the dwarf holds and swings the great axe and the great maul (F389 round 5, owner Nov 19, from a photo of a
## warrior with a long axe and the "Dwarf Fighting Poses" page): hand-made key poses, no animation pack.
##  - The LEFT fist always sits at the very end of the handle (the hinge). The RIGHT fist sits higher up the handle,
##    wide apart (owner: "his hands should be wide; the only time they get close is the slam").
##  - Each key pose says where the left fist is, which way the handle points from it, how far up the right fist sits,
##    how far his chest twists and leans, and how far his knees bend (`knee`: m the hips drop) and his hips go forward
##    (`fwd`, the lunge). DwarfFist bends both arms to reach the fists (two-bone reach), lays the handle through them,
##    and keeps his feet planted while the hips turn and drop.
##  - His arms are short (44 cm from shoulder to fist) and his chest is round, so where the right fist can't reach
##    its spot, it slides down the handle toward the left one, like a real fighter's top hand.
## Body coordinates: metres from the chest bone (spine_03), x = his right, y = up, z = his front, in the chest's own
## frame after the twist (+ = chest turned to his right) and the lean (+ = bent forward).
## Swings (owner's pick): A slanting chop from his right shoulder down past his left knee, B a low sweep back out
## to his right, C an overhead slam (the right hand slides down to the left). They take turns A, B, C.
## Targets: docs/art/2h-reference/great_axe_poses_side.jpg (until the owner's own video, tools/mocap/).
## By the dwarf-animations Claude, chats 6-8, Nov 19-20, 2026.

## "Hips lead, knees bend" (docs/art/ANIMATION-RULES.md 4): the hips take this share of the chest's twist and lean,
## LEAD of the swing ahead of the chest (they start turning first); the spine takes the rest.
const HIP_TWIST := 0.4
const HIP_LEAN := 0.3
const LEAD := 0.06

## The ready stance (the owner's photo): left fist low by his left hip, right fist up in front of his right shoulder,
## the handle slanting across his body with the head beside his right shoulder, blade facing forward. Knees soft.
const STANCE := {l = Vector3(-0.20, -0.20, 0.36), d = Vector3(0.40, 0.30, 0.0), gap = 0.42, twist = 0.0, lean = 0.0,
	edge = Vector3(0, 0.2, 1), knee = 0.03, fwd = 0.0}

## The swings: [time (share of the swing, 0..1), pose, how it moves]. The first key is wherever he is when the swing
## starts. The hit lands at 0.40 (DwarfFight._impact); a light swing lasts 1.1 s, a heavy one 1.9 s.
## How it moves: hold = share of the swing he stays still at the top; through = a middle key he swings through without
## slowing (it only bends the arc); ease "in" = speeds up into the key (the strike), "out" = slows down after it.
## Timing (rules 4, light swing): wind-up 0.30 s (the chop and slam lift the axe forward first, at 0.13: else the
## handle cut through his belly on the way up, chat 8), hold 0.04 s, strike 0.10 s, recovery 0.38 s, back to the stance.
## `edge` = which way the blade faces (the way the head moves at that moment).
const MOVES := {
	# Numbers found by tools/asset_forge/great_pose_tuner.gd (fists on their spots, handle clear of his body, head where
	# the reference sheet puts it), chat 8.
	"Chop": [  # A: up behind his right shoulder -> down in front of him, past his left knee
		[0.13, {l = Vector3(-0.02, -0.05, 0.36), d = Vector3(0.68, 0.71, -0.18), gap = 0.30, twist = -11.4, lean = -4.3,
			edge = Vector3(-0.1, 0.1, -1.0), knee = 0.03, fwd = -0.01}, {through = true}],
		[0.27, {l = Vector3(0.25, -0.16, -0.18), d = Vector3(0.13, 0.47, -0.87), gap = 0.36, twist = -52.6, lean = 19.6,
			edge = Vector3(0.4, -0.2, 0.9), knee = 0.02, fwd = -0.03}, {hold = 0.04}],
		[0.36, {l = Vector3(-0.05, -0.01, -0.07), d = Vector3(0.96, 0.27, 0.02), gap = 0.44, twist = -75.0, lean = -8.4,
			edge = Vector3(0.6, -0.7, 0.5), knee = 0.04, fwd = 0.01}, {through = true}],
		[0.40, {l = Vector3(-0.11, 0.06, 0.27), d = Vector3(0.98, -0.10, 0.19), gap = 0.40, twist = -67.2, lean = 40.0,
			edge = Vector3(0.0, -0.3, 1.0), knee = 0.08, fwd = 0.06}, {ease = "in"}],
		[0.75, {l = Vector3(-0.23, 0.02, 0.13), d = Vector3(0.82, -0.24, 0.52), gap = 0.38, twist = -73.5, lean = 16.9,
			edge = Vector3(-0.7, 0.1, 0.7), knee = 0.06, fwd = 0.04}, {ease = "out"}],
		[1.00, STANCE, {}],
	],
	"Sweep": [  # B: from low on his left, back across low in front of him and out to his right
		[0.27, {l = Vector3(-0.25, 0.03, 0.06), d = Vector3(0.74, -0.07, 0.67), gap = 0.44, twist = -75.0, lean = 9.8,
			edge = Vector3(0.6, -0.5, -0.7), knee = 0.05, fwd = -0.02}, {hold = 0.04}],
		[0.36, {l = Vector3(-0.29, 0.02, 0.20), d = Vector3(0.93, -0.17, 0.33), gap = 0.39, twist = -74.2, lean = 15.0,
			edge = Vector3(0.6, -0.4, -0.7), knee = 0.06, fwd = 0.02}, {through = true}],
		[0.40, {l = Vector3(-0.10, 0.21, 0.25), d = Vector3(0.91, -0.29, 0.30), gap = 0.40, twist = -52.2, lean = 22.9,
			edge = Vector3(0.5, -0.3, -0.9), knee = 0.08, fwd = 0.05}, {ease = "in"}],
		[0.75, {l = Vector3(-0.20, 0.05, 0.34), d = Vector3(0.99, -0.16, -0.06), gap = 0.40, twist = -30.7, lean = 21.5,
			edge = Vector3(0.4, -0.1, -0.9), knee = 0.05, fwd = 0.03}, {ease = "out"}],
		[1.00, STANCE, {}],
	],
	"Slam": [  # C: the axe straight up over his head, then down into the ground ahead; the right hand slides down
		[0.13, {l = Vector3(-0.06, 0.01, 0.42), d = Vector3(0.52, 0.69, -0.50), gap = 0.45, twist = -24.9, lean = 11.6,
			edge = Vector3(-0.7, 0.0, -0.7), knee = 0.02, fwd = -0.02}, {through = true}],
		[0.27, {l = Vector3(0.06, 0.28, 0.53), d = Vector3(0.23, 0.43, -0.87), gap = 0.33, twist = 50.6, lean = 30.3,
			edge = Vector3(-0.8, 0.1, 0.5), knee = 0.00, fwd = -0.04}, {hold = 0.04}],
		[0.36, {l = Vector3(0.10, 0.02, 0.09), d = Vector3(0.72, 0.68, -0.13), gap = 0.27, twist = -68.5, lean = 29.0,
			edge = Vector3(0.7, -0.5, 0.6), knee = 0.04, fwd = 0.00}, {through = true}],
		[0.40, {l = Vector3(0.11, 0.11, 0.45), d = Vector3(0.96, -0.26, -0.11), gap = 0.14, twist = -75.0, lean = 39.6,
			edge = Vector3(0.1, -0.9, 0.5), knee = 0.10, fwd = 0.06}, {ease = "in"}],
		[0.75, {l = Vector3(0.04, 0.20, 0.27), d = Vector3(0.91, -0.36, 0.22), gap = 0.13, twist = -67.6, lean = 40.0,
			edge = Vector3(-0.3, -0.7, -0.6), knee = 0.08, fwd = 0.05}, {ease = "out"}],
		[1.00, STANCE, {}],
	],
}
const RETURN := 6.0  ## how fast he eases back to the stance after a swing (per second)


## A pose part of the way from `a` to `b` (k 0..1).
static func blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var p := {l = (a.l as Vector3).lerp(b.l, k), d = (a.d as Vector3).normalized().slerp((b.d as Vector3).normalized(), k),
		gap = lerpf(a.gap, b.gap, k), twist = lerpf(a.twist, b.twist, k), lean = lerpf(a.lean, b.lean, k),
		edge = (a.edge as Vector3).normalized().slerp((b.edge as Vector3).normalized(), k),
		knee = lerpf(a.get("knee", 0.0), b.get("knee", 0.0), k), fwd = lerpf(a.get("fwd", 0.0), b.get("fwd", 0.0), k)}
	if a.has("hip") or b.has("hip"):
		p.hip = lerpf(a.get("hip", HIP_TWIST * float(a.twist)), b.get("hip", HIP_TWIST * float(b.twist)), k)
		p.hip_lean = lerpf(a.get("hip_lean", HIP_LEAN * float(a.lean)), b.get("hip_lean", HIP_LEAN * float(b.lean)), k)
	return p


## The pose `t` (0..1) into a swing that started from `from`, the hips LEAD ahead of the chest. `keys` = other key
## poses to use instead of MOVES[move] (the tuner trying numbers).
static func pose(move: String, t: float, from: Dictionary, keys: Array = []) -> Dictionary:
	var line := _timeline(keys if not keys.is_empty() else MOVES.get(move, []), from)
	var p := _at(line, t)
	var ahead := _at(line, minf(t + LEAD, 1.0))
	p.hip = HIP_TWIST * float(ahead.twist)
	p.hip_lean = HIP_LEAN * float(ahead.lean)
	return p


## The keys as a timeline: [time, pose, opts], the start pose first and each hold as a second, still key.
static func _timeline(keys: Array, from: Dictionary) -> Array:
	var line: Array = [[0.0, from, {}]]
	for key: Array in keys:
		var opts: Dictionary = key[2] if key.size() > 2 else {}
		line.append([float(key[0]), key[1], opts])
		if opts.has("hold"):
			line.append([float(key[0]) + float(opts.hold), key[1], {}])
	return line


## ---- The owner's own poses (F389, Nov 20: "I'll pose him by hand in Blender") ----
## tools/blender_poses/great_axe_poses.blend -> read_poses.py -> POSED_FILE: per swing 5 key poses (ready, wind-up
## top, middle, hit, recovery), each bone's turn as he set it. Played as they are, on the timing above (rules 4):
## wind-up to 0.27, a 0.04 hold, through the middle to the hit at 0.40 (speeding up), recovery to 0.75 (slowing),
## back to the ready pose at 1.0. A swing he hasn't posed yet keeps the old key poses (MOVES).
const POSED_FILE := "res://assets/anim/great_axe_poses.json"
const POSED_TIMES := {windup = [0.27, {hold = 0.04}], middle = [0.36, {through = true}], hit = [0.40, {ease = "in"}],
	recovery = [0.75, {ease = "out"}]}
static var _posed: Dictionary = {}  ## move -> [ready pose, [[time, pose, opts], ...]]
static var _posed_loaded := false


static func _load_posed() -> void:
	_posed_loaded = true
	if not FileAccess.file_exists(POSED_FILE):
		return
	var all: Variant = JSON.parse_string(FileAccess.get_file_as_string(POSED_FILE))
	if not all is Dictionary:
		return
	for move: String in all:
		if move.begins_with("_") or not all[move] is Array:
			continue
		var ready := {}
		var keys: Array = []
		for k: Dictionary in all[move]:
			var bones := {}
			for b: String in k.bones:
				var q: Array = k.bones[b]
				bones[b] = Quaternion(q[0], q[1], q[2], q[3]).normalized()
			var a: Array = k.axe
			var pp: Array = k.pelvis_pos
			var pose := {bones = bones, pelvis = Vector3(pp[0], pp[1], pp[2]), slide = float(k.left_slide),
				axe = Basis(Vector3(a[0], a[1], a[2]), Vector3(a[3], a[4], a[5]), Vector3(a[6], a[7], a[8])).orthonormalized()}
			if k.name == "ready":
				ready = pose
			elif POSED_TIMES.has(k.name):
				keys.append([float(POSED_TIMES[k.name][0]), pose, POSED_TIMES[k.name][1]])
		if not ready.is_empty():
			keys.append([1.0, ready, {}])
			_posed[move] = [ready, keys]


## True if the owner has posed this swing ("" = the ready stance: any posed swing gives one).
static func has_posed(move: String) -> bool:
	if not _posed_loaded:
		_load_posed()
	return not _posed.is_empty() if move == "" else _posed.has(move)


## The owner's ready pose (the Chop's, else the first posed swing's).
static func posed_ready() -> Dictionary:
	if not has_posed(""):
		return {}
	return (_posed.get("Chop", _posed.values()[0]) as Array)[0]


## The owner's pose `t` (0..1) into his swing `move`, started from the pose `from`.
static func posed_pose(move: String, t: float, from: Dictionary) -> Dictionary:
	if not has_posed(move):
		return {}
	return _at(_timeline((_posed[move] as Array)[1], from), t, true)


## A posed pose part of the way from `a` to `b`: every bone turns the short way, the hips and the grip slide.
static func blend_posed(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var bones := {}
	for n: String in b.bones:
		bones[n] = (a.bones.get(n, b.bones[n]) as Quaternion).slerp(b.bones[n], k)
	return {bones = bones, pelvis = (a.pelvis as Vector3).lerp(b.pelvis, k), slide = lerpf(a.slide, b.slide, k),
		axe = Basis((a.axe as Basis).get_rotation_quaternion().slerp((b.axe as Basis).get_rotation_quaternion(), k))}


static func _at(line: Array, t: float, posed := false) -> Dictionary:
	# the stretch between two keys he stops at (through keys inside it only bend the arc)
	var a := 0
	for i in line.size():
		if float(line[i][0]) <= t and not (line[i][2] as Dictionary).get("through", false):
			a = i
	var b := a + 1
	while b < line.size() and (line[b][2] as Dictionary).get("through", false):
		b += 1
	if b >= line.size():
		return (line[line.size() - 1][1] as Dictionary).duplicate()  # (a copy: the key poses are constants)
	var ta: float = line[a][0]
	var tb: float = line[b][0]
	var u := clampf((t - ta) / maxf(tb - ta, 0.001), 0.0, 1.0)
	match (line[b][2] as Dictionary).get("ease", ""):
		"in": u = u * u  # (speeds up into the key: the strike)
		"out": u = 1.0 - (1.0 - u) * (1.0 - u)  # (fast at first, then slows: the weight pulls him past the hit)
		_: u = u * u * (3.0 - 2.0 * u)  # (slow at both keys, fast between)
	var v := ta + u * (tb - ta)
	for i in range(a, b):
		var t0: float = line[i][0]
		var t1: float = line[i + 1][0]
		if v <= t1 or i == b - 1:
			var kk := clampf((v - t0) / maxf(t1 - t0, 0.001), 0.0, 1.0)
			return blend_posed(line[i][1], line[i + 1][1], kk) if posed else blend(line[i][1], line[i + 1][1], kk)
	return (line[b][1] as Dictionary).duplicate()
