class_name Ambience
extends Node
## The cave's mood: light, fog, colours, and the stuff floating in the air.
## - Dark by default: the lantern is the sun (visuals plan, style bible rule 4).
## - Volumetric fog: light from the lantern and crystals glows in the air.
## - Bounced light (SSIL): the lantern lights up nearby walls more softly and warmly.
## - Floating dust (Mossy) / glowing spores (Fungal Jungle) around the camera.
## - Each biome has its own mood; walking between them blends slowly from one to the other.
## Only looks: nothing here changes gameplay, so nothing needs to go over the network.

const MOODS := {
	"mossy": {
		ambient = Color(0.33, 0.38, 0.42), ambient_energy = 0.4,  # (was 0.32: "somewhere with nothing... I don't see anything")
		fog = Color(0.045, 0.05, 0.06), fog_emit = Color(0.012, 0.016, 0.022),
		tint = Color(1.0, 0.98, 0.94), dust = Color(0.9, 0.8, 0.65, 0.55), spores = 0.0,  # (owner, Nov 18: no purple dots: the glowing swarms instead)
	},
	"fungal": {
		ambient = Color(0.40, 0.33, 0.50), ambient_energy = 0.44,  # (was 0.36)
		fog = Color(0.05, 0.04, 0.07), fog_emit = Color(0.02, 0.012, 0.03),
		tint = Color(0.97, 0.95, 1.0), dust = Color(0.8, 0.7, 1.0, 0.5), spores = 0.0,  # (owner, Nov 18: no purple dots)
	},
}
const BLEND_SPEED := 0.6  ## how fast the mood changes when you cross into another biome

var env: Environment
var _cur := {}
var _dust: GPUParticles3D
var _spores: GPUParticles3D
var _dust_mat: StandardMaterial3D
var _warmed := false


func _ready() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.008, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.85
	# Distance fog: far-away cave fades into darkness.
	env.fog_enabled = true
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	# Volumetric fog: the air itself catches light.
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.022
	env.volumetric_fog_albedo = Color(0.75, 0.72, 0.68)
	env.volumetric_fog_anisotropy = 0.5  # light glows more when you look toward it
	env.volumetric_fog_length = 40.0
	env.volumetric_fog_detail_spread = 1.5
	env.volumetric_fog_ambient_inject = 0.0
	env.volumetric_fog_emission_energy = 1.0
	# Contact shadows in corners, and light bouncing off nearby walls.
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.8
	env.ssao_power = 1.3
	env.ssil_enabled = true
	env.ssil_radius = 4.0
	env.ssil_intensity = 1.3
	# A gentle "photo filter".
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# The glow-worms' light, falling softly from the huge cavern's ceiling (only on while you're in there).
	_moon = DirectionalLight3D.new()
	_moon.rotation_degrees = Vector3(-72.0, 25.0, 0.0)
	_moon.light_color = MOON_COLOR
	_moon.light_energy = 0.0
	_moon.light_specular = 0.2
	_moon.shadow_enabled = false  # (its shadows would all fall from the rock ceiling above)
	_moon.light_volumetric_fog_energy = 0.0  # (no glowing haze: it would hide the stars)
	_moon.visible = false
	add_child(_moon)
	_cur = MOODS.mossy.duplicate()
	_apply()
	_dust = _make_motes(320, 0.022, false)
	_spores = _make_motes(260, 0.035, true)  # (F190, owner Nov 18: more drifting glowing spores)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if not _warmed:
		_warm_up(cam)
	var at := cam.global_position
	_dust.global_position = at
	_spores.global_position = at
	var want: Dictionary = MOODS.get(CaveMaker.biome_at(at), MOODS.mossy)
	var t := clampf(delta * BLEND_SPEED, 0.0, 1.0)
	for k in want:
		_cur[k] = lerp(_cur[k], want[k], t)
	_big = move_toward(_big, _in_big_cavern(at), delta * 0.5)
	_look_around(at, delta)
	_apply()


# ---------------------------------------------------------------- the huge star cavern and dark-adapted eyes
# Owner, Nov 17: the huge first cavern was so dark you "barely understand what is happening". Picked: star light
# (the glow-worms light the cavern softly from above, "moonlit"), a little more soft light there, and eyes that
# adjust in big dark places. None of it dims the stars.
const MOON_ENERGY := 0.32  ## the star light at full (moonlit: shapes and roots show, colours stay dim)
const MOON_COLOR := Color(0.55, 0.78, 0.85)
const BIG_AMBIENT := 0.2  ## extra soft light inside the huge cavern
const EYES_MAX := 0.18  ## eyes adjusted to a big dark space: up to 18% brighter (owner, Nov 17: 0.45 too bright, 0 too dark)
const EYES_SPEED := 0.12  ## how fast eyes adjust (per second, a few seconds like real eyes)
var _moon: DirectionalLight3D
var _big := 0.0  ## 0..1: how far inside the huge cavern the camera is
var _eyes := 0.0  ## 0..1: how adjusted to the dark the eyes are
var _open := 0.0  ## 0..1: how open the space around the camera is
var _look_t := 0.0


## How far inside the huge first cavern p is (0 = outside, 1 = well inside).
func _in_big_cavern(p: Vector3) -> float:
	var w = get_parent().get("world") if get_parent() else null
	if w == null or w.maker == null:
		return 0.0
	var f: Dictionary = w.maker.first_cavern()
	if f.is_empty():
		return 0.0
	var c: Vector3 = f.center
	var r: Vector3 = f.radii
	if p.y < c.y - r.y * 0.55 - 4.0 or p.y > c.y + r.y + 2.0:
		return 0.0
	var rr := maxf(r.x, r.z)
	return 1.0 - smoothstep(rr * 0.8, rr * 1.02, Vector2(p.x - c.x, p.z - c.z).length())


## Eyes adjust (like real eyes): twice a second, feel how open it is around the camera (rock within 12 m in 10
## directions or not). In a big open dark space the eyes slowly open up; near walls they slowly go back.
func _look_around(p: Vector3, delta: float) -> void:
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = 0.5
		var w = get_parent().get("world") if get_parent() else null
		if w != null and w.maker != null:
			var air := 0
			const DIRS := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(0.7, 0.7, 0),
				Vector3(-0.7, 0.7, 0), Vector3(0, 0.7, 0.7), Vector3(0, 0.7, -0.7), Vector3(0, 1, 0), Vector3(0.6, -0.3, 0.6)]
			for d in DIRS:
				if w.maker.sdf_at(p + d * 12.0) > 0.0:
					air += 1
			_open = smoothstep(0.5, 1.0, air / float(DIRS.size()))
	_eyes = move_toward(_eyes, _open, delta * EYES_SPEED)


## Dev only (F7, owner Nov 17): every light on: bright even light everywhere and no fog, to see the whole cave.
var dev_bright := false


func set_dev_bright(on: bool) -> void:
	dev_bright = on
	env.fog_enabled = not on
	env.volumetric_fog_enabled = not on
	_apply()


func _apply() -> void:
	env.ambient_light_color = Color(0.85, 0.85, 0.85) if dev_bright else (_cur.ambient as Color).lerp(MOON_COLOR, _big * 0.4)
	env.ambient_light_energy = 2.2 if dev_bright else _cur.ambient_energy + BIG_AMBIENT * _big
	env.tonemap_exposure = 1.15 * (1.0 + EYES_MAX * _eyes)
	if _moon:
		_moon.light_energy = MOON_ENERGY * _big
		_moon.visible = _big > 0.01 and not dev_bright
	env.fog_light_color = _cur.fog
	env.volumetric_fog_emission = _cur.fog_emit
	if _dust_mat:
		_dust_mat.albedo_color = _cur.dust
	if _spores:
		_spores.amount_ratio = _cur.spores
		_spores.emitting = _cur.spores > 0.05


## Tiny specks drifting in the air around the camera. They only show where light hits them,
## so walking with the lantern makes the air feel thick and alive.
func _make_motes(count: int, size: float, glowing: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = count
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-14, -8, -14), Vector3(28, 16, 28))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(11, 5, 11)
	pm.gravity = Vector3(0, 0.02 if glowing else -0.015, 0)
	if glowing:  # each spore its own shade, violet to blue to pink (F190)
		pm.hue_variation_min = -0.22
		pm.hue_variation_max = 0.12
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.08
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.4
	pm.turbulence_noise_scale = 6.0
	pm.turbulence_influence_min = 0.02
	pm.turbulence_influence_max = 0.06
	pm.scale_min = 0.5
	pm.scale_max = 1.4
	var fade := Curve.new()
	fade.add_point(Vector2(0.0, 0.0))
	fade.add_point(Vector2(0.15, 1.0))
	fade.add_point(Vector2(0.85, 1.0))
	fade.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = fade
	pm.scale_curve = ct
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	if glowing:
		m.albedo_color = Color(0.75, 0.55, 1.0, 0.8)
		m.emission_enabled = true
		m.emission = Color(0.6, 0.35, 1.0)
		m.emission_energy_multiplier = 2.5
	else:
		m.albedo_color = _cur.dust
		_dust_mat = m
	q.material = m
	p.draw_pass_1 = q
	add_child(p)
	return p


## Godot prepares each new kind of effect the first time it is drawn, which freezes the game
## for a moment (we measured 2 FPS for a second when the first campfire appeared). So while
## the cave loads, we draw one tiny fire and one burst of chips right in front of the camera,
## too small to notice. After that, the real ones appear smoothly.
func _warm_up(cam: Camera3D) -> void:
	_warmed = true
	var at := cam.global_position - cam.global_basis.z * 1.5
	var fire := Fire.new(0.02)
	add_child(fire)
	fire.global_position = at
	Fx.burst(self, at, Color(0.5, 0.48, 0.45), 6, 0.1)
	Fx.burst(self, at, Color(0.4, 0.75, 1.0), 2, 0.1)
	get_tree().create_timer(2.0).timeout.connect(fire.queue_free)
