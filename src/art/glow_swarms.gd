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


func build(maker: CaveMaker, trunks: Array = []) -> void:
	_trunks = trunks
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


func _make(maker: CaveMaker, room: Dictionary, rng: RandomNumberGenerator, mesh: Mesh) -> Dictionary:
	var n := 650 if room == maker.rooms[0] else rng.randi_range(300, 450)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tint: Color = TINTS[rng.randi_range(0, TINTS.size() - 1)]
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 3.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = n
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	var c: Vector3 = room.center
	var r: Vector3 = room.radii
	var fl := c.y - r.y * 0.55
	var sw := {mmi = mmi, tint = tint, c = c, r = r, fl = fl, tall = r.y * 1.55,
		f = Vector3(rng.randf_range(0.05, 0.09), rng.randf_range(0.07, 0.12), rng.randf_range(0.05, 0.09)),  # loop speeds
		ph = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU), head = Vector3.ZERO, prev = Vector3.ZERO,
		along = PackedFloat32Array(), off = PackedVector2Array(), lag = PackedFloat32Array(), tw = PackedFloat32Array(),
		pos = PackedVector3Array(), ring = PackedFloat32Array(), band = 0.0,
		w = rng.randf_range(0.035, 0.06) * (1.0 if rng.randf() < 0.5 else -1.0), gap = rng.randf_range(2.5, 4.0)}
	# Along the walls (owner, Nov 18: "in front of the ceiling I don't see them, in front of the wall it looks cool"):
	# how far the wall is from the cave's middle in 48 directions, at the height they fly.
	sw.band = fl + minf(2.5, r.y * 1.55 * 0.35) + 1.0
	for k in 48:
		var a := k * TAU / 48.0
		var dir := Vector3(cos(a), 0.0, sin(a))
		var start := Vector3(c.x, sw.band, c.z)
		var hit := GlowPlacer._march(maker, start, dir, maxf(r.x, r.z) * 1.6) if maker.sdf_at(start) > 0.0 else Vector3.INF
		sw.ring.append(Vector2(hit.x - c.x, hit.z - c.z).length() if hit != Vector3.INF else minf(r.x, r.z) * 0.8)
	for i in n:
		var a := rng.randf() * TAU
		var d := sqrt(rng.randf())
		sw.along.append(pow(rng.randf(), 1.6))  # more of them near the front: a round head, a thinner tail
		sw.off.append(Vector2(cos(a), sin(a)) * d)
		sw.lag.append(rng.randf_range(1.6, 4.5))
		sw.tw.append(rng.randf() * TAU)
	sw.head = _head_at(sw, 0.0)
	sw.prev = sw.head
	for i in n:
		sw.pos.append(sw.head + Vector3(sw.off[i].x, sw.off[i].y, 0.0) * 0.6)
	_place(sw)
	return sw


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
	var p := Vector3(c.x + cos(a) * d, y, c.z + sin(a) * d)
	return _round_trunks(p, 1.2)


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
	for sw in _swarms:
		if (sw.head as Vector3).distance_to(at) > ACTIVE:
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
				sw.leaving = false
		else:
			fade = minf(1.0, fade + delta * 0.6)
		sw.fade = fade
		var vel := (head - (sw.prev as Vector3)) / maxf(delta, 0.001)
		sw.prev = head
		sw.head = head
		var speed := vel.length()
		var fwd := vel.normalized() if speed > 0.01 else Vector3.FORWARD
		var side := fwd.cross(Vector3.UP).normalized() if absf(fwd.y) < 0.95 else Vector3.RIGHT
		var up := side.cross(fwd)
		var length := 0.8 + speed * 1.4  # stretches out when it moves faster: a droplet
		var radius := 0.45  # (owner, Nov 18: "a lot tighter together")
		var pos: PackedVector3Array = sw.pos
		var mm: MultiMesh = (sw.mmi as MultiMeshInstance3D).multimesh
		var buf: PackedFloat32Array = sw.get("buf", PackedFloat32Array())
		if buf.size() != pos.size() * 16:
			buf.resize(pos.size() * 16)
		var tr: float = sw.tint.r
		var tg: float = sw.tint.g
		var tb: float = sw.tint.b
		for i in pos.size():
			var s: float = sw.along[i]
			var o: Vector2 = sw.off[i]
			var w: float = sw.tw[i]
			var spread := radius * (1.0 - 0.75 * s)  # wide at the front, thin at the tail
			var target := head - fwd * s * length + (side * o.x + up * o.y) * spread \
				+ Vector3(sin(_time * 1.3 + w), sin(_time * 1.7 + w * 1.3), cos(_time * 1.1 + w)) * 0.12
			pos[i] = pos[i].lerp(target, minf(1.0, delta * float(sw.lag[i])))
			if not _trunks.is_empty():
				pos[i] = _round_trunks(pos[i], 0.3)
			# a firefly's blink: mostly dim, then a short bright flash, each on its own beat (stars just twinkle)
			var beat := fposmod(_time * (0.35 + 0.25 * fposmod(w, 1.0)) + w, 1.0)
			var glow := 0.15 + 0.85 * clampf(1.0 - absf(beat - 0.5) * 6.0, 0.0, 1.0)
			var sc := 0.7 + 0.5 * glow
			var q := pos[i]
			var bo := i * 16  # one firefly: its 3x4 transform, then its colour, all sent in one go (650 in a pack)
			buf[bo] = sc; buf[bo + 1] = 0.0; buf[bo + 2] = 0.0; buf[bo + 3] = q.x
			buf[bo + 4] = 0.0; buf[bo + 5] = sc; buf[bo + 6] = 0.0; buf[bo + 7] = q.y
			buf[bo + 8] = 0.0; buf[bo + 9] = 0.0; buf[bo + 10] = sc; buf[bo + 11] = q.z
			buf[bo + 12] = tr; buf[bo + 13] = tg; buf[bo + 14] = tb; buf[bo + 15] = (0.5 + 0.5 * glow) * fade
		mm.buffer = buf
		sw.buf = buf
		sw.pos = pos


func _place(sw: Dictionary) -> void:
	var mm: MultiMesh = (sw.mmi as MultiMeshInstance3D).multimesh
	for i in mm.instance_count:
		mm.set_instance_transform(i, Transform3D(Basis(), sw.pos[i]))
		mm.set_instance_color(i, sw.tint)
