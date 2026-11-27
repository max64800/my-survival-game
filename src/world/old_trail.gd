class_name OldTrail
## The old worn dirt path (owner, Nov 25, F870 step 5): faint packed dirt that links the start with every ruin and
## special place, the way old dwarves once walked. No paint, no markers: easy to follow if you look, easy to leave.
##
## How it is worked out (same world number = same path on every computer, no dice at all):
## 1. The cave's own tunnels make a map: every tunnel piece's two ends are stops, the piece is the road between them.
##    Climbing costs extra, so the path keeps to level ground where it can.
## 2. From the start, the cheapest way to every place is found (Dijkstra's method with a little heap). All those ways
##    together make one branching path (a tree), so shared stretches are walked only once.
## 3. Each road is sampled every STEP metres and dropped onto the floor. A sample on built ground (a ruin, a tower,
##    a dungeon's doorway: CaveMaker.reserved), in a stone column or over a drop is left out: the path stops at a
##    ruin's edge and never cuts through it.
## The Cave Maker paints the floor there with packed dirt (Mat.PATH); nothing the world grows may stand on it
## (CaveMaker.on_trail, the placement rule).

const STEP := 1.5  ## metres between samples along the path
const PULL_STOPS := 12  ## F940: a straight stretch may skip this many stops at most
const PULL_LENGTH := 45.0  ## and be at most this long (metres, flat)
const PULL_FLOOR := 2.0  ## the floor under a straight stretch may be this far off its straight line
const SNAP := 3.5  ## tunnel ends this close (with open air between) count as one stop (ledges, ramps, side tunnels)
const CLIMB := 3.0  ## each metre up or down costs as much as this many metres walked
const DROP := 4.5  ## a sample whose floor is further below the tunnel's middle line than this is over a drop
const ROOM_DROP := 12.0  ## (across a cave's own floor the line between two stops can pass over a dip: more is fine)
const RUIN_DROP := 30.0  ## (and ruins are built down into the cave's dips: the way down to one may drop further)
## The kinds of places it leads to. Nests are left out (it shouldn't lead you into the bats), and so are sealed
## pockets (geodes, sealed shrines) that you find by digging.
const TO_TYPES := ["ruin", "camp", "great_hall", "colonnade", "shrine"]


## {points: PackedVector3Array (floor spots), along: PackedVector3Array (flat direction at each spot),
##  ends: Array of Vector3 (the places it reaches)}
static func plan(maker: CaveMaker) -> Dictionary:
	var out := {points = PackedVector3Array(), along = PackedVector3Array(), ends = []}
	if maker.segments.is_empty():
		return out
	# 1. Stops and roads.
	var pos := PackedVector3Array()
	var ids := {}  # Vector3i (0.5 m) -> stop
	var adj: Array = []  # stop -> Array of [other stop, cost]
	var stop_of := func(v: Vector3) -> int:
		var k := Vector3i((v * 2.0).round())
		if ids.has(k):
			return ids[k]
		ids[k] = pos.size()
		pos.append(v)
		adj.append([])
		return pos.size() - 1
	var link := func(a: int, b: int) -> void:
		var d: Vector3 = pos[b] - pos[a]
		var c := Vector2(d.x, d.z).length() + CLIMB * absf(d.y)
		adj[a].append([b, c])
		adj[b].append([a, c])
	for sg: Dictionary in maker.segments:
		var a: int = stop_of.call(sg.a)
		var b: int = stop_of.call(sg.b)
		if a != b:
			link.call(a, b)
	# Ends close together (ledge paths, ramps, side tunnels that start beside another tunnel): one stop.
	var grid := {}
	for i in pos.size():
		var g := Vector2i(floori(pos[i].x / SNAP), floori(pos[i].z / SNAP))
		if not grid.has(g):
			grid[g] = PackedInt32Array()
		grid[g].append(i)
	for i in pos.size():
		var g := Vector2i(floori(pos[i].x / SNAP), floori(pos[i].z / SNAP))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for j: int in grid.get(g + Vector2i(dx, dz), PackedInt32Array()):
					if j > i and pos[i].distance_to(pos[j]) < SNAP and maker.sdf_at((pos[i] + pos[j]) * 0.5) > 0.5:
						link.call(i, j)
	# Inside a cave you can walk across the floor: every tunnel end in a room joins the stop nearest its middle.
	var in_room := {}  # the roads across a cave's floor
	for room: Dictionary in maker.rooms:
		if room.get("sealed", false):
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var mid := _nearest(pos, CaveMaker.mouth(room))
		var gx0 := floori((c.x - r.x) / SNAP)
		var gx1 := floori((c.x + r.x) / SNAP)
		var gz0 := floori((c.z - r.z) / SNAP)
		var gz1 := floori((c.z + r.z) / SNAP)
		for gx in range(gx0, gx1 + 1):
			for gz in range(gz0, gz1 + 1):
				for j: int in grid.get(Vector2i(gx, gz), PackedInt32Array()):
					var q: Vector3 = pos[j]
					if j != mid and Vector2((q.x - c.x) / r.x, (q.z - c.z) / r.z).length() < 0.9 and absf(q.y - c.y) < r.y:
						link.call(mid, j)
						in_room[Vector2i(mini(mid, j), maxi(mid, j))] = true
	# Which stops hang together (the two biomes join through the gates; a stray piece can be on its own).
	var comp := PackedInt32Array()
	comp.resize(pos.size())
	comp.fill(-1)
	var ncomp := 0
	for i in pos.size():
		if comp[i] >= 0:
			continue
		var todo := [i]
		comp[i] = ncomp
		while not todo.is_empty():
			var u: int = todo.pop_back()
			for e: Array in adj[u]:
				if comp[int(e[0])] < 0:
					comp[int(e[0])] = ncomp
					todo.append(e[0])
		ncomp += 1
	# 2. Where each place is: a room's place the stop nearest it; built ruins (and dungeon doors) the stop nearest
	# their middle.
	var goals: Array[Vector3] = []
	for p: Dictionary in maker.pois:
		if not TO_TYPES.has(p.type):
			continue
		var room: int = int(p.get("room", -1))
		if room >= 0 and room < maker.rooms.size() and maker.rooms[room].get("sealed", false):
			continue
		goals.append(p.pos)
	for z: Dictionary in maker.reserved:
		goals.append(z.pos)
	var goal_stop := PackedInt32Array()
	var nets := {}  # piece -> true: the pieces that hold a place
	for goal in goals:
		var s := _nearest(pos, goal)
		goal_stop.append(s)
		if s >= 0:
			nets[comp[s]] = true
	# The cheapest ways from the start (in a piece that doesn't reach the start: from its stop nearest the start).
	var cost := PackedFloat64Array()  # (float64: a float32 copy rounds below the heap's cost and the stop was skipped)
	cost.resize(pos.size())
	cost.fill(INF)
	var back := PackedInt32Array()
	back.resize(pos.size())
	back.fill(-1)
	var heap: Array = []
	var pieces: Array = nets.keys()
	pieces.sort()
	for piece: int in pieces:
		var from := -1
		var fd := INF
		for i in pos.size():
			if comp[i] == piece:
				var d := pos[i].distance_squared_to(maker.spawn_point)
				if d < fd:
					fd = d
					from = i
		cost[from] = 0.0
		heap.append([0.0, from])
	while not heap.is_empty():
		var top: Array = _pop(heap)
		var u: int = top[1]
		if float(top[0]) > cost[u]:
			continue
		for e: Array in adj[u]:
			var v: int = e[0]
			var c: float = cost[u] + float(e[1])
			if c < cost[v]:
				cost[v] = c
				back[v] = u
				_push(heap, [c, v])
	var used := {}  # Vector2i(a, b) roads on the path
	var chains: Array = []  # each way as its stops, from the place back to where it meets the path (or the start)
	for gi in goals.size():
		var t := goal_stop[gi]
		if t < 0 or cost[t] == INF:
			continue
		out.ends.append(goals[gi])
		var chain := PackedInt32Array([t])
		while back[t] >= 0:
			var k := Vector2i(mini(t, back[t]), maxi(t, back[t]))
			if used.has(k):
				break  # the rest of the way back is already on the path
			used[k] = true
			t = back[t]
			chain.append(t)
		if chain.size() > 1:
			chains.append(chain)
	# F940 (owner, Nov 27: "it bends about"): each way is pulled tight like a string. From each stop it runs straight
	# to the furthest later stop it can see through open air with steady floor below, so it no longer zig-zags from
	# tunnel end to tunnel end (or into every cave's middle and out again). It still only bends where the cave does.
	var roads: Array = []  # [stop a, stop b, across a cave's floor]
	for chain: PackedInt32Array in chains:
		var i := 0
		while i < chain.size() - 1:
			var j := mini(chain.size() - 1, i + PULL_STOPS)
			while j > i + 1 and not _straight_ok(maker, pos[chain[i]], pos[chain[j]]):
				j -= 1
			var room := true
			for m in range(i, j):
				room = room and in_room.has(Vector2i(mini(chain[m], chain[m + 1]), maxi(chain[m], chain[m + 1])))
			roads.append([chain[i], chain[j], room])
			i = j
	# 3. Down onto the floor, leaving out built ground, columns and drops.
	for road: Array in roads:
		var a: Vector3 = pos[road[0]]
		var b: Vector3 = pos[road[1]]
		var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
		var n := maxi(1, ceili(flat.length() / STEP))
		var dir := flat.normalized() if flat.length() > 0.1 else Vector3.FORWARD
		for s in n:
			var l := a.lerp(b, float(s) / n)
			if maker.sdf_at(l) <= 0.0:
				continue  # the middle line runs in rock here (a pinched tunnel)
			var fl := _floor(maker, l)
			var fall := l.y - fl.y
			if fall > DROP and not (fall < ROOM_DROP and road[2]) and not (fall < RUIN_DROP and maker.is_reserved(fl, 15.0)):
				continue
			if maker.is_reserved(fl, 1.5) or maker._in_column(fl, 1.5) or maker.in_dungeon_stone(fl):
				continue
			if maker.sdf_at(fl + Vector3.UP * 0.5) <= 0.0 or maker.sdf_at(fl - Vector3.UP * 0.6) > 0.0:
				continue  # (a thin lip or a crack: not solid floor)
			out.points.append(fl)
			out.along.append(dir)
	return out


## True when the road may run straight from a to b (two stops' middle lines): open air all the way (no rock between,
## no stone column), no longer than PULL_LENGTH, and the floor below never more than PULL_FLOOR off the straight line
## between the two ends' floors (no cutting across a pit, over a ledge or up a wall).
static func _straight_ok(maker: CaveMaker, a: Vector3, b: Vector3) -> bool:
	var d := b - a
	if Vector2(d.x, d.z).length() > PULL_LENGTH:
		return false
	var fa := _floor(maker, a).y
	var fb := _floor(maker, b).y
	var n := maxi(2, ceili(d.length()))
	for s in range(1, n):
		var t := float(s) / n
		var l := a.lerp(b, t)
		if maker.sdf_at(l) <= 0.4:
			return false
		var fl := _floor(maker, l)
		if absf(fl.y - lerpf(fa, fb, t)) > PULL_FLOOR or maker._in_column(fl, 1.0):
			return false
	return true


## The floor under l, like CaveMaker.find_floor (the first rock spot, here within 5 cm of the top) but quicker: down in
## 1 m steps, then back up in 0.25 m and 5 cm steps.
static func _floor(maker: CaveMaker, l: Vector3) -> Vector3:
	var y := l.y
	while y > CaveMaker.Y_MIN and maker.sdf_at(Vector3(l.x, y, l.z)) > 0.0:
		y -= 1.0
	while y + 0.25 < l.y and maker.sdf_at(Vector3(l.x, y + 0.25, l.z)) <= 0.0:
		y += 0.25
	while y + 0.05 < l.y and maker.sdf_at(Vector3(l.x, y + 0.05, l.z)) <= 0.0:
		y += 0.05
	return Vector3(l.x, y, l.z)


## The stop nearest p (height counts double, so a tunnel right overhead isn't picked).
static func _nearest(pos: PackedVector3Array, p: Vector3) -> int:
	var best := -1
	var bd := INF
	for i in pos.size():
		var d := pos[i] - p
		var dd := d.x * d.x + d.z * d.z + 4.0 * d.y * d.y
		if dd < bd:
			bd = dd
			best = i
	return best


# A tiny min-heap of [cost, stop] (smallest cost on top).
static func _push(h: Array, item: Array) -> void:
	h.append(item)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if float(h[p][0]) <= float(item[0]):
			break
		h[i] = h[p]
		i = p
	h[i] = item


static func _pop(h: Array) -> Array:
	var top: Array = h[0]
	var last: Array = h.pop_back()
	if h.is_empty():
		return top
	var i := 0
	var n := h.size()
	while true:
		var l := i * 2 + 1
		if l >= n:
			break
		var r := l + 1
		var c := r if r < n and float(h[r][0]) < float(h[l][0]) else l
		if float(h[c][0]) >= float(last[0]):
			break
		h[i] = h[c]
		i = c
	h[i] = last
	return top
