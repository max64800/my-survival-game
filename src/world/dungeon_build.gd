class_name DungeonBuild
extends Node3D
## Builds a dungeon's insides in the game (owner, Nov 19): the root wood floors, walls, ceilings and doorways, the
## traps, doors, furniture and torches, from the dungeon's plan (blueprints/dungeons/<map>.json, made by
## tools/dungeons/make_mossgate.py; the 3D page "Mossgate Hold 3D" shows the same file).
## Every computer builds the same thing from the world number (the Cave Maker's dungeon spot + the plan). Repeated
## models are drawn in batches (MultiMesh), so 1,700 pieces cost about as much as 60. The walls can't be broken.
##
## Things you CAN break (owner's first play, Nov 19) are built one by one, each with its own body: furniture and crates
## (smash them: a little root wood + small finds), the rubble wall, the hidden boulder (exactly like a cave boulder),
## the stalactites (they fall when you walk under them, or when a bolt hits them) and the cracked floor tiles over the
## spike pit (they give way under you). Co-op: you ask -> the host decides (hits, falls) -> everyone sees it. The host
## keeps what's broken in world_state.dungeon_broken (saved, and sent to friends who join).
## Falling into the chasm or the spike pit kills you (decisions: instant death; the grave goes where you last stood).

const PLANS := {"mossgate": "res://blueprints/dungeons/mossgate_hold.json"}
## What you bump into, in each model's own metres: [centre, size] boxes. Models not listed and not in NO_BODY get
## the box round the whole model.
const BOXES := {
	"build/floor__plank_root.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"dungeon/floor_old.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"dungeon/floor_loose_stone.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"dungeon/trap_floor_break.glb": [[Vector3(0, 0.12, 0), Vector3(2, 0.24, 2)]],
	"build/wall__plank_root.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/wall_old.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/trap_dart_wall.glb": [[Vector3(0, 1, 0), Vector3(2, 2, 0.29)]],
	"dungeon/wall_cracked.glb": [[Vector3(0, 1, 0.05), Vector3(2, 2, 0.35)]],
	"build/wall_narrow__plank_root.glb": [[Vector3(0, 1, 0), Vector3(1, 2, 0.26)]],
	"build/half_wall__plank_root.glb": [[Vector3(0, 0.5, 0), Vector3(2, 1, 0.27)]],
	# The round doorway: its two sides and the top (the hole is about 1.3 m wide and 1.75 m high; the dungeon uses it
	# at 1.5x, and the boxes grow with it).
	"build/doorway__plank_root.glb": [[Vector3(-0.83, 1, 0), Vector3(0.34, 2, 0.25)], [Vector3(0.83, 1, 0), Vector3(0.34, 2, 0.25)],
		[Vector3(0, 1.88, 0), Vector3(1.4, 0.24, 0.25)]],
	"build/column__plank_root.glb": [[Vector3(0, 1, 0), Vector3(0.7, 2, 0.7)]],
	# The bridge: just its deck, its top level with the floor boards (fall off the side and you fall). The posts: the two
	# posts and the deck between them (owner, Nov 19: one box round the whole frame blocked the way onto the bridge).
	"dungeon/bridge_plank.glb": [[Vector3(0, 0.055, 0), Vector3(1.3, 0.11, 2.0)]],
	"dungeon/bridge_plank_broken.glb": [[Vector3(0, 0.055, 0), Vector3(1.3, 0.11, 2.0)]],
	"dungeon/bridge_posts.glb": [[Vector3(-0.64, 0.68, -0.05), Vector3(0.2, 1.2, 0.2)], [Vector3(0.64, 0.68, -0.05), Vector3(0.2, 1.2, 0.2)],
		[Vector3(0, 0.055, 0.6), Vector3(1.3, 0.11, 0.8)]],
	"dungeon/door_loot.glb": [[Vector3(0, 0.75, 0), Vector3(1.5, 1.5, 0.16)]],
	"dungeon/gate_round.glb": [[Vector3(0, 0.75, 0.03), Vector3(1.5, 1.5, 0.15)]],
	# The round stone door's frame: its two stone sides and the top (you walk through its middle).
	"dungeon/dungeon_entrance.glb": [[Vector3(-1.2, 1.3, 0), Vector3(0.66, 2.6, 0.5)], [Vector3(1.2, 1.3, 0), Vector3(0.66, 2.6, 0.5)],
		[Vector3(0, 2.4, 0), Vector3(3.0, 0.6, 0.5)]],
}
## Things you walk through (small, up high, or traps whose moves come later).
const NO_BODY := ["decor/furn_wall_torch_iron.glb", "dungeon/trap_dart_plate.glb", "dungeon/chain_hanging.glb",
	"dungeon/recipe_scroll.glb", "treasure/tr_coins_wide.glb", "treasure/tr_chalice.glb",
	"decor/fossil_plaque.glb", "decor/rune_shield.glb", "dungeon/trap_crusher.glb",
	"build/ruin_rubble__cut_stone.glb", "dungeon/railing_broken.glb", "dungeon/lever.glb", "dungeon/recipe_stand.glb"]

## Furniture you can smash (owner, decisions round 2: "a little root wood + small finds").
const SMASH := ["decor/crate_stack.glb", "decor/keg.glb", "props/barrel.glb", "decor/furn_barrel_rack.glb",
	"decor/grain_sacks.glb", "decor/shack_shelf.glb", "decor/shack_table.glb", "decor/shack_stool.glb", "decor/shack_bench.glb",
	"decor/furn_weapon_stand.glb", "decor/furn_whetstone.glb", "decor/furn_candle_stand.glb", "decor/furn_vase_tall.glb",
	"decor/furn_vase_wide.glb", "decor/furn_cauldron.glb", "decor/firewood_rack.glb", "decor/furn_banner_tall_1.glb",
	"decor/furn_banner_tall_2.glb"]
const DRIPS := ["dungeon/trap_drip_thin.glb", "dungeon/trap_drip_fat.glb", "dungeon/trap_drip_cluster.glb"]
const SMASH_HITS := 3
const RUBBLE_HITS := 4
const SMALL_FINDS := [["gold_coin", 2], ["rope", 1], ["bandage", 1], ["bolt_stone", 3], ["coal", 2]]
const SMALL_FIND_CHANCE := 0.35
const DRIP_DAMAGE := 50.0     ## a falling stalactite always hurts this much (decisions round 2)
const DRIP_WARN := 0.45       ## seconds of dust and cracking before it lets go
const DRIP_PART_GAP := 0.2    ## a cluster's stalactites fall one by one, this far apart
const DRIP_REACH := 1.3       ## walk within this (sideways) under one and it falls
const DRIP_LENGTH := 1.4      ## how far a stalactite's tip hangs below its base
const FLOOR_GIVE := 0.4       ## seconds a cracked floor tile holds you before it breaks
const KILL := 1000000.0       ## instant death (more than any health and armour)
const THING_ID := 10000       ## a thing's id: dungeon index * THING_ID + its prop index in the plan
const STONE := Color(0.5, 0.46, 0.41)
const WOOD := Color(0.45, 0.32, 0.2)

static var instance: DungeonBuild

var maker: CaveMaker
var built := 0  ## how many models were placed (tests)
var things := {}  ## id -> {kind, model, node: StaticBody3D, prop, d, centre: Vector3, landing: float}
var _applied := 0  ## how many of world_state.dungeon_broken this computer has shown
var _hits := {}    ## host: thing id -> hits so far
var _standing := {}  ## host: floor tile id -> seconds someone has stood on it
var _dead_at := {}   ## host: peer -> when we last killed them (no double kills while they respawn)
var _clock := 0.0
var _host_tick := 0.0


static func load_plan(map_id: String) -> Dictionary:
	var path: String = PLANS.get(map_id, "")
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


## What a plan prop is: "smash", "rubble", "boulder", "drip", "floor" (breakable, built one by one) or "" (batched).
static func thing_kind(p: Dictionary) -> String:
	var model := String(p.model)
	if model in SMASH:
		return "smash"
	if model in DRIPS:
		return "drip"
	if model == "dungeon/trap_floor_break.glb":
		return "floor"
	if model == "dungeon/wall_broken.glb":
		return "rubble"
	if model.begins_with("cave/boulder_"):
		return "boulder"
	return ""


static func _xform(d: Dictionary, pos: Array, yaw_deg: float, scale: float, tilt_deg: float) -> Transform3D:
	var b := Basis(Vector3.UP, float(d.turn) * PI / 2.0 + deg_to_rad(yaw_deg)) * Basis(Vector3.RIGHT, deg_to_rad(tilt_deg))
	return Transform3D(b.scaled_local(Vector3.ONE * scale), DungeonMap.to_world(d, Vector3(pos[0], pos[1], pos[2])))


## Where each model goes in the world: {model path: [Transform3D, ...]} for one placed dungeon. `game` = only what
## the game draws in batches (no breakable things: built one by one; no chests: Storage boxes draw themselves).
static func placements(d: Dictionary, plan: Dictionary, game := false) -> Dictionary:
	var out := {}
	var add := func(model: String, t: Transform3D) -> void:
		if not out.has(model):
			out[model] = []
		out[model].append(t)
	for p in plan.get("pieces", []):
		var r := int(p.rot)
		var steps := r * 3 if r < 4 else r - 4
		add.call("build/%s__%s.glb" % [p.id, p.mat], _xform(d, p.pos, steps * 30.0, float(p.get("scale", 1.0)), 0.0))
	for p in plan.get("props", []):
		if game and (thing_kind(p) != "" or p.get("role", "") == "loot"):
			continue  # (breakables are built one by one; the recipe stand is a Storage box that draws itself)
		add.call(String(p.model), _xform(d, p.pos, float(p.yaw), float(p.get("scale", 1.0)), float(p.get("tilt", 0.0))))
	if not game:
		for c in plan.get("chests", []):
			add.call("stations/%s.glb" % c.kind, _xform(d, c.pos, float(c.yaw), 1.0, 0.0))
	return out


func _ready() -> void:
	name = "DungeonBuild"
	instance = self
	for di in maker.dungeons.size():
		var d: Dictionary = maker.dungeons[di]
		var plan := load_plan(String(d.id))
		if plan.is_empty():
			push_warning("DungeonBuild: no plan for %s" % d.id)
			continue
		_build(d, plan)
		_build_things(di, d, plan)


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _build(d: Dictionary, plan: Dictionary) -> void:
	var root := Node3D.new()
	root.name = String(d.id)
	add_child(root)
	var body := StaticBody3D.new()  # one body for every wall and floor: solid, and the pickaxe doesn't dig through it
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	body.add_to_group(RuinKit.GROUP)
	root.add_child(body)
	var all := placements(d, plan, true)
	for model in all:
		var scene := _scene(String(model))
		if scene == null:
			continue
		var xforms: Array = all[model]
		var inst := scene.instantiate() as Node3D
		var whole := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var rel := _rel_xform(inst, m)
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = _own_mesh(m)
			mm.instance_count = xforms.size()
			for i in xforms.size():
				mm.set_instance_transform(i, (xforms[i] as Transform3D) * rel)
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			root.add_child(mmi)
			var box := rel * m.get_aabb()
			whole = box if first else whole.merge(box)
			first = false
		inst.free()
		built += xforms.size()
		if String(model) in NO_BODY:
			continue
		for t in xforms:
			_add_boxes(body, String(model), t as Transform3D, whole)
	# Torch light (it counts as light, so you heal by the torches: Darkness).
	for l in plan.get("lights", []):
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.68, 0.38)
		o.light_energy = 1.6
		o.omni_range = 9.0
		o.position = DungeonMap.to_world(d, Vector3(l[0], l[1], l[2]))
		root.add_child(o)
		Darkness.mark(o)
	print("DUNGEON_BUILD %s: %d models placed" % [d.id, built])


## The breakable things, each its own body (meta "dungeon_thing" = its id) so it can be hit, shot and taken away.
func _build_things(di: int, d: Dictionary, plan: Dictionary) -> void:
	var props: Array = plan.get("props", [])
	for i in props.size():
		var p: Dictionary = props[i]
		var kind := thing_kind(p)
		if kind == "":
			continue
		var scene := _scene(String(p.model))
		if scene == null:
			continue
		var t := _xform(d, p.pos, float(p.yaw), float(p.get("scale", 1.0)), float(p.get("tilt", 0.0)))
		var id := di * THING_ID + i
		var body := StaticBody3D.new()
		body.name = "Thing%d" % id
		body.collision_layer = World.TERRAIN_LAYER
		body.collision_mask = 0
		body.set_meta("dungeon_thing", id)
		add_child(body)
		var inst := scene.instantiate() as Node3D
		inst.transform = t
		body.add_child(inst)
		var whole := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var box := _rel_xform(inst, mi as Node3D) * (mi as MeshInstance3D).get_aabb()
			whole = box if first else whole.merge(box)
			first = false
		_add_boxes(body, String(p.model), t, whole)
		var landing := DungeonMap.to_world(d, Vector3(p.pos[0], 0.24, p.pos[2])).y  # (where a stalactite lands: floor or bridge)
		things[id] = {kind = kind, model = String(p.model), node = body, prop = p, d = d,
			centre = t * whole.get_center(), radius = whole.size.length() * 0.5 * float(p.get("scale", 1.0)), landing = landing}
	_apply_broken()


func _scene(model: String) -> PackedScene:
	var path := "res://assets/models/" + model
	var scene := load(path) as PackedScene if ResourceLoader.exists(path) else null
	if scene == null:
		push_warning("DungeonBuild: missing model %s" % path)
	return scene


## A mesh with the model's own materials on it (overrides on the node, or the mesh's).
static func _own_mesh(m: MeshInstance3D) -> Mesh:
	var mesh := m.mesh
	if m.material_override or m.get_surface_override_material_count() > 0:
		mesh = mesh.duplicate()
		for s in mesh.get_surface_count():
			var mat: Material = m.material_override if m.material_override else m.get_surface_override_material(s)
			if mat:
				mesh.surface_set_material(s, mat)
	return mesh


func _add_boxes(body: StaticBody3D, model: String, t: Transform3D, whole: AABB) -> void:
	var boxes: Array = BOXES.get(model, [[whole.get_center(), whole.size]])
	for bx in boxes:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		var sc := t.basis.get_scale()
		sh.size = ((bx[1] as Vector3) * sc).abs()
		cs.shape = sh
		cs.transform = Transform3D(t.basis.orthonormalized(), t * (bx[0] as Vector3))
		body.add_child(cs)


static func _rel_xform(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root:
		if c is Node3D:
			t = (c as Node3D).transform * t
		c = c.get_parent()
	return t


## The thing a collider belongs to (-1 = none).
static func id_of(collider: Object) -> int:
	if collider is Node and (collider as Node).has_meta("dungeon_thing"):
		return int((collider as Node).get_meta("dungeon_thing"))
	return -1


# ================================================================== breaking things (request -> host -> everyone)

## Our swing (or bolt: `by_bolt`) hit thing `id`.
func ask_hit(id: int, by_bolt := false) -> void:
	var auth := GameAuthority.instance
	if auth == null:
		return
	if auth.is_host():
		request_hit(auth.local_peer_id(), id, by_bolt)
	else:
		_rpc_hit.rpc_id(1, id, by_bolt)


@rpc("any_peer", "reliable")
func _rpc_hit(id: int, by_bolt: bool) -> void:
	var auth := GameAuthority.instance
	if auth and auth.is_host():
		request_hit(multiplayer.get_remote_sender_id(), id, by_bolt)


## Host: a hit on a thing. Smashing furniture: SMASH_HITS hits, then a little root wood and maybe a small find.
## The hidden boulder: exactly like a cave boulder (stone every hit, Boulders.HITS hits, then it bursts). A bolt that
## hits a stalactite brings it down.
func request_hit(peer_id: int, id: int, by_bolt := false) -> void:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	var th: Dictionary = things.get(id, {})
	if ps == null or th.is_empty() or is_broken(id):
		return
	var at: Vector3 = th.centre
	if th.kind == "drip":
		if by_bolt:
			_fall(id)
		return
	if by_bolt or th.kind == "floor":
		return
	var chest := ps.node.global_position + Vector3.UP * 1.1
	if chest.distance_to(at) > GameAuthority.REACH + float(th.radius) + 0.5:
		return
	var out := (chest - at).normalized()
	var hits: int = _hits.get(id, 0) + 1
	_hits[id] = hits
	match String(th.kind):
		"boulder":
			var pick := Items.kind(ps.selected_item()) == "pickaxe"
			if not pick and ps.selected_item() != "":
				auth._tell_feedback(peer_id, {state = "no_tool", point = at})
				_hits[id] = hits - 1
				return
			auth.spawn_drop("stone", 2 if pick else 1, at + out * 1.6 + Vector3.UP * 0.3)
			auth.give_xp(peer_id, 1, "mining")
			if hits >= Boulders.HITS:
				auth._tell_feedback(peer_id, {state = "dug", hits = hits, needed = Boulders.HITS, material = Mat.STONE, point = at, normal = out, boulder = true})
				_break(id)
			else:
				auth._tell_feedback(peer_id, {state = "hit", hits = hits, needed = Boulders.HITS, material = Mat.STONE, point = at, normal = out})
		"rubble":
			auth.spawn_drop("stone", 1, at + out * 0.8 + Vector3.UP * 0.3)
			if hits >= RUBBLE_HITS:
				_break(id)
			else:
				_ev_hit.rpc(id)
		_:
			if hits >= SMASH_HITS:
				auth.spawn_drop("rootwood", randi_range(1, 2), at + out * 0.5 + Vector3.UP * 0.3)
				if randf() < SMALL_FIND_CHANCE:
					var f: Array = SMALL_FINDS.pick_random()
					auth.spawn_drop(String(f[0]), int(f[1]), at + out * 0.5 + Vector3.UP * 0.5)
				_break(id)
			else:
				_ev_hit.rpc(id)


## Host: thing `id` is gone for good (saved; friends who join see it gone too).
func _break(id: int) -> void:
	var auth := GameAuthority.instance
	_hits.erase(id)
	var list: Array = auth.world_state.get("dungeon_broken", []).duplicate()
	if id in list:
		return
	list.append(id)
	auth.world_state["dungeon_broken"] = list
	_ev_broke.rpc(id)
	auth._ev_state.rpc(auth.world_state)


func is_broken(id: int) -> bool:
	var auth := GameAuthority.instance
	return auth != null and id in auth.world_state.get("dungeon_broken", [])


@rpc("authority", "call_local", "reliable")
func _ev_hit(id: int) -> void:
	var th: Dictionary = things.get(id, {})
	if th.is_empty():
		return
	var stone: bool = th.kind != "smash"
	Fx.burst(get_parent(), th.centre, STONE if stone else WOOD, 8, 2.5)
	Sfx.play("dig" if stone else "chop", th.centre, -3.0)


## Everyone: thing `id` breaks now (with its burst / fall).
@rpc("authority", "call_local", "reliable")
func _ev_broke(id: int) -> void:
	var th: Dictionary = things.get(id, {})
	if th.is_empty() or th.get("gone", false):
		return
	match String(th.kind):
		"boulder":  # exactly like a cave boulder breaking (Boulders.set_broken)
			var mid: Vector3 = th.centre
			var sc := float(th.prop.get("scale", 1.0))
			RockShatter.burst(get_parent(), mid + Vector3.UP * 0.2 * sc, Vector3.UP, Boulders.STONE, Mat.STONE)
			RockShatter.burst(get_parent(), mid, Vector3(1, 0.5, 0), Boulders.STONE, Mat.STONE)
			if sc > 2.5:
				RockShatter.burst(get_parent(), mid - Vector3.UP * 0.2 * sc, Vector3(-1, 0.5, 0.3), Boulders.STONE, Mat.STONE)
		"rubble":
			RockShatter.burst(get_parent(), th.centre, Vector3.UP, STONE, Mat.STONE)
		"floor":
			Fx.burst(get_parent(), th.centre, WOOD, 24, 3.0, Vector3.DOWN)
			Sfx.play("chop", th.centre, 0.0, 0.7)
		"drip":
			_drop_drip(id)
			return
		_:
			Fx.burst(get_parent(), th.centre, WOOD, 16, 3.0)
			Sfx.play("chop", th.centre, 0.0, 0.8)
	_hide(id)


func _hide(id: int) -> void:
	var th: Dictionary = things.get(id, {})
	if th.is_empty() or th.get("gone", false):
		return
	th.gone = true
	if th.kind == "drip":  # (its rock stays on the ceiling; its stones are gone)
		for part in _parts(th.node):
			(part as Node3D).visible = false
		for c in (th.node as Node).get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
		return
	(th.node as Node).queue_free()


## Show what the host says is broken (on loading, joining, or after a change).
func _apply_broken() -> void:
	var auth := GameAuthority.instance
	if auth == null:
		return
	var list: Array = auth.world_state.get("dungeon_broken", [])
	if list.size() == _applied:
		return
	_applied = list.size()
	for id in list:
		_hide(int(id))


# ================================================================== stalactites and the spike pit's floor

## Host: a stalactite lets go (someone walked under it, or a bolt hit it).
func _fall(id: int) -> void:
	if is_broken(id):
		return
	_break(id)
	var th: Dictionary = things[id]
	var parts := _parts(th.node)
	var drop := maxf(0.5, (th.node as Node3D).get_child(0).global_position.y - DRIP_LENGTH - float(th.landing))
	var land_t := DRIP_WARN + sqrt(2.0 * drop / 9.8)
	var hurt_once := {}
	for k in parts.size():
		get_tree().create_timer(land_t + k * DRIP_PART_GAP).timeout.connect(_drip_lands.bind(id, hurt_once))


## Host: a falling stalactite reaches the floor: whoever stands under it is hurt (once per stalactite).
func _drip_lands(id: int, hurt_once: Dictionary) -> void:
	var auth := GameAuthority.instance
	var th: Dictionary = things.get(id, {})
	if auth == null or th.is_empty():
		return
	var c: Vector3 = th.centre
	for pid in auth.players:
		var p: Vector3 = auth.players[pid].node.global_position
		if hurt_once.has(pid) or Vector2(p.x - c.x, p.z - c.z).length() > 1.0 or p.y < float(th.landing) - 1.0 or p.y > c.y:
			continue
		hurt_once[pid] = true
		auth.hurt(pid, DRIP_DAMAGE)


## Everyone: dust and a crack, then the stalactite (a cluster: each of its parts, one after another) drops.
func _drop_drip(id: int) -> void:
	var th: Dictionary = things[id]
	th.gone = true
	var body: StaticBody3D = th.node
	for c in body.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).disabled = true
	var top: Vector3 = th.centre
	Fx.burst(get_parent(), top, STONE, 10, 1.5, Vector3.DOWN)
	Sfx.play("dig", top, 0.0, 0.6)
	var parts := _parts(body)
	for k in parts.size():
		var part: Node3D = parts[k]
		var y0 := part.global_position.y
		var drop := maxf(0.5, y0 - DRIP_LENGTH - float(th.landing))
		var tw := create_tween()
		tw.tween_interval(DRIP_WARN + k * DRIP_PART_GAP)
		tw.tween_property(part, "global_position:y", y0 - drop, sqrt(2.0 * drop / 9.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			RockShatter.burst(get_parent(), part.global_position, Vector3.UP, STONE, Mat.STONE, 0.6)
			Sfx.play("dig", part.global_position, 2.0, 0.8)
			part.visible = false)


## A stalactite model's falling stones ("stone", or a cluster's "stone0".."stone4"); its "rock" stays on the ceiling.
static func _parts(body: Node) -> Array:
	var out := []
	for mi in body.find_children("stone*", "MeshInstance3D", true, false):
		out.append(mi)
	out.sort_custom(func(a, b): return String(a.name) < String(b.name))
	return out


# ================================================================== host: traps that watch where you stand

func _physics_process(delta: float) -> void:
	_clock += delta
	_apply_broken()
	var auth := GameAuthority.instance
	if auth == null or not auth.is_host():
		return
	_host_tick -= delta
	if _host_tick > 0.0:
		return
	var step := 0.1
	_host_tick = step
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node == null:
			continue
		var p := node.global_position
		_check_deadly_drop(auth, pid, p)
		for id in things:
			var th: Dictionary = things[id]
			if th.get("gone", false) or is_broken(id):
				continue
			var c: Vector3 = th.centre
			var flat := Vector2(p.x - c.x, p.z - c.z).length()
			if th.kind == "drip" and flat < DRIP_REACH and p.y < c.y and p.y > float(th.landing) - 1.0:
				_fall(id)
			elif th.kind == "floor":
				var q := DungeonMap.to_local(th.d, p)
				var tile: Array = th.prop.pos
				if absf(q.x - float(tile[0])) < 1.0 and absf(q.z - float(tile[2])) < 1.0 and q.y > -0.3 and q.y < 0.9:
					_standing[id] = float(_standing.get(id, 0.0)) + step
					if _standing[id] >= FLOOR_GIVE:
						_standing.erase(id)
						_break(id)


## Host: below the floor of the chasm or the spike pit (a space whose floor is under 0) = on the spikes: dead.
func _check_deadly_drop(auth: GameAuthority, pid: int, p: Vector3) -> void:
	if _clock - float(_dead_at.get(pid, -100.0)) < 5.0:
		return
	for d in maker.dungeons:
		var pit := deadly_space(d, p)
		if pit != "":
			_dead_at[pid] = _clock
			print("DUNGEON %s: player %d fell into the %s" % [d.id, pid, pit])
			auth.hurt(pid, KILL)
			return


## The deadly drop `p` has fallen into ("chasm", "spike_pit"; "" = none): down among the spikes of a space whose
## floor is below the dungeon's floor.
static func deadly_space(d: Dictionary, p: Vector3) -> String:
	if not DungeonMap.near_box(d, p, 2.0):
		return ""
	var q := DungeonMap.to_local(d, p)
	for s in d.map.spaces:
		if float(s[5]) < 0.0 and q.x > float(s[1]) - 0.5 and q.x < float(s[3]) + 0.5 and q.z > float(s[2]) - 0.5 				and q.z < float(s[4]) + 0.5 and q.y < float(s[5]) + 1.2:
			return String(s[0])
	return ""


# ================================================================== chests (host, once, when the world is made)

## Loot for each kind of chest in the plan (decisions: the loot room holds good Zone 1 things + a chance of a rare
## find; the rare finds list comes with the loot tables). [item, min, max, chance]
const LOOT := {
	"random": [["gold_coin", 3, 8, 1.0], ["rope", 1, 3, 0.5], ["bandage", 1, 3, 0.5], ["copper_ingot", 2, 4, 0.35],
		["bolt_stone", 4, 10, 0.4], ["coal", 3, 6, 0.4], ["crystal_torch", 1, 2, 0.25]],
	"vault": [["gold_coin", 12, 20, 1.0], ["copper_ingot", 5, 8, 1.0], ["silver_ore", 3, 5, 0.6], ["crystal_white", 1, 1, 0.3]],
	"buried": [["gold_coin", 8, 14, 1.0], ["bolt_metal", 6, 10, 0.8], ["bandage", 2, 4, 0.6]],
	"big": [["gold_coin", 25, 40, 1.0], ["copper_ingot", 8, 12, 1.0], ["bolt_metal", 10, 16, 1.0], ["bandage", 4, 6, 1.0],
		["leather", 3, 5, 0.6], ["crystal_white", 1, 2, 0.35], ["blueprint_page", 1, 1, 0.2]],
}
const RANDOM_CHEST_CHANCE := 0.65  ## a "random chest" is there in about 2 of 3 worlds


## Host, new world: every dungeon's chests become real chests with loot (saved and sent like any chest), and the loot
## room's recipe stand holds its dungeon's page (always the same recipe: decisions round 4).
static func add_chests(auth: GameAuthority, p_maker: CaveMaker) -> void:
	for d in p_maker.dungeons:
		var plan := load_plan(String(d.id))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([p_maker.seed, String(d.id), "chests"])
		for c in plan.get("chests", []):
			if not c.get("always", false) and rng.randf() > RANDOM_CHEST_CHANCE:
				continue
			var t := _xform(d, c.pos, float(c.yaw) + 180.0, 1.0, 0.0)  # (box fronts face -Z, the models +Z)
			var id: int = auth.storage.create_box(String(c.kind), t.origin, t.basis.get_euler().y)
			for row in LOOT.get(String(c.get("loot", "random")), LOOT.random):
				if rng.randf() < float(row[3]) and Items.exists(String(row[0])):
					auth.storage.put(id, String(row[0]), rng.randi_range(int(row[1]), int(row[2])))
			if String(c.get("loot", "")) == "big":  # the last chest always holds 1 of the dungeon's gems (gems.md)
				auth.storage.put(id, Gems.item_id(Gems.end_chest_gem(String(d.id), rng.randf(), rng.randf())), 1)
		var stand: Dictionary = plan.get("recipe_stand", {})
		if not stand.is_empty() and Items.exists(String(stand.page)):
			var t := _xform(d, stand.pos, float(stand.yaw) + 180.0, 1.0, 0.0)
			var sid: int = auth.storage.create_box("recipe_stand", t.origin, t.basis.get_euler().y)
			auth.storage.put(sid, String(stand.page), 1)
		print("DUNGEON_CHESTS %s placed" % d.id)
