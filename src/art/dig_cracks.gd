class_name DigCracks
extends Decal
## Cracks spreading on the rock you're digging (owner, Nov 17, F261: "the rock cracks in stages, then crumbles"). Hit 1
## draws a few thin cracks from where the pick struck; each hit after that adds more and longer ones, wider, until the
## rock breaks. Drawn by the game itself (branching dark lines with a pale chipped rim): no picture files.
## Only a look, on your own screen.

const SIZE := 2.2  ## metres across (a little more than the scoop the dig removes)
const STAGES := 4  ## how many crack pictures (the last one = about to break)
const FADE_AFTER := 6.0  ## seconds without a hit before the cracks fade away

static var _textures: Array[ImageTexture] = []
static var _current: DigCracks

var _at := Vector3.INF
var _idle := 0.0


## A hit landed at `point` on rock facing `normal`: `hits` of `needed` done.
static func hit(parent: Node, point: Vector3, normal: Vector3, hits: int, needed: int) -> void:
	if _textures.is_empty():
		_make_textures()
	if _current == null or not is_instance_valid(_current):
		_current = DigCracks.new()
		parent.add_child(_current)
	if _current._at.distance_to(point) > 0.9:  # a different spot: start over
		_current._at = point
		_current.global_position = point
		var n := normal.normalized() if normal.length_squared() > 0.01 else Vector3.UP
		# A decal projects along its -Y: point that into the rock.
		var side := n.cross(Vector3.UP) if absf(n.y) < 0.95 else Vector3.RIGHT
		_current.global_basis = Basis(side.normalized(), n, side.normalized().cross(n)).orthonormalized()
		_current.rotate_object_local(Vector3.UP, randf() * TAU)
	var stage := clampi(int(floor(float(hits) / maxf(needed, 1) * STAGES)), 0, STAGES - 1)
	_current.texture_albedo = _textures[stage]
	_current.modulate = Color(1, 1, 1, 1)
	_current._idle = 0.0
	_current.visible = true


## Draw the crack pictures now (while the loading screen shows), not on the first rock hit (F337: ~40 ms hiccup).
static func warm_up() -> void:
	if _textures.is_empty():
		_make_textures()


## The rock broke (or the spot is gone): no more cracks.
static func clear() -> void:
	if _current and is_instance_valid(_current):
		_current.visible = false
		_current._at = Vector3.INF


func _init() -> void:
	size = Vector3(SIZE, 1.2, SIZE)  # (1.2 deep: reaches the rock on bumpy walls)
	upper_fade = 0.2
	lower_fade = 0.2
	normal_fade = 0.5  # not on surfaces turned away (the other side of a thin wall)
	cull_mask = 0xFFFFF & ~DwarfModel.VISUAL_LAYER  # never on the dwarf


func _process(delta: float) -> void:
	if not visible:
		return
	_idle += delta
	if _idle > FADE_AFTER:
		modulate.a = maxf(0.0, 1.0 - (_idle - FADE_AFTER))
		if modulate.a <= 0.0:
			clear()


## The crack pictures: the same branching cracks growing from the middle, each stage drawing more of them.
static func _make_textures() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	var px := 256
	var cracks: Array = []  # [[points], stage it appears at]
	var arms := 7
	for a in arms:
		var ang := TAU * a / arms + rng.randf_range(-0.3, 0.3)
		_grow(rng, cracks, Vector2(px / 2.0, px / 2.0) + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)), ang, 0, 0)
	for st in STAGES:
		var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for c in cracks:
			if c[1] > st:
				continue
			var pts: Array = c[0]
			var w: float = 2.4 - 0.5 * float(c[2]) + 0.5 * (st - c[1])  # older cracks get wider
			for i in pts.size() - 1:
				var taper := 1.0 - 0.75 * float(i) / pts.size()  # thick where it starts, a hairline at its tip
				_line(img, pts[i], pts[i + 1], maxf(w * taper, 0.8))
		_textures.append(ImageTexture.create_from_image(img))


## One crack: a wobbly line out from `from`; it may split. `stage` = the hit it first shows at, `depth` = how many
## splits from the middle (thinner further out).
static func _grow(rng: RandomNumberGenerator, cracks: Array, from: Vector2, ang: float, stage: int, depth: int) -> void:
	var pts: Array = [from]
	var p := from
	var steps := rng.randi_range(9, 15)
	for i in steps:
		ang += rng.randf_range(-0.6, 0.6)  # jagged, like rock really splits
		p += Vector2(cos(ang), sin(ang)) * rng.randf_range(3.5, 7.5)
		pts.append(p)
		if depth < 2 and i > 2 and rng.randf() < 0.14:
			_grow(rng, cracks, p, ang + rng.randf_range(0.5, 1.0) * (1 if rng.randf() < 0.5 else -1), mini(stage + 1, STAGES - 1), depth + 1)
	cracks.append([pts, stage if depth == 0 and rng.randf() < 0.6 else mini(stage + 1 + depth, STAGES - 1), depth])


## A thick dark line with a pale chipped rim beside it.
static func _line(img: Image, a: Vector2, b: Vector2, w: float) -> void:
	var n := int(a.distance_to(b)) + 1
	for i in n + 1:
		var c := a.lerp(b, float(i) / n)
		for dx in range(-int(w) - 1, int(w) + 2):
			for dy in range(-int(w) - 1, int(w) + 2):
				var q := Vector2i(int(c.x) + dx, int(c.y) + dy)
				if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height():
					continue
				var d := Vector2(dx, dy).length()
				if d <= w * 0.5:
					img.set_pixelv(q, Color(0.04, 0.035, 0.03, 0.9))  # the crack: dark
				elif d <= w * 0.5 + 1.0 and img.get_pixelv(q).a < 0.5:
					img.set_pixelv(q, Color(0.72, 0.68, 0.62, 0.22))  # a faint chipped edge
