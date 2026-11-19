class_name StationLinks
extends MeshInstance3D
## Station helper lines (owner, Nov 20): while you hold a station, a helper (chopping block, bellows...) or the build
## hammer, glowing lines show which helper counts for which station (up to Station.EXTRA_RANGE away).
## Gold = already counts. Green = where the helper or station you're about to place would connect.
## Only a look on your own screen.

const SHOW_NEAR := 25.0  ## draw links around you this far
const WIDTH := 0.05
var dwarf: Dwarf
var ghost: PlaceGhost
var _mesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()


func _ready() -> void:
	mesh = _mesh
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.no_depth_test = true  # seen through the stations themselves
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(_delta: float) -> void:
	_mesh.clear_surfaces()
	var auth := GameAuthority.instance
	var ps: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id()) if auth and dwarf else null
	var held := ps.selected_item() if ps else ""
	var cam := get_viewport().get_camera_3d()
	if ps == null or cam == null or not (held == "build_hammer" or Station.helps_kind(held) != "" or Station.EXTRAS.has(held)):
		return
	var pairs := links(auth.stations.values(), dwarf.global_position)
	var green := []
	if ghost and ghost.visible:
		green = ghost_links(held, ghost.global_position, auth.stations.values())
	if pairs.is_empty() and green.is_empty():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in pairs:
		_ribbon(p[0], p[1], cam, Color(1.0, 0.78, 0.3, 0.85))
	for p in green:
		_ribbon(p[0], p[1], cam, Color(0.4, 1.0, 0.45, 0.9))
	_mesh.surface_end()


## Every helper -> station pair standing within reach of each other, near `around`. [[from, to], ...]
static func links(stations: Array, around: Vector3) -> Array:
	var out := []
	for h in stations:
		var main_kind := Station.helps_kind(h.kind)
		if main_kind == "" or h.global_position.distance_to(around) > SHOW_NEAR:
			continue
		for s in stations:
			if Station.station_type(s.kind) == main_kind and s.global_position.distance_to(h.global_position) <= Station.EXTRA_RANGE:
				out.append([s.global_position, h.global_position])
	return out


## Lines for the thing in your hand at `at`: a helper links to its stations, a station to its helpers.
static func ghost_links(held: String, at: Vector3, stations: Array) -> Array:
	var out := []
	for s in stations:
		if s.global_position.distance_to(at) > Station.EXTRA_RANGE:
			continue
		if Station.station_type(s.kind) == Station.helps_kind(held) or (Station.EXTRAS.has(held) and s.kind in Station.EXTRAS[held]):
			out.append([at, s.global_position])
	return out


## A flat band from a to b (0.7 m up), turned to face the camera so it reads as a clear line.
func _ribbon(a: Vector3, b: Vector3, cam: Camera3D, c: Color) -> void:
	a += Vector3.UP * 0.7
	b += Vector3.UP * 0.7
	var side := (b - a).cross(cam.global_position - (a + b) * 0.5).normalized() * WIDTH
	if not side.is_finite():
		return
	for v in [a - side, a + side, b + side, a - side, b + side, b - side]:
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(v)
