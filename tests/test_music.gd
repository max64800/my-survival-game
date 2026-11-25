extends TestCase
## The music (owner, Nov 25): every file loads, the right kind plays, the Music slider is remembered.

const TEST_PATH := "user://test_music.cfg"  ## never touches the real settings file


func test_every_track_and_jingle_loads() -> void:
	for group in Music.TRACKS:
		check(not Music.TRACKS[group].is_empty(), "%s has music" % group)
		for t in Music.TRACKS[group]:
			check(Music.stream(t) != null, "%s loads" % t)
	for s in Music.STINGERS:
		check(Music.stream("stinger_" + s) != null, "jingle %s loads" % s)


func test_the_right_music_for_the_moment() -> void:
	check_eq(Music.state_for(false, false, false), "explore", "walking outside")
	check_eq(Music.state_for(true, false, false), "cave", "in a cave")
	check_eq(Music.state_for(true, false, true), "combat", "fighting")
	check_eq(Music.state_for(false, true, true), "boss", "a boss beats a fight")
	check_eq(Music.ruin_stinger("Tower"), "ruin_small", "small ruin")
	check_eq(Music.ruin_stinger("Brewhall"), "ruin_medium", "medium ruin")
	check_eq(Music.ruin_stinger("Spire"), "ruin_large", "large ruin")


func test_music_volume_is_remembered() -> void:
	var old := SoundSettings.music_volume
	SoundSettings.set_music_volume(0.5, TEST_PATH)
	var bus := AudioServer.get_bus_index(SoundSettings.MUSIC_BUS)
	check(bus >= 0, "there is a Music bus")
	check_near(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.01, "half music volume")
	SoundSettings.music_volume = 1.0
	SoundSettings.load_and_apply(TEST_PATH)
	check_near(SoundSettings.music_volume, 0.5, 0.001, "it came back from the saved file")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	SoundSettings.music_volume = old
	SoundSettings.apply()
