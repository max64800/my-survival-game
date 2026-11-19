class_name GroundSnap
extends Node
## Puts floor things down on the REAL rock (owner, Nov 18: boulders, mushroom grass, bones, rocks and moss "floating").
## Everything is planned from the cave's smooth shape, but the rock that's built is chunkier (blocks, slabs, the
## tower carving its ground), so a few centimetres to a metre can be missing under something. Once the rock around a
## batch is built, each floor thing in it is checked with a ray down onto the real rock: moved onto it, or hidden if
## there's no rock under it. A few batches a frame, so it never stutters.

static var instance: GroundSnap

var world: World
var _jobs: Array[Dictionary] = []  ## {mmi, set, lift, aabb} or {call, aabb}
var _check := 0
var moved := 0  ## (for the log and tests) things put down onto the real rock
var hidden := 0  ## things with no rock under them
var _said := 0.0


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


## Something now stands at `center` (a storage box, a ruin's treasure): pebbles, plants and mushroom grass within
## `radius` (plus their own margin) are taken away (World.ground_taken). Does nothing outside a running game.
static func take(center: Vector3, radius: float) -> void:
	if instance and instance.world:
		instance.world.ground_taken.emit(center, radius)


## A batch of floor things: `set` (optional) holds "where" (PackedVector3Array) and/or "xforms" (Array) to keep in step.
## `lift`: how high the thing's origin sits above the floor (negative = its foot goes into the floor).
## `after` runs once it's done (to copy the new places into the owner's own lists).
static func add_batch(mmi: MultiMeshInstance3D, set: Dictionary = {}, lift := 0.0, after := Callable()) -> void:
	if instance == null or mmi == null or mmi.multimesh == null:
		return
	var box := mmi.multimesh.get_aabb()
	var xforms: Array = set.get("xforms", [])
	if not xforms.is_empty():  # (the owner's own list knows where its things are, even when nothing is drawn)
		box = AABB((xforms[0] as Transform3D).origin, Vector3.ZERO)
		for xf: Transform3D in xforms:
			box = box.expand(xf.origin)
	instance._jobs.append({mmi = mmi, set = set, lift = lift, aabb = mmi.transform * box, after = after})


## Anything else: `call` runs once the rock in `aabb` is built.
static func when_built(aabb: AABB, call: Callable) -> void:
	if instance:
		instance._jobs.append({call = call, aabb = aabb})


func _physics_process(delta: float) -> void:
	_said += delta
	if _said > 30.0 and moved + hidden > 0:
		_said = 0.0
		print("GROUND_SNAP moved %d, hid %d, %d batches waiting for their rock" % [moved, hidden, _jobs.size()])
	if world == null or _jobs.is_empty():
		return
	var done := 0
	var looked := 0
	var built_checks := 0
	var t0 := Time.get_ticks_usec()
	var rays := 0
	# Up to 300 quick distance checks a step, but only 12 "is the rock built here?" checks (owner, Nov 19: rocks still
	# floating; with ~12,000 batches waiting, 12 looks a step took ~16 s to get round to the ones next to you).
	while looked < 300 and built_checks < 12 and done < 2 and not _jobs.is_empty():
		looked += 1
		_check = _check % _jobs.size()
		var job: Dictionary = _jobs[_check]
		if not is_instance_valid(job.get("mmi", self)) and not job.has("call"):
			_jobs.remove_at(_check)
			continue
		var box: AABB = (job.aabb as AABB).grow(1.0)
		if not _near_player(box):
			_check += 1
			continue
		built_checks += 1
		if not _built(box):
			_check += 1
			continue
		_jobs.remove_at(_check)
		if job.has("call"):
			(job.call as Callable).call()
		else:
			rays += (job.mmi as MultiMeshInstance3D).multimesh.instance_count
			_settle(job)
			if (job.after as Callable).is_valid():
				(job.after as Callable).call()
		done += 1
	var took := (Time.get_ticks_usec() - t0) / 1000.0
	if took > 50.0:  # (F417, owner Nov 19: 9 FPS once; the play log now says when this was the slow part)
		print("GROUND_SNAP slow step: %.0f ms (%d things checked, %d batches left)" % [took, rays, _jobs.size()])


## Only near a player is the rock solid (World.COLLISION_DISTANCE): further out a ray would find no floor.
func _near_player(box: AABB) -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null or DisplayServer.get_name() == "headless":
		return true
	return cam.global_position.distance_to(box.get_center()) < World.COLLISION_DISTANCE - 15.0


## Is the rock in `box` built (drawn, or at least solid)? Windowless tests build it without drawing it.
func _built(box: AABB) -> bool:
	if world.terrain.is_area_meshed(box):
		return true
	return DisplayServer.get_name() == "headless" and world.is_ready_at(box.get_center(), maxf(box.size.x, box.size.z) * 0.5) and Engine.get_physics_frames() > 30


func _settle(job: Dictionary) -> void:
	var mmi: MultiMeshInstance3D = job.mmi
	var mm := mmi.multimesh
	var set: Dictionary = job.set
	var lift: float = job.lift
	var space := mmi.get_world_3d().direct_space_state
	var where: PackedVector3Array = set.get("where", PackedVector3Array())
	var xforms: Array = set.get("xforms", [])
	var changed := false
	for i in mm.instance_count:
		var xf: Transform3D = xforms[i] if i < xforms.size() else mm.get_instance_transform(i)
		if xf.basis.get_scale().x < 0.001 or mm.get_instance_transform(i).basis.get_scale().x < 0.001:
			continue  # already hidden (also when only the drawn copy is: dug away, broken, or under a chest; the owner's
			# list keeps where it grew so it can grow back, and that mustn't bring it back here)
		var up := xf.basis.y.normalized()
		if up.y < 0.5:
			continue  # walls and ceilings stay as they are
		var world_o := mmi.global_transform * xf.origin
		var fl := floor_at(space, world_o, 0.9, 1.4)
		if fl == Vector3.INF:
			xf = Transform3D(Basis().scaled(Vector3.ONE * 0.0001), xf.origin)  # no rock under it: hidden
			hidden += 1
		else:
			var want := fl.y + lift
			if absf(world_o.y - want) < 0.06:
				continue
			xf.origin.y += want - world_o.y
			moved += 1
		mm.set_instance_transform(i, xf)
		if i < where.size():
			where[i] = xf.origin
		if i < xforms.size():
			xforms[i] = xf
		changed = true
	if changed and set.has("where"):
		set.where = where


## The real rock's floor under p (a ray from `up` above to `down` below), skipping boulders and trees; INF if none.
static func floor_at(space: PhysicsDirectSpaceState3D, p: Vector3, up := 0.9, down := 1.4) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * up, p - Vector3.UP * down, World.TERRAIN_LAYER)
	q.hit_back_faces = false  # (a start inside the rock must not count its inside as a floor)
	q.hit_from_inside = false
	var skip: Array[RID] = []
	for k in 4:
		q.exclude = skip
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return Vector3.INF
		var c: Object = hit.collider
		if c is Node and ((c as Node).has_meta("boulder") or (c as Node).has_meta("root_pillar")):
			skip.append(hit.rid)
			continue
		if (hit.normal as Vector3).y < 0.3:
			return Vector3.INF  # a wall or overhang, not a floor
		return hit.position
	return Vector3.INF
