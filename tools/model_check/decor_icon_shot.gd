extends SceneTree
## Build menu pictures for Home pieces that have no preview to cut one from (owner, Nov 22: "Home doesn't have any
## pictures"). Each piece's model is photographed from the front-left, a bit from above, on a see-through
## background, and saved as assets/icons/build/<piece>__<material>.png (96 px, like make_piece_icons.py).
## Only pieces with no picture yet are made (add "all" to redo every Home piece).
##   godot --audio-driver Dummy --path . --resolution 256x256 --script res://tools/model_check/decor_icon_shot.gd

const OUT := "res://assets/icons/build/"
const GROUPS := ["furnish", "decor", "living", "kitchen", "trophies", "lights"]

var todo := []  ## [piece id, model path, families]
var holder: Node3D
var cam: Camera3D
var step := 0
var made := 0


func _init() -> void:
	var redo := "all" in OS.get_cmdline_user_args()
	for id in Pieces.LIST:
		var p: Dictionary = Pieces.LIST[id]
		if not p.get("group", "") in GROUPS or not p.has("model"):
			continue
		var fams := []
		for f in Pieces.FAMILIES:
			if Pieces.allowed(id, f):
				fams.append(f)
		var missing := fams.filter(func(f): return redo or not ResourceLoader.exists(OUT + "%s__%s.png" % [id, f]))
		if not missing.is_empty():
			todo.append([id, "res://assets/models/%s.glb" % p.model, missing])
	root.transparent_bg = true
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.5, 0.45)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.2
	w.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_energy = 0.4
	w.add_child(fill)
	holder = Node3D.new()
	w.add_child(holder)
	cam = Camera3D.new()
	cam.fov = 30
	w.add_child(cam)
	print("decor_icon_shot: %d pieces to photograph" % todo.size())


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var box := AABB()
	var first := true
	var t := xf * (n as Node3D).transform if n is Node3D else xf
	if n is VisualInstance3D:
		var b := t * (n as VisualInstance3D).get_aabb()
		box = b
		first = false
	for c in n.get_children():
		var cb := _aabb(c, t)
		if cb.size != Vector3.ZERO:
			box = cb if first else box.merge(cb)
			first = false
	return box


func _process(_d: float) -> bool:
	# Every piece: frame 0 load + aim, frame 3 photograph (lets the textures settle).
	var i := step / 4
	if i >= todo.size():
		print("decor_icon_shot: made %d pictures" % made)
		return true
	var phase := step % 4
	step += 1
	if phase == 0:
		for c in holder.get_children():
			holder.remove_child(c)
			c.free()
		var scene := load(todo[i][1]) as PackedScene if ResourceLoader.exists(todo[i][1]) else null
		if scene == null:
			print("decor_icon_shot: no model for %s (%s)" % [todo[i][0], todo[i][1]])
			step += 3
			return false
		holder.add_child(scene.instantiate())
		var box := _aabb(holder, Transform3D.IDENTITY)
		var mid := box.get_center()
		var r := maxf(box.size.length() * 0.5, 0.1)
		var dir := Vector3(-0.75, 0.55, 1.0).normalized()  # front-left, a bit from above (like the other pictures)
		cam.look_at_from_position(mid + dir * r / sin(deg_to_rad(cam.fov * 0.5)) * 1.02, mid)
	elif phase == 3:
		var img := root.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var used := img.get_used_rect()
		if used.size.x > 0:
			img = img.get_region(used)
		var side := maxi(img.get_width(), img.get_height())
		var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
		sq.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((side - img.get_width()) / 2, (side - img.get_height()) / 2))
		sq.resize(96, 96, Image.INTERPOLATE_LANCZOS)
		for f in todo[i][2]:
			sq.save_png(ProjectSettings.globalize_path(OUT + "%s__%s.png" % [todo[i][0], f]))
			made += 1
	return false
