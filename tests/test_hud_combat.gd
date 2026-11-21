extends TestCase
## The owner's tower-rebuild play (Nov 21), the HUD part Claude 3 fixed: F504, F570, F571, F573, F574.


## F504 (said 2×): durability shows under the tool, inside the slot's frame but never touching it.
func test_durability_bar_sits_inside_the_frame() -> void:
	for s in [48.0, 64.0, 80.0]:
		var inset := roundf(s * 0.17)
		var r := Hud.wear_bar_rect(s)
		check(r.position.x > inset and r.position.y > inset, "%d px slot: clear of the frame's top-left rim" % s)
		check(r.end.x < s - inset and r.end.y < s - inset, "%d px slot: clear of the frame's bottom-right rim" % s)
		check(r.size.y >= 5.0, "%d px slot: thick enough to read (%.0f px)" % [s, r.size.y])
		check(r.position.y > s * 0.55, "%d px slot: under the picture's middle" % s)
	check(Hud.wear_color(1.0) != Hud.wear_color(0.1), "full and nearly broken look different")
	var src := FileAccess.get_file_as_string("res://src/ui/hud.gd")
	check(src.contains("var wears := not s.is_empty() and Durability.wears(s.id)\n"), "a brand-new tool shows its bar too")


## F570: the bandage cooldown is much darker, has a gold edge and counts the seconds down.
func test_bandage_cooldown_is_easy_to_see() -> void:
	check(Hud.COOLDOWN_SHADE.a >= 0.8, "a dark shade (was 0.68 grey)")
	var auth := GameAuthority.new()
	check_eq(Hud.cooldown_seconds(auth, "bandage"), 0.0, "nothing cooling: 0 s")
	auth._cooldown_started("bandage", 30.0)
	check_near(Hud.cooldown_seconds(auth, "bandage"), 30.0, 0.5, "just used: 30 s to count down")
	auth.free()


## F574: no progress bar on anything you mine. F573: the reload bar has no "Reloading" word.
func test_no_mining_bar_and_no_reloading_word() -> void:
	var src := FileAccess.get_file_as_string("res://src/ui/hud.gd")
	check(not src.contains("_dig_bar"), "the mining bar is gone")
	check(not src.contains('"Reloading'), "no \"Reloading\" text over the crossbow bar")
	check(src.contains('_reload_box.add_theme_stylebox_override("panel", UiKit.style("slot"'), "the reload bar sits in the wood-and-brass frame")


## F571: every weapon (and a tool or shield you can hit with) shows its damage; other things don't.
func test_weapons_show_their_damage() -> void:
	var sword := Combat.damage_text({id = "sword_copper"})
	check(sword.begins_with("Damage %d" % Combat.damage("sword", false, Items.tier("sword_copper"), {armor = 0})), "a sword: %s" % sword)
	check(Combat.damage_text({id = "mace_2h_copper"}).contains("heavy"), "a great weapon shows its heavy hit too")
	check(Combat.damage_text({id = "crossbow_stone"}).contains("aimed"), "the crossbow: hip and aimed shots")
	check(Combat.damage_text({id = "pickaxe_stone"}) != "", "a pickaxe hits too")
	check_eq(Combat.damage_text({id = "stone"}), "", "a rock shows no damage")
	var plus := Combat.damage_text({id = "sword_copper", up = 3})
	check(Upgrades.bonus({id = "sword_copper", up = 3}) <= 0.0 or plus != sword, "an upgraded one hits harder")
	var hud := FileAccess.get_file_as_string("res://src/ui/hud.gd")
	var craft := FileAccess.get_file_as_string("res://src/ui/craft_panel.gd")
	check(hud.contains("Combat.damage_text(s)"), "the slot's tooltip says it")
	check(craft.contains("Combat.damage_text({id = item})"), "the crafting card says it")
