extends TestCase
## F452 (owner, Nov 20): "when I aim, I'm looking at his head, not to the right shoulder a little bit".
## Aiming the crossbow puts the camera over his right shoulder whatever the zoom; letting go brings the zoom back.


func _room() -> Node3D:
	var root := Node3D.new()
	tree.root.add_child(root)
	var body := StaticBody3D.new()
	body.collision_layer = World.TERRAIN_LAYER
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0, -0.5, 0)
	root.add_child(body)
	return root


## Where the crosshair line passes the dwarf: [metres to his right, height above his feet].
func _crosshair_at_dwarf(dwarf: Dwarf) -> Vector2:
	var cam := dwarf.camera.global_transform
	var fwd := -cam.basis.z
	var to_dwarf := dwarf.global_position - cam.origin
	var depth := to_dwarf.dot(fwd)
	var p := cam.origin + fwd * depth  # the crosshair's point level with the dwarf
	var off := p - dwarf.global_position
	return Vector2(off.dot(cam.basis.x.normalized()), off.y)


func test_aiming_looks_past_the_right_shoulder() -> void:
	Controls.setup()
	var root := _room()
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	var ps := auth.add_player(1, dwarf)
	ps.inventory.add("crossbow_copper", 1)
	for i in Inventory.HOTBAR_SIZE:
		if ps.inventory.get_slot(i).get("id", "") == "crossbow_copper":
			auth.request_select_slot(1, i)
	var was_robot := Controls.robot
	Controls.robot = true
	Controls.set_captured(true)
	dwarf._zoom = Dwarf.ZOOM_MIN  # zoomed right in: the case the owner saw
	for i in 60:
		await tree.physics_frame
	var before := _crosshair_at_dwarf(dwarf)
	Input.action_press("use")
	for i in 60:
		await tree.physics_frame
	check(dwarf.fight.aiming(), "aiming the crossbow")
	var aimed := _crosshair_at_dwarf(dwarf)
	check(aimed.x > 0.3 and aimed.x < 0.8, "the crosshair passes just right of his right shoulder (%.2f m right; before %.2f)" % [aimed.x, before.x])
	check(aimed.y > 0.75 and aimed.y < 1.1, "at shoulder height (the dwarf is about 1.2 m tall) (%.2f m up)" % aimed.y)
	Input.action_release("use")
	for i in 90:
		await tree.physics_frame
	var after := _crosshair_at_dwarf(dwarf)
	check(absf(after.x - before.x) < 0.05, "letting go brings the old camera back (%.2f vs %.2f)" % [after.x, before.x])
	Controls.set_captured(false)
	Controls.robot = was_robot
	root.queue_free()
