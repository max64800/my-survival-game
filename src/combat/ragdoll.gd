class_name Ragdoll
## When a creature dies it goes limp (owner, Nov 18; the Rock Beetle first, data.ragdoll): it keeps the speed it had
## (killed in a charge, it flies on and tumbles), falls, and lies there with its legs spread out flat, its jaws fallen
## open, its feelers drooping and its eyes closed; later it shrinks away.
##
## How (round 4, the round-2 fall the owner preferred): ONE rigid body with the whole creature's shape (a box per part)
## falls and tumbles; the parts relax into the dead pose by themselves (eased, no joints). The legs spread OUTWARD and a
## little down (round 2 turned them up: they went into the shell). Round 6 (owner's drawing): a leg with a knee (a
## "shin" child, made by sculpt_test_beetle.py) reaches out and down to the floor and its lower half lies flat on the
## ground; the body box is full height (at 85% the shell sank into the floor). Eyes: eyelids shut; a creature without eyelids
## gets its eyeballs painted the colour of its lids. Tried and dropped: a body per part held by joints (round 1: the
## joints fought each other and shivered), and a flip onto its back with curled legs (round 3: the owner preferred
## this). Only looks: every player's computer runs its own copy (like the dust and stone chips).

const LAYER := 128           ## corpses: they fall on the cave and on built pieces, never block players or monsters
const LIFETIME := 8.0        ## seconds before it shrinks away
const RELAX_TIME := 0.6      ## seconds for the legs to spread and the jaws to fall open
const MASS := 20.0
const DRAPE_AT := 0.5        ## seconds before it starts waiting to lie still; then its wings fall onto the floor (owner: "it sticks out")
const LID_COLOR := Color(0.33, 0.21, 0.14)  ## closed eyes on a creature without eyelids (data.lid_color overrides)


## Turns a dead monster's model into a ragdoll. `velocity` = how it was moving when it died (a charge flies on).
## Returns false when the model can't. A creature still on an older model made of simple shapes (balls, tubes, boxes:
## no "body" part, no joints) falls the same way as one solid piece (owner, Nov 18: "for the rest of the creatures").
## `statue` >= 0: it becomes that stone statue once it lies still (Statue), instead of shrinking away.
static func make(m: Node3D, model: Node3D, push_from: Vector3, velocity := Vector3.ZERO, statue := -1) -> bool:
	if not m.is_inside_tree():
		return false
	var simple := not model.has_meta("forged_root")
	var forged: Node3D = model if simple else model.get_meta("forged_root")
	var meshes := forged.find_children("*", "MeshInstance3D", true, false)
	var body_mi: MeshInstance3D = null
	var biggest := 0.0
	for mi: MeshInstance3D in meshes:
		if simple:  # (the biggest shape is its body)
			var sz := mi.get_aabb().size * mi.global_basis.get_scale()
			if mi.visible and sz.x * sz.y * sz.z > biggest:
				biggest = sz.x * sz.y * sz.z
				body_mi = mi
		elif String(mi.name) == "body":
			body_mi = mi
	if body_mi == null:
		return false
	_close_eyes(m, model)
	# Each creature's own way (data.ragdoll = true, or a Dictionary): stay = parts left lying where they were (the
	# snail's foot: it stays on the ground and the shell comes off it), hop = how high it bounces up, roll = "side"
	# (it tips over sideways, e.g. the tall snail) or a roll forward/back, spin = how fast a gentle death turns,
	# narrow = how wide its body box is side to side (a round shell on a narrow box rolls onto its side).
	var d: Variant = m.get("data") if m.get("data") != null else m.get_meta("data", null)  # (the picture tool: a meta)
	var style: Dictionary = {}
	if d is Dictionary and (d as Dictionary).get("ragdoll") is Dictionary:
		style = (d as Dictionary).ragdoll
	if simple and style.is_empty():  # (an older creature: it flops onto its side, like the snail; standing on its legs it looked alive)
		style = {roll = "side", spin = 5.0, narrow = 0.5}
	var stay: Array = style.get("stay", [])
	var left := []  # parts left behind on the ground
	var up_w := model.global_basis.y.normalized()
	var fwd_w := -model.global_basis.z.normalized()  # monsters face -Z
	var centre_w := body_mi.global_transform * body_mi.get_aabb().get_center()
	var bottom_w := centre_w - up_w * body_mi.get_aabb().size.y * body_mi.global_basis.get_scale().y * 0.5  # the belly's underside
	var rb := RigidBody3D.new()
	rb.name = "Corpse"
	rb.mass = MASS
	rb.collision_layer = LAYER
	rb.collision_mask = World.TERRAIN_LAYER | PieceNode.PIECE_LAYER
	rb.angular_damp = 1.2  # it settles instead of spinning on
	rb.continuous_cd = true  # (a fast corpse can't slip through the cave floor between two steps)
	rb.linear_damp = 0.1
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.05
	rb.physics_material_override = pm
	m.get_parent().add_child(rb)
	var g := body_mi.global_transform
	rb.global_transform = Transform3D(g.basis.orthonormalized(), g.origin + Vector3.UP * 0.05)
	var relax := []  # [mesh, rest turn, dead turn, size]
	var soft_mi: MeshInstance3D = null  # (the snail's soft body: his eye stalks grow out of it)
	for mi: MeshInstance3D in meshes:
		if String(mi.name) == "soft_body" and mi.visible:
			soft_mi = mi
	for mi: MeshInstance3D in meshes:
		if not mi.visible and mi != body_mi:
			continue  # (hidden parts: folded wings in flight, the snail's peeking eyes)
		if mi.get_parent() is MeshInstance3D:
			continue  # (a shin rides on its leg; the leg below bends it at the knee)
		var n := String(mi.name)
		if n in stay:
			mi.reparent(m.get_parent(), true)  # (it stays put, not part of the falling body)
			left.append(mi)
			continue
		var moves := n.begins_with("leg") or n.begins_with("mandible") or n.begins_with("soft_stalk") or n.begins_with("feeler") \
			or n.begins_with("fold") or n == "soft_body"  # (wings: they settle once it lies still: _drape)
		if mi == body_mi and not simple:
			_shape(rb, mi, Vector3(float(style.get("narrow", 0.85)), 1.0, 0.85))  # (only the body: boxes from the standing legs would hold it up
			# off its belly; full height, so the shell never sinks into the floor)
		var shin := _shin(mi)
		if n.begins_with("leg") and shin:
			_knee_pose(rb, mi, shin, centre_w, up_w, bottom_w, relax)
			continue
		var target := _dead_pose(mi, centre_w, up_w, n, bottom_w) if moves else Basis.IDENTITY  # (a world turn)
		if n == "soft_body":  # (the snail's soft body slumps: its head sags forward and down)
			target = Basis(fwd_w.cross(-up_w).normalized(), 0.3) * mi.global_basis
		if n.begins_with("soft_stalk") and soft_mi:
			# (owner: his eyes came off his body when he fell: the stalks now hang on the soft body and move with it)
			mi.reparent(soft_mi, true)
			var tl := soft_mi.global_basis.orthonormalized().inverse() * target.orthonormalized()
			relax.append([mi, mi.basis.orthonormalized().get_rotation_quaternion(), tl.get_rotation_quaternion(), mi.basis.get_scale()])
			continue
		mi.reparent(rb, true)
		if moves:
			var tb := rb.global_basis.inverse() * target  # (said in the corpse's space)
			relax.append([mi, mi.basis.orthonormalized().get_rotation_quaternion(), tb.orthonormalized().get_rotation_quaternion(), mi.basis.get_scale()])
	if simple:
		_shape_all(rb, rb.find_children("*", "MeshInstance3D", true, false), float(style.get("narrow", 0.9)))  # (one box round all of it)
	# Off it goes: the speed it had (a charge flies on), a small hop away from the player, a roll about a level axis.
	var away := rb.global_position - push_from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else fwd_w
	var r := RandomNumberGenerator.new()
	r.seed = hash(m.get_instance_id())
	var flat_v := Vector3(velocity.x, 0, velocity.z)
	var dir := flat_v.normalized() if flat_v.length() > 1.0 else away
	var across := dir.cross(Vector3.UP).normalized()
	rb.linear_velocity = flat_v + away * 0.6 + Vector3.UP * (float(style.get("hop", 1.4)) + 0.25 * flat_v.length())
	var side_fwd := Vector3(fwd_w.x, 0, fwd_w.z).normalized()  # (its own nose-to-tail line)
	var roll_axis := side_fwd if style.get("roll", "") == "side" else across  # (turning about it tips it onto its side)
	var other := side_fwd.cross(Vector3.UP) if style.get("roll", "") == "side" else dir
	rb.angular_velocity = (roll_axis * (1.0 if r.randf() < 0.5 else -1.0) * r.randf_range(0.7, 1.0) + other * r.randf_range(-0.4, 0.4)).normalized() \
		* ((float(style.get("spin", 1.0)) if flat_v.length() < 1.0 else 3.0) + 0.6 * flat_v.length())  # (a gentle death lands belly-down; a charge tumbles)
	# The parts relax into the dead pose (legs spread out, jaws open, feelers droop), eased: no shivering.
	var t := rb.create_tween()
	t.set_parallel(true)
	t.tween_interval(0.01)  # (a statue with nothing to relax would start an empty tween: an engine error)
	for p in relax:
		t.tween_method(func(k: float) -> void:
			if is_instance_valid(p[0]):
				(p[0] as MeshInstance3D).basis = Basis((p[1] as Quaternion).slerp(p[2], k)) * Basis.from_scale(p[3]), 0.0, 1.0, RELAX_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	for f: MeshInstance3D in left:  # (the snail's foot relaxes: it spreads and flattens a little on the ground)
		t.tween_property(f, "scale", f.scale * Vector3(1.08, 0.7, 1.08), RELAX_TIME * 2.0).set_trans(Tween.TRANS_SINE)
	rb.set_meta("left", left)
	if statue >= 0:
		Statue.claim(rb, statue)  # (it stays, and turns to stone at once while it falls: owner, Nov 18)
		_later(rb, 0.3, func() -> void: Statue.petrify(rb, statue))
	else:
		t.chain().tween_interval(LIFETIME)
		t.chain().tween_callback(func() -> void: rb.freeze = true)
		for c in rb.get_children():
			if c is MeshInstance3D:
				t.parallel().tween_property(c, "scale", (c as MeshInstance3D).scale * 0.02, 1.0)
		for f: MeshInstance3D in left:
			t.parallel().tween_property(f, "scale", f.scale * Vector3(1.08, 0.7, 1.08) * 0.02, 1.0)
		t.chain().tween_callback(func() -> void:
			for f: MeshInstance3D in left:
				if is_instance_valid(f):
					f.queue_free()
			rb.queue_free())
	if statue >= 0 or not rb.find_children("wing*", "MeshInstance3D", false, false).is_empty() or not rb.find_children("soft_stalk*", "MeshInstance3D", true, false).is_empty():
		_later(rb, DRAPE_AT, func() -> void: _drape_when_still(rb, DRAPE_AT))
	rb.set_meta("relax", relax.size())
	rb.set_meta("up_local", rb.global_basis.inverse() * up_w)  # (the creature's "up", in the corpse's own space)
	m.set_meta("corpse", rb)
	return true


## Its eyes close: real eyelids shut; a creature without eyelids gets its eyeballs painted the colour of its lids.
static func _close_eyes(m: Node3D, model: Node3D) -> void:
	var lids: Array = model.get_meta("blinks", [])
	for b in lids:
		(b[0] as MeshInstance3D).basis = (b[1] as Basis) * Basis(Vector3.RIGHT, MonsterModel.BLINK_SHUT)
	if not lids.is_empty():
		return
	var lid := LID_COLOR
	var d: Variant = m.get("data")
	if d is Dictionary:
		lid = (d as Dictionary).get("lid_color", LID_COLOR)
	for e: StandardMaterial3D in model.get_meta("eye_mats", []):
		e.albedo_texture = null
		e.albedo_color = lid
		e.emission_enabled = false
		e.roughness = 0.85


## The dead pose of one part, as a world turn about its own hinge: legs spread outward and a little down (lying flat
## out from the body, away from the shell), mandibles fall open (away from the middle), feelers droop.
static func _dead_pose(mi: MeshInstance3D, centre_w: Vector3, up_w: Vector3, n: String, bottom_w: Vector3) -> Basis:
	var hinge := mi.global_position
	var tip := (mi.global_transform * mi.get_aabb().get_center()) - hinge
	if tip.length() < 0.01:
		return mi.global_basis
	tip = tip.normalized()
	var out := hinge - centre_w
	out -= up_w * out.dot(up_w)  # outward from the middle, level
	out = out.normalized() if out.length() > 0.01 else tip
	var axis_w := Vector3.ZERO
	var angle := 0.0
	if n.begins_with("leg") or n.begins_with("fold"):
		# Flat on the ground (owner: "flat on the ground"): straight out from the body and tipped down just enough that
		# the leg's tip reaches the floor the belly lies on (each leg by its own length and hip height).
		var length := 2.0 * (mi.global_transform * mi.get_aabb().get_center() - hinge).length()
		var drop := clampf((hinge - bottom_w).dot(up_w) / maxf(length, 0.05), 0.0, 0.7)
		var flat := (out * sqrt(1.0 - drop * drop) - up_w * drop).normalized()
		axis_w = tip.cross(flat)
		angle = tip.angle_to(flat)
	elif n.begins_with("mandible"):
		axis_w = up_w
		angle = 0.4 * (1.0 if tip.cross(out).dot(up_w) > 0.0 else -1.0)
	elif n.begins_with("soft_stalk") or n.begins_with("feeler"):
		axis_w = tip.cross(-up_w)
		angle = 0.5
	if axis_w.length() < 0.01:
		return mi.global_basis
	return Basis(axis_w.normalized(), angle) * mi.global_basis


## One wing piece or eye stalk settles (owner, Nov 18: pieces turned the wrong way, sank into the floor or into the
## body): it tries many poses and takes the lowest one that is allowed. Allowed = no corner under the floor and its
## far end not inside the body. A wing piece only turns about its own hinge (the way it flaps), so it can't twist;
## a round stalk may point any way (up to about 140 degrees from where it is). Small turns win a tie.
static func _settle(mi: MeshInstance3D, floor_y: float, solid: Array, sheet: bool, grown_in: Dictionary) -> int:
	var ab := mi.get_aabb()
	var g := mi.global_transform
	var hinge := g.origin
	var pts: Array[Vector3] = []
	var samples := _sample_points(mi, 80)  # (real points on its surface: box corners stick out past a wing's shape)
	for i in samples.size():
		if not grown_in.has(i):  # (points where it grows out of the body don't count)
			pts.append(g * samples[i])
	var centre := g * ab.get_center()
	var reach := 0.05
	for p in pts:
		reach = maxf(reach, (p - hinge).length())
	var tries: Array[Basis] = [Basis.IDENTITY]
	if sheet:
		var ax := g.basis.z.normalized()  # (its flap hinge: front to back)
		var sw := g.basis.y.normalized()  # (and a little swing forward or back)
		for j in range(-2, 3):
			for k in range(-28, 29):  # (up to 160 degrees: the upper wing of a bat lying on its side hangs over its body)
				if k != 0 or j != 0:
					tries.append(Basis(sw, j * 0.3) * Basis(ax, k * 0.1))
	elif (centre - hinge).length() > 0.01:
		var tip := (centre - hinge).normalized()
		for az in 16:
			for el in 8:
				var aa := TAU * az / 16.0
				var e := deg_to_rad(-85.0 + 14.0 * el)
				var d := Vector3(cos(aa) * cos(e), sin(e), sin(aa) * cos(e))
				if tip.angle_to(d) < 2.5 and tip.cross(d).length() > 0.001:
					tries.append(Basis(Quaternion(tip, d)))
	var best := Basis.IDENTITY
	var best_score := INF
	var best_bad := 0
	for r in tries:
		var bad := 0  # (if no pose is fully allowed, the one with the fewest problems)
		for p in pts:
			var q := hinge + r * (p - hinge)
			if q.y < floor_y - 0.01 or ((q - hinge).length() > 0.5 * reach and _in_solid(q, solid)):
				bad += 1
		var c := hinge + r * (centre - hinge)
		var score := bad * 10.0 + (c.y - floor_y) + 0.12 * r.get_rotation_quaternion().get_angle()
		if score < best_score:
			best_score = score
			best = r
			best_bad = bad
	mi.global_basis = best * mi.global_basis
	return best_bad


## Up to `n` of the part's own surface points (evenly picked), in its own space.
static func _sample_points(mi: MeshInstance3D, n: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if mi.mesh == null:
		return out
	var all := PackedVector3Array()
	for si in mi.mesh.get_surface_count():
		all.append_array(mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX])
	var step := maxi(1, all.size() / n)
	for i in range(0, all.size(), step):
		out.append(all[i])
	return out


## Is this point inside one of these parts? (An egg shape just inside each part's box, in its own turned space: a
## box round a round body has empty corners, and counted as solid they ruled out every good pose.)
static func _in_solid(p: Vector3, solid: Array) -> bool:
	for o: MeshInstance3D in solid:
		if not is_instance_valid(o):
			continue
		var lp := o.global_transform.affine_inverse() * p
		var ab := o.get_aabb()
		var half := (ab.size * 0.46).max(Vector3.ONE * 0.01)
		var d := (lp - ab.get_center()) / half
		if d.length_squared() < 1.0:
			return true
	return false


## Waits until the body lies still (at most 1 s: owner, Nov 18, the wait before the stone was too long), then drapes
## the wings. If it still rolls then, they settle again once it lies still (a roll after draping lifted them).
static func _drape_when_still(rb: RigidBody3D, waited: float) -> void:
	if not is_instance_valid(rb) or not rb.is_inside_tree():
		return
	var still := lies_still(rb)
	if still or waited > 1.0:  # (owner, Nov 18: the stone starts 1 s after it falls)
		_drape(rb)
		if not still:
			_redrape_when_still(rb, 0.0)
		return
	_later(rb, 0.15, func() -> void: _drape_when_still(rb, waited + 0.15))


## Calls `f` after `seconds`, but only while `rb` still exists (a timer tied to the body: when the world is cleared,
## the body and its timer go together; a plain timer called back into a freed body: an engine error).
static func _later(rb: Node, seconds: float, f: Callable) -> void:
	rb.create_tween().tween_callback(f).set_delay(seconds)


## True when the body has (nearly) stopped moving.
static func lies_still(rb: RigidBody3D) -> bool:
	return rb.linear_velocity.length() < 0.15 and rb.angular_velocity.length() < 0.3


static func _redrape_when_still(rb: RigidBody3D, waited: float) -> void:
	if not is_instance_valid(rb) or not rb.is_inside_tree():
		return
	if lies_still(rb) or waited > 8.0:
		_drape(rb)
		return
	_later(rb, 0.15, func() -> void: _redrape_when_still(rb, waited + 0.15))


## Once it has landed, each wing falls onto the floor (the bat, owner Nov 18: a wing stuck up in the air): the arm,
## then the middle web on it, then the outer web (and the snail's eye stalks, then their upper halves): each settles
## as low as it may without going into the floor or the body (_settle). Worked out on the final pose, then eased there.
static func _drape(rb: RigidBody3D) -> void:
	if not is_instance_valid(rb) or not rb.is_inside_tree():
		return
	var floor_y := rb.global_position.y - 0.3
	var q := PhysicsRayQueryParameters3D.create(rb.global_position + Vector3.UP * 0.5, rb.global_position + Vector3.DOWN * 3.0,
		World.TERRAIN_LAYER | PieceNode.PIECE_LAYER, [rb.get_rid()])
	var hit := rb.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		floor_y = (hit.position as Vector3).y
	var chain: Array[MeshInstance3D] = []  # arms first, then their webs (each turned after the one it hangs on)
	for w in rb.find_children("wing*", "MeshInstance3D", false, false):
		chain.append(w)
		for c in (w as Node).find_children("web*", "MeshInstance3D", true, false):
			chain.append(c)
	var tubes := 0  # (the snail's eye stalks, then their upper halves: round, so they just flop down)
	for st in rb.find_children("soft_stalk*", "MeshInstance3D", true, false):
		chain.append(st)
		tubes += 1
		for c in (st as Node).find_children("stalktip*", "MeshInstance3D", true, false):
			chain.append(c)
			tubes += 1
	var start := []
	for mi in chain:
		start.append(mi.basis)
	var solid := []  # (what the pieces may not go into: the body, and the snail's soft body)
	for o in rb.find_children("*", "MeshInstance3D", true, false):
		if String(o.name) in ["body", "soft_body"]:
			solid.append(o)
	var grown := {}  # piece -> its points inside the body BEFORE anything moves (where it grows out of it)
	for mi in chain:
		var inside := {}
		var sp := _sample_points(mi, 80)
		for i in sp.size():
			if _in_solid(mi.global_transform * sp[i], solid):
				inside[i] = true
		grown[mi] = inside
	var left_bad := {}  # piece -> how many of its points still poke into the floor or the body (the test reads it)
	for mi in chain:
		left_bad[String(mi.name)] = _settle(mi, floor_y, solid, String(mi.name).begins_with("wing") or String(mi.name).begins_with("web"), grown[mi])
	rb.set_meta("settle_bad", left_bad)
	if chain.is_empty():
		return  # (nothing to settle: a beetle has no wings or eye stalks)
	var t := rb.create_tween()
	t.set_parallel(true)
	for i in chain.size():
		var mi := chain[i]
		var a: Basis = start[i]
		var b := mi.basis
		mi.basis = a
		var size := a.get_scale()
		var qa := a.orthonormalized().get_rotation_quaternion()
		var qb := b.orthonormalized().get_rotation_quaternion()
		t.tween_method(func(k: float) -> void:
			if is_instance_valid(mi):
				mi.basis = Basis(qa.slerp(qb, k)) * Basis.from_scale(size), 0.0, 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	rb.set_meta("draped", chain.size() - tubes)
	rb.set_meta("flopped", tubes)
	rb.set_meta("drape_floor", floor_y)


## The lower leg hanging on this leg (its knee), if the model has one.
static func _shin(mi: MeshInstance3D) -> MeshInstance3D:
	for c in mi.get_children():
		if c is MeshInstance3D and String(c.name).begins_with("shin"):
			return c
	return null


## A leg with a knee (owner's drawing, Nov 18): the upper leg reaches out and down from the hip until the knee rests
## on the floor; the lower leg lies flat on the ground, pointing straight out from the body.
static func _knee_pose(rb: RigidBody3D, leg: MeshInstance3D, shin: MeshInstance3D, centre_w: Vector3, up_w: Vector3,
		bottom_w: Vector3, relax: Array) -> void:
	var hip := leg.global_position
	var knee := shin.global_position
	var out := hip - centre_w
	out -= up_w * out.dot(up_w)
	out = out.normalized() if out.length() > 0.01 else (knee - hip).normalized()
	var upper := knee - hip
	var thick := shin.get_aabb().size * shin.global_basis.get_scale()
	var r := minf(thick.x, thick.z) * 0.5  # (the lower leg's half thickness: it lies ON the floor, not in it)
	var drop := clampf(((hip - bottom_w).dot(up_w) - r) / maxf(upper.length(), 0.05), 0.0, 0.95)
	var reach := out * sqrt(1.0 - drop * drop) - up_w * drop
	var turn1 := Basis(Quaternion(upper.normalized(), reach.normalized()))
	var leg_to := (turn1 * leg.global_basis).orthonormalized()
	var tip := turn1 * ((shin.global_transform * shin.get_aabb().get_center()) - knee)
	var turn2 := Basis(Quaternion(tip.normalized(), out)) if tip.length() > 0.01 else Basis.IDENTITY
	var shin_to := (turn2 * turn1 * shin.global_basis).orthonormalized()
	var shin_local := leg_to.inverse() * shin_to  # (the shin turns inside its leg)
	leg.reparent(rb, true)
	var leg_local := (rb.global_basis.inverse() * leg_to).orthonormalized()
	relax.append([leg, leg.basis.orthonormalized().get_rotation_quaternion(), leg_local.get_rotation_quaternion(), leg.basis.get_scale()])
	relax.append([shin, shin.basis.orthonormalized().get_rotation_quaternion(), shin_local.get_rotation_quaternion(), shin.basis.get_scale()])


## One box round all these parts, in the corpse's space (an older creature made of simple shapes).
static func _shape_all(rb: RigidBody3D, parts: Array, narrow := 0.9) -> void:
	var inv := rb.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in parts:
		var b := (inv * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = (box.size * Vector3(narrow, 1.0, 0.9)).max(Vector3.ONE * 0.05)
	shape.shape = bs
	rb.add_child(shape)
	shape.position = box.get_center()


## A box from one part's own size, in the corpse's space (scale stays on the mesh, never on the body or the shape).
static func _shape(rb: RigidBody3D, mi: MeshInstance3D, fit: Vector3) -> void:
	var g := mi.global_transform
	var aabb := mi.get_aabb()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = (aabb.size * g.basis.get_scale() * fit).max(Vector3.ONE * 0.03)
	shape.shape = box
	rb.add_child(shape)
	shape.global_transform = Transform3D(g.basis.orthonormalized(), g * aabb.get_center())
