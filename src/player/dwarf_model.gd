class_name DwarfModel
extends Node3D
## The dwarf's body. Normally the real rigged, animated dwarf (DwarfRig, src/player/dwarf_rig.gd).
## The old placeholder made of simple shapes is still here as a backup: -- art=shapes
## Faces -Z (Godot's "forward").
## The right arm holds the pickaxe and can swing; the left hand holds the lantern.

signal swing_impact  ## the pickaxe just hit (time to dig)

const SKIN := Color(0.93, 0.72, 0.58)
const BEARD := Color(0.72, 0.33, 0.14)
const TUNIC := Color(0.25, 0.38, 0.55)
## Shirt colors, so co-op friends look different: host blue, then red, green, gold.
const TUNICS := [Color(0.25, 0.38, 0.55), Color(0.6, 0.22, 0.2), Color(0.25, 0.48, 0.25), Color(0.7, 0.55, 0.2)]

var tunic := TUNIC
## Which look: "dwarf" (the real rigged dwarf, default), "shapes" (boxes and spheres) or
## "quaternius" (an older CC0 test model from assets/art_candidates). Command line: -- art=shapes
static var art := "dwarf"
var dwarf_rig: DwarfRig
const RIG_PATH := "res://assets/art_candidates/quaternius_adventurer.glb"
var rig: Node3D
var anim: AnimationPlayer
var _rig_anim := ""
const LEATHER := Color(0.33, 0.21, 0.12)
const METAL := Color(0.6, 0.6, 0.63)

var right_arm: Node3D  ## shoulder pivot, rotates on X to swing
var left_hand: Node3D  ## where the lantern hangs
var swinging := false
var _mats := {}
var _hand: Node3D  ## what the right hand holds
var _held := "?"


## Dwarf bodies live on their own visual layer (layer 2). Lanterns don't let this
## layer cast shadows, so a dwarf never blocks their own lantern light.
const VISUAL_LAYER := 2
## How a tool sits in the rigged dwarf's right hand (handle through the fist).
static var hand_tool_rot := Vector3(PI / 2.0, 0, 0)  ## tool "up" = the hand bone's Z (the thumb side)
static var hand_tool_pos := Vector3(0, 0.08, 0)


func _ready() -> void:
	if art == "dwarf":
		_build_dwarf_rig()
		return
	if art == "quaternius" and ResourceLoader.exists(RIG_PATH):
		_build_rig()
		return
	# Legs
	for x in [-0.13, 0.13]:
		_part(_cyl(0.09, 0.11, 0.36), LEATHER, Vector3(x, 0.18, 0))
		_part(_box(Vector3(0.18, 0.1, 0.28)), LEATHER.darkened(0.3), Vector3(x, 0.05, -0.04))
	# Body, belt
	_part(_capsule(0.33, 0.78), tunic, Vector3(0, 0.68, 0))
	_part(_cyl(0.34, 0.34, 0.08), LEATHER, Vector3(0, 0.55, 0))
	_part(_box(Vector3(0.12, 0.09, 0.04)), Color(0.85, 0.7, 0.3), Vector3(0, 0.55, -0.34))
	# Head, nose, eyes
	_part(_sphere(0.2), SKIN, Vector3(0, 1.12, 0))
	_part(_sphere(0.065), SKIN.darkened(0.08), Vector3(0, 1.1, -0.2))
	for x in [-0.075, 0.075]:
		_part(_sphere(0.025), Color(0.08, 0.06, 0.05), Vector3(x, 1.16, -0.18))
	# Beard: a big wedge hanging from the chin
	var beard := _part(_cyl(0.2, 0.05, 0.42), BEARD, Vector3(0, 0.88, -0.17))
	beard.rotation.x = deg_to_rad(-12)
	_part(_sphere(0.16), BEARD, Vector3(0, 1.0, -0.12))
	# Helmet with a nose guard
	var helm := _part(_hemisphere(0.23), METAL, Vector3(0, 1.17, 0))
	helm.scale = Vector3(1, 0.9, 1)
	_part(_box(Vector3(0.04, 0.14, 0.03)), METAL, Vector3(0, 1.15, -0.22))
	# Arms
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.38, 0.95, 0)
	add_child(right_arm)
	_part(_capsule(0.08, 0.5), tunic, Vector3(0, -0.22, 0), right_arm)
	_part(_sphere(0.08), SKIN, Vector3(0, -0.47, 0), right_arm)
	_hand = Node3D.new()
	_hand.position = Vector3(0, -0.47, 0)
	_hand.rotation.x = deg_to_rad(-90)
	right_arm.add_child(_hand)
	set_held("")
	var left_arm := Node3D.new()
	left_arm.position = Vector3(-0.38, 0.95, 0)
	left_arm.rotation.x = deg_to_rad(-35)
	add_child(left_arm)
	_part(_capsule(0.08, 0.5), tunic, Vector3(0, -0.22, 0), left_arm)
	_part(_sphere(0.08), SKIN, Vector3(0, -0.47, 0), left_arm)
	left_hand = Node3D.new()
	left_hand.position = Vector3(0, -0.55, 0)
	left_arm.add_child(left_hand)
	_rest()


## Swing the pickaxe: wind up, strike (emits swing_impact), recover.
func swing(duration: float) -> void:
	if swinging:
		return
	swinging = true
	if dwarf_rig:
		dwarf_rig.play_upper("dig", duration)
		get_tree().create_timer(duration * 0.55).timeout.connect(func(): swing_impact.emit())
		get_tree().create_timer(duration).timeout.connect(func(): swinging = false)
		return
	if rig:
		_rig_play("Sword_Slash", duration)
		var t0 := get_tree().create_timer(duration * 0.6)
		t0.timeout.connect(func(): swing_impact.emit())
		get_tree().create_timer(duration).timeout.connect(func(): swinging = false)
		return
	var t := create_tween()
	t.tween_property(right_arm, "rotation:x", deg_to_rad(150), duration * 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(right_arm, "rotation:x", deg_to_rad(10), duration * 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(swing_impact.emit)
	t.tween_property(right_arm, "rotation:x", deg_to_rad(35), duration * 0.38).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): swinging = false)


## Weapon attack: wind up, strike at 40% of the time, recover.
func attack(duration: float, heavy: bool) -> void:
	swinging = true
	if dwarf_rig:
		dwarf_rig.attack(duration, heavy)
		get_tree().create_timer(duration).timeout.connect(func(): swinging = false)
		return
	if rig:
		_rig_play("Sword_Slash" if heavy else "Punch_Right", duration)
		get_tree().create_timer(duration).timeout.connect(func(): swinging = false)
		return
	var t := create_tween()
	t.tween_property(right_arm, "rotation:x", deg_to_rad(165 if heavy else 120), duration * 0.3).set_trans(Tween.TRANS_SINE)
	t.tween_property(right_arm, "rotation:x", deg_to_rad(-15), duration * 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(right_arm, "rotation:x", deg_to_rad(35), duration * 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): swinging = false)


## Shows the right thing in the hand: pickaxe, sword, mace… (models in src/art/tool_models.gd)
func set_held(item: String) -> void:
	if item == _held:
		return
	_held = item
	for c in _hand.get_children():
		c.queue_free()
	if item == "":
		return
	var col := Items.color(item)
	var kind := Items.kind(item)
	var look := Combat.weapon_of(item) if kind in ["weapon", "shield", "axe"] else kind
	_hand.add_child(ToolModels.build(look, col, VISUAL_LAYER))


## The rigged look: a CC0 character squashed into dwarf proportions, tools in its right hand,
## the lantern in its left.
func _build_rig() -> void:
	rig = (load(RIG_PATH) as PackedScene).instantiate()
	add_child(rig)
	rig.rotation.y = PI  # the model faces +Z; our dwarf faces -Z
	var sk: Skeleton3D = rig.find_children("*", "Skeleton3D", true, false)[0]
	# Measure the real height from the head bone in the world (skinned meshes report tiny boxes,
	# and the skeleton inside is turned and scaled ×100 because it came from Blender).
	var head_world := sk.global_transform * sk.get_bone_global_rest(sk.find_bone("Head")).origin
	var head_y := head_world.y - rig.global_position.y
	var s := 1.2 / head_y if head_y > 0.1 else 1.0
	rig.scale = Vector3(s * 1.25, s, s * 1.25)
	anim = rig.find_children("*", "AnimationPlayer", true, false)[0]
	var right := BoneAttachment3D.new()
	right.bone_name = "Wrist.R"
	sk.add_child(right)
	_hand = Node3D.new()
	_hand.rotation.x = deg_to_rad(-90)
	right.add_child(_hand)
	var left := BoneAttachment3D.new()
	left.bone_name = "Wrist.L"
	sk.add_child(left)
	left_hand = Node3D.new()
	left.add_child(left_hand)
	# Cancel every scale above the hands (our dwarf scale AND the model's hidden ×100),
	# so tools and the lantern keep their normal size.
	for h in [_hand, left_hand]:
		h.scale = Vector3.ONE / h.get_parent().global_transform.basis.get_scale()
	right_arm = Node3D.new()  # (not used by the rigged look, kept so other code works)
	add_child(right_arm)
	set_held("")
	_rig_play("Idle", 1.0)


func _rig_play(name: String, duration: float = 0.0) -> void:
	if anim == null:
		return
	var full := "CharacterArmature|" + name
	if not anim.has_animation(full):
		return
	var speed := 1.0
	if duration > 0.0 and name in ["Sword_Slash", "Punch_Right", "Roll"]:
		speed = anim.get_animation(full).length / duration
	anim.play(full, 0.15, speed)
	_rig_anim = name


## Walking/running/rolling animation for the rigged look (the shapes look ignores this).
func set_motion(speed: float, on_floor: bool, rolling: bool) -> void:
	if dwarf_rig:
		dwarf_rig.set_motion(speed, on_floor, rolling)
		return
	if rig == null or (swinging and not rolling):
		return
	var want := "Idle"
	if rolling:
		want = "Roll"
	elif not on_floor:
		want = _rig_anim if _rig_anim in ["Run", "Walk"] else "Idle"
	elif speed > 5.0:
		want = "Run"
	elif speed > 0.5:
		want = "Walk"
	if want != _rig_anim:
		_rig_play(want, 0.45 if want == "Roll" else 0.0)


## Held poses for the rigged dwarf: block (sword up), shield up, crossbow aim.
func set_pose(blocking: bool, aiming: bool, shield: bool) -> void:
	if dwarf_rig:
		dwarf_rig.set_hold("aim" if aiming else (("shield" if shield else "block") if blocking else ""))


## A short reaction: "hit", "knock", "block", "eat", "throw".
func react(what: String) -> void:
	if dwarf_rig == null:
		return
	match what:
		"hit":
			dwarf_rig.play_full("hit", 0.45)
		"knock":
			dwarf_rig.play_full("knock", 0.9)
		"eat":
			dwarf_rig.play_upper("eat", 1.2)
		"throw":
			dwarf_rig.play_upper("throw", 0.6)


## The real dwarf (see DwarfRig). Tools go in its right hand, the lantern in its left.
func _build_dwarf_rig() -> void:
	dwarf_rig = DwarfRig.new()
	dwarf_rig.name = "Rig"
	add_child(dwarf_rig)
	dwarf_rig.build(tunic)
	_hand = Node3D.new()
	_hand.rotation = hand_tool_rot
	_hand.position = hand_tool_pos
	_hand.scale = Vector3.ONE * 0.8  # tools were sized for the old, bigger placeholder
	dwarf_rig.right_hand.add_child(_hand)
	left_hand = dwarf_rig.left_hand
	right_arm = Node3D.new()  # (only used by the shapes look; kept so other code works)
	add_child(right_arm)
	set_held("")


func _rest() -> void:
	if right_arm:
		right_arm.rotation.x = deg_to_rad(35)


# ---------------------------------------------------------------- shape helpers

func _part(mesh: Mesh, color: Color, pos: Vector3, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	mi.layers = VISUAL_LAYER  # so the dwarf's own lantern can ignore its body for shadows
	parent.add_child(mi)
	return mi


func _mat(c: Color) -> Material:
	return Look.mat(c)


func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 8
	m.rings = 1
	return m


func _capsule(r: float, h: float) -> Mesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 4
	return m


func _sphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 6
	return m


func _hemisphere(r: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r
	m.is_hemisphere = true
	m.radial_segments = 10
	m.rings = 4
	return m


func _box(size: Vector3) -> Mesh:
	var m := BoxMesh.new()
	m.size = size
	return m
