class_name GlowField
extends Node3D
## Shows the glowing crystals and mushrooms that the Glow Placer picked.
## Real lights are expensive, so only the LIGHT_COUNT spots nearest the player get
## a real light; all the others just glow (shiny material + bloom).

const GLOW_LAYER := 2
## The hand-built plants and crystals are drawn on their own layer, which the glow lights skip: a glow light sits 0.6 m
## above its spot, inside a big crystal or under a mushroom cap, and lit them blinding white from close up (Nov 16).
## They shine by themselves (emission); the lantern and everything else still light them.
const PLANT_LAYER := 1 << 10
const LIGHT_COUNT := 12
const LIGHT_UPDATE := 0.3

var _spots: Dictionary = {}  ## id -> spot data
## Speed: which spots are in which 4 m square, so "what's near here?" only checks a few squares
## instead of every spot in the world (that took ~8 ms per dig, a visible stutter).
const CELL := 4.0
var _grid := {}  ## Vector3i -> Array of spot ids
var _nodes: Dictionary = {}  ## id -> StaticBody3D
var _lights: Array[OmniLight3D] = []
var _light_spot: Array[int] = []  ## which spot each light is on (-1 = none)
var _light_target: Array[float] = []  ## how bright each light is fading toward
const ROOT_WIDTH := 1.6  ## roots look thicker than before (owner F135: they were hard to aim at)
const FADE_SPEED := 1.2  ## light energy per second
const LIGHT_REACH := 40.0
var _light_timer := 0.0
var _crystal_mesh: Mesh
var _mushroom_mesh: Mesh
var _fiber_mesh: Mesh
var _twig_mesh: Mesh
var _root_mesh: Mesh
var _materials := {}
var rock: CaveLife.Rock  ## the rock as it is drawn (main sets it): crystals sit on it, base showing (F195)


func build(spots: Array[Dictionary]) -> void:
	_crystal_mesh = _make_crystal_mesh()
	_mushroom_mesh = _make_mushroom_mesh()
	_fiber_mesh = _make_fiber_mesh()
	_twig_mesh = _make_twig_mesh()
	_root_mesh = _make_root_mesh()
	for s in spots:
		_spots[s.id] = s
		_grid_add(s)
		_add_node(s)
	for i in LIGHT_COUNT:
		var l := OmniLight3D.new()
		l.shadow_enabled = false
		l.omni_range = 6.0
		l.light_energy = 0.0
		l.light_cull_mask = ~PLANT_LAYER  # lights the cave round a glowing spot, not the plants themselves (see PLANT_LAYER)
		add_child(l)
		_lights.append(l)
		_light_spot.append(-1)
		_light_target.append(0.0)


func get_spot(id: int) -> Dictionary:
	return _spots.get(id, {})


func spot_count() -> int:
	return _spots.size()


func spots_near(p: Vector3, radius: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var lo := _cell(p - Vector3.ONE * radius)
	var hi := _cell(p + Vector3.ONE * radius)
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				for id in _grid.get(Vector3i(x, y, z), []):
					var s: Dictionary = _spots[id]
					if s.pos.distance_to(p) <= radius:
						out.append(s)
	return out


static func _cell(p: Vector3) -> Vector3i:
	return Vector3i((p / CELL).floor())


func _grid_add(s: Dictionary) -> void:
	var c := _cell(s.pos)
	if not _grid.has(c):
		_grid[c] = []
	_grid[c].append(s.id)


## A root was chopped: remember how many chops it has left.
func set_chops(id: int, left: int) -> void:
	if _spots.has(id):
		_spots[id].chops = left
		var n: Node3D = _nodes.get(id)
		if n:
			n.scale = n.scale * Vector3(0.85, 1.0, 0.85)  # a bit thinner after each chop


## Roots grow back (F106): a removed spot is remembered so it can return.
var _gone := {}


## A root grows back where it was: fresh (all its chops), starting small and growing to full size.
func restore_spot(id: int) -> void:
	if _spots.has(id) or not _gone.has(id):
		return
	var s: Dictionary = _gone[id]
	_gone.erase(id)
	s.chops = GlowPlacer.KINDS[s.kind].get("chops", 1)
	_spots[id] = s
	_grid_add(s)
	_add_node(s)
	var n: Node3D = _nodes.get(id)
	if n and n.is_inside_tree():
		var full := n.scale
		n.scale = full * 0.15
		n.create_tween().tween_property(n, "scale", full, 4.0)
	_light_timer = 0.0


func remove_spot(id: int) -> void:
	if _spots.has(id):
		_gone[id] = (_spots[id] as Dictionary).duplicate()
		var c := _cell(_spots[id].pos)
		if _grid.has(c):
			_grid[c].erase(id)
	_spots.erase(id)
	var n: Node = _nodes.get(id)
	_nodes.erase(id)
	if n:
		n.queue_free()
	_light_timer = 0.0


## Glow-spot id for a physics collider, or -1.
func id_of(collider: Object) -> int:
	if collider is Node and collider.has_meta("glow_id"):
		return collider.get_meta("glow_id")
	return -1


func _add_node(s: Dictionary) -> void:
	if s.kind == GlowPlacer.DRIP:
		_add_drip(s)
		return
	var body := StaticBody3D.new()
	body.collision_layer = GLOW_LAYER
	body.collision_mask = 0
	body.set_meta("glow_id", s.id)
	var shape := CollisionShape3D.new()
	var is_root: bool = s.kind in GlowPlacer.TALL
	if is_root:
		var cap := CapsuleShape3D.new()
		cap.radius = 0.75 if s.kind == GlowPlacer.ROOT or s.kind == GlowPlacer.ROOT_DANGLE else 0.45  # easy to aim at (F135)
		cap.height = maxf(s.length, 0.8)
		shape.shape = cap
		shape.position = Vector3.UP * s.length * 0.5
	else:
		var sphere := SphereShape3D.new()
		sphere.radius = 0.4 * s.scale
		shape.shape = sphere
		shape.position = Vector3.UP * 0.3 * s.scale
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var glows: bool = GlowPlacer.KINDS[s.kind].get("glow", false)
	var model := _model_of(s.kind)
	if model == "root":  # each root spot gets one of the three looks, the same for everyone (from its id)
		model = ROOT_LOOKS[posmod(int(s.id) * 7 + 3, ROOT_LOOKS.size())]
	if model != "" and _cave_mesh(model) != null:
		# Hand-built, sculpted and painted models (owner, Nov 16; tools/asset_forge/builds/cave_plants.py).
		mi.mesh = _cave_mesh(model)
		_tint_glow_parts(mi, model, s.color, glows)
		match model:
			"root", "root_b", "root_c": mi.scale = Vector3.ONE * s.length / s.scale  # length = its size (about its height in metres)
			"giant": mi.scale = Vector3.ONE * s.length / 4.0  # the model is 4 m tall
	else:
		match s.kind:
			"crystal", "crystal_green", "crystal_amber": mi.mesh = _crystal_mesh
			"fiber": mi.mesh = _fiber_mesh
			"twig": mi.mesh = _twig_mesh
			"root", "root_dangle":
				mi.mesh = _root_mesh
				mi.scale = Vector3(ROOT_WIDTH, s.length, ROOT_WIDTH) / s.scale
			GlowPlacer.GIANT: mi.mesh = _giant_mesh(s.length)
			_: mi.mesh = _mushroom_mesh
		mi.material_override = _material_for(s.color, glows, _surface_of(s.kind))
		if s.kind == GlowPlacer.GIANT:
			mi.material_override = null  # the giant mushroom mesh brings its own stalk + cap colors
	# far away they're not drawn (the cave fog hides them anyway): many detailed plants stay cheap
	if model != "":
		mi.layers = PLANT_LAYER
	mi.visibility_range_end = 70.0
	mi.visibility_range_end_margin = 8.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)
	_add_solid(body, mi, model, s)
	add_child(body)
	var up: Vector3 = s.normal
	var at: Vector3 = s.pos - up * 0.1
	if rock and String(s.kind).begins_with("crystal"):
		# The spot was found on the cave's exact shape; the drawn rock can be several cm off and tilted, so the
		# crystal's rock base floated or sank out of sight (owner F195). Sit it on the drawn rock, tilted to match,
		# sunk a fixed bit so the base always shows.
		var hit := rock.march(s.pos + up * 0.8, -up, 1.6)
		if hit != Vector3.INF:
			up = rock.normal(hit)
			at = hit - up * 0.035 * s.scale
	var side := up.cross(Vector3.FORWARD if absf(up.y) > 0.9 else Vector3.UP).normalized()
	var basis := Basis(side, up, side.cross(up)).orthonormalized()
	body.global_transform = Transform3D(basis.rotated(up, s.spin).scaled(Vector3.ONE * s.scale), at)
	_nodes[s.id] = body


var _solid_shapes := {}  ## model -> Shape3D (shared by every spot with that model)


## Crystals, big roots and giant mushrooms are solid: dwarfs and creatures bump into them (owner F220: "I can walk
## through crystals and roots"). The aim body above is fatter on purpose (easy to hit, F135) and only on the aim layer,
## so this is a second body shaped like the model itself, on the rock layer. It carries the same glow id, so a swing
## that hits it still counts as hitting the crystal or root. Little mushrooms, fiber and hanging roots stay soft.
func _add_solid(body: StaticBody3D, mi: MeshInstance3D, model: String, s: Dictionary) -> void:
	if not model in ["crystal", "root", "root_b", "root_c", "giant"] or s.kind == GlowPlacer.ROOT_DANGLE:
		return
	var mesh := mi.mesh as ArrayMesh
	if mesh == null:
		return
	if not _solid_shapes.has(model):
		# A crystal is a lump: its outline is enough. Roots arch and giants have a cap to stand under: the exact shape.
		_solid_shapes[model] = mesh.create_convex_shape(true, true) if model == "crystal" else mesh.create_trimesh_shape()
	var solid := StaticBody3D.new()
	solid.collision_layer = World.TERRAIN_LAYER
	solid.collision_mask = 0
	solid.set_meta("glow_id", s.id)
	solid.transform = mi.transform  # roots and giants are scaled to their length
	var shape := CollisionShape3D.new()
	shape.shape = _solid_shapes[model]
	solid.add_child(shape)
	body.add_child(solid)


## Which hand-built model each kind uses ("" = the simple shapes made here).
const CAVE_MODELS := {
	"root": "res://assets/models/cave/root.glb",  # three looks (owner, Nov 16): arch, stump, tangle
	"root_b": "res://assets/models/cave/root_b.glb",
	"root_c": "res://assets/models/cave/root_c.glb",
	"glowcap": "res://assets/models/cave/glowcap.glb",
	"crystal": "res://assets/models/cave/crystal.glb",
	"giant": "res://assets/models/cave/giant.glb",
	"drip": "res://assets/models/cave/drip_b.glb",  # the dripping stalactite: the ringed dripstone (owner, Nov 17)
}
const CRYSTAL_SHADER := preload("res://src/art/crystal.gdshader")
const ROOT_LOOKS := ["root", "root_b", "root_c"]
var _cave_meshes := {}  ## model -> ArrayMesh (null if it failed to load)
var _glow_mats := {}  ## tinted copies of the glowing parts' materials


func _model_of(kind: String) -> String:
	if kind.begins_with("crystal"):
		return "crystal"
	if kind == GlowPlacer.ROOT or kind == GlowPlacer.ROOT_DANGLE:
		return "root"
	if kind == GlowPlacer.GIANT:
		return "giant"
	if kind == "fiber" or kind == "twig" or kind == GlowPlacer.DRIP:
		return ""
	return "glowcap"  # every small mushroom kind: the same cluster, its caps tinted


## One mesh with all the model's parts (each part keeps its own painted material), loaded once.
func _cave_mesh(model: String) -> ArrayMesh:
	if _cave_meshes.has(model):
		return _cave_meshes[model]
	var mesh: ArrayMesh = null
	var ps := load(CAVE_MODELS[model]) as PackedScene
	if ps:
		var inst := ps.instantiate()
		mesh = ArrayMesh.new()
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var xf := Transform3D()
			var n: Node = mi
			while n != inst:
				xf = (n as Node3D).transform * xf
				n = n.get_parent()
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var st := SurfaceTool.new()
				st.append_from(mi.mesh, i, xf)
				st.commit(mesh)
				mesh.surface_set_material(mesh.get_surface_count() - 1, mi.mesh.surface_get_material(i))
		inst.free()
	_cave_meshes[model] = mesh
	return mesh


## The glowing parts (materials named glow_*) are painted pale: tint them with the kind's colour and let them shine.
func _tint_glow_parts(mi: MeshInstance3D, model: String, c: Color, glows: bool) -> void:
	if model == "glowcap":
		_bend_mushroom(mi, c, glows)
		return
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i) as StandardMaterial3D
		if m == null or not m.resource_name.begins_with("glow_"):
			continue
		var key := "%s/%d/%s/%s" % [model, i, c.to_html(), glows]
		if not _glow_mats.has(key):
			var t := m.duplicate() as StandardMaterial3D
			# Not too bright: the painted detail (bruises, cracks, facets) must still show (too strong = plain white blobs).
			if model != "giant":  # the giant's cap is painted in its own colours
				# the paint is near-white: a deep, extra-saturated tint keeps the colour (the AgX tonemapper turns bright colours white)
				t.albedo_color = Color.from_hsv(c.h, minf(1.0, c.s * 1.2), c.v * (0.7 if glows else 0.9))
			var ec := Color.from_hsv(c.h, minf(1.0, c.s * 1.2), c.v)
			t.emission_enabled = true
			t.emission = ec if model != "giant" else Color(0.75, 0.55, 0.85)
			t.emission_texture = m.albedo_texture
			t.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY  # colour x picture (the default ADDS them: white glow)
			t.emission_energy_multiplier = 0.9 if glows else (0.3 if model == "giant" else 0.12)
			if model == "crystal":
				# Shiny like glass (owner, Nov 16): src/art/crystal.gdshader. Facets flash as you walk round, rims glint,
				# the cut edges light up as hard lines.
				var sm := ShaderMaterial.new()
				sm.shader = CRYSTAL_SHADER
				sm.set_shader_parameter("albedo_tex", m.albedo_texture)
				sm.set_shader_parameter("tint", Color.from_hsv(c.h, minf(1.0, c.s * 1.15), c.v))
				sm.set_shader_parameter("glow", 0.45 if glows else 0.1)
				_glow_mats[key] = sm
			else:
				_glow_mats[key] = t
		mi.set_surface_override_material(i, _glow_mats[key])


const MUSHROOM_BEND := preload("res://src/art/mushroom_bend.gdshader")
const MUSHROOM_HEIGHT := 0.45  ## the glowcap model's height (m) before the spot's own size
var walkers: Node3D  ## the node holding every dwarf (main sets it): little mushrooms lean away from them (F219)
var _bend_mats: Array[ShaderMaterial] = []


## The little mushrooms lean away from dwarfs walking through them, like the ferns (owner F219). Every part of the
## model (soil, stem, gills, cap) uses the bending shader, so the whole mushroom moves together; the base stays put.
## Same colours as before: glowing parts get the kind's tint and glow, the rest keeps its painting.
func _bend_mushroom(mi: MeshInstance3D, c: Color, glows: bool) -> void:
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i) as StandardMaterial3D
		if m == null:
			continue
		var tinted := m.resource_name.begins_with("glow_")
		var key := "bend/%d/%s/%s" % [i, c.to_html() if tinted else "", glows]
		if not _glow_mats.has(key):
			var sm := ShaderMaterial.new()
			sm.shader = MUSHROOM_BEND
			sm.set_shader_parameter("albedo_tex", m.albedo_texture)
			sm.set_shader_parameter("plant_height", MUSHROOM_HEIGHT)
			sm.set_shader_parameter("push_scale", 0.35)  # stiffer than a fern: a lean and a wobble
			sm.set_shader_parameter("push_down", 0.0)  # never pushed down: big ones looked squashed flat (owner, Nov 17)
			sm.set_shader_parameter("roughness", m.roughness)
			if m.normal_texture:
				sm.set_shader_parameter("normal_tex", m.normal_texture)
				sm.set_shader_parameter("use_normal", 1.0)
			if tinted:
				sm.set_shader_parameter("albedo_color", Color.from_hsv(c.h, minf(1.0, c.s * 1.2), c.v * (0.7 if glows else 0.9)))
				sm.set_shader_parameter("emission_color", Color.from_hsv(c.h, minf(1.0, c.s * 1.2), c.v))
				sm.set_shader_parameter("emission_energy", 0.9 if glows else 0.12)
			else:
				sm.set_shader_parameter("albedo_color", m.albedo_color)
			_glow_mats[key] = sm
			_bend_mats.append(sm)
		mi.set_surface_override_material(i, _glow_mats[key])


## Tell the bending mushrooms where every dwarf's feet are (up to 4), each frame.
func _push_mushrooms() -> void:
	if _bend_mats.is_empty() or walkers == null:
		return
	var feet: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
	var i := 0
	for d in walkers.get_children():
		if d is Node3D and i < 4:
			var p := (d as Node3D).global_position
			feet[i] = Vector4(p.x, p.y, p.z, 1.0)
			i += 1
	for m in _bend_mats:
		m.set_shader_parameter("pushers", feet)


## A little wet stalactite with drops falling from its tip (not something you can hit).
func _add_drip(s: Dictionary) -> void:
	var root := Node3D.new()
	add_child(root)
	root.global_position = s.pos
	# The ringed dripstone with its drop (owner, Nov 17: "make those new stalactites the dripping stones"), hung upside
	# down, its rock chunk pushed into the ceiling like the other dripstone; drops fall from its tip.
	const SIZE := 0.9
	const TIP := (1.15 - 0.14) * SIZE  # how far below the ceiling its tip hangs
	var tip := MeshInstance3D.new()
	tip.mesh = _cave_mesh("drip")
	tip.basis = (Basis(Vector3.RIGHT, PI) * Basis(Vector3.UP, s.pos.x * 1.7)).scaled(Vector3.ONE * SIZE)
	tip.position = Vector3.UP * 0.14 * SIZE
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tip)
	var drops := CPUParticles3D.new()
	drops.amount = 3
	drops.lifetime = 1.6
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINT
	drops.direction = Vector3.DOWN
	drops.spread = 0.0
	drops.initial_velocity_min = 0.0
	drops.initial_velocity_max = 0.2
	drops.gravity = Vector3(0, -6.0, 0)
	var dm := SphereMesh.new()
	dm.radius = 0.03
	dm.height = 0.08
	dm.radial_segments = 4
	dm.rings = 2
	drops.mesh = dm
	drops.material_override = _material_for(s.color, true)
	drops.position = Vector3.DOWN * TIP
	root.add_child(drops)
	_nodes[s.id] = root


## Which painted grain each kind of plant/crystal gets (see Look.SURFACES).
func _surface_of(kind: String) -> String:
	if kind == "root" or kind == "twig":
		return "bark"
	if kind.begins_with("crystal"):
		return "smooth"
	return "fungus"


func _material_for(c: Color, glows: bool = true, surface: String = "") -> Material:
	var key := c.to_html() + str(glows) + surface
	if not _materials.has(key):
		if surface == "":
			surface = "smooth" if glows else "fungus"
		# Glowing things shine; the rest get a faint glow so they're findable in the dark.
		# Crystals stay sharp; mushrooms and roots get a little lumpy.
		var wobble := 0.0 if surface == "smooth" else 0.025
		_materials[key] = Look.mat(c.darkened(0.3) if glows else c, surface,
			2.2 if glows else (0.12 if surface == "bark" else 0.35), wobble, c)
	return _materials[key]


func _process(delta: float) -> void:
	# Lights fade in and out instead of popping like light switches (owner, Nov 15, F107).
	for i in _lights.size():
		_lights[i].light_energy = move_toward(_lights[i].light_energy, _light_target[i], delta * FADE_SPEED)
	_push_mushrooms()
	_light_timer -= delta
	if _light_timer > 0.0:
		return
	_light_timer = LIGHT_UPDATE
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_position
	# Only spots within 40 m can get a light, so only look in the squares around us.
	var near := spots_near(from, LIGHT_REACH).filter(func(s): return GlowPlacer.KINDS[s.kind].get("glow", false))
	near.sort_custom(func(a, b): return a.pos.distance_squared_to(from) < b.pos.distance_squared_to(from))
	near = near.slice(0, LIGHT_COUNT)
	var want := {}  # spot id -> how bright its light should be
	for rank in near.size():
		var s: Dictionary = near[rank]
		var d := s.pos.distance_to(from) as float
		# Dimmer the farther away, and the last few of the nearest set are dimmer too, so a spot
		# that drops out of the set (or a new one coming in) is already nearly dark.
		var fade := clampf((LIGHT_REACH - d) / 15.0, 0.0, 1.0) * clampf((LIGHT_COUNT - rank) / 4.0, 0.0, 1.0)
		want[s.id] = (1.1 if s.kind.begins_with("crystal") else 0.7) * fade
	# Lights already on a wanted spot keep it; the others fade out, and once dark take a new spot.
	var taken := {}
	for i in _lights.size():
		var sid: int = _light_spot[i]
		if want.has(sid):
			_light_target[i] = want[sid]
			taken[sid] = true
		else:
			_light_target[i] = 0.0
	for s in near:
		if taken.has(s.id):
			continue
		for i in _lights.size():
			if _light_target[i] == 0.0 and _lights[i].light_energy < 0.03:
				_light_spot[i] = s.id
				_lights[i].global_position = s.pos + s.normal * 0.6
				_lights[i].light_color = s.color
				_light_target[i] = want[s.id]
				taken[s.id] = true
				break


# ------------------------------------------------------------ simple low-poly meshes

var _giants := {}  ## height (half meters) -> mesh


## A giant mushroom `h` meters tall: a pale stalk and a wide glowing-rimmed cap.
func _giant_mesh(h: float) -> Mesh:
	var key := int(round(h * 2.0))
	if _giants.has(key):
		return _giants[key]
	h = key * 0.5
	var mesh := ArrayMesh.new()
	var stalk := CylinderMesh.new()
	stalk.radial_segments = 12
	stalk.rings = 6
	stalk.top_radius = 0.22
	stalk.bottom_radius = 0.38
	stalk.height = h
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(stalk, 0, Transform3D(Basis(), Vector3.UP * h * 0.5))
	st.generate_normals()
	st.commit(mesh)
	mesh.surface_set_material(0, Look.mat(Color(0.82, 0.77, 0.68), "fungus", 0.1, 0.07))
	var cap := SphereMesh.new()
	cap.radial_segments = 20
	cap.rings = 7
	cap.radius = 0.9 + h * 0.18
	cap.height = 0.7 + h * 0.08
	cap.is_hemisphere = true
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	st2.append_from(cap, 0, Transform3D(Basis(), Vector3.UP * (h - 0.15)))
	st2.generate_normals()
	st2.commit(mesh)
	# A wavy, lumpy cap with a soft purple glow.
	mesh.surface_set_material(1, Look.mat(Color(0.48, 0.28, 0.56), "fungus", 0.45, 0.16, Color(0.72, 0.4, 0.9)))
	_giants[key] = mesh
	return mesh

func _make_crystal_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shards := [[0.0, 0.0, 0.0, 0.75], [0.7, 0.25, 0.4, 0.5], [2.4, -0.2, 0.5, 0.45], [4.2, 0.15, -0.45, 0.55]]
	for sh in shards:
		var c := CylinderMesh.new()
		c.radial_segments = 6
		c.rings = 0
		c.top_radius = 0.015
		c.bottom_radius = 0.1
		c.height = sh[3]
		var t := Transform3D(Basis(Vector3.UP, sh[0]) * Basis(Vector3.RIGHT, sh[1]) * Basis(Vector3.FORWARD, sh[2]), Vector3.ZERO)
		t.origin = t.basis.y * sh[3] * 0.5
		st.append_from(c, 0, t)
	st.generate_normals()
	return st.commit()


func _make_mushroom_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.radial_segments = 7
	stem.rings = 2
	stem.top_radius = 0.045
	stem.bottom_radius = 0.07
	stem.height = 0.4
	st.append_from(stem, 0, Transform3D(Basis(), Vector3.UP * 0.2))
	var cap := SphereMesh.new()
	cap.radial_segments = 11
	cap.rings = 4
	cap.radius = 0.24
	cap.height = 0.2
	cap.is_hemisphere = true
	st.append_from(cap, 0, Transform3D(Basis(), Vector3.UP * 0.38))
	var small := Transform3D(Basis().scaled(Vector3.ONE * 0.55), Vector3(0.22, 0.0, 0.1))
	st.append_from(stem, 0, small * Transform3D(Basis(), Vector3.UP * 0.2))
	st.append_from(cap, 0, small * Transform3D(Basis(), Vector3.UP * 0.38))
	st.generate_normals()
	return st.commit()


## A fallen twig lying on the floor: a crooked stick about 60 cm long with a side branch and a stub.
func _make_twig_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in [[Vector3(-0.3, 0.035, 0.0), Vector3(0.0, 0.04, 0.03), 0.028], [Vector3(0.0, 0.04, 0.03), Vector3(0.3, 0.03, -0.02), 0.022],
			[Vector3(0.05, 0.04, 0.03), Vector3(0.18, 0.035, 0.16), 0.014], [Vector3(-0.12, 0.035, 0.01), Vector3(-0.15, 0.06, -0.05), 0.012]]:
		var a: Vector3 = part[0]
		var b: Vector3 = part[1]
		var stick := CylinderMesh.new()
		stick.radial_segments = 6
		stick.rings = 1
		stick.top_radius = part[2] * 0.7
		stick.bottom_radius = part[2]
		stick.height = a.distance_to(b)
		var y := (b - a).normalized()
		var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
		st.append_from(stick, 0, Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5))
	st.generate_normals()
	return st.commit()


func _make_fiber_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var blade := CylinderMesh.new()
		blade.radial_segments = 3
		blade.rings = 0
		blade.top_radius = 0.0
		blade.bottom_radius = 0.025
		blade.height = 0.35 + 0.05 * (i % 3)
		var a := i * 0.9
		var t := Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.35), Vector3(cos(a), 0, sin(a)) * 0.08)
		t.origin += t.basis.y * blade.height * 0.5
		st.append_from(blade, 0, t)
	st.generate_normals()
	return st.commit()


## A root 1 m long (stretched to fit the gap to the floor), hanging down from the ceiling:
## a thick, knobbly base, twisting and getting thinner toward the end, with a couple of side
## roots forking off and thin hair-roots at the tip. Clearly wood, not a stone icicle (F26).
func _make_root_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_root_tube(st, Vector3.ZERO, [Vector3(0.0, 0.0, 0.0), Vector3(0.06, 0.25, 0.03), Vector3(-0.05, 0.5, 0.05),
		Vector3(0.04, 0.75, -0.04), Vector3(-0.02, 1.0, 0.02)], 0.3, 0.025)
	# Side roots: forking off and curling down.
	_root_tube(st, Vector3.ZERO, [Vector3(0.0, 0.18, 0.0), Vector3(0.18, 0.3, 0.05), Vector3(0.26, 0.5, 0.1), Vector3(0.24, 0.7, 0.16)], 0.09, 0.015)
	_root_tube(st, Vector3.ZERO, [Vector3(0.0, 0.42, 0.0), Vector3(-0.16, 0.52, -0.08), Vector3(-0.2, 0.68, -0.14), Vector3(-0.17, 0.85, -0.2)], 0.07, 0.012)
	# Hair-roots at the tip.
	for k in 3:
		var a := k * TAU / 3.0
		_root_tube(st, Vector3.ZERO, [Vector3(-0.02, 0.92, 0.02), Vector3(cos(a) * 0.05, 1.0, sin(a) * 0.05), Vector3(cos(a) * 0.08, 1.08, sin(a) * 0.08)], 0.02, 0.005)
	st.generate_normals()
	return st.commit()


## A bendy tube through `points` (local +Y = down the root), from radius r0 to r1.
static func _root_tube(st: SurfaceTool, origin: Vector3, points: Array, r0: float, r1: float) -> void:
	const AROUND := 7
	const STEPS := 4  # smooth steps between two points
	var path := []
	for i in points.size() - 1:
		for k in STEPS:
			path.append((points[i] as Vector3).lerp(points[i + 1], float(k) / STEPS))
	path.append(points[points.size() - 1])
	var rings := []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		var radius := lerpf(r0, r1, pow(t, 0.7)) * (1.0 + 0.12 * sin(i * 2.3))  # knobbly
		var fwd: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := fwd.cross(Vector3.FORWARD if absf(fwd.z) < 0.9 else Vector3.RIGHT).normalized()
		var other := fwd.cross(side)
		var ring := []
		for a in AROUND:
			var ang := TAU * a / AROUND + t * 2.5  # a little twist
			ring.append(origin + path[i] + (side * cos(ang) + other * sin(ang)) * radius)
		rings.append(ring)
	for i in rings.size() - 1:
		for a in AROUND:
			var b := (a + 1) % AROUND
			for v in [rings[i][a], rings[i + 1][a], rings[i][b], rings[i][b], rings[i + 1][a], rings[i + 1][b]]:
				st.add_vertex(v)
