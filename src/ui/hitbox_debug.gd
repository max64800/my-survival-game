class_name HitboxDebug
extends CanvasLayer
## Press F10 in-game to open/close this overlay (F9 is already "god mode").
##
## Yellow ring = an enemy's longest base attack reach.
## Orange ring = effective reach (yellow + 0.8) — this is what the game actually checks.
## Blue wireframe = the dwarf's body collision (what enemy attacks aim at).
##
## Use [−] [+] to adjust reach values. Changes apply instantly. Hit Save to keep them
## across sessions. When the numbers feel right, tell Claude and they'll be written back
## into the code permanently.

const SAVE_PATH := "user://hitbox_overrides.json"
const STEP      := 0.1   # how much each [−] [+] click changes reach
const SEGS      := 40    # ring smoothness
const ENM_BONUS := 0.8   # monster_manager._in_reach adds this to every monster reach
const WPN_BONUS := 0.5   # dwarf_fight._impact adds this flat to every weapon reach

# -- 3-D wire drawing -------------------------------------------------------
var _imesh : ImmediateMesh
var _mi    : MeshInstance3D
var _dwarf : Node3D   # set by main.gd via set_dwarf()

# -- overrides: { "weapon:sword" -> delta, "monster:foreman:0" -> delta, … } --
var _deltas: Dictionary = {}

# -- panel rows: [{key, base, bonus, lbl: Label}] ---------------------------
var _rows: Array = []


# ===========================================================================
# Init
# ===========================================================================

func _ready() -> void:
	layer = 128
	_setup_mesh()
	get_tree().root.add_child.call_deferred(_mi)   # add mesh to 3-D world
	_build_panel()
	visible = false
	_load()


func _setup_mesh() -> void:
	_imesh = ImmediateMesh.new()
	_mi = MeshInstance3D.new()
	_mi.mesh = _imesh
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mi.visible = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test              = true
	mat.cull_mode                  = BaseMaterial3D.CULL_DISABLED
	_mi.material_override          = mat


func _exit_tree() -> void:
	_mi.queue_free()


## Called by main.gd after the local dwarf is created.
func set_dwarf(d: Node3D) -> void:
	_dwarf = d


# ===========================================================================
# Toggle (F10)
# ===========================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10:
			visible = not visible
			_mi.visible = visible
			if visible:
				_update_all_labels()
			get_viewport().set_input_as_handled()


# ===========================================================================
# 3-D drawing — runs every frame while visible
# ===========================================================================

func _process(_dt: float) -> void:
	if not visible:
		return
	_imesh.clear_surfaces()

	var auth := GameAuthority.instance
	if auth == null or auth.monsters == null:
		return

	var yellows: Array = []
	var oranges: Array = []
	for m: Monster in auth.monsters.monsters.values():
		if not m.is_alive():
			continue
		var atks: Array = m.data.get("attacks", [])
		var max_r := 0.0
		for i: int in atks.size():
			var atk: Dictionary = atks[i]
			var delta := float(_deltas.get("monster:%s:%d" % [m.kind, i], 0.0))
			max_r = maxf(max_r, float(atk.get("reach", 0.0)) + delta)
		if max_r > 0.01:
			var p := m.global_position + Vector3.UP * 0.08
			yellows.append({c = p, r = max_r})
			oranges.append({c = p, r = max_r + ENM_BONUS})

	_batch_rings(yellows, Color(1.0, 1.0, 0.0, 0.9))
	_batch_rings(oranges, Color(1.0, 0.55, 0.0, 0.6))

	if _dwarf:
		_draw_capsule(_dwarf.global_position, 0.36, 1.35, Color(0.4, 0.8, 1.0, 0.75))


func _batch_rings(rings: Array, color: Color) -> void:
	if rings.is_empty():
		return
	_imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for entry: Dictionary in rings:
		var c: Vector3 = entry.c
		var r: float   = entry.r
		for i: int in SEGS:
			var a0 := float(i)     / float(SEGS) * TAU
			var a1 := float(i + 1) / float(SEGS) * TAU
			_imesh.surface_set_color(color)
			_imesh.surface_add_vertex(Vector3(c.x + cos(a0) * r, c.y, c.z + sin(a0) * r))
			_imesh.surface_set_color(color)
			_imesh.surface_add_vertex(Vector3(c.x + cos(a1) * r, c.y, c.z + sin(a1) * r))
	_imesh.surface_end()


func _draw_capsule(base: Vector3, radius: float, total_h: float, color: Color) -> void:
	var rings := [
		{c = base + Vector3.UP * radius,             r = radius},
		{c = base + Vector3.UP * (total_h * 0.5),   r = radius},
		{c = base + Vector3.UP * (total_h - radius), r = radius},
	]
	_batch_rings(rings, color)
	_imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i: int in 4:
		var a   := float(i) * TAU / 4.0
		var xz  := Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		_imesh.surface_set_color(color)
		_imesh.surface_add_vertex(base + xz + Vector3.UP * radius)
		_imesh.surface_set_color(color)
		_imesh.surface_add_vertex(base + xz + Vector3.UP * (total_h - radius))
	_imesh.surface_end()


# ===========================================================================
# Panel UI
# ===========================================================================

func _build_panel() -> void:
	# Full-screen invisible root so the panel sits on top of everything
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Panel anchored to the right edge of the screen
	var panel := PanelContainer.new()
	panel.anchor_left   = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -340.0
	panel.offset_right  = 0.0
	panel.offset_top    = 0.0
	panel.offset_bottom = 0.0
	panel.mouse_filter  = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 3)
	panel.add_child(outer)

	# --- header ---
	var title := Label.new()
	title.text = "Hitboxes  (F10 to close)"
	title.add_theme_font_size_override("font_size", 14)
	outer.add_child(title)

	var note := Label.new()
	note.text = "Yellow = enemy base reach\nOrange = eff reach (yellow + 0.8)\nBlue = dwarf capsule body"
	note.add_theme_font_size_override("font_size", 10)
	note.modulate = Color(0.75, 0.75, 0.75)
	outer.add_child(note)

	var col_header := Label.new()
	col_header.text = "Name                 cur   eff   [−] [+]"
	col_header.add_theme_font_size_override("font_size", 9)
	col_header.modulate = Color(0.55, 0.55, 0.55)
	outer.add_child(col_header)

	outer.add_child(HSeparator.new())

	# --- scrollable list ---
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical      = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size      = Vector2(0, 380)
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 1)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# DWARF
	_hdr(list, "DWARF BODY")
	var body_note := Label.new()
	body_note.text = "  Capsule r=0.36  h=1.35  (not adjustable)"
	body_note.add_theme_font_size_override("font_size", 9)
	body_note.modulate = Color(0.5, 0.85, 1.0)
	list.add_child(body_note)

	_hdr(list, "Dwarf Weapons  (arc 70°, sweep 160°, spear spin 360°)")
	var wpn_note := Label.new()
	wpn_note.text = "  eff = cur + 0.5  (shown at prog mult 1.0)"
	wpn_note.add_theme_font_size_override("font_size", 9)
	wpn_note.modulate = Color(0.7, 0.7, 0.7)
	list.add_child(wpn_note)
	for w: String in ["sword", "axe", "mace", "spear", "axe_2h", "mace_2h", "shield", "pickaxe", "fists"]:
		if Combat.WEAPONS.has(w):
			_row(list, w.replace("_", " "), "weapon:%s" % w,
				float(Combat.WEAPONS[w].reach), WPN_BONUS)

	list.add_child(HSeparator.new())
	_hdr(list, "Enemy Attacks  (eff = cur + 0.8)")

	for key: String in ["tunnel_rat", "lost_miner", "foreman", "prop_warden",
			"rock_snail", "cave_bat", "rock_beetle", "great_rock_beetle",
			"cave_spider", "ghost_a", "ghost_b", "ghost_c", "ghost_lord"]:
		if not Monsters.LIST.has(key):
			continue
		var d: Dictionary = Monsters.LIST[key]
		_hdr(list, d.name)
		var atks: Array = d.get("attacks", [])
		for i: int in atks.size():
			var atk: Dictionary = atks[i]
			_row(list, "  " + atk.name, "monster:%s:%d" % [key, i],
				float(atk.get("reach", 0.0)), ENM_BONUS)

	# --- buttons ---
	outer.add_child(HSeparator.new())
	var save_btn := Button.new()
	save_btn.text = "Save  (keeps values across sessions)"
	save_btn.pressed.connect(_save)
	outer.add_child(save_btn)

	var print_btn := Button.new()
	print_btn.text = "Print final values to Godot Output"
	print_btn.pressed.connect(_print_final)
	outer.add_child(print_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset all to code defaults"
	reset_btn.pressed.connect(_reset)
	outer.add_child(reset_btn)


func _hdr(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(1.0, 0.9, 0.5)
	parent.add_child(lbl)


func _row(parent: Control, label_text: String, delta_key: String,
		base_reach: float, eff_bonus: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)

	var nm := Label.new()
	nm.text = label_text
	nm.custom_minimum_size.x = 145.0
	nm.add_theme_font_size_override("font_size", 10)
	nm.clip_text = true
	row.add_child(nm)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size.x = 90.0
	val_lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(val_lbl)

	var minus_btn := Button.new()
	minus_btn.text = "−"
	minus_btn.custom_minimum_size = Vector2(28, 22)
	minus_btn.pressed.connect(func() -> void: _adjust(delta_key, base_reach, eff_bonus, -STEP, val_lbl))
	row.add_child(minus_btn)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(28, 22)
	plus_btn.pressed.connect(func() -> void: _adjust(delta_key, base_reach, eff_bonus, STEP, val_lbl))
	row.add_child(plus_btn)

	_rows.append({key = delta_key, base = base_reach, bonus = eff_bonus, lbl = val_lbl})
	_refresh_label(val_lbl, base_reach, eff_bonus, delta_key)


func _refresh_label(lbl: Label, base: float, bonus: float, key: String) -> void:
	var delta := float(_deltas.get(key, 0.0))
	var cur   := base + delta
	var eff   := cur + bonus
	var d_str := ""
	if absf(delta) > 0.005:
		d_str = " (%+.1f)" % delta
	lbl.text = "%.1f%s → %.1f" % [cur, d_str, eff]
	lbl.modulate = Color(1.0, 0.65, 0.3) if delta > 0.005 else \
				   Color(0.5, 1.0, 0.5)   if delta < -0.005 else \
				   Color.WHITE


func _update_all_labels() -> void:
	for r: Dictionary in _rows:
		_refresh_label(r.lbl, r.base, r.bonus, r.key)


# ===========================================================================
# Adjust + live apply
# ===========================================================================

func _adjust(delta_key: String, base_reach: float, eff_bonus: float,
		step: float, lbl: Label) -> void:
	var old   := float(_deltas.get(delta_key, 0.0))
	var delta := snappedf(old + step, 0.001)
	if absf(delta) < 0.005:
		_deltas.erase(delta_key)
		delta = 0.0
	else:
		_deltas[delta_key] = delta
	_live_set(delta_key, base_reach + delta)
	_refresh_label(lbl, base_reach, eff_bonus, delta_key)


func _live_set(delta_key: String, new_reach: float) -> void:
	var parts := delta_key.split(":")
	if parts[0] == "weapon" and parts.size() >= 2:
		if Combat.WEAPONS.has(parts[1]):
			Combat.WEAPONS[parts[1]].reach = new_reach
	elif parts[0] == "monster" and parts.size() >= 3:
		if Monsters.LIST.has(parts[1]):
			var atks: Array = Monsters.LIST[parts[1]].attacks
			var idx := int(parts[2])
			if idx < atks.size():
				atks[idx].reach = new_reach


# ===========================================================================
# Save / Load / Reset / Print
# ===========================================================================

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_deltas, "\t"))
		f.close()
		print("HitboxDebug: saved %d override(s) to %s" % [_deltas.size(), SAVE_PATH])
	else:
		push_warning("HitboxDebug: could not open ", SAVE_PATH, " for writing")


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed := JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return
	_deltas = parsed
	for key: String in _deltas:
		var row := _find_row(key)
		if not row.is_empty():
			_live_set(key, float(row.base) + float(_deltas[key]))
	print("HitboxDebug: loaded %d override(s) from %s" % [_deltas.size(), SAVE_PATH])


func _reset() -> void:
	for key: String in _deltas.keys():
		var row := _find_row(key)
		if not row.is_empty():
			_live_set(key, float(row.base))
	_deltas.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_update_all_labels()
	print("HitboxDebug: reset all to code defaults")


func _print_final() -> void:
	print("\n=== HitboxDebug final values ===")
	print("--- Dwarf weapons ---")
	for w: String in ["sword", "axe", "mace", "spear", "axe_2h", "mace_2h", "shield", "pickaxe", "fists"]:
		if Combat.WEAPONS.has(w):
			print("  %s: reach = %.2f" % [w, float(Combat.WEAPONS[w].reach)])
	print("--- Enemies ---")
	for key: String in Monsters.LIST:
		var d: Dictionary = Monsters.LIST[key]
		for atk: Dictionary in d.get("attacks", []):
			print("  %s / %s: reach = %.2f" % [d.name, atk.name, float(atk.get("reach", 0.0))])
	print("================================\n")
	print("Paste any changed values to Claude to write them into the code permanently.")


func _find_row(key: String) -> Dictionary:
	for r: Dictionary in _rows:
		if r.key == key:
			return r
	return {}
