class_name GlowSwarms
extends Node3D
## Glowing swarms (owner, Nov 18: "a pack, circular, 100-150 of them, moving like a pack... the first part is wide and
## then it stretches out like a droplet... like a pack of bees, no sound, moving very elegantly; in the first cave two").
## A swarm's head drifts through its cave in slow smooth loops; every mote follows its own place in the pack a little
## late, so the pack is round at the front and draws out into a droplet's tail when it moves faster. They twinkle softly.
## Only looks; planned from the cave (same caves get them on every computer, though each screen moves its own).

const SHARE := 0.75  ## of the caves get a swarm (owner, Nov 18: "a lot more of them"; the first cave gets three)
const ACTIVE := 80.0  ## swarms further than this from the camera hold still (nobody sees them move)
const TINTS := [Color(0.4, 1.0, 0.85), Color(0.55, 1.0, 0.55), Color(1.0, 0.82, 0.4), Color(0.6, 0.85, 1.0)]

var _swarms: Array[Dictionary] = []
var _time := 0.0


func build(maker: CaveMaker) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.016  # (smaller: they were readable as little balls)
	mesh.height = 0.032
	mesh.radial_segments = 6
	mesh.rings = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9700
	for ri in maker.rooms.size():
		var room: Dictionary = maker.rooms[ri]
		var roll := rng.randf()
		var count := 3 if ri == 0 else (1 if roll < SHARE else 0)
		if room.get("sealed", false) or room.radii.y < 3.0:
			count = 0
		for k in count:
			_swarms.append(_make(maker, room, rng, mesh))


func _make(maker: CaveMaker, room: Dictionary, rng: RandomNumberGenerator, mesh: Mesh) -> Dictionary:
	var n := rng.randi_range(100, 150)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tint: Color = TINTS[rng.randi_range(0, TINTS.size() - 1)]
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 2.2
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
		pos = PackedVector3Array()}
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
	var x := sin(t * f.x + ph.x) * 0.55 + sin(t * f.x * 2.3 + ph.y) * 0.12
	var z := cos(t * f.z + ph.z) * 0.55 + sin(t * f.z * 1.7 + ph.x) * 0.12
	var y := 0.5 + 0.5 * sin(t * f.y + ph.y)
	# high up, away from the floor (owner, Nov 18: "they usually fly a lot further from the ground")
	var low: float = float(sw.fl) + minf(4.0, float(sw.tall) * 0.45)
	return Vector3(c.x + x * r.x, low + y * maxf(0.5, sw.tall * 0.85 - (low - sw.fl)), c.z + z * r.z)


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
		var length := 1.4 + speed * 2.2  # stretches out when it moves faster: a droplet
		var radius := 0.9
		var pos: PackedVector3Array = sw.pos
		var mm: MultiMesh = (sw.mmi as MultiMeshInstance3D).multimesh
		for i in pos.size():
			var s: float = sw.along[i]
			var o: Vector2 = sw.off[i]
			var w: float = sw.tw[i]
			var spread := radius * (1.0 - 0.75 * s)  # wide at the front, thin at the tail
			var target := head - fwd * s * length + (side * o.x + up * o.y) * spread \
				+ Vector3(sin(_time * 1.3 + w), sin(_time * 1.7 + w * 1.3), cos(_time * 1.1 + w)) * 0.12
			pos[i] = pos[i].lerp(target, minf(1.0, delta * float(sw.lag[i])))
			var glow := 0.55 + 0.45 * sin(_time * 2.0 + w * 3.0)
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * (0.7 + 0.5 * glow)), pos[i]))
			mm.set_instance_color(i, Color(sw.tint.r, sw.tint.g, sw.tint.b, (0.5 + 0.5 * glow) * fade))
		sw.pos = pos


func _place(sw: Dictionary) -> void:
	var mm: MultiMesh = (sw.mmi as MultiMeshInstance3D).multimesh
	for i in mm.instance_count:
		mm.set_instance_transform(i, Transform3D(Basis(), sw.pos[i]))
		mm.set_instance_color(i, sw.tint)
