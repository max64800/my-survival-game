extends TestCase
## F576 (owner, Nov 21): the K window opens on Perks; the Skills tab shows less; every ★ line is one line.


func test_perks_first_and_one_line_stars() -> void:
	var sp := SkillsPanel.new()
	check_eq(sp.tab, "perks", "the Perks tab opens first")
	var p := Progression.new()
	sp.ui = 1.0
	tree.root.add_child(sp)
	sp._tree.progress = p
	sp._show_skills(p)  # (refresh() needs a running game's player; the Skills tab only needs the progress)
	await tree.process_frame
	await tree.process_frame
	var tabs: Array = sp._tabs.keys()
	check_eq(tabs[0], "perks", "Perks is the first tab button")
	var card := sp.find_child("Skill_mining", true, false)
	check(card != null, "Mining has a card")
	if card == null:
		sp.queue_free()
		return
	check(not card.find_children("*", "RichTextLabel", true, false).size(), "no wrapping text blocks on a skill card")
	check((card as Control).tooltip_text.begins_with("Each level:"), "what each level gives is in the hover text")
	var stars := card.find_children("Star_*", "Label", true, false)
	check_eq(stars.size(), 4, "4 starred lines")
	for l in stars:
		check_eq((l as Label).get_line_count(), 1, "one line: %s" % (l as Label).text)
	# Every skill card (with its longest ★ line) still fits the page: no sideways scrolling, nothing cut off.
	var grid: GridContainer = sp._skills
	check(grid.get_combined_minimum_size().x <= SkillsPanel.PAGE.x - 30, "all cards fit across (%d px)" % grid.get_combined_minimum_size().x)
	check(grid.get_combined_minimum_size().y <= SkillsPanel.PAGE.y - 30, "all 14 fit down with no scrolling (%d px)" % grid.get_combined_minimum_size().y)
	sp.queue_free()

