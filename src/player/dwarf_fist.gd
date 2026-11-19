class_name DwarfFist
extends SkeletonModifier3D
## The dwarf's fists (owner, Nov 19: "the handle runs past his hand and his fingers stay open; he isn't really gripping
## it"). Runs after every animation frame, after the dwarf shaping (DwarfProportions), and changes only the hands:
##  - Holding a tool or weapon with a handle: the right fingers close into a tight fist, the thumb folded over them
##    (owner's pick). With a shield on: the left fingers close round its strap.
##  - The wrist turns so the hole through the fist points along the handle, and the tool slides so the handle runs
##    through the middle of the fist with a small stub (STUB) poking out below the little finger.
##    The tool itself still points exactly where the old grip put it (DwarfRig.GRIPS, the running shoulder carry, the
##    spear's level thrust: DwarfRig.hold_turn), so every swing looks as before; only the hand follows the handle now.
## The animations themselves are untouched (owner: "keep the moves"). Purely a look: nothing here is shared in co-op.
## By the dwarf-animations Claude, chat 3, Nov 19, 2026.

## How far each finger joint closes: [joint 1, joint 2, joint 3] in degrees, about the bend axis the pack's own
## standing animation curls that joint about (made by hand, so the bend directions are right).
const CURL := {
	"index": [80.0, 85.0, 70.0], "middle": [80.0, 85.0, 70.0], "ring": [80.0, 85.0, 70.0], "pinky": [80.0, 85.0, 70.0],
	"thumb": [20.0, 30.0, 60.0],
}
## Tools held by a handle through the fist (the rest, like a stone or a mushroom, sit in the open hand as before).
const HANDLE_LOOKS := ["pickaxe", "axe", "axe_2h", "sword", "mace", "mace_2h", "hammer", "shovel", "spear"]
const STUB := 0.05        ## m of handle below the fist (owner's pick: "a small stub, about a thumb's width")
const FINGER_HALF := 0.012  ## half a finger's thickness (m): the fist's edge is this far past the outer knuckle
## The most the wrist turns to line the fist up with the handle (degrees). Most tools need 20-45; past this a wrist
## looks broken (the spear, held pointing along the forearm, needed 110-130), so the tool tilts the rest of the way.
const WRIST_MAX := 45.0

## Off = the old way, for the page's "Before" (tools/asset_forge/dwarf_anim_export.gd hands=1): fingers as the
## animation has them, the tool turned in the open hand about the wrist.
static var use_fist := true

var rig: DwarfRig
var _hands := {}   ## "_r"/"_l" -> hand bone index
var _joints := {}  ## "_r"/"_l" -> [[bone, rest rotation, bend axis (bone space), degrees], ...]
var _ring := {}    ## "_r"/"_l" -> bones whose joints ring the handle (index..pinky 01, 02, 03, tips)
var _knuckles := {}  ## "_r"/"_l" -> [index_01, pinky_01]
## Measured each frame from the closed fingers (world space), for the grip and for the test:
var fist_center := Vector3.ZERO  ## the middle of the hole through the right fist
var fist_axis := Vector3.UP      ## the hole's direction, from the little finger to the index finger
var fist_radius := 0.0           ## how far the finger joints sit from the middle (m)
var fist_half := 0.0             ## half the fist's width along the handle (m)
var holding := false             ## the right fist is closed round a handle this frame
var wrist_turn := 0.0            ## how far the wrist turned this frame to line the fist up (degrees)
## The held tool's handle, measured from its model (tool holder space): [the handle's middle line's offset from the
## holder's axis, where the handle ends along that axis]. Measured, not assumed (Nov 19, owner: "the axe still needs
## work"): the axe's handle sits 5.5 cm off the axis in its model (the stone axe 7 cm), and every handle ends at the
## holder, not 10 cm below it as the old note said.
var handle := [Vector3.ZERO, 0.0]
var _handles := {}  ## tool node id -> handle


func setup(sk: Skeleton3D, owner_rig: DwarfRig) -> void:
	rig = owner_rig
	var idle: Animation = rig.tree.get_animation(DwarfRig.ANIMS.idle) if rig.tree.has_animation(DwarfRig.ANIMS.idle) else null
	for side in ["_r", "_l"]:
		_hands[side] = sk.find_bone("hand" + side)
		var joints := []
		var ring := []
		for f: String in CURL:
			for j in 3:
				var b := sk.find_bone("%s_0%d%s" % [f, j + 1, side])
				if b < 0:
					continue
				var rest := sk.get_bone_rest(b).basis.get_rotation_quaternion()
				joints.append([b, rest, _bend_axis(sk, idle, b, rest), (CURL[f] as Array)[j]])
				if f != "thumb":
					ring.append(b)
			var tip := sk.find_bone("%s_04_leaf%s" % [f, side])
			if f != "thumb" and tip >= 0:
				ring.append(tip)
		_joints[side] = joints
		_ring[side] = ring
		_knuckles[side] = [sk.find_bone("index_01" + side), sk.find_bone("pinky_01" + side)]


## The axis a finger joint bends about (in its own space): from the pack's standing animation, which curls every finger.
static func _bend_axis(sk: Skeleton3D, idle: Animation, b: int, rest: Quaternion) -> Vector3:
	if idle:
		var name := ":" + sk.get_bone_name(b)
		for t in idle.get_track_count():
			if idle.track_get_type(t) == Animation.TYPE_ROTATION_3D and str(idle.track_get_path(t)).ends_with(name):
				var d := rest.inverse() * idle.rotation_track_interpolate(t, 0.0)
				if d.get_angle() > 0.05:
					return d.get_axis().normalized()
	return Vector3.RIGHT


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or rig == null or not is_instance_valid(rig.grip):
		return
	var has_tool := rig.grip.get_child_count() > 0
	if not use_fist:
		holding = false
		_old_hold(sk)
		return
	holding = has_tool and rig.tool_look in HANDLE_LOOKS
	if holding:
		_close("_r", sk)
	if rig.shield_grip.get_child_count() > 0:
		_close("_l", sk)
	if has_tool:
		_hold(sk)


## Closes one hand's fingers into a fist.
func _close(side: String, sk: Skeleton3D) -> void:
	for j: Array in _joints[side]:
		sk.set_bone_pose_rotation(j[0], (j[1] as Quaternion) * Quaternion(j[2], deg_to_rad(j[3])))


## Turns the wrist so the fist's hole lies along the handle, then puts the tool in it.
func _hold(sk: Skeleton3D) -> void:
	var hand: int = _hands["_r"]
	var sk_world := sk.global_transform
	var socket: Node3D = rig.right_hand
	var hand_world := sk_world * sk.get_bone_global_pose(hand)
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()  # (things held keep their own size)
	# Where the old grip put the tool (the look the owner approved), plus the carry and the spear's aim.
	var want := hand_world * socket.transform * rig.grip_local
	want.basis = want.basis.orthonormalized()
	var extra := rig.hold_turn(want.basis)
	want.basis = Basis(extra) * want.basis
	var before := sk.get_bone_global_pose(hand).basis.get_rotation_quaternion()
	var inv := sk_world.basis.inverse()  # (directions in skeleton space: the dwarf is a bit wider than tall)
	var ax := Vector3.FORWARD if rig.tool_look == "spear" else Vector3.UP  # (the spear points along its holder's -Z)
	var handle_dir := want.basis * ax
	# The wrist's turn (skeleton space). The dwarf's stretched arm bones can't hold every turn exactly (a turned bone
	# under a squashed parent loses a little), so the fist's hole is lined up again until it lies along the handle.
	for i in 8:
		var turn: Quaternion
		if holding:
			_measure(sk)
			if fist_axis.angle_to(handle_dir) < deg_to_rad(0.5):
				break
			turn = Quaternion((inv * fist_axis).normalized(), (inv * handle_dir).normalized())
		else:  # (an open hand holding a stone or a mushroom: the wrist makes the carry's turn, once)
			if i > 0:
				break
			var q := sk_world.basis.get_rotation_quaternion()
			turn = q.inverse() * extra * q
		if turn.is_equal_approx(Quaternion.IDENTITY):
			break
		var g := sk.get_bone_global_pose(hand)
		g.basis = Basis(turn) * g.basis
		sk.set_bone_global_pose(hand, g)
	var g := sk.get_bone_global_pose(hand)
	var made := g.basis.get_rotation_quaternion() * before.inverse()
	if made.w < 0.0:
		made = -made  # (the short way round)
	wrist_turn = rad_to_deg(made.get_angle())
	var most := lerpf(WRIST_MAX, 180.0, rig._spear_aim)  # (the thrust: the spear points straight ahead, whatever it takes)
	if wrist_turn > most:
		g.basis = Basis(Quaternion.IDENTITY.slerp(made, most / wrist_turn) * made.inverse()) * g.basis
		sk.set_bone_global_pose(hand, g)
		wrist_turn = most
	hand_world = sk_world * sk.get_bone_global_pose(hand)
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()
	var at := (hand_world * socket.transform * rig.grip_local).origin
	if holding:
		_measure(sk)
		# what the wrist couldn't do, the tool does: it tilts into the fist
		want.basis = Basis(Quaternion(handle_dir.normalized(), fist_axis)) * want.basis
		handle = _handle_of(rig.grip.get_child(rig.grip.get_child_count() - 1), ax)
		var off: Vector3 = handle[0]
		if rig.tool_look == "spear":  # (the spear is held a third of the way up its shaft: ToolModels)
			at = fist_center - want.basis * off
		else:  # the handle's end a small stub past the little finger
			at = fist_center - fist_axis * (fist_half + STUB) - want.basis * (off + ax * float(handle[1]))
	rig.grip.transform = (hand_world * socket.transform).affine_inverse() * Transform3D(want.basis, at)


## Measures a tool's handle from its model (cached per tool): its middle line (the points 3-12 cm from its end) and
## its end, along the holder's axis `ax`.
func _handle_of(tool: Node, ax: Vector3) -> Array:
	var id := tool.get_instance_id()
	if _handles.has(id):
		return _handles[id]
	var pts: Array[Vector3] = []
	for mi: MeshInstance3D in tool.find_children("*", "MeshInstance3D", true, false):
		var x := Transform3D()  # (the mesh's place in the tool, from the nodes in between)
		var n: Node = mi
		while n != tool and n is Node3D:
			x = (n as Node3D).transform * x
			n = n.get_parent()
		x = (tool as Node3D).transform * x
		if mi.mesh:
			for sf in mi.mesh.get_surface_count():
				for v: Vector3 in mi.mesh.surface_get_arrays(sf)[Mesh.ARRAY_VERTEX]:
					pts.append(x * v)
	var found := [Vector3.ZERO, 0.0]
	if not pts.is_empty():
		var lo := INF
		var hi := -INF
		for p in pts:
			lo = minf(lo, p.dot(ax))
			hi = maxf(hi, p.dot(ax))
		var from := lo if ax == Vector3.UP else (lo + hi) / 2.0 - 0.1  # (the spear: round its middle, where he holds it)
		var mid := Vector3.ZERO
		var k := 0
		for p in pts:
			var along := p.dot(ax)
			if along > from + 0.03 and along < from + 0.12:
				mid += p - ax * along
				k += 1
		found = [mid / maxf(k, 1), lo]
	_handles[id] = found
	return found


## The way it was before the fists (for the page's "Before"): the carry and the spear's aim turned the tool holder
## about the wrist, and the fingers stayed as the animation had them.
func _old_hold(sk: Skeleton3D) -> void:
	var socket: Node3D = rig.right_hand
	var hand_world := sk.global_transform * sk.get_bone_global_pose(_hands["_r"])
	socket.scale = Vector3.ONE / hand_world.basis.get_scale()
	var s_world := hand_world * socket.transform
	var was := s_world * rig.grip_local
	was.basis = was.basis.orthonormalized()
	var turn := Basis(rig.hold_turn(was.basis))
	var now := Transform3D(turn * was.basis, s_world.origin + turn * (was.origin - s_world.origin))
	rig.grip.transform = s_world.affine_inverse() * now


## Measures the hole through the right fist (world space): the finger joints ring the handle.
func _measure(sk: Skeleton3D) -> void:
	var sk_world := sk.global_transform
	var pts: Array[Vector3] = []
	for b: int in _ring["_r"]:
		pts.append(sk_world * sk.get_bone_global_pose(b).origin)
	var kn: Array = _knuckles["_r"]
	var index := sk_world * sk.get_bone_global_pose(kn[0]).origin
	var pinky := sk_world * sk.get_bone_global_pose(kn[1]).origin
	fist_axis = (index - pinky).normalized()
	fist_half = (index - pinky).length() / 2.0 + FINGER_HALF
	# A circle through the ring of joints, seen along the axis (least squares).
	var u := fist_axis.cross(Vector3.UP if absf(fist_axis.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := fist_axis.cross(u)
	var mid := (index + pinky) / 2.0
	var sxx := 0.0; var sxy := 0.0; var syy := 0.0; var sx := 0.0; var sy := 0.0
	var sxz := 0.0; var syz := 0.0; var sz := 0.0
	var n := float(pts.size())
	for p in pts:
		var x := (p - mid).dot(u)
		var y := (p - mid).dot(v)
		var z := x * x + y * y
		sxx += x * x; sxy += x * y; syy += y * y; sx += x; sy += y
		sxz += x * z; syz += y * z; sz += z
	# x^2 + y^2 + a x + b y + c = 0
	var m := Basis(Vector3(sxx, sxy, sx), Vector3(sxy, syy, sy), Vector3(sx, sy, n))  # (columns; symmetric)
	if absf(m.determinant()) < 1e-12:
		fist_center = mid
		return
	var abc := m.inverse() * Vector3(-sxz, -syz, -sz)
	var cx := -abc.x / 2.0
	var cy := -abc.y / 2.0
	fist_center = mid + u * cx + v * cy
	fist_radius = sqrt(maxf(cx * cx + cy * cy - abc.z, 0.0))
