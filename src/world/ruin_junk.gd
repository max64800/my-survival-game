class_name RuinJunk
extends Node3D
## Ruin junk (owner, Nov 20): small things "just for looks" in and around the ruins, hugging their walls. Decoration only:
## you can't pick it up or break it. Flat junk has no body (you walk over it); crates, kegs and sacks are solid.
## Where it goes: blueprints/ruins/<ruin>_junk.json (made by tools/ruins/ruin_junk.py, in the ruin's own frame).
## Co-op: the host turns that list into world spots ONCE, when the rock around the ruin has loaded (the ground outside
## is measured on the host's rock), and writes it into the ruin's record (world_state.ruins: saved and sent to friends).
## Every computer draws it from there. The junk inside goes as soon as the ruin is being rebuilt (owner, Nov 20), and
## the junk outside too (owner, Nov 21: "any garbage outside the perimeter gets removed"; the rebuild clears the rubble).
## F864 (owner, Nov 25: "after rebuilding, all its junk is gone"): only the broken mess goes (rubble, bones, rags, dropped
## gear, smashed or tipped things); whole things (crates, kegs, sacks, carts, benches, racks) stay, unless the rebuilt
## building would stand where they are (inside a new wall, floor or stair).

const PLANS := {"tower": RuinTower.PLAN, "outpost": RuinOutpost.OUTPOST_PLAN, "brewhall": RuinBrewhall.PLAN_PATH,
	"spire": RuinSpire.PLAN_PATH,
	# F976 (owner, Nov 28): the grand ruins too (built into cave shapes: their ground junk lies on their own cave floor)
	"cliff_galleries": RuinCliffGalleries.PLAN_PATH, "smeltery": RuinSmeltery.PLAN_PATH,
	"pillar_spiral": RuinPillarSpiral.PLAN_PATH, "manor": RuinManor.PLAN_PATH}
## 2 (Nov 21): the catalogue decor joined the lists; a ruin whose junk is older is made again.
const JUNK_V := 2
const CHECK_EVERY := 1.0
const MAX_STEP := 1.0  ## outside junk whose ground is more than this above/below the ruin's base is left out (a ledge)

var auth: GameAuthority
var _check := 0.0
var _drawn := ""         ## what is drawn now (redrawn when it changes)
var _gone := {}          ## ruin box id -> true: its junk went (stays gone, even before the "done" news arrives)
var _root: Node3D
var count := 0           ## how many pieces are drawn now (tests)
var shown := []          ## the models drawn now (tests)
static var _boxes := {}  ## ruin box id + blueprint -> the rebuilt building's piece boxes (world)
static var instance: RuinJunk


func _init(p_auth: GameAuthority) -> void:
	auth = p_auth
	name = "RuinJunk"


func _ready() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


static func junk_file(ruin_name: String) -> String:
	return String(PLANS.get(ruin_name, "")).replace(".json", "_junk.json")


static func load_list(ruin_name: String) -> Array:
	var path := junk_file(ruin_name)
	if path == "" or not FileAccess.file_exists(path):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d.get("junk", []) if d is Dictionary else []


## The junk of a ruin at `origin`, turned `turn` quarter turns, in world spots: [[model, pos, yaw, inside], ...].
## Ground junk stands on the rock as this computer sees it (the host's, once).
static func world_list(world: World, ruin_name: String, origin: Vector3, turn: int) -> Array:
	var out := []
	var basis := Basis(Vector3.UP, turn * PI / 2.0)
	for j in load_list(ruin_name):
		if j.get("loot", false):
			continue  # (a lootable piece: LootProps places it, so it can be searched)
		var p: Vector3 = origin + basis * Vector3(float(j.pos[0]), float(j.pos[1]), float(j.pos[2]))
		if j.get("ground", false):
			var y := floor_at(world, p.x, p.z, p.y)  # (p.y: the ruin's base, or a grand ruin's cave floor)
			if is_nan(y) or absf(y - p.y) > MAX_STEP:
				continue  # rock in the way, a drop or a ledge: no junk there
			p.y = y
		out.append(["res://assets/models/" + String(j.model), p, deg_to_rad(float(j.yaw)) + turn * PI / 2.0, bool(j.get("inside", true))])
	return out


## The top of the rock at (x, z) near height `near` (the voxels are 1 m apart: the crossing is worked out between two of
## them, and between the four columns around the spot), or NAN.
static func floor_at(world: World, x: float, z: float, near: float) -> float:
	var x0 := floorf(x)
	var z0 := floorf(z)
	var hs: Array[float] = []
	for c in [Vector2(x0, z0), Vector2(x0 + 1, z0), Vector2(x0, z0 + 1), Vector2(x0 + 1, z0 + 1)]:
		var h := _column_floor(world, c.x, c.y, near)
		if is_nan(h):
			return NAN
		hs.append(h)
	var fx := x - x0
	var fz := z - z0
	return lerpf(lerpf(hs[0], hs[1], fx), lerpf(hs[2], hs[3], fx), fz)


static func _column_floor(world: World, x: float, z: float, near: float) -> float:
	var y := ceilf(near + MAX_STEP + 1.0)
	var above := world.sdf_at(Vector3(x, y, z))
	if above <= 0.0:
		return NAN  # rock right above: buried
	while y > near - MAX_STEP - 2.0:
		var s := world.sdf_at(Vector3(x, y - 1.0, z))
		if s <= 0.0:
			return y - 1.0 + (0.0 - s) / (above - s)  # (sdf > 0 is air)
		above = s
		y -= 1.0
	return NAN


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = CHECK_EVERY
	var ruins: Dictionary = auth.world_state.get("ruins", {})
	if auth.is_host():
		_make_missing(ruins)
		ruins = auth.world_state.get("ruins", {})  # (with any junk just made)
	var sig := ""
	for k in ruins:
		var r: Dictionary = ruins[k]
		if r.get("done", false) or (auth.builder and auth.builder.sites.has(int(k))):
			_gone[k] = true
		sig += "%s:%d:%s;" % [k, (r.get("junk", []) as Array).size(), _gone.has(k)]
	if sig != _drawn:
		_drawn = sig
		_draw(ruins)


## A ruin record with no junk list yet, or one older than JUNK_V (a world saved before the catalogue decor).
static func needs_junk(r: Dictionary) -> bool:
	return PLANS.has(String(r.get("name", ""))) and not (r.has("junk") and int(r.get("jv", 1)) >= JUNK_V)


## Host: a ruin with no junk yet (just built, or a world saved before Nov 20) gets it once the rock around it has loaded.
func _make_missing(ruins: Dictionary) -> void:
	var changed := false
	for k in ruins:
		var r: Dictionary = ruins[k]
		if not needs_junk(r):
			continue
		var origin: Vector3 = r.origin
		var reach := float(r.get("reach", 9.0)) + 2.0
		var up := 0.0  # (a grand ruin's cave floor stands this high in its box)
		for j in load_list(String(r.name)):
			if j.get("ground", false):
				up = maxf(up, float(j.pos[1]))
		var box := AABB(origin - Vector3(reach, 3.0, reach), Vector3(reach * 2.0, 6.0 + up, reach * 2.0))
		if not auth.world.terrain.is_area_meshed(box):
			continue
		var r2 := r.duplicate()
		r2.junk = world_list(auth.world, String(r.name), origin, int(r.turn))
		r2.jv = JUNK_V
		ruins = ruins.duplicate()
		ruins[k] = r2
		changed = true
		print("RUIN_JUNK %s: %d pieces" % [r.name, (r2.junk as Array).size()])
	if changed:
		auth.world_state["ruins"] = ruins
		auth._ev_state.rpc(auth.world_state)


## Broken mess: the dungeon junk (bones, rags, rubble, dropped gear), the table litter, and anything broken
## (model checks use it; after a rebuild everything goes, whole or broken: F864).
const MESS_WORDS := ["broken", "shattered", "fallen", "burst", "spill", "tipped", "overturned", "rolled", "snapped",
	"pried", "rotten", "rubble", "scrap", "bones", "dropped", "cold"]
static func is_mess(model: String) -> bool:
	var id := model.get_file().get_basename()
	if id.begins_with("junk_") or id.begins_with("tr_"):
		return true
	return MESS_WORDS.any(func(w: String): return w in id)


func _draw(ruins: Dictionary) -> void:
	if _root:
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "Junk"
	add_child(_root)
	var body := StaticBody3D.new()  # one body for the solid junk (crates, kegs, sacks)
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	body.add_to_group(RuinKit.GROUP)
	_root.add_child(body)
	var all := {}  # model -> [Transform3D]
	shown = []
	for k in ruins:
		for j in ruins[k].get("junk", []):
			if _gone.has(k):
				continue  # being rebuilt (or rebuilt): all of it goes, inside and outside (owner, Nov 21; F864, Nov 25)
			shown.append(String(j[0]))
			(all.get_or_add(String(j[0]), []) as Array).append(Transform3D(Basis(Vector3.UP, float(j[2])), j[1] as Vector3))
	var n := 0
	for model in all:
		var scene := load(model) as PackedScene if ResourceLoader.exists(model) else null
		if scene == null:
			push_warning("RuinJunk: missing model %s" % model)
			continue
		var xforms: Array = all[model]
		var inst := scene.instantiate() as Node3D
		var whole := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var rel := DungeonBuild._rel_xform(inst, m)
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = DungeonBuild._own_mesh(m)
			mm.instance_count = xforms.size()
			for i in xforms.size():
				mm.set_instance_transform(i, (xforms[i] as Transform3D) * rel)
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			_root.add_child(mmi)
			var b := rel * m.get_aabb()
			whole = b if first else whole.merge(b)
			first = false
		inst.free()
		n += xforms.size()
		if DungeonBuild._is_flat_junk(String(model).trim_prefix("res://assets/models/")):
			continue
		for t: Transform3D in xforms:
			var cs := CollisionShape3D.new()
			var sh := BoxShape3D.new()
			sh.size = whole.size
			cs.shape = sh
			cs.transform = Transform3D(t.basis, t * whole.get_center())
			body.add_child(cs)
	count = n
	print("RUIN_JUNK drawn: %d pieces" % n)
