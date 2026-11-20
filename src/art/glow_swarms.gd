class_name GlowSwarms
extends Node3D
## Glowing swarms (owner, Nov 18: "a pack, circular, 100-150 of them, moving like a pack... the first part is wide and
## then it stretches out like a droplet... like a pack of bees, no sound, moving very elegantly; in the first cave two").
## A swarm's head drifts through its cave in slow smooth loops; every mote follows its own place in the pack a little
## late, so the pack is round at the front and draws out into a droplet's tail when it moves faster. They twinkle softly.
## Only looks; planned from the cave (same caves get them on every computer, though each screen moves its own).

const SHARE := 1.0  ## every cave gets fireflies (owner, Nov 18 again: "a lot more of them"); big caves 2-3, the first cave 5
const ACTIVE := 80.0  ## swarms further than this from the camera hold still (nobody sees them move)
## Warm firefly colours (owner, Nov 18: they blended with the pale green/white glow-worm ceiling): gold, amber, lime-gold.
const TINTS := [Color(1.0, 0.8, 0.3), Color(1.0, 0.62, 0.22), Color(0.85, 1.0, 0.3), Color(1.0, 0.9, 0.45)]

var _swarms: Array[Dictionary] = []
var _time := 0.0
var _trunks := []  ## Root Trees to fly round: [{p, r, top, bottom}]
var _maker: CaveMaker
var _todo := 0  ## swarms finished so far (owner, Nov 19: loading froze ~2 s on them, so they're finished after loading)


func build(maker: CaveMaker, trunks: Array = []) -> void:
	_trunks = trunks
	_maker = maker
	var mesh := SphereMesh.new()
	mesh.radius = 0.009  # (smaller again, owner Nov 18: "a lot smaller")
	mesh.height = 0.018
	mesh.radial_segments = 6
	mesh.rings = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9700
	for ri in maker.rooms.size():
		var room: Dictionary = maker.rooms[ri]
		var roll := rng.randf()
		# one big tight swarm per cave (owner, Nov 18: "just put 1 [in the first cave], but a lot more in the pack")
		var count := 1 if ri == 0 or roll < (SHARE if room.big else 0.5) else 0
		if room.get("sealed", false) or room.radii.y < 3.0:
			count = 0
		for k in count:
			_swarms.append(_make(maker, room, rng, mesh))
	if not _swarms.is_empty():
		_finish(_swarms[0])  # the first cave's swarm is ready at once; the rest follow a little each frame
	_todo = 0


func _make(maker: CaveMaker, room: Dictionary, rng: RandomNumberGenerator, mesh: Mesh) -> Dictionary:
	var n := 650 if room == maker.rooms[0] else rng.randi_range(300, 450)
	var tint: Color = TINTS[rng.randi_range(0, TINTS.size() - 1)]
	var mat := ShaderMaterial.new()  # the graphics card places every firefly (owner, Nov 18: the speed-up run)
	mat.shader = preload("res://src/art/firefly.gdshader")
	mat.set_shader_parameter("tint", Color(tint.r * 1.6, tint.g * 1.6, tint.b * 1.6))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = n
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	var c: Vector3 = room.center
	var r: Vector3 = room.radii
	mmi.custom_aabb = AABB(c - r * 1.7, r * 3.4)  # (every firefly is moved on the card, so the box is the whole cave)
	var fl := c.y - r.y * 0.55
	var sw := {mmi = mmi, mat = mat, tint = tint, c = c, r = r, fl = fl, tall = r.y * 1.55,
		f = Vector3(rng.randf_range(0.05, 0.09), rng.randf_range(0.07, 0.12), rng.randf_range(0.05, 0.09)),  # loop speeds
		ph = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU), head = Vector3.ZERO, prev = Vector3.ZERO,
		along = PackedFloat32Array(), off = PackedVector2Array(), lag = PackedFloat32Array(), tw = PackedFloat32Array(),
		pos = PackedVector3Array(), ring = PackedFloat32Array(), band = 0.0,
		w = rng.randf_range(0.035, 0.06) * (1.0 if rng.randf() < 0.5 else -1.0), gap = rng.randf_range(2.5, 4.0)}
	# Along the walls (owner, Nov 18: "in front of the ceiling I don't see them, in front of the wall it looks cool"):
	# how far the wall is from the cave's middle in 48 directions, at the height they fly.
	sw.band = fl + minf(2.5, r.y * 1.55 * 0.35) + 1.0
	for i in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf())
		sw.along.append(pow(rng.randf(), 1.6))  # more of them near the front: a round head, a thinner tail
		sw.off.append(Vector2(cos(a), sin(a)) * d)
		sw.lag.append(rng.randf_range(1.6, 4.5))
		sw.tw.append(rng.randf() * TAU)
	mmi.visible = false  # shown once _finish has found its walls
	return sw


## The slow part of a swarm (48 looks for its cave's walls), done one swarm per frame instead of all while loading.
func _finish(sw: Dictionary) -> void:
	while _ring_step(sw):
		pass
	_finish_end(sw)


const RING := 48  ## feelers sent out from a swarm's middle to find its cave's walls
const FINISH_BUDGET := 3.0  ## ms a frame for finishing swarms after loading
const FINISH_NEAR := 110.0  ## m: swarms further than this wait until you come nearer (they hold still out there anyway)


## One feeler; false when all of this swarm's feelers are out.
func _ring_step(sw: Dictionary) -> bool:
	var k: int = (sw.ring as PackedFloat32Array).size()
	if k >= RING:
		return false
	var c: Vector3 = sw.c
	var r: Vector3 = sw.r
	var a := k * TAU / float(RING)
	var dir := Vector3(cos(a), 0.0, sin(a))
	var start := Vector3(c.x, sw.band, c.z)
	var hit := GlowPlacer._march(_maker, start, dir, maxf(r.x, r.z) * 1.6) if _maker.sdf_at(start) > 0.0 else Vector3.INF
	sw.ring.append(Vector2(hit.x - c.x, hit.z - c.z).length() if hit != Vector3.INF else minf(r.x, r.z) * 0.8)
	return true


## F417 (Nov 20): one whole swarm a frame took 40-110 ms (48 feelers through the cave rock), so the first seconds of play
## ran at ~10 FPS. Now a few feelers a frame (at most FINISH_BUDGET ms), the nearest unfinished swarm first.
func _finish_some(at: Vector3) -> void:
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < FINISH_BUDGET * 1000.0:
		if _working == null or _working.get("done", false):
			_working = null
			var best := FINISH_NEAR
			for sw in _swarms:
				if not sw.get("done", false):
					var d := (sw.c as Vector3).distance_to(at)
					if d < best:
						best = d
						_working = sw
			if _working == null:
				return
		if not _ring_step(_working):
			_finish_end(_working)


var _working = null  ## the swarm being finished now (Dictionary or null)


func _finish_end(sw: Dictionary) -> void:
	var c: Vector3 = sw.c
	sw.head = _head_at(sw, 0.0)
	sw.prev = sw.head
	for i in (sw.off as PackedVector2Array).size():
		sw.pos.append(sw.head + Vector3(sw.off[i].x, sw.off[i].y, 0.0) * 0.6)
	_place(sw)
	sw.done = true
	_todo += 1
	(sw.mmi as MultiMeshInstance3D).visible = true


## Where a swarm's head is at time t: smooth slow loops inside its cave, between 1.5 m above the floor and 2/3 up.
func _head_at(sw: Dictionary, t: float) -> Vector3:
	var f: Vector3 = sw.f
	var ph: Vector3 = sw.ph
	var c: Vector3 = sw.c
	var r: Vector3 = sw.r
	# round the cave a few metres in front of its walls, drifting nearer and further, rising and dipping a little
	var a: float = ph.x + t * float(sw.w) + sin(t * f.x * 1.7 + ph.y) * 0.25
	var ring: PackedFloat32Array = sw.ring
	var u := fposmod(a / TAU * ring.size(), float(ring.size()))
	var i0 := int(u) % ring.size()
	var wall: float = lerpf(ring[i0], ring[(i0 + 1) % ring.size()], u - floorf(u))
	var d := maxf(1.5, wall - float(sw.gap) - sin(t * f.z + ph.z) * 1.0)
	var y: float = float(sw.band) + sin(t * f.y + ph.y) * minf(1.5, float(sw.tall) * 0.15)
	return Vector3(c.x + cos(a) * d, y, c.z + sin(a) * d)  # (trees: pushed away smoothly in _process)


## Pushed out of any Root Tree (owner, Nov 18: they flew through the trees): `pad` = how far to stay off the bark.
func _round_trunks(p: Vector3, pad: float) -> Vector3:
	for tr in _trunks:
		if p.y > float(tr.top) or p.y < float(tr.bottom):
			continue
		var d := Vector2(p.x - tr.p.x, p.z - tr.p.z)
		var need: float = float(tr.r) + pad
		if d.length() < need:
			var dir := d.normalized() if d.length() > 0.01 else Vector2.RIGHT
			p.x = tr.p.x + dir.x * need
			p.z = tr.p.z + dir.y * need
	return p


func _process(delta: float) -> void:
	_time += delta
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var at := cam.global_position
	if _todo < _swarms.size():
		_finish_some(at)
	for sw in _swarms:
		if not sw.get("done", false) or (sw.head as Vector3).distance_to(at) > ACTIVE:
			continue
		# Shy (owner, Nov 18): when you come within 5 m they fade away, and gather again 10-15 m from you.
		var fade: float = sw.get("fade", 1.0)
		var head := _head_at(sw, _time + float(sw.get("skip", 0.0)))
		if head.distance_to(at) < 5.0 and not sw.get("leaving", false):
			sw.leaving = true
		if sw.get("leaving", false):
			fade = maxf(0.0, fade - delta * 1.2)
			if fade <= 0.0:
				for k in 40:  # further along its loop, until it's 10-15 m from you
					sw.skip = float(sw.get("skip", 0.0)) + 3.0
					head = _head_at(sw, _time + sw.skip)
					if head.distance_to(at) > 10.0 and head.distance_to(at) < 25.0:
						break
				var pos0: PackedVector3Array = sw.pos
				for i in pos0.size():
					pos0[i] = head + Vector3(sw.off[i].x, 0.0, sw.off[i].y) * 0.8
				sw.pos = pos0
				sw.prev = head
				sw.sm = head  # (it's faded out: jumping to its new place is fine)
				sw.trail = PackedVector3Array([head])
				sw.leaving = false
		else:
			fade = minf(1.0, fade + delta * 0.6)
		sw.fade = fade
		# Smooth flying (owner, Nov 18: "it jitters back and forth, and it teleports"): the head glides after its path
		# point instead of being put on it, Root Trees push it away gently instead of throwing it to the trunk's edge,
		# and the stretch follows its speed slowly (frame-to-frame speed shakes with every uneven frame).
		head = _above_floor(sw, head, delta)
		var sm: Vector3 = sw.get("sm", head)
		sm = sm.lerp(head, 1.0 - exp(-delta * 2.5))
		for tr in _trunks:
			if sm.y > float(tr.top) or sm.y < float(tr.bottom):
				continue
			var dd := Vector2(sm.x - tr.p.x, sm.z - tr.p.z)
			var need: float = float(tr.r) + 1.2
			if dd.length() < need:
				var away := dd.normalized() if dd.length() > 0.05 else Vector2(1, 0)
				var push := (need - dd.length()) * minf(1.0, delta * 3.0)
				sm.x += away.x * push
				sm.z += away.y * push
		sm = _keep_out(sw, sm, delta)
		sw.sm = sm
		head = sm
		var vel := (head - (sw.prev as Vector3)) / maxf(delta, 0.001)
		sw.prev = head
		sw.head = head
		var spd: float = sw.get("spd", vel.length())
		spd = lerpf(spd, minf(vel.length(), 4.0), 1.0 - exp(-delta * 1.5))
		sw.spd = spd
		var speed := spd
		var length := 0.8 + speed * 1.4  # stretches out when it moves faster: a droplet
		var radius := 0.45  # (owner, Nov 18: "a lot tighter together")
		# The pack follows the path its head really flew (owner, Nov 18: "when the swarm turns, it turns the entirety of
		# it, not in a wide arc"): the head leaves a trail and each firefly keeps its place ALONG that trail, so a turn
		# sweeps through the pack like a snake's body instead of the whole pack swinging round at once.
		var trail: PackedVector3Array = sw.get("trail", PackedVector3Array())
		if trail.is_empty() or trail[0].distance_to(head) > 3.0:
			trail = PackedVector3Array([head])
		elif trail.size() >= 2 and trail[1].distance_to(head) < 0.06:
			trail[0] = head  # the front point always IS the head (it used to jump forward in 6 cm steps)
		else:
			trail.insert(0, head)
		var total := 0.0
		var cut := trail.size()
		for k in range(1, trail.size()):
			total += trail[k].distance_to(trail[k - 1])
			if total > length + 0.5:
				cut = k + 1
				break
		if cut < trail.size():
			trail.resize(cut)
		sw.trail = trail
		# 17 points along the trail (0 = the head, 16 = the tail end), each with its own forward direction
		var back := -(vel.normalized() if speed > 0.01 else Vector3.FORWARD)
		var pts := PackedVector3Array()
		var fw := PackedVector3Array()
		var k2 := 1
		var walked := 0.0
		for b in 17:
			var want := length * b / 16.0
			while k2 < trail.size() and walked + trail[k2].distance_to(trail[k2 - 1]) < want:
				walked += trail[k2].distance_to(trail[k2 - 1])
				k2 += 1
			if k2 >= trail.size():
				var last := trail[trail.size() - 1]
				var db := (last - trail[trail.size() - 2]).normalized() if trail.size() > 1 else back
				if db.length() < 0.1:
					db = back
				pts.append(last + db * (want - walked))
				fw.append(-db)
			else:
				var seg := trail[k2] - trail[k2 - 1]
				var f := (want - walked) / maxf(seg.length(), 0.0001)
				pts.append(trail[k2 - 1] + seg * f)
				fw.append(-seg.normalized())
		var fwd: Vector3 = fw[0]
		var fly_mat: ShaderMaterial = sw.mat
		fly_mat.set_shader_parameter("pts", pts)
		fly_mat.set_shader_parameter("fws", fw)
		fly_mat.set_shader_parameter("fade", fade)
		fly_mat.set_shader_parameter("radius", radius)


const FLOOR_GAP := 1.6  ## the pack's middle stays at least this high over the real floor under it (owner F407)
const FLOOR_LOOK := 0.15  ## seconds between looks at the floor under a swarm


## Never into the ground (owner F407, Nov 19: "bees sometimes fly into the ground"): the swarm's flying height is worked
## out from the cave's middle, but cave floors rise and fall, so a raised floor or a slope could come up through it. A few
## times a second, look at the floor under (and just ahead of) the head; the head is lifted to FLOOR_GAP over it, and
## the lift eases in and out so the pack glides up over a rise instead of hopping.
func _above_floor(sw: Dictionary, head: Vector3, delta: float) -> Vector3:
	if _maker == null:
		return head
	var look: float = float(sw.get("floor_look", 0.0)) - delta
	if look <= 0.0:
		look = FLOOR_LOOK
		var top := -INF
		var step := ((head - (sw.prev as Vector3)) / maxf(delta, 0.001)) if sw.has("prev") else Vector3.ZERO
		var ahead: Vector3 = head + step.limit_length(4.0)  # (about a second ahead)
		for p: Vector3 in [head, ahead]:
			top = maxf(top, _floor_under(p))
		sw.floor_y = top
	sw.floor_look = look
	var want := 0.0
	if float(sw.get("floor_y", -INF)) > -INF:
		want = maxf(0.0, float(sw.floor_y) + FLOOR_GAP - head.y)
	var lift: float = sw.get("lift", 0.0)
	lift = lerpf(lift, want, 1.0 - exp(-delta * 3.0))
	if lift < want - 1.0:
		lift = want - 1.0  # (catch up fast when far below: never more than 1 m too low)
	sw.lift = lift
	return head + Vector3.UP * lift


## The gliding head itself (it follows its target a little late, and jumps when it flees from you): rises over the
## floor under it, quickly, and never sinks below 0.6 m over it; inside a wall (no floor found above) it drifts back
## toward the cave's middle. (F407: the target alone being lifted still left it inside rock 1 moment in 8.)
func _keep_out(sw: Dictionary, sm: Vector3, delta: float) -> Vector3:
	if _maker == null:
		return sm
	var look: float = float(sw.get("sm_look", 0.0)) - delta
	if look <= 0.0:
		look = FLOOR_LOOK
		sw.sm_floor = _floor_under(sm)
		sw.sm_rock = _maker.sdf_at(sm) < 0.3
	sw.sm_look = look
	var fy: float = sw.get("sm_floor", -INF)
	if fy > -INF:
		var want := fy + FLOOR_GAP
		if sm.y < want:
			sm.y = move_toward(sm.y, want, maxf(3.0 * delta, (want - sm.y) * minf(1.0, delta * 4.0)))
		sm.y = maxf(sm.y, fy + 0.6)
	elif sw.get("sm_rock", false):
		var c: Vector3 = sw.c
		var to_mid := Vector3(c.x - sm.x, 0.0, c.z - sm.z)
		sm += to_mid.normalized() * minf(to_mid.length(), 4.0 * delta)
	return sm


## The ground's height under p (-INF = none found). In the air: straight down to the rock. Inside the rock (a rise
## came up through the path): up to where the rock ends, at most 5 m (the march would stop at once in rock, so
## "down from a point in rock" would have said the floor is right there).
func _floor_under(p: Vector3) -> float:
	if _maker.sdf_at(p) >= 0.05:
		var fl := GlowPlacer._march(_maker, p, Vector3.DOWN, 14.0)
		return fl.y if fl != Vector3.INF else -INF
	for k in range(1, 21):
		var q := p + Vector3.UP * 0.25 * k
		if _maker.sdf_at(q) >= 0.05:
			return q.y
	return -INF


func _place(sw: Dictionary) -> void:
	var mm: MultiMesh = (sw.mmi as MultiMeshInstance3D).multimesh
	for i in mm.instance_count:
		mm.set_instance_transform(i, Transform3D())
		mm.set_instance_custom_data(i, Color(sw.along[i], sw.off[i].x, sw.off[i].y, sw.tw[i]))
