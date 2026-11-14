class_name RuinKit
## Carved dwarf stonework for ruins and halls (feedback F9/F21: "columns should look better,
## not just blocks"). Built from simple shapes but with real column parts:
##   a stepped square base, a ring, an 8-sided slightly tapering shaft with two carved bands,
##   and a wide stepped top (capital). Broken columns snap off with a jagged top and leave
##   fallen pieces (drums) and rubble around them.
## Colors go through PoiField._mat, so the shared look (Claude 3's materials) applies automatically.

const STONE := Color(0.72, 0.69, 0.64)
const DARK := Color(0.5, 0.47, 0.43)
const GROUP := "ruin_stone"  ## the pickaxe doesn't dig "through" these


## A column standing at `pos` (local to `parent`). `height` = full height when whole.
## broken_at: 0 = whole, otherwise the fraction of the shaft that's left (0.2-0.8).
static func column(parent: Node3D, pos: Vector3, height: float, width: float, broken_at: float, rng: RandomNumberGenerator, color: Color = STONE) -> void:
	var col := Node3D.new()
	col.position = pos
	col.rotation.y = rng.randf_range(0.0, TAU)
	parent.add_child(col)
	var m := PoiField._mat(color)
	var trim := PoiField._mat(color.darkened(0.18))
	var w := width
	# Stepped square base.
	_mesh(col, _box(Vector3(w * 1.6, 0.25, w * 1.6)), trim, Vector3(0, 0.125, 0))
	_mesh(col, _box(Vector3(w * 1.35, 0.25, w * 1.35)), m, Vector3(0, 0.375, 0))
	_mesh(col, _cyl(w * 0.6, w * 0.64, 0.16), trim, Vector3(0, 0.58, 0))
	var shaft_h := maxf(height - 1.3, 0.8)
	var y0 := 0.66
	var left := shaft_h if broken_at <= 0.0 else shaft_h * broken_at
	# The shaft: 8 sides, a little narrower at the top (like it's carrying weight).
	var top_r := lerpf(w * 0.55, w * 0.47, left / shaft_h)
	_mesh(col, _cyl(top_r, w * 0.55, left), m, Vector3(0, y0 + left * 0.5, 0))
	for band in [0.33, 0.66]:
		if band * shaft_h < left - 0.1:
			_mesh(col, _cyl(w * 0.6, w * 0.6, 0.12), trim, Vector3(0, y0 + band * shaft_h, 0))
	if broken_at <= 0.0:
		# The capital: flares out, then two wide square steps.
		var top := y0 + shaft_h
		_mesh(col, _cyl(w * 0.72, w * 0.5, 0.32), m, Vector3(0, top + 0.16, 0))
		_mesh(col, _box(Vector3(w * 1.45, 0.22, w * 1.45)), trim, Vector3(0, top + 0.43, 0))
		_mesh(col, _box(Vector3(w * 1.7, 0.26, w * 1.7)), m, Vector3(0, top + 0.67, 0))
	else:
		# Snapped off: a few tilted chunks make a jagged break.
		var top := y0 + left
		for k in 3:
			var chunk := _mesh(col, _cyl(top_r * rng.randf_range(0.35, 0.6), top_r * 0.7, rng.randf_range(0.15, 0.4)), m,
				Vector3(rng.randf_range(-0.12, 0.12) * w, top + 0.05, rng.randf_range(-0.12, 0.12) * w))
			chunk.rotation = Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(0, TAU), rng.randf_range(-0.35, 0.35))
		# The fallen part lies nearby as round drums, plus rubble.
		var fallen := shaft_h - left
		var dir := rng.randf_range(0.0, TAU)
		var along := w * 1.2
		while fallen > 0.3:
			var piece := minf(fallen, rng.randf_range(0.6, 1.1))
			var drum := _mesh(col, _cyl(w * 0.5, w * 0.52, piece), m, Vector3(cos(dir) * (along + piece * 0.5), w * 0.5, sin(dir) * (along + piece * 0.5)))
			drum.rotation = Vector3(PI / 2.0, 0.0, 0.0)
			drum.rotation.y = -dir + PI / 2.0 + rng.randf_range(-0.3, 0.3)
			along += piece + rng.randf_range(0.1, 0.5)
			fallen -= piece
		for k in rng.randi_range(3, 6):
			var r := rng.randf_range(0.12, 0.3)
			var bit := _mesh(col, _box(Vector3(r, r * 0.8, r * 1.2)), m,
				Vector3(rng.randf_range(-1.5, 1.5) * w, r * 0.4, rng.randf_range(-1.5, 1.5) * w))
			bit.rotation = Vector3(rng.randf_range(0, 1), rng.randf_range(0, TAU), rng.randf_range(0, 1))
	# Solid: you bump into it (but the pickaxe won't dig "through" it).
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	body.add_to_group(GROUP)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	var solid_h := (y0 + left + (0.9 if broken_at <= 0.0 else 0.2))
	shape.radius = w * 0.62
	shape.height = solid_h
	cs.shape = shape
	cs.position = Vector3(0, solid_h * 0.5, 0)
	body.add_child(cs)
	col.add_child(body)


## A stretch of old wall, built from cut blocks with some missing (a ruin, not a wall).
static func broken_wall(parent: Node3D, from: Vector3, to: Vector3, rows: int, rng: RandomNumberGenerator, color: Color = DARK) -> void:
	var m := PoiField._mat(color)
	var m2 := PoiField._mat(color.lightened(0.08))
	var length := from.distance_to(to)
	var dir := (to - from).normalized()
	var yaw := atan2(dir.x, dir.z)
	var blocks := maxi(1, int(length / 0.8))
	for row in rows:
		var offset := 0.4 if row % 2 == 1 else 0.0  # staggered like real masonry
		for i in blocks:
			# Higher rows have more blocks missing.
			if rng.randf() < 0.12 + row * 0.22:
				continue
			var along := i * 0.8 + 0.4 + offset
			if along > length:
				continue
			var p := from + dir * along + Vector3.UP * (row * 0.5 + 0.25)
			var b := _mesh(parent, _box(Vector3(0.5, 0.48, 0.76)), m if (i + row) % 3 else m2, p)
			b.rotation.y = yaw + rng.randf_range(-0.05, 0.05)
	# A few blocks that fell off lie at the foot.
	for k in rng.randi_range(2, 4):
		var p := from + dir * rng.randf_range(0.0, length) + Vector3(rng.randf_range(-1, 1), 0.22, rng.randf_range(-1, 1))
		var b := _mesh(parent, _box(Vector3(0.5, 0.45, 0.76)), m, p)
		b.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0, TAU), rng.randf_range(-0.4, 0.4))


static func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _box(s: Vector3) -> Mesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 8  # 8 flat sides: carved stone, not a smooth pipe
	c.rings = 1
	return c
