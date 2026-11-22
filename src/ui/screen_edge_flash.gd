class_name ScreenEdgeFlash
extends ColorRect
## A glow along the screen edges (F695): a quick red flash the moment you lose health, and a steady
## tinted glow while poisoned (green), burning (orange) or chilled (blue). The hit flash wins over the
## status glow so a hit always stands out, even while you're already poisoned or on fire.

const HIT_COLOR := Color(0.85, 0.08, 0.05)
const HIT_FADE := 1.4  ## seconds a hit flash takes to fade back to nothing
const STATUS_COLORS := {
	"burn": Color(1.0, 0.45, 0.05),
	"poison": Color(0.25, 0.85, 0.25),
	"chill": Color(0.35, 0.65, 1.0),
}
const STATUS_STRENGTH := 0.35

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


## A hit just landed: the edges flash red, stronger for a bigger hit, then fade (F695).
func flash_hit(amount: float) -> void:
	_hit_strength = maxf(_hit_strength, clampf(0.35 + amount * 0.02, 0.35, 1.0))


## Which ailment (if any) tints the edges while it's active: "" clears it (F695).
func set_status(kind: String) -> void:
	_status_kind = kind


func _process(delta: float) -> void:
	if _hit_strength > 0.0:
		_hit_strength = maxf(0.0, _hit_strength - delta / HIT_FADE)
		_mat.set_shader_parameter("edge_color", HIT_COLOR)
		_mat.set_shader_parameter("strength", _hit_strength)
	elif _status_kind != "":
		_mat.set_shader_parameter("edge_color", STATUS_COLORS.get(_status_kind, Color.WHITE))
		_mat.set_shader_parameter("strength", STATUS_STRENGTH)
	else:
		_mat.set_shader_parameter("strength", 0.0)
