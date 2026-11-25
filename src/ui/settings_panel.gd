class_name SettingsPanel
extends PanelContainer
## The Settings panel (owner F187 mock-up): sound volume, mute, mouse speed and graphics (owner, Nov 19), remembered on this
## computer (SoundSettings). Used by the start screen and the Escape menu. A Music slider sits under the main volume.


func _ready() -> void:
	UiKit.panel(self)
	custom_minimum_size = Vector2(360, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	UiKit.title(v, "Settings")
	var sound := _row(v, "Sound")
	sound.name = "SoundBox"
	var vol := UiKit.slider(HSlider.new())
	vol.name = "Volume"
	vol.min_value = 0
	vol.max_value = 100
	vol.step = 5
	vol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vol.set_value_no_signal(SoundSettings.volume * 100.0)
	vol.value_changed.connect(func(x: float): SoundSettings.set_volume(x / 100.0))
	sound.add_child(vol)
	var music := _row(v, "Music")
	var mus := UiKit.slider(HSlider.new())
	mus.name = "MusicVolume"
	mus.min_value = 0
	mus.max_value = 100
	mus.step = 5
	mus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mus.set_value_no_signal(SoundSettings.music_volume * 100.0)
	mus.value_changed.connect(func(x: float): SoundSettings.set_music_volume(x / 100.0))
	music.add_child(mus)
	var mute := CheckButton.new()
	mute.name = "Mute"
	mute.text = "Mute"
	mute.focus_mode = Control.FOCUS_NONE
	mute.add_theme_color_override("font_color", UiKit.TEXT)
	mute.set_pressed_no_signal(SoundSettings.muted)
	mute.toggled.connect(func(m: bool): SoundSettings.set_muted(m))
	v.add_child(mute)
	UiKit.divider(v)
	var mouse := _row(v, "Mouse speed")
	var ms := UiKit.slider(HSlider.new())
	ms.name = "MouseSpeed"
	ms.min_value = 25
	ms.max_value = 300
	ms.step = 5
	ms.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ms.set_value_no_signal(Controls.mouse_scale * 100.0)
	ms.value_changed.connect(func(x: float): SoundSettings.set_mouse_scale(x / 100.0))
	mouse.add_child(ms)
	UiKit.divider(v)
	# Camera shake (F695, owner Nov 22): some people get dizzy from it, so it can be turned down or off.
	var shake_row := _row(v, "Camera shake")
	var sh := UiKit.slider(HSlider.new())
	sh.name = "CameraShake"
	sh.min_value = 0
	sh.max_value = 100
	sh.step = 10
	sh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.set_value_no_signal(SoundSettings.camera_shake * 100.0)
	sh.value_changed.connect(func(x: float): SoundSettings.set_camera_shake(x / 100.0))
	shake_row.add_child(sh)
	UiKit.divider(v)
	# Graphics (owner, Nov 19: run well on weak computers too): a preset, and the few things people change most.
	var gfx := _row(v, "Graphics")
	var pick := OptionButton.new()
	pick.name = "Preset"
	pick.focus_mode = Control.FOCUS_NONE
	for p in GraphicsSettings.PRESETS:
		pick.add_item(GraphicsSettings.NAMES[p])
	pick.add_item(GraphicsSettings.NAMES.custom)
	gfx.add_child(pick)
	var sharp_row := _row(v, "Picture sharpness")
	var sharp := UiKit.slider(HSlider.new())
	sharp.name = "RenderScale"
	sharp.min_value = 50
	sharp.max_value = 100
	sharp.step = 5
	sharp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sharp_row.add_child(sharp)
	UiKit.label(sharp_row, "Lower = faster on weak computers (drawn smaller, then sharpened back up)", 12, UiKit.TEXT)
	var fog := CheckButton.new()
	fog.name = "GlowingAir"
	fog.text = "Glowing air (light in the fog)"
	fog.focus_mode = Control.FOCUS_NONE
	fog.add_theme_color_override("font_color", UiKit.TEXT)
	v.add_child(fog)
	var fps_row := _row(v, "Frame rate limit")
	var fps := OptionButton.new()
	fps.name = "FpsCap"
	fps.focus_mode = Control.FOCUS_NONE
	for c in GraphicsSettings.FPS_CAPS:
		fps.add_item("No limit" if c == 0 else "%d FPS" % c)
	fps_row.add_child(fps)
	var show_gfx := func() -> void:
		var i := GraphicsSettings.PRESETS.find(GraphicsSettings.preset)
		pick.select(i if i >= 0 else GraphicsSettings.PRESETS.size())
		sharp.set_value_no_signal(roundf(float(GraphicsSettings.v.get("scale", 1.0)) * 100.0))
		fog.set_pressed_no_signal(bool(GraphicsSettings.v.get("fog", true)))
		fps.select(maxi(0, GraphicsSettings.FPS_CAPS.find(GraphicsSettings.fps_cap)))
	show_gfx.call()
	pick.item_selected.connect(func(i: int):
		if i < GraphicsSettings.PRESETS.size():
			GraphicsSettings.choose(GraphicsSettings.PRESETS[i])
		show_gfx.call())
	sharp.value_changed.connect(func(x: float):
		GraphicsSettings.set_value("scale", x / 100.0)
		show_gfx.call())
	fog.toggled.connect(func(on: bool):
		GraphicsSettings.set_value("fog", on)
		show_gfx.call())
	fps.item_selected.connect(func(i: int): GraphicsSettings.set_fps(GraphicsSettings.FPS_CAPS[i], GraphicsSettings.vsync))
	visibility_changed.connect(func():  # show the saved values each time it opens
		if visible:
			vol.set_value_no_signal(SoundSettings.volume * 100.0)
			mute.set_pressed_no_signal(SoundSettings.muted)
			ms.set_value_no_signal(Controls.mouse_scale * 100.0)
			sh.set_value_no_signal(SoundSettings.camera_shake * 100.0)
			show_gfx.call())


## A setting's name over its control.
func _row(parent: Node, text: String) -> VBoxContainer:
	var r := VBoxContainer.new()
	parent.add_child(r)
	UiKit.label(r, text, 16, UiKit.AMBER)
	return r
