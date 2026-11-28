class_name PoiField
extends Node3D
## Shows the special places the Cave Maker planned (world doc 3.1): ruins, camps, rune
## shrines, nests, the Great Hall. Same on every computer.
## What you can DO at them goes through the GameAuthority (take a rune).

const POI_LAYER := 16  ## aim + E, like stations

var maker: CaveMaker
var _nodes := {}  ## poi id -> Node3D
## The ruins' stone columns (owner, Nov 19: "sometimes they're still floating, and you cannot destroy them; you should
## be able to destroy them for some stone"). id (poi id * COLS_PER_POI + its number) -> {node, body, width, height, hits}.
## Each sits on the real rock once it's built and again after digging nearby; the pickaxe breaks it (GameAuthority).
var _columns := {}
var _col_rids: Array[RID] = []  ## the columns' own bodies: the floor rays look through them
var _new_cols: Array[int] = []
const COLS_PER_POI := 16
const MAX_SINK := 1.6  ## a column may sink this far into the higher side of uneven rock; over a bigger drop it isn't made
static var _mats := {}


func build(p_maker: CaveMaker) -> void:
	maker = p_maker
	var fort := RuinOutpost.pick_room(maker)  # the Fallen Outpost's cavern: its row of old columns would stand in the yard
	for p in maker.pois:
		if p.type == "colonnade" and int(p.get("room", -1)) == fort:
			continue
		if p.type == "colonnade" and maker.is_reserved(p.pos, 4.0):
			continue  # (its old columns would stand inside the ruined watchtower: the placement rule)
		_new_cols.clear()
		var n := _make(p)
		if n:
			add_child(n)
			n.global_position = p.pos
			_nodes[p.id] = n
			if p.type == "shrine":
				_ground_shrine(n)
			for cid in _new_cols:
				var at: Vector3 = (_columns[cid].node as Node3D).global_position
				GroundSnap.when_built(AABB(at - Vector3(2, 3, 2), Vector3(4, 6, 4)), _settle_column.bind(cid))


## A rune shrine stands on its alcove's floor (owner, Nov 19: "all the time they're spawning in mid-air": its spot is
## the middle of the round alcove, ~1.5 m up), then on the real rock once that's built.
func _ground_shrine(n: Node3D) -> void:
	var p := n.global_position
	var fl := maker.find_floor(p.x, p.z, p.y + 0.5)
	if fl.y < p.y and p.y - fl.y < 7.0:
		n.global_position = fl
	GroundSnap.when_built(AABB(n.global_position - Vector3(1, 2, 1), Vector3(2, 4, 2)), func() -> void:
		if not is_instance_valid(n) or not n.is_inside_tree():
			return
		var real := GroundSnap.floor_at(n.get_world_3d().direct_space_state, n.global_position, 1.0, 2.5)
		if real != Vector3.INF:
			n.global_position = real)


static func poi_id_of(collider: Object) -> int:
	if collider is Node and collider.has_meta("poi_id"):
		return collider.get_meta("poi_id")
	return -1


## A shrine's rune was taken: dim its glow.
func set_taken(poi_id: int) -> void:
	var n: Node3D = _nodes.get(poi_id)
	if n and n.has_node("Rune"):
		n.get_node("Rune").visible = false


func _make(p: Dictionary) -> Node3D:
	var root := StaticBody3D.new()
	root.collision_layer = 0
	root.collision_mask = 0
	match p.type:
		"gate":
			# The plug of border rock between two biomes: a carved arch with a glowing seal.
			var arch_mat := _mat(Color(0.4, 0.36, 0.45))
			_part(root, _box(Vector3(0.6, 3.6, 0.6)), arch_mat, Vector3(-2.0, 1.2, 0.2))
			_part(root, _box(Vector3(0.6, 3.6, 0.6)), arch_mat, Vector3(2.0, 1.2, 0.2))
			_part(root, _box(Vector3(4.6, 0.6, 0.6)), arch_mat, Vector3(0, 3.0, 0.2))
			_part(root, _box(Vector3(1.4, 1.4, 0.06)), _mat(Color(0.65, 0.4, 1.0), 1.6), Vector3(0, 1.2, 0.05))
			root.look_at_from_position(Vector3.ZERO, -p.normal, Vector3.UP)
			_label(root, "Border rock · a Copper Pickaxe breaks it" if p.biome == "mossy" else "Border rock · the way back to Mossy Hollows", 3.6)
		"shrine":
			root.collision_layer = POI_LAYER
			root.set_meta("poi_id", p.id)
			_shape(root, Vector3(0.8, 1.2, 0.8), Vector3(0, 0.6, 0))
			_part(root, _cyl(0.35, 0.45, 0.9), _mat(Color(0.55, 0.52, 0.5)), Vector3(0, 0.45, 0))
			var rune := _part(root, _box(Vector3(0.25, 0.32, 0.08)), _mat(Color(0.95, 0.7, 0.3), 2.5), Vector3(0, 1.15, 0))
			rune.name = "Rune"
			rune.rotation.y = 0.6
			var l := OmniLight3D.new()
			GraphicsSettings.cheap_light(l, 30.0)  # off smoothly when far away (owner, Nov 19)
			l.light_color = Color(1.0, 0.75, 0.4)
			l.omni_range = 4.0
			l.light_energy = 0.8
			Darkness.mark(l)
			l.position = Vector3(0, 1.2, 0)
			rune.add_child(l)
			_label(root, "Rune shrine · E", 1.8)
		"ruin":
			# An old dwarf hall, fallen in (F9/F21): a ring of carved columns (most broken),
			# stretches of block wall with gaps, and a doorway of two columns.
			var rng := _rng_for(p)
			for i in 6:
				var a := i * TAU / 6.0 + 0.4
				var at := _on_floor(p, Vector3(cos(a), 0, sin(a)) * 4.6)
				_col(root, p, i, at, rng.randf_range(3.6, 4.6), 0.7, 0.0 if rng.randf() < 0.3 else rng.randf_range(0.2, 0.75), rng)
			RuinKit.broken_wall(root, _on_floor(p, Vector3(-2.5, 0, -3.6)), _on_floor(p, Vector3(2.5, 0, -3.6)), 3, rng)
			RuinKit.broken_wall(root, _on_floor(p, Vector3(-3.8, 0, 1.0)), _on_floor(p, Vector3(-3.8, 0, -2.2)), 2, rng)
			RuinTreasure.dress(root, p, _on_floor)  # coins, candles and books by the loot chest (owner, Nov 19)
		"colonnade":
			# A row of great columns standing in a cavern, some broken (F9/F21).
			var rng := _rng_for(p)
			var count := rng.randi_range(3, 5)
			var along := Vector3(cos(p.get("yaw", 0.0)), 0, sin(p.get("yaw", 0.0)))
			for i in count:
				var off: Vector3 = along * (float(i) - (count - 1) * 0.5) * 3.8
				var whole := rng.randf() < 0.4
				_col(root, p, i, _on_floor(p, off), rng.randf_range(5.0, 7.0), 0.95, 0.0 if whole else rng.randf_range(0.15, 0.7), rng)
		"camp":
			_part(root, _box(Vector3(0.9, 0.12, 1.9)), _mat(Color(0.45, 0.3, 0.25)), Vector3(1.2, 0.06, 0))  # bedroll
			for i in 6:
				var a := i * TAU / 6.0
				_part(root, _sphere(0.15), _mat(Color(0.35, 0.33, 0.3)), Vector3(cos(a), 0.08, sin(a)) * 0.4 + Vector3(-0.8, 0, 0))
			_part(root, _box(Vector3(0.5, 0.05, 0.3)), _mat(Color(0.12, 0.1, 0.08)), Vector3(-0.8, 0.03, 0))  # ashes
			RuinTreasure.dress(root, p, _on_floor)  # a traveller's mug, plate, map and pouch
		"nest":
			for i in 7:
				var a := i * TAU / 7.0
				_part(root, _sphere(0.3), _mat(Color(0.75, 0.72, 0.55)), Vector3(cos(a), 0.2, sin(a)) * 1.2)  # eggs
			_part(root, _cyl(1.8, 2.2, 0.4), _mat(Color(0.35, 0.28, 0.18)), Vector3(0, 0.1, 0))
		"great_hall":
			var grng := _rng_for(p)
			for i in 8:
				var a := i * TAU / 8.0
				_col(root, p, i, _on_floor(p, Vector3(cos(a), 0, sin(a)) * 10.0), 6.5, 1.1, 0.0 if i % 3 != 2 else grng.randf_range(0.3, 0.7), grng, Color(0.8, 0.78, 0.74))
			RuinTreasure.dress(root, p, _on_floor)
		_:
			return null
	return root


## A ruin column, numbered so every computer means the same one (the host breaks it by number).
func _col(root: Node3D, p: Dictionary, i: int, at: Vector3, height: float, width: float, broken_at: float, rng: RandomNumberGenerator, color: Color = RuinKit.STONE) -> void:
	if maker and p.has("pos"):
		var drop := base_drop(maker, (p.pos as Vector3) + at, width)
		if drop > MAX_SINK:
			return  # (F878: its base would hang over a drop or a ledge's edge: it fell long ago)
		at.y -= drop  # down to the lowest rock round its base (sunk into the higher side, like an old buried column)
	var col := RuinKit.column(root, at, height, width, broken_at, rng, color)
	var cid := int(p.id) * COLS_PER_POI + i
	var body: StaticBody3D = col.get_meta("solid")
	body.set_meta("ruin_col", cid)
	_col_rids.append(body.get_rid())
	var tall := (height - 1.3) * (broken_at if broken_at > 0.0 else 1.0) + 1.3
	_columns[cid] = {node = col, body = body, width = width, height = tall, hits = clampi(roundi(width * tall * 1.5), 3, 10)}
	_new_cols.append(cid)


## How far a column's base at `at` must go down so its whole base sits on rock: the floor under its middle and round
## its edge (F878, owner Nov 25: "some stone columns float in the air": a row hung over a drop, only its middle was
## checked).
static func base_drop(m: CaveMaker, at: Vector3, width: float) -> float:
	var drop := 0.0
	for k in 5:
		var p := at
		if k > 0:
			var a := k * TAU / 4.0 + 0.4
			p += Vector3(cos(a), 0.0, sin(a)) * width * 0.55
		drop = maxf(drop, p.y - m.find_floor(p.x, p.z, p.y + 0.5).y)
	return drop


## Which ruin column a ray hit (its column or a fallen drum of it), or -1.
static func column_id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("ruin_col"):
		return int((collider as Node).get_meta("ruin_col"))
	return -1


func column(cid: int) -> Dictionary:
	var c: Dictionary = _columns.get(cid, {})
	return {} if c.is_empty() or c.get("gone", false) or not is_instance_valid(c.node) else c


## Where to aim at it: its middle, at most chest high.
func column_middle(cid: int) -> Vector3:
	var c := column(cid)
	if c.is_empty():
		return Vector3.INF
	return (c.node as Node3D).global_position + Vector3.UP * minf(1.2, float(c.height) * 0.5)


## From the host: the column crumbled (burst = chunks fly; false when loading a save).
func set_column_broken(cid: int, burst := true) -> void:
	var c := column(cid)
	if c.is_empty():
		return
	c.gone = true
	var col: Node3D = c.node
	if burst and col.is_inside_tree():
		var mid := col.global_position + Vector3.UP * float(c.height) * 0.5
		RockShatter.burst(self, mid, Vector3.UP, RuinKit.STONE, Mat.STONE, float(c.width) * 1.5)
		RockShatter.burst(self, col.global_position + Vector3.UP * 0.4, Vector3(1, 0.4, 0), RuinKit.STONE, Mat.STONE, float(c.width) * 1.5)
	_col_rids.erase((c.body as StaticBody3D).get_rid())
	col.queue_free()


## On the real rock: as low as the floor under its middle and round its base (never hanging over a dip or a dug hole).
## `deeper` = look further down (after a dig it may drop into the hole).
func _settle_column(cid: int, deeper := 0.0) -> void:
	var c := column(cid)
	if c.is_empty() or not (c.node as Node3D).is_inside_tree():
		return
	var col: Node3D = c.node
	if GroundSnap.instance and GroundSnap.instance.world and not GroundSnap.instance.world.changed.is_connected(_on_rock_changed):
		GroundSnap.instance.world.changed.connect(_on_rock_changed)
	var space := col.get_world_3d().direct_space_state
	var base := col.global_position
	var low := INF
	var found := 0
	for k in 5:
		var at := base
		if k > 0:
			var a := k * TAU / 4.0 + 0.4
			at += Vector3(cos(a), 0.0, sin(a)) * float(c.width) * 0.55
		var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.5, at - Vector3.UP * (2.5 + deeper), World.TERRAIN_LAYER)
		q.exclude = _col_rids
		q.hit_back_faces = false
		q.hit_from_inside = false
		var h := space.intersect_ray(q)
		if not h.is_empty():
			low = minf(low, (h.position as Vector3).y)
			found += 1
	if found >= 2:
		col.global_position = Vector3(base.x, low - 0.05, base.z)


## Rock dug (or filled) near a column: once the new rock is solid it settles again, like the boulders.
var _settle_asked := {}  ## rock -> when it was last asked to settle (F417)


func _on_rock_changed(center: Vector3, radius: float) -> void:
	for cid in _columns:
		var c := column(cid)
		if c.is_empty():
			continue
		var p: Vector3 = (c.node as Node3D).global_position
		var reach := radius + float(c.width) * 1.5 + 1.0
		if Vector2(p.x - center.x, p.z - center.z).length() > reach or center.y > p.y + reach:
			continue
		# F417 (Nov 28): a ruin digs 1000+ balls in one frame: one set of settles is enough for all of them (it was 3
		# timers per ball, 4000 settles at once a moment later)
		var now := Time.get_ticks_msec()
		if now - int(_settle_asked.get(cid, -100000)) < 250:
			continue
		_settle_asked[cid] = now
		for wait in [0.3, 1.0, 2.5]:  # (the new rock's shape is ready a moment after the dig)
			get_tree().create_timer(wait).timeout.connect(_settle_column.bind(cid, 10.0))


## Same dice for the same place on every computer (co-op friends see the same broken columns).
static func _rng_for(p: Dictionary) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i((p.pos as Vector3).round())) + int(p.get("id", 0))
	return rng


## A spot `offset` away from the place's center, dropped onto the floor there (local to the place).
func _on_floor(p: Dictionary, offset: Vector3) -> Vector3:
	var c: Vector3 = p.pos
	var f := maker.find_floor(c.x + offset.x, c.z + offset.z, c.y + 1.5)
	return Vector3(offset.x, f.y - c.y, offset.z)


func _label(parent: Node3D, text: String, y: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3.UP * y
	l.pixel_size = 0.004
	l.font_size = 32
	l.outline_size = 8
	l.visibility_range_begin = 1.5
	l.visibility_range_end = 14.0
	parent.add_child(l)


func _shape(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _mat(c: Color, glow: float = 0.0) -> Material:
	return Look.mat(c, "", glow, 0.0 if glow > 0.0 else 0.03)  # old ruins: a bit crooked


static func _box(s: Vector3) -> Mesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 8
	return c


static func _sphere(r: float) -> Mesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 8
	s.rings = 4
	return s
