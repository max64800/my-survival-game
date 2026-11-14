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
