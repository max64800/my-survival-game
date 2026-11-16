class_name SettingsPanel
extends PanelContainer
## The Settings panel (owner F187 mock-up): sound volume, mute and mouse speed, remembered on this
## computer (SoundSettings). Used by the start screen and the Escape menu. The game has no music yet,
## so there is one volume for everything; Music / Effects sliders come when music does.


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
	visibility_changed.connect(func():  # show the saved values each time it opens
		if visible:
			vol.set_value_no_signal(SoundSettings.volume * 100.0)
			mute.set_pressed_no_signal(SoundSettings.muted)
			ms.set_value_no_signal(Controls.mouse_scale * 100.0))


## A setting's name over its control.
func _row(parent: Node, text: String) -> VBoxContainer:
	var r := VBoxContainer.new()
	parent.add_child(r)
	UiKit.label(r, text, 16, UiKit.AMBER)
	return r
