extends TestCase
## F551 (owner, Nov 21): "I hate the sound when you take damage (falling, any hit on you)". Now an old-world body
## thump made from real recordings (leather, cloth, belt gear: tools/art/make_hurt_sound.py), not the hard impact.


func test_taking_damage_sounds_old_world() -> void:
	var takes := Sfx._variants("hurt")
	check_eq(takes.size(), 4, "four takes of the hurt sound, so it never repeats")
	for s in takes:
		check(s.get_length() > 0.2 and s.get_length() < 1.0, "a short thump (%.2f s)" % s.get_length())
	var src := FileAccess.get_file_as_string("res://src/net/game_authority.gd")
	check(not src.contains('Sfx.ui("hit_heavy"'), "the old hard impact no longer plays when you are hurt")
	check(src.contains('Sfx.ui("hurt", -2.0)'), "a hit on you plays the hurt sound")
	check(src.contains('Sfx.ui("hurt", 0.0, 0.85)'), "a fall plays it lower and louder")
	var credits := FileAccess.get_file_as_string("res://CREDITS.md")
	check(credits.contains("hurt_0..3"), "the sound is in CREDITS.md")
