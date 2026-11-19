class_name GlowGroves
extends Node3D
## Glow groves (owner, Nov 19, 2026: "the trees glow ... sometimes the main source of light in some caves"; decisions
## in docs/research/asset-picks-placement.md). 1-2 big caverns per biome (never the first cave) hold a small forest:
## glowing trees (their leaves glow in the grove's colour) with dark trees standing between them (twisted ones glow
## faintly, leafless ones not at all). A few soft coloured lights make the trees the cavern's main light.
## Models: tools/asset_forge/builds/glow_trees.py (free CC0 pack trees rebuilt in our style). Every player plans the
## same groves from the cave's seed. Sizes (owner, Nov 19): "some big, some very tiny, like a bush the size of the
## dwarf", and the wood they give grows with them. Chopping works like the Root Trees: the host counts the wood
## (GameAuthority.grove_chops); a tree that gave all its wood comes down and grows back after REGROW_TIME.

const GLOW := ["gtree_common_1", "gtree_common_2", "gtree_common_3", "gtree_common_4", "gtree_common_5",
	"gtree_pine_1", "gtree_pine_2", "gtree_pine_3", "gtree_pine_4", "gtree_pine_5"]
const DARK := ["dtree_dead_1", "dtree_dead_2", "dtree_dead_3", "dtree_dead_4", "dtree_dead_5",
	"dtree_twisted_1", "dtree_twisted_2", "dtree_twisted_3", "dtree_twisted_4", "dtree_twisted_5",
	"dtree_bare_1", "dtree_bare_2", "dtree_bare_3", "dtree_bare_4", "dtree_bare_5", "dtree_bare_6"]
## One colour per grove, by biome (the first grove of a biome takes the first colour).
const COLOURS := {"mossy": [Color(0.25, 0.95, 0.85), Color(0.30, 0.55, 1.0)],
	"fungal": [Color(0.70, 0.40, 1.0), Color(1.0, 0.45, 0.70)]}
const ROCKS := ["grock_a", "grock_b", "grock_c", "grock_d", "grock_e", "grock_f", "grock_g", "grock_h", "grock_i",
	"grock_j", "grock_k", "grock_l", "grock_m", "grock_n", "grock_o", "grock_p", "grock_q", "grock_r",
	"grock_medium_1", "grock_medium_2", "grock_medium_3"]
const PEBBLES := ["gpebble_round_1", "gpebble_round_2", "gpebble_round_3", "gpebble_round_4", "gpebble_round_5",
	"gpebble_square_1", "gpebble_square_2", "gpebble_square_3", "gpebble_square_4", "gpebble_square_5", "gpebble_square_6"]
const PLANTS := ["gplant_grass_short", "gplant_grass_tall", "gplant_grass_c", "gplant_grass_d", "gplant_clover_1",
	"gplant_clover_2", "gplant_fern", "gplant_leafy_1", "gplant_leafy_1_big", "gplant_flat_7", "gplant_flat_7_big",
	"gplant_flower_bush"]
const CAPS := ["gfungus_cap"]
const MODEL_HEIGHT := 7.0  ## about how tall the models are (m); low ceilings scale a tree down
const TRUNK_R := 0.45  ## the trunk you bump into (m)
const SEEN_TO := 140.0  ## drawn up to this far away (m)
## Tree sizes: [share, smallest scale, biggest scale]. A bush is about dwarf height (0.2 x 7 m = 1.4 m).
const SIZES := [[0.25, 0.18, 0.28], [0.3, 0.35, 0.6], [0.45, 0.7, 1.25]]
const WOOD_MIN := 3  ## wood from the smallest bush
const WOOD_MAX := 36  ## wood from the biggest tree (a Root Tree gives 30)
const REGROW_TIME := 2700.0  ## seconds until a felled grove tree stands again (like a Root Tree)

var _trees: Array[Dictionary] = []
var _by_id := {}  # tree id -> its plan
var _nodes := {}  # tree id -> [model, trunk body]
var _mats := {}  # [grove index, material] -> recoloured copy


func build(maker: CaveMaker, avoid: Callable = Callable()) -> void:
	var groves := plan(maker, avoid)
	for gi in groves.size():
		var g: Dictionary = groves[gi]
		for t: Dictionary in g.trees:
			_add_tree(gi, g.colour, t)
			_trees.append(t)
			_by_id[int(t.id)] = t
		for d: Dictionary in g.dressing:
			var dn := _add_dressing(d)
			if dn and d.has("on") and _nodes.has(int(d.on.id)):  # shelf fungus comes down with its tree
				(_nodes[int(d.on.id)] as Array).append(dn)
		_add_lights(g)


## [{room, biome, colour, trees: [{id, pos, model, scale, spin, glow, wood}]}] for this cave. Same dice for every player.
static func plan(maker: CaveMaker, avoid: Callable = Callable()) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 7733
	var by_biome := {}  # biome -> its big caverns (never the first cave, where you arrive)
	for ri in range(1, maker.rooms.size()):
		var room: Dictionary = maker.rooms[ri]
		if room.big and not room.get("sealed", false):
			var b: String = room.get("biome", "mossy")
			if not by_biome.has(b):
				by_biome[b] = []
			by_biome[b].append(ri)
	var placed_all: Array[Dictionary] = []
	for biome: String in by_biome:
		var rooms: Array = by_biome[biome]
		for i in range(rooms.size() - 1, 0, -1):  # shuffle with the cave's own dice
			var j := rng.randi_range(0, i)
			var tmp = rooms[i]
			rooms[i] = rooms[j]
			rooms[j] = tmp
		var cap := rng.randi_range(1, 2)  # 1-2 groves per biome (owner): they stay special
		var made := 0
		for ri in rooms:
			if made >= cap:
				break
			var trees := _plant(maker, maker.rooms[ri], rng, avoid, placed_all)
			if trees.size() < 6:
				continue  # too cramped for a forest: try the next cavern
			var cols: Array = COLOURS.get(biome, COLOURS.mossy)
			out.append({room = ri, biome = biome, colour = cols[made % cols.size()], trees = trees,
				dressing = _dress(maker, maker.rooms[ri], rng, trees, avoid)})
			placed_all.append_array(trees)
			made += 1
	var next_id := 0
	for g in out:  # the same tree number on every player's screen
		for t: Dictionary in g.trees:
			t.id = next_id
			next_id += 1
	return out


## The wood a tree of this scale gives: a bush a few bits, the biggest a bit more than a Root Tree.
static func wood_for(s: float) -> int:
	var lo: float = SIZES[0][1]
	var hi: float = SIZES[SIZES.size() - 1][2]
	return clampi(roundi(lerpf(WOOD_MIN, WOOD_MAX, (s - lo) / (hi - lo))), WOOD_MIN, WOOD_MAX)


static func _plant(maker: CaveMaker, room: Dictionary, rng: RandomNumberGenerator, avoid: Callable, others: Array) -> Array[Dictionary]:
	var c: Vector3 = room.center
	var r: Vector3 = room.radii
	var trees: Array[Dictionary] = []
	var want_glow := rng.randi_range(6, 10)
	var want_dark := rng.randi_range(5, 8)
	for attempt in 160:
		var glow := trees.filter(func(t): return t.glow).size()
		var dark := trees.size() - glow
		if glow >= want_glow and dark >= want_dark:
			break
		var is_glow := glow < want_glow and (dark >= want_dark or rng.randf() < 0.55)
		var a := rng.randf_range(0.0, TAU)
		var d := sqrt(rng.randf()) * 0.78
		var at := Vector3(c.x + cos(a) * r.x * d, c.y, c.z + sin(a) * r.z * d)
		if maker.sdf_at(at) <= 0.5:
			continue
		var top := GlowPlacer._march(maker, at, Vector3.UP, 30.0)
		var bottom := GlowPlacer._march(maker, at, Vector3.DOWN, 30.0)
		if top == Vector3.INF or bottom == Vector3.INF:
			continue
		var room_h := top.y - bottom.y
		if room_h < 5.0:
			continue
		var roll := rng.randf()
		var size: Array = SIZES[SIZES.size() - 1]
		for sz: Array in SIZES:
			if roll < float(sz[0]):
				size = sz
				break
			roll -= float(sz[0])
		var s := minf(rng.randf_range(size[1], size[2]), (room_h - 1.2) / MODEL_HEIGHT)
		var pos := bottom - Vector3.UP * 0.15  # the roots go a little into the floor
		if not _clear(maker, pos, 1.6 * s, trees, others, avoid):
			continue
		var list: Array = GLOW if is_glow else DARK
		trees.append({pos = pos, model = list[rng.randi_range(0, list.size() - 1)], scale = s,
			spin = rng.randf_range(0.0, TAU), glow = is_glow, wood = wood_for(s)})
	return trees


## The grove's floor (tools/asset_forge/builds/grove_dressing.py): a few big rocks, pebbles, grass, ferns, clover,
## flowers and mushrooms, and shelf fungus on the dark trees' trunks. [{pos, model, scale, spin, solid}]
static func _dress(maker: CaveMaker, room: Dictionary, rng: RandomNumberGenerator, trees: Array, avoid: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var c: Vector3 = room.center
	var r: Vector3 = room.radii
	var wants := [[ROCKS, rng.randi_range(4, 7), 1.6, true], [PEBBLES, rng.randi_range(18, 30), 0.3, false],
		[PLANTS, rng.randi_range(28, 44), 0.5, false], [CAPS, rng.randi_range(3, 6), 0.4, false]]
	for w in wants:
		var list: Array = w[0]
		var placed := 0
		for attempt in int(w[1]) * 6:
			if placed >= int(w[1]):
				break
			var a := rng.randf_range(0.0, TAU)
			var d := sqrt(rng.randf()) * 0.8
			var at := Vector3(c.x + cos(a) * r.x * d, c.y, c.z + sin(a) * r.z * d)
			if maker.sdf_at(at) <= 0.5:
				continue
			var floor_at := GlowPlacer._march(maker, at, Vector3.DOWN, 30.0)
			if floor_at == Vector3.INF:
				continue
			var foot: float = w[2]
			if not _clear(maker, floor_at, foot, [], [], avoid):
				continue
			var hit_tree := false
			for t in trees:
				if Vector2(t.pos.x - floor_at.x, t.pos.z - floor_at.z).length() < foot + 0.9 + float(t.scale):
					hit_tree = true
			if hit_tree:
				continue
			var s := rng.randf_range(0.8, 1.2) if w[3] else rng.randf_range(0.7, 1.3)
			out.append({pos = floor_at - Vector3.UP * (0.08 if w[3] else 0.02), model = list[rng.randi_range(0, list.size() - 1)],
				scale = s, spin = rng.randf_range(0.0, TAU), solid = w[3]})
			placed += 1
	for t in trees:  # shelf fungus on some dark trunks, facing out
		if t.glow or float(t.scale) < 0.5 or rng.randf() > 0.55:
			continue
		for k in rng.randi_range(1, 2):
			var a := rng.randf_range(0.0, TAU)
			var h := rng.randf_range(0.9, 2.4) * float(t.scale)
			var off := Vector3(cos(a), 0, sin(a)) * TRUNK_R * float(t.scale) * 0.9
			out.append({pos = (t.pos as Vector3) + off + Vector3.UP * h, model = "gfungus_shelf",
				scale = rng.randf_range(0.35, 0.55), spin = -a + PI * 0.5, solid = false, on = t})
	return out


## The placement rule: not on kept-clear ground, a bridge, a stone column, a place, a path, a Root Tree or another tree.
static func _clear(maker: CaveMaker, at: Vector3, foot: float, mine: Array, others: Array, avoid: Callable) -> bool:
	if maker.is_reserved(at, foot + 2.0) or maker._in_column(at, foot + 2.0) or maker.on_bridge(at, foot + 1.0):
		return false
	if avoid.is_valid() and avoid.call(at, foot + 3.0):
		return false
	for q in maker.pois:
		if Vector2(q.pos.x - at.x, q.pos.z - at.z).length() < foot + 4.0:
			return false
	for t in mine + others:
		if Vector2(t.pos.x - at.x, t.pos.z - at.z).length() < foot + 2.4:
			return false
	for sg: Dictionary in maker.segments:
		if sg.get("ramp", false) or sg.get("ledge", false):
			var cp := Geometry3D.get_closest_point_to_segment(at, sg.a, sg.b)
			if Vector2(cp.x - at.x, cp.z - at.z).length() < foot + float(sg.r) + 1.0:
				return false
	return true


## True if a grove tree stands within r (m, flat distance) of p: other things that grow keep clear of them.
func near(p: Vector3, r: float) -> bool:
	for t in _trees:
		if Vector2(t.pos.x - p.x, t.pos.z - p.z).length() < r:
			return true
	return false


func _add_tree(gi: int, colour: Color, t: Dictionary) -> void:
	var scene: PackedScene = load("res://assets/models/cave/%s.glb" % t.model)
	if scene == null:
		return
	var m := scene.instantiate() as Node3D
	add_child(m)
	m.global_position = t.pos
	m.rotation.y = t.spin
	m.scale = Vector3.ONE * float(t.scale)
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = SEEN_TO
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # the lantern's shadows only (F238)
		for si in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(si) as StandardMaterial3D
			if mat and (mat.resource_name.begins_with("glow_leaves") or mat.resource_name.begins_with("bark_crack")):
				mi.set_surface_override_material(si, _tinted(gi, mat, colour))
	var body := StaticBody3D.new()  # you bump into the trunk, and chop it
	body.set_meta("grove_tree", int(t.id))
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = TRUNK_R * float(t.scale)
	cyl.height = 4.0 * float(t.scale)
	shape.shape = cyl
	shape.position.y = cyl.height * 0.5
	body.add_child(shape)
	add_child(body)
	body.global_position = t.pos
	_nodes[int(t.id)] = [m, body]


## The grove tree a swing hit (-1 = none).
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("grove_tree"):
		return int((collider as Node).get_meta("grove_tree"))
	return -1


## Tree `id`'s plan ({} = no such tree).
func tree(id: int) -> Dictionary:
	return _by_id.get(id, {})


## From the host: tree `id` has given `used` wood. All of it: the tree comes down (a burst of wood chips).
func set_used(id: int, used: int, burst := true) -> void:
	var t := tree(id)
	if t.is_empty() or not _nodes.has(id):
		return
	var down := used >= int(t.wood)
	if down and burst and (_nodes[id][0] as Node3D).visible:
		Fx.burst(self, (t.pos as Vector3) + Vector3.UP * 1.2 * float(t.scale), Color(0.45, 0.32, 0.2), 24, 4.0)
	_show(id, not down)


## From the host: felled tree `id` stands again (left <= 0).
func set_regrow(id: int, left: float) -> void:
	if left <= 0.0 and _nodes.has(id):
		_show(id, true)


func _show(id: int, on: bool) -> void:
	var n: Array = _nodes[id]
	for k in n.size():
		if k == 1:
			(n[1] as StaticBody3D).collision_layer = World.TERRAIN_LAYER if on else 0
		else:
			(n[k] as Node3D).visible = on


func _add_dressing(d: Dictionary) -> Node3D:
	var scene: PackedScene = load("res://assets/models/cave/%s.glb" % d.model)
	if scene == null:
		return null
	var m := scene.instantiate() as Node3D
	add_child(m)
	m.global_position = d.pos
	m.rotation.y = d.spin
	m.scale = Vector3.ONE * float(d.scale)
	var box := AABB()
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = SEEN_TO * (1.0 if d.solid else 0.45)  # small things fade out sooner
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		box = mi.get_aabb() if box.size == Vector3.ZERO else box.merge(mi.get_aabb())
	if d.solid and box.size != Vector3.ZERO:  # big rocks: you bump into them
		var body := StaticBody3D.new()
		body.collision_layer = World.TERRAIN_LAYER
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = box.size * 0.8  # (the body sits inside the scaled model, so it scales with it)
		shape.shape = b
		shape.position = box.get_center()
		body.add_child(shape)
		m.add_child(body)
	return m


func _tinted(gi: int, mat: StandardMaterial3D, colour: Color) -> StandardMaterial3D:
	var key := [gi, mat]
	if not _mats.has(key):
		var m := mat.duplicate() as StandardMaterial3D
		m.albedo_color = colour
		m.emission = colour
		_mats[key] = m
	return _mats[key]


## A few soft lights among the glowing trees: in a grove they are the cavern's main light (no shadows: cheap).
func _add_lights(g: Dictionary) -> void:
	var glowing: Array = g.trees.filter(func(t): return t.glow)
	for i in range(0, glowing.size(), 3):  # one light for about every three glowing trees
		var t: Dictionary = glowing[i]
		var l := OmniLight3D.new()
		l.light_color = g.colour
		l.light_energy = 1.4
		l.omni_range = 14.0
		l.omni_attenuation = 1.3
		l.shadow_enabled = false
		l.distance_fade_enabled = true
		l.distance_fade_begin = 70.0
		l.distance_fade_length = 20.0
		add_child(l)
		l.global_position = (t.pos as Vector3) + Vector3.UP * maxf(4.5 * float(t.scale), 1.5)
		if _nodes.has(int(t.id)):
			(_nodes[int(t.id)] as Array).append(l)  # a felled tree's light goes out with it
