class_name MushroomGrass
extends Node3D
## Mushroom grass in the first cave (owner, Nov 18: "a small mushroom grass just in the first cave on most of the
## surfaces"; picture docs/design/pictures/cave-grass-6-ideas.png). Tufts of tiny thin mushrooms (hand-built:
## tools/asset_forge/builds/cave_mushgrass.py, 3 tufts) over most of the first cave's floor and gentle slopes, never on
## kept-clear ground (the tower), bridges, stone columns, paths or under a Root Tree (the placement rule).
## Only looks, the same on every computer (planned from the cave's seed on a helper thread). Drawn in 12 m patches that
## only show within VIEW metres, so thousands cost little. Dug rock takes the tufts on it away.

const MODELS := ["res://assets/models/cave/mushgrass_a.glb", "res://assets/models/cave/mushgrass_b.glb", "res://assets/models/cave/mushgrass_c.glb"]
const STEP := 0.8  ## one spot every this many metres
const PER_SPOT := 3  ## tufts round each spot
const COVER := 0.78  ## of the spots get tufts ("most of the surfaces"; the rest stay bare)
const PATCH := 12.0  ## metres per drawn patch
const VIEW := 26.0  ## patches further than this aren't drawn

var _meshes: Array[Mesh] = []
var _mats: Array[Material] = []
var _patches := {}  ## Vector2i -> {xforms: [Array per model], nodes: [MultiMeshInstance3D per model]}
var _thread: Thread
var _built := false


func build(maker: CaveMaker, world: World, avoid: Callable = Callable()) -> void:
	for path in MODELS:
		var scene := load(path) as PackedScene
		var mi: MeshInstance3D = null
		if scene:
			var inst := scene.instantiate()
			var found := inst.find_children("*", "MeshInstance3D", true, false)
			if not found.is_empty():
				mi = found[0]
				_meshes.append(mi.mesh)
				_mats.append(mi.get_active_material(0))
			inst.free()
	if _meshes.size() != MODELS.size():
		return
	world.changed.connect(_on_rock_changed)
	var trees := []  # (looked up here: the helper thread can't call the tree node)
	if avoid.is_valid():
		trees = avoid.call()
	_thread = Thread.new()
	_thread.start(func() -> void:
		var spots := plan(maker, trees)
		_finish.call_deferred(spots))


func is_built() -> bool:
	return _built


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## (any thread) Every tuft: [{pos, spin, scale, model, up}]. `trees`: [{p, r}] trunks to keep away from.
static func plan(maker: CaveMaker, trees: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if maker.rooms.is_empty():
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9900
	var room: Dictionary = maker.rooms[0]
	var c: Vector3 = room.center
	var r: Vector3 = room.radii
	var paths: Array[Dictionary] = []
	for sg: Dictionary in maker.segments:
		if sg.get("ramp", false) or sg.get("ledge", false):
			paths.append(sg)
	var nx := int(r.x * 2.4 / STEP)  # (a little past the egg shape: the walls flare out)
	var nz := int(r.z * 2.4 / STEP)
	for ix in nx:
		for iz in nz:
			var x := c.x - r.x * 1.2 + (ix + rng.randf()) * STEP
			var z := c.z - r.z * 1.2 + (iz + rng.randf()) * STEP
			var cover := rng.randf()
			if Vector2((x - c.x) / r.x, (z - c.z) / r.z).length_squared() > 1.44 or cover > COVER:
				continue
			var start := Vector3.INF
			for up in [0.2, -0.1, -0.3, -0.45]:  # (near the walls the middle height is already in the rock)
				var s := Vector3(x, c.y + r.y * up, z)
				if maker.sdf_at(s) > 0.3:
					start = s
					break
			if start == Vector3.INF:
				continue
			var hit := GlowPlacer._march(maker, start, Vector3.DOWN, r.y * 2.0 + 6.0)
			if hit == Vector3.INF:
				continue
			var n := GlowPlacer.normal_at(maker, hit)
			if n.y < 0.6:
				continue  # floors and gentle slopes, not walls
			if maker.is_reserved(hit, 1.8) or maker.on_bridge(hit, 1.0) or maker._in_column(hit, 1.0):
				continue
			var clear := true
			for t in trees:
				if Vector2(hit.x - t.p.x, hit.z - t.p.z).length() < float(t.r) + 0.5:
					clear = false
					break
			for sg in paths:
				if not clear:
					break
				if Geometry3D.get_closest_point_to_segment(hit, sg.a, sg.b).distance_to(hit) < float(sg.r) + 0.3:
					clear = false
			if not clear:
				continue
			for k in PER_SPOT:
				var dx := rng.randf_range(-0.5, 0.5) * STEP
				var dz := rng.randf_range(-0.5, 0.5) * STEP
				var y := hit.y - (n.x * dx + n.z * dz) / n.y  # on the slope's plane
				out.append({pos = Vector3(hit.x + dx, y - 0.015, hit.z + dz), spin = rng.randf() * TAU,
					scale = rng.randf_range(1.1, 2.2), model = rng.randi() % MODELS.size(), up = Vector3.UP.lerp(n, 0.5).normalized()})
	return out


func _finish(spots: Array[Dictionary]) -> void:
	if _thread:
		_thread.wait_to_finish()
		_thread = null
	for s in spots:
		var key := Vector2i(floori(s.pos.x / PATCH), floori(s.pos.z / PATCH))
		if not _patches.has(key):
			_patches[key] = {xforms = [[], [], []], nodes = []}
		var up: Vector3 = s.up
		var tilt := Basis(Vector3.UP.cross(up).normalized(), Vector3.UP.angle_to(up)) if up.angle_to(Vector3.UP) > 0.01 else Basis()
		var xf := Transform3D(tilt * Basis(Vector3.UP, s.spin).scaled(Vector3.ONE * s.scale), s.pos)
		_patches[key].xforms[s.model].append(xf)
	for key in _patches:
		_draw(key)
	_built = true


func _draw(key: Vector2i) -> void:
	var pt: Dictionary = _patches[key]
	for old in pt.nodes:
		(old as Node).queue_free()
	pt.nodes = []
	for m in MODELS.size():
		var list: Array = pt.xforms[m]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _meshes[m]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = _mats[m]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = VIEW
		mmi.visibility_range_end_margin = 4.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(mmi)
		pt.nodes.append(mmi)


## Rock dug or fallen in: the tufts there go with it.
func _on_rock_changed(center: Vector3, radius: float) -> void:
	if not _built:
		return
	var r := radius + 0.4
	for kx in range(floori((center.x - r) / PATCH), floori((center.x + r) / PATCH) + 1):
		for kz in range(floori((center.z - r) / PATCH), floori((center.z + r) / PATCH) + 1):
			var key := Vector2i(kx, kz)
			if not _patches.has(key):
				continue
			var changed := false
			for m in MODELS.size():
				var keep := []
				for xf: Transform3D in _patches[key].xforms[m]:
					if xf.origin.distance_to(center) > r:
						keep.append(xf)
				if keep.size() != _patches[key].xforms[m].size():
					_patches[key].xforms[m] = keep
					changed = true
			if changed:
				_draw(key)


## How many tufts there are (for tests and the log).
func count() -> int:
	var n := 0
	for key in _patches:
		for m in MODELS.size():
			n += _patches[key].xforms[m].size()
	return n
