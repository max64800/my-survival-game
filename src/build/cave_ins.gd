class_name CaveIns
## Decides which rock falls after a dig (world doc section 6). Works on a copy of the voxels
## around the dig (a VoxelBuffer), so it never touches the live world while thinking.
##
## Two ways rock falls:
##  1. Island: a lump of rock that's no longer attached to anything.
##  2. Icicle: a thin hanging piece of rock, 20 m or longer, attached only at its top.
## Rock counts as attached ("anchored") if it reaches: the edge of the copied box (we can't
## see further, so assume it's attached), border rock, or a mine prop / ceiling panel top.

const HANG_LIMIT := 20
const THIN_FILL := 16  ## of 25 voxels in a 5×5 square
const ISLAND_MAX := 20000
const ICICLE_CAP := 3000
const HALF := Vector3i(16, 26, 16)  ## copied box: center - (16, 26, 16) .. center + (16, 24, 16)
const UP_EXTRA := 24
# What we know about each copied voxel:
const UNSEEN := 0
const LOOSE := 1  ## checked: part of a falling group
const HELD := 2  ## checked: attached to something

## The copied area for a dig at `center`: [origin, size].
static func box_for(center: Vector3) -> Array:
	var c := Vector3i(center.round())
	var origin := c - HALF
	var size := Vector3i(HALF.x * 2 + 1, HALF.y + UP_EXTRA + 1, HALF.z * 2 + 1)
	return [origin, size]


## Returns an Array of PackedVector3Array: each one is a group of rock voxels (world positions) that falls.
## `anchors` = world points (mine prop tops etc.); rock within 0.75 m of one is held up.
static func find_falls(buf: VoxelBuffer, origin: Vector3i, center: Vector3, radius: float, anchors: Array = []) -> Array:
	var size := buf.get_size()
	var c := Vector3i(center.round()) - origin
	var visited := PackedByteArray()
	visited.resize(size.x * size.y * size.z)
	var anchor_cells := {}
	for a in anchors:
		var ai := Vector3i((a as Vector3).round()) - origin
		for dz in range(-1, 2):
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					anchor_cells[ai + Vector3i(dx, dy, dz)] = true
	var falls := []
	# --- A. Islands: start from rock just outside the dug ball.
	var r := ceili(radius + 1.5)
	for z in range(-r, r + 1):
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				var d := Vector3(x, y, z).length()
				if d < radius - 0.5 or d > radius + 1.5:
					continue
				var v := c + Vector3i(x, y, z)
				if not _inside(v, size) or not _rock(buf, v) or visited[_idx(v, size)] != UNSEEN:
					continue
				var res := _fill(buf, v, size, visited, anchor_cells, ISLAND_MAX, 1 << 30)
				if not res.anchored:
					falls.append(_to_world(res.voxels, origin))
	# --- B. Icicles: thin hanging rock near the dig.
	for z in range(-4, 5):
		for x in range(-4, 5):
			for y in range(c.y - 24, c.y + 5):
				var b := Vector3i(c.x + x, y, c.z + z)
				if not _inside(b, size) or not _rock(buf, b) or visited[_idx(b, size)] == LOOSE:
					continue  # already falling as an island
				var below := b + Vector3i.DOWN
				if not _inside(below, size) or _rock(buf, below):
					continue  # not a hanging tip
				var h := 0
				var top := b.y
				while h <= HANG_LIMIT and top < size.y - 3:
					if _rock_count_5x5(buf, Vector3i(b.x, top, b.z), size) >= THIN_FILL:
						break
					top += 1
					h += 1
				if h < HANG_LIMIT:
					continue
				var piece_visited := PackedByteArray()
				piece_visited.resize(visited.size())
				var res := _fill(buf, b, size, piece_visited, anchor_cells, ICICLE_CAP, top)
				if not res.anchored:
					for cell in res.voxels:
						visited[_idx(cell, size)] = LOOSE
					falls.append(_to_world(res.voxels, origin))
	return falls


## Flood fill over rock (6 neighbours). Stops as "anchored" at the box edge, an anchor,
## border rock, rock already known to be held, or when it gets too big.
## `max_y` keeps icicle fills below their root. Everything it touched gets labelled
## HELD or LOOSE, so a later fill that bumps into it knows the answer right away.
static func _fill(buf: VoxelBuffer, start: Vector3i, size: Vector3i, visited: PackedByteArray, anchor_cells: Dictionary, cap: int, max_y: int) -> Dictionary:
	var stack: Array[Vector3i] = [start]
	var seen: Array[Vector3i] = [start]
	visited[_idx(start, size)] = LOOSE
	const DIRS := [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]
	var held := false
	while not stack.is_empty() and not held:
		var v: Vector3i = stack.pop_back()
		if v.x == 0 or v.y == 0 or v.z == 0 or v.x == size.x - 1 or v.y == size.y - 1 or v.z == size.z - 1 \
				or anchor_cells.has(v) or buf.get_voxel(v.x, v.y, v.z, VoxelBuffer.CHANNEL_INDICES) == Mat.BORDER \
				or seen.size() > cap:
			held = true
			break
		for d in DIRS:
			var n: Vector3i = v + d
			if n.y >= max_y or not _inside(n, size) or not _rock(buf, n):
				continue
			var i := _idx(n, size)
			if visited[i] == HELD:
				held = true
				break
			if visited[i] == UNSEEN:
				visited[i] = LOOSE
				stack.append(n)
				seen.append(n)
	if held:
		for cell in seen:
			visited[_idx(cell, size)] = HELD
		return {anchored = true}
	return {anchored = false, voxels = seen}


static func _rock_count_5x5(buf: VoxelBuffer, v: Vector3i, size: Vector3i) -> int:
	var n := 0
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var p := v + Vector3i(dx, 0, dz)
			if not _inside(p, size) or _rock(buf, p):
				n += 1
	return n


static func _rock(buf: VoxelBuffer, v: Vector3i) -> bool:
	return buf.get_voxel_f(v.x, v.y, v.z, VoxelBuffer.CHANNEL_SDF) < 0.0


static func _inside(v: Vector3i, size: Vector3i) -> bool:
	return v.x >= 0 and v.y >= 0 and v.z >= 0 and v.x < size.x and v.y < size.y and v.z < size.z


static func _idx(v: Vector3i, size: Vector3i) -> int:
	return v.x + v.y * size.x + v.z * size.x * size.y


static func _to_world(cells: Array, origin: Vector3i) -> PackedVector3Array:
	var out := PackedVector3Array()
	for v in cells:
		out.append(Vector3(v + origin))
	return out
