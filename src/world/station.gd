class_name Station
extends StaticBody3D
## A crafting station placed in the world (campfire, workbench, smelter, ...).
## Slow jobs (smelting, cooking, tanning) wait in a queue; only the host runs the timer,
## and finished items pop out next to the station for anyone to pick up.

const STATION_LAYER := 16
const MAX_QUEUE := 20
const LADDER_HEIGHT := 6.0

var station_id := 0
var kind := "workbench"
var jobs: Array[Dictionary] = []  ## {item, count, left (seconds)}
## Drip Buckets (doc 6.4): water collected so far, and how it fills.
const WATER := {"drip_bucket": {holds = 5, every = 240.0}, "copper_drip_basin": {holds = 15, every = 120.0}}
var water := 0
var water_timer := 0.0
var under_drip := false  ## host decides when it's placed
var _label: Label3D
var _fire: OmniLight3D

## Station levels (building polish spec §3): a station is level 1, plus 1 for each DIFFERENT extra
## of its own standing within 4 m. Levels unlock building pieces and gear upgrades.
const EXTRAS := {
	"workbench": ["chopping_block", "carpenters_vise", "tool_rack"],
	"masonry_table": ["chisel_rack", "stone_saw"],
	"anvil": ["bellows", "grindstone"],
}
const EXTRA_RANGE := 4.0
var _label_timer := 0.0


func level() -> int:
	return 1 + _extras_near().size()


static func max_level(p_kind: String) -> int:
	return 1 + EXTRAS.get(p_kind, []).size()


## The next extra to build for a higher level ("" = already at the top).
func next_extra() -> String:
	var have := _extras_near()
	for e in EXTRAS.get(kind, []):
		if not have.has(e):
			return e
	return ""


func _extras_near() -> Dictionary:
	var found := {}
	var auth := GameAuthority.instance
	if auth == null or not EXTRAS.has(kind):
		return found
	for st in auth.stations.values():
		if st.kind in EXTRAS[kind] and (st as Station).global_position.distance_to(global_position) <= EXTRA_RANGE:
			found[st.kind] = true
	return found


func _process(delta: float) -> void:
	_label_timer -= delta
	if _label_timer > 0.0 or _label == null:
		return
	_label_timer = 1.0
	_label.text = "%s · level %d" % [Items.display_name(kind), level()]


func _ready() -> void:
	collision_layer = STATION_LAYER | World.TERRAIN_LAYER  # you can stand on it and aim at it
	if kind == "rope_ladder":
		collision_layer = STATION_LAYER  # you climb it, you don't bump into it
	collision_mask = 0
	set_meta("station_id", station_id)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = _size()
	shape.shape = box
	shape.position = Vector3.UP * box.size.y * 0.5
	add_child(shape)
	_build_look()
	set_process(EXTRAS.has(kind))  # only levelled stations update their name tag


func can_queue() -> bool:
	return jobs.size() < MAX_QUEUE


func queue_job(item: String, count: int, seconds: float) -> void:
	jobs.append({item = item, count = count, left = seconds})


## Runs the first job's timer. Returns finished jobs as [[item, count], ...].
func tick(delta: float) -> Array:
	var done := []
	if jobs.is_empty():
		return done
	# The Twin Smelter works on 2 jobs at once.
	for i in range(mini(2 if kind == "twin_smelter" else 1, jobs.size()) - 1, -1, -1):
		jobs[i].left -= delta
		if jobs[i].left <= 0.0:
			var j: Dictionary = jobs.pop_at(i)
			done.append([j.item, j.count])
	if _fire:
		_fire.light_energy = 1.6 + randf() * 0.4
	return done


## Host: fills a drip bucket. Returns true when the amount changed.
func tick_water(delta: float) -> bool:
	var w: Dictionary = WATER.get(kind, {})
	if w.is_empty() or not under_drip or water >= w.holds:
		return false
	water_timer += delta
	if water_timer < w.every:
		return false
	water_timer = 0.0
	water += 1
	return true


func set_water(n: int) -> void:
	water = n
	if _label and WATER.has(kind):
		_label.text = "%s · %d/%d water · E" % [Items.display_name(kind), water, WATER[kind].holds] if under_drip \
			else "%s · no drips here!" % Items.display_name(kind)


func busy_text() -> String:
	if jobs.is_empty():
		return ""
	return "Making %s… %ds (%d waiting)" % [Items.display_name(jobs[0].item), ceili(jobs[0].left), jobs.size() - 1]


func _size() -> Vector3:
	match kind:
		"campfire": return Vector3(1.0, 0.5, 1.0)
		"workbench", "masonry_table": return Vector3(1.8, 1.0, 0.9)
		"smelter": return Vector3(1.2, 1.6, 1.2)
		"anvil": return Vector3(0.9, 0.8, 0.5)
		"cooking_pot": return Vector3(0.9, 0.7, 0.9)
		"bed": return Vector3(1.0, 0.5, 2.0)
		"rune_slab": return Vector3(1.6, 1.8, 0.4)
		"twin_smelter": return Vector3(2.0, 1.6, 1.2)
		"crystal_sconce", "glow_marker", "glow_lamp": return Vector3(0.4, 1.2, 0.4)
		"training_dummy": return Vector3(0.6, 1.6, 0.6)
		"rope_ladder": return Vector3(0.7, LADDER_HEIGHT, 0.15)
		"gem_bench": return Vector3(1.4, 0.9, 0.8)
		"farm_plot": return Vector3(2.0, 0.2, 2.0)
		"chopping_block": return Vector3(0.7, 0.6, 0.7)
		"carpenters_vise", "chisel_rack": return Vector3(1.0, 1.0, 0.6)
		"tool_rack": return Vector3(1.4, 1.6, 0.3)
		"stone_saw": return Vector3(1.4, 1.1, 0.8)
		"bellows": return Vector3(1.0, 0.6, 0.6)
		"grindstone": return Vector3(0.8, 1.0, 0.6)
	return Vector3(1.0, 1.0, 1.0)


## The campfire's flames, sparks and smoke, and its flickering light.
func _add_fire() -> void:
	var fire := Fire.new(1.0)
	fire.position = Vector3.UP * 0.12
	add_child(fire)
	_fire = OmniLight3D.new()
	_fire.light_color = Color(1.0, 0.6, 0.3)
	_fire.omni_range = 9.0
	_fire.light_energy = 1.8
	_fire.position = Vector3.UP * 0.6
	add_child(_fire)


## Placeholder looks made of boxes and cylinders (used until the asset forge has a model).
func _build_look() -> void:
	var c := Items.color(kind)
	var sz := _size()
	# A real 3D model from the asset forge, when one exists (else the simple shapes below).
	var model := Look.forged("stations", kind)
	if model:
		model.rotation.y = PI  # forged models face +Z; stations face -Z
		add_child(model)
		if kind == "campfire":
			_add_fire()
		return
	match kind:
		"campfire":
			for i in 6:
				var a := i * TAU / 6.0
				_part(_box(Vector3(0.2, 0.15, 0.2)), Color(0.45, 0.43, 0.4), Vector3(cos(a), 0.07, sin(a)) * 0.4)
			for i in 3:
				var log := _part(_cyl(0.06, 0.06, 0.7), Color(0.4, 0.27, 0.15), Vector3(0, 0.12, 0))
				log.rotation = Vector3(PI / 2.0, i * PI / 3.0, 0)
			_part(_cyl(0.12, 0.2, 0.08), Color(1.0, 0.45, 0.12), Vector3(0, 0.08, 0), true)  # glowing coals
			_add_fire()
		"smelter":
			_part(_cyl(0.45, 0.6, sz.y), c, Vector3.UP * sz.y * 0.5)
			_part(_box(Vector3(0.4, 0.35, 0.1)), Color(1.0, 0.5, 0.15), Vector3(0, 0.35, -0.55), true)
			_part(_cyl(0.15, 0.18, 0.6), c.darkened(0.3), Vector3.UP * (sz.y + 0.3))
			var mouth := Fire.new(0.45, false)
			mouth.position = Vector3(0, 0.22, -0.62)
			add_child(mouth)
		"gem_bench":
			_part(_box(Vector3(sz.x, 0.12, sz.z)), Color(0.4, 0.3, 0.22), Vector3.UP * 0.8)
			for x in [-0.6, 0.6]:
				_part(_box(Vector3(0.1, 0.8, 0.7)), Color(0.35, 0.25, 0.18), Vector3(x, 0.4, 0))
			_part(_cyl(0.2, 0.2, 0.06), Color(0.6, 0.6, 0.62), Vector3(-0.3, 0.9, 0))  # polishing wheel
			for i in 3:
				_part(_box(Vector3(0.1, 0.1, 0.1)), [Color(1.0, 0.35, 0.2), Color(0.4, 1.0, 0.4), Color(0.45, 0.75, 1.0)][i], Vector3(0.2 + i * 0.15, 0.92, 0.1), true)
		"anvil":
			_part(_box(Vector3(0.35, 0.45, 0.35)), Color(0.4, 0.3, 0.2), Vector3.UP * 0.22)
			_part(_box(Vector3(0.9, 0.3, 0.4)), c, Vector3.UP * 0.6)
		"cooking_pot":
			_part(_cyl(0.42, 0.32, 0.55), c, Vector3.UP * 0.35)
			_part(_cyl(0.38, 0.38, 0.05), Color(0.6, 0.45, 0.3), Vector3.UP * 0.6)
		"bed":
			_part(_box(Vector3(sz.x, 0.25, sz.z)), Color(0.45, 0.3, 0.18), Vector3.UP * 0.12)
			_part(_box(Vector3(sz.x * 0.9, 0.15, sz.z * 0.8)), c, Vector3(0, 0.32, 0.1))
			_part(_box(Vector3(sz.x * 0.8, 0.15, 0.35)), Color(0.9, 0.88, 0.8), Vector3(0, 0.35, -0.75))
		"rune_slab":
			_part(_box(sz), Color(0.45, 0.45, 0.5), Vector3.UP * sz.y * 0.5)
			_part(_box(Vector3(1.2, 1.2, 0.05)), Color(0.4, 0.6, 1.0), Vector3(0, sz.y * 0.55, -0.21), true)
		"farm_plot":
			_part(_box(sz), Color(0.3, 0.2, 0.12), Vector3.UP * 0.1)
		"crystal_sconce", "glow_marker", "glow_lamp":
			# A post with a glowing crystal (sconce: blue light; marker: an amber flag, shown on the map;
			# glow lamp: a beetle's glow gland, soft green light).
			var marker := kind == "glow_marker"
			_part(_cyl(0.05, 0.06, 1.1), Color(0.4, 0.3, 0.2), Vector3.UP * 0.55)
			_part(_box(Vector3(0.25, 0.25, 0.25)) if not marker else _box(Vector3(0.45, 0.3, 0.03)), c, Vector3(0.0 if not marker else 0.24, 1.15, 0), true)
			var l := OmniLight3D.new()
			l.light_color = c
			l.omni_range = 8.0 if not marker else 5.0
			l.light_energy = 1.4 if not marker else 0.8
			l.position = Vector3.UP * 1.2
			add_child(l)
		"twin_smelter":
			for x in [-0.5, 0.5]:
				_part(_cyl(0.42, 0.55, sz.y), c, Vector3(x, sz.y * 0.5, 0))
				_part(_box(Vector3(0.35, 0.3, 0.1)), Color(1.0, 0.5, 0.15), Vector3(x, 0.35, -0.55), true)
		"rope_ladder":
			for x in [-0.3, 0.3]:
				_part(_box(Vector3(0.04, sz.y, 0.04)), c, Vector3(x, sz.y * 0.5, 0))
			for i in int(sz.y / 0.4):
				_part(_box(Vector3(0.6, 0.05, 0.05)), Color(0.5, 0.35, 0.2), Vector3(0, 0.2 + i * 0.4, 0))
		"training_dummy":
			_part(_cyl(0.05, 0.05, 1.6), Color(0.4, 0.3, 0.2), Vector3.UP * 0.8)
			_part(_cyl(0.25, 0.28, 0.7), c, Vector3.UP * 1.0)
			_part(_box(Vector3(1.0, 0.1, 0.1)), Color(0.4, 0.3, 0.2), Vector3.UP * 1.2)
			_part(_sphere_mesh(0.18), c.lightened(0.1), Vector3.UP * 1.5)
		# --- station extras (simple shapes until the asset forge makes models)
		"chopping_block":
			_part(_cyl(0.32, 0.36, 0.5), Color(0.45, 0.32, 0.2), Vector3.UP * 0.25)  # a stump
			var axe := _part(_cyl(0.025, 0.025, 0.6), Color(0.5, 0.35, 0.2), Vector3(0.05, 0.75, 0))
			axe.rotation.z = 0.5
			_part(_box(Vector3(0.05, 0.16, 0.2)), Color(0.6, 0.6, 0.62), Vector3(-0.08, 0.55, 0))
		"carpenters_vise", "chisel_rack":
			_part(_box(Vector3(sz.x, 0.1, sz.z)), Color(0.45, 0.32, 0.2), Vector3.UP * (sz.y - 0.05))
			for x in [-0.4, 0.4]:
				_part(_box(Vector3(0.1, sz.y - 0.1, sz.z - 0.1)), Color(0.38, 0.27, 0.17), Vector3(x, (sz.y - 0.1) * 0.5, 0))
			if kind == "carpenters_vise":
				_part(_box(Vector3(0.3, 0.2, 0.2)), Color(0.4, 0.4, 0.42), Vector3(0.3, sz.y + 0.1, 0))  # the iron vise
			else:
				for i in 5:
					_part(_box(Vector3(0.03, 0.25, 0.03)), Color(0.6, 0.6, 0.62), Vector3(-0.3 + i * 0.15, sz.y + 0.12, 0))  # chisels
		"tool_rack":
			_part(_box(Vector3(sz.x, sz.y, 0.06)), Color(0.42, 0.3, 0.19), Vector3(0, sz.y * 0.5, 0.1))
			for i in 4:
				_part(_box(Vector3(0.05, 0.6, 0.05)), Color(0.5, 0.36, 0.22), Vector3(-0.5 + i * 0.33, 0.9, 0.0))
				_part(_box(Vector3(0.18, 0.1, 0.05)), Color(0.6, 0.6, 0.62), Vector3(-0.5 + i * 0.33, 1.25, 0.0))
		"stone_saw":
			_part(_box(Vector3(sz.x, 0.12, sz.z)), Color(0.55, 0.53, 0.5), Vector3.UP * 0.8)
			for x in [-0.6, 0.6]:
				_part(_box(Vector3(0.12, 0.8, sz.z - 0.1)), Color(0.45, 0.43, 0.4), Vector3(x, 0.4, 0))
			var blade := _part(_cyl(0.3, 0.3, 0.03), Color(0.7, 0.7, 0.72), Vector3(0, 0.95, 0))
			blade.rotation.x = PI / 2.0
		"bellows":
			_part(_box(Vector3(0.8, 0.15, 0.5)), Color(0.4, 0.28, 0.18), Vector3.UP * 0.1)
			var top := _part(_box(Vector3(0.8, 0.08, 0.5)), Color(0.4, 0.28, 0.18), Vector3(0, 0.4, 0))
			top.rotation.z = 0.25
			_part(_box(Vector3(0.7, 0.25, 0.45)), Color(0.5, 0.33, 0.2), Vector3(-0.05, 0.27, 0))  # leather
			_part(_cyl(0.04, 0.06, 0.4), Color(0.5, 0.35, 0.2), Vector3(0.55, 0.25, 0)).rotation.z = PI / 2.0
		"grindstone":
			for x in [-0.3, 0.3]:
				_part(_box(Vector3(0.1, 0.7, 0.1)), Color(0.42, 0.3, 0.19), Vector3(x, 0.35, 0))
			var wheel := _part(_cyl(0.32, 0.32, 0.12), Color(0.6, 0.58, 0.55), Vector3(0, 0.6, 0))
			wheel.rotation.z = PI / 2.0
		"drip_bucket", "copper_drip_basin":
			var big := kind == "copper_drip_basin"
			_part(_cyl(0.32 if not big else 0.55, 0.26 if not big else 0.5, 0.5 if not big else 0.4), c, Vector3.UP * 0.25)
			_part(_cyl(0.28 if not big else 0.5, 0.28 if not big else 0.5, 0.02), Color(0.3, 0.55, 0.95), Vector3.UP * 0.45, true)
		_:
			# Tables: a top on four legs.
			_part(_box(Vector3(sz.x, 0.12, sz.z)), c, Vector3.UP * (sz.y - 0.06))
			for x in [-1, 1]:
				for z in [-1, 1]:
					_part(_box(Vector3(0.12, sz.y - 0.12, 0.12)), c.darkened(0.25), Vector3(x * (sz.x * 0.5 - 0.1), (sz.y - 0.12) * 0.5, z * (sz.z * 0.5 - 0.1)))
			if kind == "masonry_table":
				_part(_box(Vector3(0.5, 0.3, 0.4)), Color(0.6, 0.6, 0.6), Vector3(0.3, sz.y + 0.15, 0))
	var label := Label3D.new()
	_label = label
	label.text = Items.display_name(kind)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3.UP * (sz.y + 0.5)
	label.pixel_size = 0.004
	label.font_size = 40
	label.outline_size = 10
	label.modulate = Color(1, 1, 1, 0.8)
	add_child(label)
	label.visibility_range_begin = 2.0  # hide when the camera is right on top of it
	label.visibility_range_end = 30.0


func _part(mesh: Mesh, color: Color, pos: Vector3, glow: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Look.mat(color, "", 3.0 if glow else 0.0)
	mi.position = pos
	add_child(mi)
	return mi


func _sphere_mesh(r: float) -> Mesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _box(size: Vector3) -> Mesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(top: float, bottom: float, h: float) -> Mesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 8
	return c
