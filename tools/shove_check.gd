extends SceneTree
## How far a beetle's charge throws the dwarf (owner, Nov 17/19, F234: "much too far, a couple of metres at most").
##   godot --audio-driver Dummy --headless --path . --script res://tools/shove_check.gd
func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	Controls.setup()
	var root := Node3D.new()
	self.root.add_child(root)
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	cs.shape = box
	body.add_child(cs)
	body.position = Vector3(0, -0.5, 0)
	root.add_child(body)
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	auth.add_player(1, dwarf)
	for i in 30:
		await physics_frame
	for kd in [false, true]:
		dwarf.global_position = Vector3(0, 0.05, 0)
		dwarf.velocity = Vector3.ZERO
		for i in 10:
			await physics_frame
		var p0 := dwarf.global_position
		if kd:
			dwarf.knock_down()
		dwarf.shove(Vector3(7.0, 0, 3.0))
		for i in 120:
			await physics_frame
		var d := dwarf.global_position - p0
		print("SHOVE knocked_down=%s: thrown %.2f m" % [kd, Vector2(d.x, d.z).length()])
	quit()
