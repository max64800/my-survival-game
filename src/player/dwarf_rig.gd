class_name DwarfRig
extends Node3D
## The real dwarf: a rigged, animated model built from free CC0 Quaternius packs
## (credits in CREDITS.md), put together in code:
##   - clothes: "Ranger" outfit (hood, leather tunic, belt, boots)
##   - head + eyes + eyebrows from the base character (only the head part; the clothes cover the rest)
##   - a big beard
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
const HEIGHT := 1.0   ## where the head bone ends up (metres); the whole dwarf is ~1.3 m tall
const WIDTH := 1.45   ## dwarves are short, fat and wide: the whole body is squashed wider
const BEARD_COLOR := Color(0.62, 0.32, 0.14)
## Which animation does what. Names from the UAL packs ("b/" = pack 2). Godot drops the
## "_Loop" ending from the file's names when it imports them, and makes those animations loop.
const ANIMS := {
	idle = "Idle", walk = "Walk", jog = "Jog_Fwd", sprint = "Sprint",
	air = "Jump", roll = "Roll", hit = "Hit_Chest",
	dig = "Sword_Attack", attack_a = "b/Sword_Regular_A", attack_b = "b/Sword_Regular_B",
	heavy = "b/Sword_Regular_C", block = "b/Sword_Block", eat = "b/Consume", use = "Interact",
}
## Speeds (m/s) where each move animation fits best.
const MOVE_POINTS := {idle = 0.0, walk = 1.6, jog = 4.0, sprint = 6.5}

static var _libs := {}
static var _head_mesh: Mesh

var skeleton: Skeleton3D
var tree: AnimationTree
var right_hand: Node3D  ## tools go here
var left_hand: Node3D   ## the lantern hangs here
var _air := 0.0
var _rolling := false
var _attack_flip := false


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
		if m:
			m.albedo_color = BEARD_COLOR * 1.6  # the hair texture is light grey: tint it ginger
			mi.material_override = m)
	_tint_clothes(tint)
	for mi in find_children("*", "MeshInstance3D", true, false):
		mi.layers = DwarfModel.VISUAL_LAYER
	# Dwarf proportions, applied after every animation frame.
	var prop := DwarfProportions.new()
	skeleton.add_child(prop)
	prop.setup(skeleton)
	# Size: put the head bone at HEIGHT, and make the dwarf a bit wider.
	var head := skeleton.find_bone("Head")
	var head_y := prop._rest_global(skeleton, head, true).origin.y - (skeleton.get_bone_rest(skeleton.find_bone("pelvis")).basis * prop._drop).y
	var s := HEIGHT / maxf(head_y, 0.1)
	scale = Vector3(s * WIDTH, s, s * WIDTH)
	# Hands: things held keep their own size (cancel the dwarf scale and the big-hand scale).
	right_hand = _hand_socket("hand_r")
	left_hand = _hand_socket("hand_l")
	_build_tree(body)


func _process(_delta: float) -> void:
	for h in [right_hand, left_hand]:
		var p := h.get_parent() as Node3D
		h.scale = Vector3.ONE / p.global_transform.basis.get_scale()


## Legs follow `speed` (m/s); in the air we blend to the jump pose; a dodge rolls the whole body.
func set_motion(speed: float, on_floor: bool, rolling: bool) -> void:
	tree.set("parameters/move/blend_position", speed)
	_air = move_toward(_air, 0.0 if on_floor else 1.0, get_process_delta_time() * 6.0)
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
	# Whole-body one-shots (roll, hit).
	_add_oneshot(bt, "full", "air", false)
	# Upper-body one-shots (dig, attack): only the spine and up, so the legs keep walking.
	_add_oneshot(bt, "upper", "full", true)
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
		shot.filter_enabled = true
		var spine := skeleton.find_bone("spine_01")
		for i in skeleton.get_bone_count():
			var b := i
			while b >= 0 and b != spine:
				b = skeleton.get_bone_parent(b)
			if b == spine:
				shot.set_filter_path(NodePath("Armature/Skeleton3D:" + skeleton.get_bone_name(i)), true)
	bt.add_node(layer, shot)
	bt.connect_node(layer, 0, below)
	bt.connect_node(layer, 1, layer + "_speed")


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


## Each player's shirt and hood get their own colour (host blue, then red, green, gold).
func _tint_clothes(tint: Color) -> void:
	var soft := Color.WHITE.lerp(tint * 1.8, 0.6)
	for part in ["Male_Ranger_Body", "Male_Ranger_Head_Hood"]:
		var mi := skeleton.get_node_or_null(part) as MeshInstance3D
		if mi == null:
			continue
		var m := mi.get_active_material(0).duplicate() as BaseMaterial3D
		if m:
			m.albedo_color = soft
			mi.set_surface_override_material(0, m)


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
