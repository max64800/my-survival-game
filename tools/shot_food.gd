extends SceneTree
## Photographs the HUD with a dwarf who ate a Miner's Pie and drank a Moss Ale (F426 food slots). Usage:
## godot --audio-driver Dummy --path . -s tools/shot_food.gd -- out=<file.png>


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://food_hud.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.trim_prefix("out=")
	root.size = Vector2i(1600, 900)
	var auth := GameAuthority.new()
	root.add_child(auth)
	var body := Node3D.new()
	root.add_child(body)
	var ps := auth.add_player(1, body)
	ps.vitals.consume("dish_miners_pie")
	ps.vitals.consume("drink_moss_ale")
	ps.vitals.buffs[1].time_left = 200.0
	var bg := ColorRect.new()
	bg.color = Color(0.22, 0.2, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var hud: Hud = load("res://src/ui/hud.tscn").instantiate() if ResourceLoader.exists("res://src/ui/hud.tscn") else Hud.new()
	root.add_child(hud)
	hud.set_loading(false)
	for i in 30:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
