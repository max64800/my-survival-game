extends SceneTree
## Hunts "broken numbers" (NaN / infinite places), Claude Nov 19: the owner's log had ~1,300 "Vector3 cannot be
## normalized" warnings. Starts a world (saving OFF), walks the dwarf through the given spots, and every half second
## checks every 3D thing for a place or turn that isn't a real number; prints the first ones it finds.
##   godot --audio-driver Dummy --path . --script res://tools/nan_hunt.gd -- seed=594196
var main: Node
const PATH := [Vector3(4, -20, 21), Vector3(0, -21, 13), Vector3(-6, -23, -1), Vector3(-33, -23, -8),
	Vector3(-20, -25, -20), Vector3(4, -27, -37), Vector3(-10, -23, -24), Vector3(-11, -23, -23)]


func _init() -> void:
	main = (load("res://src/main.tscn") as PackedScene).instantiate()
	main.set("_saving", false)
	root.add_child.call_deferred(main)
	_run.call_deferred()


func _run() -> void:
	var waited := 0
	while not main.call("is_ready_to_play") and waited < 240 * 60:
		await process_frame
		waited += 1
	var auth := GameAuthority.instance
	var dwarf: Node3D = auth.get_player(auth.local_peer_id()).node
	var found := {}
	for p in PATH:
		var spot: Vector3 = auth.world.maker.find_floor(p.x, p.z, p.y + 2.0) + Vector3.UP * 0.2
		dwarf.global_position = spot
		for k in 16:  # 8 s at each spot
			await create_timer(0.5).timeout
			for n in _all(root):
				if n is Node3D and n.is_inside_tree() and not found.has(n.get_instance_id()):
					var g := (n as Node3D).global_transform
					if not (g.origin.is_finite() and g.basis.x.is_finite() and g.basis.y.is_finite() and g.basis.z.is_finite()):
						found[n.get_instance_id()] = true
						print("NAN at walk spot %s: %s (%s, script %s)" % [p, n.get_path(), n.get_class(), n.get_script().resource_path if n.get_script() else "-"])
	print("NAN_HUNT_END found %d" % found.size())
	quit()


func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out
