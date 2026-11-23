class_name ScreenEdgeFlash
extends ColorRect
## A glow along the screen edges (F695): a quick red flash the moment you lose health, and a look
## of its own while poisoned, burning or chilled (see F799 below).
## Owner, Nov 22 ("too much, it goes on the entire screen"): now only a thin, faint rim, and only for
## BIG hits (a tenth of your health or more). Small hits show on the health bar and the dwarf instead.

## F799 (owner, Nov 23): each ailment now has its own clear but soft look, still only at the edges:
## green creeping edges = poison, orange flicker = burning, frosty white edges = chilled/frozen.
## The looks grow in and fade away instead of popping, get a bit stronger with more stacks, and a hit's
## red rim is drawn on top of them (you see both).
## Owner, Nov 23 round 2: poison = pumping green veins like roots, frost = thick feathery frost from the
## corners, burning = calmer (3 styles to pick from, FIRE_STYLE), and F802: a low-health screen (dark red,
## thicker left and right, blood splats) that grows from half health down.
## Round 3: burning = lots of glowing embers and black ash rising from the bottom, mostly up the sides;
## frost = sharp fern-like needles like frost on a window, on all four edges; blood = smaller thrown-paint streaks.
## Round 4: frost stays closer to the edges but is packed thick in the corners, with many kinds of
## snowflakes; blood = lots of big and small splats bunched in the corners, some thrown in from outside
## the screen, and the round ones splat, fade and splat again.
## Round 5: frost = frozen-lake ice, solid in the corners with white cracks and milky crust, creeping to the
## middle (no more snowflakes); blood splats built in layers (lumpy pool, uneven spikes, flung drops, mist).
## Round 6: many more ice cracks, a jagged broken-ice front with cracks shooting out; long blood slashes
## across one or two random corners (new corners each time your health drops low again).

const HIT_COLOR := Color(0.85, 0.08, 0.05)
const HIT_FADE := 0.4  ## seconds a hit flash takes to fade back to nothing
const BIG_HIT_SHARE := 0.1  ## a hit must take this share of your max health to flash the edges
const HIT_MIN := 0.2  ## the faintest edge flash (a hit of exactly BIG_HIT_SHARE)
const HIT_MAX := 0.35  ## the strongest (a hit of 40% of your health or more)
const STATUS_MODES := {"poison": 1, "burn": 2, "chill": 3}  ## which look the shader draws
const FADE_IN := 0.6  ## seconds for a look to grow in
const FADE_OUT := 0.9  ## seconds for it to melt away again
const FROST_FADE_IN := 1.4  ## frost creeps in slower, like real frost growing
const LOW_START := 0.5  ## the low-health screen starts below this share of health (F802)...
const LOW_FULL := 0.1  ## ...and is at full strength here
const LOW_SPEED := 1.5  ## how fast it follows your health (per second), so it never jumps

var _hit_strength := 0.0
var _status_kind := ""  ## the ailment that should show now ("" = none)
var _status_level := 0.0  ## how bad it is, 0..1 (more stacks = stronger look)
var _shown_kind := ""  ## the look on screen right now (still fading out after the ailment ended)
var _fade := 0.0  ## 0 = gone, 1 = fully grown in
var _low_target := 0.0  ## how strong the low-health screen should be (0..1)
var _low := 0.0  ## how strong it is right now
var _blood_seed := 0.0  ## picks which corners get the long blood slashes
var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	color = Color(0, 0, 0, 0)
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://src/ui/screen_edge_flash.gdshader")
	material = _mat


## A hit just landed: big hits flash the edges red, a bit stronger for a bigger one, then fade (F695).
func flash_hit(amount: float, max_health: float = 100.0) -> void:
	var share := amount / maxf(max_health, 1.0)
	if share < BIG_HIT_SHARE:
		return
	var k := clampf((share - BIG_HIT_SHARE) / 0.3, 0.0, 1.0)
	_hit_strength = maxf(_hit_strength, lerpf(HIT_MIN, HIT_MAX, k))


## Which ailment (if any) shows at the edges: "" clears it. level 0..1 = how bad (F695, F799).
func set_status(kind: String, level: float = 1.0) -> void:
	_status_kind = kind if STATUS_MODES.has(kind) else ""
	if _status_kind != "":
		_status_level = clampf(level, 0.0, 1.0)


## Your health share (0..1) for the low-health screen (F802).
func set_health(share: float) -> void:
	_low_target = clampf((LOW_START - share) / (LOW_START - LOW_FULL), 0.0, 1.0)


func _process(delta: float) -> void:
	if _low <= 0.0 and _low_target > 0.0:
		_blood_seed = randf_range(0.0, 100.0)  # new corners each time you drop low again
	_low = move_toward(_low, _low_target, delta * LOW_SPEED)
	if _hit_strength > 0.0:
		_hit_strength = maxf(0.0, _hit_strength - delta * HIT_MAX / HIT_FADE)
	# A different ailment first melts the old look away, then grows its own in.
	if _status_kind != "" and _status_kind == _shown_kind:
		_fade = minf(1.0, _fade + delta / (FROST_FADE_IN if _shown_kind == "chill" else FADE_IN))
	elif _fade > 0.0:
		_fade = maxf(0.0, _fade - delta / FADE_OUT)
	else:
		_shown_kind = _status_kind
	_mat.set_shader_parameter("hit_color", HIT_COLOR)
	_mat.set_shader_parameter("hit_strength", _hit_strength)
	_mat.set_shader_parameter("status_mode", int(STATUS_MODES.get(_shown_kind, 0)))
	_mat.set_shader_parameter("status_fade", _fade)
	_mat.set_shader_parameter("status_level", _status_level)
	_mat.set_shader_parameter("low_health", _low)
	_mat.set_shader_parameter("blood_seed", _blood_seed)
