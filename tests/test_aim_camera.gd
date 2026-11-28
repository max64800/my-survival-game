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


## How close the crosshair line (in front of the camera) comes to the dwarf's middle line, feet to helmet top.
func _ray_clearance(dwarf: Dwarf) -> float:
	var cam := dwarf.camera.global_transform
	var fwd := -cam.basis.z.normalized()
	var best := INF
	for k in 29:
		var p := dwarf.global_position + Vector3.UP * (k * 0.05)
		var t := maxf(0.0, (p - cam.origin).dot(fwd))
		best = minf(best, (cam.origin + fwd * t).distance_to(p))
	return best


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
	ps.inventory.add_worn("crossbow_copper")
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
	# F927 (owner, Nov 27): aiming while looking up showed the back of the dwarf. The crosshair line must pass clear
	# of his body (feet to helmet top), with the camera not pressed against him.
	for pitch in [0.5, 0.8, 1.1]:
		dwarf._pitch = pitch
		for i in 60:
			await tree.physics_frame
		var clear := _ray_clearance(dwarf)
		check(clear > 0.45, "looking up %.1f while aiming: the crosshair passes %.2f m clear of him" % [pitch, clear])
	dwarf._pitch = -0.25
	for i in 60:
		await tree.physics_frame
	Input.action_release("use")
	for i in 90:
		await tree.physics_frame
	var after := _crosshair_at_dwarf(dwarf)
	check(absf(after.x - before.x) < 0.05, "letting go brings the old camera back (%.2f vs %.2f)" % [after.x, before.x])
	Controls.set_captured(false)
	Controls.robot = was_robot
	root.queue_free()


## How close the camera itself sits to the dwarf's middle line, feet to helmet top (minus his ~0.3 m body radius).
func _camera_gap(dwarf: Dwarf) -> float:
	var c := dwarf.camera.global_position
	var best := INF
	for k in 29:
		best = minf(best, c.distance_to(dwarf.global_position + Vector3.UP * (k * 0.05)))
	return best


## F946 (owner, Nov 28): looking straight up without aiming (picking vines overhead), the camera went inside the
## dwarf ("you see the inside of his belly"). On a flat floor, at any zoom and looking up, it stays outside him.
func test_looking_up_never_puts_the_camera_inside_him() -> void:
	Controls.setup()
	var root := _room()
	var auth := GameAuthority.new()
	auth.drops_root = root
	root.add_child(auth)
	var dwarf := Dwarf.new()
	root.add_child(dwarf)
	dwarf.global_position = Vector3(0, 0.05, 0)
	auth.add_player(1, dwarf)
	var was_robot := Controls.robot
	Controls.robot = true
	for zoom in [Dwarf.ZOOM_MIN, Dwarf.CAMERA_DISTANCE, 5.0]:
		dwarf._zoom = zoom
		for pitch in [0.6, 0.9, 1.1]:
			dwarf._pitch = pitch
			for i in 60:
				await tree.physics_frame
			var gap := _camera_gap(dwarf)
			check(gap > Dwarf.CAM_HIDE_GAP or not dwarf.model.visible,
				"zoom %.1f, looking up %.1f: the camera is %.2f m from his middle (or he's hidden)" % [zoom, pitch, gap])
	# The safety net: a camera pressed right against him (a tight tunnel) hides him, and he's back once it's out.
	dwarf.camera.global_position = dwarf.global_position + Vector3(0.2, 0.7, 0.1)
	dwarf._hide_if_camera_inside()
	check(not dwarf.model.visible, "the camera inside him hides him on this screen")
	dwarf.camera.global_position = dwarf.global_position + Vector3(0, 1.0, 2.0)
	dwarf._hide_if_camera_inside()
	check(dwarf.model.visible, "out again, he shows again")
	Controls.robot = was_robot
	root.queue_free()
