class_name World
extends Node3D
## World: holds the dig-anywhere terrain (Voxel Tools) and changes it.
## Only the GameAuthority should call apply_dig(), so every player's world stays the same.

const VIEW_DISTANCE := 128
const COLLISION_DISTANCE := 100  ## solid rock round your dwarf (creatures live up to 100 m away: MonsterManager.DESPAWN_FAR)
const TERRAIN_LAYER := 1

var maker: CaveMaker
var terrain: VoxelTerrain
var _tool: VoxelTool


## Caves already planned this session (same seed = same cave, and planning takes ~1.5 s).
## Safe to share: a CaveMaker never changes after it's made.
static var _planned := {}


func setup(seed: int) -> void:
	var key := "%d:%d" % [seed, CaveMaker.layout]  # the same seed makes different caves in each layout (F211)
	if not _planned.has(key):
		_planned[key] = CaveMaker.new(seed)
	maker = _planned[key]
	terrain = VoxelTerrain.new()
	terrain.name = "Terrain"
	var fmt := VoxelFormat.new()
	fmt.indices_depth = VoxelBuffer.DEPTH_8_BIT
	terrain.format = fmt
	var mesher := VoxelMesherTransvoxel.new()
	mesher.texturing_mode = VoxelMesherTransvoxel.TEXTURES_SINGLE_S4
	terrain.mesher = mesher
	terrain.generator = CaveGenerator.new(maker)
	# Keeps dug-out chunks in memory when you walk away. (Saving to disk comes in Step 7.)
	terrain.stream = VoxelStreamMemory.new()
	terrain.max_view_distance = VIEW_DISTANCE
	terrain.generate_collisions = true
	terrain.collision_layer = TERRAIN_LAYER
	var lo := Vector3i(CaveMaker.X_MIN - 16, CaveMaker.Y_MIN - 16, -CaveMaker.HALF_SIZE - 16)
	var hi := Vector3i(CaveMaker.X_MAX + 16, CaveMaker.Y_MAX + 16, CaveMaker.HALF_SIZE + 16)
	terrain.bounds = AABB(Vector3(lo), Vector3(hi - lo))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/world/terrain.gdshader")
	mat.set_shader_parameter("albedo_tex", preload("res://assets/textures/terrain/terrain_albedo.png"))
	mat.set_shader_parameter("normal_tex", preload("res://assets/textures/terrain/terrain_normal.png"))
	mat.set_shader_parameter("flat_shading", 1.0 if CaveMaker.rock_style == "blocks" else 0.0)  # soft light, like before (owner)
	_rock_mat = mat
	var star := maker.star_room()  # thicker glow-worm stars and a group of snakes there (owner F260, Nov 17)
	if not star.is_empty():
		mat.set_shader_parameter("star_center", star.center)
		mat.set_shader_parameter("star_radius", star.radius)
		mat.set_shader_parameter("star_snakes", float(star.snakes))
	var quiet := maker.quiet_room()  # no stars where you wake up (owner, Nov 19)
	if not quiet.is_empty():
		mat.set_shader_parameter("quiet_center", quiet.center)
		mat.set_shader_parameter("quiet_radius", quiet.radius)
	terrain.material_override = mat
	add_child(terrain)
	_tool = terrain.get_voxel_tool()


## True when the voxels around `p` are loaded and can be read/edited.
func is_ready_at(p: Vector3, radius: float = 2.0) -> bool:
	var r := Vector3.ONE * radius
	return _tool.is_area_editable(AABB(p - r, r * 2.0))


## Material of the rock voxel at `p` (rounded to the nearest voxel).
func material_at(p: Vector3) -> int:
	var vi := Vector3i(p.round())
	if not is_ready_at(p, 1.0):
		return maker.material_at(vi)
	_tool.channel = VoxelBuffer.CHANNEL_INDICES
	return _tool.get_voxel(vi)


func sdf_at(p: Vector3) -> float:
	_tool.channel = VoxelBuffer.CHANNEL_SDF
	return _tool.get_voxel_f(Vector3i(p.round()))


## The Mason's Shovel filling a dip (owner, Nov 17): makes a ball of rock of material `mat` where there is air.
## Returns how many voxels became rock. The opposite of apply_dig.
func apply_fill(center: Vector3, radius: float, mat: int) -> int:
	var lo := Vector3i((center - Vector3.ONE * (radius + 1.0)).floor())
	var hi := Vector3i((center + Vector3.ONE * (radius + 1.0)).ceil())
	var size := hi - lo + Vector3i.ONE
	if not _tool.is_area_editable(AABB(Vector3(lo), Vector3(size))):
		return 0
	var buf := VoxelBuffer.new()
	buf.create(size.x, size.y, size.z)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	var mask := (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES)
	_tool.copy(lo, buf, mask)
	var filled := 0
	for z in size.z:
		for y in size.y:
			for x in size.x:
				var old := buf.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
				var p := Vector3(lo + Vector3i(x, y, z))
				var solid := p.distance_to(center) - radius  # below 0 inside the ball
				if solid >= old:
					continue
				buf.set_voxel_f(solid, x, y, z, VoxelBuffer.CHANNEL_SDF)
				if old >= 0.0 and solid < 0.0:
					buf.set_voxel(mat, x, y, z, VoxelBuffer.CHANNEL_INDICES)
					filled += 1
	_tool.paste(lo, buf, mask)
	if filled > 0:
		changed.emit(center, radius)
	return filled


## Like sdf_at, but blended from the 8 voxels around p (sdf_at snaps to the nearest whole metre), for checks that
## care about a few centimetres, like "is this table touching the wall" (Station.in_rock).
func sdf_smooth(p: Vector3) -> float:
	_tool.channel = VoxelBuffer.CHANNEL_SDF
	var g := Vector3i(p.floor())
	var f := p - Vector3(g)
	var v := 0.0
	for i in 8:
		var o := Vector3i(i & 1, (i >> 1) & 1, (i >> 2) & 1)
		var w := (f.x if o.x else 1.0 - f.x) * (f.y if o.y else 1.0 - f.y) * (f.z if o.z else 1.0 - f.z)
		v += _tool.get_voxel_f(g + o) * w
	return v


## Finds the rock material nearest to `p` inside a small radius (what the pickaxe is touching).
func rock_material_near(p: Vector3, radius: float = 1.2) -> int:
	var best := -1
	var best_d := INF
	var r := ceili(radius)
	_tool.channel = VoxelBuffer.CHANNEL_SDF
	var c := Vector3i(p.round())
	for z in range(-r, r + 1):
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				var v := c + Vector3i(x, y, z)
				var d := Vector3(v).distance_to(p)
				if d > radius or d >= best_d:
					continue
				if _tool.get_voxel_f(v) < 0.0:
					best_d = d
					best = _material_of(v)
	return best


func _material_of(v: Vector3i) -> int:
	_tool.channel = VoxelBuffer.CHANNEL_INDICES
	var m := _tool.get_voxel(v)
	_tool.channel = VoxelBuffer.CHANNEL_SDF
	return m


## Carves a ball of rock away. Rock too hard for `tool_tier` (like border rock) is left alone.
## Returns how many voxels of each material turned into air: {Mat.STONE: 7, ...}
## Rock changed near `center` (dig or cave-in). Only looks listen (e.g. Clutter lifts away).
signal changed(center: Vector3, radius: float)
## Something was put down here (a chest, a barrel, a ruin's treasure): floor looks (pebbles, plants, mushroom grass)
## get out of the way. Not a dig: waterfalls, critters and root curtains don't listen (owner, Nov 19).
signal ground_taken(center: Vector3, radius: float)


func apply_dig(center: Vector3, radius: float, tool_tier: int = 0) -> Dictionary:
	var counts := {}
	var lo := Vector3i((center - Vector3.ONE * (radius + 1.0)).floor())
	var hi := Vector3i((center + Vector3.ONE * (radius + 1.0)).ceil())
	var size := hi - lo + Vector3i.ONE
	if not _tool.is_area_editable(AABB(Vector3(lo), Vector3(size))):
		return counts
	var buf := VoxelBuffer.new()
	buf.create(size.x, size.y, size.z)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	var mask := (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES)
	_tool.copy(lo, buf, mask)
	for z in size.z:
		for y in size.y:
			for x in size.x:
				var old := buf.get_voxel_f(x, y, z, VoxelBuffer.CHANNEL_SDF)
				var p := Vector3(lo + Vector3i(x, y, z))
				var carve := radius - p.distance_to(center)
				if carve <= old:
					continue
				var m := buf.get_voxel(x, y, z, VoxelBuffer.CHANNEL_INDICES)
				if not Mat.is_diggable(m, tool_tier):
					continue
				buf.set_voxel_f(carve, x, y, z, VoxelBuffer.CHANNEL_SDF)
				if old < 0.0 and carve >= 0.0:
					counts[m] = counts.get(m, 0) + 1
	_tool.paste(lo, buf, mask)
	if not counts.is_empty():
		changed.emit(center, radius)
	return counts


## Turns these rock voxels into air (a cave-in). Border rock is left alone.
## Returns how many voxels of each material fell: {Mat.STONE: 40, ...}
func remove_voxels(points: PackedVector3Array) -> Dictionary:
	var counts := {}
	if points.is_empty():
		return counts
	var lo := Vector3i(points[0])
	var hi := lo
	for p in points:
		lo = lo.min(Vector3i(p))
		hi = hi.max(Vector3i(p))
	var size := hi - lo + Vector3i.ONE
	if not _tool.is_area_editable(AABB(Vector3(lo), Vector3(size))):
		return counts
	var buf := VoxelBuffer.new()
	buf.create(size.x, size.y, size.z)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	var mask := (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES)
	_tool.copy(lo, buf, mask)
	for p in points:
		var v := Vector3i(p) - lo
		var m := buf.get_voxel(v.x, v.y, v.z, VoxelBuffer.CHANNEL_INDICES)
		if m == Mat.BORDER or m == Mat.EDGE or buf.get_voxel_f(v.x, v.y, v.z, VoxelBuffer.CHANNEL_SDF) >= 0.0:
			continue
		buf.set_voxel_f(0.6, v.x, v.y, v.z, VoxelBuffer.CHANNEL_SDF)
		counts[m] = counts.get(m, 0) + 1
	_tool.paste(lo, buf, mask)
	if not counts.is_empty():
		changed.emit((Vector3(lo) + Vector3(hi)) * 0.5, (Vector3(hi - lo)).length() * 0.5 + 1.0)
	return counts


## Copies the voxels in a box (for the cave-in check, which must not touch the live world).
func copy_area(origin: Vector3i, size: Vector3i) -> VoxelBuffer:
	if not _tool.is_area_editable(AABB(Vector3(origin), Vector3(size))):
		return null
	var buf := VoxelBuffer.new()
	buf.create(size.x, size.y, size.z)
	buf.set_channel_depth(VoxelBuffer.CHANNEL_INDICES, VoxelBuffer.DEPTH_8_BIT)
	_tool.copy(origin, buf, (1 << VoxelBuffer.CHANNEL_SDF) | (1 << VoxelBuffer.CHANNEL_INDICES))
	return buf


# ---------------------------------------------------------------- veins under the bridges
# The rock's look code gets the 16 rock bridges nearest the camera, twice a second (owner, Nov 18: the glowing veins
# "under the bridges as well"; all of them would make every ceiling pixel check every bridge).
var _rock_mat: ShaderMaterial
var _bridge_t := 0.0


func _process(delta: float) -> void:
	_bridge_t -= delta
	if _bridge_t > 0.0 or _rock_mat == null or maker == null:
		return
	_bridge_t = 0.5
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var at := cam.global_position
	var list := maker._bridges.duplicate()
	list.sort_custom(func(x, y): return ((x.a as Vector3).lerp(x.b, 0.5)).distance_squared_to(at) < ((y.a as Vector3).lerp(y.b, 0.5)).distance_squared_to(at))
	var ba := PackedVector4Array()
	var bb := PackedVector4Array()
	for br in list.slice(0, 16):
		ba.append(Vector4(br.a.x, br.a.y, br.a.z, float(br.w)))
		bb.append(Vector4(br.b.x, br.b.y, br.b.z, float(br.t)))
	var n := ba.size()
	ba.resize(16)
	bb.resize(16)
	_rock_mat.set_shader_parameter("bridge_count", n)
	_rock_mat.set_shader_parameter("bridge_a", ba)
	_rock_mat.set_shader_parameter("bridge_b", bb)
	_send_guides(at)


## The 16 tunnel mouths that lead on (CaveMaker.guide_points) nearest the camera, for the glowing veins.
func _send_guides(at: Vector3) -> void:
	var all := maker.guide_points()
	if all.is_empty():
		return
	var list := Array(all)
	list.sort_custom(func(x, y): return (x as Vector3).distance_squared_to(at) < (y as Vector3).distance_squared_to(at))
	var pts := PackedVector3Array(list.slice(0, 16))
	var n := pts.size()
	pts.resize(16)
	_rock_mat.set_shader_parameter("guide_count", n)
	_rock_mat.set_shader_parameter("guide_pts", pts)
