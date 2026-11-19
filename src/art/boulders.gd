class_name Boulders
extends Node3D
## Breakable boulders (owner, Nov 18: "rocks like in Conan Exiles that you can break to get some stone, multiple shapes
## around the caves"). Five hand-built shapes (tools/asset_forge/builds/cave_boulders.py) on open cave floors: 3-5 in
## each big cave, 1-2 in small ones, clear of paths, places, bridges, trees and ground kept for ruins. Solid. Every hit
## gives stone (2 with a pickaxe, 1 by hand); after HITS hits it bursts into rock chunks, and RESPAWN seconds later a
## new one stands there (it appears while nobody is looking). The host keeps the count (GameAuthority.boulder_hits).

## (boulder_split is out, owner Nov 18: "some of the boulders have a gap in between them")
const SHAPES := ["boulder_round", "boulder_tall", "boulder_slabs", "boulder_cluster"]
const LOOKS := ["", "_b", "_c"]  ## three stone pictures per shape (owner, Nov 18: "different styles in terms of textures")
static var MODELS: Array[String] = _models()
const HITS := 6
const RESPAWN := 1200.0  ## 20 minutes
const STONE := Color(0.5, 0.46, 0.41)

static func _models() -> Array[String]:
	var out: Array[String] = []
	for sh in SHAPES:
		for lk in LOOKS:
			out.append("res://assets/models/cave/%s%s.glb" % [sh, lk])
	return out


var _rocks: Array[Dictionary] = []  ## {pos, model, spin, scale, body, broken, want_back}
var _check := 0.0


var _thread: Thread


## Planned on a helper thread (~3.5 s), made when ready. `blocking` = all at once (tests).
func build(maker: CaveMaker, avoid: Callable = Callable(), blocking := false) -> void:
	if blocking:
		_finish(cached_plan(maker, avoid))
		return
	_thread = Thread.new()
	_thread.start(func() -> void:
		var list := cached_plan(maker, avoid)
		_finish.call_deferred(list))


func _finish(list: Array[Dictionary]) -> void:
	if _thread:
		_thread.wait_to_finish()
		_thread = null
	_rocks = list
	for i in _rocks.size():
		_make(i)
	var auth := GameAuthority.instance
	if auth:  # boulders broken in a save loaded before they were made
		for id in auth.boulder_back:
			set_broken(int(id), true, false)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## [{pos, model, spin, scale}] for this cave (same seed, same rocks). `avoid(p, r) -> bool` = more things to keep clear of.
## plan(), read from the saved file when this cave was planned before (PlanCache: faster second load).
static func cached_plan(maker: CaveMaker, avoid: Callable = Callable()) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(PlanCache.get_or_make("boulders", maker, "res://src/art/boulders.gd", func() -> Array: return plan(maker, avoid)))
	return out


static func plan(maker: CaveMaker, avoid: Callable = Callable()) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9800
	var near := {}
	for room in maker.rooms:
		var want := rng.randi_range(7, 11) if room.big else rng.randi_range(2, 4)  # (owner, Nov 18: "a lot more boulders")
		if room.get("sealed", false) or maker.sdf_at(room.center) <= 0.0:
			continue
		for attempt in want * 10:
			if want <= 0:
				break
			var dir := Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.2, 0.9), rng.randf_range(-1, 1)).normalized()
			var model := rng.randi_range(0, MODELS.size() - 1)
			var spin := rng.randf_range(0.0, TAU)
			var scale := rng.randf_range(1.2, 2.0)  # (in-game look: 0.8-1.4 was pebble-sized)
			if room.big and rng.randf() < 0.15:
				scale = rng.randf_range(2.8, 4.2)  # now and then a really big one (owner, Nov 18)
			var buried := rng.randf() < 0.5  # half of them sunk into the ground (owner, Nov 18)
			var sink_part := rng.randf_range(0.2, 0.45)
			var hit := GlowPlacer._march(maker, room.center, dir, 60.0)
			if hit == Vector3.INF or GlowPlacer.normal_at(maker, hit).y < 0.85:
				continue  # open, fairly flat floor only
			if maker.sdf_at(hit + Vector3.UP * maxf(2.0, scale * 1.3)) <= 0.8:
				continue  # room above it
			if maker.is_reserved(hit, 3.0) or maker.on_bridge(hit, 2.0) or maker._in_column(hit, 2.5):
				continue
			if avoid.is_valid() and avoid.call(hit, 3.0):
				continue
			# never floating (owner, Nov 18: "a few of them just float"): it stands as low as the lowest floor under its edge
			var low := hit.y
			var ok := true
			for k in 8:
				var a := k * TAU / 8.0
				var edge := hit + Vector3(cos(a), 0.0, sin(a)) * 0.6 * scale
				var fl := GlowPlacer._march(maker, edge + Vector3.UP * 1.0, Vector3.DOWN, 3.0 + scale)
				if fl == Vector3.INF:
					ok = false  # its edge hangs over a drop
					break
				low = minf(low, fl.y)
			if not ok or hit.y - low > 0.5 * scale:
				continue  # too steep under it
			var bury := sink_part * 1.1 * scale if buried else 0.0
			var sink := (hit.y - low) + 0.08 + bury
			var key := Vector3i((hit / 4.0).floor())
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
			var lean := Vector3.UP.lerp(GlowPlacer.normal_at(maker, hit), 0.7).normalized()  # leans with the slope a little
			out.append({pos = hit - Vector3.UP * sink, model = model, spin = spin, scale = scale, sink = sink, lean = lean, bury = bury})
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
	var lean: Vector3 = r.get("lean", Vector3.UP)
	var tilt := Basis(Vector3.UP.cross(lean).normalized(), Vector3.UP.angle_to(lean)) if lean.angle_to(Vector3.UP) > 0.01 else Basis()
	body.global_basis = tilt * Basis(Vector3.UP, r.spin)
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
	var box := AABB((r.pos as Vector3) - Vector3(2, 2, 2) * r.scale, Vector3(4, 4, 4) * r.scale)
	GroundSnap.when_built(box, _settle.bind(i))


## On the real rock (owner, Nov 18: "some of the boulders are still floating"): the real floor under its middle and
## round its edge; it stands as low as the lowest of them, sunk as planned. No rock under it at all: it goes.
func _settle(i: int) -> void:
	var r: Dictionary = _rocks[i]
	var body: StaticBody3D = r.body
	if not is_instance_valid(body):
		return
	var space := body.get_world_3d().direct_space_state
	var scale: float = r.scale
	var top := (r.pos as Vector3) + Vector3.UP * float(r.sink)
	var low := INF
	var found := 0
	for k in 9:
		var at := top
		if k > 0:
			var a := k * TAU / 8.0
			at += Vector3(cos(a), 0.0, sin(a)) * 0.75 * scale
		var fl := GroundSnap.floor_at(space, at, 1.5 + scale, 2.5 + scale)
		if fl != Vector3.INF:
			low = minf(low, fl.y)
			found += 1
	if found < 3:
		r.broken = true
		body.visible = false
		for c in body.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
		return
	var y := low - 0.08 - float(r.get("bury", 0.0))
	r.sink = float(r.sink) + ((r.pos as Vector3).y - y)
	r.pos = Vector3(r.pos.x, y, r.pos.z)
	body.global_position = r.pos


## Which boulder a ray hit, or -1.
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("boulder"):
		return int((collider as Node).get_meta("boulder"))
	return -1


## The middle of the part that shows above the ground.
static func middle(r: Dictionary) -> Vector3:
	return (r.pos as Vector3) + Vector3.UP * (float(r.get("sink", 0.0)) + 1.1 * float(r.scale)) * 0.5


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
			var mid := middle(r)
			RockShatter.burst(get_parent(), mid + Vector3.UP * 0.2 * r.scale, Vector3.UP, STONE, Mat.STONE)
			RockShatter.burst(get_parent(), mid, Vector3(1, 0.5, 0), STONE, Mat.STONE)
			if r.scale > 2.5:  # a really big one breaks into even more
				RockShatter.burst(get_parent(), mid - Vector3.UP * 0.2 * r.scale, Vector3(-1, 0.5, 0.3), STONE, Mat.STONE)
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
