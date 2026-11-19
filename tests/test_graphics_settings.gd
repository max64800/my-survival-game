extends TestCase
## Graphics presets (owner, Nov 19: "run well on potato computers"): Potato..Ultra, remembered on this computer.

const PATH := "user://test_graphics_settings.cfg"


func test_presets_apply_and_are_remembered() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var env := Environment.new()
	env.volumetric_fog_enabled = true
	env.ssao_enabled = true
	GraphicsSettings.env = env
	GraphicsSettings.choose("potato", PATH)
	var vp := tree.root
	check(absf(vp.scaling_3d_scale - 0.5) < 0.01, "Potato draws the 3D picture at half size")
	check(not env.volumetric_fog_enabled and not env.ssao_enabled, "Potato turns off the glowing air and corner shadows")
	check_eq(GraphicsSettings.light_count(), 8, "Potato lights 8 crystals for real")
	GraphicsSettings.set_value("fog", true, PATH)
	check_eq(GraphicsSettings.preset, "custom", "changing one thing by hand makes it Custom")
	check(env.volumetric_fog_enabled, "the glowing air is back on")
	GraphicsSettings.preset = ""
	GraphicsSettings.v = {}
	GraphicsSettings.load_and_apply(PATH)
	check_eq(GraphicsSettings.preset, "custom", "remembered after a restart")
	check(absf(float(GraphicsSettings.v.scale) - 0.5) < 0.01 and bool(GraphicsSettings.v.fog), "with its values")
	GraphicsSettings.choose("high", PATH)
	check(absf(vp.scaling_3d_scale - 1.0) < 0.01 and env.ssil_enabled, "High: full sharpness, wall bounce light on")
	GraphicsSettings.env = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_settings_panel_has_graphics() -> void:
	var panel := SettingsPanel.new()
	tree.root.add_child(panel)
	await tree.process_frame
	check(panel.find_child("Preset", true, false) != null, "a preset picker")
	check(panel.find_child("RenderScale", true, false) != null, "a sharpness slider")
	check(panel.find_child("GlowingAir", true, false) != null, "a glowing-air switch")
	panel.queue_free()
