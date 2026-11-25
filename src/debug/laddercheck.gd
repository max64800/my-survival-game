extends Node
## Robot (Nov 25, F845): climbs every built ladder near the start in a ruin test world, the way you do (hold forward,
## facing the ladder), and says whether the dwarf gets off at the top onto the floor above. Made for the Smeltery's
## 6-sided turrets (their ladders go up through a hole in each storey's floor). A picture at each ladder's top.
## Run: godot --audio-driver Dummy --path . -- ruintest=smeltery laddercheck claude=smeltery_ladders shots=<folder>
## (add ruinrebuilt to climb the whole rebuilt works' ladders: every piece put back first)

var _main: Node
var _shots := ""


func _ready() -> void:
	_main = get_parent()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("shots="):
			_shots = a.trim_prefix("shots=")
	if _shots != "":
		DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if _shots != "":
		print("LADDERCHECK shot ", _main.take_screenshot(_shots.path_join("ladder_%s.png" % name)))


## Which side of the ladder you stand on: toward the floors at its foot (the turret's inside).
func _stand_side(b: Builder, p: Vector3) -> Vector3:
	var sum := Vector3.ZERO
	for uid in b.structure.pieces:
		var q: Dictionary = b.structure.pieces[uid]
		if String(q.piece).begins_with("floor") or String(q.piece).begins_with("foundation"):
			var d: Vector3 = q.pos - p
			if absf(Pieces.box(q.piece, q.pos, q.rot).end.y - p.y) < 0.15 and Vector2(d.x, d.z).length() < 2.6:
				sum += Vector3(d.x, 0, d.z)
	return sum.normalized() if sum.length() > 0.01 else Vector3.FORWARD


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 180.0:
		await _wait(0.25)
		waited += 0.25
	var b: Builder = _main.authority.builder
	waited = 0.0
	while b.ladders.is_empty() and waited < 120.0:  # (the ruin builds once its rock is loaded)
		await _wait(0.5)
		waited += 0.5
	await _wait(2.0)
	var dwarf: Dwarf = _main.dwarf
	Controls.set_captured(true)
	var ok := 0
	var uids: Array = b.ladders.keys()
	uids.sort_custom(func(x, y): return b.structure.pieces[x].pos.y < b.structure.pieces[y].pos.y)
	print("LADDERCHECK %d ladders" % uids.size())
	for uid in uids:
		var p: Vector3 = b.structure.pieces[uid].pos
		var side := _stand_side(b, p)
		dwarf.global_position = p + side * 0.45 + Vector3.UP * 0.05
		dwarf.velocity = Vector3.ZERO
		dwarf._yaw = atan2(side.x, side.z)  # (facing the ladder: forward = -z turned by yaw, so face away from the floors)
		await _wait(0.4)
		Input.action_press("move_forward")
		dwarf.bot_move = Vector2(0, -1)
		var t := 0.0
		var top := p.y
		while t < 6.0:
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			top = maxf(top, dwarf.global_position.y)
			if dwarf.global_position.y > p.y + 2.1:  # at the top: let go and step back off it, onto the floor behind
				break
		Input.action_release("move_forward")
		dwarf.bot_move = Vector2(0, 1)
		await _wait(0.5)
		dwarf.bot_move = Vector2.ZERO
		await _wait(0.8)
		var y := dwarf.global_position.y
		var up := y > p.y + 2.1 and dwarf.is_on_floor()
		ok += 1 if up else 0
		print("LADDERCHECK ladder at %s: %s (feet %.2f, highest %.2f, ladder top floor %.2f)" % [p.snappedf(0.01),
			"CLIMBED UP" if up else "STUCK", y, top, p.y + 2.25])
		await _shot("%d_%s" % [uid, "up" if up else "stuck"])
	print("LADDERCHECK done: %d of %d ladders climbed" % [ok, uids.size()])
	get_tree().quit()
