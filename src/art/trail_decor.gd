class_name TrailDecor
extends Node3D
## What's left along the old dirt path (owner, Nov 25, F870 step 5): stretches of old sunken stones, now and then a
## few pieces of broken cart track (crooked, with gaps), and here and there a fallen torch lying beside the way, long
## gone out. No paint, no markers. Only looks, the same on every computer (planned from the path, no dice). Uses the
## game's own models (stepping_stones, rail_track, wall_torch), drawn in patches that only show close by. Dug rock
## takes what's on it away; things settle onto the real rock (GroundSnap).

const MODELS := ["res://assets/models/decor/stepping_stones.glb", "res://assets/models/decor/rail_track.glb",
	"res://assets/models/decor/wall_torch.glb"]
enum { STONES, RAIL, TORCH }
const STRETCH := 24.0  ## the path is split into stretches this long: each is plain dirt, old stones or old track
const RAIL_SHARE := 0.09  ## of the stretches still have bits of cart track
const STONE_SHARE := 0.32  ## of the stretches still have old stones
const TORCH_EVERY := 0.012  ## chance per path spot of a fallen torch (about one every 125 m)
const PATCH := 24.0
const VIEW := 48.0  ## further than this: not drawn

var _meshes: Array[Mesh] = []
var _patches := {}  ## Vector2i -> {xforms: [Array per model], nodes: []}
var _built := false


func build(maker: CaveMaker, world: World) -> void:
	for path in MODELS:
		_meshes.append(Clutter._model_mesh(path))
	world.changed.connect(_on_rock_changed)
	world.ground_taken.connect(_on_rock_changed)
	for it in plan(maker):
		var key := Vector2i(floori(it.xform.origin.x / PATCH), floori(it.xform.origin.z / PATCH))
		if not _patches.has(key):
			_patches[key] = {xforms = [[], [], []], nodes = []}
		_patches[key].xforms[it.model].append(it.xform)
	for key in _patches:
		_draw(key)
	_built = true


func is_built() -> bool:
	return _built


## Everything along the path: [{model (STONES/RAIL/TORCH), xform}].
static func plan(maker: CaveMaker) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pts := maker.trail
	var dirs := maker.trail_along
	for i in pts.size():
		var p: Vector3 = pts[i]
		var dir: Vector3 = dirs[i]
		var yaw := atan2(dir.x, dir.z)
		var h := _h(p, 1)
		var cell := Vector2i(floori(p.x / STRETCH), floori(p.z / STRETCH))
		var kind := absf(float(hash(Vector3i(cell.x, maker.seed, cell.y)) % 1000)) / 1000.0
		if kind < RAIL_SHARE:
			# Old cart track: only where the path runs straight and level, a piece at most spots (the gaps between
			# are where it rotted away), each a little crooked.
			if h < 0.6 and i + 1 < pts.size() and (dirs[i + 1] as Vector3).dot(dir) > 0.95 and absf(pts[i + 1].y - p.y) < 0.5:
				var b := Basis(Vector3.UP, yaw + (_h(p, 2) - 0.5) * 0.16)
				b = b * Basis(Vector3.FORWARD, (_h(p, 3) - 0.5) * 0.14) * Basis(Vector3.RIGHT, (_h(p, 4) - 0.5) * 0.1)
				out.append({model = RAIL, xform = Transform3D(b, p + Vector3.UP * -0.03)})
		elif kind < RAIL_SHARE + STONE_SHARE:
			# Old stones, worn down into the dirt (about half the spots: some were lost).
			if h < 0.55:
				var side := Vector3(dir.z, 0.0, -dir.x) * (_h(p, 5) - 0.5) * 0.5
				var b := Basis(Vector3.UP, yaw + (_h(p, 6) - 0.5) * 0.9).scaled(Vector3.ONE * (0.8 + 0.3 * _h(p, 7)))
				out.append({model = STONES, xform = Transform3D(b, p + side + Vector3.UP * -0.035)})
		if _h(p, 8) < TORCH_EVERY:
			# A fallen torch, lying on its side by the edge of the path.
			var sgn := 1.0 if _h(p, 9) < 0.5 else -1.0
			var at := p + Vector3(dir.z, 0.0, -dir.x) * sgn * 1.0
			var fl := OldTrail._floor(maker, at + Vector3.UP * 1.0)
			if absf(fl.y - p.y) < 0.8 and maker.sdf_at(fl + Vector3.UP * 0.5) > 0.0 \
					and not maker.is_reserved(fl, 1.0) and not maker._in_column(fl, 1.0):
				var b := Basis(Vector3.UP, yaw + (_h(p, 10) - 0.5) * 2.4) * Basis(Vector3.FORWARD, PI * 0.5 * sgn)
				out.append({model = TORCH, xform = Transform3D(b, fl + Vector3.UP * 0.1)})
	return out


## A number 0..1 that's always the same for this spot (and `salt`).
static func _h(p: Vector3, salt: int) -> float:
	return float(absi(hash(Vector4i(roundi(p.x * 4.0), roundi(p.y * 4.0), roundi(p.z * 4.0), salt))) % 10000) / 10000.0


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
		mm.use_colors = true
		mm.mesh = _meshes[m]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
			var v := 0.86 + 0.14 * _h((list[i] as Transform3D).origin, 11)  # old and dusty, each a little different
			mm.set_instance_color(i, Color(v, v * 0.97, v * 0.92))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = VIEW
		mmi.visibility_range_end_margin = 4.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		add_child(mmi)
		pt.nodes.append(mmi)
		GroundSnap.add_batch(mmi, {xforms = list}, -0.03 if m != TORCH else 0.1)


## Rock dug or fallen in (or something put down there): what's on it goes.
func _on_rock_changed(center: Vector3, radius: float) -> void:
	if not _built:
		return
	var r := radius + 0.5
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


## How many things there are (for tests).
func count() -> int:
	var n := 0
	for key in _patches:
		for m in MODELS.size():
			n += _patches[key].xforms[m].size()
	return n
