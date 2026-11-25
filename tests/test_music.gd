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


func test_music_blends_and_waits() -> void:
	# F879 (owner, Nov 25): tracks fade into each other, and a 5 s trip into a cave doesn't swap the music.
	check(Music.hold_time("explore", "cave") > 5.0, "a quick cave visit keeps the outside music")
	check(Music.hold_time("cave", "explore") > 5.0, "a quick step outside keeps the cave music")
	check_eq(Music.hold_time("explore", "combat"), 0.0, "a fight starts its music at once")
	check_eq(Music.hold_time("cave", "boss"), 0.0, "so does a boss")
	check(Music.hold_time("combat", "explore") < Music.hold_time("explore", "cave"), "after a fight the calm comes back sooner")
	check_eq(Music.hold_time("", "explore"), 0.0, "the first music plays at once")
	# Halfway through the blend both tracks are still clearly heard (the old fade had the new one at -40 dB).
	check(Music.fade_db(0.5) > -7.0, "half way: both well heard (%.1f dB)" % Music.fade_db(0.5))
	check_eq(Music.fade_db(0.0), -80.0, "silent at the end")
	# Run it for a bit (no game: it's "explore"): one track starts, fades up, and nothing breaks.
	var m := Music.new()
	tree.root.add_child(m)
	for i in 20:
		m._process(0.5)
	check_eq(m.state, "explore", "outside music plays")
	check(m._cur != null and m._cur.volume_db > -1.0, "faded all the way up")
	m.queue_free()
