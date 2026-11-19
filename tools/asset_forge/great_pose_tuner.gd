extends SceneTree
## Tunes the great axe's key poses (DwarfGreatSwing, F389 round 5) by trying numbers instead of guessing: holds one
## key pose still (DwarfRig.great_fixed), measures the handle's room in front of his body, how far each fist misses
## its spot, the gap between the fists and where the weapon's head ends up, then keeps small random changes that
## score better. Prints the best poses ready to paste into dwarf_great_swing.gd.
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://tools/asset_forge/great_pose_tuner.gd
##     -- claude=pose_tuner [keys=Chop1,Sweep2] [tries=200] [probe=1]
## Heads: where the weapon's head should be (metres from his feet: x his right, y up, z his front).
## By the dwarf-animations Claude, chat 7, Nov 19, 2026.
const HEADS := {
	"Chop0": Vector3(0.35, 1.30, -0.15),  # wind-up: up behind his right shoulder
	"Chop1": Vector3(-0.10, 0.45, 0.85),  # hit: low in front of him, a little to his left
	"Chop2": Vector3(-0.45, 0.30, 0.65),  # follow-through: down past his left knee
	"Chop3": Vector3(-0.45, 0.30, 0.60),
	"Sweep0": Vector3(-0.45, 0.30, 0.60),  # from low on his left
	"Sweep1": Vector3(0.15, 0.65, 0.85),  # hit: in front, waist high
	"Sweep2": Vector3(0.80, 0.80, 0.25),  # follow-through: out to his right
	"Slam0": Vector3(0.30, 1.55, -0.25),  # wind-up: high over his right shoulder (his own head is in the way above)
	"Slam1": Vector3(0.0, 0.10, 0.90),  # hit: the ground ahead
	"Slam2": Vector3(0.0, 0.05, 0.90),
}
const ROOM := 0.035  ## m the handle should keep from his body
var model: DwarfModel
var frames := 0
var tries := 200
var keys: PackedStringArray = []
var probe := false
var tool_len := 1.0
var seed_prev := false  ## seed=1: a key may also start from the key before's best


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("tries="): tries = int(a.substr(6))
		if a.begins_with("keys="): keys = a.substr(5).split(",")
		if a == "probe=1": probe = true
		if a == "seed=1": seed_prev = true
	if keys.is_empty():
		keys = PackedStringArray(HEADS.keys())
	var w := Node3D.new()
	root.add_child(w)
	model = DwarfModel.new()
	w.add_child(model)
	await process_frame
	await process_frame
	model.set_held("axe_2h_copper")
	_run()


func _process(_d: float) -> bool:
	frames += 1
	if model and model.dwarf_rig:
		model.dwarf_rig.set_motion(0.0, true, false)
	return false


func _wait(n := 2) -> void:
	for i in n:
		await process_frame


## Holds `p` still and measures it.
func _measure(p: Dictionary) -> Dictionary:
	var rig := model.dwarf_rig
	rig.great_fixed = p
	await _wait()
	var f := rig.fist
	var dir := (f.fist_center - f.left_center).normalized()
	var end := f.left_center - dir * (f.fist_half + DwarfFist.STUB)
	var head := rig.global_transform.affine_inverse() * (end + dir * tool_len * 0.9)
	return {twist = p.twist, head_w = end + dir * tool_len * 0.9, room = f.clearance, part = f.clear_part, hair = f.clearance_hair, lm = f.left_miss, rm = f.right_miss,
		gap = f.left_gap, head = Vector3(head.x, head.y, -head.z)}


func _score(key: String, m: Dictionary) -> float:
	var s := 30.0 * maxf(0.0, ROOM - float(m.room)) + 8.0 * (float(m.lm) + float(m.rm))
	s += 1.5 * (m.head as Vector3).distance_to(HEADS[key])
	var want_gap := 0.08 if key in ["Slam1", "Slam2"] else 0.30
	s += 5.0 * maxf(0.0, want_gap - float(m.gap))
	s += 3.0 * maxf(0.0, 0.01 - float(m.hair))  # (braids may touch the handle: only a little)
	s += 0.012 * maxf(0.0, absf(float(m.twist)) - 45.0)  # (more twist than that looks like a corkscrew: legs don't turn)
	return s


static func _to_vec(p: Dictionary) -> PackedFloat32Array:
	var l: Vector3 = p.l
	var d: Vector3 = (p.d as Vector3).normalized()
	return PackedFloat32Array([l.x, l.y, l.z, d.x, d.y, d.z, p.gap, p.twist, p.lean])


static func _to_pose(v: PackedFloat32Array, edge: Vector3) -> Dictionary:
	return {l = Vector3(v[0], v[1], v[2]), d = Vector3(v[3], v[4], v[5]).normalized(), gap = clampf(v[6], 0.07, 0.45),
		twist = clampf(v[7], -75.0, 75.0), lean = clampf(v[8], -25.0, 40.0), edge = edge}


func _run() -> void:
	await _wait(40)
	var rig := model.dwarf_rig
	rig.fist.measure_clearance = true
	var tool: Node3D = rig.grip.get_child(rig.grip.get_child_count() - 1)
	var lo := INF
	var hi := -INF
	for mi: MeshInstance3D in tool.find_children("*", "MeshInstance3D", true, false):
		var bb := mi.get_aabb()
		lo = minf(lo, bb.position.y)
		hi = maxf(hi, bb.end.y)
	tool_len = (hi - lo) * tool.scale.y
	var st := await _measure(DwarfGreatSwing.STANCE)
	print("tool %.2f m. stance: room %d cm, gap %d cm, head %s" % [tool_len, roundi(st.room * 100), roundi(st.gap * 100), st.head])
	if probe:
		for key: String in keys:
			var mv := key.rstrip("0123456789")
			var p: Dictionary = DwarfGreatSwing.MOVES[mv][int(key.substr(mv.length()))][1]
			_print(key, p, await _measure(p))
		quit()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	const STEP := [0.03, 0.03, 0.03, 0.2, 0.2, 0.2, 0.04, 10.0, 6.0]
	var prev := {}  # the last key's best pose (the next key starts from it when that scores better)
	var moves := {}  # move -> [[key, pose, measure]...]
	for key: String in keys:
		var mv := key.rstrip("0123456789")
		var start: Dictionary = DwarfGreatSwing.MOVES[mv][int(key.substr(mv.length()))][1]
		var bm := await _measure(start)
		var bs := _score(key, bm)
		var best := _to_vec(start)
		if seed_prev and not prev.is_empty() and prev.mv == mv:
			var pm := await _measure(prev.pose)
			if _score(key, pm) < bs:
				bs = _score(key, pm)
				bm = pm
				best = _to_vec(prev.pose)
		var scale := 1.0
		for i in tries:
			var v := best.duplicate()
			for j in v.size():
				if rng.randf() < 0.5:
					v[j] += rng.randfn() * float(STEP[j]) * scale
			var m := await _measure(_to_pose(v, start.edge))
			var s := _score(key, m)
			if s < bs:
				bs = s
				best = v
				bm = m
			elif i % 40 == 39:
				scale = maxf(scale * 0.7, 0.25)
		var bp := _to_pose(best, start.edge)
		prev = {mv = mv, pose = bp}
		if not moves.has(mv):
			moves[mv] = []
		moves[mv].append([key, bp, bm])
	# the blade faces the way the head moves (from the key before to the key after), in each key's chest frame
	var rb := rig.global_basis.orthonormalized()
	for mv: String in moves:
		var list: Array = moves[mv]
		for i in list.size():
			var a: Vector3 = list[maxi(i - 1, 0)][2].head_w
			var b: Vector3 = list[mini(i + 1, list.size() - 1)][2].head_w
			var p: Dictionary = list[i][1]
			if a.distance_to(b) > 0.05:
				var q := Quaternion(rb.y, deg_to_rad(-float(p.twist))) * Quaternion(rb.x, deg_to_rad(-float(p.lean)))
				var e := (Basis(q) * rb).inverse() * (b - a).normalized()
				p.edge = Vector3(e.x, e.y, -e.z).snappedf(0.1)
			_print(list[i][0], p, list[i][2])
	quit()


func _print(key: String, p: Dictionary, m: Dictionary) -> void:
	print("%-7s room %2d cm (%s) braids %2d, miss L%2d R%2d, gap %2d, head %s want %s" % [key, roundi(m.room * 100),
		m.part, roundi(m.hair * 100), roundi(m.lm * 100), roundi(m.rm * 100), roundi(m.gap * 100),
		(m.head as Vector3).snappedf(0.01), HEADS.get(key, Vector3.ZERO)])
	var l: Vector3 = p.l
	var d: Vector3 = p.d
	var e: Vector3 = p.edge
	print("    {l = Vector3(%.2f, %.2f, %.2f), d = Vector3(%.2f, %.2f, %.2f), gap = %.2f, twist = %.1f, lean = %.1f," % [
		l.x, l.y, l.z, d.x, d.y, d.z, p.gap, p.twist, p.lean])
	print("        edge = Vector3(%.1f, %.1f, %.1f)}" % [e.x, e.y, e.z])
