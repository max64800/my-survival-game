extends SceneTree
## Do rock chunks end up inside each other? Two bursts on one spot onto a floor, then counts pairs of chunks whose
## middles are closer than a third of their sizes added up (deep inside each other). (Claude, Nov 18, owner: "the rocks
## are sometimes in each other".)
##   godot --headless --audio-driver Dummy --path . --script res://tools/model_check/shatter_overlap.gd
var frames := 0


func _init() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var floor := StaticBody3D.new()
	floor.collision_layer = World.TERRAIN_LAYER
	var fs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(20, 0.2, 20)
	fs.shape = bx
	floor.add_child(fs)
	floor.position.y = -0.1
	w.add_child(floor)
	RockShatter.burst(w, Vector3(0, 0.4, 0), Vector3.UP, Color.GRAY, -1, 1.0)
	RockShatter.burst(w, Vector3(0, 0.6, 0), Vector3.UP, Color.GRAY, -1, 1.0)


func _physics_process(_d: float) -> bool:
	frames += 1
	if frames < 150:
		return false
	var cs: Array = root.find_children("*", "RockShatter", true, false)
	var deep := 0
	for i in cs.size():
		for j in range(i + 1, cs.size()):
			var a: RockShatter = cs[i]
			var b: RockShatter = cs[j]
			if a.global_position.distance_to(b.global_position) < (a._size + b._size) * 0.5 * 0.33:
				deep += 1
	print("SHATTER_OVERLAP chunks %d, deep overlaps %d" % [cs.size(), deep])
	return true
