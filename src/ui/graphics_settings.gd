class_name GraphicsSettings
## Graphics settings (owner, Nov 19: "optimize... for potato computers"; plan: docs/research/Voxel game performance
## plan.md). Five presets, from Potato to Ultra, plus a few switches of your own; remembered on this computer in
## user://settings.cfg ("graphics" section). The first time the game starts it picks Low on a laptop's built-in graphics
## and High on a real graphics card.
##
## What each preset changes, biggest saving first: how sharp the 3D picture is drawn (render scale, then sharpened back
## up with AMD FSR), the glowing air (volumetric fog), the soft corner shadows and wall bounce light (SSAO, SSIL), how
## many crystals light up the cave for real, simpler far-away models (mesh LOD), lantern shadow size, edge smoothing.

const PATH := "user://settings.cfg"
const PRESETS := ["potato", "low", "medium", "high", "ultra"]
const NAMES := {"potato": "Potato", "low": "Low", "medium": "Medium", "high": "High", "ultra": "Ultra", "custom": "Custom"}
const VALUES := {
	"potato": {scale = 0.5, fog = false, ssao = false, ssil = false, glow = false, lights = 8, lod = 8.0, shadow = 1024, msaa = 0},
	"low": {scale = 0.67, fog = false, ssao = false, ssil = false, glow = true, lights = 14, lod = 4.0, shadow = 2048, msaa = 0},
	"medium": {scale = 0.77, fog = true, ssao = true, ssil = false, glow = true, lights = 20, lod = 2.0, shadow = 2048, msaa = 0},
	"high": {scale = 1.0, fog = true, ssao = true, ssil = true, glow = true, lights = 28, lod = 1.0, shadow = 4096, msaa = 0},
	"ultra": {scale = 1.0, fog = true, ssao = true, ssil = true, glow = true, lights = 36, lod = 0.0, shadow = 4096, msaa = 2},
}
const FPS_CAPS := [30, 60, 90, 120, 144, 0]  ## 0 = no cap
const MAX_LIGHTS := 36  ## the most crystal lights any preset uses (GlowField makes this many)

static var preset := ""  ## "" = not chosen yet (first start), or a PRESETS name, or "custom"
static var v := {}  ## the values in use (a copy of a preset, maybe changed by hand)
static var fps_cap := 0
static var vsync := true
static var env: Environment  ## the cave's look (Ambience sets this)


## Reads the saved choice (or picks one for this computer) and applies it. Call once when the game starts.
static func load_and_apply(path: String = PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)
	preset = String(cfg.get_value("graphics", "preset", ""))
	if preset == "" or not (preset in PRESETS or preset == "custom"):
		preset = guess()
	v = (VALUES.get(preset, VALUES.high) as Dictionary).duplicate()
	if preset == "custom":
		var saved: Dictionary = cfg.get_value("graphics", "values", {})
		for k in saved:
			v[k] = saved[k]
	fps_cap = int(cfg.get_value("graphics", "fps_cap", 0))
	vsync = bool(cfg.get_value("graphics", "vsync", true))
	apply()


## First start: built-in laptop graphics get Low, everything else High.
static func guess() -> String:
	if RenderingServer.get_video_adapter_type() == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU:
		return "low"
	return "high"


static func choose(p: String, path: String = PATH) -> void:
	if not p in PRESETS:
		return
	preset = p
	v = (VALUES[p] as Dictionary).duplicate()
	apply()
	save(path)


## One value changed by hand: the preset becomes "Custom".
static func set_value(key: String, value: Variant, path: String = PATH) -> void:
	if v.is_empty():
		v = (VALUES.high as Dictionary).duplicate()
	v[key] = value
	preset = "custom"
	apply()
	save(path)


static func set_fps(cap: int, sync: bool, path: String = PATH) -> void:
	fps_cap = cap
	vsync = sync
	apply()
	save(path)


static func apply() -> void:
	if v.is_empty():
		v = (VALUES.high as Dictionary).duplicate()
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var vp := tree.root
	var forward_plus := RenderingServer.get_current_rendering_method() == "forward_plus"
	var scale: float = clampf(float(v.scale), 0.4, 1.0)
	vp.scaling_3d_scale = scale
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if forward_plus and scale < 0.99 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.msaa_3d = Viewport.MSAA_2X if int(v.msaa) == 2 else (Viewport.MSAA_4X if int(v.msaa) >= 4 else Viewport.MSAA_DISABLED)
	vp.mesh_lod_threshold = float(v.lod)
	vp.positional_shadow_atlas_size = int(v.shadow)
	Engine.max_fps = fps_cap
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	apply_env()


## The cave's look: glowing air, corner shadows, wall bounce light, glow.
static func apply_env() -> void:
	if env == null or v.is_empty():
		return
	env.volumetric_fog_enabled = bool(v.fog)
	env.fog_density = 0.012 if bool(v.fog) else 0.02  # (without the glowing air, a little more plain fog keeps the depth)
	env.ssao_enabled = bool(v.ssao)
	env.ssil_enabled = bool(v.ssil)
	env.glow_enabled = bool(v.glow)


## How many crystals light up the cave for real (GlowField reads this).
static func light_count() -> int:
	return clampi(int(v.get("lights", 28)), 4, MAX_LIGHTS) if not v.is_empty() else 28


## Mushroom grass: [how many of the tufts to draw, how far away] (fewer and nearer on weak computers).
static func grass() -> Array:
	return {"potato": [0.35, 14.0], "low": [0.55, 18.0], "medium": [0.8, 22.0], "ultra": [1.0, 32.0]}.get(preset, [1.0, 26.0])


## How many rock chunks fly when rock breaks (fewer on weak computers; the big ones always fly).
static func chunk_share() -> float:
	return {"potato": 0.4, "low": 0.65}.get(preset, 1.0)


## A small decorative light (a torch, a glowing creature, a place's lamp): it switches off smoothly when far away, so
## the graphics card never works on lights you can't see (owner, Nov 19: cheaper lights).
static func cheap_light(l: Light3D, far := 30.0) -> void:
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = far
	l.distance_fade_length = 8.0


static func save(path: String = PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)  # keep the sound and mouse settings already in the file
	cfg.set_value("graphics", "preset", preset)
	cfg.set_value("graphics", "values", v)
	cfg.set_value("graphics", "fps_cap", fps_cap)
	cfg.set_value("graphics", "vsync", vsync)
	cfg.save(path)
