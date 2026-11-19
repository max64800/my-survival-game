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
		(corpse as CollisionObject3D).collision_layer = World.TERRAIN_LAYER  # solid: you bump into it
	Sfx.play("dig_rock", box.get_center(), -10.0, 0.55)  # a low stony grind as it sets


static func _freeze_when_still(rb: RigidBody3D, waited: float) -> void:
	if not is_instance_valid(rb) or not rb.is_inside_tree():
		return
	if Ragdoll.lies_still(rb) or waited > 4.0:
		rb.freeze = true
		rb.collision_layer = World.TERRAIN_LAYER  # solid now: you bump into it (still rolling it was only a corpse)
		return
	Ragdoll._later(rb, 0.15, func() -> void: _freeze_when_still(rb, waited + 0.15))


## A pickaxe hit (the host's count): the cracks run deeper.
static func hit(id: int, hits: int, needed: int) -> void:
	var c: Node3D = nodes.get(id)
	if is_instance_valid(c):
		for m: ShaderMaterial in c.get_meta("stone_mats", []):
			m.set_shader_parameter("damage", clampf(float(hits) / maxf(1.0, needed), 0.0, 1.0))


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
	for mi: MeshInstance3D in _meshes(c):
		t.tween_property(mi, "scale", mi.scale * Vector3(1.1, 0.05, 1.1), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void: _free(c))


static func _free(c: Node3D) -> void:
	for f in c.get_meta("left", []):
		if is_instance_valid(f):
			(f as Node).queue_free()
	c.queue_free()


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
