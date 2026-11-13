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


func _build() -> void:
	var s: Vector3 = Pieces.LIST[piece].size
	match piece:
		"doorway", "window_wall":
			var hole: Vector3 = Pieces.LIST[piece].opening
			var side := (s.x - hole.x) * 0.5
			var bottom: float = hole.z
			var top := s.y - bottom - hole.y
			_box(Vector3(side, s.y, s.z), Vector3(-(hole.x + side) * 0.5, s.y * 0.5, 0))
			_box(Vector3(side, s.y, s.z), Vector3((hole.x + side) * 0.5, s.y * 0.5, 0))
			if top > 0.01:
				_box(Vector3(hole.x, top, s.z), Vector3(0, s.y - top * 0.5, 0))
			if bottom > 0.01:
				_box(Vector3(hole.x, bottom, s.z), Vector3(0, bottom * 0.5, 0))
		"stairs":
			for i in 4:
				var h := (i + 1) * s.y / 4.0
				_box(Vector3(s.x, h, s.z / 4.0), Vector3(0, h * 0.5, s.z * 0.5 - (i + 0.5) * s.z / 4.0), false)
			if not ghost:
				_ramp_shape(s)
		"mine_prop":
			_box(Vector3(0.3, s.y - 0.3, 0.3), Vector3(-0.8, (s.y - 0.3) * 0.5, 0))
			_box(Vector3(0.3, s.y - 0.3, 0.3), Vector3(0.8, (s.y - 0.3) * 0.5, 0))
			_box(Vector3(s.x, 0.3, s.z), Vector3(0, s.y - 0.15, 0))
		"pillar":
			_box(s, Vector3(0, s.y * 0.5, 0))
			_box(Vector3(s.x + 0.15, 0.15, s.z + 0.15), Vector3(0, 0.075, 0), false)
			_box(Vector3(s.x + 0.15, 0.15, s.z + 0.15), Vector3(0, s.y - 0.075, 0), false)
		_:
			_box(s, Vector3(0, s.y * 0.5, 0))
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
		var m := StandardMaterial3D.new()
		m.albedo_color = f.color
		m.roughness = 0.85 if not f.get("glow", false) else 0.2
		if f.get("glow", false):
			m.emission_enabled = true
			m.emission = f.color
			m.emission_energy_multiplier = 1.5
		_mats[fam] = m
	return _mats[fam]
