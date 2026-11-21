class_name Statue
## A dead creature turns to stone (owner, Nov 18): it falls and lies still (Ragdoll), then dark cracks run out from its
## middle and grey stone fills in behind them (petrify.gdshader, PETRIFY_TIME), until it is a stone statue in the pose
## it died in. Then it is solid like a boulder: mine it with a pickaxe (MonsterManager.request_hit_statue: the host
## counts the hits and drops its stone and loot when it breaks). Left alone it crumbles to dust after
## MonsterManager.STATUE_LIFE. This file is only the looks: every player's computer turns its own copy to stone.

const PETRIFY_TIME := 7.0  ## (owner, Nov 18: 3 s was too fast)
const SHADER := preload("res://src/combat/petrify.gdshader")
const STONE := Color(0.45, 0.43, 0.4)

static var nodes := {}  ## statue id -> this computer's stone body (a RigidBody3D corpse or a StaticBody3D)


## The statue id a pickaxe ray hit (-1 = not a statue).
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("statue"):
		return int((collider as Node).get_meta("statue"))
	if collider is Node and (collider as Node).has_meta("statue_pending"):  # (owner, Nov 18: mine it the moment it dies)
		return int((collider as Node).get_meta("statue_pending"))
	return -1


## This fallen body will become statue `id` (it turns to stone once it lies still).
static func claim(corpse: Node3D, id: int) -> void:
	nodes[id] = corpse
	corpse.set_meta("statue_pending", id)


## The body's meshes, with parts left lying beside it (the snail's foot).
static func _meshes(corpse: Node3D) -> Array:
	var out: Array = corpse.find_children("*", "MeshInstance3D", true, false)
	for f in corpse.get_meta("left", []):
		if is_instance_valid(f):
			out.append(f)
	return out


## Its middle and size (world), from all its meshes.
static func _bounds(corpse: Node3D) -> AABB:
	if corpse.has_meta("bone_box"):
		return corpse.get_meta("bone_box")  # (a pile of bones: where they really lie)
	if not corpse.find_children("*", "Skeleton3D", true, false).is_empty():
		return bone_box(corpse)
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in _meshes(corpse):
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Turns it to stone: the cracks and stone spread over PETRIFY_TIME (it starts 0.3 s after it dies, while it still falls:
## owner, Nov 18, it took too long); once it lies still it freezes there and is solid.
static func petrify(corpse: Node3D, id: int) -> void:
	if not is_instance_valid(corpse) or corpse.has_meta("statue"):
		return
	var box := _bounds(corpse)
	var drawn := DisplayServer.get_name() != "headless"  # (tests draw nothing: a stone cover there only makes the engine complain)
	var mats := {}  # a part's lumpiness -> its stone cover (older creatures push their corners out: prop.gdshader "wobble";
	# a cover that doesn't push the same way hides under the paint)
	for mi: MeshInstance3D in _meshes(corpse):
		mi.set_meta("stone", true)
		if not drawn:
			continue
		var wob := 0.0
		if mi.material_override is ShaderMaterial:
			var w: Variant = (mi.material_override as ShaderMaterial).get_shader_parameter("wobble")
			wob = float(w) if w != null else 0.0
		if not mats.has(wob):
			var mat := ShaderMaterial.new()
			mat.shader = SHADER
			mat.set_shader_parameter("seed_pos", box.get_center())
			mat.set_shader_parameter("spread", maxf(0.2, box.size.length() * 0.5))
			mat.set_shader_parameter("wobble", wob)
			mats[wob] = mat
		mi.material_overlay = mats[wob]
	corpse.set_meta("stone_mats", mats.values())
	# Where the stone starts rides along with the body (F369, Nov 19): it starts while the body still falls, and a bat
	# shot off a high roost fell metres below a start point fixed in the air, so the stone never reached it.
	# (Kept on the body as "stone_seed" too, so a test without drawing can check it.)
	var seed_local := corpse.global_transform.affine_inverse() * box.get_center()
	var t := corpse.create_tween()
	t.tween_method(func(k: float) -> void:
		var at := corpse.global_transform * seed_local
		corpse.set_meta("stone_seed", at)
		for m: ShaderMaterial in mats.values():
			m.set_shader_parameter("seed_pos", at)
			m.set_shader_parameter("progress", k), 0.0, 1.0, PETRIFY_TIME).set_trans(Tween.TRANS_LINEAR)  # (steady: the first cracks show at once, the stone creeps on evenly)
	corpse.set_meta("statue", id)
	corpse.remove_meta("statue_pending")
	if corpse is RigidBody3D:
		_freeze_when_still(corpse as RigidBody3D, 0.0)  # (a stone statue doesn't roll; never frozen mid-roll; then solid)
	else:
		pass  # (it stays on Ragdoll.LAYER: your pickaxe hits it, but you and the creatures walk through it: owner,
		# Nov 20, "if I kill them in the spot, I can block the entrance")
	Sfx.play("dig_rock", box.get_center(), -10.0, 0.55)  # a low stony grind as it sets


static func _freeze_when_still(rb: RigidBody3D, waited: float) -> void:
	if not is_instance_valid(rb) or not rb.is_inside_tree():
		return
	if Ragdoll.lies_still(rb) or waited > 4.0:
		rb.freeze = true
		rb.collision_layer = Ragdoll.LAYER  # (walk-through, owner Nov 20; the pickaxe still hits it)
		return
	Ragdoll._later(rb, 0.15, func() -> void: _freeze_when_still(rb, waited + 0.15))


## A pickaxe hit (the host's count): the cracks run deeper.
static func hit(id: int, hits: int, needed: int) -> void:
	var c: Node3D = nodes.get(id)
	if is_instance_valid(c):
		for m: ShaderMaterial in c.get_meta("stone_mats", []):
			m.set_shader_parameter("damage", clampf(float(hits) / maxf(1.0, needed), 0.0, 1.0))


## Where statue `id`'s stone body is now (its middle), or `fallback` if it isn't drawn here. A bat that died in the
## air falls metres after dying: the mining sparks and the loot belong where it lies (owner, Nov 19).
static func where(id: int, fallback: Vector3) -> Vector3:
	var c: Node3D = nodes.get(id)
	return _bounds(c).get_center() if is_instance_valid(c) and not _meshes(c).is_empty() else fallback


## Gone: mined (it bursts into chunks) or left too long (it crumbles to dust and sinks).
static func remove(id: int, mined: bool) -> void:
	var c: Node3D = nodes.get(id)
	nodes.erase(id)
	if not is_instance_valid(c):
		return
	var box := _bounds(c)
	var parent := c.get_parent()
	if mined:
		if DisplayServer.get_name() != "headless":  # (the chunks' rock material makes a drawing-less test computer complain)
			# The same burst as mining rock (owner, Nov 18), with pieces sized to the statue (bat ~0.5, beetle ~0.85, Great Rock Beetle ~1.3).
			var dims := [box.size.x, box.size.y, box.size.z]
			dims.sort()
			var size := clampf(float(dims[1]) / 1.6, 0.3, 1.3)  # (its middle measure: a bat's long wings don't count)
			RockShatter.burst(parent, box.get_center(), Vector3.UP, STONE, Mat.STONE, size)
			RockShatter.burst(parent, box.get_center() + Vector3.UP * 0.15 * size, Vector3.UP, STONE, Mat.STONE, size * 0.8)
		_free(c)
		return
	Fx.burst(parent, box.get_center(), STONE.lightened(0.2), 24, 1.5)  # a puff of stone dust
	Sfx.play("dig_soft", box.get_center(), -4.0, 0.7)
	var t := c.create_tween().set_parallel(true)
	if c.has_meta("bone_box"):  # (a skinned pile follows its bones, not its parts: flatten the whole pile)
		for cs: CollisionShape3D in c.find_children("*", "CollisionShape3D", true, false):
			cs.set_deferred("disabled", true)  # (a squashed box only makes the physics engine complain)
		t.tween_property(c, "scale", c.scale * Vector3(1.1, 0.05, 1.1), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for mi: MeshInstance3D in _meshes(c):
		t.tween_property(mi, "scale", mi.scale * Vector3(1.1, 0.05, 1.1), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void: _free(c))


const STIR_GLOW := Color(0.55, 0.95, 0.85)  ## the Prop Warden's call: a cold miner-blue glow


## The Prop Warden's Rally Slam (owner, Nov 21): this statue glows and shakes for `seconds` (0 = stop: he was hit).
static func stir(id: int, seconds: float) -> void:
	var c: Node3D = nodes.get(id)
	if not is_instance_valid(c):
		return
	var old: Node = c.get_node_or_null("StirGlow")
	if old:
		old.queue_free()
	if c.has_meta("stir_from"):
		c.position = c.get_meta("stir_from")
		c.remove_meta("stir_from")
	if c.has_meta("stir_tween"):
		var tw: Tween = c.get_meta("stir_tween")
		if tw and tw.is_valid():
			tw.kill()
		c.remove_meta("stir_tween")
	if seconds <= 0.0:
		return
	var box := _bounds(c)
	var light := OmniLight3D.new()
	light.name = "StirGlow"
	light.light_color = STIR_GLOW
	light.omni_range = 2.5
	light.light_energy = 0.0
	c.add_child(light)
	light.global_position = box.get_center() + Vector3.UP * 0.3
	Fx.burst(c.get_parent(), box.get_center(), STIR_GLOW, 10, 1.2)
	var from := c.position
	c.set_meta("stir_from", from)
	light.create_tween().tween_property(light, "light_energy", 3.0, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var t := c.create_tween()  # (shaking harder and harder until he slams)
	c.set_meta("stir_tween", t)
	var n := maxi(1, int(seconds / 0.08))
	for i in n:
		var k := 0.01 + 0.04 * float(i) / float(n)
		t.tween_property(c, "position", from + Vector3(randf_range(-k, k), randf_range(0.0, k), randf_range(-k, k)), 0.08)
	t.tween_property(c, "position", from, 0.05)


## Raised: the stone falls off as dust (the Lost Miner that gets up in its place is a new creature).
static func raise_away(id: int) -> void:
	var c: Node3D = nodes.get(id)
	nodes.erase(id)
	if not is_instance_valid(c):
		return
	var box := _bounds(c)
	Fx.burst(c.get_parent(), box.get_center(), STONE.lightened(0.2), 24, 2.0)
	Fx.burst(c.get_parent(), box.get_center(), STIR_GLOW, 14, 2.5)
	Sfx.play("dig_soft", box.get_center(), -4.0, 0.6)
	_free(c)


static func _free(c: Node3D) -> void:
	for f in c.get_meta("left", []):
		if is_instance_valid(f):
			(f as Node).queue_free()
	c.queue_free()


## A skeleton creature (CreatureRig, owner F463): it falls apart into a pile of bones (its own move), then the pile
## turns to stone. Its solid box is measured from where the bones lie (a skinned body's own box is its standing shape).
static func from_rig(m: Node3D, model: Node3D, id: int, rig: CreatureRig) -> void:
	var sb := StaticBody3D.new()
	sb.name = "Corpse"
	sb.collision_layer = Ragdoll.LAYER  # (your pickaxe can hit it at once)
	m.get_parent().add_child(sb)
	sb.global_transform = m.global_transform
	model.reparent(sb, true)
	if id >= 0:
		claim(sb, id)
	var fall := rig.die()
	var t := sb.create_tween()
	t.tween_interval(fall * 0.5)
	if id >= 0:
		t.tween_callback(func() -> void: petrify(sb, id))  # (the stone starts while the last bones still fall)
	else:
		t.tween_interval(fall * 0.5 + 0.5)  # (no statue: the pile sinks away)
		t.tween_property(model, "position:y", model.position.y - 0.6, 0.8)
		t.tween_callback(sb.queue_free)
		return
	t.tween_interval(fall * 0.5)
	t.tween_callback(func() -> void:
		var box := bone_box(sb)
		sb.set_meta("bone_box", box)
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = box.size.max(Vector3.ONE * 0.1)
		shape.shape = bs
		sb.add_child(shape)
		shape.global_position = box.get_center())


## Where a skeleton's bones lie now (world), a little padded.
static func bone_box(corpse: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for sk: Skeleton3D in corpse.find_children("*", "Skeleton3D", true, false):
		for b in sk.get_bone_count():
			var p := sk.global_transform * sk.get_bone_global_pose(b).origin
			box = AABB(p, Vector3.ZERO) if first else box.expand(p)
			first = false
	return box.grow(0.12)


## A creature without a ragdoll (an older model): it tips over where it stands, then turns to stone there.
static func from_model(m: Node3D, model: Node3D, id: int) -> void:
	var sb := StaticBody3D.new()
	sb.name = "Corpse"
	sb.collision_layer = Ragdoll.LAYER  # (your pickaxe can hit it at once)
	m.get_parent().add_child(sb)
	sb.global_position = model.global_position
	model.reparent(sb, true)
	claim(sb, id)
	var t := sb.create_tween()
	t.tween_property(model, "rotation:z", deg_to_rad(80.0) * (1.0 if id % 2 == 0 else -1.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_interval(0.4)
	t.tween_callback(func() -> void:
		var box := _bounds(sb)  # (lying down now: its solid box is where it lies)
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = box.size.max(Vector3.ONE * 0.1)
		shape.shape = bs
		sb.add_child(shape)
		shape.global_position = box.get_center()
		petrify(sb, id))
