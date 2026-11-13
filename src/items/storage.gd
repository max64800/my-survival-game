class_name Storage
extends Node
## Storage: chests, graves and Builder's Chests. A helper of the GameAuthority (Authority/Storage),
## same pattern: ask_* (your computer) → request_* (host approves) → _ev_* (everyone).
## Chests are shared in co-op: first come, first served.

const BOX_LAYER := 16  ## same layer as stations, so you can aim at them and press E
const REACH := 4.5
const SIZES := {"chest_small": 12, "chest_stone": 24, "grave": Inventory.SIZE, "builder": 24}

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
	var left := dst.add(s.id, s.count)
	var moved: int = s.count - left
	if moved == 0:
		return false
	src.remove(s.id, moved)
	_changed(box_id)
	return true


func request_take_all(peer_id: int, box_id: int) -> int:
	var ps := auth.get_player(peer_id)
	var box := get_box(box_id)
	if ps == null or box.is_empty() or _far(ps, box):
		return 0
	var moved := 0
	for i in box.inv.slots.size():
		var s: Dictionary = box.inv.slots[i]
		if s.is_empty():
			continue
		var n: int = s.count - ps.inventory.add(s.id, s.count)
		if n > 0:
			box.inv.remove(s.id, n)
			moved += n
	_changed(box_id)
	return moved


## What a box will hold. Builder's Chests only take building materials (and the rock they carve).
static func accepts(kind: String, item: String) -> bool:
	if kind != "builder":
		return true
	return Pieces.FAMILIES.has(item) or item in ["stone", "dirt", "moss", "clay", "copper_ore", "copper_ingot"]


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
	_next_id = maxi(_next_id, id + 1)


@rpc("authority", "call_local", "reliable")
func _ev_box(id: int, data: Array) -> void:
	var box := get_box(id)
	if not box.is_empty():
		box.inv.load_data(data)


@rpc("authority", "call_local", "reliable")
func _ev_remove_box(id: int) -> void:
	var box := get_box(id)
	boxes.erase(id)
	if not box.is_empty():
		box.node.queue_free()


func _build_look(body: StaticBody3D, kind: String) -> void:
	var size := Vector3(1.0, 0.7, 0.7) if kind != "grave" else Vector3(0.9, 0.6, 0.9)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = Vector3.UP * size.y * 0.5
	body.add_child(cs)
	var color: Color = {"chest_small": Color(0.55, 0.38, 0.22), "chest_stone": Color(0.55, 0.55, 0.55),
		"builder": Color(0.3, 0.45, 0.7), "grave": Color(0.45, 0.43, 0.4)}.get(kind, Color.GRAY)
	if kind == "grave":
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
		bmat.albedo_color = Color(1.0, 0.9, 0.6, 0.25)
		bmat.no_depth_test = true  # shows through rock, so you can find your way back
		beam.material_override = bmat
		beam.position = Vector3.UP * 6.5
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
	label.text = {"chest_small": "Chest", "chest_stone": "Stone Chest", "builder": "Builder's Chest", "grave": "Grave"}.get(kind, kind)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3.UP * 1.3
	label.pixel_size = 0.004
	label.font_size = 36
	label.outline_size = 10
	body.add_child(label)
	label.visibility_range_begin = 2.0
	label.visibility_range_end = 30.0


static func _mat(c: Color) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


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
