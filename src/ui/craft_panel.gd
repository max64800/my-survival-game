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
var _tabs: HFlowContainer
var _scroll: ScrollContainer
## How many to make with one click (owner F129): 1, 5 or -1 = as many as you can.
var amount := 1
var _amount_row: HBoxContainer
## Recipe cards (owner F187): click a card, it shows big at the bottom with one Craft button.
const CARD := 86
const CARD_COLUMNS := 5
var _picked := ""
var _detail: PanelContainer
var _detail_pic: TextureRect
var _detail_name: Label
var _detail_needs: GridContainer
var _craft_button: Button
## Gear upgrades sit in their own panel, left of the bag, at a workbench or anvil (owner F178).
var upgrade_panel: PanelContainer
var _up_list: VBoxContainer


func _ready() -> void:
	UiKit.panel(self)  # "dwarf workshop" look (owner F187)
	custom_minimum_size = Vector2(500, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_title = UiKit.title(box, "Crafting")
	_status = UiKit.label(box, "", 14, UiKit.AMBER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(460, 0)  # a wrapping label needs a width, or it grows very tall
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.show_percentage = false
	_bar.visible = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.75, 0.35)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	_tabs = HFlowContainer.new()  # tabs wrap onto a second line instead of widening the panel
	_tabs.add_theme_constant_override("h_separation", 4)
	_tabs.add_theme_constant_override("v_separation", 4)
	box.add_child(_tabs)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(470, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_scroll = scroll
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	# The picked recipe, big, with have / need and one Craft button (owner F187).
	_detail = PanelContainer.new()
	_detail.add_theme_stylebox_override("panel", UiKit.style("tooltip", 14))
	box.add_child(_detail)
	var dv := VBoxContainer.new()
	_detail.add_child(dv)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	dv.add_child(top)
	var pic_frame := PanelContainer.new()
	pic_frame.add_theme_stylebox_override("panel", UiKit.style("slot", 6))
	top.add_child(pic_frame)
	_detail_pic = TextureRect.new()
	_detail_pic.custom_minimum_size = Vector2(78, 78)
	_detail_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic_frame.add_child(_detail_pic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	_detail_name = UiKit.label(info, "", 19, UiKit.AMBER)
	_detail_needs = GridContainer.new()
	_detail_needs.columns = 3
	_detail_needs.add_theme_constant_override("h_separation", 8)
	info.add_child(_detail_needs)
	_amount_row = HBoxContainer.new()
	_amount_row.add_theme_constant_override("separation", 6)
	dv.add_child(_amount_row)
	for a in [1, 5, -1]:
		var b := UiKit.dark_button(Button.new(), 15)
		b.name = "Amount%d" % a
		b.text = "×%d" % a if a > 0 else "All"
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(76, 42)
		b.button_pressed = a == amount
		var pick: int = a
		b.pressed.connect(func(): amount = pick; _paint_amounts())
		_amount_row.add_child(b)
	_craft_button = UiKit.gold_button(Button.new(), 22)
	_craft_button.text = "Craft"
	_craft_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_craft_button.custom_minimum_size = Vector2(0, 44)
	_craft_button.pressed.connect(func(): if _picked != "": start_making(_picked))
	_amount_row.add_child(_craft_button)


## The separate "Upgrade gear" panel. The HUD adds it to the screen and places it.
func make_upgrade_panel() -> PanelContainer:
	upgrade_panel = PanelContainer.new()
	UiKit.panel(upgrade_panel)
	upgrade_panel.custom_minimum_size = Vector2(330, 0)
	upgrade_panel.visible = false
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(310, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	upgrade_panel.add_child(scroll)
	_up_list = VBoxContainer.new()
	_up_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_up_list)
	visibility_changed.connect(func():
		if not visible:
			upgrade_panel.visible = false)
	return upgrade_panel


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
	var special := station != null and station.kind in ["rune_slab", "gem_bench"]
	_detail.visible = not special
	_tabs.visible = not special
	if special:
		_scroll.custom_minimum_size.y = 250  # gem bench / rune slab lists keep the tall scroll
		UiKit.fit(self)
	if station and station.kind == "rune_slab":
		_rune_slab(ps, auth)
		return
	if station and station.kind == "gem_bench":
		_gem_bench(ps)
		return
	var where := Recipes.HAND if station == null else station.kind
	_title.text = "Crafting" if station == null else Items.display_name(station.kind)
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
		_status.text = "Works by itself: put %s in a chest within 5 m." % 			("wood" if station.kind == "kiln" else "ore and coal")
	var keep_scroll := _scroll.scroll_vertical  # the list stays where it was after you make something (F129)
	UiKit.clear(_list)
	UiKit.clear(_tabs)
	# Only recipes you've unlocked, in tabs (owner F127). Missing materials still show in red, with where to get them.
	var by_tab := {}
	var ids := Recipes.for_station(where)
	if station and station.kind == "workbench":
		ids = Recipes.for_station(Recipes.HAND) + ids  # anything you can make by hand, you can make here too (owner F174)
	for id in ids:
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
		var tb := UiKit.dark_button(Button.new(), 13)
		tb.text = t
		tb.icon = Items.icon(Recipes.get_recipe(by_tab[t][0]).output)  # a picture of the tab's first thing
		tb.expand_icon = true
		tb.add_theme_constant_override("icon_max_width", 22)
		tb.custom_minimum_size = Vector2(0, 38)
		tb.toggle_mode = true
		tb.button_pressed = t == _tab
		var pick: String = t
		tb.pressed.connect(func(): _tab = pick; _scroll.scroll_vertical = 0; refresh())
		_tabs.add_child(tb)
	var shown := 0
	var cards := GridContainer.new()
	cards.columns = CARD_COLUMNS
	cards.add_theme_constant_override("h_separation", 6)
	cards.add_theme_constant_override("v_separation", 6)
	_list.add_child(cards)
	var tab_ids: Array = by_tab.get(_tab, [])
	if not _picked in tab_ids:
		_picked = tab_ids[0] if not tab_ids.is_empty() else ""
	for id in tab_ids:
		shown += 1
		cards.add_child(_card(id, ps.inventory))
	_show_detail(ps.inventory)
	# The card area is only as tall as its cards, up to 3 rows (F247: no empty space under the icons).
	var rows := ceili(maxi(shown, 1) / float(CARD_COLUMNS))
	_scroll.custom_minimum_size.y = mini(rows, 3) * (CARD + 6) - 6
	_scroll.set_deferred("scroll_vertical", keep_scroll)
	if shown == 0:
		var l := Label.new()
		l.text = "Nothing to make here yet. Explore and collect more!"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(l)
	var upgrades := station != null and station.kind in ["workbench", "anvil"]
	if upgrade_panel:
		upgrade_panel.visible = upgrades
		if upgrades:
			_upgrade_rows(ps.inventory)
	UiKit.fit(self)  # F247: the panel shrinks to what it shows, no dead space at the bottom


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
	UiKit.clear(_up_list)
	var heading := Label.new()
	heading.text = "Upgrade gear"
	heading.add_theme_font_size_override("font_size", 20)
	_up_list.add_child(heading)
	var sub := Label.new()
	sub.text = "+15% each step, up to +3"
	sub.add_theme_font_size_override("font_size", 13)
	_up_list.add_child(sub)
	var any := false
	for i in inv.slots.size():
		var s := inv.get_slot(i)
		if s.is_empty() or not Upgrades.can_upgrade(s.id) or Upgrades.station_for(s.id) != station.kind:
			continue
		any = true
		var row := HBoxContainer.new()
		var text := RichTextLabel.new()
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # long lines wrap: the panel keeps its width
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
		_up_list.add_child(row)
	if not any:
		var l := Label.new()
		l.text = "Nothing to upgrade here. (%s)" % ("copper and silver gear" if station.kind == "anvil" else "stone, wood, leather and shell gear")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_up_list.add_child(l)


## Can you make it right now (enough of everything, station level high enough)?
func _ready_to_make(recipe_id: String, inv: Inventory) -> bool:
	var r := Recipes.get_recipe(recipe_id)
	if station and r.station != Recipes.HAND and station.level() < int(r.get("level", 1)):
		return false
	return can_make_count(recipe_id, inv) > 0 and _fuel_have(inv) >= int(r.get("fuel", 0))


## Fuel is coal only, made from wood in the Bloomery (owner, Nov 19, F404; game_authority).
static func _fuel_have(inv: Inventory) -> int:
	return inv.count_of("coal")


## One recipe card: the picture and the name. Dim when you can't make it yet; gold frame when picked.
func _card(recipe_id: String, inv: Inventory) -> Control:
	var r := Recipes.get_recipe(recipe_id)
	var b := Button.new()
	b.name = "Card_" + recipe_id
	b.custom_minimum_size = Vector2(CARD, CARD)
	b.focus_mode = Control.FOCUS_NONE
	b.icon = Items.icon(r.output)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_constant_override("icon_max_width", 46)
	b.text = Items.display_name(r.output) + ("" if r.count == 1 else " ×%d" % r.count)
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", UiKit.TEXT)
	b.add_theme_color_override("font_hover_color", UiKit.AMBER)
	b.tooltip_text = Items.display_name(r.output)
	var picked := recipe_id == _picked
	var normal := UiKit.style("slot_selected" if picked else "card", 6)
	for st in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, normal)
	b.add_theme_stylebox_override("hover", UiKit.style("slot_selected", 6))
	if not _ready_to_make(recipe_id, inv):
		b.modulate = Color(1, 1, 1, 0.5)
	b.pressed.connect(func(): _picked = recipe_id; refresh())
	return b


## The picked recipe at the bottom: big picture, every ingredient as have / need (missing in red).
func _show_detail(inv: Inventory) -> void:
	UiKit.clear(_detail_needs)
	if _picked == "":
		_detail.visible = false
		return
	_detail.visible = true
	var r := Recipes.get_recipe(_picked)
	_detail_pic.texture = Items.icon(r.output)
	var timer := "" if r.get("seconds", 0) == 0 else "  (%ds)" % r.seconds
	_detail_name.text = Items.display_name(r.output) + ("" if r.count == 1 else " ×%d" % r.count) + timer
	var needs: Dictionary = r.inputs.duplicate()
	if r.get("fuel", 0) > 0:
		needs["fuel"] = int(r.fuel)
	for item in needs:
		var have := _fuel_have(inv) if item == "fuel" else inv.count_of(item)
		var need: int = needs[item]
		var col := UiKit.TEXT if have >= need else UiKit.MISSING
		var pic := TextureRect.new()
		pic.texture = Items.icon("coal" if item == "fuel" else item)
		pic.custom_minimum_size = Vector2(22, 22)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_detail_needs.add_child(pic)
		var n := UiKit.label(_detail_needs, "Fuel (coal)" if item == "fuel" else Items.display_name(item), 14, col)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.label(_detail_needs, "%d / %d" % [have, need], 14, col)
	# No yellow "where to get it" lines (owner F179: too much text). Only a short red note
	# when the station's level is too low.
	if station and r.station != Recipes.HAND and station.level() < int(r.get("level", 1)):
		_detail_needs.add_child(Control.new())
		UiKit.label(_detail_needs, "needs level %d" % int(r.level), 14, UiKit.MISSING)
		_detail_needs.add_child(Control.new())
	_craft_button.disabled = not _ready_to_make(_picked, inv) or not _making.is_empty()


## The Gem Bench (combat doc 4.4): every item with sockets, its gems, and the gems you carry.
func _gem_bench(ps: GameAuthority.PlayerState) -> void:
	_title.text = "Gem Bench"
	_status.text = "Socketing is free. Taking a gem out costs 5 blue glow crystals."
	UiKit.clear(_list)
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
	UiKit.clear(_list)
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
