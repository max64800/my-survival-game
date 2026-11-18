class_name Boulders
extends Node3D
## Breakable boulders (owner, Nov 18: "rocks like in Conan Exiles that you can break to get some stone, multiple shapes
## around the caves"). Five hand-built shapes (tools/asset_forge/builds/cave_boulders.py) on open cave floors: 3-5 in
## each big cave, 1-2 in small ones, clear of paths, places, bridges, trees and ground kept for ruins. Solid. Every hit
## gives stone (2 with a pickaxe, 1 by hand); after HITS hits it bursts into rock chunks, and RESPAWN seconds later a
## new one stands there (it appears while nobody is looking). The host keeps the count (GameAuthority.boulder_hits).

const MODELS := ["res://assets/models/cave/boulder_round.glb", "res://assets/models/cave/boulder_tall.glb",
	"res://assets/models/cave/boulder_slabs.glb", "res://assets/models/cave/boulder_cluster.glb",
	"res://assets/models/cave/boulder_split.glb"]
const HITS := 6
const RESPAWN := 1200.0  ## 20 minutes
const STONE := Color(0.5, 0.46, 0.41)

var _rocks: Array[Dictionary] = []  ## {pos, model, spin, scale, body, broken, want_back}
var _check := 0.0


func build(maker: CaveMaker, avoid: Callable = Callable()) -> void:
	_rocks = plan(maker, avoid)
	for i in _rocks.size():
		_make(i)


## [{pos, model, spin, scale}] for this cave (same seed, same rocks). `avoid(p, r) -> bool` = more things to keep clear of.
static func plan(maker: CaveMaker, avoid: Callable = Callable()) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9800
	var near := {}
	for room in maker.rooms:
		var want := rng.randi_range(3, 5) if room.big else rng.randi_range(1, 2)
		if room.get("sealed", false) or maker.sdf_at(room.center) <= 0.0:
			continue
		for attempt in want * 10:
			if want <= 0:
				break
			var dir := Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.2, 0.9), rng.randf_range(-1, 1)).normalized()
			var model := rng.randi_range(0, MODELS.size() - 1)
			var spin := rng.randf_range(0.0, TAU)
			var scale := rng.randf_range(1.2, 2.0)  # (in-game look: 0.8-1.4 was pebble-sized)
			var hit := GlowPlacer._march(maker, room.center, dir, 60.0)
			if hit == Vector3.INF or GlowPlacer.normal_at(maker, hit).y < 0.85:
				continue  # open, fairly flat floor only
			if maker.sdf_at(hit + Vector3.UP * 2.0) <= 0.8:
				continue  # room above it
			if maker.is_reserved(hit, 3.0) or maker.on_bridge(hit, 2.0) or maker._in_column(hit, 2.5):
				continue
			if avoid.is_valid() and avoid.call(hit, 3.0):
				continue
			var key := Vector3i((hit / 6.0).floor())
			if near.has(key):
				continue  # one every few metres
			var clear := true
			for q in maker.pois:
				if (q.pos as Vector3).distance_to(hit) < 3.0:
					clear = false
					break
			for sg: Dictionary in maker.segments:
				if not clear:
					break
				if sg.get("ramp", false) or sg.get("ledge", false):
					if Geometry3D.get_closest_point_to_segment(hit, sg.a, sg.b).distance_to(hit) < float(sg.r) + 1.5:
						clear = false
			if not clear:
				continue
			near[key] = true
			out.append({pos = hit - Vector3.UP * 0.08, model = model, spin = spin, scale = scale})
			want -= 1
	return out


func _make(i: int) -> void:
	var r: Dictionary = _rocks[i]
	r.broken = false
	r.want_back = false
	var scene := load(MODELS[r.model]) as PackedScene
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER  # you bump into it, stand on it, aim at it
	body.collision_mask = 0
	body.set_meta("boulder", i)
	add_child(body)
	body.global_position = r.pos
	body.rotation.y = r.spin
	if scene:
		var m := scene.instantiate() as Node3D
		m.scale = Vector3.ONE * r.scale
		body.add_child(m)
		var meshes := m.find_children("*", "MeshInstance3D", true, false)
		for mi: MeshInstance3D in meshes:
			if mi.mesh:
				var shape := CollisionShape3D.new()
				shape.shape = mi.mesh.create_convex_shape()
				shape.transform = m.transform * mi.transform
				body.add_child(shape)
	r.body = body


## Which boulder a ray hit, or -1.
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("boulder"):
		return int((collider as Node).get_meta("boulder"))
	return -1


func rock(i: int) -> Dictionary:
	return _rocks[i] if i >= 0 and i < _rocks.size() else {}


## From the host: boulder i broke (burst = show its chunks flying) or came back.
func set_broken(i: int, broken: bool, burst := true) -> void:
	var r := rock(i)
	if r.is_empty():
		return
	if broken and not r.broken:
		r.broken = true
		r.want_back = false
		if burst:
			RockShatter.burst(get_parent(), (r.pos as Vector3) + Vector3.UP * 0.6 * r.scale, Vector3.UP, STONE, Mat.STONE)
			RockShatter.burst(get_parent(), (r.pos as Vector3) + Vector3.UP * 0.3 * r.scale, Vector3(1, 0.5, 0), STONE, Mat.STONE)
		(r.body as Node3D).visible = false
		for c in (r.body as Node).get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
	elif not broken and r.broken:
		r.want_back = true  # it comes back while nobody is looking


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = 1.0
	var cam := get_viewport().get_camera_3d()
	for r in _rocks:
		if not r.get("want_back", false):
			continue
		var p: Vector3 = r.pos
		if cam and cam.global_position.distance_to(p) < 50.0 and cam.is_position_in_frustum(p):
			continue
		r.want_back = false
		r.broken = false
		(r.body as Node3D).visible = true
		for c in (r.body as Node).get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = false
