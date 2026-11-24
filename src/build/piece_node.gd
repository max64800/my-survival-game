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
var plan := false  ## a blueprint's blue plan piece (set before adding it)
var capped := false  ## spiral stairs (F780): another flight sits on top (no landing rail, the post stops at the top)
static var _plan_mat: StandardMaterial3D
static var _mats := {}


func _ready() -> void:
	if ghost:
		collision_layer = 0
		collision_mask = 0
		if plan:  # every blue plan piece shares one glass (F565: fewer draw calls)
			if _plan_mat == null:
				_plan_mat = StandardMaterial3D.new()
				_plan_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				_plan_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				_plan_mat.albedo_color = Color(0.35, 0.6, 1.0, 0.3)
			_ghost_mat = _plan_mat
		else:
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
## stands against the wall's side and you can still aim at it to close it. They open either way:
## away from whoever opens them (1 = toward the door's front, -1 = toward its back).
var is_open := false
var _swing := 0.0  ## 0 = closed, 1 / -1 = fully open one way or the other
var _swing_tween: Tween


func set_open(open: int) -> void:
	is_open = open != 0
	var target := float(signi(open))
	if not is_inside_tree():
		_apply_swing(target)
		return
	if _swing_tween:
		_swing_tween.kill()
	_swing_tween = create_tween()
	_swing_tween.tween_method(_apply_swing, _swing, target, 0.35).set_trans(Tween.TRANS_SINE)


func _apply_swing(t: float) -> void:
	_swing = t
	var hinge := Vector3(-Pieces.LIST[piece].size.x * 0.5, 0, 0)
	var xf := Transform3D(Basis(Vector3.UP, -t * PI / 2.0), Vector3.ZERO)
	xf = Transform3D(Basis(), hinge) * xf * Transform3D(Basis(), -hinge)
	for c in get_children():
		if c is MeshInstance3D:
			(c as Node3D).transform = xf
		elif c is CollisionShape3D:
			(c as Node3D).transform = xf


## F810 (owner, Nov 23: "the side with the ring must always face outwards"): a double gate's right leaf is the left
## one turned round (so it hinges at the outer edge), which put its ring on the inside. Its look is mirrored front to
## back (the hinge side stays), so both rings face the gateway's front. The builder sets it (Builder._flip_gate_leaves).
var look_flipped := false


func set_look_flipped(f: bool) -> void:
	if f == look_flipped:
		return
	look_flipped = f
	# F813 (owner, Nov 23: "one of them is a lot darker"): mirroring with a -1 scale turned the leaf's light inside
	# out (it drew dark). Now its mesh is swapped for a real mirrored copy (front to back), lit like the other leaf.
	for c in get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var mi := c as MeshInstance3D
			if not mi.has_meta("plain_mesh"):
				mi.set_meta("plain_mesh", mi.mesh)
			var plain: Mesh = mi.get_meta("plain_mesh")
			mi.mesh = mirrored_z(plain) if f else plain


static var _mirrored := {}


## A copy of `mesh` mirrored front to back (z -> -z), with its normals, tangents and triangle order fixed so it
## lights like the original. Made once per mesh.
static func mirrored_z(mesh: Mesh) -> ArrayMesh:
	if _mirrored.has(mesh):
		return _mirrored[mesh]
	var out := ArrayMesh.new()
	for si in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(si)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		for i in v.size():
			v[i].z = -v[i].z
		a[Mesh.ARRAY_VERTEX] = v
		if a[Mesh.ARRAY_NORMAL] != null:
			var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			for i in n.size():
				n[i].z = -n[i].z
			a[Mesh.ARRAY_NORMAL] = n
		if a[Mesh.ARRAY_TANGENT] != null:
			var t: PackedFloat32Array = a[Mesh.ARRAY_TANGENT]
			for i in range(0, t.size(), 4):
				t[i + 2] = -t[i + 2]
				t[i + 3] = -t[i + 3]   # (mirroring flips its handedness)
			a[Mesh.ARRAY_TANGENT] = t
		if a[Mesh.ARRAY_INDEX] != null:
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
			for i in range(0, idx.size() - 2, 3):
				var k := idx[i + 1]
				idx[i + 1] = idx[i + 2]
				idx[i + 2] = k
			a[Mesh.ARRAY_INDEX] = idx
		else:   # (no index list: swap the vertices of each triangle instead)
			for key in a.size():
				if a[key] == null or key == Mesh.ARRAY_INDEX:
					continue
				var arr = a[key]
				var per: int = arr.size() / v.size() if v.size() > 0 else 1
				for i in range(0, v.size() - 2, 3):
					for j in per:
						var x = arr[(i + 1) * per + j]
						arr[(i + 1) * per + j] = arr[(i + 2) * per + j]
						arr[(i + 2) * per + j] = x
				a[key] = arr
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		out.surface_set_material(out.get_surface_count() - 1, mesh.surface_get_material(si))
	_mirrored[mesh] = out
	return out


func set_ghost_ok(ok: bool) -> void:
	if _ghost_mat:
		_ghost_mat.albedo_color = Color(0.3, 1.0, 0.4, 0.35) if ok else Color(1.0, 0.25, 0.2, 0.35)


## Blueprint plans show as blue glass (so they don't look like the green "OK" ghost).
func set_ghost_plan() -> void:
	if _ghost_mat:
		_ghost_mat.albedo_color = Color(0.35, 0.6, 1.0, 0.3)


## Rebuild for a different piece/material (the ghost changes when you pick something else).
## F162: log legs under a Shack foundation, each reaching down to the rock by itself (`drops` from
## Pieces.leg_drops: metres per leg; 0 or -1 = no extra leg). Stacked 1 m hewn sections, a stone at the foot.
var _legs: Node3D
var _leg_key := ""


func set_legs(drops: Array) -> void:
	var key := ",".join(drops.map(func(d): return str(snappedf(d, 0.1))))
	if key == _leg_key:
		return
	_leg_key = key
	if _legs:
		_legs.queue_free()
		_legs = null
	var spots := Pieces.leg_spots(piece, family)
	_legs = Node3D.new()
	add_child(_legs)
	for i in mini(spots.size(), drops.size()):
		var d: float = drops[i]
		if d < 0.05:
			continue
		var top := 0.15  # the new section starts inside the model's own leg
		var length := d + top
		var n := int(ceil(length / 1.0))
		var at := Vector3(spots[i].x, top, spots[i].y)
		for k in n:
			var mi := MeshInstance3D.new()
			mi.mesh = _part_mesh("foundation_leg__plank_root")
			if mi.mesh == null:
				var cm := CylinderMesh.new()
				cm.top_radius = 0.16
				cm.bottom_radius = 0.16
				cm.height = 1.0
				mi.mesh = cm
				mi.position.y = -0.5
			var seg := Node3D.new()
			seg.position = at + Vector3.DOWN * (length / n) * k
			seg.scale = Vector3(1, length / n, 1)  # at most stretched to 1 m, at least half
			seg.add_child(mi)
			_legs.add_child(seg)
			if ghost:
				mi.material_override = _ghost_mat
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var foot := MeshInstance3D.new()
		foot.mesh = _part_mesh("foundation_foot__plank_root")
		if foot.mesh:
			foot.position = Vector3(spots[i].x, -d, spots[i].y)
			if ghost:
				foot.material_override = _ghost_mat
			_legs.add_child(foot)
		if not ghost:  # you bump into the legs
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.16
			cyl.height = length
			cs.shape = cyl
			cs.position = Vector3(spots[i].x, top - length * 0.5, spots[i].y)
			add_child(cs)


static func _part_mesh(model: String) -> Mesh:
	if not _forged_meshes.has(model):
		var m: Mesh = null
		var scene := Look.forged("build", model) if use_models else null
		if scene:
			var parts := scene.find_children("*", "MeshInstance3D", true, false)
			if not parts.is_empty():
				m = (parts[0] as MeshInstance3D).mesh
			scene.free()
		_forged_meshes[model] = m
	return _forged_meshes[model]


func rebuild(p_piece: String, p_family: String) -> void:
	_leg_key = ""
	_legs = null
	piece = p_piece
	family = p_family
	for c in get_children():
		c.queue_free()
	_build()
	if look_flipped:   # (F813: the new look is mirrored again)
		look_flipped = false
		set_look_flipped(true)


## F780: spiral stairs with another flight on top swap to their "stacked" model (no landing rail across the way
## on up, the post stops at the top so the one above carries it on: no two posts in the same place).
func set_capped(on: bool) -> void:
	if on == capped:
		return
	capped = on
	rebuild(piece, family)


static func stacked_mesh(p_family: String) -> Mesh:
	var key := "stairs_spiral_stacked__" + p_family
	if not _forged_meshes.has(key):
		var m: Mesh = null
		var scene := Look.forged("build", key) if use_models else null
		if scene:
			var parts := scene.find_children("*", "MeshInstance3D", true, false)
			if parts.size() == 1:
				m = (parts[0] as MeshInstance3D).mesh
			scene.free()
		_forged_meshes[key] = m
	return _forged_meshes[key]


static var _forged_meshes := {}
static var _fire_spots := {}  ## piece__family -> [[position, size]] from the model's fire_spot markers


## Claude 2's hand-made model for this piece + material (assets/models/build/<piece>__<family>.glb),
## or null to use the shape made in code. Built in the same piece space as PieceMesh, so it lines up
## with the solid shape. Only the look changes; bumping into it still uses PieceMesh.solid().
static var use_models := true  ## false = always the shapes made in code (robots: `nomodels`)


## F565: a build site starts reading its pieces' models in the background, so the first wall or floor of a kind
## doesn't freeze the game for 50-100 ms while its file is read.
static func start_loading(p_piece: String, p_family: String) -> void:
	var key := p_piece + "__" + p_family
	if not use_models or _forged_meshes.has(key) or not Pieces.LIST.has(p_piece):
		return
	var model: String = Pieces.LIST[p_piece].get("model", "build/" + key)
	Look.start_loading(model.get_slice("/", 0), model.get_slice("/", 1))


static func forged_mesh(p_piece: String, p_family: String) -> Mesh:
	if not use_models:
		return null
	var key := p_piece + "__" + p_family
	var model: String = Pieces.LIST[p_piece].get("model", "build/" + key)  # wall decor: one model for every wood
	if not _forged_meshes.has(key):
		var m: Mesh = null
		var scene := Look.forged(model.get_slice("/", 0), model.get_slice("/", 1))
		if scene:
			var parts := scene.find_children("*", "MeshInstance3D", true, false)
			if parts.size() == 1:
				m = (parts[0] as MeshInstance3D).mesh  # one baked mesh, as agreed with Claude 2
				var why := model_misfit(p_piece, m.get_aabb())
				if why == "" and floating_parts(p_piece, m) > 0:
					why = "%d separate parts: something floats" % PieceMesh.islands(m).size()
				if why != "":
					print("Model skipped: %s.glb doesn't fit its piece (%s); using the code shape" % [key, why])
					m = null
			elif parts.size() > 1:
				push_warning("%s.glb has %d meshes; expected 1 (using the code shape)" % [key, parts.size()])
			var spots: Array = []  # fire markers (fire_spot_<size>, kit.fire_spot): where its fire burns (the Fire Bowl)
			for n: Node in scene.find_children("fire_spot_*", "", true, false):
				if n is Node3D:
					var size := String(n.name).trim_prefix("fire_spot_").replace("_", ".").to_float()  # (Godot turns "1.40" into "1_40")
					spots.append([(n as Node3D).position, maxf(size, 0.3)])
			_fire_spots[key] = spots
			scene.free()
		_forged_meshes[key] = m
	return _forged_meshes[key]


## How many parts of a model float: every part but one, or for wreckage lying in pieces (Pieces "lies_in_parts",
## the Spire's fallen top broke in two, F479) every part that doesn't rest on the ground.
static func floating_parts(p_piece: String, m: Mesh) -> int:
	var parts := PieceMesh.islands(m)
	if Pieces.LIST.get(p_piece, {}).get("lies_in_parts", false):
		return parts.filter(func(b: AABB): return b.position.y > 0.1).size()
	return parts.size() - 1


## Why a model's box doesn't match the piece it's for ("" = it fits). Catches models made for an
## old shape (the half-square triangles became 60° ones), sunk in or floating above the base,
## or built off-centre. A model may be up to 20% (at least 16 cm) bigger: sills, handles, wider
## pillar feet, overhanging shingles. Smaller is fine down to half (a slim sconce).
static func model_misfit(p_piece: String, box: AABB) -> String:
	var want := Pieces.box(p_piece, Vector3.ZERO, 0)
	var lift: float = Pieces.LIST[p_piece].get("model_lift", 0.1)  # how high a model may start (stair railing: on the steps)
	if box.position.y < -0.1 or box.position.y > lift:
		return "bottom at %.2f m, should be 0" % box.position.y
	for axis in [0, 2]:
		var w: float = want.size[axis]
		if box.size[axis] > w + maxf(0.2 * w, 0.16) or box.size[axis] < 0.5 * w:
			return "%s size %.2f m, should be %.2f" % ["xyz"[axis], box.size[axis], w]
		if absf(box.get_center()[axis] - want.get_center()[axis]) > maxf(0.1 * w, 0.12):
			return "%s middle at %.2f m, should be %.2f" % ["xyz"[axis], box.get_center()[axis], want.get_center()[axis]]
	# Wall decor hangs on the wall: a model still standing on a floor post is too tall.
	if Pieces.LIST[p_piece].get("on_wall", false) and box.size.y > want.size.y * 1.2 + 0.05:
		return "y size %.2f m, should be %.2f (hangs on a wall, no floor post)" % [box.size.y, want.size.y]
	return ""


func _build() -> void:
	var s: Vector3 = Pieces.LIST[piece].size
	# The look: one shared, detailed shape per piece + material (PieceMesh, spec §6).
	var mi := MeshInstance3D.new()
	_look = mi
	# Ghosts use the code shape, except furniture: its real outline, like a crafting bench's (F726: it was a box).
	var made := forged_mesh(piece, family) if not ghost or (Pieces.turns_freely(piece) and not plan) else null
	if capped and not ghost:
		made = stacked_mesh(family)
	mi.mesh = made if made else PieceMesh.visual(piece, family)
	mi.material_override = _ghost_mat if ghost else (null if made else _mat(family))
	if ghost:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# The solid shape: a smooth ramp for steps (nice to walk up), the plain outline for the rest.
	if not ghost:
		if Pieces.LIST[piece].get("walkable_slope", false):
			_ramp_shape(s)
		elif made and Pieces.LIST[piece].get("collide_as_model", false):
			_model_slices(made, s)
		else:
			var cs := CollisionShape3D.new()
			cs.shape = PieceMesh.solid(piece).create_trimesh_shape()
			add_child(cs)
	if Pieces.FAMILIES[family].get("glow", false) and not ghost:
		var l := OmniLight3D.new()
		GraphicsSettings.cheap_light(l, 30.0)  # off smoothly when far away (owner, Nov 19)
		l.light_color = Pieces.FAMILIES[family].color
		l.omni_range = 5.0
		l.light_energy = 0.6
		Darkness.mark(l)
		l.position = Vector3(0, s.y * 0.5, 0)
		add_child(l)
	_decor_extras(s, made != null)
	if not ghost and gap_fill.y > 0.0:
		_add_gap_fill()


## F833 🔁 (F165): a wall, window or doorway standing on another one with no floor between leaves a 25 cm slit
## (walls are 2 m, a storey 2.25 m; a floor's rim beam fills it when there is a floor). Builder._refill_gaps
## then gives the lower piece a beam on its top: this material's own Beam model, squeezed into the slit.
## `gap_fill` = (from x, gap height, to x) along the wall, in the piece's own space; y = 0 means none.
## The beam reaches 1 cm into both walls (no slit left) and stands 1.5 cm proud of their faces (no shimmer).
var gap_fill := Vector3.ZERO
var _gap_node: Node3D
const GAP_OVERLAP := 0.01
const GAP_PROUD := 0.015


func set_gap_fill(fill: Vector3) -> void:
	if fill.is_equal_approx(gap_fill):
		return
	gap_fill = fill
	if _gap_node and is_instance_valid(_gap_node):
		_gap_node.queue_free()
	_gap_node = null
	if fill.y > 0.0 and not ghost and is_inside_tree():
		_add_gap_fill()


func _add_gap_fill() -> void:
	var s: Vector3 = Pieces.LIST[piece].size
	var box := Vector3(gap_fill.z - gap_fill.x, gap_fill.y + GAP_OVERLAP * 2.0, s.z + GAP_PROUD * 2.0)
	var centre := Vector3((gap_fill.x + gap_fill.z) * 0.5, s.y + gap_fill.y * 0.5, 0.0)
	var holder := Node3D.new()
	holder.name = "GapFill"
	_gap_node = holder
	var mi := MeshInstance3D.new()
	var made := forged_mesh("beam", family)
	mi.mesh = made if made else PieceMesh.visual("beam", family)
	if not made:
		mi.material_override = _mat(family)
	var aabb := mi.mesh.get_aabb()
	var k := Vector3(box.x / maxf(aabb.size.x, 0.01), box.y / maxf(aabb.size.y, 0.01), box.z / maxf(aabb.size.z, 0.01))
	mi.scale = k
	mi.position = centre - aabb.get_center() * k
	holder.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(box.x, gap_fill.y, s.z)
	cs.shape = shape
	cs.position = centre
	holder.add_child(cs)
	add_child(holder)


## Decor pieces: cloth parts (rug, banner) in their own colour, and the sconce's glowing crystal.
func _decor_extras(s: Vector3, has_model: bool) -> void:
	var info: Dictionary = Pieces.LIST[piece]
	if info.has("cloth") and not has_model:
		var c: Color = info.cloth
		if piece == "rug":
			_cloth(Vector3(s.x - 0.12, 0.02, s.z - 0.12), Vector3(0, 0.03, 0), c)
			_cloth(Vector3(s.x * 0.6, 0.02, s.z * 0.5), Vector3(0, 0.035, 0), Color(0.78, 0.6, 0.3))  # a gold middle
		else:
			_cloth(Vector3(s.x, s.y - 0.15, 0.03), Vector3(0, (s.y - 0.1) * 0.5, 0.0), c)
			_cloth(Vector3(0.3, 0.3, 0.035), Vector3(0, s.y * 0.6, 0.0), Color(0.85, 0.65, 0.25))  # a gold emblem
	if info.get("fire", false) and not ghost:
		# A fire that burns forever (the Fire Bowl, F479): on the model's fire_spot markers, or on top without a model.
		var spots: Array = _fire_spots.get(piece + "__" + family, []) if has_model else []
		if spots.is_empty():
			spots = [[Vector3(0, s.y, 0), 1.0]]
		for sp in spots:
			var fire := Fire.new(float(sp[1]))
			fire.position = sp[0]
			add_child(fire)
		var l := OmniLight3D.new()
		GraphicsSettings.cheap_light(l, 60.0)  # a beacon: seen from further than a sconce
		l.light_color = Color(1.0, 0.6, 0.3)
		l.omni_range = 14.0
		l.light_energy = 2.0
		Darkness.mark(l)
		l.position = (spots[0][0] as Vector3) + Vector3.UP * 0.6
		add_child(l)
	if info.has("light"):
		if not has_model:
			_cloth(Vector3(0.1, 0.16, 0.1), Vector3(0, s.y * 0.45 + 0.12, 0.04), info.light, true)
		if not ghost:
			var l := OmniLight3D.new()
			GraphicsSettings.cheap_light(l, 30.0)  # off smoothly when far away (owner, Nov 19)
			l.light_color = info.light
			l.omni_range = 7.0
			l.light_energy = 1.2
			Darkness.mark(l)
			l.position = Vector3(0, s.y * 0.6, 0.25)
			add_child(l)


func _cloth(size: Vector3, pos: Vector3, c: Color, glow: bool = false) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _ghost_mat if ghost else Look.mat(c, "", 2.0 if glow else 0.0)
	if ghost:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


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
## F715 (owner, Nov 22: "these walls need a better collision... I was trying to jump over them and I couldn't"): a
## broken wall collides as its real broken top, not the whole wall: 8 upright slices along it, each as tall as the
## model's stones in that slice (a slice with no stone is a gap you can walk through). Worked out once per model.
static var _slices := {}
const SLICES := 8


func _model_slices(made: Mesh, s: Vector3) -> void:
	var key := "%s/%s" % [piece, family]
	if not _slices.has(key):
		var tops := PackedFloat32Array()
		tops.resize(SLICES)
		tops.fill(0.0)
		var lo := -s.x * 0.5
		var w := s.x / SLICES
		for si in made.get_surface_count():
			var arr := made.surface_get_arrays(si)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var n := idx.size() if idx.size() > 0 else v.size()
			for t in range(0, n - 2, 3):
				var a := v[idx[t]] if idx.size() > 0 else v[t]
				var b := v[idx[t + 1]] if idx.size() > 0 else v[t + 1]
				var c := v[idx[t + 2]] if idx.size() > 0 else v[t + 2]
				var k0 := clampi(int(floor((minf(a.x, minf(b.x, c.x)) - lo) / w)), 0, SLICES - 1)
				var k1 := clampi(int(floor((maxf(a.x, maxf(b.x, c.x)) - lo) / w - 0.001)), 0, SLICES - 1)
				for k in range(k0, k1 + 1):
					tops[k] = maxf(tops[k], _top_in_slab([a, b, c], lo + k * w, lo + (k + 1) * w))
		_slices[key] = tops
	var tops: PackedFloat32Array = _slices[key]
	for k in SLICES:
		if tops[k] < 0.05:
			continue
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(s.x / SLICES, minf(tops[k], s.y), s.z)
		cs.shape = box
		cs.position = Vector3(-s.x * 0.5 + (k + 0.5) * s.x / SLICES, box.size.y * 0.5, 0.0)
		add_child(cs)


## The highest point of a triangle between x0 and x1 (its corners in there, and where its edges cross x0 and x1).
static func _top_in_slab(t: Array, x0: float, x1: float) -> float:
	var top := -1.0
	for i in 3:
		var p: Vector3 = t[i]
		var q: Vector3 = t[(i + 1) % 3]
		if p.x >= x0 and p.x <= x1:
			top = maxf(top, p.y)
		for x in [x0, x1]:
			if (p.x - x) * (q.x - x) < 0.0:
				top = maxf(top, lerpf(p.y, q.y, (x - p.x) / (q.x - p.x)))
	return top


func _ramp_shape(s: Vector3) -> void:
	var cs := CollisionShape3D.new()
	if piece == "stairs_corner":
		# F781 🔁 (owner, Nov 23: still jitters walking up): as their real 25 cm steps, every step was a bump, a stop
		# and a 25 cm pop. Now they're one smooth bent sheet that climbs evenly round the post (like the spiral
		# stairs), plus the post. It's steep (about 55 degrees halfway out, 70 near the post), so the dwarf counts
		# stairs as ground up to Dwarf.STAIRS_FLOOR_ANGLE while he's on them.
		cs.shape = corner_slope(s, lip)
		_slope = cs
		add_child(cs)
		var post := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(0.3, s.y, 0.3)
		post.shape = bx
		post.position = Vector3(-s.x * 0.5 + 0.16, s.y * 0.5, s.z * 0.5 - 0.16)
		add_child(post)
		return
	if piece == "stairs_spiral":
		# F716: a smooth spiral slope of slanted treads, the post, the landing (and its pillar), the outside
		# corner pillars and the rails, so you can't fall off the open side.
		# F781 (owner, Nov 22: "very jittery"): the slope is one smooth bent sheet (a single trimesh: no seams between
		# separate pieces for the dwarf's feet to catch on). The thin parts (post, rails, pillars) sit on their own
		# body on the piece layer only: dwarfs and monsters still bump into them, but the camera doesn't, so it no
		# longer jumps in and out every time a rail or the post passes between it and the dwarf.
		var thin := StaticBody3D.new()
		thin.name = "Thin"
		thin.collision_layer = 0 if ghost else PIECE_LAYER
		thin.collision_mask = 0
		thin.set_meta("piece_uid", uid)
		add_child(thin)
		var post := CylinderShape3D.new()
		post.radius = PieceMesh.SPIRAL_POST
		post.height = s.y + (0.0 if capped else 0.95)  # (F780: a spiral on top carries the post on up)
		cs.shape = post
		cs.position = Vector3(0, post.height * 0.5, 0)
		thin.add_child(cs)
		var slope := CollisionShape3D.new()
		var sheet := ConcavePolygonShape3D.new()
		# The landing's top is part of the same sheet (a box's side edge, 25 cm thick, caught the dwarf's side
		# on the last tread and bumped him up).
		var faces := PieceMesh.spiral_slope_faces(s)
		var l := 1.99
		faces.append_array([Vector3(0, s.y, 0), Vector3(l, s.y, 0), Vector3(l, s.y, l), Vector3(0, s.y, 0), Vector3(l, s.y, l), Vector3(0, s.y, l)])
		sheet.set_faces(faces)
		sheet.backface_collision = true
		slope.shape = sheet
		add_child(slope)
		var boxes := [[Vector3(1.72, PieceMesh.SPIRAL_LANDING * 0.5, 1.72), Vector3(0.24, PieceMesh.SPIRAL_LANDING, 0.24)]]
		for a in [PI * 0.25, PI * 0.75, PI * 1.25]:
			var c := PieceMesh._sq(a, 1.73)
			var h := PieceMesh.spiral_slope_y(s, a) + PieceMesh.SPIRAL_RAIL_H
			boxes.append([Vector3(c.x, h * 0.5, c.y), Vector3(0.22, h, 0.22)])
		for b in boxes:
			var bs := BoxShape3D.new()
			bs.size = b[1]
			var part := CollisionShape3D.new()
			part.shape = bs
			part.position = b[0]
			thin.add_child(part)
		for pts: PackedVector3Array in PieceMesh.spiral_rail_parts(s, not capped):
			var part := CollisionShape3D.new()
			var hull := ConvexPolygonShape3D.new()
			hull.points = pts
			part.shape = hull
			thin.add_child(part)
		return
	var sh := ConvexPolygonShape3D.new()
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	sh.points = PackedVector3Array([
		Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz),
		Vector3(-hx, s.y, -hz), Vector3(hx, s.y, -hz)])
	if piece == "stairs":
		sh = stairs_slope(s, lip)
		_slope = cs
	cs.shape = sh
	add_child(cs)


## The corner stairs' walking surface: from the foot (+z side, at the floor) it climbs evenly with the angle round
## the post at the turn up to its top step, which then rises LIP more with `p_lip` (to the next floor's top; you can
## step off it on its -x side or at its -z end). Open underneath.
static func corner_slope(s: Vector3, p_lip: bool) -> ConcavePolygonShape3D:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var h := s.y + (LIP if p_lip else 0.0)
	var c := Vector2(-hx, hz)   # the turn (where the post stands)
	var far := atan2(2.0 * hz, 2.0 * hx)   # the back-right corner's angle
	var top_a := PI * 0.5 * 7.0 / 8.0   # where the top step (of 8) starts
	var angles := []
	var n := 24
	for k in n + 1:
		var a := PI * 0.5 * k / n
		if not angles.is_empty() and angles[-1] < far - 0.0001 and a > far + 0.0001:
			angles.append(far)
		angles.append(a)
	var ring := func(a: float, out: bool) -> Vector3:
		var e := PieceMesh._square_exit(c, a, hx, hz)
		var q := e if out else c + (e - c).normalized() * 0.3   # (inside 0.3 m is the post)
		# up to the top step's height at the top step's start (like the real steps), then over the top step up the lip
		var y := s.y * minf(a / top_a, 1.0) + (h - s.y) * maxf(0.0, (a - top_a) / (PI * 0.5 - top_a))
		return Vector3(q.x, y, q.y)
	var faces := PackedVector3Array()
	for k in angles.size() - 1:
		var i0: Vector3 = ring.call(angles[k], false)
		var o0: Vector3 = ring.call(angles[k], true)
		var i1: Vector3 = ring.call(angles[k + 1], false)
		var o1: Vector3 = ring.call(angles[k + 1], true)
		faces.append_array([i0, o0, o1, i0, o1, i1])
	var sh := ConcavePolygonShape3D.new()
	sh.backface_collision = true
	sh.set_faces(faces)
	return sh


## A straight stairs' solid shape: a slanted slab you walk up, open underneath so you can walk under the stairs
## (owner, Nov 16). `lip`: it climbs LIP higher than its steps, to the top of the next floor's slab (F803).
static func stairs_slope(s: Vector3, p_lip: bool) -> ConvexPolygonShape3D:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var h := s.y + (LIP if p_lip else 0.0)
	var t := PieceMesh.STAIRS_UNDER  # how thick the slab is, straight down (F169: like the open models)
	var zt := hz - t * (2.0 * hz / h)  # where its underside meets the floor
	var sh := ConvexPolygonShape3D.new()
	sh.points = PackedVector3Array([
		Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(-hx, 0, zt), Vector3(hx, 0, zt),
		Vector3(-hx, h, -hz), Vector3(hx, h, -hz), Vector3(-hx, h - t, -hz), Vector3(hx, h - t, -hz)])
	return sh


## F803 (owner, Nov 23: going down "feels like jumping"): the next floor's slab usually sits 25 cm above a straight
## stairs' top step (floors are 2.25 m apart, stairs 2 m). Walking down, the dwarf's round feet rolled off that
## edge, lost the floor and fell in an arc over the whole flight (40 frames in the air). Where such a slab is
## (Builder._relip_stairs sets `lip`), the solid slope climbs those 25 cm too (48 degrees, still walkable) and
## meets the slab's top: no edge left. (The steps' look stays; the feet ride at most 25 cm over the top step.)
const LIP := 0.25
var lip := false
var _slope: CollisionShape3D


func set_lip(on: bool) -> void:
	if on == lip:
		return
	lip = on
	if _slope and is_instance_valid(_slope):
		var sz: Vector3 = Pieces.LIST[piece].size
		_slope.shape = corner_slope(sz, lip) if piece == "stairs_corner" else stairs_slope(sz, lip)


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
		var m := Look.mat(f.color, surface, 1.5 if f.get("glow", false) else 0.0)
		# No rim light on building pieces (F58): Godot's rim brightens every surface seen edge-on, no
		# matter where the light is. A stone wall is dozens of small blocks with gaps, so turning the
		# camera made white streaks on all their edges. Props and monsters keep their rim.
		if m is ShaderMaterial:
			m = m.duplicate()
			(m as ShaderMaterial).set_shader_parameter("rim", 0.0)
		_mats[fam] = m
	return _mats[fam]
