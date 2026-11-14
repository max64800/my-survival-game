class_name Sfx
## Plays sound effects from assets/sfx (CC0 sounds by Kenney, see CREDITS.md).
## Each sound has a few variants (name_0.ogg, name_1.ogg…); one is picked at random with
## a small random pitch so repeated hits don't sound like a machine gun.
##   Sfx.play("dig_rock", where)  → a sound in the 3D world
##   Sfx.ui("open")               → a flat interface sound

const FOLDER := "res://assets/sfx/"
const MAX_VARIANTS := 4

static var _streams := {}  ## name -> Array[AudioStream]
static var muted := false  ## tests and the autopilot can turn sounds off


static func _variants(name: String) -> Array:
	if not _streams.has(name):
		var list := []
		for i in MAX_VARIANTS:
			var path := FOLDER + "%s_%d.ogg" % [name, i]
			if ResourceLoader.exists(path):
				list.append(load(path))
		_streams[name] = list
	return _streams[name]


## A sound at a spot in the world (fades with distance).
static func play(name: String, at: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var list := _variants(name)
	if muted or list.is_empty() or tree == null or tree.root == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = list.pick_random()
	p.volume_db = volume_db
	p.pitch_scale = pitch * randf_range(0.92, 1.08)
	p.unit_size = 6.0
	p.max_distance = 45.0
	tree.root.add_child(p)
	p.global_position = at
	p.play()
	p.finished.connect(p.queue_free)


## A flat sound (menus, your own pickups).
static func ui(name: String, volume_db: float = -4.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var list := _variants(name)
	if muted or list.is_empty() or tree == null or tree.root == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = list.pick_random()
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.95, 1.05)
	tree.root.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
