class_name Peephole
extends Node3D
## The glowing crack in the starting room's soft wall (feedback F10): "something is glowing
## on the other side". The world is made of 1 m blocks, so a truly tiny hole would close up;
## instead this shows bright slivers of crystal light leaking through, and a soft glow on the
## room side. It goes away once the wall has been dug out.

const GLOW := Color(0.45, 0.85, 1.0)

var _world: World
var _check_at := Vector3.ZERO
var _light: OmniLight3D
var _t := 0.0


## Puts the crack on the room-side face of the wall. Returns null if there's no start room.
static func make(world: World) -> Peephole:
	var st: Dictionary = world.maker.start
	if st.is_empty():
		return null
	var u: Vector3 = st.dir
	# A little to the right of center, so the dwarf's head doesn't hide it from the camera.
	var right := u.cross(Vector3.UP).normalized()
	var eye := Vector3(st.room_c.x, st.floor_y + CaveMaker.START_HOLE_Y, st.room_c.z) + right * 0.6
	# Walk from the room toward the wall until we touch rock.
	var p := eye
	for i in 80:
		if world.maker.sdf_at(p) < 0.0:
			break
		p += u * 0.1
	var ph := Peephole.new()
	ph._world = world
	ph._check_at = p + u * 0.7  # inside the wall, right behind the crack
	ph.position = p - u * 0.45  # in front of the wall (the drawn 1 m-block wall bulges past the math)
	ph.basis = Basis.looking_at(-u, Vector3.UP)
	return ph


func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GLOW
	mat.emission_enabled = true
	mat.emission = GLOW
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# A few thin slivers, like light coming through a crack.
	for s in [[Vector3(0.0, 0.0, 0.0), 0.15, 0.7], [Vector3(0.1, 0.2, 0.0), 0.6, 0.35], [Vector3(-0.09, -0.22, 0.0), -0.5, 0.32],
			[Vector3(0.03, 0.33, 0.0), -0.2, 0.18]]:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.07, s[2], 0.05)
		mi.mesh = box
		mi.material_override = mat
		mi.position = s[0]
		mi.rotation.z = s[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_light = OmniLight3D.new()
	_light.light_color = GLOW
	_light.light_energy = 1.2
	_light.omni_range = 3.5
	_light.position = Vector3(0, 0, -0.5)  # on the room side (-Z points back into the room)
	add_child(_light)


func _process(delta: float) -> void:
	_t += delta
	_light.light_energy = 1.1 + 0.25 * sin(_t * 1.7)  # a slow shimmer
	# Gone once the wall here has been dug away (only checked once that part of the cave has loaded).
	if _world.is_ready_at(_check_at, 1.0) and _world.sdf_at(_check_at) > 0.0:
		queue_free()
