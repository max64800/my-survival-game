class_name Clutter
extends Node3D
## Small loose things on cave floors, only for looks: pebbles, chunky rocks, old bones,
## twigs (Mossy Hollows) and fungus nubs (Fungal Jungle). You can't pick them up.
## And dripstone on the ceilings (F232, owner Nov 17): hand-built models (tools/asset_forge/builds/cave_dripstone.py:
## a stalactite cluster, a big ringed one with a drop, a stubby cluster), each on a chunk of rock tucked into the
## ceiling, in different sizes and slightly different colours, a main one with a smaller one or two beside it.
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
	"twig": {color = Color(0.35, 0.24, 0.15), surface = "bark", size = [0.3, 0.55], biome = "mossy", weight = 0},  # (real, pickable twigs: GlowPlacer)
	"nub": {color = Color(0.62, 0.48, 0.66), surface = "fungus", size = [0.08, 0.2], biome = "fungal", weight = 3},
	# Ceilings (weight 0 = never picked for floors; placed by _ceiling instead).
	"stal_mossy": {color = Color(0.5, 0.46, 0.41), surface = "stone", size = [0, 0], biome = "mossy", weight = 0},
	"stal_fungal": {color = Color(0.4, 0.33, 0.46), surface = "stone", size = [0, 0], biome = "fungal", weight = 0},
}
const CLUSTERS_BIG_ROOM := 30
const CLUSTERS_ROOM := 7
## Rock shelves on walls (F232, tools/asset_forge/builds/cave_shelves.py): rock only; the game puts its own moss,
## mushrooms and recoloured crystals on top (owner: "use our existing mushrooms... crystals, a different colour").
## SHELF_TOPS: where things sit on each model (its own space: +Z = out of the wall, +Y = up), and what.
const SHELVES := {
	"shelf_a": {model = "res://assets/models/cave/shelf_a.glb", size = [0.8, 2.2]},
	"shelf_b": {model = "res://assets/models/cave/shelf_b.glb", size = [0.8, 2.0]},
	"shelf_c": {model = "res://assets/models/cave/shelf_c.glb", size = [0.8, 1.8]},
	"shelf_d": {model = "res://assets/models/cave/shelf_d.glb", size = [0.8, 1.8]},
}
const SHELF_TOPS := {
	"shelf_b": [[Vector3(-0.08, 0.0, 0.16), "moss", 0.55], [Vector3(0.16, 0.0, 0.12), "moss", 0.4], [Vector3(0.02, -0.02, 0.36), "moss_drape", 0.5]],
	"shelf_c": [[Vector3(-0.1, 0.24, 0.12), "cap", 0.32], [Vector3(0.15, -0.22, 0.18), "cap", 0.4]],
	"shelf_d": [[Vector3(0.0, 0.0, 0.14), "crystal", 0.32]],
}
const SHELF_CRYSTALS := [Color(0.72, 0.42, 1.0), Color(1.0, 0.68, 0.3), Color(1.0, 0.45, 0.6)]  # not the cave's blue
const WALL_SHELVES_BIG_ROOM := 14
const WALL_SHELVES_ROOM := 4
## Roots hanging from ceilings (F232, tools/asset_forge/builds/cave_hanging.py; no rock chunk, they come out of the real
## ceiling). Owner: "I really like 3... make them very big and random... 1 is good too".
const HROOTS := {
	"hroot_a": {model = "res://assets/models/cave/hroot_a.glb", length = 1.25, size = [1.5, 4.0]},
	"hroot_c": {model = "res://assets/models/cave/hroot_c.glb", length = 1.2, size = [1.5, 4.0]},
}
const HROOTS_BIG_ROOM := 12
const HROOTS_ROOM := 3
## Dripstone models: how far each hangs at size 1 (m), and its size range (owner: "different sizes").
const DRIPS := {
	"drip_a": {model = "res://assets/models/cave/drip_a.glb", length = 0.95, size = [0.8, 2.0]},
	"drip_b": {model = "res://assets/models/cave/drip_b.glb", length = 1.15, size = [0.8, 1.9]},
	"drip_d": {model = "res://assets/models/cave/drip_d.glb", length = 0.45, size = [0.9, 2.4]},
}

var _sets := {}   ## kind -> MultiMeshInstance3D
var _where := {}  ## kind -> PackedVector3Array (positions, for hiding near digs)
var _drips := {}  ## dripstone kind -> Array of [Transform3D, tint]
var _drip_cells := {}  ## dripstone kind -> Array of MultiMeshInstance3D (one per 32 m square)


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
	for k in DRIPS:
		_drips[k] = []
	for room in maker.rooms:
		for i in (CLUSTERS_BIG_ROOM if room.big else CLUSTERS_ROOM):
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.5, 1.0), rng.randf_range(-1, 1)).normalized()
			_ceiling(maker, rng, picks, room.center, dir)
	for k in KINDS:
		_make_set(k, picks[k])
	for k in DRIPS:
		_make_drip_set(k, _drips[k])
	_place_hanging_roots(maker, rng)
	# _place_shelves(maker, rng)  # off (owner, Nov 17: "really bad... doesn't blend with walls"); ledges in the rock instead?
	world.changed.connect(_on_rock_changed)


## A cluster of stalactites where a ray from `start` hits the ceiling: one big one, a few small
## ones around it. Never so long that a dwarf would bump their head walking under it.
func _ceiling(maker: CaveMaker, rng: RandomNumberGenerator, picks: Dictionary, start: Vector3, dir: Vector3) -> void:
	if maker.sdf_at(start) <= 0.0:
		return
	var hit := GlowPlacer._march(maker, start, dir, 60.0)
	if hit == Vector3.INF or GlowPlacer.normal_at(maker, hit).y > -0.6:
		return  # not a ceiling
	var fungal := CaveMaker.biome_at(hit) == "fungal"
	var names := DRIPS.keys()
	var count := rng.randi_range(1, 3)  # a main one, maybe a smaller one or two beside it
	for j in count:
		var at := hit
		if j > 0:
			var off := Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
			at = GlowPlacer._march(maker, hit + off + Vector3.DOWN * 0.4, Vector3.UP, 3.0)
			if at == Vector3.INF:
				continue
		var kind: String = names[rng.randi_range(0, names.size() - 1)]
		var d: Dictionary = DRIPS[kind]
		var size := rng.randf_range(d.size[0], d.size[1]) * (1.0 if j == 0 else 0.6)
		var spin := rng.randf() * TAU
		# slightly different colours (owner): a little warmer, cooler, lighter or darker; the jungle's are purplish
		var tint := Color.from_hsv(rng.randf_range(0.04, 0.12), rng.randf_range(0.0, 0.14), rng.randf_range(0.85, 1.08))
		if fungal:
			tint *= Color(0.84, 0.74, 0.94)
		var n := GlowPlacer.normal_at(maker, at)
		if n.y > -0.5:
			continue  # not under a ceiling here
		var floor_hit := GlowPlacer._march(maker, at + Vector3.DOWN * 0.3, Vector3.DOWN, 40.0)
		var gap := at.distance_to(floor_hit) if floor_hit != Vector3.INF else 40.0
		size = minf(size, (gap - 2.0) / float(d.length))  # keep 2 m clear below: nobody bumps their head
		if size < 0.5:
			continue
		# The model grows along its +Y away from its rock: hang it upside down, the rock pushed up into the ceiling.
		var basis := Basis(Vector3.RIGHT, PI) * Basis(Vector3.UP, spin)
		_drips[kind].append([Transform3D(basis.scaled(Vector3.ONE * size), at + Vector3.UP * 0.07 * size), tint])


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
	if kind in ["pebble", "rock", "nub"]:
		size *= GlowPlacer.size_boost(hit)  # sometimes bigger, never smaller (owner F218)
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


## One batch per kind per 32 m square (owner, Nov 17: "yes", fix it): a single batch for the whole zone had its 45 m
## draw distance measured from the zone's middle, so the pebbles, rocks, bones and twigs were never drawn.
func _make_set(kind: String, xforms: Array) -> void:
	if xforms.is_empty():
		return
	var cells := {}
	for xf: Transform3D in xforms:
		var c := Vector3i((xf.origin / DRIP_CELL).floor())
		if not cells.has(c):
			cells[c] = []
		cells[c].append(xf)
	var k: Dictionary = KINDS[kind]
	var mat := Look.mat(k.color, k.surface, 0.0, 0.0)
	var mesh := _mesh(kind)
	for c in cells:
		var group: Array = cells[c]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = group.size()
		var where := PackedVector3Array()
		for i in group.size():
			mm.set_instance_transform(i, group[i])
			where.append((group[i] as Transform3D).origin)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.visibility_range_end = 45.0  # far-away pebbles aren't worth drawing
		mmi.visibility_range_end_margin = 5.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if kind == "pebble":
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		var key := "%s@%s" % [kind, c]  # (_on_rock_changed walks every batch the same way)
		_sets[key] = mmi
		_where[key] = where


## Big roots hanging from room ceilings, very different sizes, a slight tint each; 2 m kept clear above the floor.
func _place_hanging_roots(maker: CaveMaker, rng: RandomNumberGenerator) -> void:
	var items := {}
	for k in HROOTS:
		items[k] = []
	var names := HROOTS.keys()
	for room in maker.rooms:
		if room.get("sealed", false) or maker.sdf_at(room.center) <= 0.0:
			continue
		for i in (HROOTS_BIG_ROOM if room.big else HROOTS_ROOM):
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.5, 1.0), rng.randf_range(-1, 1)).normalized()
			var kind: String = names[rng.randi_range(0, names.size() - 1)]
			var d: Dictionary = HROOTS[kind]
			var size := rng.randf_range(d.size[0], d.size[1])
			var spin := rng.randf() * TAU
			var tint := Color.from_hsv(rng.randf_range(0.05, 0.1), rng.randf_range(0.0, 0.15), rng.randf_range(0.82, 1.06))
			var hit := GlowPlacer._march(maker, room.center, dir, 60.0)
			if hit == Vector3.INF or GlowPlacer.normal_at(maker, hit).y > -0.5:
				continue  # not a ceiling
			var floor_hit := GlowPlacer._march(maker, hit + Vector3.DOWN * 0.3, Vector3.DOWN, 40.0)
			var gap := hit.distance_to(floor_hit) if floor_hit != Vector3.INF else 40.0
			size = minf(size, (gap - 2.0) / float(d.length))  # nobody bumps their head
			if size < 0.8:
				continue
			var basis := Basis(Vector3.RIGHT, PI) * Basis(Vector3.UP, spin)  # grows along +Y: hang it upside down
			items[kind].append([Transform3D(basis.scaled(Vector3.ONE * size), hit + Vector3.UP * 0.04 * size), tint])
	for k in HROOTS:
		_make_model_cells(k, _model_mesh(HROOTS[k].model), items[k])


## Rock shelves on room walls, 0.8-6 m above the floor, different sizes and tints, with their moss, mushrooms and
## crystals. (After everything else, with the same dice, so nothing above moves.)
func _place_shelves(maker: CaveMaker, rng: RandomNumberGenerator) -> void:
	var items := {}
	for k in SHELVES:
		items[k] = []
	var extras := {"moss": [], "moss_drape": [], "cap": [], "crystal0": [], "crystal1": [], "crystal2": []}
	var names := SHELVES.keys()
	for room in maker.rooms:
		if room.get("sealed", false):
			continue
		for i in (WALL_SHELVES_BIG_ROOM if room.big else WALL_SHELVES_ROOM):
			var ang := rng.randf() * TAU
			var dir := Vector3(cos(ang), rng.randf_range(-0.25, 0.25), sin(ang)).normalized()
			var kind: String = names[rng.randi_range(0, names.size() - 1)]
			var size := rng.randf_range(SHELVES[kind].size[0], SHELVES[kind].size[1])
			var tint := Color.from_hsv(rng.randf_range(0.04, 0.1), rng.randf_range(0.0, 0.12), rng.randf_range(0.85, 1.08))
			var roll := rng.randi()
			if maker.sdf_at(room.center) <= 0.0:
				continue
			var hit := GlowPlacer._march(maker, room.center, dir, 60.0)
			if hit == Vector3.INF:
				continue
			var n := GlowPlacer.normal_at(maker, hit)
			if absf(n.y) > 0.3:
				continue  # walls only
			var fl := GlowPlacer._march(maker, hit + Vector3(n.x, 0, n.z).normalized() * 0.8, Vector3.DOWN, 10.0)
			if fl == Vector3.INF or hit.y - fl.y < 0.8 or hit.y - fl.y > 6.0:
				continue
			if CaveMaker.biome_at(hit) == "fungal":
				tint *= Color(0.84, 0.74, 0.94)
			var out := Vector3(n.x, 0, n.z).normalized()
			var basis := Basis(Vector3.UP.cross(out), Vector3.UP, out)
			var xf := Transform3D(basis.scaled(Vector3.ONE * size), hit - out * 0.05 * size)  # the wall slice pushed into the rock
			items[kind].append([xf, tint])
			for top in SHELF_TOPS.get(kind, []):
				var at: Vector3 = xf * (top[0] as Vector3)
				var s: float = top[2] * size
				match top[1]:
					"moss", "moss_drape":
						var b := Basis(Vector3.UP, roll * 0.001) if top[1] == "moss" else Basis.looking_at(out, Vector3.UP)
						extras[top[1]].append([Transform3D(b.scaled(Vector3.ONE * s), at), CaveLife._tint("moss", roll, CaveMaker.biome_at(at), 0.8),
							Color(CaveLife._fuzz("moss", "damp", 0.8), 0.8, 0, 0)])
					"cap":
						extras.cap.append([Transform3D(Basis(Vector3.UP, roll * 0.002).scaled(Vector3.ONE * s), at), Color(0.92, 0.86, 0.74)])
					"crystal":
						extras["crystal%d" % (roll % SHELF_CRYSTALS.size())].append([Transform3D(Basis(Vector3.UP, roll * 0.003).scaled(Vector3.ONE * s), at), Color.WHITE])
	for k in SHELVES:
		_make_model_cells(k, _model_mesh(SHELVES[k].model), items[k])
	_make_model_cells("moss", CaveLife.mesh_of("moss"), extras.moss, true)
	_make_model_cells("moss_drape", CaveLife.mesh_of("moss_drape"), extras.moss_drape, true)
	_make_model_cells("cap", _model_mesh("res://assets/models/cave/glowcap.glb"), extras.cap)
	for c in SHELF_CRYSTALS.size():
		_make_model_cells("crystal%d" % c, _model_mesh("res://assets/models/cave/crystal.glb", SHELF_CRYSTALS[c]), extras["crystal%d" % c])


## Any model, in 32 m squares: items are [Transform3D, colour] (or [Transform3D, colour, custom data]).
func _make_model_cells(key: String, mesh: Mesh, items: Array, custom := false) -> void:
	if items.is_empty() or mesh == null:
		return
	var cells := {}
	for it in items:
		var c := Vector3i(((it[0] as Transform3D).origin / DRIP_CELL).floor())
		if not cells.has(c):
			cells[c] = []
		cells[c].append(it)
	var holders: Array[MultiMeshInstance3D] = []
	for c in cells:
		var group: Array = cells[c]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = custom
		mm.mesh = mesh
		mm.instance_count = group.size()
		for i in group.size():
			mm.set_instance_transform(i, group[i][0])
			mm.set_instance_color(i, group[i][1])
			if custom:
				mm.set_instance_custom_data(i, group[i][2])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = 55.0
		mmi.visibility_range_end_margin = 6.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(mmi)
		holders.append(mmi)
	_drip_cells[key] = holders


## Dripstone, in 32 m squares per model: each square is its own batch with its own draw distance (one batch for the
## whole zone would be measured from the zone's middle, so it was never drawn, and drawing all of it would be heavy).
const DRIP_CELL := 32.0

func _make_drip_set(kind: String, items: Array) -> void:
	if items.is_empty():
		return
	var cells := {}
	for it in items:
		var o: Vector3 = (it[0] as Transform3D).origin
		var c := Vector3i((o / DRIP_CELL).floor())
		if not cells.has(c):
			cells[c] = []
		cells[c].append(it)
	var where := PackedVector3Array()
	var holders: Array[MultiMeshInstance3D] = []
	for c in cells:
		var group: Array = cells[c]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _model_mesh(DRIPS[kind].model)
		mm.instance_count = group.size()
		for i in group.size():
			mm.set_instance_transform(i, group[i][0])
			mm.set_instance_color(i, group[i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = 60.0
		mmi.visibility_range_end_margin = 6.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(mmi)
		holders.append(mmi)
	_drip_cells[kind] = holders


static var _models := {}  ## path -> ArrayMesh (all the model's parts, their paint tinted by each copy's colour)


static func _model_mesh(path: String, glow := Color(0, 0, 0, 0)) -> Mesh:
	var key := "%s/%s" % [path, glow.to_html()]
	if _models.has(key):
		return _models[key]
	var mesh := ArrayMesh.new()
	var ps := load(path) as PackedScene
	if ps:
		var inst := ps.instantiate()
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			var xf := Transform3D()
			var node: Node = mi
			while node != inst:
				xf = (node as Node3D).transform * xf
				node = node.get_parent()
			for sidx in mi.mesh.get_surface_count():
				var st := SurfaceTool.new()
				st.create_from(mi.mesh, sidx)
				var arrays := st.commit_to_arrays()
				var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				for v in verts.size():
					verts[v] = xf * verts[v]
				arrays[Mesh.ARRAY_VERTEX] = verts
				var nrm = arrays[Mesh.ARRAY_NORMAL]
				if nrm is PackedVector3Array:
					for v in nrm.size():
						nrm[v] = (xf.basis * nrm[v]).normalized()
					arrays[Mesh.ARRAY_NORMAL] = nrm
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				var m := mi.mesh.surface_get_material(sidx)
				if m is StandardMaterial3D:
					m = m.duplicate()
					var sm := m as StandardMaterial3D
					sm.vertex_color_use_as_albedo = true  # each copy's tint (MultiMesh colour)
					if glow.a > 0.0 and sm.resource_name.begins_with("glow_"):  # a crystal of another colour, glowing
						sm.albedo_color = Color.from_hsv(glow.h, minf(1.0, glow.s * 1.2), glow.v * 0.75)
						sm.emission_enabled = true
						sm.emission = glow
						sm.emission_texture = sm.albedo_texture
						sm.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
						sm.emission_energy_multiplier = 0.9
				mesh.surface_set_material(mesh.get_surface_count() - 1, m)
		inst.free()
	_models[key] = mesh
	return mesh


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
	var rd := (radius + 1.2) * (radius + 1.2)  # dripstone hangs from a wider chunk of rock
	for kind in _drip_cells:
		for mmi: MultiMeshInstance3D in _drip_cells[kind]:
			var mm := mmi.multimesh
			for i in mm.instance_count:
				var o := mm.get_instance_transform(i).origin
				if o.distance_squared_to(center) < rd:
					mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), o))
	for kind in _sets:
		var where: PackedVector3Array = _where[kind]
		var mm: MultiMesh = (_sets[kind] as MultiMeshInstance3D).multimesh
		for i in where.size():
			if where[i].distance_squared_to(center) < r2:
				mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), where[i]))
				where[i] = Vector3.INF
		_where[kind] = where
