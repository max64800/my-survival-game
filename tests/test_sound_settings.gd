extends TestCase
## The volume slider and Mute switch on the pause screen (feedback F15).

const TEST_PATH := "user://test_sound_settings.cfg"  ## never touches the real settings file


func test_mute_and_volume_change_the_sound_and_are_remembered() -> void:
	var bus := AudioServer.get_bus_index("Master")
	var old_v := SoundSettings.volume
	var old_m := SoundSettings.muted
	SoundSettings.set_muted(true, TEST_PATH)
	check(AudioServer.is_bus_mute(bus), "Mute really mutes")
	SoundSettings.set_muted(false, TEST_PATH)
	check(not AudioServer.is_bus_mute(bus), "and un-mutes")
	SoundSettings.set_volume(0.5, TEST_PATH)
	check_near(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.01, "half volume")
	# Remembered: change it in memory, then load the saved file back.
	SoundSettings.volume = 1.0
	SoundSettings.load_and_apply(TEST_PATH)
	check_near(SoundSettings.volume, 0.5, 0.001, "volume came back from the saved file")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	SoundSettings.volume = old_v
	SoundSettings.muted = old_m
	SoundSettings.apply()


## The Settings panel's mouse speed (F187) is remembered too, and kept in a sane range.
func test_mouse_speed_is_remembered() -> void:
	var old := Controls.mouse_scale
	SoundSettings.set_mouse_scale(1.6, TEST_PATH)
	Controls.mouse_scale = 1.0
	SoundSettings.load_and_apply(TEST_PATH)
	check_near(Controls.mouse_scale, 1.6, 0.001, "mouse speed came back from the saved file")
	SoundSettings.set_mouse_scale(50.0, TEST_PATH)
	check(Controls.mouse_scale <= 3.0, "never absurdly fast")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	Controls.mouse_scale = old
	SoundSettings.load_and_apply()


## The Settings panel's camera shake slider (F695, owner Nov 22) is remembered and kept between 0 and 1.
func test_camera_shake_is_remembered() -> void:
	var old := SoundSettings.camera_shake
	SoundSettings.set_camera_shake(0.3, TEST_PATH)
	SoundSettings.camera_shake = 1.0
	SoundSettings.load_and_apply(TEST_PATH)
	check_near(SoundSettings.camera_shake, 0.3, 0.001, "camera shake came back from the saved file")
	SoundSettings.set_camera_shake(5.0, TEST_PATH)
	check_eq(SoundSettings.camera_shake, 1.0, "never more than full")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	SoundSettings.camera_shake = old
	SoundSettings.load_and_apply()


## F761: four sliders (main, music, effects, voice); effects and voice each get their own bus and are remembered.
func test_effects_and_voice_volume_are_remembered() -> void:
	var old_e := SoundSettings.effects_volume
	var old_v := SoundSettings.voice_volume
	SoundSettings.set_effects_volume(0.5, TEST_PATH)
	SoundSettings.set_voice_volume(0.25, TEST_PATH)
	var eb := AudioServer.get_bus_index(SoundSettings.EFFECTS_BUS)
	var vb := AudioServer.get_bus_index(SoundSettings.VOICE_BUS)
	check(eb >= 0 and vb >= 0, "there is an Effects bus and a Voice bus")
	check_near(AudioServer.get_bus_volume_db(eb), linear_to_db(0.5), 0.01, "half effects volume")
	check_near(AudioServer.get_bus_volume_db(vb), linear_to_db(0.25), 0.01, "quarter voice volume")
	SoundSettings.effects_volume = 1.0
	SoundSettings.voice_volume = 1.0
	SoundSettings.load_and_apply(TEST_PATH)
	check_near(SoundSettings.effects_volume, 0.5, 0.001, "effects volume came back from the saved file")
	check_near(SoundSettings.voice_volume, 0.25, 0.001, "voice volume came back from the saved file")
	var panel := SettingsPanel.new()
	tree.root.add_child(panel)
	await tree.process_frame
	check(panel.find_child("EffectsVolume", true, false) != null and panel.find_child("VoiceVolume", true, false) != null,
			"the Audio tab shows the Effects and Voice sliders")
	panel.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	SoundSettings.effects_volume = old_e
	SoundSettings.voice_volume = old_v
	SoundSettings.load_and_apply()
