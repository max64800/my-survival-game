extends SceneTree
## Writes a ready-made blueprint as JSON (for making 3D previews of it in Blender).
##   godot --headless --audio-driver Dummy --path . -s res://tools/dump_blueprint.gd -- delvers_hut out.json


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var bp := BlueprintLibrary.make(args[0] if args.size() > 0 else "delvers_hut")
	var f := FileAccess.open(args[1] if args.size() > 1 else "user://blueprint.json", FileAccess.WRITE)
	f.store_string(bp.to_json())
	f.close()
	var total := {}  # what the whole building costs, by item name
	for p in bp.pieces:
		var c := Pieces.cost(p.id, p.mat)
		for item in c:
			var nm := Items.display_name(item)
			total[nm] = total.get(nm, 0) + c[item]
	print("COST ", JSON.stringify(total))
	quit()
