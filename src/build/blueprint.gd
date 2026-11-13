class_name Blueprint
extends RefCounted
## A saved building (world doc section 7). Saved as JSON text so friends can share them.
##
## Loading one is a TRUST BOUNDARY: files come from friends and the internet. from_json()
## checks every field and refuses anything odd. Nothing in a file is ever run as code.

const FORMAT := 1
const MAX_SIZE := Vector3(32, 24, 32)
const MAX_PIECES := 2000

var name := "Blueprint"
var author := ""
var source := "player"  ## "player" or "ancient" (found in ruins)
var size := Vector3(8, 4, 8)  ## box in meters
var pieces: Array[Dictionary] = []  ## {id, mat, pos: Vector3 (relative to the box's bottom centre), rot}
var air := PackedByteArray()  ## 1 per 1 m cell: 1 = should be open air (the chest carves it)


# ---------------------------------------------------------------- making one

## Records every piece whose centre is inside the box from `lo` to `hi`, and which cells are open air.
static func capture(structure: Structure, sdf: Callable, lo: Vector3, hi: Vector3, p_name: String) -> Blueprint:
	var bp := Blueprint.new()
	var a := lo.min(hi).floor()
	var b := lo.max(hi).ceil()
	bp.size = (b - a).clamp(Vector3.ONE, MAX_SIZE)
	b = a + bp.size
	bp.name = p_name
	var origin := Vector3((a.x + b.x) * 0.5, a.y, (a.z + b.z) * 0.5)
	for uid in structure.pieces:
		var p: Dictionary = structure.pieces[uid]
		var centre := structure.box_of(uid).get_center()
		if AABB(a, bp.size).has_point(centre):
			bp.pieces.append({id = p.piece, mat = p.family, pos = (p.pos - origin).snapped(Vector3.ONE * 0.5), rot = p.rot})
	var sx := int(bp.size.x)
	var sy := int(bp.size.y)
	var sz := int(bp.size.z)
	bp.air.resize(sx * sy * sz)
	var i := 0
	for y in sy:
		for z in sz:
			for x in sx:
				bp.air[i] = 1 if sdf.call(a + Vector3(x + 0.5, y + 0.5, z + 0.5)) > 0.0 else 0
				i += 1
	return bp


func cost() -> Dictionary:
	var c := {}
	for p in pieces:
		var pc := Pieces.cost(p.id, p.mat)
		for item in pc:
			c[item] = c.get(item, 0) + pc[item]
	return c


# ---------------------------------------------------------------- placing one

## Where every piece goes when the box's bottom centre is at `origin`, turned `rot` quarter turns.
func world_pieces(origin: Vector3, rot: int) -> Array:
	var out := []
	var basis := Basis(Vector3.UP, rot * PI / 2.0)
	for p in pieces:
		out.append({piece = p.id, family = p.mat, pos = origin + basis * p.pos, rot = (p.rot + rot) % 4})
	return out


## World centres of the cells the Builder's Chest must carve (open air in the plan).
func carve_cells(origin: Vector3, rot: int) -> Array:
	var out := []
	var basis := Basis(Vector3.UP, rot * PI / 2.0)
	var sx := int(size.x)
	var sy := int(size.y)
	var sz := int(size.z)
	var i := 0
	for y in sy:
		for z in sz:
			for x in sx:
				if air[i] == 1:
					var local := Vector3(x + 0.5 - size.x * 0.5, y + 0.5, z + 0.5 - size.z * 0.5)
					out.append(origin + basis * local)
				i += 1
	return out


# ---------------------------------------------------------------- saving / loading

func to_json() -> String:
	var plist := []
	for p in pieces:
		plist.append({id = p.id, mat = p.mat, pos = [p.pos.x, p.pos.y, p.pos.z], rot = p.rot})
	var rle := _rle(air)
	var d := {format = FORMAT, name = name, author = author, source = source,
		created = Time.get_date_string_from_system(), size = [size.x, size.y, size.z],
		origin = "bottom_center", pieces = plist, air = {cell = 1, rle = rle}, cost = cost()}
	d.check = _checksum(plist, rle)
	return JSON.stringify(d, "  ")


## Returns {ok: bool, blueprint: Blueprint, error: String}.
static func from_json(text: String) -> Dictionary:
	if text.length() > 2_000_000:
		return _fail("File is too big.")
	var json := JSON.new()
	if json.parse(text) != OK:  # (the quiet way: bad files just get a message, no error log)
		return _fail("This isn't a blueprint file.")
	var d = json.data
	if not d is Dictionary:
		return _fail("This isn't a blueprint file.")
	if d.get("format") != float(FORMAT):
		return _fail("Unknown blueprint format.")
	var bp := Blueprint.new()
	bp.name = str(d.get("name", "Blueprint")).left(60)
	bp.author = str(d.get("author", "")).left(60)
	bp.source = "ancient" if d.get("source") == "ancient" else "player"
	var sz = d.get("size")
	if not (sz is Array and sz.size() == 3 and sz.all(func(v): return (v is float or v is int) and is_finite(v))):
		return _fail("Bad size.")
	bp.size = Vector3(sz[0], sz[1], sz[2])
	if bp.size.x < 1 or bp.size.y < 1 or bp.size.z < 1 or bp.size.x > MAX_SIZE.x or bp.size.y > MAX_SIZE.y or bp.size.z > MAX_SIZE.z \
			or bp.size != bp.size.floor():
		return _fail("Size must be whole meters, at most 32 × 24 × 32.")
	var plist = d.get("pieces")
	if not plist is Array or plist.size() > MAX_PIECES:
		return _fail("Bad piece list (max %d pieces)." % MAX_PIECES)
	var half := Vector3(bp.size.x * 0.5 + 1.0, bp.size.y + 1.0, bp.size.z * 0.5 + 1.0)
	for p in plist:
		if not p is Dictionary:
			return _fail("Bad piece.")
		var id = p.get("id")
		var mat = p.get("mat")
		var pos = p.get("pos")
		var rot = p.get("rot")
		if not (id is String and mat is String and Pieces.allowed(id, mat)):
			return _fail("Unknown piece or material: %s / %s" % [str(id).left(20), str(mat).left(20)])
		if not (pos is Array and pos.size() == 3 and pos.all(func(v): return (v is float or v is int) and is_finite(v))):
			return _fail("Bad piece position.")
		var v := Vector3(pos[0], pos[1], pos[2])
		if absf(v.x) > half.x or v.y < -1.0 or v.y > half.y or absf(v.z) > half.z:
			return _fail("A piece is outside the blueprint's box.")
		if not ((rot is float or rot is int) and int(rot) == rot and rot >= 0 and rot <= 3):
			return _fail("Bad piece rotation.")
		bp.pieces.append({id = id, mat = mat, pos = v, rot = int(rot)})
	var a = d.get("air")
	var rle = a.get("rle") if a is Dictionary else null
	if not rle is Array or not rle.all(func(v): return (v is float or v is int) and v >= 0 and int(v) == v):
		return _fail("Bad air mask.")
	var cells := int(bp.size.x * bp.size.y * bp.size.z)
	var total := 0
	for v in rle:
		total += int(v)
	if total != cells:
		return _fail("Air mask doesn't match the box size.")
	bp.air = _unrle(rle, cells)
	if d.get("check") != _checksum(plist, rle):
		return _fail("The file is damaged (checksum doesn't match).")
	return {ok = true, blueprint = bp, error = ""}


static func _fail(msg: String) -> Dictionary:
	return {ok = false, blueprint = null, error = msg}


## Run-lengths: alternating counts of 0s and 1s, starting with 0s.
static func _rle(bits: PackedByteArray) -> Array:
	var out := []
	var cur := 0
	var n := 0
	for b in bits:
		if b == cur:
			n += 1
		else:
			out.append(n)
			cur = b
			n = 1
	out.append(n)
	return out


static func _unrle(rle: Array, cells: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(cells)
	var i := 0
	var cur := 0
	for n in rle:
		for k in int(n):
			out[i] = cur
			i += 1
		cur = 1 - cur
	return out


static func _checksum(plist: Array, rle: Array) -> String:
	var parts := []
	for p in plist:
		parts.append("%s|%s|%.2f,%.2f,%.2f|%d" % [p.id, p.mat, float(p.pos[0]), float(p.pos[1]), float(p.pos[2]), int(p.rot)])
	parts.append(",".join(rle.map(func(v): return str(int(v)))))
	return "|".join(parts).md5_text().left(8)
