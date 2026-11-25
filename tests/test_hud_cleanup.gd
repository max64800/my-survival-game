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
	check_eq(Controls.key_name("refill_lantern"), "R", "refill is R (L puts the lantern away)")


## A skill pops up for ~2 s only when it grows, then hides; a level up shows too.
func test_skill_pops_up_when_it_grows() -> void:
	var pop := SkillPopup.new()
	tree.root.add_child(pop)
	var p := Progression.new()
	pop.watch(p, 0.016)
	check(not pop.visible, "hidden at the start")
	p.add_xp(6, "mining")
	pop.watch(p, 0.016)
	check(pop.visible, "shows after mining XP")
	check(pop.text().begins_with("Mining 0") and pop.text().ends_with("+6"), "says the skill and the gain: '%s'" % pop.text())
	p.add_xp(4, "mining")
	pop.watch(p, 0.016)
	check(pop.text().ends_with("+10"), "gains add up while it's showing: '%s'" % pop.text())
	for i in 200:  # 3.2 s, nothing gained
		pop.watch(p, 0.016)
	check(not pop.visible, "gone again after ~2 s")
	p.add_xp(Progression.xp_to_next(p.level), "")
	pop.watch(p, 0.016)
	check(pop.text().begins_with("Level 2"), "a level up shows: '%s'" % pop.text())
	check_eq(SkillPopup._gain([0, Progression.skill_xp_to_next(0) - 5], 1, 3), 8, "XP over a skill level-up is counted right")
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
