class_name RootPillars
extends Node3D
## Root Trees (owner, Nov 18: "this is a perfect way to get trees... enormous roots"; plan: docs/design/root-trees-plan.md).
## Ancient Trunks from floor to ceiling (tools/asset_forge/builds/cave_rootpillar.py: rtree_b1-b3): 3 in the first
## cave, 1-2 in every other big cave. Every hit gives wood (axe 2, pickaxe 1) until CHOPS are taken; chunks of wood
## burst off at 10 and 20; on the last chop it cracks: the top pulls back into the ceiling (the crown stays there), the
## bottom crumbles to a stump, and it drops 1-2 Root Seeds. A seed planted with the Mason's Shovel grows: a seedling,
## after 30 minutes a sprout, after 30 more a full Root Tree up to the ceiling, each step only while nobody looks at it.
## The host keeps the counts (GameAuthority.pillar_chops, .planted); this node shows them.

const MODELS := ["res://assets/models/cave/rtree_b1.glb", "res://assets/models/cave/rtree_b2.glb", "res://assets/models/cave/rtree_b3.glb"]
const STUMP := "res://assets/models/cave/rtree_stump.glb"
const CROWN := "res://assets/models/cave/rtree_crown.glb"
const SEED_MODEL := "res://assets/models/items/root_seed.glb"
const CHOPS := 30  ## wood a Root Tree gives before it cracks
const STAGE_CHOPS := [10, 20]  ## chunks of wood burst off here
const GROW_TIME := 3600.0  ## seconds from planting to a full tree (a sprout halfway)
const PLANTED_ID := 10000  ## planted trees' ids start here
## A broken tree grows back from both ends (owner, Nov 18): the stump grows up and the ceiling crown grows down, a step
## every 15 minutes, and after 45 they meet in the middle: a full tree again.
const REGROW_TIME := 2700.0
const REGROW_STRETCH := {"regrow1": 1.35, "regrow2": 1.75}  ## how far the stump and crown reach (x their broken size): the gap between them is 50% of the height broken, 33% at step 1, 13% at step 2
const WOOD := Color(0.42, 0.28, 0.17)

var _trees := {}  ## id -> {top, bottom, width, model, spin, body, used, stage, want_stage}
var _cam_check := 0.0


func build(maker: CaveMaker) -> void:
	var list := plan(maker)
	for i in list.size():
		_add_tree(i, list[i], "tree")


## [{top, bottom, width, model, spin}] for this cave: 3 in the first cave, 1-2 in every other big one.
static func plan(maker: CaveMaker) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9401
	for ri in maker.rooms.size():
		var room: Dictionary = maker.rooms[ri]
		var want := 3 if ri == 0 else rng.randi_range(1, 2)
		if not room.big or room.get("sealed", false):
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var placed := 0
		# The first cave tries much harder and further out (owner F405, Nov 19: "the starting cave has no big tree, it
		# needs at least 2"): 40 tries often found only 1 spot clear of the tower, the stone columns and the paths.
		for attempt in (800 if ri == 0 else 40):
			if placed >= want:
				break
			var a := rng.randf_range(0.0, TAU)
			var d := rng.randf_range(0.15, 0.95 if ri == 0 else 0.7)
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
			if h < 5.0 or h > 22.0:  # (up to 22 m: the first cave's ceiling is high; owner saw no trees there)
				continue
			width = maxf(width, h * 0.9)  # tall ones stay massive, not stretched thin (in-game look: still thin at 0.6)
			if maker.on_bridge(top, 2.0) or maker.on_bridge(bottom, 2.0):
				continue  # up to a real ceiling, never into a bridge (and not standing on one)
			if not _clear(maker, at, width * 0.45, out):
				continue
			out.append({top = top + Vector3.UP * 0.3, bottom = bottom - Vector3.UP * 0.3, width = width, model = model, spin = spin})
			placed += 1
	return out


## The placement rule: not on kept-clear ground, a bridge, a stone column, a place, a path or another tree.
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


func _add_tree(id: int, p: Dictionary, stage: String) -> void:
	var t := p.duplicate()
	t.used = 0
	t.stage = ""
	t.want_stage = stage
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER  # you bump into it and aim at it, like the rock
	body.collision_mask = 0
	body.set_meta("root_pillar", id)
	add_child(body)
	body.global_position = t.top
	t.body = body
	_trees[id] = t
	_show(id, stage)


## Swap what tree `id` looks like: "seed", "sprout", "tree", "broken".
func _show(id: int, stage: String) -> void:
	var t: Dictionary = _trees[id]
	if t.stage == stage:
		return
	t.stage = stage
	var body: StaticBody3D = t.body
	for c in body.get_children():
		c.queue_free()
	var top: Vector3 = t.top
	var h: float = top.y - (t.bottom as Vector3).y
	var flip := Basis(Vector3.RIGHT, PI) * Basis(Vector3.UP, t.spin)
	match stage:
		"tree", "broken", "regrow1", "regrow2":
			var paths: Array = [MODELS[t.model]] if stage == "tree" else [STUMP, CROWN]
			var k: float = REGROW_STRETCH.get(stage, 1.0)
			for path in paths:
				var scene := load(path) as PackedScene
				if scene:
					var m := scene.instantiate() as Node3D
					m.basis = flip * Basis.from_scale(Vector3(t.width, h * k, t.width))
					if path == STUMP:
						m.position = Vector3.UP * h * (k - 1.0)  # the stump grows up from the floor (the crown down from the ceiling)
					body.add_child(m)
					_add_skin(body, m)  # solid all the way round its bark (owner, Nov 18: "I can walk fully inside")
		"seed", "sprout":
			# planted: a seed in a little mound, then a waist-high young tree (the same tree, small, standing on the floor)
			var bottom: Vector3 = t.bottom
			if stage == "seed":
				var s := load(SEED_MODEL) as PackedScene
				if s:
					var m := s.instantiate() as Node3D
					m.scale = Vector3.ONE * 3.0
					body.add_child(m)
					m.global_position = bottom + Vector3.UP * 0.25
			else:
				var scene := load(MODELS[t.model]) as PackedScene
				if scene:
					var m := scene.instantiate() as Node3D
					var sh := 1.3
					m.basis = flip * Basis.from_scale(Vector3(1.1, sh, 1.1))
					body.add_child(m)
					m.global_position = bottom + Vector3.UP * (sh + 0.3)


## The tree's own shape as its collision: every bark face is solid, so you walk round the trunk and over its feet.
static func _add_skin(body: StaticBody3D, m: Node3D) -> void:
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var xf := m.transform * mi.transform
		var faces := mi.mesh.get_faces()
		for i in faces.size():
			faces[i] = xf * faces[i]
		var skin := ConcavePolygonShape3D.new()
		skin.set_faces(faces)
		skin.backface_collision = true  # (solid from inside too, if you ever end up in a hollow)
		var shape := CollisionShape3D.new()
		shape.shape = skin
		body.add_child(shape)


## Trunks to keep clear of (for flying things): [{p (on the trunk's axis), r (metres), top, bottom}].
func trunks() -> Array:
	var out := []
	for id in _trees:
		var t: Dictionary = _trees[id]
		if t.stage == "tree":
			out.append({p = (t.top as Vector3).lerp(t.bottom, 0.5), r = float(t.width) * 0.4, top = (t.top as Vector3).y, bottom = (t.bottom as Vector3).y})
	return out


## How much wood tree `id` has given (from the host): shows the chunks bursting off, and the crack at the end.
func set_used(id: int, used: int, burst := true) -> void:
	if not _trees.has(id):
		return
	var t: Dictionary = _trees[id]
	var before: int = t.used
	t.used = used
	var mid: Vector3 = (t.top as Vector3).lerp(t.bottom, 0.65)
	if burst:
		for s in STAGE_CHOPS:
			if before < s and used >= s:
				RockShatter.burst(get_parent(), mid, Vector3(cos(t.spin), 0.3, sin(t.spin)), WOOD)
	if used >= CHOPS and t.stage == "tree":
		if burst:  # the crack: the bottom crumbles into wood chunks
			for k in 3:
				RockShatter.burst(get_parent(), (t.top as Vector3).lerp(t.bottom, 0.55 + 0.15 * k), Vector3(cos(k * 2.1), 0.4, sin(k * 2.1)), WOOD)
		_show(id, "broken")
		t.want_stage = "broken"


## A tree planted by a player (from the host): {id, pos (floor), top (ceiling), grow (seconds left), model, spin}.
func add_planted(e: Dictionary) -> void:
	if _trees.has(int(e.id)):
		return
	var h: float = (e.top as Vector3).y - (e.pos as Vector3).y
	var p := {top = (e.top as Vector3) + Vector3.UP * 0.3, bottom = (e.pos as Vector3) - Vector3.UP * 0.3,
		width = maxf(5.0, h * 0.6), model = int(e.model), spin = float(e.spin)}
	_add_tree(int(e.id), p, stage_of(float(e.grow)))


## Regrowing a broken tree: which step it's at with `left` seconds to go.
static func regrow_stage(left: float) -> String:
	if left > REGROW_TIME * 2.0 / 3.0:
		return "broken"
	if left > REGROW_TIME / 3.0:
		return "regrow1"
	if left > 0.0:
		return "regrow2"
	return "tree"


## From the host: broken tree `id` has `left` seconds until it's whole (0 = whole again, ready to chop).
func set_regrow(id: int, left: float) -> void:
	if not _trees.has(id):
		return
	_trees[id].want_stage = regrow_stage(left)
	if left <= 0.0:
		_trees[id].used = 0


static func stage_of(grow_left: float) -> String:
	if grow_left > GROW_TIME * 0.5:
		return "seed"
	if grow_left > 0.0:
		return "sprout"
	return "tree"


## The host says planted tree `id` has `grow_left` seconds to go: it changes when nobody is looking at it.
func set_growth(id: int, grow_left: float) -> void:
	if _trees.has(id):
		_trees[id].want_stage = stage_of(grow_left)


func _process(delta: float) -> void:
	_cam_check -= delta
	if _cam_check > 0.0:
		return
	_cam_check = 1.0
	var cam := get_viewport().get_camera_3d()
	for id in _trees:
		var t: Dictionary = _trees[id]
		if t.want_stage == t.stage:
			continue
		var mid: Vector3 = (t.top as Vector3).lerp(t.bottom, 0.5)
		var seen := cam != null and cam.global_position.distance_to(mid) < 60.0 and cam.is_position_in_frustum(mid)
		if not seen:  # (grows only while nobody is looking)
			_show(id, t.want_stage)


## Which tree a ray hit (its collider), or -1.
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("root_pillar"):
		return int((collider as Node).get_meta("root_pillar"))
	return -1


func pillar(id: int) -> Dictionary:
	return _trees.get(id, {})


## Is there a tree (or planted seed) within `r` of p?
func near(p: Vector3, r: float) -> bool:
	for id in _trees:
		var t: Dictionary = _trees[id]
		if Vector2(t.top.x - p.x, t.top.z - p.z).length() < r:
			return true
	return false
