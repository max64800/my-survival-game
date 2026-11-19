extends SceneTree
## Dumps every item, recipe and "where to get it" to JSON for the Crafting Wiki page.
##   godot --headless --path . --script res://tools/craft_wiki/dump.gd -- out=<file.json>
## Then: python tools/craft_wiki/build.py <file.json> <page.html>


func _init() -> void:
	var out := "user://craft_wiki.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out = a.trim_prefix("out=")
	var items := {}
	for id in Items.ids():
		var info: Dictionary = Items.info(id)
		var clean := {}
		for k in info:
			var v = info[k]
			if v is String or v is int or v is float or v is bool:
				clean[k] = v
		clean.name = Items.display_name(id)
		clean.kind = Items.kind(id)
		clean.color = Items.color(id).to_html(false)
		clean.short = Items.short_label(id)
		clean.has_icon = FileAccess.file_exists(Items.ICON_DIR + id + ".png")
		items[id] = clean
	var recipes := []
	for id in Recipes.LIST:
		var r: Dictionary = Recipes.LIST[id]
		recipes.append({id = id, station = r.station, level = int(r.get("level", 1)), inputs = r.inputs,
			output = r.output, count = r.count, seconds = r.get("seconds", 0), unlock = Recipes.unlock_hint(id)})
	var drops := {}  # item -> ["Cave Bat (always)", ...]
	for c in Monsters.LIST:
		for d in Monsters.info(c).get("drops", []):
			if not drops.has(d[0]):
				drops[d[0]] = []
			var who: String = Monsters.info(c).get("name", c)
			var line := "%s (%s)" % [who, "always" if d[2] >= 1.0 else "%d%%" % roundi(d[2] * 100)]
			if not line in drops[d[0]]:
				drops[d[0]].append(line)
	var gather := {}
	for i in Recipes.GATHER:
		gather[i] = Recipes.GATHER[i]
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({items = items, recipes = recipes, drops = drops, gather = gather, hand = Recipes.HAND}))
	f.close()
	print("wrote ", out, ": ", items.size(), " items, ", recipes.size(), " recipes")
	quit()
