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
		"door": _door(s)
		"steps": _steps(s, 2)
		"triangle": _triangle(s)
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
			_slab(Vector3(-0.8, (s.y - 0.3) * 0.5, 0), Vector3(0.3, s.y - 0.3, 0.3), "post")
			_slab(Vector3(0.8, (s.y - 0.3) * 0.5, 0), Vector3(0.3, s.y - 0.3, 0.3), "post")
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
	_arc_stones(Vector3(0, s.y - 0.24 - 0.7, 0), 0.7, d, 7)


static func _arch_doorway(s: Vector3, opening: Vector3) -> void:
	var side := (s.x - opening.x) * 0.5
	var spring := opening.y - opening.x * 0.5  # where the round top starts
	_slab(Vector3(-(opening.x + side) * 0.5, s.y * 0.5, 0), Vector3(side, s.y, s.z), "wall")
	_slab(Vector3((opening.x + side) * 0.5, s.y * 0.5, 0), Vector3(side, s.y, s.z), "wall")
	var top := s.y - opening.y
	if top > 0.01:
		_slab(Vector3(0, s.y - top * 0.5, 0), Vector3(opening.x, top, s.z), "wall")
	# Fill the corners above the round top, then the curved stones.
	var r := opening.x * 0.5
	_box(Vector3(-r + 0.15, spring + r * 0.7, 0), Vector3(0.3, r * 0.6, s.z))
	_box(Vector3(r - 0.15, spring + r * 0.7, 0), Vector3(0.3, r * 0.6, s.z))
	_arc_stones(Vector3(0, spring, 0), r, s.z + (0.04 if _detail else 0.0), 7)


## Wedge stones along a half circle (centre `c`, radius `r`), each one turned to the curve.
static func _arc_stones(c: Vector3, r: float, depth: float, count: int) -> void:
	for i in count:
		var a := PI * (i + 0.5) / count
		var p := c + Vector3(-cos(a) * (r + 0.12), sin(a) * (r + 0.12), 0)
		_push(Transform3D(Basis(Vector3.BACK, a - PI * 0.5), p))
		_box(Vector3.ZERO, Vector3(PI * r / count - 0.02, 0.26, depth))
		_pop()


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
			_box(Vector3(-0.4 + i * 0.4, s.y * 0.5 + 0.05, 0.08), Vector3(0.04, s.y - 0.1, 0.04))
			_box(Vector3(-0.4 + i * 0.4, s.y + 0.05, 0.08), Vector3(0.08, 0.16, 0.02))


## A diagonal brace: a beam from the bottom-left to the top-right corner.
static func _brace(s: Vector3) -> void:
	var seg_len := Vector2(s.x, s.y).length()
	_push(Transform3D(Basis(Vector3.BACK, atan2(s.y, s.x)), Vector3(0, s.y * 0.5, 0)))
	_slab(Vector3.ZERO, Vector3(seg_len - 0.1, 0.22, s.z), "beam")
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


static func _door(s: Vector3) -> void:
	_slab(Vector3(0, s.y * 0.5, 0), s, "door")
	if _detail:
		for y in [0.35, s.y - 0.35]:
			_box(Vector3(0, y, 0), Vector3(s.x - 0.04, 0.08, s.z + 0.03))  # iron bands
		_box(Vector3(s.x * 0.35, s.y * 0.5, s.z * 0.5 + 0.03), Vector3(0.06, 0.12, 0.06))  # handle


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
		_box(c, size - Vector3.ONE * 0.01)
		return
	var along := 1 if kind in ["wall", "door"] else 2  # walls: planks stacked up y; floors: across z
	var span: float = size[along]
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
	var slope := atan2(rise, d)
	var seg_len := Vector2(d, rise).length()
	var rows := maxi(2, roundi(seg_len / 0.33))
	for r in rows:
		var f := (r + 0.5) / rows
		var p := Vector3(0, t + rise * f + 0.03, d * 0.5 - d * f)
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
