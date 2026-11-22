class_name PieceMesh
## The shapes of building pieces (building polish spec §6). Each (piece, material) shape is built
## once and shared by every copy, so hundreds of pieces stay fast.
##   wood   = planks with small gaps      stone = staggered blocks over a recessed backing
##   brick  = small bricks                 metal = plates with rivets
##   roofs  = shingle rows on a wedge      columns = 8 sides with a base, bands and a capital
## Every piece also has a plain "solid" shape (no detail) used for bumping into it.
## Colors/textures come from the material (PieceNode._mat → Claude 3's Look), not from here.

static var _visual := {}  ## "piece|style" -> ArrayMesh
static var _solid := {}   ## "piece" -> ArrayMesh (no detail)

static var _st: SurfaceTool
static var _xf := Transform3D.IDENTITY  ## where the shapes being added go (inside the piece)
static var _detail := true
static var _style := "plain"


## wood / stone / brick / metal / plain, from the material family.
static func style_of(family: String) -> String:
	if family.begins_with("plank"):
		return "wood"
	if family.ends_with("ingot"):
		return "metal"
	if family in ["clay_brick", "mushroom_brick", "ancient_brick"]:
		return "brick"
	if family == "crystal_blue":
		return "plain"
	return "stone"


static func visual(piece: String, family: String) -> ArrayMesh:
	var key := "%s|%s" % [piece, style_of(family)]
	if not _visual.has(key):
		_visual[key] = _make(piece, style_of(family), true)
	return _visual[key]


## The plain shape for collision (same outline, no planks/blocks/rivets).
static func solid(piece: String) -> ArrayMesh:
	if not _solid.has(piece):
		_solid[piece] = _make(piece, "plain", false)
	return _solid[piece]


static func _make(piece: String, style: String, detail: bool) -> ArrayMesh:
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_xf = Transform3D.IDENTITY
	_detail = detail
	_style = style
	var info: Dictionary = Pieces.LIST[piece]
	var s: Vector3 = info.size
	var shape: String = info.get("shape", "box")
	match shape:
		"roof": _roof(s, float(info.rise))
		"ridge": _ridge(s, float(info.rise))
		"roof_outer": _roof_outer(s, float(info.rise))
		"roof_inner": _roof_inner(s, float(info.rise))
		"gable": _gable(s, float(info.rise))
		"arch": _arch(s)
		"arch_doorway": _arch_doorway(s, info.opening)
		"column": _column(s)
		"brace": _brace(s)
		"ladder": _ladder(s)
		"railing": _railing(s)
		"railing_stairs": _stair_railing(s)
		"stairs_corner": _corner_steps(s, 8)
		"stairs_spiral": _spiral_steps(s)
		"hatch": _floor_hatch(s)
		"gable_down": _prism_z([Vector2(-s.x * 0.5, 0), Vector2(-s.x * 0.5, s.y), Vector2(s.x * 0.5, s.y)], -s.z * 0.5, s.z * 0.5)
		"roof_cap": _roof_cap(s)
		"door": _circle_door(s, float(info.circle)) if info.has("circle") else _door(s)
		"steps": _steps(s, 2)
		"ramp": _ramp(s)
		"triangle": _triangle(s)
		"tri": _tri(s)
		"flat_roof": _flat_roof(s)
		"battlement": _battlement(s)
		"battlement_corner": _battlement_corner(s)
		"diagonal": _diagonal(piece, s)
		"column_base", "column_shaft", "column_capital": _column_part(shape, s)
		"table", "bench": _table(s, shape == "bench")
		"chair": _chair(s)
		"shelf": _shelf(s)
		"barrel": _barrel(s)
		"crate": _crate(s)
		"rug": _box(Vector3(0, 0.01, 0), Vector3(s.x, 0.02, s.z))  # a thin backing; the cloth is drawn by PieceNode
		"banner": _banner(s)
		"wall_shield": _wall_shield(s)
		"plaque": _plaque(s)
		"block": _box(Vector3(0, s.y * 0.5, 0), s)  # furniture with its own model: a plain box to bump into
		"wall_sconce": _wall_sconce(s)
		"weapon_rack": _weapon_rack(s)
		_: _plain_piece(piece, s, info)
	var mesh := _st.commit()
	_st = null
	return mesh


# ================================================================== pieces

static func _plain_piece(piece: String, s: Vector3, info: Dictionary) -> void:
	var group: String = info.get("group", "")
	if info.has("opening"):
		if info.has("circle"):
			_circle_hole(s, info.opening.x * 0.5, float(info.circle))
		elif info.get("round", false):
			_round_hole(s, info.opening, false)
		else:
			_wall_with_hole(s.x, s.y, s.z, info.opening)
		return
	match piece:
		"stairs":
			_steps(s, 4)
		"pillar":
			_slab(Vector3(0, s.y * 0.5, 0), s, "post")
			_box(Vector3(0, 0.075, 0), Vector3(s.x + 0.15, 0.15, s.z + 0.15))
			_box(Vector3(0, s.y - 0.075, 0), Vector3(s.x + 0.15, 0.15, s.z + 0.15))
		"mine_prop":
			_slab(Vector3(-0.8, (s.y - 0.25) * 0.5, 0), Vector3(0.3, s.y - 0.25, 0.3), "post")
			_slab(Vector3(0.8, (s.y - 0.25) * 0.5, 0), Vector3(0.3, s.y - 0.25, 0.3), "post")
			_slab(Vector3(0, s.y - 0.15, 0), Vector3(s.x, 0.3, s.z), "beam")
		_:
			match group:
				"foundation":
					_slab(Vector3(0, s.y * 0.5 - 0.05, 0), Vector3(s.x, s.y - 0.1, s.z), "wall_x")
					_box(Vector3(0, s.y - 0.05, 0), Vector3(s.x - 0.06, 0.1, s.z - 0.06))  # a top lip
				"floor", "mining":
					_slab(Vector3(0, s.y * 0.5, 0), s, "floor")
				"support":
					_slab(Vector3(0, s.y * 0.5, 0), s, "beam")
				_:
					_slab(Vector3(0, s.y * 0.5, 0), s, "wall")


## A wall-like piece of length `w` with a rectangular hole: opening = (width, height, bottom).
static func _wall_with_hole(w: float, h: float, d: float, opening: Vector3) -> void:
	var side := (w - opening.x) * 0.5
	var bottom := opening.z
	var top := h - bottom - opening.y
	_slab(Vector3(-(opening.x + side) * 0.5, h * 0.5, 0), Vector3(side, h, d), "wall")
	_slab(Vector3((opening.x + side) * 0.5, h * 0.5, 0), Vector3(side, h, d), "wall")
	if top > 0.01:
		_slab(Vector3(0, h - top * 0.5, 0), Vector3(opening.x, top, d), "wall")
	if bottom > 0.01:
		_slab(Vector3(0, bottom * 0.5, 0), Vector3(opening.x, bottom, d), "wall")
	if _detail:
		# A frame around the opening: a sill (windows), side posts and a lintel.
		var fy := bottom + opening.y * 0.5
		_box(Vector3(-opening.x * 0.5 - 0.04, fy, 0), Vector3(0.08, opening.y, d + 0.06))
		_box(Vector3(opening.x * 0.5 + 0.04, fy, 0), Vector3(0.08, opening.y, d + 0.06))
		_box(Vector3(0, bottom + opening.y + 0.05, 0), Vector3(opening.x + 0.24, 0.1, d + 0.08))
		if bottom > 0.01:
			_box(Vector3(0, bottom - 0.03, 0), Vector3(opening.x + 0.2, 0.06, d + 0.12))


static func _steps(s: Vector3, count: int) -> void:
	for i in count:
		var h := (i + 1) * s.y / count
		var depth := s.z / count
		_slab(Vector3(0, h * 0.5, s.z * 0.5 - (i + 0.5) * depth), Vector3(s.x, h, depth), "floor")


## Ramp: a solid wedge, low at the front (z = +d/2) and full height at the back, with cleats
## across the slope so it looks walkable.
static func _ramp(s: Vector3) -> void:
	var hz := s.z * 0.5
	_prism_x([Vector2(hz, 0.0), Vector2(-hz, 0.0), Vector2(-hz, s.y)], -s.x * 0.5, s.x * 0.5)
	if _detail:
		var slope := atan2(s.y, s.z)
		for i in 4:
			var t := (i + 0.5) / 4.0
			_push(Transform3D(Basis(Vector3.RIGHT, slope), Vector3(0, s.y * t, hz - s.z * t)))
			_box(Vector3(0, 0.025, 0), Vector3(s.x - 0.1, 0.05, 0.08))
			_pop()


## Roof: low at the front (z = +d/2), `rise` higher at the back.
static func _roof(s: Vector3, rise: float) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var t := 0.15  # thickness at the low edge
	_prism_x([Vector2(hz, 0), Vector2(hz, t), Vector2(-hz, rise), Vector2(-hz, 0)], -hx, hx)
	_shingles(s.x, s.z, rise, t)


static func _ridge(s: Vector3, rise: float) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	_prism_x([Vector2(hz, 0), Vector2(hz, 0.12), Vector2(0, rise), Vector2(-hz, 0.12), Vector2(-hz, 0)], -hx, hx)
	if _detail:
		_box(Vector3(0, rise + 0.03, 0), Vector3(s.x + 0.04, 0.12, 0.3))  # the cap along the top


## Outside corner of a hip roof: highest at the back-left corner (−x, −z).
static func _roof_outer(s: Vector3, rise: float) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var a := Vector3(-hx, 0, -hz)
	var b := Vector3(hx, 0, -hz)
	var c := Vector3(hx, 0, hz)
	var d := Vector3(-hx, 0, hz)
	var top := Vector3(-hx, rise, -hz)
	_face([a, b, c, d], Vector3.DOWN)
	_face([a, b, top], Vector3.BACK * -1.0)
	_face([a, d, top], Vector3.LEFT)
	_face([b, c, top], Vector3(1, 1, 0))
	_face([c, d, top], Vector3(0, 1, 1))


## Inside corner (a valley): high along the back and the left, low at the front-right corner.
static func _roof_inner(s: Vector3, rise: float) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var fr := Vector3(hx, 0, hz)
	var b0 := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), fr, Vector3(-hx, 0, hz)]
	_face(b0, Vector3.DOWN)
	var bl := Vector3(-hx, rise, -hz)
	var br := Vector3(hx, rise, -hz)
	var fl := Vector3(-hx, rise, hz)
	_face([fr, br, bl], Vector3(0, 1, 1))   # slope rising to the back
	_face([fr, bl, fl], Vector3(1, 1, 0))   # slope rising to the left
	_face([Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), br, bl], Vector3.FORWARD)
	_face([Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), fl, bl], Vector3.LEFT)
	_face([Vector3(-hx, 0, hz), fr, fl], Vector3.BACK)
	_face([fr, Vector3(hx, 0, -hz), br], Vector3.RIGHT)


## A gable: a triangle of wall rising from the left end (x = −w/2) to `rise` at the right end.
static func _gable(s: Vector3, rise: float) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	_prism_z([Vector2(-hx, 0), Vector2(hx, 0), Vector2(hx, rise)], -hz, hz)
	if _detail:
		var seg_len := Vector2(s.x, rise).length()
		_push(Transform3D(Basis(Vector3.BACK, atan2(rise, s.x)), Vector3(0, rise * 0.5 + 0.06, 0)))
		_box(Vector3.ZERO, Vector3(seg_len, 0.12, s.z + 0.06))  # a trim board along the slope
		_pop()


## Stone arch: two side blocks, a curved row of wedge stones, and a flat top.
static func _arch(s: Vector3) -> void:
	var hx := s.x * 0.5
	var d := s.z
	_slab(Vector3(-hx + 0.15, s.y * 0.5, 0), Vector3(0.3, s.y, d), "post")
	_slab(Vector3(hx - 0.15, s.y * 0.5, 0), Vector3(0.3, s.y, d), "post")
	_slab(Vector3(0, s.y - 0.12, 0), Vector3(s.x, 0.24, d), "beam")
	var r := hx - 0.3
	_round_top(r, s.y - 0.24 - r, s.y - 0.24, d, 0.22, d + 0.04)


## A round-topped opening in a wall (F57: round doors, like a hobbit hole): side walls, a wall
## above, and the curve between them filled in; stone and brick get a ring of wedge stones.
static func _arch_doorway(s: Vector3, opening: Vector3) -> void:
	_round_hole(s, opening, true)


static func _round_hole(s: Vector3, opening: Vector3, stones: bool) -> void:
	var r := opening.x * 0.5
	var side := (s.x - opening.x) * 0.5
	_slab(Vector3(-(opening.x + side) * 0.5, s.y * 0.5, 0), Vector3(side, s.y, s.z), "wall")
	_slab(Vector3((opening.x + side) * 0.5, s.y * 0.5, 0), Vector3(side, s.y, s.z), "wall")
	var top := s.y - opening.y
	if top > 0.01:
		_slab(Vector3(0, s.y - top * 0.5, 0), Vector3(opening.x, top, s.z), "wall")
	var ring := minf(0.24, s.y - opening.y - 0.005) if stones and _style in ["stone", "brick"] else 0.07
	ring = maxf(ring, 0.07)
	var ring_d := s.z + (0.04 if ring > 0.1 else 0.06)
	_round_top(r, opening.y - r, opening.y, s.z - 0.02, ring if _detail else 0.0, ring_d)
	if _detail:  # straight trim down both sides of the opening, under the ring
		for x in [-r - ring * 0.5, r + ring * 0.5]:
			_box(Vector3(x, (opening.y - r) * 0.5, 0), Vector3(ring, opening.y - r, ring_d - 0.01))


## The curved top of an opening: radius `r` around (0, spring). Fills the corners up to `top`
## (so nothing pokes into the opening), plus a ring of `count` wedges `ring` thick (0 = none).
## Every part meets the next edge to edge; nothing overlaps on the same flat face.
static func _round_top(r: float, spring: float, top: float, fill_d: float, ring: float, ring_d: float, count: int = 9) -> void:
	for i in count:
		var a0 := PI * i / count
		var a1 := PI * (i + 1) / count
		var p0 := Vector2(cos(a0) * r, spring + sin(a0) * r)
		var p1 := Vector2(cos(a1) * r, spring + sin(a1) * r)
		if top - maxf(p0.y, p1.y) > 0.005 or top - minf(p0.y, p1.y) > 0.005:
			_prism_z([p0, p1, Vector2(p1.x, top), Vector2(p0.x, top)], -fill_d * 0.5, fill_d * 0.5)
		if ring > 0.0:
			var g := 0.012 if ring > 0.1 else 0.0  # mortar between wedge stones
			var b0 := a0 + g
			var b1 := a1 - g
			var q := [Vector2(cos(b0) * r, spring + sin(b0) * r), Vector2(cos(b0) * (r + ring), spring + sin(b0) * (r + ring)),
				Vector2(cos(b1) * (r + ring), spring + sin(b1) * (r + ring)), Vector2(cos(b1) * r, spring + sin(b1) * r)]
			_prism_z(q, -ring_d * 0.5, ring_d * 0.5)


## Carved column: square plinth, 8-sided shaft with two bands, flared capital.
static func _column(s: Vector3) -> void:
	var w := s.x
	_box(Vector3(0, 0.1, 0), Vector3(w, 0.2, w))
	_cyl(Vector3(0, 0.2, 0), w * 0.42, w * 0.38, s.y - 0.5)
	if _detail:
		for f in [0.33, 0.66]:
			_cyl(Vector3(0, 0.2 + (s.y - 0.5) * f - 0.05, 0), w * 0.44, w * 0.44, 0.1)
	_cyl(Vector3(0, s.y - 0.3, 0), w * 0.38, w * 0.5, 0.15)
	_box(Vector3(0, s.y - 0.075, 0), Vector3(w, 0.15, w))


# ---------------------------------------------------------------- decor (front = +z for wall pieces)

## Stackable column parts: a square plinth with a round foot, a round shaft, a flared top.
static func _column_part(shape: String, s: Vector3) -> void:
	var w := s.x
	match shape:
		"column_base":
			_box(Vector3(0, 0.12, 0), Vector3(w, 0.24, w))
			_cyl(Vector3(0, 0.24, 0), w * 0.46, w * 0.4, 0.12)
			_cyl(Vector3(0, 0.36, 0), w * 0.38, w * 0.36, s.y - 0.36)
		"column_shaft":
			_cyl(Vector3.ZERO, w * 0.36, w * 0.36, s.y)
			if _detail:
				_cyl(Vector3(0, s.y * 0.5 - 0.04, 0), w * 0.39, w * 0.39, 0.08)
		"column_capital":
			_cyl(Vector3.ZERO, w * 0.36, w * 0.38, 0.12)
			_cyl(Vector3(0, 0.12, 0), w * 0.38, w * 0.52, s.y - 0.3)
			_box(Vector3(0, s.y - 0.09, 0), Vector3(w, 0.18, w))


## A table (or a lower, narrower bench): a thick top on four legs, with a stretcher between them.
static func _table(s: Vector3, bench: bool) -> void:
	var top := 0.08 if bench else 0.1
	_slab(Vector3(0, s.y - top * 0.5, 0), Vector3(s.x, top, s.z), "floor")
	var lx := s.x * 0.5 - 0.12
	var lz := s.z * 0.5 - 0.1
	var leg := 0.09 if bench else 0.11
	for x in [-lx, lx]:
		for z in ([0.0] if bench else [-lz, lz]):
			_box(Vector3(x, (s.y - top) * 0.5, z), Vector3(leg, s.y - top, 0.3 if bench else leg))
	_box(Vector3(0, 0.18, 0), Vector3(s.x - 0.24, 0.06, 0.06))


static func _chair(s: Vector3) -> void:
	var seat := 0.45
	_slab(Vector3(0, seat - 0.03, 0), Vector3(s.x, 0.06, s.z), "floor")
	var l := s.x * 0.5 - 0.05
	for x in [-l, l]:
		for z in [-l, l]:
			_box(Vector3(x, (seat - 0.06) * 0.5, z), Vector3(0.06, seat - 0.06, 0.06))
	for x in [-l, l]:  # the back posts and two slats, at the back (−z)
		_box(Vector3(x, seat + (s.y - seat) * 0.5, -l), Vector3(0.06, s.y - seat, 0.06))
	for y in [seat + 0.25, s.y - 0.08]:
		_box(Vector3(0, y, -l), Vector3(s.x - 0.1, 0.08, 0.04))


static func _shelf(s: Vector3) -> void:
	for x in [-s.x * 0.5 + 0.04, s.x * 0.5 - 0.04]:
		_box(Vector3(x, s.y * 0.5, 0), Vector3(0.08, s.y, s.z))
	_box(Vector3(0, s.y * 0.5, -s.z * 0.5 + 0.02), Vector3(s.x, s.y, 0.04))  # back board
	for i in 4:
		_slab(Vector3(0, 0.05 + i * (s.y - 0.1) / 3.0, 0), Vector3(s.x - 0.16, 0.05, s.z - 0.04), "floor")
	if _detail:  # a few pots and boxes on the shelves
		_cyl(Vector3(-0.3, 0.08 + (s.y - 0.1) / 3.0, 0.02), 0.1, 0.08, 0.22)
		_box(Vector3(0.25, 0.18 + (s.y - 0.1) / 3.0, 0.02), Vector3(0.3, 0.22, 0.22))
		_cyl(Vector3(0.1, 0.08 + 2.0 * (s.y - 0.1) / 3.0, 0.02), 0.12, 0.1, 0.18)


static func _barrel(s: Vector3) -> void:
	var r := s.x * 0.5
	_cyl(Vector3.ZERO, r * 0.82, r, s.y * 0.5)
	_cyl(Vector3(0, s.y * 0.5, 0), r, r * 0.82, s.y * 0.5)
	if _detail:  # hoops
		for y in [0.12, s.y - 0.16]:
			_cyl(Vector3(0, y, 0), r * 0.9, r * 0.9, 0.04)
		_cyl(Vector3(0, s.y * 0.5 - 0.03, 0), r * 1.02, r * 1.02, 0.06)


static func _crate(s: Vector3) -> void:
	_box(Vector3(0, s.y * 0.5, 0), s - Vector3(0.06, 0.06, 0.06))
	if _detail:  # a frame of thicker boards on each edge
		var h := s * 0.5
		for x in [-h.x + 0.04, h.x - 0.04]:
			for z in [-h.z + 0.04, h.z - 0.04]:
				_box(Vector3(x, h.y, z), Vector3(0.08, s.y, 0.08))
		for y in [0.04, s.y - 0.04]:
			_box(Vector3(0, y, -h.z + 0.04), Vector3(s.x, 0.08, 0.08))
			_box(Vector3(0, y, h.z - 0.04), Vector3(s.x, 0.08, 0.08))
			_box(Vector3(-h.x + 0.04, y, 0), Vector3(0.08, 0.08, s.z))
			_box(Vector3(h.x - 0.04, y, 0), Vector3(0.08, 0.08, s.z))


## A banner's pole and the cord it hangs from (the cloth itself is drawn by PieceNode).
static func _banner(s: Vector3) -> void:
	_box(Vector3(0, s.y - 0.05, 0), Vector3(s.x + 0.1, 0.06, 0.06))
	for x in [-s.x * 0.5 - 0.05, s.x * 0.5 + 0.05]:
		_box(Vector3(x, s.y - 0.05, 0), Vector3(0.09, 0.09, 0.09))


## A round shield with a boss in the middle, hung flat on the wall.
## Wall decor before its model is ready: a board on the wall with a raised middle.
static func _plaque(s: Vector3) -> void:
	_slab(Vector3(0, s.y * 0.5, -s.z * 0.5 + 0.03), Vector3(s.x, s.y, 0.06), "wall")
	_box(Vector3(0, s.y * 0.5, -s.z * 0.5 + 0.06 + minf(s.z - 0.06, 0.08) * 0.5), Vector3(s.x * 0.6, s.y * 0.6, minf(s.z - 0.06, 0.08)))


static func _wall_shield(s: Vector3) -> void:
	var r := s.x * 0.5
	_push(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, s.y * 0.5, -s.z * 0.5)))
	_cyl(Vector3.ZERO, r, r, s.z * 0.6)
	_cyl(Vector3(0, s.z * 0.6, 0), r * 0.25, r * 0.18, s.z * 0.4)
	if _detail:
		_cyl(Vector3(0, s.z * 0.6, 0), r * 0.98, r * 0.92, 0.015)  # a rim
	_pop()


## A bracket from the wall holding a little bowl (the crystal glows; PieceNode adds the light).
static func _wall_sconce(s: Vector3) -> void:
	_box(Vector3(0, s.y * 0.5, -s.z * 0.5 + 0.03), Vector3(0.12, s.y * 0.8, 0.06))
	_box(Vector3(0, s.y * 0.35, -0.02), Vector3(0.05, 0.05, s.z * 0.8))
	_cyl(Vector3(0, s.y * 0.45, 0.04), 0.06, 0.12, 0.08)


static func _weapon_rack(s: Vector3) -> void:
	for x in [-s.x * 0.5 + 0.05, s.x * 0.5 - 0.05]:
		_box(Vector3(x, s.y * 0.5, 0), Vector3(0.1, s.y, 0.1))
		_box(Vector3(x, 0.04, 0), Vector3(0.12, 0.08, s.z))  # feet
	for y in [0.35, s.y - 0.25]:
		_slab(Vector3(0, y, 0), Vector3(s.x, 0.08, 0.1), "beam")
	if _detail:  # three spears leaning in it
		for i in 3:
			_box(Vector3(-0.4 + i * 0.4, (s.y - 0.16) * 0.5 + 0.04, 0.08), Vector3(0.04, s.y - 0.24, 0.04))
			_box(Vector3(-0.4 + i * 0.4, s.y - 0.1, 0.08), Vector3(0.08, 0.16, 0.02))


## A diagonal brace: a beam from the bottom-left to the top-right corner.
static func _brace(s: Vector3) -> void:
	var seg_len := Vector2(s.x, s.y).length()
	_push(Transform3D(Basis(Vector3.BACK, atan2(s.y, s.x)), Vector3(0, s.y * 0.5, 0)))
	_slab(Vector3.ZERO, Vector3(seg_len - 0.25, 0.22, s.z), "beam")  # its ends stay above the floor
	_pop()


static func _ladder(s: Vector3) -> void:
	for x in [-s.x * 0.4, s.x * 0.4]:
		_box(Vector3(x, s.y * 0.5, 0), Vector3(0.08, s.y, 0.08))
	var rungs := int(s.y / 0.3)
	for i in rungs:
		_box(Vector3(0, 0.2 + i * 0.3, 0), Vector3(s.x * 0.8, 0.05, 0.06))


static func _railing(s: Vector3) -> void:
	for x in [-s.x * 0.5 + 0.06, 0.0, s.x * 0.5 - 0.06]:
		_box(Vector3(x, s.y * 0.5, 0), Vector3(0.1, s.y, 0.1))
	_box(Vector3(0, s.y - 0.05, 0), Vector3(s.x, 0.1, 0.14))
	_box(Vector3(0, s.y * 0.5, 0), Vector3(s.x, 0.06, 0.06))


## Stair railing: along x, climbing (s.y − 1) m from the left end to the right end like the stairs beside it.
## Solid: a slanted panel 1 m tall (you can't step off the stairs' side). Look: three posts and two slanted rails.
static func _stair_railing(s: Vector3) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var climb := s.y - 1.0
	if not _detail:
		_prism_z([Vector2(-hx, 0), Vector2(-hx, 1.0), Vector2(hx, s.y), Vector2(hx, climb)], -hz, hz)
		return
	_prism_z([Vector2(-hx, 0.88), Vector2(-hx, 1.0), Vector2(hx, s.y), Vector2(hx, s.y - 0.12)], -hz, hz)  # hand rail
	_prism_z([Vector2(-hx, 0.4), Vector2(-hx, 0.46), Vector2(hx, climb + 0.46), Vector2(hx, climb + 0.4)], -0.04, 0.04)
	for x: float in [-hx + 0.06, 0.0, hx - 0.06]:
		var y0: float = 0.0 if x < -0.5 else (x + hx) / s.x * climb  # the first post stands on the floor
		var y1: float = (x + hx) / s.x * climb + 0.94
		_box(Vector3(x, (y0 + y1) * 0.5, 0), Vector3(0.1, y1 - y0, 0.1))


## Where a ray from the corner c (x, z) at angle a (0 = +x, 90° = −z) leaves the square ±hx, ±hz.
static func _square_exit(c: Vector2, a: float, hx: float, hz: float) -> Vector2:
	var d := Vector2(cos(a), -sin(a))
	var t := 99.0
	if d.x > 0.000001:
		t = minf(t, (hx - c.x) / d.x)
	if d.y < -0.000001:
		t = minf(t, (-hz - c.y) / d.y)
	return c + d * t


## Corner stairs: n wedge steps fanning a quarter turn round the front-left corner, from along the front
## edge (lowest) to along the left edge (top, s.y up). Each step reaches CORNER_UNDER below the one before (F169).
## F169: how thick the stairs' undersides are, straight down. The models (stonehold_v2.py, hearthbrick_v2_*.py) match.
const STAIRS_UNDER := 0.58     # straight stairs: the slanted underside is this far below the line of the step tips
const CORNER_UNDER := 0.2      # corner stairs: each step reaches this far below the step before it
## F716 (owner, Nov 22: "my dwarf had a very hard time climbing them, and they should come to a solid block"):
## the spiral is 4×4 m. 9 wide treads climb 3/4 of a turn round a thick post (from +x toward −z), then a landing
## fills the last quarter (+x, +z) at the top, over the way in, so nothing hangs low over a tread. A rail runs
## round the outside. The models (spiral_layout.py in tools/asset_forge/builds) use the same numbers.
const SPIRAL_TREAD := 0.18     # spiral stairs: each tread's thickness
const SPIRAL_STEPS := 9        # treads, 30° each
const SPIRAL_POST := 0.32      # the post's radius
const SPIRAL_REACH := 1.84     # treads reach this far from the middle along x or z (a wall's inner face is at 1.85)
const SPIRAL_LANDING := 1.75   # the landing's underside (its top is the piece's top)
const SPIRAL_RAIL := 1.76      # the outer rail's middle, from the post along x or z
const SPIRAL_RAIL_H := 0.85    # how high the rail stands over the slope


## F169: how high the open space under a stair piece is at a spot (x, z in the piece's own unturned frame, its
## bottom at y 0): 0 = solid there (or the post), INF = nothing above (outside it). Used so chests, barrels and
## other furniture can go under stairs (Structure.fits_under_stairs).
static func stair_underside(piece: String, s: Vector3, q: Vector2) -> float:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	if absf(q.x) > hx or absf(q.y) > hz:
		return INF
	match piece:
		"stairs":
			return maxf(0.0, (hz - q.y) / (2.0 * hz) * s.y - STAIRS_UNDER)
		"stairs_corner":
			if q.x < -hx + 0.32 and q.y > hz - 0.32:
				return 0.0  # the post at the turn
			var n := 8
			var a := atan2(hz - q.y, q.x + hx)
			var i := clampi(int(a / (PI * 0.5) * n), 0, n - 1)
			return maxf(0.0, s.y * i / n - CORNER_UNDER)
		"stairs_spiral":
			if q.length() < SPIRAL_POST + 0.02:
				return 0.0  # the post
			for c in [Vector2(1.72, 1.72), Vector2(1.73, -1.73), Vector2(-1.73, -1.73), Vector2(-1.73, 1.73)]:
				if absf(q.x - c.x) < 0.16 and absf(q.y - c.y) < 0.16:
					return 0.0  # a corner pillar
			if q.x >= 0.0 and q.y >= 0.0:
				return SPIRAL_LANDING
			var a := fposmod(atan2(-q.y, q.x), TAU)
			var i := clampi(int(a / (PI / 6.0)), 0, SPIRAL_STEPS - 1)
			return maxf(0.0, s.y * 0.1 * (i + 1) - SPIRAL_TREAD)
	return 0.0


static func _corner_steps(s: Vector3, n: int) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var c := Vector2(-hx, hz)
	var far := atan2(2.0 * hz, 2.0 * hx)  # the back-right corner's angle
	for i in n:
		var a0 := PI * 0.5 * i / n
		var a1 := PI * 0.5 * (i + 1) / n
		var pts := [c, _square_exit(c, a0, hx, hz)]
		if a0 + 0.0001 < far and far < a1 - 0.0001:
			pts.append(Vector2(hx, -hz))
		pts.append(_square_exit(c, a1, hx, hz))
		# F169: open below; each step reaches only CORNER_UNDER under the step before it (like the models)
		_prism_y(pts, maxf(0.0, s.y * i / n - CORNER_UNDER), s.y * (i + 1) / n)
	_box(Vector3(-hx + 0.16, s.y * 0.5, hz - 0.16), Vector3(0.3, s.y, 0.3))  # the post at the turn


## Where a ray from the middle at angle a (0 = +x, 90° = −z) meets the square ±h.
static func _sq(a: float, h: float) -> Vector2:
	var d := Vector2(cos(a), -sin(a))
	return d * h / maxf(absf(d.x), absf(d.y))


## Spiral tread i seen from above (x, z): a 30° wedge from the post out to the square, a little over the next
## tread (no gaps seen from above; the last one stops at the landing).
static func spiral_tread(i: int) -> Array:
	var a0 := PI / 6.0 * i
	var a1 := PI / 6.0 * (i + 1) + (0.05 if i < SPIRAL_STEPS - 1 else 0.0)
	var pts := [_sq(a0, SPIRAL_REACH)]
	for c in [PI * 0.25, PI * 0.75, PI * 1.25]:
		if a0 < c and c < a1:
			pts.append(_sq(c, SPIRAL_REACH))
	pts.append(_sq(a1, SPIRAL_REACH))
	pts.append(Vector2(cos(a1), -sin(a1)) * (SPIRAL_POST - 0.06))
	pts.append(Vector2(cos(a0), -sin(a0)) * (SPIRAL_POST - 0.06))
	return pts


## The smooth slope you walk up at angle a: from the floor (no lip: under the landing there's no head room for a
## step-up), through the middle of every tread top, to 10 cm under the landing (a step-up there, in the open).
static func spiral_slope_y(s: Vector3, a: float) -> float:
	var u := a / (PI / 6.0)
	return minf(s.y, s.y * (0.1 * u + 0.05 * minf(1.0, u)))


## The rails as solid panels (corner points: 4 at the bottom, then the same 4 at the top), for the code shape and
## the bumping: round the outside from the 45° corner to the landing, and along the landing's drop.
static func spiral_rail_parts(s: Vector3) -> Array:
	var parts := []
	var keys := [PI * 0.25, PI * 0.5, PI * 0.75, PI, PI * 1.25, PI * 1.5]
	for k in keys.size() - 1:
		var p0 := _sq(keys[k], SPIRAL_RAIL)
		var p1 := _sq(keys[k + 1], SPIRAL_RAIL)
		var y0 := spiral_slope_y(s, keys[k])
		var y1 := spiral_slope_y(s, keys[k + 1])
		parts.append(_panel(p0, p1, y0 - 0.15, y1 - 0.15, y0 + SPIRAL_RAIL_H, y1 + SPIRAL_RAIL_H))
	parts.append(_panel(Vector2(SPIRAL_POST - 0.02, 0.08), Vector2(1.9, 0.08), s.y, s.y, s.y + 0.85, s.y + 0.85))
	return parts


static func _panel(p0: Vector2, p1: Vector2, b0: float, b1: float, t0: float, t1: float) -> PackedVector3Array:
	var n := (p1 - p0).normalized().orthogonal() * 0.05
	var pts := PackedVector3Array()
	for y in [[b0, b1], [t0, t1]]:
		pts.append(Vector3(p0.x - n.x, y[0], p0.y - n.y))
		pts.append(Vector3(p1.x - n.x, y[1], p1.y - n.y))
		pts.append(Vector3(p1.x + n.x, y[1], p1.y + n.y))
		pts.append(Vector3(p0.x + n.x, y[0], p0.y + n.y))
	return pts


## Spiral stairs (F716): the post, the treads, the landing on its corner pillar, the floor-standing pillars at the
## outside corners and the rails. Open under the treads and the landing.
static func _spiral_steps(s: Vector3) -> void:
	_cyl(Vector3.ZERO, SPIRAL_POST, SPIRAL_POST, s.y + 0.95)
	for i in SPIRAL_STEPS:
		var top := s.y * 0.1 * (i + 1)
		_prism_y(spiral_tread(i), top - SPIRAL_TREAD, top)
	_box(Vector3(0.995, (SPIRAL_LANDING + s.y) * 0.5, 0.995), Vector3(1.99, s.y - SPIRAL_LANDING, 1.99))
	_box(Vector3(1.72, SPIRAL_LANDING * 0.5, 1.72), Vector3(0.24, SPIRAL_LANDING, 0.24))
	for a in [PI * 0.25, PI * 0.75, PI * 1.25]:
		var c := _sq(a, 1.73)
		var h := spiral_slope_y(s, a) + SPIRAL_RAIL_H + 0.08
		_box(Vector3(c.x, h * 0.5, c.y), Vector3(0.22, h, 0.22))
	for p: PackedVector3Array in spiral_rail_parts(s):
		_prism_sides([p[0], p[1], p[2], p[3]], [p[4], p[5], p[6], p[7]], Vector3.DOWN, Vector3.UP)


## The spiral stairs' treads as one smooth slanted slope (30° wedges, each from the one before up to its own
## top), so the dwarf walks up instead of hopping 20 cm steps. Each is a list of corner points for a
## ConvexPolygonShape3D, 10° each (a wider one bulges: its hull joins points round the turn into a steep wall).
## They start 0.6 m from the middle: closer in the slope is steeper than a dwarf can stand on (it acts as a
## wall), and no dwarf fits there anyway (the post is 0.32 m, the dwarf 0.36 m each side).
static func spiral_slope_parts(s: Vector3) -> Array:
	var parts := []
	var step := PI / 18.0
	for i in SPIRAL_STEPS * 3:
		var pts := PackedVector3Array()
		var angles := [step * i, step * (i + 1)]
		for c in [PI * 0.25, PI * 0.75, PI * 1.25]:
			if step * i < c and c < step * (i + 1):
				angles.append(c)
		for a: float in angles:
			var y := spiral_slope_y(s, a)
			for q in [_sq(a, SPIRAL_REACH), Vector2(cos(a), -sin(a)) * 0.6]:
				pts.append(Vector3(q.x, y, q.y))
				pts.append(Vector3(q.x, maxf(0.0, y - 0.15), q.y))
		parts.append(pts)
	return parts


## Where the floor hatch's hole is: centre z and radius (the models: Stonehold/Hearthbrick z 0.47, Shack z 0.40,
## both radius 0.42; this sits between them). A dwarf (0.72 m wide) drops through it.
const HATCH_Z := 0.435
const HATCH_R := 0.42


## Floor hatch: a 0.25 m floor with a round hole, built from strips; its round lid lies open behind the hole.
static func _floor_hatch(s: Vector3) -> void:
	var t := 0.25
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var z0 := HATCH_Z - HATCH_R
	var z1 := HATCH_Z + HATCH_R
	_box(Vector3(0, t * 0.5, (-hz + z0) * 0.5), Vector3(s.x, t, z0 + hz))  # behind the hole
	_box(Vector3(0, t * 0.5, (z1 + hz) * 0.5), Vector3(s.x, t, hz - z1))   # in front of it
	var strips := 14
	for i in strips:
		var za := z0 + (z1 - z0) * i / strips
		var zb := z0 + (z1 - z0) * (i + 1) / strips
		var d := 0.0 if (za <= HATCH_Z and HATCH_Z <= zb) else minf(absf(za - HATCH_Z), absf(zb - HATCH_Z))
		var half := sqrt(maxf(0.0, HATCH_R * HATCH_R - d * d))
		for sgn in [-1.0, 1.0]:
			_box(Vector3(sgn * (half + hx) * 0.5, t * 0.5, (za + zb) * 0.5), Vector3(hx - half, t, zb - za))
	if _detail:
		_cyl(Vector3(0, t, HATCH_Z - 2.0 * HATCH_R - 0.01), HATCH_R, HATCH_R, s.y - t)  # the lid, lying open


## Roof cap: a low pyramid over where four sloped roofs meet.
static func _roof_cap(s: Vector3) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var top := Vector3(0, s.y, 0)
	var b := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	_face(b, Vector3.DOWN)
	for i in 4:
		var p: Vector3 = b[i]
		var q: Vector3 = b[(i + 1) % 4]
		_face([p, q, top], (p + q) * 0.5 + Vector3.UP * 0.3)


## Stonehold's flat roof: a thick slab, with a slightly raised rim so rain (and eyes) see an edge.
static func _flat_roof(s: Vector3) -> void:
	_slab(Vector3(0, (s.y - 0.05) * 0.5, 0), Vector3(s.x, s.y - 0.05, s.z), "floor")
	_box(Vector3(0, s.y - 0.025, 0), Vector3(s.x - 0.08, 0.05, s.z - 0.08))


## A low wall with two raised blocks (merlons) on top, on a grid line like a wall.
static func _battlement(s: Vector3) -> void:
	var low := s.y - 0.4
	_slab(Vector3(0, low * 0.5, 0), Vector3(s.x, low, s.z), "wall")
	for x in [-0.5, 0.5]:
		_slab(Vector3(x, low + 0.2, 0), Vector3(0.6, 0.4, s.z), "wall_x")


## A square post that caps the corner where two battlements meet.
static func _battlement_corner(s: Vector3) -> void:
	_slab(Vector3(0, (s.y - 0.12) * 0.5, 0), Vector3(s.x, s.y - 0.12, s.z), "wall_x")
	_box(Vector3(0, s.y - 0.06, 0), Vector3(s.x, 0.12, s.z))  # a cap stone


## An equilateral triangle (building kit): every side 2 m, the middle at the origin, one edge
## facing +z. Foundations get a top lip like the square ones.
static func _tri(s: Vector3) -> void:
	var k := s.x * 0.5
	var r_in := Pieces.TRI_IN * k
	var r_out := Pieces.TRI_OUT * k
	var tri := [Vector2(-k, r_in), Vector2(k, r_in), Vector2(0, -r_out)]
	if s.y > 0.5:
		_prism_y(tri, 0.0, s.y - 0.1)
		var f := (r_in - 0.03) / r_in
		_prism_y([tri[0] * f, tri[1] * f, tri[2] * f], s.y - 0.1, s.y)  # a top lip
	else:
		_prism_y(tri, 0.0, s.y)


## A round-topped door (F57): planks up to where the curve starts, then a half circle.
## Half the width of a circle (radius r, centre cy) over the strip y0..y1, measured where it's
## narrowest, so the solid never pokes into the round opening. 0 = the strip misses the circle.
static func _circle_half(r: float, cy: float, y0: float, y1: float) -> float:
	var far := maxf(absf(y0 - cy), absf(y1 - cy))
	if minf(absf(y0 - cy), absf(y1 - cy)) >= r and signf(y0 - cy) == signf(y1 - cy):
		return 0.0
	return sqrt(maxf(0.0, r * r - far * far)) if far < r else 0.0


## A wall with a hobbit-style round hole (circle radius r around (0, cy), flat at the floor), built from
## thin strips: solid to the left and right of the circle in each strip, solid above it.
static func _circle_hole(s: Vector3, r: float, cy: float) -> void:
	var strip := 0.04
	var y := 0.0
	var top := minf(cy + r, s.y)
	_slab(Vector3(-(s.x * 0.5 + r) * 0.5, s.y * 0.5, 0), Vector3(s.x * 0.5 - r, s.y, s.z), "wall")
	_slab(Vector3((s.x * 0.5 + r) * 0.5, s.y * 0.5, 0), Vector3(s.x * 0.5 - r, s.y, s.z), "wall")
	if s.y - top > 0.005:
		_slab(Vector3(0, (top + s.y) * 0.5, 0), Vector3(r * 2.0, s.y - top, s.z), "wall")
	while y < top - 0.001:
		var y1 := minf(y + strip, top)
		var hw := _circle_half(r, cy, y, y1)
		if r - hw > 0.002:
			for side in [-1.0, 1.0]:  # each strip reaches 1.5 cm into the side wall and the strip above, so all touch
				_box(Vector3(side * (hw + r + 0.015) * 0.5, (y + y1 + 0.01) * 0.5, 0), Vector3(r + 0.015 - hw, y1 - y + 0.01, s.z))
		y = y1


## A round hobbit door: the same circle, flat at the bottom, built from thin strips.
static func _circle_door(s: Vector3, cy: float) -> void:
	var r := s.x * 0.5
	var strip := 0.04
	var y := 0.0
	while y < s.y - 0.001:
		var y1 := minf(y + strip, s.y)
		var mid := (y + y1) * 0.5
		var hw := sqrt(maxf(0.0, r * r - (mid - cy) * (mid - cy)))
		if hw > 0.01:
			_box(Vector3(0, mid, 0), Vector3(hw * 2.0, y1 - y, s.z))
		y = y1
	if _detail:
		_box(Vector3(r * 0.45, cy, s.z * 0.5 + 0.03), Vector3(0.08, 0.08, 0.06))  # a round knob in the middle


static func _door(s: Vector3) -> void:
	var r := s.x * 0.5
	var spring := s.y - r
	_slab(Vector3(0, spring * 0.5, 0), Vector3(s.x, spring, s.z), "door")
	var half := []
	for i in 10:
		var a := PI * i / 9.0
		half.append(Vector2(cos(a) * r, spring + sin(a) * r))
	_prism_z(half, -s.z * 0.5, s.z * 0.5)
	if _detail:
		for y in [0.35, spring - 0.1]:
			_box(Vector3(0, y, 0), Vector3(s.x - 0.04, 0.08, s.z + 0.03))  # iron bands
		_box(Vector3(s.x * 0.3, spring * 0.6, s.z * 0.5 + 0.03), Vector3(0.07, 0.07, 0.06))  # round knob


## A triangle: half of the square, the half on the −x/+z side of the line (−1,−1)→(1,1).
static func _triangle(s: Vector3) -> void:
	var hx := s.x * 0.5
	var hz := s.z * 0.5
	var tri := [Vector2(-hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	_prism_y(tri, 0.0, s.y)
	if _detail and s.y > 0.5:
		_prism_y([Vector2(-hx + 0.06, -hz + 0.2), Vector2(hx - 0.2, hz - 0.06), Vector2(-hx + 0.06, hz - 0.06)], s.y, s.y + 0.04)


## Diagonal pieces stand on the line (−1,−1)→(1,1) of their square, 2.83 m long.
static func _diagonal(piece: String, s: Vector3) -> void:
	var seg_len := Vector2(s.x, s.z).length()
	_push(Transform3D(Basis(Vector3.UP, -PI / 4.0), Vector3.ZERO))
	var info: Dictionary = Pieces.LIST[piece]
	if piece == "railing_diagonal":
		_railing(Vector3(seg_len, s.y, 0.15))
	elif info.has("opening"):
		_wall_with_hole(seg_len, s.y, 0.3, info.opening)
	else:
		_slab(Vector3(0, s.y * 0.5, 0), Vector3(seg_len, s.y, 0.3), "wall")
	_pop()


# ================================================================== surfaces with detail

## A box-shaped part dressed in the material's pattern. kind: wall (thin along z), wall_x (a thick
## block), floor (thin along y), beam / post (long thin), door.
static func _slab(c: Vector3, size: Vector3, kind: String) -> void:
	if not _detail or _style == "plain":
		_box(c, size)
		return
	match _style:
		"wood":
			_wood(c, size, kind)
		"stone":
			_blocks(c, size, kind, 0.5, 0.66)
		"brick":
			_blocks(c, size, kind, 0.25, 0.5)
		"metal":
			_plates(c, size, kind)
		_:
			_box(c, size)


## Planks: across the long side, with 1.5 cm gaps and every other plank a little proud.
static func _wood(c: Vector3, size: Vector3, kind: String) -> void:
	if kind in ["beam", "post"]:
		# Slightly thinner, but the full length, so a post still touches the beam it holds.
		var long := 0 if size.x >= size.y and size.x >= size.z else (1 if size.y >= size.z else 2)
		var shrink := Vector3.ONE * 0.01
		shrink[long] = 0.0
		_box(c, size - shrink)
		return
	var along := 1 if kind in ["wall", "door"] else 2  # walls: planks stacked up y; floors: across z
	var span: float = size[along]
	# A board behind the planks: the gaps between planks show it (no see-through slits), and the
	# planks are all held together (nothing floating).
	var back_thin := 2 if kind in ["wall", "door"] else 1
	var backing := size
	backing[back_thin] = maxf(size[back_thin] - 0.04, 0.01)
	_box(c, backing)
	var n := maxi(1, roundi(span / 0.25))
	var step := span / n
	for i in n:
		var pc := c
		pc[along] = c[along] - span * 0.5 + step * (i + 0.5)
		var ps := size
		ps[along] = step - 0.015
		var thin := 2 if kind in ["wall", "door"] else 1
		ps[thin] = size[thin] - (0.02 if i % 2 == 1 else 0.0)
		_box(pc, ps)


## Blocks in staggered rows over a slightly smaller backing (the gaps read as mortar).
static func _blocks(c: Vector3, size: Vector3, kind: String, row_h: float, block_l: float) -> void:
	var gap := 0.025
	var thin := 1 if kind == "floor" else 2
	var backing := size
	backing[thin] -= 0.04
	backing.x = maxf(backing.x - 0.02, 0.01)
	_box(c, backing)
	var u := 0  # the axis along the rows
	var v := 2 if kind == "floor" else 1  # the axis rows stack along
	if kind in ["post", "wall_x"] and size.x < size.z:
		u = 2
	var rows := maxi(1, roundi(size[v] / row_h))
	var rh: float = size[v] / rows
	for r in rows:
		var n := maxi(1, roundi(size[u] / block_l))
		var bl: float = size[u] / n
		var offset := bl * 0.5 if r % 2 == 1 else 0.0
		var x0: float = c[u] - size[u] * 0.5
		var cuts := [0.0]
		for k in n:
			var e := offset + bl * (k + 1)
			if e < size[u] - 0.05:
				cuts.append(e)
		cuts.append(size[u])
		for k in cuts.size() - 1:
			var a: float = cuts[k]
			var b: float = cuts[k + 1]
			if b - a < 0.06:
				continue
			var bc := c
			bc[u] = x0 + (a + b) * 0.5
			bc[v] = c[v] - size[v] * 0.5 + rh * (r + 0.5)
			var bs := size
			bs[u] = b - a - gap
			bs[v] = rh - gap
			_box(bc, bs)


## Metal: one plate per meter with a gap, and rivets near the corners on both faces.
static func _plates(c: Vector3, size: Vector3, kind: String) -> void:
	if kind in ["beam", "post"]:
		_box(c, size)
		for e in [-0.5, 0.5]:
			var rp := c
			var long := 0 if size.x >= size.y and size.x >= size.z else (1 if size.y >= size.z else 2)
			rp[long] += e * (size[long] - 0.2)
			_box(rp, Vector3(size.x + 0.03, size.y + 0.03, size.z + 0.03) * (Vector3.ONE - _axis(long) * 0.95))
		return
	var thin := 1 if kind == "floor" else 2
	_box(c, size)
	var u := 0
	var v := 2 if thin == 1 else 1
	var nu := maxi(1, roundi(size[u]))
	var nv := maxi(1, roundi(size[v]))
	for i in nu:
		for j in nv:
			for su in [-1.0, 1.0]:
				for sv in [-1.0, 1.0]:
					var rp := c
					rp[u] = c[u] - size[u] * 0.5 + (i + 0.5) * size[u] / nu + su * (size[u] / nu * 0.5 - 0.08)
					rp[v] = c[v] - size[v] * 0.5 + (j + 0.5) * size[v] / nv + sv * (size[v] / nv * 0.5 - 0.08)
					var rs := Vector3(0.05, 0.05, 0.05)
					rs[thin] = size[thin] + 0.03
					_box(rp, rs)


static func _axis(i: int) -> Vector3:
	return [Vector3.RIGHT, Vector3.UP, Vector3.BACK][i]


## Roof shingles: overlapping rows of thin boards lying on the slope.
static func _shingles(w: float, d: float, rise: float, t: float) -> void:
	if not _detail:
		return
	# The roof's top runs from height t at the front (z = +d/2) to `rise` at the back. The shingles
	# lie ON that slope (they used to float above it, so feet sank into them).
	var slope := atan2(rise - t, d)
	var seg_len := Vector2(d, rise - t).length()
	var rows := maxi(2, roundi(seg_len / 0.33))
	for r in rows:
		var f := (r + 0.5) / rows
		var p := Vector3(0, t + (rise - t) * f, d * 0.5 - d * f) + Basis(Vector3.RIGHT, slope) * Vector3(0, 0.025, 0)
		_push(Transform3D(Basis(Vector3.RIGHT, slope), p))
		_box(Vector3.ZERO, Vector3(w + 0.06, 0.05, seg_len / rows + 0.08))
		_pop()


# ================================================================== raw shapes

static var _stack: Array[Transform3D] = []


static func _push(t: Transform3D) -> void:
	_stack.append(_xf)
	_xf = _xf * t


static func _pop() -> void:
	_xf = _stack.pop_back()


static func _box(c: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var p := [
		c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z), c + Vector3(h.x, h.y, -h.z), c + Vector3(-h.x, h.y, -h.z),
		c + Vector3(-h.x, -h.y, h.z), c + Vector3(h.x, -h.y, h.z), c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z)]
	_face([p[0], p[1], p[2], p[3]], Vector3.FORWARD)
	_face([p[4], p[5], p[6], p[7]], Vector3.BACK)
	_face([p[0], p[4], p[7], p[3]], Vector3.LEFT)
	_face([p[1], p[5], p[6], p[2]], Vector3.RIGHT)
	_face([p[3], p[2], p[6], p[7]], Vector3.UP)
	_face([p[0], p[1], p[5], p[4]], Vector3.DOWN)


## A prism: a (z, y) outline pushed along x from x0 to x1.
static func _prism_x(outline: Array, x0: float, x1: float) -> void:
	var a := []
	var b := []
	for q in outline:
		a.append(Vector3(x0, q.y, q.x))
		b.append(Vector3(x1, q.y, q.x))
	_prism_sides(a, b, Vector3.LEFT, Vector3.RIGHT)


## A prism: an (x, y) outline pushed along z from z0 to z1.
static func _prism_z(outline: Array, z0: float, z1: float) -> void:
	var a := []
	var b := []
	for q in outline:
		a.append(Vector3(q.x, q.y, z0))
		b.append(Vector3(q.x, q.y, z1))
	_prism_sides(a, b, Vector3.FORWARD, Vector3.BACK)


## A prism: an (x, z) outline pushed up from y0 to y1.
static func _prism_y(outline: Array, y0: float, y1: float) -> void:
	var a := []
	var b := []
	for q in outline:
		a.append(Vector3(q.x, y0, q.y))
		b.append(Vector3(q.x, y1, q.y))
	_prism_sides(a, b, Vector3.DOWN, Vector3.UP)


static func _prism_sides(a: Array, b: Array, cap_a: Vector3, cap_b: Vector3) -> void:
	_face(a, cap_a)
	_face(b, cap_b)
	var mid := Vector3.ZERO
	for q in a + b:
		mid += q
	mid /= float(a.size() + b.size())
	for i in a.size():
		var j := (i + 1) % a.size()
		var quad := [a[i], a[j], b[j], b[i]]
		var fc: Vector3 = (a[i] + a[j] + b[i] + b[j]) * 0.25
		_face(quad, fc - mid)


## A tapered 8-sided cylinder standing on `base`.
static func _cyl(base: Vector3, r_bottom: float, r_top: float, h: float) -> void:
	var bot := []
	var top := []
	for i in 8:
		var a := TAU * (i + 0.5) / 8.0
		bot.append(base + Vector3(cos(a) * r_bottom, 0, sin(a) * r_bottom))
		top.append(base + Vector3(cos(a) * r_top, h, sin(a) * r_top))
	_prism_sides(bot, top, Vector3.DOWN, Vector3.UP)


## One flat face (convex outline). `outward` only says which way it faces; the corner order is fixed
## here so the face shows from that side (Godot draws clockwise triangles as the front).
static func _face(pts: Array, outward: Vector3) -> void:
	var w := []
	for q in pts:
		w.append(_xf * (q as Vector3))
	var out := (_xf.basis * outward).normalized()
	var n: Vector3 = ((w[1] - w[0]) as Vector3).cross(w[2] - w[0])
	if n.length() < 0.000001 and w.size() > 3:
		n = ((w[2] - w[0]) as Vector3).cross(w[3] - w[0])
	n = n.normalized()
	var flip := n.dot(out) > 0.0
	var normal := n if not flip else n
	if normal.dot(out) < 0.0:
		normal = -normal
	for i in range(1, w.size() - 1):
		var a: Vector3 = w[0]
		var b: Vector3 = w[i]
		var c: Vector3 = w[i + 1]
		var tri := [a, c, b] if flip else [a, b, c]
		for v in tri:
			_st.set_normal(normal)
			_st.set_uv(Vector2((v as Vector3).x + (v as Vector3).z, (v as Vector3).y))
			_st.add_vertex(v)

## The separate parts of a mesh after joining the ones that touch or nearly touch (1 cm).
## One part = everything holds together; more = something floats (owner's model notes F34-F62).
static func islands(mesh: Mesh) -> Array:
	var boxes: Array = []
	for si in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(si)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx := PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] != null:
			idx = arr[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			for i in verts.size():
				idx.append(i)
		# Triangles sharing a corner position belong together (union-find on positions to 1 mm).
		var parent := {}
		var keys := []
		keys.resize(verts.size())
		for i in verts.size():
			var v := verts[i]
			var k := Vector3i(roundi(v.x * 1000.0), roundi(v.y * 1000.0), roundi(v.z * 1000.0))
			keys[i] = k
			if not parent.has(k):
				parent[k] = k
		for i in range(0, idx.size() - 2, 3):
			var r0: Vector3i = _root(parent, keys[idx[i]])
			for j in [1, 2]:
				var r: Vector3i = _root(parent, keys[idx[i + j]])
				if r != r0:
					parent[r] = r0
		var part := {}
		for k in parent:
			var r: Vector3i = _root(parent, k)
			var p := Vector3(k) / 1000.0
			part[r] = (part[r] as AABB).expand(p) if part.has(r) else AABB(p, Vector3.ZERO)
		boxes.append_array(part.values())
	var merged := true
	while merged:
		merged = false
		for i in boxes.size():
			for j in range(i + 1, boxes.size()):
				if (boxes[i] as AABB).grow(0.01).intersects(boxes[j]):
					boxes[i] = (boxes[i] as AABB).merge(boxes[j])
					boxes.remove_at(j)
					merged = true
					break
			if merged:
				break
	return boxes


static func _root(parent: Dictionary, k: Vector3i) -> Vector3i:
	while parent[k] != k:
		parent[k] = parent[parent[k]]
		k = parent[k]
	return k
