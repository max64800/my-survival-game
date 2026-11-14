class_name DwarfRig
extends Node3D
## The real dwarf: a rigged, animated model built from free CC0 Quaternius packs
## (credits in CREDITS.md), put together in code:
##   - clothes: "Ranger" outfit (leather tunic, belt, boots; its hood is swapped for a dwarf helmet)
##   - head + eyes + eyebrows from the base character (only the head part; the clothes cover the rest)
##   - a big beard (the pack's short beard, stretched long and full in code)
##   - a metal helmet with a nose guard, made from simple shapes, riding on the head bone
##   - DwarfProportions: short legs, big head and hands
##   - animations from the Universal Animation Library 1 + 2, mixed by an AnimationTree:
##       legs: idle -> walk -> jog -> sprint by speed, a jump pose in the air
##       upper body (separate layer): pickaxe swings, sword attacks, so you can swing while walking
##       whole body: dodge roll, getting hit
## Faces -Z like the rest of the game. All meshes sit on DwarfModel.VISUAL_LAYER.

const OUTFIT := "res://assets/characters/dwarf/Male_Ranger.gltf"
const BASE := "res://assets/characters/dwarf/Superhero_Male_FullBody.gltf"
const BEARD := "res://assets/characters/dwarf/Hair_Beard.gltf"
const LIBS := {"": "res://assets/characters/anims/UAL1.glb", "b": "res://assets/characters/anims/UAL2.glb"}
const HEIGHT := 0.98  ## where the head bone ends up (metres); with the helmet the dwarf is ~1.3 m tall
const WIDTH := 1.2    ## a little extra width overall (most of the bulk comes from DwarfProportions)
const BEARD_COLOR := Color(0.62, 0.32, 0.14)
## Which animation does what. Names from the UAL packs ("b/" = pack 2). Godot drops the
## "_Loop" ending from the file's names when it imports them, and makes those animations loop.
const ANIMS := {
	idle = "Idle", walk = "Walk", jog = "Jog_Fwd", sprint = "Sprint",
	air = "Jump", roll = "Roll", hit = "Hit_Chest", knock = "b/Hit_Knockback",
	dig = "x/Pickaxe_Mine", climb = "x/Ladder_Climb", chop = "b/TreeChopping", wake = "b/LayToIdle", attack_a = "b/Sword_Regular_A", attack_b = "b/Sword_Regular_B",
	heavy = "b/Sword_Regular_C", eat = "b/Consume", use = "Interact", throw = "b/OverhandThrow",
	# Held poses (as long as the button is down):
	block = "b/Sword_Block", shield = "b/Idle_Shield", aim = "Pistol_Aim_Neutral",
}
## Speeds (m/s) where each move animation fits best.
const MOVE_POINTS := {idle = 0.0, walk = 1.6, jog = 4.0, sprint = 6.5}

## Our own animations, stitched together from poses of the pack's animations (see _made_library).
## Each entry: [time 0..1, source animation, moment in it (0..1 of its length)].
const MADE := {
	# A real mining swing: raise the pick high over the head, smash it down in front, recover.
	# The strike lands at 0.55, the moment the dig happens (DwarfModel.swing).
	"Pickaxe_Mine": [
		[0.0, "b/TreeChopping", 0.9], [0.38, "b/TreeChopping", 0.7], [0.55, "Sword_Attack", 0.36],
		[0.7, "Sword_Attack", 0.5], [1.0, "b/TreeChopping", 0.9]],
}

## Animations stitched from two sources: the upper body (spine and up) from one, the legs from
## another. Each key: [time 0..1, upper source, moment, lower source, moment]. They loop.
const MADE_SPLIT := {
	# Climbing a rope ladder: hands high on the rungs (from a "hold the rail overhead" pose)
	# while the legs step up in turns (from the jog).
	"Ladder_Climb": [
		[0.0, "b/Idle_Rail_Call", 0.25, "Jog_Fwd", 0.0], [0.5, "b/Idle_Rail_Call", 0.45, "Jog_Fwd", 0.5],
		[1.0, "b/Idle_Rail_Call", 0.25, "Jog_Fwd", 1.0]],
}

static var _libs := {}
static var _made: AnimationLibrary
static var _head_mesh: Mesh

var skeleton: Skeleton3D
var tree: AnimationTree
var right_hand: Node3D  ## tools go here
var left_hand: Node3D   ## the lantern hangs here
var _air := 0.0
var _air_time := 0.0  ## how long we've been off the ground (for the landing dip)
var _rolling := false
var _attack_flip := false
var _hold := ""        ## which held pose is on ("" = none)
var _hold_amount := 0.0


func build(tint: Color) -> void:
	var body: Node3D = (load(OUTFIT) as PackedScene).instantiate()
	add_child(body)
	body.rotation.y = PI  # the model faces +Z; our dwarf faces -Z
	skeleton = body.find_children("*", "Skeleton3D", true, false)[0]
	# Head, eyes, eyebrows and beard come from other files with the same skeleton:
	# move their meshes onto our skeleton.
	_borrow_meshes(BASE, func(mi: MeshInstance3D):
		if mi.name == "SuperHero_Male":
			mi.mesh = _head_only(mi))
	_borrow_meshes(BEARD, func(mi: MeshInstance3D):
		var m := mi.get_active_material(0).duplicate() as BaseMaterial3D
		mi.mesh = _big_beard(mi)
		if m:
			m.albedo_color = BEARD_COLOR * 1.6  # the hair texture is light grey: tint it ginger
			m.cull_mode = BaseMaterial3D.CULL_DISABLED  # a stretched beard shows its inside
			mi.material_override = m)
	var hood := skeleton.get_node_or_null("Male_Ranger_Head_Hood") as Node3D
	if hood:
		hood.visible = false
	_tint_clothes(tint)
	for mi in find_children("*", "MeshInstance3D", true, false):
		mi.layers = DwarfModel.VISUAL_LAYER
		_add_rim(mi)
	# Dwarf proportions, applied after every animation frame.
	var prop := DwarfProportions.new()
	skeleton.add_child(prop)
	prop.setup(skeleton)
	# Size: put the head bone at HEIGHT, and make the dwarf a bit wider.
	var head := skeleton.find_bone("Head")
	var head_y := prop._rest_global(skeleton, head, true).origin.y - prop.drop_height
	var s := HEIGHT / maxf(head_y, 0.1)
	scale = Vector3(s * WIDTH, s, s * WIDTH)
	# Hands: things held keep their own size (cancel the dwarf scale and the big-hand scale).
	right_hand = _hand_socket("hand_r")
	left_hand = _hand_socket("hand_l")
	_build_helmet()
	_build_beard()
	_build_tree(body)


func _process(delta: float) -> void:
	for h in [right_hand, left_hand]:
		var p := h.get_parent() as Node3D
		h.scale = Vector3.ONE / p.global_transform.basis.get_scale()
	_hold_amount = move_toward(_hold_amount, 1.0 if _hold != "" else 0.0, delta * 8.0)
	tree.set("parameters/hold/blend_amount", _hold_amount)


## On a ladder: the whole body plays the climbing loop (it fades in and out).
var _climb := 0.0


func set_climbing(on: bool, delta: float) -> void:
	_climb = move_toward(_climb, 1.0 if on else 0.0, delta * 6.0)
	tree.set("parameters/climb/blend_amount", _climb)


## A pose held with the upper body while a button is down: "block", "shield", "aim" or "" (none).
func set_hold(what: String) -> void:
	if what == _hold:
		return
	_hold = what
	if what == "":
		return  # fades out in _process
	var node := (tree.tree_root as AnimationNodeBlendTree).get_node("hold_anim") as AnimationNodeAnimation
	node.animation = ANIMS.get(what, what)
	tree.set("parameters/hold_seek/seek_request", 0.0)


## Legs follow `speed` (m/s); in the air we blend to the jump pose; a dodge rolls the whole body.
func set_motion(speed: float, on_floor: bool, rolling: bool) -> void:
	tree.set("parameters/move/blend_position", speed)
	var dt := get_process_delta_time()
	_air = move_toward(_air, 0.0 if on_floor else 1.0, dt * 6.0)
	if on_floor:
		if _air_time > 0.45 and not rolling:
			play_full("Jump_Land", 0.35)  # a real fall, not a bump: bend the knees on landing
		_air_time = 0.0
	else:
		_air_time += dt
	tree.set("parameters/air/blend_amount", _air)
	if rolling and not _rolling:
		play_full("roll", 0.5)
	_rolling = rolling


## Upper-body action (legs keep walking): dig, attack, block, eat…  `duration` = seconds.
func play_upper(what: String, duration: float = 0.0) -> void:
	_play("upper", what, duration)


## Whole-body action: roll, get hit.
func play_full(what: String, duration: float = 0.0) -> void:
	_play("full", what, duration)


func attack(duration: float, heavy: bool) -> void:
	_attack_flip = not _attack_flip
	play_upper("heavy" if heavy else ("attack_a" if _attack_flip else "attack_b"), duration)


func _play(layer: String, what: String, duration: float) -> void:
	var anim_name: String = ANIMS.get(what, what)
	if not tree.has_animation(anim_name):
		return
	var node := (tree.tree_root as AnimationNodeBlendTree).get_node(layer + "_anim") as AnimationNodeAnimation
	node.animation = anim_name
	var length := tree.get_animation(anim_name).length
	tree.set("parameters/%s_speed/scale" % layer, length / duration if duration > 0.0 else 1.0)
	tree.set("parameters/%s/request" % layer, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _build_tree(body: Node3D) -> void:
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	for lib_name in LIBS:
		tree.add_animation_library(lib_name, _library(LIBS[lib_name]))
	tree.add_animation_library("x", _made_library())
	var bt := AnimationNodeBlendTree.new()
	# Legs: blend between idle, walk, jog and sprint by speed.
	var move := AnimationNodeBlendSpace1D.new()
	for k in MOVE_POINTS:
		var a := AnimationNodeAnimation.new()
		a.animation = ANIMS[k]
		move.add_blend_point(a, MOVE_POINTS[k], -1, k)
	move.min_space = 0.0
	move.max_space = 8.0
	bt.add_node("move", move, Vector2(0, 0))
	var jump := AnimationNodeAnimation.new()
	jump.animation = ANIMS.air
	bt.add_node("jump", jump, Vector2(0, 200))
	bt.add_node("air", AnimationNodeBlend2.new(), Vector2(200, 0))
	bt.connect_node("air", 0, "move")
	bt.connect_node("air", 1, "jump")
	# Ladders: the climbing loop over everything below it.
	var climb := AnimationNodeAnimation.new()
	climb.animation = ANIMS.climb
	bt.add_node("climb_anim", climb)
	bt.add_node("climb", AnimationNodeBlend2.new())
	bt.connect_node("climb", 0, "air")
	bt.connect_node("climb", 1, "climb_anim")
	# Whole-body one-shots (roll, hit).
	_add_oneshot(bt, "full", "climb", false)
	# Held upper-body poses (block, shield up, crossbow aim). Non-looping ones hold their last frame.
	var hold_anim := AnimationNodeAnimation.new()
	hold_anim.animation = ANIMS.block
	bt.add_node("hold_anim", hold_anim)
	bt.add_node("hold_seek", AnimationNodeTimeSeek.new())
	bt.connect_node("hold_seek", 0, "hold_anim")
	var hold := AnimationNodeBlend2.new()
	_upper_filter(hold)
	bt.add_node("hold", hold)
	bt.connect_node("hold", 0, "full")
	bt.connect_node("hold", 1, "hold_seek")
	# Upper-body one-shots (dig, attack): only the spine and up, so the legs keep walking.
	_add_oneshot(bt, "upper", "hold", true)
	bt.connect_node("output", 0, "upper")
	tree.tree_root = bt
	body.add_child(tree)  # root_node ".." = the model, where "Armature/Skeleton3D" lives
	tree.active = true


func _add_oneshot(bt: AnimationNodeBlendTree, layer: String, below: String, upper_only: bool) -> void:
	var anim := AnimationNodeAnimation.new()
	anim.animation = ANIMS.idle
	bt.add_node(layer + "_anim", anim)
	bt.add_node(layer + "_speed", AnimationNodeTimeScale.new())
	bt.connect_node(layer + "_speed", 0, layer + "_anim")
	var shot := AnimationNodeOneShot.new()
	shot.fadein_time = 0.08
	shot.fadeout_time = 0.2
	if upper_only:
		_upper_filter(shot)
	bt.add_node(layer, shot)
	bt.connect_node(layer, 0, below)
	bt.connect_node(layer, 1, layer + "_speed")


## Let a blend node only touch the spine and everything above it (arms, head).
func _upper_filter(node: AnimationNode) -> void:
	node.filter_enabled = true
	var spine := skeleton.find_bone("spine_01")
	for i in skeleton.get_bone_count():
		var b := i
		while b >= 0 and b != spine:
			b = skeleton.get_bone_parent(b)
		if b == spine:
			node.set_filter_path(NodePath("Armature/Skeleton3D:" + skeleton.get_bone_name(i)), true)


func _hand_socket(bone: String) -> Node3D:
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	skeleton.add_child(att)
	var socket := Node3D.new()
	att.add_child(socket)
	return socket


## Take the meshes out of another model file (same skeleton) and put them on ours.
func _borrow_meshes(path: String, fix: Callable) -> void:
	var other: Node = (load(path) as PackedScene).instantiate()
	for mi: MeshInstance3D in other.find_children("*", "MeshInstance3D", true, false):
		mi.owner = null
		mi.get_parent().remove_child(mi)
		skeleton.add_child(mi)
		mi.skeleton = NodePath("..")
		fix.call(mi)
	other.free()


## Things worn (armor, masks). Each id builds its parts on a bone; new armor = a new entry here.
var _worn := {}  ## id -> the node holding its parts


func set_wear(ids: Array) -> void:
	for id in _worn.keys():
		if id not in ids:
			_worn[id].queue_free()
			_worn.erase(id)
	for id in ids:
		if not _worn.has(id) and has_method("_wear_" + id):
			_worn[id] = call("_wear_" + id)


## Spore Mask: a cloth mask over nose and mouth with two round filters (head bone units,
## face toward +Z; see _build_helmet for the measurements).
func _wear_spore_mask() -> Node3D:
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	skeleton.add_child(att)
	var cloth := Color(0.5, 0.58, 0.42)
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.2
	sm.radial_segments = 12
	sm.rings = 6
	var mask := MeshInstance3D.new()
	mask.mesh = sm
	mask.position = Vector3(0, 0.03, 0.115)
	mask.scale = Vector3(1.35, 0.75, 0.7)
	mask.material_override = Look.mat(cloth, "cloth")
	att.add_child(mask)
	for x in [-0.075, 0.075]:
		var f := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.035
		cm.bottom_radius = 0.04
		cm.height = 0.035
		cm.radial_segments = 10
		f.mesh = cm
		f.position = Vector3(x, 0.0, 0.17)
		f.rotation = Vector3(PI / 2.0, 0, x * 3.0)
		f.material_override = Look.mat(Color(0.35, 0.33, 0.3), "metal")
		att.add_child(f)
	for mi: MeshInstance3D in att.find_children("*", "MeshInstance3D", true, false):
		mi.layers = DwarfModel.VISUAL_LAYER
	return att


## A dwarf helmet on the head bone. Sizes are in the head bone's own units (measured: the skull
## is about ±0.15 wide, its top at +0.21 up, the face toward +Z).
func _build_helmet() -> void:
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	skeleton.add_child(att)
	var iron := Color(0.5, 0.5, 0.53)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.128
	sm.height = 0.128
	sm.is_hemisphere = true
	sm.radial_segments = 16
	sm.rings = 6
	dome.mesh = sm
	dome.position = Vector3(0, 0.115, -0.02)
	dome.scale = Vector3(1.0, 1.25, 1.1)
	dome.material_override = Look.mat(iron, "metal")
	att.add_child(dome)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.124
	tm.outer_radius = 0.14
	tm.rings = 20
	tm.ring_segments = 6
	rim.mesh = tm
	rim.position = Vector3(0, 0.12, -0.02)
	rim.scale = Vector3(1.0, 0.6, 1.1)
	rim.material_override = Look.mat(Color(0.55, 0.38, 0.2), "metal")  # a bronze band
	att.add_child(rim)
	var ridge := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(0.022, 0.026, 0.18)
	ridge.mesh = rb
	ridge.position = Vector3(0, 0.25, -0.02)
	ridge.material_override = Look.mat(Color(0.55, 0.38, 0.2), "metal")
	att.add_child(ridge)
	var nose := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.026, 0.1, 0.02)
	nose.mesh = nb
	nose.position = Vector3(0, 0.08, 0.14)
	nose.material_override = Look.mat(iron, "metal")
	att.add_child(nose)
	for mi in [dome, rim, ridge, nose]:
		mi.layers = DwarfModel.VISUAL_LAYER


## The big dwarf beard: a full, lumpy beard that grows from the jaw and flows down onto the chest,
## built from rings (like stacking hoops of different sizes and wrapping them in skin).
## It rides on the head bone, so it turns with the head. Head bone units: face toward +Z.
func _build_beard() -> void:
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	skeleton.add_child(att)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const RINGS := 9
	const AROUND := 12
	var rings := []
	for r in RINGS:
		var t := float(r) / (RINGS - 1)
		var y := lerpf(0.05, -0.46, t)                  # from the jaw down onto the chest
		var z := lerpf(0.07, 0.17, sqrt(t))             # follows the chest forward
		var w := 0.135 * (1.0 + 0.3 * sin(PI * t * 0.85)) * (1.0 - 0.8 * t * t)  # widest in the middle
		var d := 0.075 * (1.0 - 0.55 * t)
		var ring := []
		for a in AROUND:
			var ang := TAU * a / AROUND
			var lump := 1.0 + 0.12 * sin(ang * 3.0 + r * 1.7) * t  # hand-made, uneven locks
			ring.append(Vector3(cos(ang) * w * lump, y, z + sin(ang) * d * lump))
		rings.append(ring)
	var tip := Vector3(0, -0.53, 0.19)
	for r in RINGS - 1:
		for a in AROUND:
			var b := (a + 1) % AROUND
			_quad(st, rings[r][a], rings[r][b], rings[r + 1][b], rings[r + 1][a])
	for a in AROUND:
		st.add_vertex(rings[RINGS - 1][a])
		st.add_vertex(tip)
		st.add_vertex(rings[RINGS - 1][(a + 1) % AROUND])
	# A thick moustache: two drooping tufts under the nose.
	for sx in [-1.0, 1.0]:
		var root := Vector3(0.02 * sx, 0.075, 0.155)
		var end := Vector3(0.12 * sx, -0.01, 0.12)
		for a in 6:
			var a0 := TAU * a / 6.0
			var a1 := TAU * (a + 1) / 6.0
			var o0 := Vector3(0, cos(a0), sin(a0)) * 0.025
			var o1 := Vector3(0, cos(a1), sin(a1)) * 0.025
			st.add_vertex(root + o0)
			st.add_vertex(end)
			st.add_vertex(root + o1)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := Look.mat(BEARD_COLOR, "bark", 0.0, 0.0)  # bark's long streaks read as strands of hair
	mi.material_override = m
	mi.layers = DwarfModel.VISUAL_LAYER
	att.add_child(mi)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, c, b, a, d, c]:  # this order makes the outside the visible side
		st.add_vertex(v)


## The pack's short chin beard, stretched into a big dwarf beard: longer down onto the chest,
## fuller and pushed forward. Works in the head bone's space (where the face points to +Z).
static func _big_beard(mi: MeshInstance3D) -> Mesh:
	var bind := -1
	for i in mi.skin.get_bind_count():
		if String(mi.skin.get_bind_name(i)) == "Head":
			bind = i
	if bind < 0:
		return mi.mesh
	var to_head := mi.skin.get_bind_pose(bind)
	var from_head := to_head.affine_inverse()
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var pivot := Vector3(0, 0.075, 0.05)  # just under the nose
	for i in verts.size():
		var d := to_head * verts[i] - pivot
		var t := clampf(-d.y / 0.05, 0.0, 1.0)  # 0 = moustache, 1 = the hanging part
		var k := Vector3(1.15, 1.1, 1.1).lerp(Vector3(1.25, 1.3, 1.15), t)  # only a little: it must stay on the face
		verts[i] = from_head * (pivot + d * k)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = arrays[Mesh.ARRAY_NORMAL]
	var m := ArrayMesh.new()
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if bones.size() == verts.size() * 8 else 0
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	m.surface_set_material(0, mi.mesh.surface_get_material(0))
	return m


## A soft light along the dwarf's outline, so they stand out against the dark cave
## (the same trick the painted props use; see Look / prop.gdshader).
static func _add_rim(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i) as BaseMaterial3D
		if m == null:
			continue
		if mi.get_surface_override_material(i) == null and mi.material_override == null:
			m = m.duplicate()
		m.rim_enabled = true
		m.rim = 0.35
		m.rim_tint = 0.6
		if mi.material_override == null:
			mi.set_surface_override_material(i, m)


## Each player's shirt and hood get their own colour (host blue, then red, green, gold).
func _tint_clothes(tint: Color) -> void:
	var soft := Color.WHITE.lerp(tint * 1.8, 0.6)
	for part in ["Male_Ranger_Body"]:
		var mi := skeleton.get_node_or_null(part) as MeshInstance3D
		if mi == null:
			continue
		var m := mi.get_active_material(0).duplicate() as BaseMaterial3D
		if m:
			m.albedo_color = soft
			mi.set_surface_override_material(0, m)


## Builds our own animations (MADE) once: for every bone, take its pose at the chosen moments of
## the pack's animations and use those as keys (like a flip book made from other flip books).
static func _made_library() -> AnimationLibrary:
	if _made:
		return _made
	_made = AnimationLibrary.new()
	var src := {"": _library(LIBS[""]), "b": _library(LIBS["b"])}
	for anim_name in MADE:
		var keys: Array = MADE[anim_name]
		var out := Animation.new()
		out.length = 1.0
		var first := _source(src, keys[0][1])
		for t in first.get_track_count():
			var kind := first.track_get_type(t)
			if kind != Animation.TYPE_ROTATION_3D and kind != Animation.TYPE_POSITION_3D:
				continue
			var path := first.track_get_path(t)
			var nt := out.add_track(kind)
			out.track_set_path(nt, path)
			for k in keys:
				var a := _source(src, k[1])
				var st := a.find_track(path, kind)
				if st < 0:
					continue
				var at: float = k[2] * a.length
				if kind == Animation.TYPE_ROTATION_3D:
					out.rotation_track_insert_key(nt, k[0], a.rotation_track_interpolate(st, at))
				else:
					out.position_track_insert_key(nt, k[0], a.position_track_interpolate(st, at))
		_made.add_animation(anim_name, out)
	for anim_name in MADE_SPLIT:
		_made.add_animation(anim_name, _split_anim(src, MADE_SPLIT[anim_name]))
	return _made


## See MADE_SPLIT. Which bones are "upper body" is read from the bone names in the track paths.
const UPPER_ROOTS := ["spine_", "neck_", "Head", "clavicle", "upperarm", "lowerarm", "hand_",
	"index_", "middle_", "pinky_", "ring_", "thumb_"]


static func _split_anim(src: Dictionary, keys: Array) -> Animation:
	var out := Animation.new()
	out.length = 1.0
	out.loop_mode = Animation.LOOP_LINEAR
	var first := _source(src, keys[0][1])
	for t in first.get_track_count():
		var kind := first.track_get_type(t)
		if kind != Animation.TYPE_ROTATION_3D and kind != Animation.TYPE_POSITION_3D:
			continue
		var path := first.track_get_path(t)
		var bone := String(path.get_concatenated_subnames())
		var upper := false
		for r in UPPER_ROOTS:
			if bone.begins_with(r):
				upper = true
		var nt := out.add_track(kind)
		out.track_set_path(nt, path)
		for k in keys:
			var a := _source(src, k[1] if upper else k[3])
			var st := a.find_track(path, kind)
			if st < 0:
				continue
			var at: float = (k[2] if upper else k[4]) * a.length
			if kind == Animation.TYPE_ROTATION_3D:
				out.rotation_track_insert_key(nt, k[0], a.rotation_track_interpolate(st, at))
			else:
				out.position_track_insert_key(nt, k[0], a.position_track_interpolate(st, at))
	return out


static func _source(src: Dictionary, full_name: String) -> Animation:
	var lib := "b" if full_name.begins_with("b/") else ""
	return (src[lib] as AnimationLibrary).get_animation(full_name.trim_prefix("b/"))


## The animations, loaded once and shared by every dwarf.
static func _library(path: String) -> AnimationLibrary:
	if _libs.has(path):
		return _libs[path]
	var scene: Node = (load(path) as PackedScene).instantiate()
	var player: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
	var lib := player.get_animation_library(&"")
	scene.free()
	_libs[path] = lib
	return lib


## The base body's mesh, cut down to just the head and neck (the clothes cover the rest;
## a full body under the clothes would poke through and cost speed).
static func _head_only(mi: MeshInstance3D) -> Mesh:
	if _head_mesh:
		return _head_mesh
	var src := mi.mesh
	var keep := {}
	for i in mi.skin.get_bind_count():
		var bn := String(mi.skin.get_bind_name(i))
		if bn in ["Head", "neck_01"]:
			keep[i] = true
	var arrays := src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / verts.size()
	var head_vert := PackedByteArray()
	head_vert.resize(verts.size())
	for v in verts.size():
		var best := 0
		for k in per:
			if weights[v * per + k] > weights[v * per + best]:
				best = k
		head_vert[v] = 1 if keep.has(bones[v * per + best]) else 0
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var out := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if head_vert[idx[t]] and head_vert[idx[t + 1]] and head_vert[idx[t + 2]]:
			out.append_array([idx[t], idx[t + 1], idx[t + 2]])
	arrays[Mesh.ARRAY_INDEX] = out
	var m := ArrayMesh.new()
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per == 8 else 0
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	m.surface_set_material(0, src.surface_get_material(0))
	_head_mesh = m
	return m
