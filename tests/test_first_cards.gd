extends TestCase
## F870 step 3 (owner, Nov 25: "teach with pictures, not words"): first-time picture cards, kept in the Notes tab (J),
## with a "Hints and cards" switch; no goal text, no first-steps line, no hammer lessons.

const PATH := "user://claude_test_first_cards_unit.cfg"
const SET := "user://claude_test_first_cards_settings.cfg"


func _fresh() -> FirstCards:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	return FirstCards.new(PATH)


## The first time something lands in your bag (or you get poisoned, or hungry) its card shows; never again.
func test_a_card_shows_once() -> void:
	var fc := _fresh()
	var ps := GameAuthority.PlayerState.new()
	check(fc.check(ps).is_empty(), "nothing new in an empty bag")
	ps.inventory.add("copper_ore", 2)
	check_eq(fc.check(ps), ["copper_ore"] as Array[String], "copper ore: its card")
	check(fc.check(ps).is_empty(), "only once")
	ps.inventory.add("crystal_amber", 1)
	ps.vitals.hunger = 10.0
	var got := fc.check(ps)
	check("crystal" in got and "hungry" in got, "any glow crystal = the crystal card, and hunger: %s" % [got])
	var again := FirstCards.new(PATH)
	check_eq(again.seen.size(), 3, "remembered on this computer (a new world doesn't show them again)")
	check(again.check(ps).is_empty(), "still only once after a restart")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Every card has a name, one line and a real picture.
func test_every_card_has_a_picture() -> void:
	for id in FirstCards.CARDS:
		var c: Array = FirstCards.CARDS[id]
		check(c[0] != "" and c[1] != "" and not c[1].contains("\n"), "%s: a name and one line" % id)
		check(FirstCards.picture(id) != null, "%s: a picture" % id)
	for id in FirstCards.ITEMS:
		check(FirstCards.CARDS.has(id), "%s: an item card has its words" % id)


## The switch in Settings turns the pop-ups off (the Notes still fill up), and it is remembered.
func test_hints_switch() -> void:
	var was := FirstCards.hints_on
	FirstCards.set_hints(false, SET)
	FirstCards.hints_on = true
	FirstCards.load_setting(SET)
	check(not FirstCards.hints_on, "off is remembered")
	FirstCards.hints_on = was
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SET))
	var panel := SettingsPanel.new()
	tree.root.add_child(panel)
	await tree.process_frame
	check(panel.find_child("Hints", true, false) is CheckButton, "a Hints and cards switch in Settings")
	var keys := SettingsPanel.CONTROLS.map(func(r): return r[0])
	check("J" in keys, "J is in the controls list")
	panel.free()


## J opens the skills window on the Notes tab: one card per thing you have met.
func test_notes_tab() -> void:
	var fc := _fresh()
	fc.meet("lantern")
	fc.meet("poison")
	var sp := SkillsPanel.new()
	sp.notes = fc
	tree.root.add_child(sp)
	await tree.process_frame
	sp.show_tab("notes")
	check(sp.find_child("NotesPage", true, false).visible, "the Notes page shows")
	check(sp.find_child("Note_lantern", true, false) != null and sp.find_child("Note_poison", true, false) != null, "a note per card seen")
	check(sp.find_child("Note_stone", true, false) == null, "nothing you haven't met")
	check_eq(Controls.key_name("toggle_notes"), "J", "J opens it")
	sp.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## The old teaching text is gone: no goal list, no first-steps line, no hammer lessons.
func test_no_old_teaching_text() -> void:
	var hud := FileAccess.get_file_as_string("res://src/ui/hud.gd")
	check(not hud.contains("_goals_label") and not hud.contains("Goals.next_steps"), "no Next steps goal text")
	check(not hud.contains("_update_first_steps"), "no first-steps line")
	check(not hud.contains("lessons.text()"), "no hammer lessons in the build panel")
	check(not ResourceLoader.exists("res://src/build/build_lessons.gd"), "the hammer lessons are gone")
	check(hud.contains("first_cards.check("), "the HUD looks for first times")
