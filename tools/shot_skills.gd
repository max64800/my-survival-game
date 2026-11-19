extends SceneTree
## Photographs the skills window with a sample dwarf (level 18, some perks). Usage:
## godot --audio-driver Dummy --path . -s tools/shot_skills.gd -- out=<file.png>


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://skills_window.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.trim_prefix("out=")
	root.size = Vector2i(1600, 900)
	var auth := GameAuthority.new()
	root.add_child(auth)
	var body := Node3D.new()
	root.add_child(body)
	var ps := auth.add_player(1, body)
	ps.progress.add_xp(Progression.total_xp_for_level(18))
	for s in ["mining", "sword", "running", "crafting", "cooking"]:
		ps.progress.skill_level[s] = {"mining": 34, "sword": 27, "running": 18, "crafting": 22, "cooking": 12}[s]
	for id in ["thick_skin", "thick_skin", "big_lungs", "stone_skin", "warriors_grip", "warriors_grip", "light_feet",
			"deep_pockets", "ore_smasher", "prospector", "shoulder_to_shoulder", "war_horn"]:
		ps.progress.buy_perk(id)
	ps.progress.perks["poison_blood"] = 1
	ps.progress.perks["stone_skin"] = 1
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var sp := SkillsPanel.new()
	sp.peer_id = 1
	root.add_child(sp)
	sp.refresh()
	for i in 8:
		await process_frame
	sp.position = (Vector2(root.size) - sp.size) / 2.0
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
