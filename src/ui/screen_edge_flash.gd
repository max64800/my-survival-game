class_name ScreenEdgeFlash
extends ColorRect
## A glow along the screen edges (F695): a quick red flash the moment you lose health, and a steady
## tinted glow while poisoned (green), burning (orange) or chilled (blue). The hit flash wins over the
## status glow so a hit always stands out, even while you're already poisoned or on fire.
## Owner, Nov 22 ("too much, it goes on the entire screen"): now only a thin, faint rim, and only for
## BIG hits (a tenth of your health or more). Small hits show on the health bar and the dwarf instead.

const HIT_COLOR := Color(0.85, 0.08, 0.05)
const HIT_FADE := 0.4  ## seconds a hit flash takes to fade back to nothing
const BIG_HIT_SHARE := 0.1  ## a hit must take this share of your max health to flash the edges
const HIT_MIN := 0.2  ## the faintest edge flash (a hit of exactly BIG_HIT_SHARE)
const HIT_MAX := 0.35  ## the strongest (a hit of 40% of your health or more)
const STATUS_COLORS := {
	"burn": Color(1.0, 0.45, 0.05),
	"poison": Color(0.25, 0.85, 0.25),
	"chill": Color(0.35, 0.65, 1.0),
}
const STATUS_STRENGTH := 0.15

var _hit_strength := 0.0
var _status_kind := ""
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


## Which ailment (if any) tints the edges while it's active: "" clears it (F695).
func set_status(kind: String) -> void:
	_status_kind = kind


func _process(delta: float) -> void:
	if _hit_strength > 0.0:
		_hit_strength = maxf(0.0, _hit_strength - delta * HIT_MAX / HIT_FADE)
		_mat.set_shader_parameter("edge_color", HIT_COLOR)
		_mat.set_shader_parameter("strength", _hit_strength)
	elif _status_kind != "":
		_mat.set_shader_parameter("edge_color", STATUS_COLORS.get(_status_kind, Color.WHITE))
		_mat.set_shader_parameter("strength", STATUS_STRENGTH)
	else:
		_mat.set_shader_parameter("strength", 0.0)
