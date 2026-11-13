class_name Station
extends StaticBody3D
## A crafting station placed in the world (campfire, workbench, smelter, ...).
## Slow jobs (smelting, cooking, tanning) wait in a queue; only the host runs the timer,
## and finished items pop out next to the station for anyone to pick up.

const STATION_LAYER := 16
const MAX_QUEUE := 20

var station_id := 0
var kind := "workbench"
var jobs: Array[Dictionary] = []  ## {item, count, left (seconds)}
var _fire: OmniLight3D


func _ready() -> void:
	collision_layer = STATION_LAYER | World.TERRAIN_LAYER  # you can stand on it and aim at it
	collision_mask = 0
	set_meta("station_id", station_id)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = _size()
	shape.shape = box
	shape.position = Vector3.UP * box.size.y * 0.5
	add_child(shape)
	_build_look()


func can_queue() -> bool:
	return jobs.size() < MAX_QUEUE


func queue_job(item: String, count: int, seconds: float) -> void:
	jobs.append({item = item, count = count, left = seconds})


## Runs the first job's timer. Returns finished jobs as [[item, count], ...].
func tick(delta: float) -> Array:
	var done := []
	if jobs.is_empty():
		return done
	jobs[0].left -= delta
	if jobs[0].left <= 0.0:
		var j: Dictionary = jobs.pop_front()
		done.append([j.item, j.count])
	if _fire:
		_fire.light_energy = 1.6 + randf() * 0.4
	return done


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
		"farm_plot": return Vector3(2.0, 0.2, 2.0)
	return Vector3(1.0, 1.0, 1.0)


## Placeholder looks made of boxes and cylinders (real art comes with the art pack).
func _build_look() -> void:
	var c := Items.color(kind)
	var sz := _size()
	match kind:
		"campfire":
			for i in 6:
				var a := i * TAU / 6.0
				_part(_box(Vector3(0.2, 0.15, 0.2)), Color(0.45, 0.43, 0.4), Vector3(cos(a), 0.07, sin(a)) * 0.4)
			for i in 3:
				var log := _part(_cyl(0.06, 0.06, 0.7), Color(0.4, 0.27, 0.15), Vector3(0, 0.12, 0))
				log.rotation = Vector3(PI / 2.0, i * PI / 3.0, 0)
			var flame := _part(_cyl(0.0, 0.18, 0.45), Color(1.0, 0.6, 0.2), Vector3(0, 0.35, 0), true)
			flame.rotation.y = 0.3
			_fire = OmniLight3D.new()
			_fire.light_color = Color(1.0, 0.6, 0.3)
			_fire.omni_range = 9.0
			_fire.light_energy = 1.8
			_fire.position = Vector3.UP * 0.6
			add_child(_fire)
		"smelter":
			_part(_cyl(0.45, 0.6, sz.y), c, Vector3.UP * sz.y * 0.5)
			_part(_box(Vector3(0.4, 0.35, 0.1)), Color(1.0, 0.5, 0.15), Vector3(0, 0.35, -0.55), true)
			_part(_cyl(0.15, 0.18, 0.6), c.darkened(0.3), Vector3.UP * (sz.y + 0.3))
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
		_:
			# Tables: a top on four legs.
			_part(_box(Vector3(sz.x, 0.12, sz.z)), c, Vector3.UP * (sz.y - 0.06))
			for x in [-1, 1]:
				for z in [-1, 1]:
					_part(_box(Vector3(0.12, sz.y - 0.12, 0.12)), c.darkened(0.25), Vector3(x * (sz.x * 0.5 - 0.1), (sz.y - 0.12) * 0.5, z * (sz.z * 0.5 - 0.1)))
			if kind == "masonry_table":
				_part(_box(Vector3(0.5, 0.3, 0.4)), Color(0.6, 0.6, 0.6), Vector3(0.3, sz.y + 0.15, 0))
	var label := Label3D.new()
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
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 3.0
	mi.material_override = m
	mi.position = pos
	add_child(mi)
	return mi


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
