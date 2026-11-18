class_name RootPillars
extends Node3D
## Giant root pillars (owner, Nov 17, F189: "huge twisted tree roots running floor to ceiling in some caverns, like the
## stone pillars but wood; you can chop bits for wood"). Models: tools/asset_forge/builds/cave_rootpillar.py.
## Planned from the cave (same seed, same pillars): about half the big caverns get one or two where the ceiling is
## 5-14 m up, clear of paths, places, stone columns and ground kept clear for built things. Solid: you bump into them.
## Every hit gives rootwood (2 with an axe), up to CHOPS per pillar; the pillar stays (it's huge). The host keeps count.

const MODELS := ["res://assets/models/cave/rpillar_a.glb", "res://assets/models/cave/rpillar_b.glb"]
const CHOPS := 12  ## wood a pillar gives before it's chopped bare
const GROUP := "root_pillar"

var _pillars: Array[Dictionary] = []  ## {top, bottom, width, model}


func build(maker: CaveMaker) -> void:
	_pillars = plan(maker)
	for i in _pillars.size():
		var p: Dictionary = _pillars[i]
		var scene := load(MODELS[p.model]) as PackedScene
		if scene == null:
			continue
		var body := StaticBody3D.new()
		body.collision_layer = World.TERRAIN_LAYER  # you bump into it and aim at it, like the rock
		body.collision_mask = 0
		body.set_meta("root_pillar", i)
		body.add_to_group(GROUP)
		add_child(body)
		var top: Vector3 = p.top
		var h: float = top.y - (p.bottom as Vector3).y
		body.global_position = top
		var model := scene.instantiate() as Node3D
		# The model grows along +Y from the ceiling: hang it upside down, stretched to the room's height.
		model.basis = Basis(Vector3.RIGHT, PI) * Basis(Vector3.UP, p.spin) * Basis.from_scale(Vector3(p.width, h, p.width))
		body.add_child(model)
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = p.width * 0.14  # the twisted core (the feet spread wider, into the rock)
		cyl.height = h
		shape.shape = cyl
		shape.position = Vector3.DOWN * h * 0.5
		body.add_child(shape)


## [{top, bottom, width, model, spin}] for this cave.
static func plan(maker: CaveMaker) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9400
	for ri in maker.rooms.size():
		var room: Dictionary = maker.rooms[ri]
		var roll := rng.randf()
		var want := rng.randi_range(1, 2)
		if not room.big or room.get("sealed", false) or roll > 0.5:
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var placed := 0
		for attempt in 20:
			if placed >= want:
				break
			var a := rng.randf_range(0.0, TAU)
			var d := rng.randf_range(0.2, 0.6)
			var at := Vector3(c.x + cos(a) * r.x * d, c.y, c.z + sin(a) * r.z * d)
			var width := rng.randf_range(4.5, 7.0)
			var spin := rng.randf_range(0.0, TAU)
			var model := rng.randi_range(0, MODELS.size() - 1)
			if maker.sdf_at(at) <= 0.5:
				continue
			var top := GlowPlacer._march(maker, at, Vector3.UP, 20.0)
			var bottom := GlowPlacer._march(maker, at, Vector3.DOWN, 20.0)
			if top == Vector3.INF or bottom == Vector3.INF:
				continue
			var h := top.y - bottom.y
			if h < 5.0 or h > 14.0:
				continue
			width = maxf(width, h * 0.6)  # tall ones stay massive, not stretched thin (first in-game look)
			if not _clear(maker, at, width * 0.45, out):
				continue
			out.append({top = top + Vector3.UP * 0.3, bottom = bottom - Vector3.UP * 0.3, width = width, model = model, spin = spin})
			placed += 1
	return out


## The placement rule: not on kept-clear ground, not in a stone column, not on places, paths or another pillar.
static func _clear(maker: CaveMaker, at: Vector3, foot: float, out: Array[Dictionary]) -> bool:
	if maker.is_reserved(at, foot + 2.0) or maker._in_column(at, foot + 2.0):
		return false
	for q in maker.pois:
		if Vector2(q.pos.x - at.x, q.pos.z - at.z).length() < foot + 4.0:
			return false
	for p in out:
		if Vector2(p.top.x - at.x, p.top.z - at.z).length() < foot * 2.0 + 6.0:
			return false
	for sg: Dictionary in maker.segments:
		if sg.get("ramp", false) or sg.get("ledge", false):
			var cp := Geometry3D.get_closest_point_to_segment(at, sg.a, sg.b)
			if Vector2(cp.x - at.x, cp.z - at.z).length() < foot + float(sg.r) + 1.0:
				return false
	return true


## Which pillar a ray hit (its collider), or -1.
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("root_pillar"):
		return int((collider as Node).get_meta("root_pillar"))
	return -1


func pillar(id: int) -> Dictionary:
	return _pillars[id] if id >= 0 and id < _pillars.size() else {}
