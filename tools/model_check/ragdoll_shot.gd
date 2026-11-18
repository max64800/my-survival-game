extends SceneTree
## Pictures of a creature's death ragdoll falling onto a floor (Claude, Nov 18).
##   godot --audio-driver Dummy --path . --script res://tools/model_check/ragdoll_shot.gd -- rock_beetle <out_prefix>
var frames := 0
var shots := [6, 20, 45, 150, 300]  # (physics steps)
var prefix := ""
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var kind: String = a[0] if a.size() > 0 else "rock_beetle"
	prefix = a[1] if a.size() > 1 else "user://ragdoll"
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.45, 0.47)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	w.add_child(sun)
	var floor := StaticBody3D.new()
	floor.collision_layer = World.TERRAIN_LAYER
	var fs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(20, 0.2, 20)
	fs.shape = bx
	floor.add_child(fs)
	var fm := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(20, 0.2, 20)
	fm.mesh = pm
	floor.add_child(fm)
	floor.position.y = -0.1
	w.add_child(floor)
	var holder := Node3D.new()
	w.add_child(holder)
	var info := Monsters.info(kind)
	var model := MonsterModel.build(info.get("shape", kind), info.get("color", Color.WHITE), 0.9, false, kind, 5, "")  # (its own shape: the older creatures are built from it)
	holder.add_child(model)
	var cam := Camera3D.new()
	w.add_child(cam)
	await process_frame
	cam.look_at_from_position(Vector3(1.7, 1.4, 2.0) if not OS.get_cmdline_user_args().has("charge") else Vector3(2.4, 2.0, 3.4), Vector3(-0.3, 0.2, -0.3) if not OS.get_cmdline_user_args().has("charge") else Vector3(-1.5, 0.2, -1.5))
	if OS.get_cmdline_user_args().has("other"):  # (from the other side: e.g. the snail's face)
		cam.look_at_from_position(Vector3(-1.6, 1.2, -1.9), Vector3(0.0, 0.2, 0.0))
	var vel := Vector3(-5, 0, -5) if OS.get_cmdline_user_args().has("charge") else Vector3.ZERO  # (killed mid-charge: it flies on)
	holder.set_meta("data", Monsters.info(kind))  # (each creature's own ragdoll: the snail leaves its foot)
	var statue := 1 if OS.get_cmdline_user_args().has("statue") else -1  # (it turns to stone: Statue)
	if statue >= 0:
		shots = [6, 240, 420, 640]
	print("RAGDOLL_MADE ", Ragdoll.make(holder, model, Vector3(-2, 0, -2), vel, statue))


func _process(_d: float) -> bool:
	var f := Engine.get_physics_frames()
	if frames == 0:
		frames = f
	var k := f - frames
	for sh in shots:
		if k >= sh and not has_meta("s%d" % sh):
			set_meta("s%d" % sh, true)
			root.get_viewport().get_texture().get_image().save_png("%s_%d.png" % [prefix, sh])
	if k == shots.back():
		for c in root.find_children("Corpse", "RigidBody3D", true, false):
			var rb := c as RigidBody3D
			print("RAGDOLL_END up·sky %.2f  height %.2f" % [(rb.global_basis * (rb.get_meta("up_local") as Vector3)).normalized().dot(Vector3.UP), rb.global_position.y])
	return k > shots.back()
