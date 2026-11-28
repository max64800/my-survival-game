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
const BATCH_MAX_SECONDS := 8.0  ## making many at once never takes longer than this (F555)
## Recipes sorted into tabs (owner F127) by what they make.
const TABS := ["Tools", "Weapons", "Armor", "Stations", "Materials", "Food"]
var _tab := ""
var _tabs: HFlowContainer
var _scroll: ScrollContainer
## How many to make with one click (owner F129): 1, 5 or -1 = as many as you can.
var amount := 1
var _amount_row: HBoxContainer
var _amount_slider: HSlider
var _amount_label: Label
var _amount_for := ""  ## the recipe the amount slider was set for (F920: a new pick resets it to ×1)
## Recipe cards (owner F187): click a card, it shows big at the bottom with one Craft button.
const CARD := 86
const CARD_INSET := 11  ## F923: how far in from the card's edge its picture and name stay (clear of the frame)
const CARD_PIC := 35  ## the picture box's height on a recipe card
const CARD_COLUMNS := 5
var _picked := ""
var _detail: PanelContainer
var _detail_pic: TextureRect
var _detail_name: Label
var _detail_needs: GridContainer
var _detail_food: VBoxContainer  ## what a food does: healing hearts, then the other effects as bullets
var _craft_button: Button
## Gear upgrades sit in their own panel, left of the bag, at a workbench or anvil (owner F178).
var upgrade_panel: PanelContainer
var _up_list: VBoxContainer


func _ready() -> void:
	UiKit.panel(self)  # "dwarf workshop" look (owner F187)
	custom_minimum_size = Vector2(500, 0)
	visibility_changed.connect(func(): if not visible: reset_amount())  # closing the bench resets the amount
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_title = UiKit.title(box, "Crafting")
	_status = UiKit.label(box, "", 14, UiKit.AMBER)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(460, 0)  # a wrapping label needs a width, or it grows very tall
	# Always exactly 2 rows tall, empty or full: its text changes while crafting, and a changing height
	# slid the whole menu up and down, because the menus are centred by height (F387).
	_status.max_lines_visible = 2
	_status.custom_minimum_size.y = _status.get_line_height() * 2 + _status.get_theme_constant("line_spacing")
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 14)
	_bar.show_percentage = false
	_bar.modulate.a = 0.0  # always takes its space, just hidden: the menu doesn't jump when crafting starts (owner, Nov 20)
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
	pic_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # stays square when the text beside it is long
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
	_detail_food = VBoxContainer.new()
	_detail_food.add_theme_constant_override("separation", 0)
	info.add_child(_detail_food)
	_amount_row = HBoxContainer.new()
	_amount_row.add_theme_constant_override("separation", 6)
	dv.add_child(_amount_row)
	# How many: a slider from 1 to as many as you can make, and All moves it to the end (owner, Nov 20).
	_amount_slider = UiKit.slider(HSlider.new())
	_amount_slider.name = "AmountSlider"
	_amount_slider.min_value = 1
	_amount_slider.step = 1
	_amount_slider.scrollable = false  # F920: the mouse wheel scrolls the list, never changes the amount
	_amount_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_amount_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_amount_slider.value_changed.connect(func(v): amount = int(v); _amount_label.text = "×%d" % amount; _name_detail())
	_amount_row.add_child(_amount_slider)
	_amount_label = UiKit.label(_amount_row, "×1", 17, UiKit.AMBER)
	_amount_label.custom_minimum_size = Vector2(44, 0)
	var all := UiKit.dark_button(Button.new(), 15)
	all.name = "AmountAll"
	all.text = "All"
	all.custom_minimum_size = Vector2(64, 42)
	all.pressed.connect(func(): _amount_slider.value = _amount_slider.max_value)
	_amount_row.add_child(all)
	_craft_button = UiKit.gold_button(Button.new(), 22)
	_craft_button.text = "Craft"
	_craft_button.custom_minimum_size = Vector2(140, 44)
	_craft_button.pressed.connect(func(): if _picked != "": start_making(_picked))
	_amount_row.add_child(_craft_button)


## The separate "Upgrade gear" panel. The HUD adds it to the screen and places it.
func make_upgrade_panel() -> PanelContainer:
	upgrade_panel = PanelContainer.new()
	UiKit.panel(upgrade_panel)
	upgrade_panel.custom_minimum_size = Vector2(360, 0)
	upgrade_panel.visible = false
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	upgrade_panel.add_child(scroll)
	_up_list = VBoxContainer.new()
	_up_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_up_list)
	visibility_changed.connect(func():
		if not visible:
			upgrade_panel.visible = false)
	return upgrade_panel


## Back to 1 (each time the bench opens or closes, owner Nov 20).
func reset_amount() -> void:
	amount = 1
	if _amount_slider:
		_amount_slider.value = 1


## Which tab a recipe goes in, by the kind of thing it makes.
static func tab_of(recipe_id: String) -> String:
	if Recipes.get_recipe(recipe_id).output == "crystal_torch":
		return "Tools"  # (F965, owner Nov 28: a light you carry and set down, not a station)
	match Items.kind(Recipes.get_recipe(recipe_id).output):
		"pickaxe", "axe", "hammer", "shovel", "lantern", "lens", "waterskin", "tonic", "throw", "horn":  # (shovel: owner, Nov 20)
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
	reset_amount()
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
			_status.text = "Put a Cooking Pot on the fire to reach level %d." % (station.level() + 1) if nxt == "cooking_pot" else "Place a %s within %d m to reach level %d." % [Items.display_name(nxt), int(Station.EXTRA_RANGE), station.level() + 1]
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
	var stock := stock_of(ps)  # your bag and the chests nearby (F888)
	for id in tab_ids:
		shown += 1
		cards.add_child(_card(id, stock))
	_show_detail(stock)
	# The card area is only as tall as its cards, up to 3 rows (F247: no empty space under the icons).
	var rows := ceili(maxi(shown, 1) / float(CARD_COLUMNS))
	_scroll.custom_minimum_size.y = mini(rows, 3) * (CARD + 6) - 6
	_scroll.set_deferred("scroll_vertical", keep_scroll)
	if shown == 0:
		var l := Label.new()
		l.text = "Nothing to make here yet. Explore and collect more!"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(l)
	# (only while this window is open: a craft ending after it closed used to bring the panel back alone, with no
	# way to close it; owner, Nov 22)
	var upgrades := visible and station != null and station.kind in ["workbench", "anvil", "armoury_bench"]
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


## F888 (owner, Nov 25): what you can craft from: your bag and the chests and barrels nearby (the host moves what's
## needed from them into your bag when you craft).
static func stock_of(ps: GameAuthority.PlayerState) -> Inventory:
	var auth := GameAuthority.instance
	if auth == null or auth.storage == null or not is_instance_valid(ps.node):
		return ps.inventory
	return auth.storage.craft_stock(ps.inventory, ps.node.global_position)


## How many of a recipe you can make right now with what you carry (and the chests nearby).
static func can_make_count(recipe_id: String, inv: Inventory) -> int:
	var r := Recipes.get_recipe(recipe_id)
	var most := 999
	for item in r.inputs:
		most = mini(most, inv.count_of(item) / maxi(1, int(r.inputs[item])))
	return most


## How long making `count` at once takes (owner F555: "I'm crafting 1 by 1, it takes so long").
## One bar for the whole amount: the first takes the normal time, each extra one a third of it,
## never more than 8 s in all. Crafting ★75: the extras add no time at all.
static func batch_time(one: float, count: int, star75: bool = false) -> float:
	if one <= 0.0 or count <= 1 or star75:
		return one
	return minf(one * (1.0 + (count - 1) / 3.0), maxf(one, BATCH_MAX_SECONDS))


func start_making(recipe_id: String, count: int = -2) -> void:
	if not _making.is_empty():
		return
	var me_ps := GameAuthority.instance.get_player(peer_id) if GameAuthority.instance else null
	if count == -2:  # from the Craft button: the chosen amount (owner F129)
		count = amount
	if me_ps:
		count = mini(count, maxi(can_make_count(recipe_id, stock_of(me_ps)), 1))
	count = maxi(count, 1)
	var one := craft_time(recipe_id) * (_prog().craft_time_mult(false) if _prog() else 1.0)  # Crafting: −3% per 10 levels
	if one <= 0.0:
		for i in count:
			_finish(recipe_id)
		return
	var t := batch_time(one, count, _prog() != null and _prog().has_star("crafting", 75))
	var me := _me()
	_making = {id = recipe_id, left = t, total = t, from = me.global_position if me else Vector3.ZERO, count = count}
	_work_beat = 0.0
	_bar.modulate.a = 1.0
	_bar.max_value = t
	_bar.value = 0.0
	_status.text = "Making %s%s…" % ["" if count <= 1 else "%d " % count, Items.display_name(Recipes.get_recipe(recipe_id).output)]
	refresh()


func cancel_making(why: String) -> void:
	if _making.is_empty():
		return
	_making = {}
	_bar.modulate.a = 0.0
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
		if visible and station and not station.jobs.is_empty():
			_status.text = station.busy_text()  # (F955: the cooking count-down runs while the menu is open)
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
		var count: int = _making.get("count", 1)
		_making = {}
		_bar.modulate.a = 0.0
		_status.text = ""
		reset_amount()  # F920: after a batch the amount goes back to ×1
		for i in count:  # the whole amount at once (F555); the host checks each one, so a short bag just stops
			_finish(id)


func _prog() -> Progression:
	var ps := GameAuthority.instance.get_player(peer_id) if GameAuthority.instance else null
	return ps.progress if ps else null


## Gear upgrades (building polish spec §4): everything you carry or wear that this station can improve.
## F918 (owner, Nov 27: "needs pictures and better UI"): a plaque title, then one card per tool/weapon/armour piece
## with its picture in a slot, its upgrade steps as gold pips, every cost as picture + have / need (missing in red),
## and the kit's gold Upgrade / dark Repair buttons (the same look as the Workbench's picked recipe).
func _upgrade_rows(inv: Inventory) -> void:
	UiKit.clear(_up_list)
	UiKit.title(_up_list, "Upgrade & Repair")
	UiKit.label(_up_list, "Each upgrade: +15%, up to +3. Repairs are free.", 13, UiKit.DIM).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# One big button that fixes everything this station can fix (owner F568: "repairing should cost nothing").
	var worn := repairable_here(inv, station.kind)
	var all := UiKit.gold_button(Button.new(), 15) if worn > 0 else UiKit.dark_button(Button.new(), 14)
	all.name = "RepairAll"
	all.text = "Repair all (free)" if worn > 0 else "Nothing needs repair"
	all.disabled = worn == 0
	all.custom_minimum_size = Vector2(0, 40)
	all.pressed.connect(func():
		GameAuthority.instance.ask_repair_all(station.station_id)
		get_tree().create_timer(0.15).timeout.connect(refresh))
	_up_list.add_child(all)
	UiKit.divider(_up_list)
	var any := false
	for i in inv.slots.size():
		var s := inv.get_slot(i)
		if s.is_empty() or not Upgrades.can_upgrade(s.id) or Upgrades.station_for(s.id) != station.kind:
			continue
		any = true
		_up_list.add_child(_upgrade_card(inv, s, i))
	if not any:
		var l := UiKit.label(_up_list, "Nothing to upgrade here. (%s)" % {"anvil": "copper, bronze and silver tools and weapons", "armoury_bench": "armour and shields"}.get(station.kind, "stone and wood tools and weapons"), 14, UiKit.DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## One gear card in the upgrade box (F918).
func _upgrade_card(inv: Inventory, s: Dictionary, slot_index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "UpgradeCard"
	card.add_theme_stylebox_override("panel", UiKit.style("tooltip", 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.style("slot", 5))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(frame)
	var pic := TextureRect.new()
	pic.name = "Pic"
	pic.texture = Items.icon(s.id)
	pic.custom_minimum_size = Vector2(54, 54)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(pic)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	top.add_child(info)
	var name_l := UiKit.label(info, Items.display_name(s.id), 16, UiKit.AMBER)  # (the pips show the +level)
	name_l.add_theme_font_override("font", UiKit.heading_font())
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lvl := Upgrades.level(s)
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	info.add_child(pips)
	for n in Upgrades.MAX_UP:
		var pip := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiKit.AMBER if n < lvl else Color(0.16, 0.1, 0.06)
		sb.border_color = Color(0.55, 0.38, 0.18)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		pip.add_theme_stylebox_override("panel", sb)
		pip.custom_minimum_size = Vector2(14, 10)
		pips.add_child(pip)
	UiKit.label(pips, "  +%d of %d" % [lvl, Upgrades.MAX_UP] if lvl < Upgrades.MAX_UP else "  fully upgraded", 13, UiKit.TEXT if lvl < Upgrades.MAX_UP else UiKit.AMBER)
	if Durability.needs_repair(s):
		UiKit.label(info, Durability.status_text(s), 13, UiKit.MISSING).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var cost := Upgrades.next_cost(s, 0.10 if _prog() and _prog().has_star("crafting", 25) else 0.0)
	var ok := not cost.is_empty() and station.level() >= Upgrades.needed_level(s)
	if not cost.is_empty():
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 8)
		v.add_child(grid)
		for item in cost:
			var have := inv.count_of(item)
			ok = ok and have >= cost[item]
			var col := UiKit.TEXT if have >= cost[item] else UiKit.MISSING
			var ip := TextureRect.new()
			ip.texture = Items.icon(item)
			ip.custom_minimum_size = Vector2(22, 22)
			ip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			grid.add_child(ip)
			UiKit.label(grid, Items.display_name(item), 14, col).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UiKit.label(grid, "%d / %d" % [have, cost[item]], 14, col)
		if station.level() < Upgrades.needed_level(s):
			UiKit.label(v, "To make it +%d, this %s must be level %d (now %d)." % [lvl + 1, Items.display_name(station.kind),
				Upgrades.needed_level(s), station.level()], 13, UiKit.MISSING).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(buttons)
	if Durability.needs_repair(s):
		var rb := UiKit.dark_button(Button.new(), 14)
		rb.text = "Repair"
		rb.custom_minimum_size = Vector2(90, 36)
		rb.pressed.connect(func():
			GameAuthority.instance.ask_repair(slot_index, station.station_id)
			get_tree().create_timer(0.15).timeout.connect(refresh))
		buttons.add_child(rb)
	if not cost.is_empty():
		var b := UiKit.gold_button(Button.new(), 15)
		b.name = "Upgrade"
		b.text = "Upgrade"
		b.disabled = not ok
		b.custom_minimum_size = Vector2(110, 36)
		b.pressed.connect(func():
			GameAuthority.instance.ask_upgrade(slot_index, station.station_id)
			get_tree().create_timer(0.15).timeout.connect(refresh))
		buttons.add_child(b)
	return card


## How many worn things you carry or wear that a `kind` station can repair (for "Repair all").
static func repairable_here(inv: Inventory, kind: String) -> int:
	var n := 0
	for s in inv.slots:
		if Durability.needs_repair(s) and Upgrades.station_for(s.id) == kind:
			n += 1
	return n


## Can you make it right now (enough of everything, station level high enough)?
func _ready_to_make(recipe_id: String, inv: Inventory) -> bool:
	var r := Recipes.get_recipe(recipe_id)
	if station and r.station != Recipes.HAND and station.level() < int(r.get("level", 1)):
		return false
	return (can_make_count(recipe_id, inv) > 0 or _can_chain(recipe_id, inv)) and _fuel_have(inv) >= int(r.get("fuel", 0))


## Auto-crafting: the dwarf can make the missing in-between items here first (same station only, owner Nov 19).
func _can_chain(recipe_id: String, inv: Inventory) -> bool:
	return not _chain_plan(recipe_id, inv).is_empty()


## The auto-craft plan: in-between recipes first, the picked one last ([] = can't be made, even by chaining).
func _chain_plan(recipe_id: String, inv: Inventory) -> Array:
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(peer_id) if auth else null
	if ps == null:
		return []
	var lvl := station.level() if station else 1
	return Crafting.plan(inv, recipe_id, Recipes.get_recipe(recipe_id).station, func(id): \
		return Recipes.is_unlocked(id, ps.seen, auth.taught_recipes()) and lvl >= int(Recipes.get_recipe(id).get("level", 1)))


## Owner, Nov 22: "crafted a shield with no planks but with wood ... looks like a bug". When the bench will make the
## in-between items first, say so: one line per step, e.g. "First makes 6 Rootwood Plank from 3 Rootwood".
func chain_lines(recipe_id: String, inv: Inventory) -> Array:
	if can_make_count(recipe_id, inv) > 0:
		return []
	var steps := _chain_plan(recipe_id, inv)
	var times := {}
	for i in steps.size() - 1:
		times[steps[i]] = times.get(steps[i], 0) + 1
	var lines := []
	for id in times:
		var r := Recipes.get_recipe(id)
		var from := []
		for item in r.inputs:
			from.append("%d %s" % [int(r.inputs[item]) * times[id], Items.display_name(item)])
		lines.append("First makes %d %s from %s" % [int(r.count) * times[id], Items.display_name(r.output), " + ".join(from)])
	return lines


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
	# F923 (owner, Nov 27): the button's own icon + text spilled over the frame (long names ran over the border,
	# tall pictures pushed into the name). Now a fixed picture box and a name that wraps onto 2 lines, both
	# kept inside the frame's border.
	b.clip_contents = true
	var inside := VBoxContainer.new()
	inside.name = "Inside"
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.offset_left = CARD_INSET
	inside.offset_right = -CARD_INSET
	inside.offset_top = CARD_INSET
	inside.offset_bottom = -CARD_INSET + 3
	inside.add_theme_constant_override("separation", 1)
	b.add_child(inside)
	var pic := TextureRect.new()
	pic.name = "Pic"
	pic.texture = Items.icon(r.output)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(0, CARD_PIC)
	inside.add_child(pic)
	var name_l := UiKit.label(inside, Items.display_name(r.output) + ("" if r.count == 1 else " ×%d" % r.count), 11, UiKit.TEXT)
	name_l.name = "Name"
	name_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.max_lines_visible = 2
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.add_theme_constant_override("line_spacing", 0)
	name_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_l.clip_text = true
	b.mouse_entered.connect(func(): name_l.add_theme_color_override("font_color", UiKit.AMBER))
	b.mouse_exited.connect(func(): name_l.add_theme_color_override("font_color", UiKit.TEXT))
	b.tooltip_text = Items.display_name(r.output)
	if station_role(r.output).begins_with("Upgrade"):  # F935: a gold "UP" tag on station upgrades
		var tag := UiKit.label(b, "UP", 10, UiKit.DARK_TEXT)
		tag.name = "UpgradeTag"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_theme_font_override("font", UiKit.heading_font())
		var tsb := StyleBoxFlat.new()
		tsb.bg_color = UiKit.AMBER
		tsb.set_corner_radius_all(3)
		tsb.content_margin_left = 3
		tsb.content_margin_right = 3
		tag.add_theme_stylebox_override("normal", tsb)
		tag.position = Vector2(CARD - CARD_INSET - 22, CARD_INSET - 2)
	var picked := recipe_id == _picked
	var normal := UiKit.style("slot_selected" if picked else "card", 6)
	for st in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, normal)
	b.add_theme_stylebox_override("hover", UiKit.style("slot_selected", 6))
	if not _ready_to_make(recipe_id, inv):
		b.modulate = Color(1, 1, 1, 0.5)
	b.pressed.connect(func(): _picked = recipe_id; refresh())
	return b


const DETAIL_TEXT_WIDTH := 300  ## wrapping lines beside the big picture (the column is ~330 wide)


## The picked recipe's name, with its time when the station makes it on its own timer (F955: it follows the amount).
func _name_detail() -> void:
	if _picked == "" or _detail_name == null:
		return
	var r := Recipes.get_recipe(_picked)
	var timer := "" if r.get("seconds", 0) == 0 else "  " + timed_text(r, amount, _prog())
	_detail_name.text = Items.display_name(r.output) + ("" if r.count == 1 else " ×%d" % r.count) + timer


## F955 (owner, Nov 28): how long a recipe on the station's own timer takes, one and the whole amount (they're made
## one after the other): "(cooks in 10 s)" / "(cooks in 10 s each, 3 = 0:30)".
static func timed_text(r: Dictionary, count: int, prog: Progression) -> String:
	var cooking: bool = r.get("station", "") == "campfire"
	var mult := 1.0
	if prog:
		mult = prog.craft_time_mult(cooking) * (prog.smelt_time_mult() if r.get("station", "") == "smelter" else 1.0)
	var one := float(r.seconds) * mult
	var verb := "cooks" if cooking else "takes"
	if count <= 1:
		return "(%s in %d s)" % [verb, ceili(one)]
	return "(%s in %d s each, %d = %s)" % [verb, ceili(one), count, PickupFeed.clock(one * count)]


## The picked recipe at the bottom: big picture, every ingredient as have / need (missing in red).
func _show_detail(inv: Inventory) -> void:
	UiKit.clear(_detail_needs)
	if _picked == "":
		_detail.visible = false
		return
	_detail.visible = true
	var r := Recipes.get_recipe(_picked)
	_detail_pic.texture = Items.icon(r.output)
	_name_detail()
	var needs: Dictionary = r.inputs.duplicate()
	if r.get("fuel", 0) > 0:
		needs["fuel"] = int(r.fuel)
	for item in needs:
		var have := _fuel_have(inv) if item == "fuel" else inv.count_of(item)
		var need: int = needs[item]
		var col := UiKit.TEXT if have >= need else (UiKit.AMBER if _can_chain(_picked, inv) and item != "fuel" else UiKit.MISSING)
		var pic := TextureRect.new()
		pic.texture = Items.icon("coal" if item == "fuel" else item)
		pic.custom_minimum_size = Vector2(22, 22)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_detail_needs.add_child(pic)
		var n := UiKit.label(_detail_needs, "Fuel (coal)" if item == "fuel" else Items.display_name(item), 14, col)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.label(_detail_needs, "%d / %d" % [have, need], 14, col)
	_food_lines(r.output)
	var chain := chain_lines(_picked, inv)
	for line in chain:
		UiKit.label(_detail_food, "⚒  " + line, 14, UiKit.AMBER)
	if not chain.is_empty():
		UiKit.label(_detail_food, "⚒  then the %s" % Items.display_name(r.output), 14, UiKit.AMBER)
	# No yellow "where to get it" lines (owner F179: too much text). Only a short red note
	# when the station's level is too low.
	if station and r.station != Recipes.HAND and station.level() < int(r.get("level", 1)):
		_detail_needs.add_child(Control.new())
		UiKit.label(_detail_needs, "needs level %d" % int(r.level), 14, UiKit.MISSING)
		_detail_needs.add_child(Control.new())
	_craft_button.disabled = not _ready_to_make(_picked, inv) or not _making.is_empty()
	if _picked != _amount_for:  # F920 (owner, Nov 27): a new pick starts at ×1 (6 maces were made by a left-over amount)
		_amount_for = _picked
		reset_amount()
	_amount_slider.max_value = maxi(1, can_make_count(_picked, inv))  # the slider never goes past what you can make
	_amount_slider.editable = _amount_slider.max_value > 1


## The Gem Bench (combat doc 4.4): every item with sockets, its gems, and the gems you carry.
func _gem_bench(ps: GameAuthority.PlayerState) -> void:
	_title.text = "Gem Bench"
	_status.text = "Socketing is free. Taking a gem out costs %d gold. 3 of the same gem make 1 better one." % Gems.REMOVE_COST.gold_coin
	UiKit.clear(_list)
	var carried := []
	for s in ps.inventory.slots:
		if not s.is_empty() and Gems.gem_of(s.id) != "" and not carried.has(Gems.gem_of(s.id)):
			carried.append(Gems.gem_of(s.id))
	# Combining: every gem you hold 3 of.
	for g in carried:
		if not Gems.NORMAL.has(Gems.base_of(g)) or Gems.level_of(g) >= Gems.MAX_LEVEL:
			continue
		var have := ps.inventory.count_of(Gems.item_id(g))
		var next := Gems.with_level(Gems.base_of(g), Gems.level_of(g) + 1)
		var b := Button.new()
		b.text = "Combine 3 %s into 1 %s  (%d gold, you have %d gems)" % [Gems.full_name(g), Gems.full_name(next), Gems.COMBINE_GOLD[Gems.level_of(next)], have]
		b.tooltip_text = Gems.describe(next)
		b.disabled = have < 3
		var gem: String = g
		b.pressed.connect(func():
			GameAuthority.instance.ask_combine(gem)
			get_tree().create_timer(0.15).timeout.connect(refresh))
		_list.add_child(b)
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
			b.text = "Take out %s" % Gems.full_name(gems[gi]) if Gems.NORMAL.has(Gems.base_of(gems[gi])) else gems[gi]
			b.tooltip_text = Gems.describe(gems[gi])
			var slot_i := i
			var idx := gi
			b.pressed.connect(func():
				GameAuthority.instance.ask_unsocket(slot_i, idx)
				get_tree().create_timer(0.15).timeout.connect(refresh))
			row.add_child(b)
		if gems.size() < Gems.socket_count(s.id):
			for g in carried:
				if not Gems.can_socket(s, g):
					continue
				var b := Button.new()
				b.text = "+ %s" % Gems.full_name(g)
				b.tooltip_text = Gems.describe(g)
				var slot_i := i
				var gem: String = g
				b.pressed.connect(func():
					GameAuthority.instance.ask_socket(slot_i, gem)
					get_tree().create_timer(0.15).timeout.connect(refresh))
				row.add_child(b)
	if not any:
		var l := Label.new()
		l.text = "Copper and better weapons, shields, tools and armor have a gem socket. Stone and leather ones don't."
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


## A food's effects under its ingredients: "Healing" with half hearts (hover = the exact speed), then bullets.
## F935 (owner, Nov 27: at the Stove Oven "I couldn't tell if the Charcoal Kiln was an upgrade or not"): is this
## station an upgrade for another one (Station.EXTRAS), or a station of its own? "" for things that aren't stations.
static func station_role(item: String) -> String:
	for main: String in Station.EXTRAS:
		if item in Station.EXTRAS[main]:
			var where := "set it on a %s" % Items.display_name(main) if Station.EXTRA_REACH.has(item) 				else "place it within %d m of a %s" % [int(Station.EXTRA_RANGE), Items.display_name(main)]
			return "Upgrade for the %s: %s to raise its level." % [Items.display_name(main), where]
	if Items.kind(item) == "station" and item in Station.EXTRAS:
		return "Its own station. Upgrades raise its level: %s." % ", ".join(Station.EXTRAS[item].map(func(x): return Items.display_name(x)))
	if Items.kind(item) == "station":
		return "Its own station (not an upgrade)."
	return ""


func _food_lines(item: String) -> void:
	UiKit.clear(_detail_food)
	var role := station_role(item)
	if role != "":
		var rl := UiKit.label(_detail_food, "•  " + role, 14, UiKit.AMBER)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.custom_minimum_size.x = DETAIL_TEXT_WIDTH  # F949: a fresh wrapping line has no width yet, so it measured
		# one word a line, very tall, and the menu sized itself to that (Materials -> Stations: big empty space)
	var hits := Combat.damage_text({id = item})  # (owner F571: weapons show their damage)
	if hits != "":
		UiKit.label(_detail_food, "•  " + hits, 15, UiKit.AMBER)
		var kind := RichTextLabel.new()  # F831: "Blunt · one hand"
		kind.bbcode_enabled = true
		kind.fit_content = true
		kind.scroll_active = false
		kind.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kind.custom_minimum_size.x = DETAIL_TEXT_WIDTH  # (F949, as above)
		kind.add_theme_font_size_override("normal_font_size", 14)
		kind.add_theme_color_override("default_color", UiKit.AMBER)
		kind.text = Combat.type_text(item)
		_detail_food.add_child(kind)
	if not Foods.is_buff_food(item):
		return
	var regen: float = Foods.buff_of(item).get("regen", 0.0)
	if regen > 0.0:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.tooltip_text = "heals 1 health every %.1f s (normal: every %d s)" % [1.0 / (Vitals.HEALTH_REGEN + regen), roundi(1.0 / Vitals.HEALTH_REGEN)]
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		_detail_food.add_child(row)
		UiKit.label(row, "•  Healing", 14, UiKit.TEXT).mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(UiKit.hearts(Foods.heart_halves(regen), 18))
	for line in Foods.effect_lines(item):
		UiKit.label(_detail_food, "•  " + line, 14, UiKit.DIM if line.begins_with("lasts") else UiKit.TEXT)
