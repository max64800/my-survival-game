extends SceneTree
## Preview pictures for F389 round 5 (great axe / great maul, hand-made key poses: DwarfGreatSwing): the ready stance,
## then each swing at its key moments (wind-up, hit, follow-through), named plainly: stance_front.png, Chop_hit_front.png…
##   godot --audio-driver Dummy --fixed-fps 60 --path . --script res://tools/asset_forge/twohand_preview.gd -- claude=twohand_preview
##     item=axe_2h_copper out=<folder> [cam=front|side|back|three|left|top] [moves=Chop,Sweep,Slam] [len=1.1] [walk=0]
## Also prints, every few frames, the gap between the fists and how close the handle comes to his chest.
var out := "user://twohand"
var cam_name := "three"
var item := "axe_2h_copper"
var moves: PackedStringArray = ["Chop", "Sweep", "Slam"]
var clip_len := 1.1
var walk := 0.0
var model: DwarfModel
var cam: Camera3D
var frames := 0
var _move := -1  ## which of `moves` plays now
var markers := false
var balls: Array[MeshInstance3D] = []
var _move_frame := 0  ## the frame it started
var _worst := INF  ## the handle's least room during the swing playing now (m), and when (share of the swing)
var _worst_t := 0.0
const NAMES := {0.28: "windup", 0.25: "windup", 0.30: "windup", 0.40: "hit", 0.42: "hit", 0.58: "follow", 0.70: "follow", 1.0: "end"}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("out="): out = a.substr(4)
		if a.begins_with("cam="): cam_name = a.substr(4)
		if a.begins_with("item="): item = a.substr(5)
		if a.begins_with("moves="): moves = a.substr(6).split(",")
		if a.begins_with("walk="): walk = float(a.substr(5))
		if a.begins_with("len="): clip_len = float(a.substr(4))
		if a == "markers=1": markers = true
	DirAccess.make_dir_recursive_absolute(out)
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.13, 0.11)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.55, 0.55)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 25, 0)
	w.add_child(sun)
	model = DwarfModel.new()
	w.add_child(model)
	for c: Color in [Color(0.2, 0.5, 1.0), Color(1.0, 0.85, 0.1)]:  # markers=1: blue = the left fist's spot, yellow = the right's
		var ball := MeshInstance3D.new()
		ball.mesh = SphereMesh.new()
		(ball.mesh as SphereMesh).radius = 0.025
		(ball.mesh as SphereMesh).height = 0.05
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		mat.no_depth_test = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ball.material_override = mat
		ball.visible = markers
		w.add_child(ball)
		balls.append(ball)
	cam = Camera3D.new()
	cam.fov = 40
	w.add_child(cam)
	var at := Vector3(0, 0.75, 0)
	# the dwarf faces -Z: the front camera is at -Z, his right side is +X
	var spots := {"front": Vector3(0.0, 1.0, -3.0), "side": Vector3(3.0, 1.0, 0.0), "back": Vector3(0.4, 1.1, 3.0),
		"three": Vector3(1.9, 1.2, -2.2), "left": Vector3(-3.0, 1.0, 0.0), "top": Vector3(0.0, 3.6, -0.01)}
	cam.look_at_from_position(spots.get(cam_name, spots.three), at)
	await process_frame
	await process_frame
	model.set_held(item)


func _shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, name, cam_name])


func _process(_d: float) -> bool:
	frames += 1
	if model == null or model.dwarf_rig == null:
		return frames > 200
	var rig := model.dwarf_rig
	rig.set_motion(walk, true, false)
	rig.fist.measure_clearance = true
	if balls.size() == 2:
		balls[0].global_position = rig.fist.target_l
		balls[1].global_position = rig.fist.target_r
	if frames == 40:
		_shot("stance")
		_report("stance")
	var per := int(clip_len * 60.0) + 2
	if frames >= 45 and (frames - 45) % per == 0 and (frames - 45) / per < moves.size():
		if _move >= 0:
			print("%-14s least handle room %d cm at %d%%" % [moves[_move], roundi(_worst * 100), roundi(_worst_t * 100)])
		_move = (frames - 45) / per
		_move_frame = frames
		_worst = INF
		rig.play_upper("g/" + moves[_move], clip_len)
	if _move >= 0 and _move < moves.size():
		if frames > _move_frame + 1 and rig.fist.clearance < _worst:
			_worst = rig.fist.clearance
			_worst_t = float(frames - _move_frame) / (clip_len * 60.0)
		if frames == 45 + per * moves.size() + 4:
			print("%-14s least handle room %d cm at %d%%" % [moves[_move], roundi(_worst * 100), roundi(_worst_t * 100)])
		for key: Array in DwarfGreatSwing.MOVES[moves[_move]]:
			if frames == _move_frame + int(float(key[0]) * clip_len * 60.0) - (1 if float(key[0]) >= 1.0 else 0):
				var nm: String = NAMES.get(snappedf(key[0], 0.01), "at%d" % roundi(float(key[0]) * 100))
				_shot("%s_%s" % [moves[_move], nm])
				_report("%s %s" % [moves[_move], nm])
	return frames > 45 + per * moves.size() + 5


## The gap between the fists, how far each fist missed its spot, and the handle's room in front of his body.
func _report(what: String) -> void:
	var f := model.dwarf_rig.fist
	print("%-14s gap %2d cm  misses: left %2d cm, right %2d cm  handle room %2d cm (%s), braids %2d cm" % [what,
		roundi(f.left_gap * 100), roundi(f.left_miss * 100), roundi(f.right_miss * 100), roundi(f.clearance * 100),
		f.clear_part, roundi(f.clearance_hair * 100)])
