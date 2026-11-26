class_name SettingsPanel
extends PanelContainer
## The Settings panel (owner F187 mock-up): sound volume, mute, mouse speed and graphics (owner, Nov 19), remembered on this
## computer (SoundSettings). Used by the start screen and the Escape menu. A Music slider sits under the main volume.
## F876 (owner, Nov 25: "like in normal games"): tabs along the top: Display, Audio, Controls, Gameplay.

const TABS := [["display", "Display"], ["audio", "Audio"], ["controls", "Controls"], ["gameplay", "Gameplay"]]
var tab := "display"
var _pages := {}  ## tab id -> its page
var _tab_buttons := {}


func _ready() -> void:
	UiKit.panel(self)
	custom_minimum_size = Vector2(620, 560)  # the same size on every tab (it doesn't jump when you switch)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	UiKit.title(box, "Settings")
	var bar := HBoxContainer.new()
	bar.name = "Tabs"
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 8)
	box.add_child(bar)
	for t in TABS:
		var b := UiKit.dark_button(Button.new(), 18)
		b.name = "Tab_" + t[0]
		b.text = t[1]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(140, 42)
		b.pressed.connect(func(): show_tab(t[0]))
		bar.add_child(b)
		_tab_buttons[t[0]] = b
	UiKit.divider(box)
	for t in TABS:
		var page := VBoxContainer.new()
		page.name = "Page_" + t[0]
		page.add_theme_constant_override("separation", 12)
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(page)
		_pages[t[0]] = page
	var v: VBoxContainer = _pages.audio
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
	for e in [["Effects", "EffectsVolume", SoundSettings.effects_volume, SoundSettings.set_effects_volume],
			["Voice", "VoiceVolume", SoundSettings.voice_volume, SoundSettings.set_voice_volume]]:  # F761
		var sl := UiKit.slider(HSlider.new())
		sl.name = e[1]
		sl.min_value = 0
		sl.max_value = 100
		sl.step = 5
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.set_value_no_signal(e[2] * 100.0)
		var setter: Callable = e[3]
		sl.value_changed.connect(func(x: float): setter.call(x / 100.0))
		_row(v, e[0]).add_child(sl)
	var mute := CheckButton.new()
	mute.name = "Mute"
	mute.text = "Mute"
	mute.focus_mode = Control.FOCUS_NONE
	mute.add_theme_color_override("font_color", UiKit.TEXT)
	mute.set_pressed_no_signal(SoundSettings.muted)
	mute.toggled.connect(func(m: bool): SoundSettings.set_muted(m))
	v.add_child(mute)
	v = _pages.controls
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
	_build_controls(v)
	v = _pages.gameplay
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
	var hints := CheckButton.new()  # F870: the first-time picture cards (the Notes in J fill up either way)
	hints.name = "Hints"
	hints.text = "Hints and cards"
	hints.focus_mode = Control.FOCUS_NONE
	hints.add_theme_color_override("font_color", UiKit.TEXT)
	hints.set_pressed_no_signal(FirstCards.hints_on)
	hints.toggled.connect(func(on: bool): FirstCards.set_hints(on))
	v.add_child(hints)
	UiKit.label(v, "Hints and cards: a picture card the first time you meet something new (they are all kept in Notes, J)", 13, UiKit.DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v = _pages.display
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
			hints.set_pressed_no_signal(FirstCards.hints_on)
			show_gfx.call())
	show_tab(tab)


## Shows one tab's page (F876).
func show_tab(which: String) -> void:
	tab = which
	for k in _pages:
		_pages[k].visible = k == which
		var b: Button = _tab_buttons[k]
		b.add_theme_color_override("font_color", UiKit.AMBER if k == which else UiKit.DIM)
		b.modulate = Color.WHITE if k == which else Color(0.78, 0.78, 0.78)


## F870 (owner, Nov 25: "the screen is all over the place"): the controls list lives only here, not on the game screen.
const CONTROLS := [
	["W A S D", "walk"], ["Shift", "run"], ["Space", "jump"], ["Ctrl", "dodge roll"], ["Mouse", "look"],
	["Left click", "dig, harvest, attack"], ["Right click", "eat, place, block"], ["E", "use, open, pick up"],
	["1 - 9", "hotbar"], ["Wheel", "zoom"], ["F", "draw / put away weapon"],
	["R", "refill the lantern"], ["L", "put the lantern away / out"],
	["Tab", "bag + crafting"], ["K", "skills"], ["J", "notes"], ["M", "map"], ["B", "build menu (hammer)"],
	["V", "blueprints (hammer)"], ["Q", "turn piece (hammer)"], ["Z  G  T", "perks"],
	["F5", "quick save"], ["Esc", "pause"],
]


func _build_controls(parent: Node) -> void:
	var scroll := ScrollContainer.new()  # (F876: big and easy to read; scrolls if the screen is small)
	scroll.name = "ControlsList"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4  # two columns of key + what it does
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	var half := ceili(CONTROLS.size() / 2.0)
	for i in half:
		for row in [CONTROLS[i], CONTROLS[i + half] if i + half < CONTROLS.size() else []]:
			if row.is_empty():
				continue
			var key := UiKit.label(grid, row[0], 18, UiKit.AMBER)
			key.custom_minimum_size.x = 100
			var what := UiKit.label(grid, row[1], 17, UiKit.TEXT)
			what.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## A setting's name over its control.
func _row(parent: Node, text: String) -> VBoxContainer:
	var r := VBoxContainer.new()
	parent.add_child(r)
	UiKit.label(r, text, 16, UiKit.AMBER)
	return r
