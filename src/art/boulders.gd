class_name Boulders
extends Node3D
## Breakable boulders (owner, Nov 18: "rocks like in Conan Exiles that you can break to get some stone, multiple shapes
## around the caves"). Hand-built shapes (tools/asset_forge/builds/cave_boulders.py) on cave floors by the walls: 1-2 in
## each big cave, 1 in small ones (owner F404, Nov 19), clear of paths, places, bridges, trees and ground kept for ruins. Solid. Every hit
## gives stone (2 with a pickaxe, 1 by hand); after HITS hits it bursts into rock chunks, and RESPAWN seconds later a
## new one stands there (it appears while nobody is looking). The host keeps the count (GameAuthority.boulder_hits).

## (boulder_split is out, owner Nov 18: "some of the boulders have a gap in between them")
const SHAPES := ["boulder_round", "boulder_tall", "boulder_slabs", "boulder_cluster"]
const LOOKS := ["", "_b", "_c"]  ## three stone pictures per shape (owner, Nov 18: "different styles in terms of textures")
static var MODELS: Array[String] = _models()
const HITS := 6
const START_EXTRA := 3  ## more boulders by the starting cave's walls (owner F418)
const START_EDGE := 0.6  ## ...out in the outer part of its oval
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
		if _rocks[i].get("gone", false):
			set_broken(i, true, false)  # on a ruin chest's or treasure's ground: never there
	if GroundSnap.instance and GroundSnap.instance.world and not GroundSnap.instance.world.changed.is_connected(_on_rock_changed):
		GroundSnap.instance.world.changed.connect(_on_rock_changed)  # dug out from under: it drops (owner, Nov 19)
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
	var taken := RuinTreasure.keep_clear(maker)  # old places' loot chests and treasure (owner, Nov 19)
	for room in maker.rooms:
		var want := rng.randi_range(1, 2) if room.big else 1  # (owner F404, Nov 19: "maybe 1-2 per cave")
		if room.get("sealed", false) or maker.sdf_at(room.center) <= 0.0:
			continue
		for attempt in maxi(want, 1) * 30:
			if want <= 0:
				break
			if _try(maker, room, rng, near, taken, avoid, out):
				want -= 1
	# F418 (owner, Nov 19: "boulders in the starting cave too, close to the edges"): a few more by its walls. Added
	# last with their own dice, so every other boulder keeps its place and its number (broken ones in saves).
	if maker.made_layout >= 13 and not maker.rooms.is_empty():
		var first: Dictionary = maker.rooms[0]
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = maker.seed + 9801
		var more := START_EXTRA
		for attempt in START_EXTRA * 40:
			if more <= 0 or maker.sdf_at(first.center) <= 0.0:
				break
			if _try(maker, first, rng2, near, taken, avoid, out, START_EDGE):
				more -= 1
	return out


## Layout 19 on: does `p` sit deeper inside another cave's oval than inside its own `room`'s? (Caves overlap; the
## Prow Hall's move in layout 19 put a third boulder in one cave that way.)
static func _deeper_in_another(maker: CaveMaker, room: Dictionary, p: Vector3) -> bool:
	var own := pow((p.x - room.center.x) / room.radii.x, 2) + pow((p.z - room.center.z) / room.radii.z, 2)
	for other in maker.rooms:
		if other == room:
			continue
		var rc: Vector3 = other.center
		var rr: Vector3 = other.radii
		if absf(p.y - rc.y) < rr.y * 1.5 + 2.0 and pow((p.x - rc.x) / rr.x, 2) + pow((p.z - rc.z) / rr.z, 2) < own:
			return true
	return false


## One try at a boulder in `room`: a low line from its middle to the floor by a wall. Appended to `out` if it fits.
## `outer`: how far out it must stand (0 = anywhere by a wall; 0.6 = the outer part of the cave's oval).
static func _try(maker: CaveMaker, room: Dictionary, rng: RandomNumberGenerator, near: Dictionary, taken: Array,
		avoid: Callable, out: Array[Dictionary], outer := 0.0) -> bool:
	# low lines from the middle: they land far out, by the walls (owner F404: "near the walls")
	var dir := Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.1, 0.45), rng.randf_range(-1, 1)).normalized()
	var model := rng.randi_range(0, MODELS.size() - 1)
	var spin := rng.randf_range(0.0, TAU)
	var scale := rng.randf_range(1.2, 2.0)  # (in-game look: 0.8-1.4 was pebble-sized)
	if room.big and rng.randf() < 0.15:
		scale = rng.randf_range(2.8, 4.2)  # now and then a really big one (owner, Nov 18)
	var buried := rng.randf() < 0.5  # half of them sunk into the ground (owner, Nov 18)
	var sink_part := rng.randf_range(0.2, 0.45)
	var hit := GlowPlacer._march(maker, room.center, dir, 60.0)
	if hit == Vector3.INF or GlowPlacer.normal_at(maker, hit).y < 0.85:
		return false  # open, fairly flat floor only
	if maker.sdf_at(hit + Vector3.UP * maxf(2.0, scale * 1.3)) <= 0.8:
		return false  # room above it
	if maker.is_reserved(hit, 3.0) or maker.on_bridge(hit, 2.0) or maker.on_trail(hit, 2.0) or maker._in_column(hit, 2.5):
		return false
	var rc: Vector3 = room.center
	var rr: Vector3 = room.radii
	if pow((hit.x - rc.x) / rr.x, 2) + pow((hit.z - rc.z) / rr.z, 2) > 1.1:
		return false  # (the line reached out of this cave into the next one: each cave counts its own)
	if outer > 0.0 and pow((hit.x - rc.x) / rr.x, 2) + pow((hit.z - rc.z) / rr.z, 2) < outer * outer:
		return false  # (the starting cave's extra ones: out by its edges, owner F418)
	if not near_wall(maker, hit, 1.0 * scale + 2.0):
		return false  # out in the open: boulders only stand by the walls (owner F404)
	if avoid.is_valid() and avoid.call(hit, 3.0):
		return false
	if maker.made_layout >= 19 and _deeper_in_another(maker, room, hit):
		return false  # (where two caves overlap: it counts for the other cave too; keeps each cave at 1-2, F404)
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
		return false  # too steep under it
	var bury := sink_part * 1.1 * scale if buried else 0.0
	var sink := (hit.y - low) + 0.08 + bury
	var key := Vector3i((hit / 4.0).floor())
	if near.has(key):
		return false  # one every few metres
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
		return false
	near[key] = true
	var lean := Vector3.UP.lerp(GlowPlacer.normal_at(maker, hit), 0.7).normalized()  # leans with the slope a little
	# On a chest's or a treasure's ground: kept in the list but never there (ids stay the same for saves).
	var gone := false
	for z in taken:
		if Vector2(hit.x - z.pos.x, hit.z - z.pos.z).length() < float(z.r) + 0.6 * scale and absf(hit.y - z.pos.y) < 3.0:
			gone = true
			break
	out.append({pos = hit - Vector3.UP * sink, model = model, spin = spin, scale = scale, sink = sink, lean = lean, bury = bury, gone = gone})
	return true


## Is there a cave wall within `reach` m of this floor spot (looking sideways at about knee-to-chest height)?
static func near_wall(maker: CaveMaker, at: Vector3, reach: float) -> bool:
	for k in 12:
		var a := k * TAU / 12.0
		var side := Vector3(cos(a), 0.0, sin(a))
		for h in [0.8, 1.6]:
			if GlowPlacer._march(maker, at + Vector3.UP * h, side, reach) != Vector3.INF:
				return true
	return false


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


## Rock dug (or filled) near a boulder: once the new rock is solid, it settles again, so digging under one never leaves
## it floating (owner, Nov 19: "yes"). Every computer sees the same dig, so every computer drops it the same way.
var _settle_asked := {}  ## rock -> when it was last asked to settle (F417)


func _on_rock_changed(center: Vector3, radius: float) -> void:
	for i in _rocks.size():
		var r: Dictionary = _rocks[i]
		if r.get("broken", false) or not is_instance_valid(r.get("body")):
			continue
		var reach := radius + 1.6 * float(r.scale)
		if Vector2(r.pos.x - center.x, r.pos.z - center.z).length() > reach or center.y > (r.pos as Vector3).y + float(r.sink) + reach:
			continue
		# F417 (Nov 28): a ruin digs 1000+ balls in one frame: one set of settles is enough for all of them (it was 3
		# timers per ball, 4000 settles at once a moment later)
		var now := Time.get_ticks_msec()
		if now - int(_settle_asked.get(i, -100000)) < 250:
			continue
		_settle_asked[i] = now
		for wait in [0.3, 1.0, 2.5]:  # (the new rock's shape is ready a moment after the dig)
			get_tree().create_timer(wait).timeout.connect(_settle.bind(i, 10.0))


## On the real rock (owner, Nov 18: "some of the boulders are still floating"): the real floor under its middle and
## round its edge; it stands as low as the lowest of them, sunk as planned. No rock under it at all: it goes.
## `deeper` = look further down (after a dig: it may drop into a hole).
func _settle(i: int, deeper := 0.0) -> void:
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
		var fl := GroundSnap.floor_at(space, at, 1.5 + scale, 2.5 + scale + deeper)
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
	elif not broken and r.broken and not r.get("gone", false):
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
