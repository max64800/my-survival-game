class_name AbilityFx
## Looks only (every computer plays them from GameAuthority._ev_ability; the host does the healing and resisting):
## the Healing Brew flask flying and splashing, and the Clan Banner standing for a minute (owner, Nov 27).

const FLASK := "res://assets/models/abilities/brew_flask.glb"
const BANNER := "res://assets/models/abilities/clan_banner.glb"
const BREW_COLOR := Color(0.95, 0.35, 0.3)  ## the brew inside the flask: warm red
const BANNER_COLOR := Color(0.95, 0.7, 0.3)


## The flask spins along the same arc as a thrown bomb, then bursts: red drops and a ring showing who it reaches.
static func throw_flask(parent: Node, from: Vector3, to: Vector3, seconds: float, reach: float) -> void:
	var flask: Node3D = load(FLASK).instantiate()
	parent.add_child(flask)
	flask.global_position = from
	var tw := flask.create_tween()
	tw.tween_method(func(k: float):
		flask.global_position = from.lerp(to, k) + Vector3.UP * sin(k * PI) * from.distance_to(to) * 0.25
		flask.rotation.x = -k * TAU * 1.5, 0.0, 1.0, seconds)
	tw.tween_callback(func():
		flask.queue_free()
		Sfx.play("dig_soft", to, 2.0, 1.6)  # glass breaking
		Sfx.play("eat", to, 0.0, 1.2)
		Fx.burst(parent, to + Vector3.UP * 0.2, BREW_COLOR, 24, 5.0, Vector3.UP, 80.0, false, 0.8)
		_ring(parent, to, reach, BREW_COLOR, 0.9))


## The banner rises out of the ground where it was planted, stays `seconds`, then sinks away. A faint ring on the
## floor shows the 10 m it protects.
static func plant_banner(parent: Node, at: Vector3, yaw: float, seconds: float) -> void:
	var banner: Node3D = load(BANNER).instantiate()
	parent.add_child(banner)
	banner.global_position = at + Vector3.DOWN * 0.6
	banner.rotation.y = yaw
	var tw := banner.create_tween()
	tw.tween_property(banner, "global_position", at, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(seconds - 0.8)
	tw.tween_property(banner, "global_position", at + Vector3.DOWN * 2.2, 0.5)
	tw.tween_callback(banner.queue_free)
	Fx.burst(parent, at, Color(0.45, 0.38, 0.3), 12, 2.5)  # a puff of dirt as it goes in
	_ring(parent, at, GameAuthority.BANNER_REACH, BANNER_COLOR, seconds, 0.12)


## A flat glowing ring on the floor, radius `reach`: grows out fast, holds, fades.
static func _ring(parent: Node, at: Vector3, reach: float, col: Color, seconds: float, alpha := 0.5) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.94
	t.outer_radius = 1.0
	t.rings = 48
	ring.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(col, alpha)
	ring.material_override = m
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	ring.global_position = at + Vector3.UP * 0.08
	ring.scale = Vector3(0.2, 0.05, 0.2)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3(reach, 0.05, reach), 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(seconds - 0.75, 0.0))
	tw.tween_property(m, "albedo_color:a", 0.0, 0.5)
	tw.tween_callback(ring.queue_free)
	return ring
