class_name Structure
extends RefCounted
## Everything that's been built, and how steady each piece is (world doc 5.6).
##  - A piece touching rock is 100% steady ("anchored").
##  - Every other piece takes the best steadiness of a piece it touches, minus a loss:
##    the "up" loss if that neighbour is below it, the "sideways" loss otherwise.
##    Wood loses fast, stone slower, metal slowest.
##  - Below 10% a piece falls apart.

var pieces := {}  ## uid -> {piece, family, pos, rot, hp, anchored, stability}


func add(uid: int, piece: String, family: String, pos: Vector3, rot: int, anchored: bool) -> void:
	anchored = anchored or is_foundation(piece)  # foundations are always steady (spec §5)
	pieces[uid] = {piece = piece, family = family, pos = pos, rot = rot, hp = Pieces.hp(piece, family),
		anchored = anchored, stability = 1.0 if anchored else 0.0}


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
	pieces.erase(uid)


func box_of(uid: int) -> AABB:
	var p: Dictionary = pieces[uid]
	return Pieces.box(p.piece, p.pos, p.rot)


## Would a new piece overlap something already built? Boxes are shrunk a little first, so
## pieces that just touch (a wall on a floor's edge, two walls meeting at a corner) are fine.
func overlaps(piece: String, pos: Vector3, rot: int) -> bool:
	var mine := _shrunk(Pieces.box(piece, pos, rot), 0.16)
	for uid in pieces:
		if _shrunk(box_of(uid), 0.16).intersects(mine):
			return true
	return false


## Shrinks a box on every side, but never past its middle (thin walls stay valid boxes).
static func _shrunk(b: AABB, amount: float) -> AABB:
	var d := Vector3(minf(amount, b.size.x * 0.5 - 0.01), minf(amount, b.size.y * 0.5 - 0.01), minf(amount, b.size.z * 0.5 - 0.01))
	return AABB(b.position + d, b.size - d * 2.0)


func neighbors(uid: int) -> Array:
	var b := box_of(uid).grow(0.06)
	var out := []
	for other in pieces:
		if other != uid and b.intersects(box_of(other)):
			out.append(other)
	return out


## How steady a piece WOULD be if placed here (for the green/red ghost).
func preview_stability(piece: String, family: String, pos: Vector3, rot: int, anchored: bool) -> float:
	if anchored or is_foundation(piece):
		return 1.0
	var b := Pieces.box(piece, pos, rot)
	var best := 0.0
	for uid in pieces:
		var nb := box_of(uid)
		if not b.grow(0.06).intersects(nb):
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
		out.append([uid, p.piece, p.family, p.pos, p.rot, p.anchored])
	return out
