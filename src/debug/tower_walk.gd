extends Node
## Robot (Nov 23, F783/F781/F803): walks the REAL dwarf (its own body, its own camera) over every flight of stairs
## and through every door of a rebuilt ruin, up and back down. Prints what it bumps into when it gets stuck, how
## much it bobs up and down on the way (jitter), and whether it ever drops through a stair. Started by
## ruin_test_start.gd when the run has `walk` (e.g. -- ruintest=twin_gate walk claude=twin_gate_stairs shots=<folder>).

const STUCK_TIME := 1.5   ## seconds without getting closer = stuck
const REACH := 0.35       ## close enough to a waypoint

var _main: Node
var _shots := ""
var report: Array[String] = []
var fails := 0
var _home := Vector3.ZERO  ## where the dwarf stood at the start (in front of the gate, by the chest)


func run(main: Node, shots: String) -> void:
	_main = main
	_shots = shots
	_home = _main.dwarf.global_position
	var b: Builder = _main.authority.builder
	for uid in b.structure.pieces:                       # every door open, like a player would
		var p: Dictionary = b.structure.pieces[uid]
		if p.piece in Pieces.DOORS and int(p.get("open", 0)) == 0:
			b._ev_door(uid, 1)
	b._door_shut_at.clear()  # (F869) the walk needs every door to stay open, also ones the save had open
	await get_tree().create_timer(1.0).timeout
	var flights := []
	for uid in b.structure.pieces:
		var p: Dictionary = b.structure.pieces[uid]
		if p.piece == "stairs" or p.piece == "stairs_corner":
			flights.append(p)
	flights.sort_custom(func(a, c): return a.pos.x < c.pos.x or (a.pos.x == c.pos.x and a.pos.y < c.pos.y))
	var walks := not OS.get_cmdline_user_args().has("reachonly")
	for p in flights if walks else []:
		var path := _flight_path(p)
		await _walk("%s at %s UP" % [p.piece, p.pos], path, p.pos.y + 2.0)
		path.reverse()
		await _walk("%s at %s DOWN" % [p.piece, p.pos], path, p.pos.y)
	for uid in b.structure.pieces if walks else []:
		var p: Dictionary = b.structure.pieces[uid]
		if p.piece in Pieces.DOORS:
			var bs := Basis(Vector3.UP, Pieces.yaw_of(p.rot))
			var a: Vector3 = p.pos + bs * Vector3(0, 0.3, 1.3)
			var c: Vector3 = p.pos + bs * Vector3(0, 0.3, -1.3)
			await _walk("%s at %s" % [p.piece, p.pos], [a, p.pos + Vector3.UP * 0.3, c], p.pos.y)
	await _reach(flights)
	print("TOWER_WALK done: %d problems" % fails)
	for line in report:
		print("TOWER_WALK ", line)


## The way over a flight, in the world (each point at the height of the floor or step under it): from the floor in front of its foot, over the steps, onto the floor above.
func _flight_path(p: Dictionary) -> Array:
	var bs := Basis(Vector3.UP, Pieces.yaw_of(p.rot))
	var local := []
	if p.piece == "stairs":
		local = [Vector3(0, -0.25, 2.2), Vector3(0, 0, 1.9), Vector3(0, 1, 0.8), Vector3(0, 2, -1.25), Vector3(0, 2, -1.9)]
	else:
		local = [Vector3(0.4, -0.25, 2.5), Vector3(0.4, 0, 2.2), Vector3(0.4, 0.6, 0.6), Vector3(0.1, 1.2, -0.1),
			Vector3(-0.5, 1.6, -0.5), Vector3(-1.2, 2, -0.6), Vector3(-1.9, 2, -0.6)]
	var out := []
	for q: Vector3 in local:
		out.append(p.pos + bs * q + Vector3.UP * 0.3)
	return out


func _walk(name: String, path: Array, floor_y: float) -> void:
	var d: Dwarf = _main.dwarf
	d.global_position = path[0]
	d.velocity = Vector3.ZERO
	var trace := []
	for i in 10:
		await get_tree().physics_frame
		trace.append(snappedf(d.global_position.y, 0.01))
	if OS.get_cmdline_user_args().has("trace"):
		print("TOWER_WALK trace %s placed %s: %s" % [name, path[0], trace])
	var low := 99.0
	var bumps := 0      # times the dwarf went down while walking up (or up while walking down): the jitter
	var last_y := d.global_position.y
	var last_dy := 0.0
	var start_y := d.global_position.y
	var ok := true
	var stuck_on := ""
	for k in range(1, path.size()):
		var goal: Vector3 = path[k]
		var best := INF
		var since := 0.0
		while true:
			await get_tree().physics_frame
			var to := goal - d.global_position
			to.y = 0.0
			if to.length() < REACH:
				break
			if to.length() < best - 0.02:
				best = to.length()
				since = 0.0
			else:
				since += get_physics_process_delta_time()
			if since > STUCK_TIME:
				ok = false
				stuck_on = _blockers(d)
				break
			var local := Basis(Vector3.UP, d._yaw).inverse() * to.normalized()
			d.bot_move = Vector2(local.x, local.z)
			var y := d.global_position.y
			var dy := y - last_y
			if absf(dy) > 0.004 and last_dy != 0.0 and signf(dy) != signf(last_dy):
				bumps += 1
			if absf(dy) > 0.004:
				last_dy = dy
			last_y = y
			low = minf(low, y)
		if not ok:
			break
	d.bot_move = Vector2.ZERO
	var end_y := d.global_position.y
	var fell := low < minf(start_y, floor_y) - 0.6
	var line := "%s: %s, %d bumps, from y %.2f to %.2f (lowest %.2f)%s" % [name, "OK" if ok else "STUCK at %s on [%s]" % [d.global_position, stuck_on],
		bumps, start_y, end_y, low, "  FELL THROUGH" if fell else ""]
	if not ok or fell:
		fails += 1
		if _shots != "":
			await RenderingServer.frame_post_draw
			_main.take_screenshot(_shots.path_join("walk_%02d.png" % fails))
			line += "  (picture walk_%02d.png)" % fails
	report.append(line)
	print("TOWER_WALK ", line)


## What the dwarf's body is pushing against right now: the piece names (or "rock").
func _blockers(d: Dwarf) -> String:
	var names := {}
	for i in d.get_slide_collision_count():
		var c := d.get_slide_collision(i)
		var n: Node = c.get_collider() as Node
		var label := "rock/other"
		while n:
			if n is PieceNode:
				label = "%s %s" % [n.piece, n.global_position.snapped(Vector3.ONE * 0.05)]
				break
			n = n.get_parent()
		if absf(c.get_normal().y) < 0.7:
			names[label] = true
	return ", ".join(names.keys())


## Like pouring water from where the dwarf stands: every spot its real body can walk, step up (0.5 m) or drop down
## to, in 25 cm squares lined up with the building grid. Then: is the top of every flight, and both sides of every door, among the wet spots?
## (Walking each flight on its own passed while the owner still couldn't get up: this finds a missing way BETWEEN.)
func _reach(flights: Array) -> void:
	var o: Vector3 = (_main.authority.world_state.get("ruins", {}).values()[0] as Dictionary).origin
	var t := Time.get_ticks_msec()
	var spots := ReachMap.flood(_main.dwarf, _home, AABB(o - Vector3(30, 0, 30), Vector3(60, 0, 60)))
	print("TOWER_WALK reach: %d spots in %.1f s, highest %.2f m above the gate's foot" % [spots.size(),
		(Time.get_ticks_msec() - t) / 1000.0, spots.reduce(func(a, q): return maxf(a, q.y), -99.0) - o.y])
	for p in flights:
		var ends := ReachMap.flight_ends(p.piece, p.pos, p.rot)
		var a := ReachMap.distance(spots, ends[0])
		var c := ReachMap.distance(spots, ends[1])
		_note(a < 0.6 and c < 0.6, "reach %s at %s (%.1f m up): foot %s, top %s" % [p.piece, p.pos, p.pos.y - o.y,
			"ok" if a < 0.6 else "NOT REACHED (%.1f m off)" % a, "ok" if c < 0.6 else "NOT REACHED (%.1f m off)" % c])
	var b: Builder = _main.authority.builder
	for uid in b.structure.pieces:
		var p: Dictionary = b.structure.pieces[uid]
		if not p.piece in Pieces.DOORS or p.piece == "gate_leaf":
			continue
		var bs := Basis(Vector3.UP, Pieces.yaw_of(p.rot))
		var a := ReachMap.distance(spots, p.pos + bs * Vector3(0, 0, 1.0))
		var c := ReachMap.distance(spots, p.pos + bs * Vector3(0, 0, -1.0))
		_note(a < 0.6 and c < 0.6, "reach door at %s (%.1f m up): front %s, back %s" % [p.pos, p.pos.y - o.y,
			"ok" if a < 0.6 else "NOT REACHED", "ok" if c < 0.6 else "NOT REACHED"])


func _note(ok: bool, line: String) -> void:
	if not ok:
		fails += 1
	report.append(line)
	print("TOWER_WALK ", line)
