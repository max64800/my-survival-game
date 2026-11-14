class_name PieceNode
extends StaticBody3D
## One built piece in the world: its look and its solid shape.
## Placeholder looks (boxes in the material's color) until the art pack arrives.

const PIECE_LAYER := 32

var uid := 0
var piece := "wall"
var family := "plank_root"
var ghost := false  ## true = the see-through preview while placing
var _ghost_mat: StandardMaterial3D
static var _mats := {}


func _ready() -> void:
	if ghost:
		collision_layer = 0
		collision_mask = 0
		_ghost_mat = StandardMaterial3D.new()
		_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ghost_mat.albedo_color = Color(0.3, 1.0, 0.4, 0.35)
	else:
		collision_layer = PIECE_LAYER | World.TERRAIN_LAYER  # walkable like ground
		collision_mask = 0
		set_meta("piece_uid", uid)
	_build()
	set_process(false)  # only trembling pieces need a per-frame update


var _look: MeshInstance3D
var _shaking := false
var _shake_t := 0.0
static var _tints := {}


## Soft physics: a piece about to give way trembles (only its look moves, not its solid shape).
func set_shaking(on: bool) -> void:
	_shaking = on
	set_process(on)
	if not on and _look:
		_look.position = Vector3.ZERO


func _process(delta: float) -> void:
	if not _shaking or _look == null:
		return
	_shake_t += delta
	var a := 0.03 + 0.03 * minf(_shake_t / 2.0, 1.0)  # shakes harder as it gets closer to falling
	_look.position = Vector3(randf_range(-a, a), randf_range(-a, a) * 0.5, randf_range(-a, a))


## While the Build Hammer is out, every piece glows faintly in its strength color (spec §5).
## Pass Color(0,0,0,0) to clear it.
func set_tint(c: Color) -> void:
	if _look == null:
		return
	if c.a <= 0.0:
		_look.material_overlay = null
		return
	if not _tints.has(c):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(c.r, c.g, c.b, 0.28)
		m.cull_mode = BaseMaterial3D.CULL_BACK
		_tints[c] = m
	_look.material_overlay = _tints[c]


## Doors swing open on their left hinge (look and solid shape together), so an open door
## stands against the wall's side and you can still aim at it to close it.
var is_open := false
var _swing := 0.0  ## 0 = closed, 1 = fully open
var _swing_tween: Tween


func set_open(open: bool) -> void:
	is_open = open
	if not is_inside_tree():
		_apply_swing(1.0 if open else 0.0)
		return
	if _swing_tween:
		_swing_tween.kill()
	_swing_tween = create_tween()
	_swing_tween.tween_method(_apply_swing, _swing, 1.0 if open else 0.0, 0.35).set_trans(Tween.TRANS_SINE)


func _apply_swing(t: float) -> void:
	_swing = t
	var hinge := Vector3(-Pieces.LIST[piece].size.x * 0.5, 0, 0)
	var xf := Transform3D(Basis(Vector3.UP, -t * PI / 2.0), Vector3.ZERO)
	xf = Transform3D(Basis(), hinge) * xf * Transform3D(Basis(), -hinge)
	for c in get_children():
		if c is MeshInstance3D or c is CollisionShape3D:
			(c as Node3D).transform = xf


func set_ghost_ok(ok: bool) -> void:
	if _ghost_mat:
		_ghost_mat.albedo_color = Color(0.3, 1.0, 0.4, 0.35) if ok else Color(1.0, 0.25, 0.2, 0.35)


## Blueprint plans show as blue glass (so they don't look like the green "OK" ghost).
func set_ghost_plan() -> void:
	if _ghost_mat:
		_ghost_mat.albedo_color = Color(0.35, 0.6, 1.0, 0.3)


## Rebuild for a different piece/material (the ghost changes when you pick something else).
func rebuild(p_piece: String, p_family: String) -> void:
	piece = p_piece
	family = p_family
	for c in get_children():
		c.queue_free()
	_build()


static var _forged_meshes := {}


## Claude 2's hand-made model for this piece + material (assets/models/build/<piece>__<family>.glb),
## or null to use the shape made in code. Built in the same piece space as PieceMesh, so it lines up
## with the solid shape. Only the look changes; bumping into it still uses PieceMesh.solid().
static func forged_mesh(p_piece: String, p_family: String) -> Mesh:
	var key := p_piece + "__" + p_family
	if not _forged_meshes.has(key):
		var m: Mesh = null
		var scene := Look.forged("build", key)
		if scene:
			var parts := scene.find_children("*", "MeshInstance3D", true, false)
			if parts.size() == 1:
				m = (parts[0] as MeshInstance3D).mesh  # one baked mesh, as agreed with Claude 2
			elif parts.size() > 1:
				push_warning("%s.glb has %d meshes; expected 1 (using the code shape)" % [key, parts.size()])
			scene.free()
		_forged_meshes[key] = m
	return _forged_meshes[key]


func _build() -> void:
	var s: Vector3 = Pieces.LIST[piece].size
	# The look: one shared, detailed shape per piece + material (PieceMesh, spec §6).
	var mi := MeshInstance3D.new()
	_look = mi
	var made := forged_mesh(piece, family) if not ghost else null
	mi.mesh = made if made else PieceMesh.visual(piece, family)
	mi.material_override = _ghost_mat if ghost else (null if made else _mat(family))
	if ghost:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# The solid shape: a smooth ramp for steps (nice to walk up), the plain outline for the rest.
	if not ghost:
		if Pieces.LIST[piece].get("walkable_slope", false):
			_ramp_shape(s)
		else:
			var cs := CollisionShape3D.new()
			cs.shape = PieceMesh.solid(piece).create_trimesh_shape()
			add_child(cs)
	if Pieces.FAMILIES[family].get("glow", false) and not ghost:
		var l := OmniLight3D.new()
		l.light_color = Pieces.FAMILIES[family].color
		l.omni_range = 5.0
		l.light_energy = 0.6
		l.position = Vector3(0, s.y * 0.5, 0)
		add_child(l)


func _box(size: Vector3, pos: Vector3, solid: bool = true) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _ghost_mat if ghost else _mat(family)
	mi.position = pos
	if ghost:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if solid and not ghost and piece != "stairs":
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		cs.position = pos
		add_child(cs)


## Stairs collide like a smooth ramp, so walking up them feels nice.
func _ramp_shape(s: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var sh := ConvexPolygonShape3D.new()
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	sh.points = PackedVector3Array([
		Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz),
		Vector3(-hx, s.y, -hz), Vector3(hx, s.y, -hz)])
	cs.shape = sh
	add_child(cs)


static func _mat(fam: String) -> Material:
	if not _mats.has(fam):
		var f: Dictionary = Pieces.FAMILIES[fam]
		var surface := "stone"
		if fam.begins_with("plank"):
			surface = "wood"
		elif fam == "mushroom_brick":
			surface = "fungus"
		elif fam.ends_with("ingot"):
			surface = "metal"
		elif f.get("glow", false):
			surface = "smooth"
		_mats[fam] = Look.mat(f.color, surface, 1.5 if f.get("glow", false) else 0.0)
	return _mats[fam]
