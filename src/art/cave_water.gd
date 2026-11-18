class_name CaveWater
extends Node3D
## Water in the caves (owner, Nov 18, F190: "water: puddles, small streams, a low mist in the deepest spots").
## - Puddles: one under every water drip (rings where the drops land), and a few in the low spots of cavern floors.
## - Mist: a thin, slowly drifting mist hugging the floor in some of the deepest caverns.
## (Streams need the cave itself to carve beds for them: a later step.) Only looks; planned from the cave.

const PUDDLES_PER_CAVERN := 2
const MIST_SHARE := 0.35  ## of the low caverns


func build(maker: CaveMaker, spots: Array[Dictionary]) -> void:
	var shader: Shader = load("res://src/art/water.gdshader")
	for p in plan_puddles(maker, spots):
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
