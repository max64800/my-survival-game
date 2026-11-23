class_name CameraFade
extends RefCounted
## F807 (owner, Nov 23, "best case"): a built piece between the camera and the dwarf turns see-through, so you
## always see him (the rock already does this with its speckle, F766). Each frame a fat invisible tube from the
## camera to his chest asks "which pieces are in here?". Those get the see-through paint (see_through.gdshaderinc):
## a CIRCLE round him on screen, almost fully clear in the middle and less and less clear toward the corners.
## Their "see_amount" fades in to DwarfFeel.CAM_BUILD_FADE; the rest fade back and get their own paint again.
## Only on your own screen: nothing is sent to the other players.

## The tube stops this far (m) short of his chest. (It was "85% of the way" until Nov 23: with the camera far back
## that left a metre out, so an upper floor right over his head stayed solid. The floor he stands on is kept
## solid by the floors-below-his-chest rule instead, and the paint never cuts anything behind him.)
const TUBE_STOP := 0.35
const MAX_HITS := 128
## The search over the whole screen may hand back this many. (It was 128 until Nov 23: in the Twin Gate the floors
## under him filled the list first, so some slabs over his head stayed solid, a different few each frame.)
const SCREEN_HITS := 4096
## Once something was in the way, keep the whole-screen circle on this long (s), so it doesn't blink off when the
## line from the camera slips through a gap between two slabs.
const HOLD := 0.4

static var _see_shader: Shader        ## the stand-in paint for two-sided models ...
static var _see_shader_one: Shader    ## ... and for one-sided ones
static var _swaps := {}               ## a model's own paint -> its see-through stand-in (shared by every piece)

var _faded := {}  ## PieceNode instance id -> [piece, how see-through it is now (0..1), _swap_in()'s answer]
var _shape := CapsuleShape3D.new()
var _screen := ConvexPolygonShape3D.new()
var _hold := 0.0   ## seconds left of the whole-screen circle


## `from` = the camera, `to` = his chest. `exclude` = his own body. `cam` = the camera itself (tests leave it out):
## as soon as anything is in the way, EVERY piece on screen that is nearer than him gets the circle paint, so the
## circle runs smoothly across neighbouring pieces (owner, Nov 23: with only the pieces right on the line, the slabs
## next to it stayed solid and still hid him).
func update(world: World3D, from: Vector3, to: Vector3, delta: float, exclude: Array[RID] = [], on := true,
		cam: Camera3D = null) -> void:
	var want := {}
	var amount := DwarfFeel.CAM_BUILD_FADE
	if on and amount > 0.0 and world and from.distance_to(to) > 0.3:
		RenderingServer.global_shader_parameter_set("see_target", to)
		RenderingServer.global_shader_parameter_set("see_cam", from)
		RenderingServer.global_shader_parameter_set("see_shape", Vector3(DwarfFeel.CAM_CIRCLE_MIDDLE,
			DwarfFeel.CAM_CIRCLE_CORNERS, DwarfFeel.CAM_CIRCLE_SIZE))
		var blocking := _pieces_between(world, from, to.move_toward(from, TUBE_STOP), to.y, exclude)
		_hold = HOLD if not blocking.is_empty() else maxf(_hold - delta, 0.0)
		if _hold > 0.0 and cam and cam.is_inside_tree():
			blocking.append_array(_pieces_on_screen(world, cam, to, exclude))   # (doubles drop out below)
		for p in blocking:
			want[p.get_instance_id()] = p
	for id in want:
		if not _faded.has(id):
			_faded[id] = [want[id], 0.0, _swap_in(want[id])]
	var step := delta * DwarfFeel.CAM_BUILD_FADE_SPEED
	for id in _faded.keys():
		var entry: Array = _faded[id]
		if not is_instance_valid(entry[0]):   # (removed while faded: just forget it)
			_faded.erase(id)
			continue
		entry[1] = move_toward(entry[1], amount if want.has(id) else 0.0, step)
		_set_see_through(entry[2], entry[1])
		if entry[1] <= 0.0 and not want.has(id):
			_swap_out(entry[2])
			_faded.erase(id)


## How see-through this piece is right now (0 = solid). For tests.
func faded(p: Node) -> float:
	var entry: Array = _faded.get(p.get_instance_id(), [])
	return entry[1] if entry.size() > 1 else 0.0


func _pieces_between(world: World3D, a: Vector3, b: Vector3, chest_y: float, exclude: Array[RID]) -> Array:
	var length := a.distance_to(b)
	if length < 0.05:
		return []
	var r := DwarfFeel.CAM_CIRCLE_TUBE
	_shape.radius = r
	_shape.height = length + r * 2.0
	var up := (b - a) / length   # (a capsule stands along its own y)
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	return _pieces_in(world, _shape, Transform3D(Basis(side, up, side.cross(up)), (a + b) * 0.5), chest_y, exclude)


## Every piece the camera sees nearer than him: a pyramid from the camera to the screen's corners at his distance.
func _pieces_on_screen(world: World3D, cam: Camera3D, chest: Vector3, exclude: Array[RID]) -> Array:
	var depth := -(cam.global_transform.affine_inverse() * chest).z
	if depth < 0.3:
		return []
	var size := cam.get_viewport().get_visible_rect().size
	var pts := PackedVector3Array([Vector3.ZERO])
	for c in [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]:
		pts.append(cam.project_position(c, depth) - cam.global_position)
	_screen.points = pts
	return _pieces_in(world, _screen, Transform3D(Basis(), cam.global_position), chest.y, exclude, SCREEN_HITS)


func _pieces_in(world: World3D, shape: Shape3D, at: Transform3D, chest_y: float, exclude: Array[RID],
		most := MAX_HITS) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = PieceNode.PIECE_LAYER
	q.exclude = exclude
	q.transform = at
	var found := []
	var seen := {}
	for hit in world.direct_space_state.intersect_shape(q, most):
		var n := hit.get("collider") as Node
		if n and not (n is PieceNode) and n.get_parent() is PieceNode:
			n = n.get_parent()   # (a spiral stair's rail is its own small body, F781)
		# Floors and stairs below his chest stay solid (the floor he walks on, and the one in front of him).
		if n is PieceNode and not (n as PieceNode).ghost and not seen.has(n) and CameraRoom.see_through(n, chest_y):
			seen[n] = true
			found.append(n)
	return found


## Give the piece's models their own copy of the see-through paint. Returns [what to put back, the copies].
static func _swap_in(p: Node) -> Array:
	var undo := []
	var mats := []
	for g in p.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.material_override:
			var see := _own_copy(mi.material_override)   # (code-made looks: the prop paint has the circle built in)
			if see:
				undo.append([mi, -1, mi.material_override])
				mats.append(see)
				mi.material_override = see
			continue
		if not mi.mesh:
			continue
		for s in mi.mesh.get_surface_count():
			var old := mi.get_surface_override_material(s)
			var see := _own_copy(old if old else mi.mesh.surface_get_material(s))
			if see:
				undo.append([mi, s, old])
				mats.append(see)
				mi.set_surface_override_material(s, see)
	return [undo, mats]


## A copy of the see-through version of this paint, for one piece. null = can't (left as is).
static func _own_copy(m: Material) -> ShaderMaterial:
	if m is ShaderMaterial and (m as ShaderMaterial).shader and "see_cut" in (m as ShaderMaterial).shader.code:
		return m.duplicate() as ShaderMaterial
	var see := _see_version(m)
	return see.duplicate() as ShaderMaterial if see else null


static func _swap_out(swap: Array) -> void:
	for u in swap[0]:
		if not is_instance_valid(u[0]):
			continue
		if u[1] < 0:
			(u[0] as MeshInstance3D).material_override = u[2]
		else:
			(u[0] as MeshInstance3D).set_surface_override_material(u[1], u[2])


## The see-through stand-in for a model's plain paint (same colour, picture and shine). null = can't (left as is).
static func _see_version(m: Material) -> Material:
	if not (m is StandardMaterial3D):
		return null
	if _swaps.has(m):
		return _swaps[m]
	var s := m as StandardMaterial3D
	if s.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or s.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL:
		return null
	if not _see_shader:
		_see_shader = load("res://src/art/see_through.gdshader")
		_see_shader_one = Shader.new()
		_see_shader_one.code = _see_shader.code.replace("render_mode cull_disabled;", "render_mode cull_back;")
	var see := ShaderMaterial.new()
	see.shader = _see_shader if s.cull_mode == BaseMaterial3D.CULL_DISABLED else _see_shader_one
	see.set_shader_parameter("albedo", s.albedo_color)
	see.set_shader_parameter("has_tex", s.albedo_texture != null)
	see.set_shader_parameter("albedo_tex", s.albedo_texture)
	see.set_shader_parameter("use_color", s.vertex_color_use_as_albedo)
	see.set_shader_parameter("uv_scale", s.uv1_scale)
	see.set_shader_parameter("uv_offset", s.uv1_offset)
	see.set_shader_parameter("roughness", s.roughness)
	see.set_shader_parameter("metallic", s.metallic)
	see.set_shader_parameter("specular", s.metallic_specular)
	see.set_shader_parameter("emission", s.emission if s.emission_enabled else Color.BLACK)
	see.set_shader_parameter("emission_energy", s.emission_energy_multiplier if s.emission_enabled else 0.0)
	_swaps[m] = see
	return see


static func _set_see_through(swap: Array, t: float) -> void:
	for m in swap[1]:
		(m as ShaderMaterial).set_shader_parameter("see_amount", t)
