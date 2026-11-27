extends TestCase
## F870 step 1 (owner, Nov 25: "the screen is all over the place, too much text"): the HUD clean-up.


## The controls list, the skills corner, the lantern bar and "Well fed" are gone from the game screen.
func test_the_screen_has_less_text() -> void:
	var src := FileAccess.get_file_as_string("res://src/ui/hud.gd")
	check(not src.contains("WASD walk"), "no controls list on the screen")
	check(not src.contains("_level_label"), "no skills / level text in the top-right corner")
	check(not src.contains("_fuel_bar"), "no lantern bar")
	check(not src.contains('"Well fed"'), "no Well fed word (the hunger dial shows it)")
	check(src.contains("skill_popup.watch("), "the skill pop-up is fed every frame")


## The controls list now lives in the settings page, and the lantern hint names the real key.
func test_controls_are_in_the_settings_page() -> void:
	var panel := SettingsPanel.new()
	tree.root.add_child(panel)
	await tree.process_frame
	check(panel.find_child("ControlsList", true, false) != null, "a Controls list in Settings")
	var keys := SettingsPanel.CONTROLS.map(func(r): return r[1])
	check("refill the lantern" in keys and "skills" in keys and "map" in keys, "it lists the main keys")
	panel.free()
	check_eq(Controls.key_name("refill_lantern"), OS.get_keycode_string(Controls.KEYS.refill_lantern[0]), "the refill key comes from the key list")
	check_eq(Controls.key_name("refill_lantern"), "L", "refill is hold L (a tap puts the lantern away)")


## F880 (owner, Nov 25): a skill pops up (with its picture) only when it LEVELS UP, not on every bit of XP; a level up shows too.
func test_skill_pops_up_when_it_grows() -> void:
	var pop := SkillPopup.new()
	tree.root.add_child(pop)
	var p := Progression.new()
	pop.watch(p, 0.016)
	check(not pop.visible, "hidden at the start")
	p.add_xp(1, "jumping")
	pop.watch(p, 0.016)
	check(not pop.visible, "a bit of XP shows nothing (was 'Jumping 0 +1')")
	p.add_xp(Progression.skill_xp_to_next(0), "mining")
	pop.watch(p, 0.016)
	check(pop.visible and pop.text() == "Mining 1!", "a skill level up shows: '%s'" % pop.text())
	for i in 250:  # 4 s, nothing new
		pop.watch(p, 0.016)
	check(not pop.visible, "gone again after ~2.5 s")
	p.add_xp(Progression.xp_to_next(p.level), "")
	pop.watch(p, 0.016)
	check(pop.text().begins_with("Level 2"), "a level up shows: '%s'" % pop.text())
	for s in Progression.SKILL_INFO:
		check(SkillPopup.icon(s) != null, "%s has a picture" % s)
	pop.free()


## F870 step 2: a perfect parry has no words: a spark star + a flash + a ringing blade; a normal block is a dull thud.
func test_parry_is_a_spark_not_words() -> void:
	check(not FileAccess.get_file_as_string("res://src/combat/dwarf_fight.gd").contains('"Perfect parry!"'), "no Perfect parry word")
	var main_src := FileAccess.get_file_as_string("res://src/main.gd")
	check(not main_src.contains('"Dodged!"') and not main_src.contains('"Blocked %s'), "no Blocked / Dodged words")
	check(not Sfx._variants("parry_ring").is_empty(), "a ringing blade sound")
	check(not Sfx._variants("block_thud").is_empty(), "a dull thud for a block")
	var at := Node3D.new()
	tree.root.add_child(at)
	var flash := Fx.parry_star(at, Vector3(0, 1, 0), Vector3.FORWARD)
	var sparks := at.get_children().filter(func(c): return c is CPUParticles3D)
	check(sparks.size() >= 3, "a star of sparks (and two streaks)")
	check(flash != null and flash.light_energy > 0.0, "a flash of light")
	at.free()
