class_name NanWatch
extends Node
## A lookout for "broken numbers" (Claude, Nov 19): the owner's log had ~1,300 "Vector3 cannot be normalized" warnings
## (something got a NaN / infinite place) and it couldn't be made to happen on purpose. A few hundred 3D things are
## checked each frame (so it never stutters); the first broken ones are written to the log with their name, so the
## next session's log says exactly what it was.

const PER_FRAME := 400
const MAX_REPORTS := 12

var _queue: Array[Node] = []
var _reported := {}


func _process(_delta: float) -> void:
	if _reported.size() >= MAX_REPORTS:
		return
	if _queue.is_empty():
		_queue.append(get_tree().root)  # (walks the whole tree a little each frame: no stutter)
	for i in PER_FRAME:
		if _queue.is_empty():
			return
		var n: Node = _queue.pop_back()
		if not is_instance_valid(n) or not n.is_inside_tree():
			continue
		_queue.append_array(n.get_children())
		if not n is Node3D or _reported.has(n.get_instance_id()):
			continue
		var g := (n as Node3D).global_transform
		if g.origin.is_finite() and g.basis.x.is_finite() and g.basis.y.is_finite() and g.basis.z.is_finite():
			continue
		_reported[n.get_instance_id()] = true
		var sc: Script = n.get_script()
		var p := n.get_parent()
		print("NAN_WATCH broken place on %s (%s, script %s, parent %s) doing: %s" % [n.get_path(), n.get_class(),
			sc.resource_path if sc else "-", p.get_script().resource_path if p and p.get_script() else (p.get_class() if p else "-"),
			FreezeWatch.doing])
