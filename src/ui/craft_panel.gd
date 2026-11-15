class_name CraftPanel
extends PanelContainer
## The crafting list: by hand (shown next to the bag) or at a station (press E at it).
## Only recipes you've unlocked appear. Missing ingredients show in red.

var peer_id := 1
var station: Station = null  ## null = crafting by hand
var _title: Label
var _status: Label
var _list: VBoxContainer


func _ready() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.05, 0.05, 0.9)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(12)
	add_theme_stylebox_override("panel", bg)
	custom_minimum_size = Vector2(430, 0)
	var box := VBoxContainer.new()
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	box.add_child(_title)
	_status = Label.new()
	_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.5))
	box.add_child(_status)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(410, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func open_for(st: Station) -> void:
	station = st
	visible = true
	refresh()


func refresh() -> void:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null or not is_inside_tree():
		return
	if station and station.kind == "rune_slab":
		_rune_slab(ps, auth)
		return
	if station and station.kind == "gem_bench":
		_gem_bench(ps)
		return
	var where := Recipes.HAND if station == null else station.kind
	_title.text = "Craft by hand" if station == null else Items.display_name(station.kind)
	_status.text = station.busy_text() if station else ""
	if station and Station.EXTRAS.has(station.kind):
		# Station levels (building polish spec §3): show the level and how to raise it.
		var nxt := station.next_extra()
		_title.text += "  ·  level %d of %d" % [station.level(), Station.max_level(station.kind)]
		if nxt != "" and _status.text == "":
			_status.text = "Place a %s within 4 m to reach level %d." % [Items.display_name(nxt), station.level() + 1]
	if station and station.kind in AutoSmelt.KINDS and _status.text == "":
		_status.text = "Works by itself: put %s in a chest within 5 m." % 			("wood" if station.kind == "kiln" else "ore and coal (or wood)")
	for c in _list.get_children():
		c.queue_free()
	var shown := 0
	for id in Recipes.for_station(where):
		if not Recipes.is_unlocked(id, ps.seen, auth.taught_recipes()):
			continue
		shown += 1
		_list.add_child(_row(id, ps.inventory))
	if shown == 0:
		var l := Label.new()
		l.text = "Nothing to make here yet. Explore and collect more!"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(l)
	if station and station.kind in ["workbench", "anvil"]:
		_upgrade_rows(ps.inventory)


## Gear upgrades (building polish spec §4): everything you carry or wear that this station can improve.
func _upgrade_rows(inv: Inventory) -> void:
	var heading := Label.new()
	heading.text = "Upgrade gear (+15% each step, up to +3)"
	heading.add_theme_font_size_override("font_size", 17)
	_list.add_child(heading)
	var any := false
	for i in inv.slots.size():
		var s := inv.get_slot(i)
		if s.is_empty() or not Upgrades.can_upgrade(s.id) or Upgrades.station_for(s.id) != station.kind:
			continue
		any = true
		var row := HBoxContainer.new()
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost := Upgrades.next_cost(s)
		var ok := not cost.is_empty() and station.level() >= Upgrades.needed_level(s)
		var parts := []
		for item in cost:
			var have := inv.count_of(item)
			var col := "white" if have >= cost[item] else "#ff7070"
			ok = ok and have >= cost[item]
			parts.append("[color=%s]%d/%d %s[/color]" % [col, mini(have, cost[item]), cost[item], Items.display_name(item)])
		if cost.is_empty():
			parts = ["fully upgraded"]
		elif station.level() < Upgrades.needed_level(s):
			parts.append("[color=#ff7070]needs station level %d[/color]" % Upgrades.needed_level(s))
		text.text = "[b]%s[/b]\n[font_size=13]%s[/font_size]" % [Upgrades.display_name(s), ", ".join(parts)]
		row.add_child(text)
		var b := Button.new()
		b.text = "Upgrade"
		b.disabled = not ok
		b.custom_minimum_size = Vector2(80, 0)
		var slot_index := i
		b.pressed.connect(func():
			GameAuthority.instance.ask_upgrade(slot_index, station.station_id)
			get_tree().create_timer(0.15).timeout.connect(refresh))
		row.add_child(b)
		_list.add_child(row)
	if not any:
		var l := Label.new()
		l.text = "Nothing to upgrade here. (%s)" % ("copper and silver gear" if station.kind == "anvil" else "stone, wood, leather and shell gear")
		_list.add_child(l)


func _row(recipe_id: String, inv: Inventory) -> Control:
	var r := Recipes.get_recipe(recipe_id)
	var row := HBoxContainer.new()
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var parts := []
	var ok := true
	for item in r.inputs:
		var have := inv.count_of(item)
		var need: int = r.inputs[item]
		var col := "white" if have >= need else "#ff7070"
		if have < need:
			ok = false
		parts.append("[color=%s]%d/%d %s[/color]" % [col, mini(have, need), need, Items.display_name(item)])
	if r.get("fuel", 0) > 0:
		parts.append("+ %d wood fuel" % r.fuel)
	var out := Items.display_name(r.output) + ("" if r.count == 1 else " ×%d" % r.count)
	var timer := "" if r.get("seconds", 0) == 0 else "  (%ds)" % r.seconds
	text.text = "[b]%s[/b]%s\n[font_size=13]%s[/font_size]" % [out, timer, ", ".join(parts)]
	row.add_child(text)
	var b := Button.new()
	b.text = "Make"
	b.disabled = not ok
	b.custom_minimum_size = Vector2(70, 0)
	b.pressed.connect(func():
		GameAuthority.instance.ask_craft(recipe_id, station.station_id if station else 0)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	row.add_child(b)
	return row


## The Gem Bench (combat doc 4.4): every item with sockets, its gems, and the gems you carry.
func _gem_bench(ps: GameAuthority.PlayerState) -> void:
	_title.text = "Gem Bench"
	_status.text = "Socketing is free. Taking a gem out costs 5 blue glow crystals."
	for c in _list.get_children():
		c.queue_free()
	var carried := []
	for s in ps.inventory.slots:
		if not s.is_empty() and Gems.gem_of(s.id) != "" and not carried.has(Gems.gem_of(s.id)):
			carried.append(Gems.gem_of(s.id))
	var any := false
	for i in ps.inventory.slots.size():
		var s := ps.inventory.get_slot(i)
		if s.is_empty() or Gems.socket_count(s.id) == 0:
			continue
		any = true
		var gems: Array = s.get("gems", [])
		var l := Label.new()
		l.text = "%s  (%d of %d sockets used)" % [Items.display_name(s.id), gems.size(), Gems.socket_count(s.id)]
		l.add_theme_font_size_override("font_size", 16)
		_list.add_child(l)
		var row := HBoxContainer.new()
		_list.add_child(row)
		for gi in gems.size():
			var b := Button.new()
			b.text = "Take out %s" % Gems.NORMAL.get(gems[gi], {}).get("name", gems[gi])
			var slot_i := i
			var idx := gi
			b.pressed.connect(func():
				GameAuthority.instance.ask_unsocket(slot_i, idx)
				get_tree().create_timer(0.15).timeout.connect(refresh))
			row.add_child(b)
		if gems.size() < Gems.socket_count(s.id):
			for g in carried:
				if not Gems.NORMAL.has(g):
					continue
				var b := Button.new()
				b.text = "+ %s" % Gems.NORMAL[g].name
				b.tooltip_text = str(Gems.NORMAL[g][Gems.slot_kind(s.id)])
				var slot_i := i
				var gem: String = g
				b.pressed.connect(func():
					GameAuthority.instance.ask_socket(slot_i, gem)
					get_tree().create_timer(0.15).timeout.connect(refresh))
				row.add_child(b)
	if not any:
		var l := Label.new()
		l.text = "Copper and better weapons, shields and pickaxes have gem sockets. Stone ones don't."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(l)


## The Rune Slab: carve runes you carry. Each colour helps one skill branch; a full set gives a big perk.
func _rune_slab(ps: GameAuthority.PlayerState, auth: GameAuthority) -> void:
	_title.text = "Rune Slab"
	_status.text = ""
	for c in _list.get_children():
		c.queue_free()
	var slab := auth.rune_slab
	for colour in RuneSlab.COLOURS:
		var l := Label.new()
		var n_m := RuneSlab.runes_in_set(colour + "_m").filter(func(r): return slab.carved_runes.has(r)).size()
		l.text = "%s (%s): %d of 5 carved%s · shards %d" % [colour.capitalize(), RuneSlab.COLOURS[colour].capitalize(), n_m,
			"  ★ " + RuneSlab.SET_PERKS[colour + "_m"].get_slice(":", 0) if slab.is_set_done(colour + "_m") else "", slab.shards[colour]]
		_list.add_child(l)
	var any := false
	for s in ps.inventory.slots:
		if s.is_empty() or not s.id.begins_with("rune_"):
			continue
		any = true
		var row := HBoxContainer.new()
		var t := Label.new()
		var rid: String = s.id.trim_prefix("rune_")
		var effect: Dictionary = RuneSlab.RUNES.get(rid, {})
		t.text = "%s ×%d — %s%s" % [Items.display_name(s.id), s.count, ("teaches " + str(effect.recipe)) if effect.has("recipe") else str(effect),
			" (already carved: becomes a shard)" if slab.carved_runes.has(rid) else ""]
		t.autowrap_mode = TextServer.AUTOWRAP_WORD
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(t)
		var b := Button.new()
		b.text = "Carve"
		var item: String = s.id
		b.pressed.connect(func():
			GameAuthority.instance.ask_carve(item)
			get_tree().create_timer(0.15).timeout.connect(refresh))
		row.add_child(b)
		_list.add_child(row)
	if not any:
		var l := Label.new()
		l.text = "You carry no runes. Find them at rune shrines, in ruins, and on pack leaders."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(l)
