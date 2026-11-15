class_name CraftPanel
extends PanelContainer
## The crafting list: by hand (shown next to the bag) or at a station (press E at it).
## Only recipes you've unlocked appear. Missing ingredients show in red.

var peer_id := 1
var station: Station = null  ## null = crafting by hand
var _title: Label
var _status: Label
var _list: VBoxContainer
## Making something takes a moment (owner, Nov 15, F92): a bar fills while the dwarf works.
## Walking away cancels it; nothing is used up until it's done.
var _making := {}  ## {id, left, total, from (where you stood)}
var _bar: ProgressBar
var _work_beat := 0.0
const CANCEL_DISTANCE := 0.6
## Recipes sorted into tabs (owner F127) by what they make.
const TABS := ["Tools", "Weapons", "Armor", "Stations", "Materials", "Food"]
var _tab := ""
var _tabs: HBoxContainer
var _scroll: ScrollContainer
## How many to make with one click (owner F129): 1, 5, 10 or -1 = as many as you can.
var amount := 1
var _amount_row: HBoxContainer


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
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.show_percentage = false
	_bar.visible = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.75, 0.35)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 4)
	box.add_child(_tabs)
	_amount_row = HBoxContainer.new()
	box.add_child(_amount_row)
	var how := Label.new()
	how.text = "Make:"
	_amount_row.add_child(how)
	for a in [1, 5, 10, -1]:
		var b := Button.new()
		b.name = "Amount%d" % a
		b.text = "×%d" % a if a > 0 else "All"
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.button_pressed = a == amount
		var pick: int = a
		b.pressed.connect(func(): amount = pick; _paint_amounts())
		_amount_row.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(410, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_scroll = scroll
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func _paint_amounts() -> void:
	for b in _amount_row.get_children():
		if b is Button:
			(b as Button).set_pressed_no_signal(b.name == "Amount%d" % amount)


## Which tab a recipe goes in, by the kind of thing it makes.
static func tab_of(recipe_id: String) -> String:
	match Items.kind(Recipes.get_recipe(recipe_id).output):
		"pickaxe", "axe", "hammer", "lantern", "lens", "waterskin", "tonic", "throw", "horn":
			return "Tools"
		"weapon", "shield", "ammo":
			return "Weapons"
		"wear", "pack":
			return "Armor"
		"station", "chest":
			return "Stations"
		"food", "drink":
			return "Food"
	return "Materials"


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
	if not _making.is_empty():
		_status.text = "Making %s…" % Items.display_name(Recipes.get_recipe(_making.id).output)
	if station and Station.EXTRAS.has(station.kind):
		# Station levels (building polish spec §3): show the level and how to raise it.
		var nxt := station.next_extra()
		_title.text += "  ·  level %d of %d" % [station.level(), Station.max_level(station.kind)]
		if nxt != "" and _status.text == "":
			_status.text = "Place a %s within 4 m to reach level %d." % [Items.display_name(nxt), station.level() + 1]
	if station and station.kind in AutoSmelt.KINDS and _status.text == "":
		_status.text = "Works by itself: put %s in a chest within 5 m." % 			("wood" if station.kind == "kiln" else "ore and coal (or wood)")
	var keep_scroll := _scroll.scroll_vertical  # the list stays where it was after you make something (F129)
	for c in _list.get_children():
		c.queue_free()
	for c in _tabs.get_children():
		c.queue_free()
	# Only recipes you've unlocked, in tabs (owner F127). Missing materials still show in red, with where to get them.
	var by_tab := {}
	for id in Recipes.for_station(where):
		if Recipes.is_unlocked(id, ps.seen, auth.taught_recipes()):
			by_tab[tab_of(id)] = by_tab.get(tab_of(id), []) + [id]
	if not by_tab.has(_tab):
		_tab = ""
		for t in TABS:
			if by_tab.has(t):
				_tab = t
				break
	for t in TABS:
		if not by_tab.has(t):
			continue
		var tb := Button.new()
		tb.text = "%s (%d)" % [t, by_tab[t].size()]
		tb.toggle_mode = true
		tb.button_pressed = t == _tab
		tb.focus_mode = Control.FOCUS_NONE
		var pick: String = t
		tb.pressed.connect(func(): _tab = pick; _scroll.scroll_vertical = 0; refresh())
		_tabs.add_child(tb)
	var shown := 0
	for id in by_tab.get(_tab, []):
		shown += 1
		_list.add_child(_row(id, ps.inventory))
	_scroll.set_deferred("scroll_vertical", keep_scroll)
	if shown == 0:
		var l := Label.new()
		l.text = "Nothing to make here yet. Explore and collect more!"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(l)
	if station and station.kind in ["workbench", "anvil"]:
		_upgrade_rows(ps.inventory)


## How long making it takes: 1 s for small things up to 3 s for big ones (by how much goes in).
## Recipes that already run on a station's own timer (smelting, cooking) start right away.
static func craft_time(recipe_id: String) -> float:
	var r := Recipes.get_recipe(recipe_id)
	if r.get("seconds", 0) > 0:
		return 0.0
	var amount := 0
	for item in r.inputs:
		amount += int(r.inputs[item])
	return clampf(amount / 6.0, 1.0, 3.0)


## How many of a recipe you can make right now with what you carry.
static func can_make_count(recipe_id: String, inv: Inventory) -> int:
	var r := Recipes.get_recipe(recipe_id)
	var most := 999
	for item in r.inputs:
		most = mini(most, inv.count_of(item) / maxi(1, int(r.inputs[item])))
	return most


func start_making(recipe_id: String, count: int = -2) -> void:
	if not _making.is_empty():
		return
	if count == -2:  # from the Make button: the chosen amount (owner F129)
		var me_ps := GameAuthority.instance.get_player(peer_id) if GameAuthority.instance else null
		var can := can_make_count(recipe_id, me_ps.inventory) if me_ps else 1
		count = can if amount < 0 else mini(amount, maxi(can, 1))
	count = maxi(count, 1)
	var t := craft_time(recipe_id)
	if t <= 0.0:
		for i in count:
			_finish(recipe_id)
		return
	var me := _me()
	_making = {id = recipe_id, left = t, total = t, from = me.global_position if me else Vector3.ZERO, more = count - 1}
	_work_beat = 0.0
	_bar.visible = true
	_bar.max_value = t
	_bar.value = 0.0
	_status.text = "Making %s…%s" % [Items.display_name(Recipes.get_recipe(recipe_id).output), "" if count <= 1 else "  (%d more after this)" % (count - 1)]
	refresh()


func cancel_making(why: String) -> void:
	if _making.is_empty():
		return
	_making = {}
	_bar.visible = false
	_status.text = why
	refresh()


func _finish(recipe_id: String) -> void:
	GameAuthority.instance.ask_craft(recipe_id, station.station_id if station else 0)
	get_tree().create_timer(0.15).timeout.connect(refresh)


func _me() -> Node3D:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	return ps.node if ps else null


func _process(delta: float) -> void:
	if _making.is_empty():
		return
	var me := _me()
	if not visible or me == null:
		cancel_making("")
		return
	if me.global_position.distance_to(_making.from) > CANCEL_DISTANCE:
		cancel_making("You walked away: nothing was used up.")
		return
	_work_beat -= delta
	if _work_beat <= 0.0 and me is Dwarf:
		_work_beat = 0.7
		(me as Dwarf).model.react("use")  # hands busy at the work
	_making.left -= delta
	_bar.value = _making.total - _making.left
	if _making.left <= 0.0:
		var id: String = _making.id
		var more: int = _making.get("more", 0)
		_making = {}
		_bar.visible = false
		_status.text = ""
		_finish(id)
		if more > 0:  # making several: start the next one (stops by itself when materials run out)
			get_tree().create_timer(0.2).timeout.connect(func():
				var ps := GameAuthority.instance.get_player(peer_id) if GameAuthority.instance else null
				if ps and visible and can_make_count(id, ps.inventory) > 0:
					start_making(id, more))


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
	var pic := TextureRect.new()  # a picture of what it makes (owner F123)
	pic.texture = Items.icon(r.output)
	pic.custom_minimum_size = Vector2(44, 44)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(pic)
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
	# Missing ingredients: say where to get them (F103).
	var tips := []
	for item in r.inputs:
		if inv.count_of(item) < int(r.inputs[item]) and Recipes.how_to_get(item) != "":
			tips.append("%s: %s" % [Items.display_name(item), Recipes.how_to_get(item)])
	if station and station.level() < int(r.get("level", 1)):
		ok = false
		tips.push_front("Needs %s level %d: place a %s within 4 m" % [Items.display_name(station.kind), int(r.level),
			Items.display_name(Station.EXTRAS.get(station.kind, [""])[mini(int(r.level) - 2, Station.EXTRAS.get(station.kind, []).size() - 1)])])
	var tip_text := "" if tips.is_empty() else "\n[font_size=12][color=#d8c08a]%s[/color][/font_size]" % "\n".join(tips)
	text.text = "[b]%s[/b]%s\n[font_size=13]%s[/font_size]%s" % [out, timer, ", ".join(parts), tip_text]
	row.add_child(text)
	var b := Button.new()
	b.text = "Make"
	b.disabled = not ok
	b.custom_minimum_size = Vector2(70, 0)
	b.disabled = not ok or not _making.is_empty()
	b.pressed.connect(func(): start_making(recipe_id))
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
