class_name World
extends Node3D
## World: holds the dig-anywhere terrain (Voxel Tools) and changes it.
## Only the GameAuthority should call apply_dig(), so every player's world stays the same.

const VIEW_DISTANCE := 128
const TERRAIN_LAYER := 1

var maker: CaveMaker
var terrain: VoxelTerrain
var _tool: VoxelTool


func setup(seed: int) -> void:
	maker = CaveMaker.new(seed)
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
	var lo := Vector3i(-CaveMaker.HALF_SIZE - 16, CaveMaker.Y_MIN - 16, -CaveMaker.HALF_SIZE - 16)
	var hi := Vector3i(CaveMaker.HALF_SIZE + 16, CaveMaker.Y_MAX + 16, CaveMaker.HALF_SIZE + 16)
	terrain.bounds = AABB(Vector3(lo), Vector3(hi - lo))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/world/terrain.gdshader")
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
		if m == Mat.BORDER or buf.get_voxel_f(v.x, v.y, v.z, VoxelBuffer.CHANNEL_SDF) >= 0.0:
			continue
		buf.set_voxel_f(0.6, v.x, v.y, v.z, VoxelBuffer.CHANNEL_SDF)
		counts[m] = counts.get(m, 0) + 1
	_tool.paste(lo, buf, mask)
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
