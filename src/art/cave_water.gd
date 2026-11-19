class_name CaveWater
extends Node3D
## Water in the caves (owner, Nov 18, F190: "water: puddles, small streams, a low mist in the deepest spots").
## - Puddles: one under every water drip (rings where the drops land), and a few in the low spots of cavern floors.
## - Mist: a thin, slowly drifting mist hugging the floor in some of the deepest caverns.
## - Little waterfalls (owner, Nov 19): water seeping out of a crack 2.5-7 m up a cave wall, running down the rock face to
##   a small pool on the floor (src/art/waterfall.gdshader). 1-2 in each big cave, sometimes one in a smaller room.
## (Streams along the floor need the cave itself to carve beds for them: a later step.) Only looks; planned from the cave.

const PUDDLES_PER_CAVERN := 2
const MIST_SHARE := 0.35  ## of the low caverns


func build(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var shader: Shader = load("res://src/art/water.gdshader")
	var falls := plan_falls(maker)
	var puddles := plan_puddles(maker, spots)
	var fall_shader: Shader = load("res://src/art/waterfall.gdshader")
	for f in falls:
		_make_fall(f, fall_shader)
	if GroundSnap.instance and GroundSnap.instance.world:
		GroundSnap.instance.world.changed.connect(_on_rock_changed)
	for p in puddles:
		var mi := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE * p.r * 2.0
		mi.mesh = plane
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("drip", 1.0 if p.drip else 0.0)
		mat.set_shader_parameter("radius", p.r)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 45.0
		add_child(mi)
		mi.global_position = p.pos
	for m in plan_mist(maker):
		var fog := FogVolume.new()
		fog.size = m.size
		fog.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
		var fm := FogMaterial.new()
		fm.density = 0.25
		fm.albedo = Color(0.75, 0.8, 0.85)
		fm.height_falloff = 1.2  # thick at the floor, thinning upward
		fm.edge_fade = 0.6
		var noise := FastNoiseLite.new()
		noise.frequency = 0.08
		var tex := NoiseTexture3D.new()
		tex.width = 48
		tex.height = 16
		tex.depth = 48
		tex.seamless = true
		tex.noise = noise
		fm.density_texture = tex
		fog.material = fm
		add_child(fog)
		fog.global_position = m.pos


## Little waterfalls: [{pts: PackedVector3Array (the crack down to the floor, a hand's width off the rock), side
## (Vector3, across the water), pool (floor point)}]. The placement rule: not over paths, places, bridges, Root Trees or
## ground kept clear for built things (test: test_waterfalls_keep_clear).
static func plan_falls(maker: CaveMaker) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9950
	var trees := RootPillars.plan(maker)
	for ri in maker.rooms.size():
		var room: Dictionary = maker.rooms[ri]
		# (owner, Nov 19: "I don't see any waterfalls": his world had none near the start) more of them, and the first
		# cave searched much harder, from spots all round it, not just its middle
		var want := (rng.randi_range(2, 3) if room.big else (1 if rng.randf() < 0.4 else 0))
		var tries := 14
		if ri == 0:
			want = 3
			tries = 60
		if room.get("sealed", false) or maker.sdf_at(room.center) <= 0.0:
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		var fl := c.y - r.y * 0.55
		for attempt in want * tries:
			if want <= 0:
				break
			var a := rng.randf_range(0.0, TAU)
			var off := Vector2(rng.randf_range(-0.5, 0.5) * r.x, rng.randf_range(-0.5, 0.5) * r.z)
			var start := Vector3(c.x + off.x, fl + rng.randf_range(2.5, 7.0), c.z + off.y)
			if maker.sdf_at(start) <= 0.5:
				continue
			var dir := Vector3(cos(a), 0.0, sin(a))
			var hit := GlowPlacer._march(maker, start, dir, maxf(r.x, r.z) * 1.6)
			if hit == Vector3.INF:
				continue
			var n := GlowPlacer.normal_at(maker, hit)
			if absf(n.y) > 0.55:
				continue  # a wall (it may lean a little), not a floor or ceiling
			n = Vector3(n.x, 0.0, n.z).normalized()
			var top := hit + n * 0.12
			if maker.sdf_at(top) <= 0.03:
				top = hit + n * 0.3  # (a rough wall: the crack's water starts a little further out)
				if maker.sdf_at(top) <= 0.03:
					continue
			var pts := PackedVector3Array([top])
			var p: Vector3 = pts[0]
			var ok := true
			for step in 60:  # down the rock face, a hand's width off it, following its bumps
				var q := p + Vector3.DOWN * 0.25
				if maker.sdf_at(q) <= 0.06:
					break  # reached the floor (or a ledge)
				var wall := GlowPlacer._march(maker, q + n * 0.6, -n, 1.5)
				if wall != Vector3.INF:
					q = wall + n * 0.12
				for push in 8:  # the rock bulges out below: the water runs over the bulge (round 3)
					if maker.sdf_at(q) > 0.05:
						break
					q += n * 0.12
				if maker.sdf_at(q) <= 0.02:
					ok = false
					break
				pts.append(q)
				p = q
			if not ok or pts.size() < 7:
				continue  # at least 1.5 m of falling water
			var pool := GlowPlacer._march(maker, p + n * 0.25, Vector3.DOWN, 2.0)
			if pool == Vector3.INF or GlowPlacer.normal_at(maker, pool).y < 0.75:
				continue
			if not _fall_clear(maker, pts, pool, trees):
				continue
			var near := false
			for other in out:  # (round 3: not two side by side)
				var o: Vector3 = (other.pts as PackedVector3Array)[0]
				if Vector2(o.x - pts[0].x, o.z - pts[0].z).length() < 8.0:
					near = true
			if near:
				continue
			out.append({pts = pts, side = Vector3.UP.cross(n).normalized(), pool = pool})
			want -= 1
	return out


static func _fall_clear(maker: CaveMaker, pts: PackedVector3Array, pool: Vector3, trees: Array) -> bool:
	for q in [pts[0], pts[pts.size() / 2], pts[pts.size() - 1], pool]:
		if maker.is_reserved(q, 1.5) or maker.on_bridge(q, 1.5):
			return false
		for t in trees:
			if Vector2(q.x - t.top.x, q.z - t.top.z).length() < float(t.width) * 0.6 + 1.0:
				return false
	for poi in maker.pois:
		if (poi.pos as Vector3).distance_to(pool) < 3.0:
			return false
	for sg: Dictionary in maker.segments:
		if sg.get("ramp", false) or sg.get("ledge", false):
			if Geometry3D.get_closest_point_to_segment(pool, sg.a, sg.b).distance_to(pool) < float(sg.r) + 1.5:
				return false
	return true


var _falls: Array[Dictionary] = []  ## {pts (planned), side, mi, mat, pool (MeshInstance3D), splash}


## A waterfall: its ribbon of water, the pool and the splash where it lands. Once the real rock under it is built it's
## made to reach the real floor (owner, Nov 19: "it doesn't touch the floor"), and again whenever rock is dug below it.
func _make_fall(f: Dictionary, shader: Shader) -> void:
	var mi := MeshInstance3D.new()
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 90.0  # (seen from across a big cave)
	add_child(mi)
	var pool := _make_pool()
	var fall := {pts = _smoothed(f.pts), side = f.side, mi = mi, mat = mat, pool = pool, splash = _make_splash(f.pool)}
	_falls.append(fall)
	_add_trickle(fall.splash)
	_shape_fall(fall, f.pool)
	var bottom: Vector3 = (f.pts as PackedVector3Array)[(f.pts as PackedVector3Array).size() - 1]
	GroundSnap.when_built(AABB(bottom - Vector3(2, 6, 2), Vector3(4, 8, 4)), _fit_fall.bind(fall))


const TRICKLE := "res://assets/sfx/waterfall_trickle.ogg"  ## a real CC0 recording of running water (CREDITS.md)


## The water's sound (owner, Nov 19): a quiet loop at the splash, heard from a few metres away. It sits on the splash,
## so it moves with the fall's end. Each fall starts at its own place in the loop and a little higher or lower, so
## two near each other don't sound like one.
func _add_trickle(at: Node3D) -> void:
	if Sfx.muted or not ResourceLoader.exists(TRICKLE):
		return
	var stream := load(TRICKLE) as AudioStreamOggVorbis
	if stream == null:
		return
	stream.loop = true
	var p := AudioStreamPlayer3D.new()
	p.name = "Trickle"
	p.stream = stream
	p.volume_db = -9.0
	p.unit_size = 2.5
	p.max_distance = 22.0
	p.pitch_scale = randf_range(0.85, 1.12)
	at.add_child(p)
	if p.is_inside_tree():
		p.play(randf() * stream.get_length())
	else:
		p.autoplay = true


## The path, smoothed sideways (owner, Nov 19: it kinked out where the rock bulged); points that would end up in
## the rock keep their place.
static func _smoothed(pts: PackedVector3Array) -> PackedVector3Array:
	var out := pts.duplicate()
	for round in 3:
		var prev := out.duplicate()
		for i in range(1, out.size() - 1):
			var m := (prev[i - 1] + prev[i] * 2.0 + prev[i + 1]) * 0.25
			out[i] = Vector3(m.x, prev[i].y, m.z)
	return out


## Down to the real floor under its lowest point (the rock as built, or dug since).
func _fit_fall(fall: Dictionary) -> void:
	if not is_inside_tree():
		return
	var pts: PackedVector3Array = fall.pts
	var last := pts[pts.size() - 1]
	var fl := GroundSnap.floor_at(get_world_3d().direct_space_state, last, 0.4, 12.0)
	if fl == Vector3.INF:
		return
	var path := PackedVector3Array()
	for q in pts:
		if q.y > fl.y + 0.05:
			path.append(q)
	if path.is_empty():
		return
	var end := path[path.size() - 1]
	while end.y - 0.25 > fl.y + 0.03:  # straight down the rest of the way
		end = end + Vector3.DOWN * 0.25
		path.append(end)
	path.append(Vector3(end.x, fl.y + 0.03, end.z))
	fall.shown = path
	_shape_fall(fall, Vector3(end.x, fl.y, end.z))


func _on_rock_changed(center: Vector3, radius: float) -> void:
	for fall in _falls:
		var pts: PackedVector3Array = fall.get("shown", fall.pts)
		var bottom := pts[pts.size() - 1]
		if Vector2(center.x - bottom.x, center.z - bottom.z).length() < radius + 1.0 and center.y < bottom.y + 1.5:
			# rock dug under it: it runs on down into the hole once the rock there is rebuilt (a moment later)
			get_tree().create_timer(0.6).timeout.connect(_fit_fall.bind(fall))


func _make_pool() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	mi.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/art/water.gdshader")
	mat.set_shader_parameter("drip", 1.0)
	mat.set_shader_parameter("radius", 0.5)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 45.0
	add_child(mi)
	return mi


func _shape_fall(fall: Dictionary, landing: Vector3) -> void:
	var pts: PackedVector3Array = fall.get("shown", fall.pts)
	var side: Vector3 = fall.side
	(fall.pool as Node3D).global_position = landing + Vector3.UP * 0.05
	(fall.splash as Node3D).global_position = landing + Vector3.UP * 0.05
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var down := 0.0
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for i in pts.size():
		if i > 0:
			down += pts[i].distance_to(pts[i - 1])
		var w := lerpf(0.3, 0.85, float(i) / float(pts.size() - 1))  # thin at the crack, spreading as it falls (round 2: wider)
		verts.append(pts[i] - side * w * 0.5)
		verts.append(pts[i] + side * w * 0.5)
		uvs.append(Vector2(0.0, down))
		uvs.append(Vector2(1.0, down))
	for i in pts.size() - 1:
		var k := i * 2
		for j in [k, k + 1, k + 2, k + 1, k + 3, k + 2]:
			st.set_uv(uvs[j])
			st.add_vertex(verts[j])
	st.generate_normals()
	(fall.mi as MeshInstance3D).mesh = st.commit()
	(fall.mat as ShaderMaterial).set_shader_parameter("length", down)


## Droplets bouncing up where the water lands (a few tiny glints, cheap: the graphics card moves them).
func _make_splash(at: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 24
	p.lifetime = 0.7
	p.visibility_aabb = AABB(Vector3(-1, -0.2, -1), Vector3(2, 1.4, 2))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 35.0
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 1.8
	pm.gravity = Vector3(0, -9.0, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.18
	pm.scale_min = 0.5
	pm.scale_max = 1.0
	p.process_material = pm
	var drop := SphereMesh.new()
	drop.radius = 0.012
	drop.height = 0.024
	drop.radial_segments = 6
	drop.rings = 3
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.7, 0.85, 0.95)
	drop.material = dm
	p.draw_pass_1 = drop
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_range_end = 30.0
	add_child(p)
	p.global_position = at + Vector3.UP * 0.05
	return p


## Puddles: [{pos, r, drip}]. Under each water drip (on the floor below it), and a few in low floor spots.
static func plan_puddles(maker: CaveMaker, spots: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in spots:
		if s.kind != GlowPlacer.DRIP:
			continue
		var fl := GlowPlacer._march(maker, (s.pos as Vector3) + Vector3.DOWN * 0.5, Vector3.DOWN, 20.0)
		if fl == Vector3.INF or maker.is_reserved(fl, 1.0):
			continue
		for r in [1.0, 0.6]:  # water only lies where the floor is flat (first look: a sheet on a slope was a stain)
			if _flat(maker, fl, r):
				out.append({pos = fl + Vector3.UP * 0.06, r = r, drip = true})
				break
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9500
	for room: Dictionary in maker.rooms:
		var n := PUDDLES_PER_CAVERN if room.big else 0
		for i in n:
			var a := rng.randf_range(0.0, TAU)
			var d := rng.randf_range(0.1, 0.7)
			var c: Vector3 = room.center
			var r: Vector3 = room.radii
			var at := Vector3(c.x + cos(a) * r.x * d, c.y, c.z + sin(a) * r.z * d)
			var size := rng.randf_range(0.8, 2.2)
			if maker.sdf_at(at) <= 0.3:
				continue
			var fl := GlowPlacer._march(maker, at, Vector3.DOWN, 20.0)
			if fl == Vector3.INF or maker.is_reserved(fl, size + 1.0) or maker._in_column(fl, size):
				continue
			# a low spot: the floor around is a little higher, so the water would gather here
			var low := true
			for k in 6:
				var q := fl + Vector3(cos(k * TAU / 6.0), 0.0, sin(k * TAU / 6.0)) * size
				var qf := GlowPlacer._march(maker, q + Vector3.UP * 1.0, Vector3.DOWN, 3.0)
				if qf == Vector3.INF or qf.y < fl.y - 0.05:
					low = false
					break
			if low:
				out.append({pos = fl + Vector3.UP * 0.08, r = size, drip = false})
	return out


## Is the floor around `fl` (within r) flat or a shallow dip: no point more than 4 cm below it or 25 cm above?
static func _flat(maker: CaveMaker, fl: Vector3, r: float) -> bool:
	for k in 8:
		var q := fl + Vector3(cos(k * TAU / 8.0), 0.0, sin(k * TAU / 8.0)) * r * 0.85
		var qf := GlowPlacer._march(maker, q + Vector3.UP * 1.0, Vector3.DOWN, 3.0)
		if qf == Vector3.INF or qf.y < fl.y - 0.04 or qf.y > fl.y + 0.25:
			return false
	return true


## Mist: [{pos, size}] in some of the deepest caverns (their floor in the lowest part of the cave).
static func plan_mist(maker: CaveMaker) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = maker.seed + 9600
	for room: Dictionary in maker.rooms:
		var roll := rng.randf()
		if not room.big or room.get("sealed", false) or roll > MIST_SHARE:
			continue
		var c: Vector3 = room.center
		var r: Vector3 = room.radii
		if c.y - r.y * 0.55 > (CaveMaker.Y_MIN + CaveMaker.Y_MAX) * 0.5:
			continue  # only the low caverns
		var fl := GlowPlacer._march(maker, c, Vector3.DOWN, 20.0)
		if fl == Vector3.INF:
			continue
		out.append({pos = fl + Vector3.UP * 0.8, size = Vector3(r.x * 1.5, 2.2, r.z * 1.5)})
	return out
