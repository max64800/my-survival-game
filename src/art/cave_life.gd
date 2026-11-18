class_name CaveLife
extends Node3D
## Life on the cave floors and walls, only for looks (owner's cave-life plan, batch 1, F188): fluffy moss (also
## spilling over ledges), pale cave grass, small roots poking out, lichen crusts and small curly ferns.
## In patches (owner): lush round glowing things, drips (damp) and roots, bare rock in between, so the lush spots
## feel special and the game stays fast.
## - Same seed = same patches on every computer (no network needed): placed round the glow spots with the cave's dice.
## - Drawn in batches: one MultiMesh per kind per 20 m square, so squares far away aren't drawn at all.
## - Rock dug or caved in nearby: the things there disappear (nothing floats).
## - Grass and ferns lean away from every dwarf walking through (src/art/plant_bend.gdshader); moss is fuzzy
##   (src/art/moss_shell.gdshader).
## Models: tools/asset_forge/builds/cave_cover.py.

const CELL := 20.0
const MOSS_SHELLS := 12  ## how many layers the moss fuzz is drawn in

## kind -> its model, how far away it is still drawn (m), size range, how it is drawn
const KINDS := {
	"moss": {model = "res://assets/models/cave/moss.glb", view = 45.0, size = [0.65, 1.3], look = "moss", gap = 0.5},
	"moss_drape": {model = "res://assets/models/cave/moss_drape.glb", view = 45.0, size = [0.8, 1.15], look = "moss", gap = 0.6},
	"grass": {model = "res://assets/models/cave/grass.glb", view = 35.0, size = [1.0, 1.7], look = "bend", height = 0.24, gap = 0.28, breaks = true},
	"fern": {model = "res://assets/models/cave/fern.glb", view = 40.0, size = [1.1, 1.8], look = "bend", height = 0.2, gap = 0.45, breaks = true},
	"rootlet": {model = "res://assets/models/cave/rootlet.glb", view = 40.0, size = [0.9, 1.5], look = "bend", height = 0.3, push = 0.35,
		bend_parts = ["bark", "rootlets"], gap = 0.45, breaks = true},
	"rootlet_b": {model = "res://assets/models/cave/rootlet_b.glb", view = 40.0, size = [0.9, 1.5], look = "bend", height = 0.3, push = 0.35,
		bend_parts = ["bark", "rootlets"], gap = 0.45, breaks = true},
	"lichen": {model = "res://assets/models/cave/lichen.glb", view = 50.0, size = [1.0, 2.2], look = "plain", gap = 0.3},
	# Almost everywhere (owner, F188 said twice: "the cave still looks empty"): gravel drifts and tiny pale mushrooms.
	"gravel": {model = "res://assets/models/cave/gravel.glb", view = 40.0, size = [0.8, 1.6], look = "plain", gap = 0.5},
	"gravel_b": {model = "res://assets/models/cave/gravel_b.glb", view = 35.0, size = [0.9, 1.6], look = "plain", gap = 0.4},
	"tinycaps": {model = "res://assets/models/cave/tinycaps.glb", view = 30.0, size = [0.8, 1.5], look = "plain", gap = 0.3},
}
const EVERY_BIG_ROOM := 220  ## tries for the everywhere cover per big room
const EVERY_ROOM := 50
const EVERY_TUNNEL := 5
const EVERY_HELPERS := 3  ## threads that feel for the floors of the everywhere cover (big caves only)
const FIBER_DROP := "fiber"  ## what a broken grass tuft, fern or small root drops (owner, F197)

## What grows round each kind of life, by surface: floor (flat), slope, wall. (rootlet = either small root look)
const MIX := {
	"light": {floor = {moss = 4, grass = 4, fern = 4, rootlet = 1}, slope = {moss = 4, lichen = 2, fern = 1}, wall = {lichen = 6, rootlet = 1}},
	"root": {floor = {moss = 4, grass = 2, rootlet = 5}, slope = {moss = 3, rootlet = 3, lichen = 1}, wall = {lichen = 3, rootlet = 4}},
	"damp": {floor = {moss = 8, grass = 3, fern = 1, rootlet = 1}, slope = {moss = 5, lichen = 2}, wall = {lichen = 6, rootlet = 1}},
}

## Colours the game picks per plant (the models are painted pale where they are tinted: tint_* parts).
const GRASS_TINTS := [Color(1.0, 0.98, 0.86), Color(0.96, 0.94, 0.78), Color(0.72, 0.95, 0.88), Color(0.66, 0.88, 0.9)]
const LICHEN_TINTS := [Color(1.0, 0.56, 0.18), Color(0.95, 0.68, 0.25), Color(0.9, 0.45, 0.16), Color(0.3, 0.78, 0.74), Color(0.4, 0.86, 0.8)]
const FERN_TINTS := [Color(1.0, 1.0, 1.0), Color(0.86, 0.96, 0.9), Color(0.72, 0.95, 0.95)]

var walkers: Node3D  ## the node holding every dwarf (main's Players): grass and ferns lean away from them
var _cells := {}  ## Vector3i -> {kind -> {mmi: MultiMeshInstance3D, where: PackedVector3Array, xforms: Array}}
var _bend_mats: Array[ShaderMaterial] = []
var _task := -1  ## the background placing job (-1 = none)
var _planned: Array[Dictionary] = []
var _pending := []  ## rock changes that came in while placing: [center, radius]
var _index := {}  ## plant id -> [cell, kind, i] (ids are the plan's order: the same on every computer)
var _pending_breaks: Array[int] = []  ## plants broken (save, host) before the placing was done
static var _meshes := {}  ## kind -> Mesh, built once (moss with its fuzz layers)
static var _mats := {}  ## kind/surface -> Material


## background = place everything on a helper thread while the cave loads (~2 s of searching the rock); the plants
## appear when it's done (main waits for it before you can play).
func build(maker: CaveMaker, spots: Array[Dictionary], world: World = null, background := false) -> void:
	if world:
		world.changed.connect(_on_rock_changed)
	if not background:
		_make_all(plan(maker, spots))
		return
	_task = WorkerThreadPool.add_task(func() -> void: _planned = plan(maker, spots), false, "cave life")


func is_built() -> bool:
	return _task < 0


func _make_all(picks: Array[Dictionary]) -> void:
	var by_cell := {}
	for id in picks.size():
		var p: Dictionary = picks[id]
		p.id = id
		var c := _cell(p.xform.origin)
		if not by_cell.has(c):
			by_cell[c] = {}
		if not by_cell[c].has(p.kind):
			by_cell[c][p.kind] = []
		by_cell[c][p.kind].append(p)
	for c in by_cell:
		_cells[c] = {}
		for kind in by_cell[c]:
			_cells[c][kind] = _make_set(kind, by_cell[c][kind])
			var ids: PackedInt32Array = _cells[c][kind].ids
			for i in ids.size():
				_index[ids[i]] = [c, kind, i]
	for id in _pending_breaks:
		remove_plant(id)
	_pending_breaks.clear()


## A grass tuft, fern or small root right where a swing landed (owner F197: people will hit them by accident, they
## break and drop fiber): its id, or -1.
func breakable_at(point: Vector3, reach: float = 0.45) -> int:
	var best := -1
	var bd := INF
	var c0 := _cell(point)
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var cell: Dictionary = _cells.get(c0 + Vector3i(x, y, z), {})
				for kind in cell:
					if not KINDS[kind].get("breaks", false):
						continue
					var where: PackedVector3Array = cell[kind].where
					for i in where.size():
						var d := where[i].distance_to(point)
						var r: float = reach * maxf(1.0, (cell[kind].xforms[i] as Transform3D).basis.y.length())
						if d < r and d < bd:
							bd = d
							best = cell[kind].ids[i]
	return best


## Where plant `id` grows (INF if it's gone or unknown).
func position_of(id: int) -> Vector3:
	var at: Array = _index.get(id, [])
	if at.is_empty():
		return Vector3.INF
	return (_cells[at[0]][at[1]].where as PackedVector3Array)[at[2]]


## A plant was broken (the host said so): it's gone on this computer.
func remove_plant(id: int) -> void:
	if _task >= 0:
		_pending_breaks.append(id)
		return
	var at: Array = _index.get(id, [])
	if at.is_empty():
		return
	var set: Dictionary = _cells[at[0]][at[1]]
	var where: PackedVector3Array = set.where
	(set.mmi as MultiMeshInstance3D).multimesh.set_instance_transform(at[2], Transform3D(Basis().scaled(Vector3.ZERO), where[at[2]]))
	where[at[2]] = Vector3.INF
	set.where = where


## Which kind plant `id` is ("" if unknown).
func kind_of(id: int) -> String:
	var at: Array = _index.get(id, [])
	return at[1] if not at.is_empty() else ""


## A broken plant grows back where it was (owner, Nov 17: small roots regrow like the big ones).
func restore_plant(id: int) -> void:
	var at: Array = _index.get(id, [])
	if at.is_empty():
		return
	var set: Dictionary = _cells[at[0]][at[1]]
	var xf: Transform3D = set.xforms[at[2]]
	var where: PackedVector3Array = set.where
	(set.mmi as MultiMeshInstance3D).multimesh.set_instance_transform(at[2], xf)
	where[at[2]] = xf.origin
	set.where = where


## Where plant `id` grew, even if it's broken now (INF if unknown).
func home_of(id: int) -> Vector3:
	var at: Array = _index.get(id, [])
	if at.is_empty():
		return Vector3.INF
	return (_cells[at[0]][at[1]].xforms[at[2]] as Transform3D).origin


func _exit_tree() -> void:
	if _task >= 0:  # never leave the helper thread working on a game that's gone
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


## The plant of this kind nearest to p (for the look test): its transform (origin INF when there is none).
func nearest(kind: String, p: Vector3) -> Transform3D:
	var best := Transform3D(Basis(), Vector3.INF)
	var bd := INF
	for c in _cells:
		if not _cells[c].has(kind):
			continue
		var where: PackedVector3Array = _cells[c][kind].where
		for i in where.size():
			var d := where[i].distance_squared_to(p)
			if d < bd:
				bd = d
				best = _cells[c][kind].xforms[i]
	return best


func count() -> int:
	var n := 0
	for c in _cells:
		for kind in _cells[c]:
			n += (_cells[c][kind].where as PackedVector3Array).size()
	return n


## Where everything grows: an Array of {kind, xform, color, custom}. The same seed and spots give the same list.
static func plan(maker: CaveMaker, spots: Array[Dictionary]) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 5151
	var out: Array[Dictionary] = []
	var taken := {}  ## Vector3i (1 m squares) -> Array of [pos, gap]
	var rock := Rock.new(maker)
	for s in spots:  # nothing grows right on top of a harvestable thing
		_take(taken, s.pos, 0.35 * float(s.get("scale", 1.0)) + 0.25)
	for s: Dictionary in spots:  # (in id order: the same on every computer)
		var src := _source(s)
		if src.is_empty():
			continue
		var center: Vector3 = s.pos
		var start: Vector3 = s.pos + s.normal * 0.6 + Vector3.UP * 0.25
		if s.kind == GlowPlacer.DRIP:  # the damp patch is on the floor under the drip
			var below := rock.march(s.pos + Vector3.DOWN * 0.7, Vector3.DOWN, 25.0)
			if below == Vector3.INF:
				continue
			center = below
			start = below + Vector3.UP * 0.8
		if rock.at(start) <= 0.1:
			continue
		var clear := _clearance(s)
		for i in src.tries:
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
			if i % 3 != 2:
				dir.y = -absf(dir.y) - 0.35  # most tries aim at the ground
			dir = dir.normalized()
			var roll := rng.randf()  # dice rolled every try, so one try never shifts the next one's dice
			var spin := rng.randf() * TAU
			var size_roll := rng.randf()
			var tint_roll := rng.randi()
			var hit := rock.march(start, dir, src.reach + 1.0)
			if hit == Vector3.INF:
				continue
			var dist := hit.distance_to(center)
			if dist > src.reach or dist < clear:
				continue
			var n := rock.normal(hit)
			var surf := "floor" if n.y >= 0.72 else ("slope" if n.y >= 0.4 else ("wall" if n.y > -0.45 else ""))
			if surf == "":
				continue
			var life: float = 1.0 - dist / float(src.reach)
			var kind := _pick(MIX[src.type][surf], roll)
			if kind == "fern" and (src.type != "light" or dist > 2.4):
				kind = "moss" if surf != "wall" else "lichen"
			if kind == "rootlet" and tint_roll % 2 == 1:
				kind = "rootlet_b"
			var at := hit
			var hang := Vector3.ZERO
			if kind == "moss" and surf != "wall" and tint_roll % 3 == 0:  # (a ledge's rounded edge often reads as a slope)
				var edge := _ledge(rock, at)
				if not edge.is_empty():
					kind = "moss_drape"
					hang = edge[0]
					at = edge[1]
			var k: Dictionary = KINDS[kind]
			var size: float = lerpf(k.size[0], k.size[1], size_roll) * (0.75 + 0.35 * life)
			if kind in ["fern", "rootlet", "rootlet_b"]:  # (not grass: giant blades looked like spikes, owner Nov 17)
				# sometimes bigger, never smaller (owner F218); ferns at most 1.6x: 3x ferns looked like spikes too
				size *= minf(GlowPlacer.size_boost(at), 1.6 if kind == "fern" else 9.0)
			if not _free(taken, at, k.gap * size):
				continue
			_take(taken, at, k.gap * size)
			var up := n if kind != "moss_drape" else Vector3.UP
			var basis := _upright(up, spin)
			if kind == "moss_drape":  # the curtain hangs down the drop (Blender's +Y, the drop side, is the model's -Z)
				basis = Basis.looking_at(hang, Vector3.UP)
			var sink: float = {"moss": 0.012, "moss_drape": 0.015, "lichen": 0.003, "grass": 0.006, "fern": 0.004}.get(kind, 0.0) * size
			var shape := Basis.from_scale(Vector3(size, size * (0.45 if kind == "lichen" else 1.0), size))  # lichen: wide but a thin crust
			out.append({kind = kind, xform = Transform3D(basis * shape, at - up * sink),
				color = _tint(kind, tint_roll, CaveMaker.biome_at(at), life), custom = Color(_fuzz(kind, src.type, life), life, 0, 0)})
	_plan_everywhere(maker, rock, taken, out)
	if not maker.reserved.is_empty() or not maker._bridges.is_empty():  # nothing on built ground or bridge tops
		var kept: Array[Dictionary] = []
		for it in out:
			if not maker.is_reserved((it.xform as Transform3D).origin, 0.3) and not maker.on_bridge((it.xform as Transform3D).origin):
				kept.append(it)
		out = kept
	return out


## Almost everywhere (owner, F188 said twice: "the cave still looks empty"): gravel drifts and carpets of tiny pale
## mushrooms on the floors of every room and tunnel, in little clusters, thicker in big rooms. After the patches, with
## their own dice, so the patch plants keep their ids.
static func _plan_everywhere(maker: CaveMaker, rock: Rock, taken: Dictionary, out: Array[Dictionary]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 6161
	var starts := []
	for room in maker.rooms:
		for i in (EVERY_BIG_ROOM if room.big else EVERY_ROOM):
			starts.append([room.center, Vector3(rng.randf_range(-1, 1), -rng.randf_range(0.35, 1.0), rng.randf_range(-1, 1)).normalized(), 60.0])
	for sg: Dictionary in maker.segments:
		for i in EVERY_TUNNEL:
			starts.append([(sg.a as Vector3).lerp(sg.b, rng.randf()), Vector3(rng.randf_range(-0.3, 0.3), -1, rng.randf_range(-0.3, 0.3)).normalized(), 14.0])
	var dice := []  # all dice first, in the same order as always (feeling for the rock never rolls any)
	for st in starts:
		var offs := []
		var roll := rng.randf()
		var many := rng.randi_range(1, 4)
		for j in 4:
			offs.append([Vector3(rng.randf_range(-1.1, 1.1), 0.0, rng.randf_range(-1.1, 1.1)), rng.randf() * TAU, rng.randf(), rng.randi()])
		dice.append([roll, many, offs])
	# The slow part, feeling for the floor, doesn't depend on what was placed before: helpers do it side by side
	# (F211 speed: 3x more tunnels in layout 2), each with its own rock cache. Then the room checks run in the old
	# order, so the result is exactly the same as doing it all in one go.
	var found := []
	found.resize(starts.size())
	var helpers := EVERY_HELPERS if starts.size() > 2000 else 1
	var threads: Array[Thread] = []
	for h in helpers:
		var lo := starts.size() * h / helpers
		var hi := starts.size() * (h + 1) / helpers
		if h == helpers - 1:
			_feel_floors(maker, rock, starts, dice, found, lo, hi)  # this thread does the last share itself
		else:
			var th := Thread.new()
			th.start(_feel_floors.bind(maker, Rock.new(maker), starts, dice, found, lo, hi))
			threads.append(th)
	for th in threads:
		th.wait_to_finish()
	for i in starts.size():
		var kind := "tinycaps" if dice[i][0] < 0.4 else ("gravel" if dice[i][0] < 0.75 else "gravel_b")
		var k: Dictionary = KINDS[kind]
		for c: Array in found[i]:
			var at: Vector3 = c[0]
			var n: Vector3 = c[1]
			var offs: Array = c[2]
			var size: float = lerpf(k.size[0], k.size[1], offs[2]) * GlowPlacer.size_boost(at)  # (owner F218)
			if not _free(taken, at, k.gap * size):
				continue
			_take(taken, at, k.gap * size)
			var sink: float = {"gravel": 0.008, "gravel_b": 0.004, "tinycaps": 0.004}[kind] * size
			out.append({kind = kind, xform = Transform3D(_upright(n, offs[1]) * Basis.from_scale(Vector3.ONE * size), at - n * sink),
				color = _tint(kind, offs[3], CaveMaker.biome_at(at), 0.0), custom = Color(1, 0, 0, 0)})


## For starts lo..hi-1: the floor spots of each cluster ([at, normal, its dice]), before the "is there room" check.
static func _feel_floors(maker: CaveMaker, rock: Rock, starts: Array, dice: Array, found: Array, lo: int, hi: int) -> void:
	for i in range(lo, hi):
		var st: Array = starts[i]
		var many: int = dice[i][1]
		var offs: Array = dice[i][2]
		var cl := []
		found[i] = cl
		var hit := rock.march(st[0], st[1], st[2])
		if hit == Vector3.INF or rock.normal(hit).y < 0.72:
			continue
		for j in many:
			var at := hit
			if j > 0:  # the rest of the cluster: dropped onto the floor round the first
				at = rock.march(hit + offs[j][0] + Vector3.UP * 0.5, Vector3.DOWN, 1.4)
				if at == Vector3.INF:
					continue
			var n := rock.normal(at)
			if n.y < 0.72:
				continue
			cl.append([at, n, offs[j]])


## How long the moss fuzz is: longer where it's damp (owner: "thicker where it's damp"), short on a hanging curtain
## (seen side-on, long fuzz shows its layers as stripes).
static func _fuzz(kind: String, type: String, life: float) -> float:
	if kind == "moss_drape":
		return 0.55
	return 1.0 + (0.6 if type == "damp" else 0.0) * life


## What kind of life a glow spot brings: type, how far it reaches (m), how many tries round it ({} = none).
static func _source(s: Dictionary) -> Dictionary:
	if s.get("extra", false):
		return {}  # (the extra wood roots: no new patches, so every plant keeps its id)
	var kind: String = s.kind
	if kind == GlowPlacer.DRIP:
		return {type = "damp", reach = 4.0, tries = 18}
	if kind == GlowPlacer.ROOT or kind == GlowPlacer.ROOT_DANGLE:
		return {type = "root", reach = 3.0, tries = 12}
	if kind == GlowPlacer.GIANT:
		return {type = "light", reach = 4.0, tries = 12}
	if GlowPlacer.KINDS.get(kind, {}).get("glow", false):
		return {type = "light", reach = 3.2, tries = 10}
	return {}  # plain mushrooms and fiber: no patch (owner: lush near light, water and roots, bare rock in between)


## How close to the spot itself nothing grows (its own model is there).
static func _clearance(s: Dictionary) -> float:
	match s.kind:
		GlowPlacer.ROOT, GlowPlacer.ROOT_DANGLE: return 1.0
		GlowPlacer.GIANT: return 1.4
		GlowPlacer.DRIP: return 0.3
	return 0.3 * float(s.get("scale", 1.0)) + 0.25


static func _pick(weights: Dictionary, roll: float) -> String:
	var total := 0.0
	for k in weights:
		total += weights[k]
	var r := roll * total
	for k in weights:
		r -= weights[k]
		if r <= 0.0:
			return k
	return weights.keys()[0]


static func _tint(kind: String, roll: int, biome: String, life: float) -> Color:
	match kind:
		"grass":  # whitish-yellow in the Mossy Hollows, more blue-green in the Fungal Jungle
			return GRASS_TINTS[(roll >> 3) % 2 + (2 if biome == "fungal" or (roll >> 5) % 5 == 0 else 0)]
		"lichen":  # orange, or teal (more teal in the jungle)
			var teal := (roll >> 3) % 4 == 0 or (biome == "fungal" and (roll >> 3) % 4 != 3)
			return LICHEN_TINTS[3 + (roll >> 6) % 2] if teal else LICHEN_TINTS[(roll >> 6) % 3]
		"fern":
			return FERN_TINTS[(roll >> 3) % FERN_TINTS.size()]
		"gravel", "gravel_b":  # the local rock: grey-brown stone, purple-grey sporestone in the jungle
			var v := 0.85 + 0.15 * float((roll >> 3) % 5) / 4.0
			return Color(0.47, 0.43, 0.38) * v if biome != "fungal" else Color(0.44, 0.37, 0.48) * v  # (paler stood out like eggs)
		"tinycaps":  # white, cream or pale brown
			return [Color(1.0, 1.0, 0.97), Color(1.0, 0.94, 0.8), Color(0.86, 0.74, 0.6), Color(0.95, 0.9, 1.0)][(roll >> 3) % 4]
		"moss", "moss_drape":  # greener and darker where it's most alive, a little yellower at the edges
			var v := 0.88 + 0.12 * float((roll >> 3) % 5) / 4.0
			return Color(v * (1.05 - 0.1 * life), v, v * (0.9 + 0.1 * life))
	return Color.WHITE


## An up-facing basis on the normal n, turned by spin round it (the models grow along +Y).
static func _upright(n: Vector3, spin: float) -> Basis:
	var side := n.cross(Vector3.FORWARD if absf(n.y) > 0.9 else Vector3.UP).normalized()
	return Basis(side, n, side.cross(n)).orthonormalized().rotated(n, spin)


## The drawn rock: Voxel Tools draws the cave from its numbers at whole metres, blended in between, so it can sit
## a few cm off the exact shape. Every search here uses the drawn rock (thin lichen must not float), and remembers
## each metre's numbers (asking the cave is slow: ~11 microseconds each).
class Rock:
	var maker: CaveMaker
	var _cells := {}  ## Vector3i -> PackedFloat32Array (its 8 corners)
	var _corners := {}

	func _init(m: CaveMaker) -> void:
		maker = m

	func _corner(c: Vector3i) -> float:
		var v = _corners.get(c)
		if v == null:
			v = maker.sdf_at(Vector3(c))
			_corners[c] = v
		return v

	## Positive = open air, negative = inside the rock.
	func at(p: Vector3) -> float:
		var g := Vector3i(p.floor())
		var v: PackedFloat32Array = _cells.get(g, PackedFloat32Array())
		if v.is_empty():
			v.resize(8)
			for k in 8:
				v[k] = _corner(g + Vector3i(k & 1, (k >> 1) & 1, (k >> 2) & 1))
			_cells[g] = v
		var f := p - Vector3(g)
		return lerpf(lerpf(lerpf(v[0], v[1], f.x), lerpf(v[2], v[3], f.x), f.y), lerpf(lerpf(v[4], v[5], f.x), lerpf(v[6], v[7], f.x), f.y), f.z)

	## Points away from the rock, into the air.
	func normal(p: Vector3) -> Vector3:
		const E := 0.3
		var g := Vector3(at(p + Vector3(E, 0, 0)) - at(p - Vector3(E, 0, 0)), at(p + Vector3(0, E, 0)) - at(p - Vector3(0, E, 0)),
			at(p + Vector3(0, 0, E)) - at(p - Vector3(0, 0, E)))
		return g.normalized() if g.length() > 0.0001 else Vector3.UP

	## From start along dir: the point where it meets the drawn rock, or INF.
	func march(start: Vector3, dir: Vector3, reach: float) -> Vector3:
		var t := 0.0
		var d := at(start)
		if d <= 0.0:
			return Vector3.INF
		while t < reach:
			var nt := minf(t + maxf(d * 0.5, 0.06), reach)
			var nd := at(start + dir * nt)
			if nd <= 0.0:
				var a := t
				var b := nt
				for i in 7:  # narrow it down to ~1 cm
					var m := (a + b) * 0.5
					if at(start + dir * m) > 0.0:
						a = m
					else:
						b = m
				return start + dir * ((a + b) * 0.5)
			t = nt
			d = nd
		return Vector3.INF


## The edge of a ledge right next to p (the ground drops away a short step sideways): [which way it drops, the
## point on the edge], or [] when there's no ledge.
static func _ledge(rock: Rock, p: Vector3) -> Array:
	for k in 8:
		var d := Vector3(cos(k * TAU / 8.0), 0.0, sin(k * TAU / 8.0))
		if rock.at(p + d * 0.45 + Vector3.DOWN * 0.35) > 0.05 and rock.at(p + d * 0.45 + Vector3.DOWN * 0.65) > 0.05 \
				and rock.at(p - d * 0.2 + Vector3.DOWN * 0.25) < 0.0:
			for i in 9:  # walk toward the drop until there's air just under the ledge's top
				var t := i * 0.05
				if rock.at(p + d * t + Vector3.DOWN * 0.12) > 0.02:
					var edge := p + d * maxf(t - 0.03, 0.0)
					for depth in [0.12, 0.24, 0.36]:  # the curtain needs the rock face right behind it, not leaning away
						var q: Vector3 = edge + Vector3.DOWN * depth
						if rock.at(q - d * 0.05) > 0.0 or rock.at(q + d * 0.12) < 0.0:
							return []
					return [d, edge]
	return []


static func _key(p: Vector3) -> Vector3i:
	return Vector3i(p.floor())


static func _take(taken: Dictionary, p: Vector3, gap: float) -> void:
	var k := _key(p)
	if not taken.has(k):
		taken[k] = []
	taken[k].append([p, gap])


static func _free(taken: Dictionary, p: Vector3, gap: float) -> bool:
	var k := _key(p)
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				for e in taken.get(k + Vector3i(x, y, z), []):
					if (e[0] as Vector3).distance_to(p) < maxf(gap, e[1]) * 0.8:
						return false
	return true


static func _cell(p: Vector3) -> Vector3i:
	return Vector3i((p / CELL).floor())


func _make_set(kind: String, picks: Array) -> Dictionary:
	var k: Dictionary = KINDS[kind]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh_of(kind)
	mm.instance_count = picks.size()
	var where := PackedVector3Array()
	var xforms := []
	var ids := PackedInt32Array()
	for i in picks.size():
		mm.set_instance_transform(i, picks[i].xform)
		mm.set_instance_color(i, picks[i].color)
		mm.set_instance_custom_data(i, picks[i].custom)
		where.append(picks[i].xform.origin)
		xforms.append(picks[i].xform)
		ids.append(picks[i].get("id", -1))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = k.view
	mmi.visibility_range_end_margin = 6.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if k.look == "bend":
		for i in mm.mesh.get_surface_count():
			var m := mm.mesh.surface_get_material(i)
			if m is ShaderMaterial and not _bend_mats.has(m):
				_bend_mats.append(m)
	add_child(mmi)
	return {mmi = mmi, where = where, xforms = xforms, ids = ids}


## The model as one mesh, each part with its game material: moss gets its fuzz layers and the fuzzy shader, the
## tinted parts of grass and ferns the bending shader, lichen takes its colour from each plant.
static func mesh_of(kind: String) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var k: Dictionary = KINDS[kind]
	var src := ArrayMesh.new()
	var ps := load(k.model) as PackedScene
	if ps:
		var inst := ps.instantiate()
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			var xf := Transform3D()
			var node: Node = mi
			while node != inst:
				xf = (node as Node3D).transform * xf
				node = node.get_parent()
			for i in mi.mesh.get_surface_count():
				var st := SurfaceTool.new()
				st.append_from(mi.mesh, i, xf)
				st.commit(src)
				src.surface_set_material(src.get_surface_count() - 1, mi.mesh.surface_get_material(i))
		inst.free()
	var out := src
	if k.look == "moss" and src.get_surface_count() > 0:
		out = _shell_mesh(src, MOSS_SHELLS)
	for i in out.get_surface_count():
		out.surface_set_material(i, _material(kind, src.surface_get_material(mini(i, src.get_surface_count() - 1)) as StandardMaterial3D))
	_meshes[kind] = out
	return out


## The moss cushion copied MOSS_SHELLS times, each copy's number (0..1) in the vertex colour's alpha; the shader
## pushes each copy out along the surface.
static func _shell_mesh(src: ArrayMesh, shells: int) -> ArrayMesh:
	var a := src.surface_get_arrays(0)
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var ov := PackedVector3Array()
	var on := PackedVector3Array()
	var ou := PackedVector2Array()
	var oc := PackedColorArray()
	var oi := PackedInt32Array()
	for s in shells:
		var h := float(s) / float(shells - 1)
		var base := ov.size()
		ov.append_array(verts)
		on.append_array(norms)
		ou.append_array(uvs)
		var c := PackedColorArray()
		c.resize(verts.size())
		c.fill(Color(1, 1, 1, h))
		oc.append_array(c)
		if idx.is_empty():
			for i in verts.size():
				oi.append(base + i)
		else:
			for i in idx:
				oi.append(base + i)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = ov
	arr[Mesh.ARRAY_NORMAL] = on
	arr[Mesh.ARRAY_TEX_UV] = ou
	arr[Mesh.ARRAY_COLOR] = oc
	arr[Mesh.ARRAY_INDEX] = oi
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


static func _bend_part(k: Dictionary, name: String) -> bool:
	for part in k.get("bend_parts", []):
		if name.begins_with(part + "_"):
			return true
	return false


static func _material(kind: String, m: StandardMaterial3D) -> Material:
	var k: Dictionary = KINDS[kind]
	var key := "%s/%s" % [kind, m.resource_name if m else ""]
	if _mats.has(key):
		return _mats[key]
	var out: Material = m
	if m == null:
		out = null
	elif k.look == "moss":
		var sm := ShaderMaterial.new()
		sm.shader = preload("res://src/art/moss_shell.gdshader")
		sm.set_shader_parameter("albedo_tex", m.albedo_texture)
		out = sm
	elif k.look == "bend" and (m.resource_name.begins_with("tint_") or _bend_part(k, m.resource_name)):
		var sm := ShaderMaterial.new()
		sm.shader = preload("res://src/art/plant_bend.gdshader")
		sm.set_shader_parameter("albedo_tex", m.albedo_texture)
		sm.set_shader_parameter("plant_height", k.height)
		sm.set_shader_parameter("push_scale", k.get("push", 1.0))
		if m.normal_texture:
			sm.set_shader_parameter("normal_tex", m.normal_texture)
			sm.set_shader_parameter("use_normal", 1.0)
		if not m.resource_name.begins_with("tint_"):
			sm.set_shader_parameter("tinted", 0.0)
		out = sm
	elif m.resource_name.begins_with("tint_"):  # lichen, gravel, tiny mushrooms: the painting times each plant's colour
		var t := m.duplicate() as StandardMaterial3D
		t.vertex_color_use_as_albedo = true
		out = t
	_mats[key] = out
	return out


func _process(_delta: float) -> void:
	if _task >= 0:
		if not WorkerThreadPool.is_task_completed(_task):
			return
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_make_all(_planned)
		_planned = []
		for c in _pending:
			_on_rock_changed(c[0], c[1])
		_pending.clear()
	if _bend_mats.is_empty() or walkers == null:
		return
	var feet: Array[Vector4] = [Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO]
	var i := 0
	for d in walkers.get_children():
		if d is Node3D and i < 4:
			var p := (d as Node3D).global_position
			feet[i] = Vector4(p.x, p.y, p.z, 1.0)
			i += 1
	for m in _bend_mats:
		m.set_shader_parameter("pushers", feet)


## Rock changed near here: anything growing there disappears (it fell with the rock).
func _on_rock_changed(center: Vector3, radius: float) -> void:
	if _task >= 0:  # still placing: do it when the plants are there
		_pending.append([center, radius])
		return
	var r := radius + 0.6
	var lo := _cell(center - Vector3.ONE * r)
	var hi := _cell(center + Vector3.ONE * r)
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				var cell: Dictionary = _cells.get(Vector3i(x, y, z), {})
				for kind in cell:
					var where: PackedVector3Array = cell[kind].where
					var mm: MultiMesh = (cell[kind].mmi as MultiMeshInstance3D).multimesh
					for i in where.size():
						if where[i].distance_squared_to(center) < r * r:
							mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), where[i]))
							where[i] = Vector3.INF
					cell[kind].where = where
