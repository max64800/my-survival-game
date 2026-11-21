class_name LootProps
extends Node
## Lootable decor (handover Nov 22, section 4): a coin chest, a charcoal bay, an ingot cart... You press E, you get
## its few items, and the model swaps to its "_empty" twin (decor/<id>_empty.glb) for everyone. The full model stays
## full-looking even though it gives only a few things (owner). A model with a "lid" part (the strongbox,
## kit.save(lid=...)) opens its lid like a chest instead (ChestOpen) and stays open.
## One code path for dungeons AND ruins: DungeonBuild (blueprints/dungeons/*.json) and the ruin plans
## (blueprints/ruins/*.json, read here from world_state.ruins) both call place().
## Co-op: you ask -> the host checks and gives the items -> everyone swaps the model. What is looted is the host's
## world_state.props_looted (a list of keys: saved with the world, sent to friends who join), so it stays looted.
## A child of the GameAuthority ("LootProps": the same path on every computer, for the messages).
##
## CONTRACT (the plans other chats write):
##   a plan prop {"model": "decor/<id>.glb", "pos": [x, y, z], "yaw": deg, "scale": 1.0, "role": "lootable",
##                "label": "Coin chest"}
##   - <id> must be in LOOT below (what it gives); its empty look is decor/<id>_empty.glb (or a "lid" part).
##   - "label" (optional) names it in the "You take ... from the <label>." message; else NAMES, else "Loot".
##     (The aim line shows only "E to take", owner F134.)
##   - a "lootable" prop whose <id> is not in LOOT is drawn as ordinary decor (nothing to take).
##   Keys: "d:<dungeon id>:<prop index>" in a dungeon, "r:<ruin record key>:<prop index>" in a ruin.
##   Special pieces (any role, normally "decor"): bv_vault_door_forced and vo_spyhole_wall get collision boxes that
##   leave their round doorway / spyhole open (DungeonBuild.BOXES); bv_strongbox is "lootable" (its lid opens).

const ROLE := "lootable"
const REACH := 3.0       ## like a dungeon door's E (DungeonBuild.USE_REACH); the host allows a little more
const CHECK_EVERY := 0.5
## What each lootable model gives (the amounts are the owner's, from the build files' headers; tools/asset_forge/
## builds/decor_nov21_*.py). Items the game doesn't have were swapped for the closest one that exists:
## bronze and iron ingots -> copper ingots, silver coins -> gold coins.
const LOOT := {
	"bv_coin_chest_tipped": {gold_coin = 60},
	"bv_coin_niche_found": {gold_coin = 25},
	"bv_pigeonholes": {gold_coin = 40},          # (owner: "40 coins, gold and silver": there are no silver coins)
	"bv_strongbox": {gold_coin = 30},            # (no amount from the owner yet: Claude's pick)
	"cf_charcoal_bay": {coal = 5},
	"cf_ingot_stack": {copper_ingot = 3},        # (owner: 3 bronze ingots)
	"ef_coal_scuttle": {coal = 3},
	"ef_cooling_rack": {sword_stone = 1},
	"ef_ingot_wall": {copper_ingot = 3},         # (no amount from the owner yet; the build file suggests 3 iron ingots)
	"hw_ingot_cart": {copper_ingot = 3},         # (owner: 3 bronze ingots)
	"hw_ingot_stack": {copper_ingot = 3},        # (owner: 3 bronze ingots)
	"ro_quiver_rack": {crossbow_stone = 1, bolt_stone = 5},
	"rt_arrow_crate_spill": {bolt_stone = 10},
}
const NAMES := {
	"bv_coin_chest_tipped": "Coin chest", "bv_coin_niche_found": "Coin niche", "bv_pigeonholes": "Coin pigeonholes",
	"bv_strongbox": "Strongbox", "cf_charcoal_bay": "Charcoal bay", "cf_ingot_stack": "Ingot stack",
	"ef_coal_scuttle": "Coal scuttle", "ef_cooling_rack": "Cooling rack", "ef_ingot_wall": "Ingot rack",
	"hw_ingot_cart": "Ingot cart", "hw_ingot_stack": "Ingot stack", "ro_quiver_rack": "Crossbow rack",
	"rt_arrow_crate_spill": "Bolt crate",
}
## The ruins whose plans may hold lootable props (world_state.ruins[k].name -> plan).
const RUIN_PLANS := {"tower": RuinTower.PLAN, "outpost": RuinOutpost.OUTPOST_PLAN, "brewhall": RuinBrewhall.PLAN_PATH,
	"spire": RuinSpire.PLAN_PATH, "kiln": "res://blueprints/ruins/kiln_ruin.json"}

var auth: GameAuthority
var props := {}          ## key -> {model, xform: Transform3D, label, node: StaticBody3D, inst: Node3D, looted: bool}
var _root: Node3D
var _check := 0.0
var _applied := -1       ## how many of world_state.props_looted this computer has shown
var _ruins_placed := {}  ## ruin record key -> true: its lootable props are placed
static var _plans := {}  ## plan path -> plan (ruins)


func _ready() -> void:
	auth = get_parent() as GameAuthority
	_root = Node3D.new()
	_root.name = "Props"
	add_child(_root)


## The model's id: "decor/bv_coin_chest_tipped.glb" -> "bv_coin_chest_tipped".
static func model_id(model: String) -> String:
	return model.get_file().get_basename()


## Is this plan prop a lootable one (role "lootable" and something to give)?
static func is_lootable(p: Dictionary) -> bool:
	return String(p.get("role", "")) == ROLE and LOOT.has(model_id(String(p.get("model", ""))))


static func empty_model(model: String) -> String:
	return model.get_base_dir().path_join(model_id(model) + "_empty.glb")


static func key_of(collider: Object) -> String:
	if collider is Node and (collider as Node).has_meta("loot_prop"):
		return String((collider as Node).get_meta("loot_prop"))
	return ""


func is_looted(key: String) -> bool:
	return auth != null and key in auth.world_state.get("props_looted", [])


## Everyone: put lootable prop `key` in the world (every computer gives it the same key). Already looted: it is built
## empty (or with its lid open).
func place(key: String, model: String, xform: Transform3D, label := "") -> void:
	if props.has(key):
		return
	var path := "res://assets/models/" + model
	if not ResourceLoader.exists(path):
		push_warning("LootProps: missing model %s" % path)
		return
	var body := StaticBody3D.new()
	body.name = "Loot_" + key.replace(":", "_")
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	body.set_meta("loot_prop", key)
	body.add_to_group(RuinKit.GROUP)  # (the pickaxe doesn't dig "through" it)
	_root.add_child(body)
	var inst := (load(path) as PackedScene).instantiate() as Node3D
	inst.transform = xform
	body.add_child(inst)
	var whole := AABB()
	var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var box := DungeonBuild._rel_xform(inst, mi as Node3D) * (mi as MeshInstance3D).get_aabb()
		whole = box if first else whole.merge(box)
		first = false
	DungeonBuild.add_boxes(body, model, xform, whole)
	var id := model_id(model)
	props[key] = {model = model, xform = xform, label = label if label != "" else String(NAMES.get(id, "Loot")), node = body,
		inst = inst, looted = false}
	if is_looted(key):
		_show_looted(key, false)


## What E does on it (for the aim line, which shows only "E to take": owner F134): {kind, name, loot_key}, or {}
## once it's empty.
func use_info(key: String) -> Dictionary:
	var pr: Dictionary = props.get(key, {})
	if pr.is_empty() or pr.looted or is_looted(key):
		return {}
	return {kind = "loot", name = "%s · E to take" % pr.label, loot_key = key}


# ================================================================== request -> host -> everyone

## Our E on lootable prop `key`: ask the host.
func ask_loot(key: String) -> void:
	if auth == null:
		return
	if auth.is_host():
		request_loot(auth.local_peer_id(), key)
	else:
		_rpc_loot.rpc_id(1, key)


@rpc("any_peer", "reliable")
func _rpc_loot(key: String) -> void:
	if auth and auth.is_host():
		request_loot(multiplayer.get_remote_sender_id(), key)


## Host: a player loots `key`. First come, first served: it gives its items once (what doesn't fit in the bag drops
## at their feet), then it is empty for everyone, for good.
func request_loot(peer_id: int, key: String) -> bool:
	var ps := auth.get_player(peer_id) if auth else null
	var pr: Dictionary = props.get(key, {})
	if ps == null or pr.is_empty() or is_looted(key):
		return false
	var at: Vector3 = (pr.xform as Transform3D).origin
	if ps.node.global_position.distance_to(at) > REACH + 1.5:
		return false
	var loot: Dictionary = LOOT.get(model_id(String(pr.model)), {})
	var said := []
	for item in loot:
		var n := int(loot[item])
		var left: int = ps.inventory.add(String(item), n)
		if left > 0:
			auth.spawn_drop(String(item), left, ps.node.global_position + Vector3.UP)
		said.append("%d %s" % [n, Items.display_name(String(item))])
	var list: Array = auth.world_state.get("props_looted", []).duplicate()
	list.append(key)
	auth.world_state["props_looted"] = list
	_ev_looted.rpc(key)
	auth._ev_state.rpc(auth.world_state)
	if peer_id == auth.local_peer_id() or multiplayer.get_peers().has(peer_id):  # (not to a friend who just left)
		auth.tell(peer_id, "You take %s from the %s." % [", ".join(said), String(pr.label).to_lower()])
	return true


## Everyone: `key` was just looted.
@rpc("authority", "call_local", "reliable")
func _ev_looted(key: String) -> void:
	_show_looted(key, true)


## Shows `key` empty: its lid swings open (`live`: with the chest's creak) or the model swaps to its _empty twin.
func _show_looted(key: String, live: bool) -> void:
	var pr: Dictionary = props.get(key, {})
	if pr.is_empty() or pr.looted:
		return
	pr.looted = true
	var body: StaticBody3D = pr.node
	var lid := ChestOpen.lid_of(body)
	if lid:
		if live:
			ChestOpen.open(body)
		else:
			lid.rotation.x = ChestOpen.OPEN_ANGLE
		return
	var empty := "res://assets/models/" + empty_model(String(pr.model))
	if not ResourceLoader.exists(empty):
		push_warning("LootProps: no empty model %s" % empty)
		return
	var inst := (load(empty) as PackedScene).instantiate() as Node3D
	inst.transform = pr.xform
	(pr.inst as Node).queue_free()
	body.remove_child(pr.inst)
	body.add_child(inst)
	pr.inst = inst
	if live:
		Sfx.play("chest_open", (pr.xform as Transform3D).origin + Vector3.UP * 0.5, -16.0, 1.3)


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0 or auth == null:
		return
	_check = CHECK_EVERY
	apply_looted()
	var ruins: Dictionary = auth.world_state.get("ruins", {})
	for k in ruins:
		if not _ruins_placed.has(str(k)):
			place_ruin(str(k), ruins[k])


## Show what the host says is looted (on loading a save, a friend joining, or after a change).
func apply_looted() -> void:
	var list: Array = auth.world_state.get("props_looted", [])
	if list.size() == _applied:
		return
	_applied = list.size()
	for key in list:
		_show_looted(String(key), false)


## Everyone: the lootable props of ruin record `k` ({name, origin, turn}), from its plan (or `plan`, for tests).
func place_ruin(k: String, r: Dictionary, plan := {}) -> void:
	_ruins_placed[k] = true
	if plan.is_empty():
		var path := String(RUIN_PLANS.get(String(r.get("name", "")), ""))
		if path == "":
			return
		if not _plans.has(path):
			_plans[path] = RuinTower.load_plan(path)
		plan = _plans[path]
	var origin: Vector3 = r.get("origin", Vector3.ZERO)
	var turn := int(r.get("turn", 0))
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	var props_list: Array = plan.get("props", [])
	for i in props_list.size():
		var p: Dictionary = props_list[i]
		if not is_lootable(p):
			continue
		var pos: Vector3 = origin + basis * Vector3(float(p.pos[0]), float(p.pos[1]), float(p.pos[2]))
		var b := Basis(Vector3.UP, deg_to_rad(float(p.get("yaw", 0.0))) + turn * PI / 2.0)
		place("r:%s:%d" % [k, i], String(p.model), Transform3D(b.scaled_local(Vector3.ONE * float(p.get("scale", 1.0))), pos),
			String(p.get("label", "")))
	# The lootable catalogue pieces in the ruin's junk list (the arrow crate, the quiver rack: Nov 21).
	var junk := RuinJunk.load_list(String(r.get("name", "")))
	for i in junk.size():
		var j: Dictionary = junk[i]
		if not j.get("loot", false) or not LOOT.has(model_id(String(j.model))):
			continue
		var pos: Vector3 = origin + basis * Vector3(float(j.pos[0]), float(j.pos[1]), float(j.pos[2]))
		place("r:%s:j%d" % [k, i], String(j.model), Transform3D(Basis(Vector3.UP, deg_to_rad(float(j.yaw)) + turn * PI / 2.0), pos))
