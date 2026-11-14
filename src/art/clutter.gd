class_name Clutter
extends Node3D
## Small loose things on cave floors, only for looks: pebbles, chunky rocks, old bones,
## twigs (Mossy Hollows) and fungus nubs (Fungal Jungle). You can't pick them up.
## And stone stalactites on the ceilings: wide at the top, thinning to a rounded tip, in
## clusters (a big one with smaller ones around it), in the colour of the local rock.
## - Same seed = same spots on every computer (no network needed).
## - Drawn in batches (one MultiMesh per kind), so thousands cost about as much as a few.
## - When rock is dug or caves in nearby, the things there disappear, so nothing floats.

const PER_BIG_ROOM := 160
const PER_ROOM := 40
const PER_TUNNEL := 6

## kind: mesh maker, colour, surface, size range, which biome ("" = both), weight
const KINDS := {
	"pebble": {color = Color(0.45, 0.42, 0.38), surface = "stone", size = [0.05, 0.12], biome = "", weight = 6},
	"rock": {color = Color(0.4, 0.37, 0.34), surface = "stone", size = [0.18, 0.4], biome = "", weight = 2},
	"bone": {color = Color(0.82, 0.78, 0.66), surface = "smooth", size = [0.25, 0.4], biome = "mossy", weight = 1},
	"twig": {color = Color(0.35, 0.24, 0.15), surface = "bark", size = [0.3, 0.55], biome = "mossy", weight = 2},
	"nub": {color = Color(0.62, 0.48, 0.66), surface = "fungus", size = [0.08, 0.2], biome = "fungal", weight = 3},
	# Ceilings (weight 0 = never picked for floors; placed by _ceiling instead).
	"stal_mossy": {color = Color(0.5, 0.46, 0.41), surface = "stone", size = [0, 0], biome = "mossy", weight = 0},
	"stal_fungal": {color = Color(0.4, 0.33, 0.46), surface = "stone", size = [0, 0], biome = "fungal", weight = 0},
}
const CLUSTERS_BIG_ROOM := 30
const CLUSTERS_ROOM := 7

var _sets := {}   ## kind -> MultiMeshInstance3D
var _where := {}  ## kind -> PackedVector3Array (positions, for hiding near digs)


func build(maker: CaveMaker, world: World) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 4242
	var picks := {}  ## kind -> Array of Transform3D
	for k in KINDS:
		picks[k] = []
	for room in maker.rooms:
		var n: int = PER_BIG_ROOM if room.big else PER_ROOM
		for i in n:
			var dir := Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.4, 1.0), rng.randf_range(-1, 1)).normalized()
			_try(maker, rng, picks, room.center, dir, 60.0)
	for s: Dictionary in maker.segments:
		for i in PER_TUNNEL:
			var at: Vector3 = (s.a as Vector3).lerp(s.b, rng.randf())
			_try(maker, rng, picks, at, Vector3(rng.randf_range(-0.3, 0.3), -1, rng.randf_range(-0.3, 0.3)).normalized(), 10.0)
	for room in maker.rooms:
		for i in (CLUSTERS_BIG_ROOM if room.big else CLUSTERS_ROOM):
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.5, 1.0), rng.randf_range(-1, 1)).normalized()
			_ceiling(maker, rng, picks, room.center, dir)
	for k in KINDS:
		_make_set(k, picks[k])
	world.changed.connect(_on_rock_changed)


## A cluster of stalactites where a ray from `start` hits the ceiling: one big one, a few small
## ones around it. Never so long that a dwarf would bump their head walking under it.
func _ceiling(maker: CaveMaker, rng: RandomNumberGenerator, picks: Dictionary, start: Vector3, dir: Vector3) -> void:
	if maker.sdf_at(start) <= 0.0:
		return
	var hit := GlowPlacer._march(maker, start, dir, 60.0)
	if hit == Vector3.INF or GlowPlacer.normal_at(maker, hit).y > -0.6:
		return  # not a ceiling
	var kind := "stal_fungal" if CaveMaker.biome_at(hit) == "fungal" else "stal_mossy"
	var small := rng.randi_range(2, 5)
	for j in small + 1:
		var at := hit
		var big := j == 0
		if not big:  # the small ones sit around the big one, a bit higher up on the rock
			var off := Vector3(rng.randf_range(-0.7, 0.7), 0, rng.randf_range(-0.7, 0.7))
			at = GlowPlacer._march(maker, hit + off + Vector3.DOWN * 0.4, Vector3.UP, 3.0)
			if at == Vector3.INF:
				continue
		var floor_hit := GlowPlacer._march(maker, at + Vector3.DOWN * 0.3, Vector3.DOWN, 40.0)
		var gap := at.distance_to(floor_hit) if floor_hit != Vector3.INF else 40.0
		var length := rng.randf_range(0.9, 2.4) if big else rng.randf_range(0.2, 0.75)
		length = minf(length, gap - 2.0)  # keep 2 m clear below
		if length < 0.15:
			continue
		var radius := length * rng.randf_range(0.16, 0.24)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(radius, length, radius * rng.randf_range(0.8, 1.2)))
		picks[kind].append(Transform3D(basis, at + Vector3.UP * 0.25 * length))  # tucked into the rock a bit


func _try(maker: CaveMaker, rng: RandomNumberGenerator, picks: Dictionary, start: Vector3, dir: Vector3, reach: float) -> void:
	if maker.sdf_at(start) <= 0.0:
		return
	var hit := GlowPlacer._march(maker, start, dir, reach)
	if hit == Vector3.INF:
		return
	var n := GlowPlacer.normal_at(maker, hit)
	if n.y < 0.75:
		return  # floors only (no walls, no ceilings)
	var biome := CaveMaker.biome_at(hit)
	var kind := _pick(rng, biome)
	var k: Dictionary = KINDS[kind]
	var size := rng.randf_range(k.size[0], k.size[1])
	var up := n
	var side := up.cross(Vector3.FORWARD if absf(up.y) < 0.9 else Vector3.RIGHT).normalized()
	var basis := Basis(side, up, side.cross(up)).orthonormalized().rotated(up, rng.randf() * TAU)
	var shape := Vector3(rng.randf_range(0.8, 1.3), rng.randf_range(0.5, 0.9), rng.randf_range(0.8, 1.3))
	if kind in ["bone", "twig"]:
		basis = basis * Basis(Vector3.RIGHT, PI / 2.0)  # lying down
		shape = Vector3.ONE
	picks[kind].append(Transform3D(basis.scaled(shape * size), hit + n * size * 0.15))


func _pick(rng: RandomNumberGenerator, biome: String) -> String:
	var total := 0
	for k in KINDS:
		if KINDS[k].biome in ["", biome]:
			total += KINDS[k].weight
	var r := rng.randi_range(1, total)
	for k in KINDS:
		if KINDS[k].biome in ["", biome]:
			r -= KINDS[k].weight
			if r <= 0:
				return k
	return "pebble"


func _make_set(kind: String, xforms: Array) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _mesh(kind)
	mm.instance_count = xforms.size()
	var where := PackedVector3Array()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		where.append(xforms[i].origin)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var k: Dictionary = KINDS[kind]
	mmi.material_override = Look.mat(k.color, k.surface, 0.0, 0.0)
	mmi.visibility_range_end = 45.0  # far-away pebbles aren't worth drawing
	if kind == "pebble":
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	_sets[kind] = mmi
	_where[kind] = where


## The unit shape of each kind (the transform makes it the right size).
static func _mesh(kind: String) -> Mesh:
	if kind.begins_with("stal"):
		return _stalactite_mesh()
	match kind:
		"bone":
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var shaft := CylinderMesh.new()
			shaft.top_radius = 0.06
			shaft.bottom_radius = 0.06
			shaft.height = 0.8
			shaft.radial_segments = 6
			shaft.rings = 1
			st.append_from(shaft, 0, Transform3D())
			var knob := SphereMesh.new()
			knob.radius = 0.11
			knob.height = 0.2
			knob.radial_segments = 6
			knob.rings = 3
			for y in [-0.4, 0.4]:
				for x in [-0.06, 0.06]:
					st.append_from(knob, 0, Transform3D(Basis(), Vector3(x, y, 0)))
			st.generate_normals()
			return st.commit()
		"twig":
			var c := CylinderMesh.new()
			c.top_radius = 0.02
			c.bottom_radius = 0.045
			c.height = 1.0
			c.radial_segments = 5
			c.rings = 2
			return c
		"nub":
			var s := SphereMesh.new()
			s.radius = 0.5
			s.height = 0.7
			s.is_hemisphere = true
			s.radial_segments = 8
			s.rings = 3
			return s
	# pebble / rock: a squashed, faceted ball
	var r := SphereMesh.new()
	r.radius = 0.5
	r.height = 0.8
	r.radial_segments = 6
	r.rings = 4
	return r


## A stalactite 1 unit wide at the top and 1 unit long, hanging down from y = 0:
## thick at the top, getting thinner and thinner, with a little rounded tip and a few
## bumpy rings (dripping rock builds up unevenly).
static func _stalactite_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const RINGS := 10
	const AROUND := 9
	var ring_pts := []
	for r in RINGS:
		var t := float(r) / (RINGS - 1)
		var radius := pow(1.0 - t, 1.4) * 0.5 + 0.055      # thinner and thinner toward the tip
		radius *= 1.0 + 0.08 * sin(t * 23.0)               # bumpy rings
		var pts := []
		for a in AROUND:
			var ang := TAU * a / AROUND
			pts.append(Vector3(cos(ang) * radius, -t * 0.94, sin(ang) * radius))
		ring_pts.append(pts)
	for r in RINGS - 1:
		for a in AROUND:
			var b := (a + 1) % AROUND
			for v in [ring_pts[r][a], ring_pts[r + 1][b], ring_pts[r][b], ring_pts[r][a], ring_pts[r + 1][a], ring_pts[r + 1][b]]:
				st.add_vertex(v)
	var tip := Vector3(0, -0.985, 0)  # the rounded drip at the end
	for a in AROUND:
		for v in [ring_pts[RINGS - 1][a], tip, ring_pts[RINGS - 1][(a + 1) % AROUND]]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## Rock changed near here: anything resting there disappears (it fell with the rock).
func _on_rock_changed(center: Vector3, radius: float) -> void:
	var r2 := (radius + 0.6) * (radius + 0.6)
	for kind in _sets:
		var where: PackedVector3Array = _where[kind]
		var mm: MultiMesh = (_sets[kind] as MultiMeshInstance3D).multimesh
		for i in where.size():
			if where[i].distance_squared_to(center) < r2:
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), where[i]))
				where[i] = Vector3.INF
		_where[kind] = where
