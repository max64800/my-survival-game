class_name PickupFeed
extends VBoxContainer
## F885 (owner, Nov 25: "every resource you pick up should pop up on the left: its picture and the amount"): a short
## list on the left of the screen. Each thing your bag gains shows as a row ("+5 Stone" with its picture); more of the
## same tops up its row; a row fades after SHOW seconds. The HUD calls watch() with your bag each time it changes.
## Quiet while only the bag is open (moving things around there isn't picking up). With a chest open it shows what
## you take out (F911, owner Nov 26).

const SHOW := 3.0
const FADE := 0.5
const MAX_ROWS := 6
const ICON := 44

var _last := {}  ## item -> how many the bag had last time
var _rows := {}  ## item -> {node, count, label, left}
var _started := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 6)


## Should the feed keep quiet? Only while the bag is open on its own (sorting it); with a chest open, what you take
## out pops up (F911).
static func quiet_for(bag_open: bool, chest_open: bool) -> bool:
	return bag_open and not chest_open


## What you spend that shows too, while you hold this (F933, owner Nov 27: flattening "when you lose stone it should
## show the same way as when you add stone"): the Mason's Shovel's fill and raise use up dirt and stone.
const SPEND_SHOWN := {"masons_shovel": ["stone", "dirt"]}


## The bag changed: anything it has more of now pops up (unless `quiet`); so does less of what `held` spends.
func watch(inv: Inventory, quiet: bool, held := "") -> void:
	var now := {}
	for s: Dictionary in inv.slots:
		if not s.is_empty():
			now[s.id] = now.get(s.id, 0) + int(s.count)
	if _started and not quiet:
		for id in now:
			var more: int = now[id] - int(_last.get(id, 0))
			if more > 0:
				add(id, more)
		for id in SPEND_SHOWN.get(held, []):
			var less: int = int(_last.get(id, 0)) - int(now.get(id, 0))
			if less > 0:
				add(id, -less)
	_last = now
	_started = true


## n < 0: spent (a "-3  Stone" row in red, its own row next to the "+" one). `note`: said after it, on its own row
## (F953/F954: "-1  White Glow Crystal · lantern +10:00, 12:30 left").
func add(id: String, n: int, note := "") -> void:
	var key := (id if n > 0 else "-" + id) + ("|" + note.get_slice(" ", 0) if note != "" else "")
	if _rows.has(key):
		var r: Dictionary = _rows[key]
		r.count += n
		r.left = SHOW
		(r.label as Label).text = _text(id, r.count, note)
		(r.node as Control).modulate.a = 1.0
		move_child(r.node, get_child_count() - 1)  # the newest at the bottom
		return
	if _rows.size() >= MAX_ROWS:  # too many: the oldest goes
		var oldest: String = ""
		var least := INF
		for k in _rows:
			if float(_rows[k].left) < least:
				least = _rows[k].left
				oldest = k
		_drop(oldest)
	var row := PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.04, 0.72)
	sb.border_color = Color(0.55, 0.42, 0.25, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6
	sb.content_margin_right = 14
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	row.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 8)
	row.add_child(h)
	var pic := TextureRect.new()
	pic.texture = Items.icon(id)
	pic.custom_minimum_size = Vector2(ICON, ICON)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(pic)
	var l := UiKit.label(h, _text(id, n, note), 19, UiKit.TEXT if n > 0 else Color(1.0, 0.55, 0.45))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	add_child(row)
	_rows[key] = {node = row, count = n, label = l, left = SHOW}


static func _text(id: String, n: int, note := "") -> String:
	return "%s%d  %s%s" % ["+" if n > 0 else "-", absi(n), Items.display_name(id), "  ·  " + note if note != "" else ""]


## F953/F954 (owner, Nov 28): the lantern burned one `id` (+`added` s); `fuel` s are left now. Wood gives a minute,
## a crystal ten, so this says why the light ran out so soon.
func lantern_refilled(id: String, added: float, fuel: float) -> void:
	add(id, -1, "lantern +%s, %s left" % [clock(added), clock(fuel)])


static func clock(seconds: float) -> String:
	var s := int(round(seconds))
	return "%d:%02d" % [s / 60, s % 60]


func _process(delta: float) -> void:
	for id in _rows.keys():
		var r: Dictionary = _rows[id]
		r.left -= delta
		if r.left <= 0.0:
			_drop(id)
		elif r.left < FADE:
			(r.node as Control).modulate.a = r.left / FADE


func _drop(id: String) -> void:
	if _rows.has(id):
		(_rows[id].node as Node).queue_free()
		_rows.erase(id)


## How many rows show (for tests).
func shown() -> int:
	return _rows.size()
