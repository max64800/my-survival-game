class_name BlueprintPreview
extends SubViewportContainer
## A small turning 3D picture of a blueprint for the blueprint book (owner F99: "the list has no
## pictures"; F187 mock-up: the picked building shown big). It builds the real pieces in its own
## little world (nothing touches the game world) and slowly turns them.

const TURN_SPEED := 0.35  ## radians per second

var _view: SubViewport
var _turn: Node3D
var _cam: Camera3D


func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(300, 220)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.transparent_bg = true
	_view.msaa_3d = Viewport.MSAA_4X
	_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_view)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.65, 0.55)
	env.environment.ambient_light_energy = 0.6
	_view.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_color = Color(1.0, 0.85, 0.65)
	sun.light_energy = 1.2
	_view.add_child(sun)
	_turn = Node3D.new()
	_view.add_child(_turn)
	_cam = Camera3D.new()
	_view.add_child(_cam)


## Shows this blueprint (null = empty).
func show_blueprint(bp: Blueprint) -> void:
	for c in _turn.get_children():
		c.queue_free()
	if bp == null:
		return
	for p in bp.world_pieces(Vector3(0, -bp.size.y * 0.5, 0), 0):
		var n: PieceNode = PieceNode.new()
		n.piece = p.piece
		n.family = p.family
		n.position = p.pos
		n.rotation.y = Pieces.yaw_of(p.rot)
		_turn.add_child(n)
	# Frame it: far enough back that the whole box fits, looking a little down.
	var reach := maxf(bp.size.length() * 0.62, 3.0)
	_cam.fov = 40.0
	_cam.position = Vector3(0, reach * 0.55, reach * 1.25)
	_cam.look_at(Vector3.ZERO)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_turn.rotation.y += TURN_SPEED * delta
