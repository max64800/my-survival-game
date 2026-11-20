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
	UiKit.clear(_turn)
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


## A ruin as it stands (Builder.ruin_picture, owner F431): whole pieces as they are, broken ones glowing amber,
## missing ones as faint amber ghosts, so you see exactly what the chest will rebuild.
func show_ruin(pieces: Array[Dictionary]) -> void:
	UiKit.clear(_turn)
	if pieces.is_empty():
		return
	var low := INF
	var high := -INF
	var reach := 3.0
	for p in pieces:
		low = minf(low, p.pos.y)
		high = maxf(high, p.pos.y)
		reach = maxf(reach, Vector2(p.pos.x, p.pos.z).length())
	for p in pieces:
		var n: PieceNode = PieceNode.new()
		n.piece = p.piece
		n.family = p.family
		n.ghost = p.fix == "missing"
		n.position = p.pos - Vector3(0, (low + high) * 0.5, 0)
		n.rotation.y = Pieces.yaw_of(p.rot)
		_turn.add_child(n)
		if p.fix != "":
			_glow.call_deferred(n, p.fix == "missing")
	var size := Vector3(reach * 2.0, high - low + 3.0, reach * 2.0)
	_cam.fov = 40.0
	var back := maxf(size.length() * 0.62, 3.0)
	_cam.position = Vector3(0, back * 0.55, back * 1.25)
	_cam.look_at(Vector3.ZERO)


static var _broken_mat: StandardMaterial3D
static var _missing_mat: StandardMaterial3D


func _glow(n: Node, faint: bool) -> void:
	if _broken_mat == null:
		_broken_mat = StandardMaterial3D.new()  # laid over the piece's own paint, so you still see what it is
		_broken_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_broken_mat.albedo_color = Color(1.0, 0.55, 0.15, 0.45)
		_broken_mat.emission_enabled = true
		_broken_mat.emission = Color(1.0, 0.5, 0.1)
		_broken_mat.emission_energy_multiplier = 1.4
		_missing_mat = _broken_mat.duplicate()
		_missing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_missing_mat.albedo_color = Color(1.0, 0.6, 0.2, 0.35)
		_missing_mat.emission_energy_multiplier = 0.8
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if faint:
			(mi as MeshInstance3D).material_override = _missing_mat
		else:
			(mi as MeshInstance3D).material_overlay = _broken_mat


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_turn.rotation.y += TURN_SPEED * delta
