extends SceneTree
## Tunes the great axe's key poses (DwarfGreatSwing, F389 round 5) by trying numbers instead of guessing: holds one
## key pose still (DwarfRig.great_fixed), measures the handle's room in front of his body, how far each fist misses
## its spot, the gap between the fists and where the weapon's head ends up, then keeps small random changes that
## score better. Prints the best poses ready to paste into dwarf_great_swing.gd.
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . --script res://tools/asset_forge/great_pose_tuner.gd
##     -- claude=pose_tuner [keys=Chop1,Sweep2] [tries=200] [probe=1] [check=1] [write=1]
## probe=1: only measure the keys as they are. check=1: measure every swing at its keys and at 10 moments in between
## (the rules' check, docs/art/ANIMATION-RULES.md 5).
## Middle keys (through) are tuned last, together with the moments around them (the strike's path).
## Heads: where the weapon's head should be (metres from his feet: x his right, y up, z his front), from the reference
## sheet docs/art/2h-reference/great_axe_poses_side.jpg (chat 8).
## By the dwarf-animations Claude, chats 7-8, Nov 19-20, 2026.
const HEADS := {
	"Chop0": Vector3(0.50, 1.62, -0.08),  # lifting: straight up above his right shoulder (upright before the fist pulls in)
	"Slam0": Vector3(0.40, 1.55, 0.15),  # lifting: up in front of his right shoulder
	"Chop1": Vector3(0.30, 1.45, -0.25),  # wind-up: high up behind his right shoulder
	"Chop3": Vector3(-0.05, 0.25, 0.90),  # hit: low in front of him (the lunge)
	"Chop4": Vector3(-0.40, 0.20, 0.70),  # recovery: pulled on past his left knee
	"Chop2": Vector3(0.30, 1.10, 0.50),  # middle: out in front over his right shoulder, on the way down
	"Sweep0": Vector3(-0.55, 0.45, 0.25),  # wind-up: low out to his left (the sheet has it behind him: his arms are too short)
	"Sweep2": Vector3(0.10, 0.30, 0.90),  # hit: low in front
	"Sweep3": Vector3(0.55, 0.45, 0.55),  # recovery: out to his right, in front
	"Sweep1": Vector3(-0.30, 0.35, 0.70),  # middle: low in front, to his left
	"Slam1": Vector3(0.10, 1.65, -0.30),  # wind-up: straight up over his head, a little behind
	"Slam3": Vector3(0.0, 0.05, 0.90),  # hit: the ground ahead (deep knees)
	"Slam4": Vector3(0.05, 0.10, 0.85),
	"Slam2": Vector3(0.05, 1.30, 0.55),  # middle: high in front, on the way down
}
const ROOM := 0.035  ## m the handle should keep from his body
const NEAR := 0.02  ## m a fist may miss its spot
var model: DwarfModel
var frames := 0
var tries := 200
var keys: PackedStringArray = []
var probe := false
var check := false
var at_moments: PackedStringArray = []  ## at=Chop:0.15,Slam:0.25: measure those moments of a swing and stop
var write := false  ## write=1: put the tuned poses into dwarf_great_swing.gd
var tool_len := 1.0
var cur := {}  ## move -> its key list as tuned so far ([t, pose, opts])


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("tries="): tries = int(a.substr(6))
		if a.begins_with("keys="): keys = a.substr(5).split(",")
		if a == "probe=1": probe = true
		if a == "check=1": check = true
		if a == "write=1": write = true
		if a.begins_with("at="): at_moments = a.substr(3).split(",")
	if keys.is_empty():
		keys = PackedStringArray(HEADS.keys())
	for mv: String in DwarfGreatSwing.MOVES:
		cur[mv] = (DwarfGreatSwing.MOVES[mv] as Array).duplicate(true)
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
		gap = f.left_gap, head = Vector3(head.x, head.y, -head.z), feet = f.feet_miss}


func _score(key: String, m: Dictionary) -> float:
	var s := 30.0 * maxf(0.0, ROOM - float(m.room)) + 8.0 * (float(m.lm) + float(m.rm))
	s += 1.5 * (m.head as Vector3).distance_to(HEADS[key])
	var want_gap := 0.08 if key in ["Slam3", "Slam4"] else (0.15 if key == "Slam2" else 0.30)
	s += 5.0 * maxf(0.0, want_gap - float(m.gap))
	if key in ["Slam3", "Slam4"]:  # (the slam: hands close, the right one slid down)
		s += 3.0 * maxf(0.0, float(m.gap) - 0.18)
	s += 3.0 * maxf(0.0, 0.01 - float(m.hair))  # (braids may touch the handle: only a little)
	# (more spine twist than that looks like a corkscrew: the hips only take their share)
	s += 0.012 * maxf(0.0, absf(float(m.twist)) * (1.0 - DwarfGreatSwing.HIP_TWIST) - 40.0)
	return s


## The moments on both sides of key `idx` (12 each, from the key before to the key after): the handle's room and the
## fists, as a score (chat 8: the chop and slam touched him on the way up to the wind-up, not only on the way down).
func _between_score(mv: String, list: Array, idx: int) -> float:
	var s := 0.0
	var hold := func(i: int) -> float: return float((list[i][2] as Dictionary).get("hold", 0.0))
	var before: float = 0.0 if idx == 0 else float(list[idx - 1][0]) + hold.call(idx - 1)
	var at: float = list[idx][0]
	var after: float = at + hold.call(idx)
	var next: float = list[mini(idx + 1, list.size() - 1)][0]
	var ts: Array[float] = []
	for n in 12:  # (12 a side: the strike covers most of its arc in the last 2% of the swing; 3 and 6 missed dips)
		var k := (float(n) + 1.0) / 13.0
		ts.append(lerpf(before, at, k))
		if next > after:
			ts.append(lerpf(after, next, k))
	for t in ts:
		var m := await _measure(DwarfGreatSwing.pose(mv, t, DwarfGreatSwing.STANCE, list))
		s += 30.0 * maxf(0.0, ROOM - float(m.room)) + 8.0 * maxf(0.0, float(m.lm) + float(m.rm) - NEAR)
	return s


static func _to_vec(p: Dictionary) -> PackedFloat32Array:
	var l: Vector3 = p.l
	var d: Vector3 = (p.d as Vector3).normalized()
	return PackedFloat32Array([l.x, l.y, l.z, d.x, d.y, d.z, p.gap, p.twist, p.lean])


static func _to_pose(v: PackedFloat32Array, start: Dictionary) -> Dictionary:
	return {l = Vector3(v[0], v[1], v[2]), d = Vector3(v[3], v[4], v[5]).normalized(), gap = clampf(v[6], 0.07, 0.45),
		twist = clampf(v[7], -75.0, 75.0), lean = clampf(v[8], -25.0, 40.0), edge = start.edge,
		knee = start.get("knee", 0.0), fwd = start.get("fwd", 0.0)}


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
	print("tool %.2f m. stance: room %d cm, gap %d cm, head %s, feet off %d cm" % [tool_len, roundi(st.room * 100),
		roundi(st.gap * 100), st.head, roundi(st.feet * 100)])
	if not at_moments.is_empty():
		for am in at_moments:
			var mv := am.get_slice(":", 0)
			var m := await _measure(DwarfGreatSwing.pose(mv, float(am.get_slice(":", 1)), DwarfGreatSwing.STANCE, cur[mv]))
			var f := model.dwarf_rig.fist
			var inv := model.dwarf_rig.global_transform.affine_inverse()
			var lf := inv * f.left_center
			var rf := inv * f.fist_center
			print("%s room %.1f cm (%s, %d cm up the handle) shapes %d pushed %.1f cm miss L%.0f R%.0f head %s  L %s R %s" % [am, m.room * 100, m.part, roundi(f.clear_along * 100), f._shapes.size(), f.keep_push * 100, m.lm * 100, m.rm * 100, (m.head as Vector3).snappedf(0.01), Vector3(lf.x, lf.y, -lf.z).snappedf(0.01), Vector3(rf.x, rf.y, -rf.z).snappedf(0.01)])
		quit()
		return
	if check:
		await _check_all()
		quit()
		return
	if probe:
		for key: String in keys:
			var mv := key.rstrip("0123456789")
			_print(key, cur[mv][int(key.substr(mv.length()))][1], await _measure(cur[mv][int(key.substr(mv.length()))][1]))
		quit()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	const STEP := [0.03, 0.03, 0.03, 0.2, 0.2, 0.2, 0.04, 10.0, 6.0]
	var moves := {}  # move -> {index: [key, pose, measure]}
	var order: Array[String] = []
	for key: String in keys:  # (middle keys last: their score needs the keys on both sides)
		var mv := key.rstrip("0123456789")
		var passes: bool = ((cur[mv][int(key.substr(mv.length()))] as Array)[2] as Dictionary).get("through", false)
		if not passes:
			order.append(key)
	for key: String in keys:
		if not order.has(key):
			order.append(key)
	for key: String in order:
		var mv := key.rstrip("0123456789")
		var idx := int(key.substr(mv.length()))
		var start: Dictionary = cur[mv][idx][1]
		var bm := await _measure(start)
		var bs := _score(key, bm)
		bs += await _between_score(mv, cur[mv], idx)
		var best := _to_vec(start)
		var scale := 1.0
		for i in tries:
			var v := best.duplicate()
			for j in v.size():
				if rng.randf() < 0.5:
					v[j] += rng.randfn() * float(STEP[j]) * scale
			var cand := _to_pose(v, start)
			var m := await _measure(cand)
			var s := _score(key, m)
			if s < bs:  # (only worth the slow check when the key itself already scores better)
				var list: Array = (cur[mv] as Array).duplicate()
				list[idx] = [cur[mv][idx][0], cand, cur[mv][idx][2]]
				s += await _between_score(mv, list, idx)
			if s < bs:
				bs = s
				best = v
				bm = m
			elif i % 40 == 39:
				scale = maxf(scale * 0.7, 0.25)
		var bp := _to_pose(best, start)
		cur[mv][idx] = [cur[mv][idx][0], bp, cur[mv][idx][2]]
		if not moves.has(mv):
			moves[mv] = {}
		moves[mv][idx] = [key, bp, bm]
	# the blade faces the way the head moves (from the key before to the key after), in each key's chest frame
	var rb := rig.global_basis.orthonormalized()
	for mv: String in moves:
		var idxs: Array = (moves[mv] as Dictionary).keys()
		idxs.sort()
		for n in idxs.size():
			var a: Vector3 = moves[mv][idxs[maxi(n - 1, 0)]][2].head_w
			var b: Vector3 = moves[mv][idxs[mini(n + 1, idxs.size() - 1)]][2].head_w
			var p: Dictionary = moves[mv][idxs[n]][1]
			if a.distance_to(b) > 0.05:
				var q := Quaternion(rb.y, deg_to_rad(-float(p.twist))) * Quaternion(rb.x, deg_to_rad(-float(p.lean)))
				var e := (Basis(q) * rb).inverse() * (b - a).normalized()
				p.edge = Vector3(e.x, e.y, -e.z).snappedf(0.1)
			_print(moves[mv][idxs[n]][0], p, moves[mv][idxs[n]][2])
	await _check_all()
	if write:
		_write_moves()
	quit()


## write=1: puts the tuned key poses into dwarf_great_swing.gd (its MOVES block), so nothing is copied by hand.
const SWING_FILE := "res://src/player/dwarf_great_swing.gd"
const MOVE_NOTES := {"Chop": "A: up behind his right shoulder -> down in front of him, past his left knee",
	"Sweep": "B: from low on his left, back across low in front of him and out to his right",
	"Slam": "C: the axe straight up over his head, then down into the ground ahead; the right hand slides down"}
func _write_moves() -> void:
	var text := FileAccess.get_file_as_string(SWING_FILE)
	var a := text.find("const MOVES := {")
	var b := text.find("\nconst RETURN")
	if a < 0 or b < a:
		print("write: MOVES block not found, nothing written")
		return
	var head_end := text.find("\n\t\"", a)  # (keep the comment lines at the top of the block)
	var out := text.substr(0, head_end + 1)
	for mv: String in cur:
		out += "\t\"%s\": [  # %s\n" % [mv, MOVE_NOTES.get(mv, "")]
		for key: Array in cur[mv]:
			var p: Dictionary = key[1]
			var opts := _opts_text(key[2])
			if float(key[0]) >= 1.0:  # (the last key is always the stance)
				out += "\t\t[%.2f, STANCE, %s],\n" % [key[0], opts]
				continue
			var l: Vector3 = p.l
			var d: Vector3 = (p.d as Vector3).normalized()
			var e: Vector3 = p.edge
			out += "\t\t[%.2f, {l = Vector3(%.2f, %.2f, %.2f), d = Vector3(%.2f, %.2f, %.2f), gap = %.2f, twist = %.1f, lean = %.1f,\n" % [
				key[0], l.x, l.y, l.z, d.x, d.y, d.z, p.gap, p.twist, p.lean]
			out += "\t\t\tedge = Vector3(%.1f, %.1f, %.1f), knee = %.2f, fwd = %.2f}, %s],\n" % [e.x, e.y, e.z,
				p.get("knee", 0.0), p.get("fwd", 0.0), opts]
		out += "\t],\n"
	out += "}" + text.substr(b)
	var f := FileAccess.open(SWING_FILE, FileAccess.WRITE)
	f.store_string(out)
	f.close()
	print("write: MOVES written to ", SWING_FILE)


static func _opts_text(o: Dictionary) -> String:
	var parts: PackedStringArray = []
	if o.has("hold"): parts.append("hold = %.2f" % o.hold)
	if o.get("through", false): parts.append("through = true")
	if o.has("ease"): parts.append("ease = \"%s\"" % o.ease)
	return "{%s}" % ", ".join(parts)


## The rules' check: every swing at its keys and at 120 moments in between (from the stance).
func _check_all() -> void:
	for mv: String in cur:
		var worst := INF
		var worst_t := 0.0
		var worst_miss := 0.0
		var miss_t := 0.0
		var ts: Array[float] = []
		for i in 120:  # (about one per frame of a light swing: the strike is too fast for 10)
			ts.append((float(i) + 0.5) / 120.0)
		for key: Array in cur[mv]:
			ts.append(float(key[0]))
		for t in ts:
			var m := await _measure(DwarfGreatSwing.pose(mv, t, DwarfGreatSwing.STANCE, cur[mv]))
			if float(m.room) < worst:
				worst = m.room
				worst_t = t
			if maxf(m.lm, m.rm) > worst_miss:
				worst_miss = maxf(m.lm, m.rm)
				miss_t = t
		print("CHECK %-6s least handle room %d cm at %d%%, worst fist miss %d cm at %d%%  %s" % [mv, roundi(worst * 100),
			roundi(worst_t * 100), roundi(worst_miss * 100), roundi(miss_t * 100),
			"ok" if worst >= 0.03 and worst_miss <= NEAR else "FAILS"])


func _print(key: String, p: Dictionary, m: Dictionary) -> void:
	print("%-7s room %2d cm (%s) braids %2d, miss L%2d R%2d, gap %2d, feet %d, head %s want %s" % [key, roundi(m.room * 100),
		m.part, roundi(m.hair * 100), roundi(m.lm * 100), roundi(m.rm * 100), roundi(m.gap * 100), roundi(m.feet * 100),
		(m.head as Vector3).snappedf(0.01), HEADS.get(key, Vector3.ZERO)])
	var l: Vector3 = p.l
	var d: Vector3 = p.d
	var e: Vector3 = p.edge
	print("    {l = Vector3(%.2f, %.2f, %.2f), d = Vector3(%.2f, %.2f, %.2f), gap = %.2f, twist = %.1f, lean = %.1f," % [
		l.x, l.y, l.z, d.x, d.y, d.z, p.gap, p.twist, p.lean])
	print("        edge = Vector3(%.1f, %.1f, %.1f), knee = %.2f, fwd = %.2f}" % [e.x, e.y, e.z, p.get("knee", 0.0), p.get("fwd", 0.0)])
