class_name Storage
extends Node
## Storage: chests, graves and Builder's Chests. A helper of the GameAuthority (Authority/Storage),
## same pattern: ask_* (your computer) → request_* (host approves) → _ev_* (everyone).
## Chests are shared in co-op: first come, first served.

const BOX_LAYER := 16  ## same layer as stations, so you can aim at them and press E
const REACH := 4.5
## Rows of 8 (owner, Nov 17): a barrel one row, a chest two, a stone chest three.
const SIZES := {"barrel": 8, "chest_small": 16, "chest_stone": 24, "chest_copper": 36, "crate_ore": 60, "grave": Inventory.EQUIP_START, "builder": 24,
	"rebuild": 24, "chest_loot": 16, "recipe_stand": 4}  ## (rebuild: the Rebuilding Chest at a ruin, owner Nov 19; docs/design/ruin-rebuild-plan.md)
## The Ore Crate only takes ores, stone types, clay and crystals (doc 8 storage table).
const ORE_CRATE := ["stone", "dirt", "moss", "clay", "copper_ore", "tin_ore", "silver_ore", "sporestone", "amberrock", "marble", "basalt", "brown_rock"]

var auth: GameAuthority
var boxes := {}  ## id -> {kind, inv: Inventory, node: Node3D, owner: int}
var _next_id := 1
var _root: Node3D


func _ready() -> void:
	auth = get_parent()
	_root = Node3D.new()
	_root.name = "Boxes"
	add_child(_root)


func get_box(id: int) -> Dictionary:
	return boxes.get(id, {})


static func box_id_of(collider: Object) -> int:
	if collider is Node and collider.has_meta("box_id"):
		return collider.get_meta("box_id")
	return -1


# ================================================================== ask

## Moves one whole stack: from the box to your bag (`from_box` true) or the other way.
func ask_transfer(box_id: int, from_box: bool, slot: int) -> void:
	if auth.is_host():
		request_transfer(auth.local_peer_id(), box_id, from_box, slot)
	else:
		_rpc_transfer.rpc_id(1, box_id, from_box, slot)


## The build hammer's E on a chest or barrel: pick it up to put it somewhere else (owner, Nov 17). Only when it's
## empty (its things would have nowhere to go), never a Builder's Chest or a grave.
func ask_pick_up(box_id: int) -> void:
	if auth.is_host():
		var why := request_pick_up(auth.local_peer_id(), box_id)
		if why != "":
			auth.hud_message.emit(why)
	else:
		_rpc_pick_up.rpc_id(1, box_id)


@rpc("any_peer", "reliable")
func _rpc_pick_up(box_id: int) -> void:
	if auth.is_host():
		request_pick_up(multiplayer.get_remote_sender_id(), box_id)


## "" = picked up, otherwise why not.
func request_pick_up(peer_id: int, box_id: int) -> String:
	var ps := auth.get_player(peer_id)
	var box := get_box(box_id)
	if ps == null or box.is_empty() or not Items.exists(box.kind):
		return "That can't be moved."
	if _far(ps, box):
		return "Too far away."
	for sl in box.inv.slots:
		if not sl.is_empty():
			return "Empty it first, then pick it up."
	var left: int = ps.inventory.add(box.kind, 1)
	if left > 0:
		auth.spawn_drop(box.kind, left, box.node.global_position + Vector3.UP)
	_ev_remove_box.rpc(box_id)
	return ""


func ask_take_all(box_id: int) -> void:
	if auth.is_host():
		request_take_all(auth.local_peer_id(), box_id)
	else:
		_rpc_take_all.rpc_id(1, box_id)


@rpc("any_peer", "reliable")
func _rpc_transfer(box_id: int, from_box: bool, slot: int) -> void:
	if auth.is_host():
		request_transfer(multiplayer.get_remote_sender_id(), box_id, from_box, slot)


@rpc("any_peer", "reliable")
func _rpc_take_all(box_id: int) -> void:
	if auth.is_host():
		request_take_all(multiplayer.get_remote_sender_id(), box_id)


# ================================================================== approve (host)

func request_transfer(peer_id: int, box_id: int, from_box: bool, slot: int) -> bool:
	var ps := auth.get_player(peer_id)
	var box := get_box(box_id)
	if ps == null or box.is_empty() or _far(ps, box):
		return false
	var src: Inventory = box.inv if from_box else ps.inventory
	var dst: Inventory = ps.inventory if from_box else box.inv
	var s := src.get_slot(slot)
	if s.is_empty():
		return false
	if not from_box and not accepts(box.kind, s.id):
		return false
	if _move_slot(src, slot, dst) == 0:
		return false
	_changed(box_id)
	return true


## Moves one slot into another bag. Slots with their own data (a half-empty waterskin's sips)
## move whole, so that data isn't lost. Returns how many items moved.
static func _move_slot(src: Inventory, i: int, dst: Inventory) -> int:
	var s := src.get_slot(i)
	if s.is_empty():
		return 0
	s.erase("worn")  # put in a box = taken off (F825)
	if s.size() > 2:
		for j in dst.slots.size():
			if dst.slots[j].is_empty():
				dst.slots[j] = s
				src.slots[i] = {}
				src.changed.emit()
				dst.changed.emit()
				return s.count
		return 0
	var moved: int = s.count - dst.add(s.id, s.count)
	if moved > 0:
		s.count -= moved
		if s.count <= 0:
			src.slots[i] = {}
		src.changed.emit()
	return moved


func request_take_all(peer_id: int, box_id: int) -> int:
	var ps := auth.get_player(peer_id)
	var box := get_box(box_id)
	if ps == null or box.is_empty() or _far(ps, box):
		return 0
	var moved := 0
	for i in box.inv.slots.size():
		moved += _move_slot(box.inv, i, ps.inventory)
	_changed(box_id)
	return moved


## What a box will hold. Builder's Chests only take building materials (and the rock they carve).
static func accepts(kind: String, item: String) -> bool:
	if kind == "crate_ore":
		return item in ORE_CRATE or item.begins_with("crystal_")
	if kind != "builder" and kind != "rebuild":
		return true
	if _piece_extras().has(item):
		return true  # fiber for rugs and banners, crystals for sconces...
	return Pieces.FAMILIES.has(item) or item in ["stone", "dirt", "moss", "clay", "copper_ore", "tin_ore", "copper_ingot",
		"sporestone", "amberrock", "silver_ore", "mushroom_flesh"]  # what a builder carves out of the Jungle


static var _extras_cache := {}


## Every extra item some building piece costs (besides its material).
static func _piece_extras() -> Dictionary:
	if _extras_cache.is_empty():
		for id in Pieces.LIST:
			for item in Pieces.LIST[id].get("extra", {}):
				_extras_cache[item] = true
	return _extras_cache


## Host: make a new box. Returns its id.
func create_box(kind: String, pos: Vector3, yaw: float, owner: int = 0) -> int:
	var id := _next_id
	_next_id += 1
	_ev_add_box.rpc(id, kind, pos, yaw, owner)
	return id


## Host: put items straight into a box (graves, carved rock).
func put(box_id: int, item: String, count: int) -> int:
	var box := get_box(box_id)
	if box.is_empty():
		return count
	var left: int = box.inv.add(item, count)
	_changed(box_id)
	return left


func _changed(box_id: int) -> void:
	var box := get_box(box_id)
	if box.is_empty():
		return
	var empty := true
	for s in box.inv.slots:
		if not s.is_empty():
			empty = false
	if empty and box.kind == "grave":
		_ev_remove_box.rpc(box_id)  # an emptied grave crumbles away
	else:
		_ev_box.rpc(box_id, box.inv.to_data())
	if box.kind == "rebuild" and auth and auth.builder:
		auth.builder.ruin_chest_changed(box_id)  # the first planks or cut stone start the rebuilding


func _far(ps: GameAuthority.PlayerState, box: Dictionary) -> bool:
	return ps.node.global_position.distance_to(box.node.global_position) > REACH + 1.5


# ================================================================== everyone updates

@rpc("authority", "call_local", "reliable")
func _ev_add_box(id: int, kind: String, pos: Vector3, yaw: float, owner: int) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = BOX_LAYER
	body.collision_mask = 0
	body.set_meta("box_id", id)
	_root.add_child(body)
	body.global_position = pos
	body.rotation.y = yaw
	_build_look(body, kind)
	boxes[id] = {kind = kind, inv = Inventory.new(SIZES.get(kind, 12)), node = body, owner = owner}
	# No pebbles, grass or mushrooms poking through a box (owner, Nov 19): they make room, on every computer.
	var room := 0.75
	if _is_furniture(kind):
		var fs: Vector3 = Pieces.LIST[kind].size
		room = maxf(fs.x, fs.z) * 0.5 + 0.1
	GroundSnap.take(pos, room)
	_next_id = maxi(_next_id, id + 1)


@rpc("authority", "call_local", "reliable")
func _ev_box(id: int, data: Array) -> void:
	var box := get_box(id)
	if not box.is_empty():
		box.inv.load_data(data)
		if box.kind == "crate_ore":
			show_fill(box.node, box.inv)
		elif box.kind == "recipe_stand":
			DungeonBuild.show_scroll(box.node, box.inv)


const CRATE_FULL := 400  ## the ore pile looks heaped-up at this many items (feedback F33)


## How full the Ore Crate looks: 0 = empty, 1 = heaped up.
static func fill_level(inv: Inventory) -> float:
	var n := 0
	for sl in inv.slots:
		if not sl.is_empty():
			n += int(sl.count)
	return clampf(float(n) / CRATE_FULL, 0.0, 1.0)


## The Ore Crate's pile of ore rises as you fill it (Claude 2's crate_ore_fill model).
static func show_fill(body: Node3D, inv: Inventory) -> void:
	var pile := body.get_node_or_null("Fill") as Node3D
	if pile == null:
		return
	var f := fill_level(inv)
	pile.visible = f > 0.0
	pile.scale = Vector3(1.0, 0.3 + 0.75 * sqrt(f), 1.0)  # a few ores already show; it heaps up slowly


@rpc("authority", "call_local", "reliable")
func _ev_remove_box(id: int) -> void:
	var box := get_box(id)
	boxes.erase(id)
	if not box.is_empty():
		box.node.queue_free()


## A storing piece of furniture (Furnish tab, `use = "store"`). Not the loot barrel: "barrel" is also a building
## piece (a solid decor barrel), but the loot barrel has its own model with a lid (two sessions' work met here, Nov 19).
static func _is_furniture(kind: String) -> bool:
	return Pieces.LIST.has(kind) and String(Pieces.LIST[kind].get("use", "")) == "store"


## Which stations model a box uses (the placing ghost uses it too, F632). It is turned around (PI) when shown.
static func model_id(kind: String) -> String:
	return "barrel_box" if kind == "barrel" else ("builder" if kind == "rebuild" else kind)


func _build_look(body: StaticBody3D, kind: String) -> void:
	if _is_furniture(kind):
		# Furniture that stores things (Furnish tab: cabinet, bookcase...): the built piece shows itself; the box
		# is only its inside, a touchable shape just around the piece.
		var fs: Vector3 = Pieces.LIST[kind].size + Vector3(0.04, 0.04, 0.04)
		var fcs := CollisionShape3D.new()
		var fsh := BoxShape3D.new()
		fsh.size = fs
		fcs.shape = fsh
		fcs.position = Vector3.UP * fs.y * 0.5
		body.add_child(fcs)
		return
	var size := Vector3(1.0, 0.7, 0.7) if kind != "grave" else Vector3(0.9, 0.6, 0.9)
	if kind == "barrel":
		size = Vector3(0.7, 0.9, 0.7)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = Vector3.UP * size.y * 0.5
	body.add_child(cs)
	var color: Color = {"chest_small": Color(0.55, 0.38, 0.22), "chest_stone": Color(0.55, 0.55, 0.55),
		"builder": Color(0.3, 0.45, 0.7), "rebuild": Color(0.45, 0.35, 0.25), "grave": Color(0.45, 0.43, 0.4)}.get(kind, Color.GRAY)
	# A loot barrel: its own model with a lid that swings open (owner, Nov 19); the building kit's barrel is solid.
	# (the Rebuilding Chest looks like a Builder's Chest)
	var model := Look.forged("stations", model_id(kind))  # a real model, if made
	if kind == "recipe_stand":  # a dungeon's recipe stand with its glowing scroll (owner, Nov 19)
		model = Look.forged("dungeon", "recipe_stand")
		var scroll := Look.forged("dungeon", "recipe_scroll")
		if model and scroll:
			scroll.name = "Scroll"  # (it rolls up and vanishes when its page is taken: DungeonBuild.show_scroll)
			scroll.position = Vector3(0.0, 0.90, 0.007)
			scroll.rotation.x = deg_to_rad(20.0)
			model.add_child(scroll)
	if model == null and kind == "barrel":
		model = Look.forged("build", "barrel__plank_root")
	if kind == "barrel":
		body.set_meta("slide_lid", true)  # (its lid lifts and slides aside, it doesn't swing: ChestOpen)
	if model:
		model.rotation.y = PI  # forged models face +Z; boxes face -Z
		body.add_child(model)
		var pile := Look.forged("stations", "crate_ore_fill") if kind == "crate_ore" else null
		if pile:
			pile.name = "Fill"
			pile.rotation.y = PI
			pile.visible = false
			body.add_child(pile)
	elif kind == "grave":
		# A little cairn of stones with a soft beam of light so you can find it again.
		for i in 5:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.28 - i * 0.03
			sm.height = sm.radius * 1.6
			sm.radial_segments = 6
			sm.rings = 3
			mi.mesh = sm
			mi.position = Vector3(sin(i * 2.4) * 0.15, 0.15 + i * 0.16, cos(i * 2.4) * 0.15)
			mi.material_override = _mat(color)
			body.add_child(mi)
		var beam := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.2
		cm.height = 12.0
		beam.mesh = cm
		var bmat := StandardMaterial3D.new()
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bmat.albedo_color = Color(1.0, 0.9, 0.6, 0.18)
		bmat.no_depth_test = true  # shows through rock, so you can find your way back
		beam.material_override = bmat
		beam.position = Vector3.UP * 6.5
		beam.visibility_range_begin = 6.0  # only from a distance (up close it would fill the screen)
		beam.visibility_range_end = 60.0
		body.add_child(beam)
	else:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.position = Vector3.UP * size.y * 0.5
		mi.material_override = _mat(color)
		body.add_child(mi)
		var lid := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(size.x + 0.05, 0.08, size.z + 0.05)
		lid.mesh = lm
		lid.position = Vector3.UP * (size.y + 0.02)
		lid.material_override = _mat(color.darkened(0.3))
		body.add_child(lid)
	var label := Label3D.new()
	label.text = {"builder": "Builder's Chest", "rebuild": "Rebuilding Chest", "grave": "Grave", "chest_loot": "Old Chest"}.get(kind, Items.display_name(kind))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3.UP * 1.3
	label.pixel_size = 0.004
	label.font_size = 36
	label.outline_size = 10
	body.add_child(label)
	label.visible = kind in ["builder", "grave"]  # no names over ordinary chests (owner, Nov 17); the Builder's Chest and graves keep theirs
	label.visibility_range_begin = 2.0
	label.visibility_range_end = 30.0


static func _mat(c: Color) -> Material:
	return Look.mat(c)


# ================================================================== late joiners

func snapshot() -> Array:
	var out := []
	for id in boxes:
		var b: Dictionary = boxes[id]
		out.append([id, b.kind, b.node.global_position, b.node.rotation.y, b.owner, b.inv.to_data()])
	return out


func load_snapshot(list: Array) -> void:
	for b in list:
		_ev_add_box(b[0], b[1], b[2], b[3], b[4])
		_ev_box(b[0], b[5])
