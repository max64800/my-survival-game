class_name Look
## One place that decides how things look. Every prop, station, building piece, monster and
## drop asks Look.mat() for its material instead of making a plain flat colour.
## The rules (docs/design/visuals-plan.md, "style bible"): earthy colours, hand-painted grain,
## a little lumpy, soft rim light. Change the look here and the whole game follows.

## The grain layers in assets/textures/props/prop_detail.png (tools/art/bake_prop_textures.py).
const SURFACES := {stone = 0, wood = 1, fungus = 2, cloth = 3, leather = 4, metal = 5, bark = 6, smooth = 7}
const ROUGH := {stone = 0.88, wood = 0.8, fungus = 0.75, cloth = 0.95, leather = 0.7, metal = 0.42, bark = 0.9, smooth = 0.3}
const METAL := {metal = 0.65}

static var _cache := {}
static var _shader: Shader
static var _detail: Texture
static var _normal: Texture


## A material for `color`. `surface` = one of SURFACES ("" = guess from the colour).
## `glow` > 0 makes it shine (in `glow_color`, or its own colour). `wobble` = metres of lumpiness.
static func mat(color: Color, surface: String = "", glow: float = 0.0, wobble: float = 0.0,
		glow_color: Color = Color(0, 0, 0, 0)) -> Material:
	if surface == "":
		surface = guess(color)
	var key := "%s|%s|%.2f|%.3f|%s" % [color.to_html(), surface, glow, wobble, glow_color.to_html()]
	if _cache.has(key):
		return _cache[key]
	var m: Material
	if color.a < 0.99:
		var s := StandardMaterial3D.new()  # see-through things keep the simple material
		s.albedo_color = color
		s.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s.roughness = 0.3
		if glow > 0.0:
			s.emission_enabled = true
			s.emission = glow_color if glow_color.a > 0.0 else color
			s.emission_energy_multiplier = glow
		m = s
	else:
		_load()
		var sm := ShaderMaterial.new()
		sm.shader = _shader
		sm.set_shader_parameter("detail_tex", _detail)
		sm.set_shader_parameter("normal_tex", _normal)
		sm.set_shader_parameter("albedo", color)
		sm.set_shader_parameter("layer", float(SURFACES.get(surface, 0)))
		sm.set_shader_parameter("roughness", ROUGH.get(surface, 0.85) if glow <= 0.0 else 0.35)
		sm.set_shader_parameter("metallic", METAL.get(surface, 0.0))
		sm.set_shader_parameter("emission_color", glow_color if glow_color.a > 0.0 else color)
		sm.set_shader_parameter("emission_energy", glow)
		sm.set_shader_parameter("wobble", wobble)
		sm.set_shader_parameter("detail_strength", 0.45 if surface == "smooth" else 1.0)
		m = sm
	_cache[key] = m
	return m


## Guess the surface from a colour: greys are stone, browns are wood, everything else is
## "fungus" (soft blotchy skin: mushrooms, creatures).
static func guess(c: Color) -> String:
	var h := c.h * 360.0
	if c.s < 0.2:
		return "stone"
	if h >= 15.0 and h <= 48.0 and c.v < 0.72:
		return "wood"
	return "fungus"


static func _load() -> void:
	if _shader == null:
		_shader = load("res://src/art/prop.gdshader")
		_detail = load("res://assets/textures/props/prop_detail.png")
		_normal = load("res://assets/textures/props/prop_normal.png")
