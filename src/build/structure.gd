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
	pieces[uid] = {piece = piece, family = family, pos = pos, rot = rot, hp = Pieces.hp(piece, family),
		anchored = anchored, stability = 1.0 if anchored else 0.0}


func remove(uid: int) -> void:
	pieces.erase(uid)


func box_of(uid: int) -> AABB:
	var p: Dictionary = pieces[uid]
	return Pieces.box(p.piece, p.pos, p.rot)


## Would a new piece overlap something already built? Boxes are shrunk a little so touching
## is fine. Different kinds (a wall on a floor's edge) may overlap a bit more: a wall sits
## half on the floor next to it.
func overlaps(piece: String, pos: Vector3, rot: int) -> bool:
	var kind: String = Pieces.LIST[piece].place
	for uid in pieces:
		var shrink := 0.05 if Pieces.LIST[pieces[uid].piece].place == kind else 0.2
		if _shrunk(box_of(uid), shrink).intersects(_shrunk(Pieces.box(piece, pos, rot), shrink)):
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
	if anchored:
		return 1.0
	var b := Pieces.box(piece, pos, rot)
	var best := 0.0
	for uid in pieces:
		var nb := box_of(uid)
		if not b.grow(0.06).intersects(nb):
			continue
		best = maxf(best, pieces[uid].stability - _loss(family, nb, b))
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
				var s: float = pieces[other].stability - _loss(me.family, box_of(other), my_box)
				if s > me.stability + 0.0001:
					me.stability = s
					changed = true
	var falling := []
	for uid in pieces:
		if pieces[uid].stability < Pieces.MIN_STABILITY:
			falling.append(uid)
	return falling


## Loss for `family` sitting next to a neighbour box: "up" if the neighbour is underneath.
static func _loss(family: String, neighbor: AABB, me: AABB) -> float:
	var f: Dictionary = Pieces.FAMILIES[family]
	var below := neighbor.end.y <= me.position.y + 0.05
	return f.up if below else f.side


func to_data() -> Array:
	var out := []
	for uid in pieces:
		var p: Dictionary = pieces[uid]
		out.append([uid, p.piece, p.family, p.pos, p.rot, p.anchored])
	return out
