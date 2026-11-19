class_name Structure
extends RefCounted
## Everything that's been built, and how steady each piece is (world doc 5.6).
##  - A piece touching rock is 100% steady ("anchored").
##  - Every other piece takes the best steadiness of a piece it touches, minus a loss:
##    the "up" loss if that neighbour is below it, the "sideways" loss otherwise.
##    Wood loses fast, stone slower, metal slowest.
##  - Below 10% a piece falls apart.

var pieces := {}  ## uid -> {piece, family, pos, rot, hp, anchored, stability}
var version := 0  ## goes up whenever a piece is added or removed (the hammer's colors refresh)
## Pieces by 4 m cell, so a piece only checks the pieces near it (checking every piece against every other piece
## took many seconds once a ruin of 700 pieces stood in the world). Neighbour lists are kept until something changes.
const CELL := 4.0
var _cells := {}   ## Vector3i -> Array of uids
var _nb := {}      ## uid -> its neighbours (cleared on every add/remove)


func add(uid: int, piece: String, family: String, pos: Vector3, rot: int, anchored: bool) -> void:
	anchored = anchored or is_foundation(piece)  # foundations are always steady (spec §5)
	if pieces.has(uid):
		_unindex(uid)
	pieces[uid] = {piece = piece, family = family, pos = pos, rot = rot, hp = Pieces.hp(piece, family),
		anchored = anchored, stability = 1.0 if anchored else 0.0}
	for c in _cells_of(Pieces.box(piece, pos, rot)):
		if not _cells.has(c):
			_cells[c] = []
		_cells[c].append(uid)
	_nb.clear()
	version += 1


func _cells_of(b: AABB) -> Array:
	var lo := Vector3i(((b.position - Vector3.ONE * 0.25) / CELL).floor())
	var hi := Vector3i(((b.end + Vector3.ONE * 0.25) / CELL).floor())
	var out := []
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			for z in range(lo.z, hi.z + 1):
				out.append(Vector3i(x, y, z))
	return out


func _unindex(uid: int) -> void:
	var p: Dictionary = pieces[uid]
	for c in _cells_of(Pieces.box(p.piece, p.pos, p.rot)):
		if _cells.has(c):
			_cells[c].erase(uid)


static func is_foundation(piece: String) -> bool:
	return Pieces.LIST.get(piece, {}).get("foundation", false)


## The hammer's strength colors (spec §5): blue ≥ 0.75, green ≥ 0.5, yellow ≥ 0.25, red below.
static func strength_color(s: float) -> Color:
	if s >= 0.75:
		return Color(0.35, 0.6, 1.0)
	if s >= 0.5:
		return Color(0.35, 0.9, 0.4)
	if s >= 0.25:
		return Color(1.0, 0.85, 0.25)
	return Color(1.0, 0.3, 0.25)


func remove(uid: int) -> void:
	if pieces.has(uid):
		_unindex(uid)
	pieces.erase(uid)
	_nb.clear()
	version += 1


func box_of(uid: int) -> AABB:
	var p: Dictionary = pieces[uid]
	return Pieces.box(p.piece, p.pos, p.rot)


## Would a new piece overlap something already built? Outlines are shrunk a little first, so
## pieces that just touch (a wall on a floor's edge, two walls meeting at a corner, two triangles
## side by side) are fine. Uses the real outline seen from above (triangles, 30°/60° turns).
func overlaps(piece: String, pos: Vector3, rot: int) -> bool:
	var mine_y := _y_range(piece, pos, -0.16)
	var mine := Pieces.footprint(piece, pos, rot, -0.16)
	for uid in pieces:
		var o: Dictionary = pieces[uid]
		if fits_inside(piece, o.piece) or fits_inside(o.piece, piece):
			continue  # a door goes inside a doorway
		var oy := _y_range(o.piece, o.pos, -0.16)
		if mine_y.y <= oy.x or oy.y <= mine_y.x:
			continue
		if Pieces.outlines_overlap(mine, Pieces.footprint(o.piece, o.pos, o.rot, -0.16)):
			return true
	return false


## Bottom and top of a piece, grown (or shrunk, never past its middle).
static func _y_range(piece: String, pos: Vector3, grow: float) -> Vector2:
	var h: float = Pieces.LIST[piece].size.y
	var g := maxf(grow, -(h * 0.5 - 0.01))
	return Vector2(pos.y - g, pos.y + h + g)


## Do two pieces touch (or nearly: 6 cm)?
func _touching(piece: String, pos: Vector3, rot: int, other: Dictionary) -> bool:
	var a := _y_range(piece, pos, 0.06)
	var b := _y_range(other.piece, other.pos, 0.0)
	if a.y < b.x or b.y < a.x:
		return false
	return Pieces.outlines_overlap(Pieces.footprint(piece, pos, rot, 0.06), Pieces.footprint(other.piece, other.pos, other.rot, 0.0))


## Pieces made to sit inside another one's opening.
static func fits_inside(inner: String, outer: String) -> bool:
	return (inner == "door" and outer in ["doorway", "arch_doorway"]) or (inner == "gate_leaf" and outer == "gateway")


## Shrinks a box on every side, but never past its middle (thin walls stay valid boxes).
static func _shrunk(b: AABB, amount: float) -> AABB:
	var d := Vector3(minf(amount, b.size.x * 0.5 - 0.01), minf(amount, b.size.y * 0.5 - 0.01), minf(amount, b.size.z * 0.5 - 0.01))
	return AABB(b.position + d, b.size - d * 2.0)


func neighbors(uid: int) -> Array:
	if _nb.has(uid):
		return _nb[uid]
	var me: Dictionary = pieces[uid]
	var out := []
	var seen := {}
	for c in _cells_of(box_of(uid)):
		for other in _cells.get(c, []):
			if other != uid and not seen.has(other):
				seen[other] = true
				if _touching(me.piece, me.pos, me.rot, pieces[other]):
					out.append(other)
	_nb[uid] = out
	return out


## How steady a piece WOULD be if placed here (for the green/red ghost).
func preview_stability(piece: String, family: String, pos: Vector3, rot: int, anchored: bool) -> float:
	if anchored or is_foundation(piece):
		return 1.0
	var b := Pieces.box(piece, pos, rot)
	var best := 0.0
	for uid in pieces:
		var nb := box_of(uid)
		if not _touching(piece, pos, rot, pieces[uid]):
			continue
		best = maxf(best, pieces[uid].stability - _loss(family, nb, b, piece))
	return best


## Recomputes every piece's steadiness. Returns the uids that are now too shaky (they should fall).
func recompute() -> Array:
	for uid in pieces:
		pieces[uid].stability = 1.0 if pieces[uid].anchored else 0.0
	var changed := true
	var guard := 0
	while changed and guard < 500:
		changed = false
		guard += 1
		for uid in pieces:
			var me: Dictionary = pieces[uid]
			if me.anchored:
				continue
			var my_box := box_of(uid)
			for other in neighbors(uid):
				var s: float = pieces[other].stability - _loss(me.family, box_of(other), my_box, me.piece)
				if s > me.stability + 0.0001:
					me.stability = s
					changed = true
	var falling := []
	for uid in pieces:
		if pieces[uid].stability < Pieces.MIN_STABILITY:
			falling.append(uid)
	return falling


## Loss for `family` sitting next to a neighbour box: "up" if the neighbour is underneath.
## Pillars and columns carry weight straight down very well (spec §5: only 0.02 going up).
static func _loss(family: String, neighbor: AABB, me: AABB, piece: String = "") -> float:
	var f: Dictionary = Pieces.FAMILIES[family]
	var below := neighbor.end.y <= me.position.y + 0.05
	if below and piece in ["pillar", "column"]:
		return minf(Pieces.PILLAR_UP_LOSS, f.up)
	return f.up if below else f.side


func to_data() -> Array:
	var out := []
	for uid in pieces:
		var p: Dictionary = pieces[uid]
		out.append([uid, p.piece, p.family, p.pos, p.rot, p.anchored, p.get("open", false)])
	return out
