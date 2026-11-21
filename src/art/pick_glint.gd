class_name PickGlint
extends MeshInstance3D
## The star that twinkles on an enemy's pick a moment before its blow lands (owner, Nov 20: "I don't see them
## attacking, they're behind my dwarf, so I don't see when to parry"). Drawn on top of everything, so your own dwarf
## can't hide it. Only looks: every screen makes its own from the swing it already plays (CreatureRig.attack).

const LIFE := 0.38   ## seconds it shows: pops in, holds, shrinks away
const SIZE := 0.55   ## metres across at its biggest
const COLOR := Color(1.0, 0.93, 0.7)  ## white-gold, like sun on metal

static var _tex: ImageTexture

var _holder: Node3D  ## the hand socket
var _at := Vector3(0, 0.9, 0)  ## where on the tool it sits, in the hand socket's own space (the leading point)
var _t := 0.0


## A star on the tool held by `holder`, at `at` in the hand socket's own space (CreatureRig.lead_tip).
static func on(holder: Node3D, at: Vector3) -> PickGlint:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(holder) or not holder.is_inside_tree():
		return null  # (the test computer draws nothing)
	var g := PickGlint.new()
	g._holder = holder
	g._at = at
	holder.get_tree().root.add_child(g)
	return g


func _ready() -> void:
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var q := QuadMesh.new()
	q.size = Vector2.ONE * SIZE
	mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.no_depth_test = true  # (seen through walls of bone, dwarves and dust: that's the point)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _star()
	m.albedo_color = COLOR
	m.render_priority = 10
	material_override = m
	scale = Vector3.ONE * 0.01
	_follow()


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE or not is_instance_valid(_holder):
		queue_free()
		return
	_follow()
	var u := _t / LIFE
	# Pops up fast (a little too big), settles, then shrinks to nothing; it turns a little as it twinkles.
	var s := 1.25 * sin(minf(u / 0.25, 1.0) * PI * 0.5) if u < 0.25 else lerpf(1.0, 0.0, pow((u - 0.25) / 0.75, 1.6))
	scale = Vector3.ONE * maxf(s, 0.01)
	rotation.z = u * 0.9  # (the billboard keeps facing you; this only spins the star)


func _follow() -> void:
	global_position = _holder.global_transform * _at


## A four-pointed star with a soft glow, drawn once.
static func _star() -> ImageTexture:
	if _tex != null:
		return _tex
	const N := 64
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var dx := (x + 0.5) / N * 2.0 - 1.0
			var dy := (y + 0.5) / N * 2.0 - 1.0
			var r := sqrt(dx * dx + dy * dy)
			var rays := maxf(0.0, 1.0 - absf(dx) * 9.0 - absf(dy) * 0.95) + maxf(0.0, 1.0 - absf(dy) * 9.0 - absf(dx) * 0.95)
			var glow := pow(maxf(0.0, 1.0 - r), 3.0)
			var a := clampf(rays + glow * 0.8, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_tex = ImageTexture.create_from_image(img)
	return _tex
