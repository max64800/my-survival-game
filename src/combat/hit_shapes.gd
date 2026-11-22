class_name HitShapes
extends Node3D
## Shape hitboxes (owner, Nov 22: "the boss's spin hits me even when the pick points away").
##
## Every dwarf and creature carries one of these. It holds two kinds of invisible shapes:
## - HURT shapes (green in F9): bubbles round the body that can be hurt: head, body, arms, legs.
## - HIT shapes (red in F9 while swinging, grey otherwise): the part that does the hurting: the weapon's head or blade,
##   a beetle's mandibles, a bat's whole body, the snail's spit bubble.
## A hit will count only when a HIT shape touches a HURT shape. Step 1 (this file): the shapes exist, follow the
## bones every frame and show in F9 and the preview pictures (tools/hitbox_preview.gd). The fights still use the old
## distance check until the owner OKs the shapes (docs: journal Nov 22, "hitbox design").
##
## The shapes are Area3D nodes placed in the world (top level), moved every frame from the bones, so the dwarf's
## squashed proportions and the creatures' odd model scales never stretch them.

const HURT_LAYER := 1 << 11  ## bodies that can be hurt
const HIT_LAYER := 1 << 12   ## the hurting parts
const GROUP := "hit_shapes"

## Humanoid bones: the dwarf and the shades use the first name, the skeleton creatures (Pit Boss, Prop Warden,
## Hollow Miner, Bone Rot) the second.
const BONES := {
	hips = ["pelvis", "hips"], chest = ["spine_03", "chest"], neck = ["neck_01", "chest"], head = ["Head", "head"],
	uarm_l = ["upperarm_l", "upperarm.l"], larm_l = ["lowerarm_l", "lowerarm.l"], hand_l = ["hand_l", "hand.l"],
	uarm_r = ["upperarm_r", "upperarm.r"], larm_r = ["lowerarm_r", "lowerarm.r"], hand_r = ["hand_r", "hand.r"],
	thigh_l = ["thigh_l", "upperleg.l"], calf_l = ["calf_l", "lowerleg.l"], foot_l = ["foot_l", "foot.l"],
	thigh_r = ["thigh_r", "upperleg.r"], calf_r = ["calf_r", "lowerleg.r"], foot_r = ["foot_r", "foot.r"],
}
## Body bubbles: [name, from bone, to bone, start, end, radius]. A capsule from (from + (to-from)*start) to
## (from + (to-from)*end); start == end is a ball. Radius is a share of the body's size (hips to head).
const HUMANOID_HURT := [
	["head", "neck", "head", 1.55, 1.55, 0.30],
	["body", "hips", "chest", -0.15, 1.15, 0.40],
	["arm_l", "uarm_l", "larm_l", 0.1, 1.0, 0.13],
	["arm_r", "uarm_r", "larm_r", 0.1, 1.0, 0.13],
	["thigh_l", "thigh_l", "calf_l", 0.0, 1.0, 0.17],
	["thigh_r", "thigh_r", "calf_r", 0.0, 1.0, 0.17],
	["shin_l", "calf_l", "foot_l", 0.0, 1.0, 0.13],
	["shin_r", "calf_r", "foot_r", 0.0, 1.0, 0.13],
]
## How chunky each body is (the radii above are for a dwarf).
const STOUT := {dwarf = 1.0, shade = 0.85, skeleton = 0.7}
## The dwarf's own skeleton (dwarves and Shades) is squashed short and round: its big head and belly stick out far past
## the bones, so these bubbles are made fatter, and the head bubble sits higher (into the hair). Seen in the
## preview pictures, Nov 22. [share of radius, head end]
const DWARF_FAT := {head = 1.75, body = 1.85, arm_l = 1.2, arm_r = 1.2, thigh_l = 1.15, thigh_r = 1.15}
const DWARF_HEAD_UP := 2.1

## Dwarf weapons: which part of the held model hurts, from the hand (0) to the far end (1), plus how much bigger
## than the model the box is (m, each side). The width and depth are measured from the model itself.
const WEAPON := {
	sword = {from = 0.22, pad = 0.04},     # the blade
	axe = {from = 0.62, pad = 0.04},       # the head
	mace = {from = 0.60, pad = 0.04},      # the head
	spear = {from = 0.55, pad = 0.05},     # the front half
	axe_2h = {from = 0.60, pad = 0.05},
	mace_2h = {from = 0.60, pad = 0.05},
	pickaxe = {from = 0.62, pad = 0.04},   # the head with both points
	shield = {from = 0.0, pad = 0.03},     # the whole shield (a bash)
	fists = {ball = 0.13},                 # a ball round the fist
}
const SLAM_RADIUS := 2.5  ## the two-handed mace's heavy ground slam: a flat round zone at the feet
const SPIT_RADIUS := 0.28  ## the snail's spit bubble

## Which hit shape each creature attack uses (anything not listed swings its weapon: "weapon").
const ATTACK_PART := {
	"Mandible Snap": "bite", "Horn Gore": "bite", "Charge": "charge",
	"Lunging Bite": "bite", "Spit": "spit",
	"Dive Through": "body", "Bite": "bite", "Pounce": "pounce", "Shield Charge": "charge",
}

enum { SEG, BOX, CYL }


class Part:
	var name: String
	var hurt: bool
	var area: Area3D
	var shape: CollisionShape3D
	var kind := SEG
	var sk: Skeleton3D
	var a := -1
	var b := -1
	var ta := 0.0
	var tb := 1.0
	var r := 0.1
	var share := 0.0         ## SEG on a body: radius as a share of the finished hips→head size (0 = `r` as it is)
	var pa := Vector3.ZERO   ## SEG: the two bone points, read once the skeleton is finished (see _on_bones)
	var pb := Vector3.ZERO
	var read := false
	var node: Node3D         ## BOX / CYL: the shape rides on this node
	var local := Transform3D.IDENTITY  ## where the shape sits in that node's (unscaled) frame
	var s0 := Vector3.ONE    ## the node's size when the box was measured (the box grows and shrinks with it)
	var base := Vector3.ZERO ## the box's size then
	var active_until := -1.0
	var active_from := 0.0


var parts: Array[Part] = []
var who := ""      ## what this is, for the preview's labels ("dwarf", "foreman", …)
var _clock := 0.0


func _ready() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	for p in parts:
		if is_instance_valid(p.area):
			p.area.queue_free()


func _process(delta: float) -> void:
	_clock += delta


func _physics_process(_d: float) -> void:
	sync()


# ---------------------------------------------------------------- building

## The dwarf (or a shade: the dwarf's skeleton under a ghost body).
static func for_dwarf(dm: DwarfModel, stout := "dwarf") -> HitShapes:
	var hs := HitShapes.new()
	hs.name = "HitShapes"
	hs.who = stout
	dm.add_child(hs)
	if dm.dwarf_rig != null:
		hs.add_humanoid(dm.dwarf_rig.skeleton, STOUT[stout], 0)
	return hs


## A creature from MonsterModel.build (a skeleton creature or one moved in parts).
static func for_monster(model: Node3D, kind: String, data: Dictionary) -> HitShapes:
	var hs := HitShapes.new()
	hs.name = "HitShapes"
	hs.who = kind
	model.add_child(hs)
	hs._build_monster.call_deferred(model, kind, data)
	return hs


func _build_monster(model: Node3D, kind: String, data: Dictionary) -> void:
	if model.has_meta("ghost_model"):
		var dm := model.find_child("Ghost", false, false) as DwarfModel
		if dm and dm.dwarf_rig:
			add_humanoid(dm.dwarf_rig.skeleton, STOUT.shade, 1)
			weapon_box(dm.dwarf_rig.grip, "mace", "weapon")
		return
	var forged: Node3D = model.get_meta("forged_root", null)
	var sks := (forged if forged else model).find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		var sk := sks[0] as Skeleton3D
		add_humanoid(sk, STOUT.skeleton, 1)
		if not creature_tool_box(sk, "handslot.r", "weapon"):
			ball_on_bone(sk, _bone(sk, "hand_r", 1), 0.13 * _unit(sk, 1), "weapon")
		if data.get("front_shield", false):
			creature_tool_box(sk, "handslot.l", "charge")  # the Prop Warden's Shield Charge: his shield
		return
	var root: Node3D = forged if forged else model
	var front := -model.global_basis.z.normalized()  # monsters face -Z
	match String(data.get("shape", kind)):
		"rock_beetle":
			var body := _named(root, "body")
			hurt_box(body, [body], 0.02)
			var jaws := [_named(root, "mandible_l"), _named(root, "mandible_r")]
			mesh_box(body, jaws, 0.06, "bite", false)
			# The charge (owner, Nov 22): the mandibles made as wide as the beetle with its legs, so a leg brushing
			# you still counts. From the mandible tips back to the middle of the body.
			charge_box(body, root, jaws, front)
		"rock_snail":
			var body := _named(root, "body")
			hurt_box(body, [body, _named(root, "soft_body"), _named(root, "soft_foot")], 0.02)
			var head := [_named(root, "peek"), _named(root, "soft_stalk_l"), _named(root, "soft_stalk_r")]
			mesh_box(body, head, 0.08, "bite", false)
			spit_ball(body, head, front)
		"cave_bat":
			var body := _named(root, "body")
			hurt_box(body, [body], 0.03)
			mesh_box(body, [root], 0.03, "body", false)  # it flies through you: the whole bat, wings too
		_:
			# Built from simple shapes (the spider): the body can be hurt, the front third bites, a pounce is all of it.
			hurt_box(root, [root], 0.0)
			front_box(root, front, 0.35, "bite")
			mesh_box(root, [root], 0.04, "pounce", false)


## Head, body, arms and legs as bubbles on the bones.
func add_humanoid(sk: Skeleton3D, stout: float, alias: int) -> void:
	var u := _unit(sk, alias)
	var dwarfish := sk.find_bone("pelvis") >= 0
	for row in HUMANOID_HURT:
		var a := _bone(sk, row[1], alias)
		var b := _bone(sk, row[2], alias)
		if a < 0 or b < 0:
			continue
		var p := _new_part(row[0], true)
		p.sk = sk
		p.a = a
		p.b = b
		p.ta = row[3]
		p.tb = row[4]
		p.share = float(row[5]) * (1.0 if row[0] == "head" else stout)  # (a slim skeleton's skull is still a skull)
		if dwarfish:
			p.share *= float(DWARF_FAT.get(row[0], 1.0))
			if row[0] == "head":
				p.ta = DWARF_HEAD_UP
				p.tb = DWARF_HEAD_UP
		p.r = p.share * u
		p.shape.shape = SphereShape3D.new() if is_equal_approx(p.ta, p.tb) else CapsuleShape3D.new()
	_follow(sk)
	if who == "dwarf":
		var hand := _bone(sk, "hand_r", alias)
		ball_on_bone(sk, hand, WEAPON.fists.ball, "fists")
		_slam_zone()


## The held weapon's hurting part as a box riding on the grip (rebuilt whenever the dwarf changes weapons).
func weapon_box(grip: Node3D, weapon: String, name_: String = "weapon") -> Part:
	remove(name_)
	var w: Dictionary = WEAPON.get(weapon, WEAPON.sword)
	if w.has("ball") or grip == null:
		return null
	# The box rides on the weapon's own mesh, not on the hand: the hand lines the weapon up a moment after it
	# is picked up (dwarf_fist), and a box measured on the hand before that stayed where the spear used to be
	# (owner, Nov 22: "spear a bit off").
	var meshes := grip.find_children("*", "MeshInstance3D", true, false)
	var on: Node3D = null
	var most := -1
	for mi: MeshInstance3D in meshes:
		if mi.mesh != null and mi.is_visible_in_tree() and mi.mesh.get_surface_count() > 0:
			var n: int = mi.mesh.surface_get_array_len(0)
			if n > most:
				most = n
				on = mi
	if on == null:
		return null
	var pts := _mesh_points(meshes, on)
	if pts.is_empty():
		return null
	return _box_along(on, pts, float(w.from), float(w.pad), name_, _frame(on).affine_inverse() * grip.global_position)


## A creature's tool (pick, shovel, plank, axe, shield) from its skinned "tool…" meshes in a hand slot.
func creature_tool_box(sk: Skeleton3D, slot: String, name_: String) -> bool:
	var hb := sk.find_bone(slot)
	if hb < 0:
		return false
	var holder := BoneAttachment3D.new()
	holder.bone_name = slot
	sk.add_child(holder)
	var pts: PackedVector3Array = []
	var shieldy := name_ == "charge"
	for mi: MeshInstance3D in sk.get_parent().find_children("*", "MeshInstance3D", true, false):
		var nm := String(mi.name).to_lower()
		if mi.mesh == null or mi.skin == null:
			continue
		var is_shield := nm.contains("shield") or nm.contains("plank")
		if (shieldy and not is_shield) or (not shieldy and (is_shield or not nm.begins_with("tool"))):
			continue  # (the Warden's axe and his plank shield are two different things)
		var bind := Transform3D.IDENTITY
		var found := false
		for i in mi.skin.get_bind_count():
			if mi.skin.get_bind_name(i) == StringName(slot) or mi.skin.get_bind_bone(i) == hb:
				bind = mi.skin.get_bind_pose(i)
				found = true
		if not found:
			continue
		for si in mi.mesh.get_surface_count():
			for v: Vector3 in mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				pts.append(bind * v)  # into the hand socket's own space (the box rides on that socket)
	if pts.is_empty():
		holder.queue_free()
		return false
	var from := 0.0 if shieldy else 0.55  # a shield is all of it; a tool's far part hurts
	_box_along(holder, pts, from, 0.05, name_)
	return true


func ball_on_bone(sk: Skeleton3D, bone: int, radius: float, name_: String) -> void:
	if bone < 0:
		return
	var p := _new_part(name_, false)
	p.sk = sk
	p.a = bone
	p.b = bone
	p.ta = 0.0
	p.tb = 0.0
	p.r = radius
	p.shape.shape = SphereShape3D.new()
	_follow(sk)


## Bones are read only when the skeleton is finished. The dwarf's short, stout shape (DwarfProportions) and his
## weight are SkeletonModifier3Ds: they run last, and a bone read at any other time is the tall, human-sized one
## nobody sees (owner, Nov 22: "the hitboxes are way too up").
func _follow(sk: Skeleton3D) -> void:
	if not sk.skeleton_updated.is_connected(_on_bones):
		sk.skeleton_updated.connect(_on_bones.bind(sk))


func _on_bones(sk: Skeleton3D) -> void:
	var g := sk.global_transform
	var u := -1.0
	for p in parts:
		if p.kind != SEG or p.sk != sk:
			continue
		p.pa = g * sk.get_bone_global_pose(p.a).origin
		p.pb = g * sk.get_bone_global_pose(p.b).origin
		p.read = true
		if p.share > 0.0:
			if u < 0.0:
				u = _unit_now(sk)
			p.r = p.share * u


## Hips to head in the finished pose (the size the player sees).
func _unit_now(sk: Skeleton3D) -> float:
	var alias := 0 if sk.find_bone("pelvis") >= 0 else 1
	var h := _bone(sk, "hips", alias)
	var hd := _bone(sk, "head", alias)
	if h < 0 or hd < 0:
		return 0.5
	return maxf(sk.get_bone_global_pose(hd).origin.distance_to(sk.get_bone_global_pose(h).origin) * sk.global_basis.get_scale().y, 0.1)


func hurt_box(on: Node3D, nodes: Array, pad: float) -> void:
	mesh_box(on, nodes, pad, "hurt", true)


## A box round some model parts, riding on `on`.
func mesh_box(on: Node3D, nodes: Array, pad: float, name_: String, hurt: bool) -> Part:
	if on == null:
		return null
	var meshes: Array = []
	for n in nodes:
		if n is MeshInstance3D:
			meshes.append(n)
		if n is Node:
			meshes.append_array((n as Node).find_children("*", "MeshInstance3D", true, false))
	var pts := _mesh_points(meshes, on)
	if pts.is_empty():
		return null
	var box := AABB(pts[0], Vector3.ZERO)
	for q in pts:
		box = box.expand(q)
	box = box.grow(pad)
	var p := _new_part(name_, hurt)
	p.kind = BOX
	p.node = on
	p.s0 = on.global_basis.get_scale()
	p.local = Transform3D(Basis.IDENTITY, box.get_center())
	var bs := BoxShape3D.new()
	bs.size = box.size
	p.shape.shape = bs
	return p


## The beetle's charge: mandible tips back to the middle of the body, as wide and tall as the whole beetle.
func charge_box(body: Node3D, root: Node3D, jaws: Array, front_world: Vector3) -> void:
	var all := _mesh_points(root.find_children("*", "MeshInstance3D", true, false), body)
	var jp := _mesh_points(jaws.filter(func(j): return j != null), body)
	if all.is_empty():
		return
	var f := (_frame(body).basis.inverse() * front_world).normalized()
	var whole := AABB(all[0], Vector3.ZERO)
	for q in all:
		whole = whole.expand(q)
	var axis := _main_axis(f)
	var sgn := signf(f[axis])
	var tip := -INF
	for q in (jp if not jp.is_empty() else all):
		tip = maxf(tip, q[axis] * sgn)
	var mid := whole.get_center()[axis] * sgn
	var box := whole
	box.position[axis] = minf(mid * sgn, (tip + 0.06) * sgn)
	box.size[axis] = absf(tip + 0.06 - mid)
	box = box.grow(0.03)
	var p := _new_part("charge", false)
	p.kind = BOX
	p.node = body
	p.s0 = body.global_basis.get_scale()
	p.local = Transform3D(Basis.IDENTITY, box.get_center())
	var bs := BoxShape3D.new()
	bs.size = box.size
	p.shape.shape = bs


## The front share of a model (a spider's bite).
func front_box(on: Node3D, front_world: Vector3, share: float, name_: String) -> void:
	var pts := _mesh_points(on.find_children("*", "MeshInstance3D", true, false), on)
	if pts.is_empty():
		return
	var f := (_frame(on).basis.inverse() * front_world).normalized()
	var axis := _main_axis(f)
	var box := AABB(pts[0], Vector3.ZERO)
	for q in pts:
		box = box.expand(q)
	var len := box.size[axis]
	if f[axis] > 0.0:
		box.position[axis] = box.end[axis] - len * share
	box.size[axis] = len * share
	box = box.grow(0.04)
	var p := _new_part(name_, false)
	p.kind = BOX
	p.node = on
	p.s0 = on.global_basis.get_scale()
	p.local = Transform3D(Basis.IDENTITY, box.get_center())
	var bs := BoxShape3D.new()
	bs.size = box.size
	p.shape.shape = bs


## The snail's spit bubble, shown where it leaves the mouth (in the fight it flies at you; the bubble is what hits).
func spit_ball(body: Node3D, head: Array, front_world: Vector3) -> void:
	var pts := _mesh_points(head.filter(func(h): return h != null), body)
	if pts.is_empty():
		return
	var f := (_frame(body).basis.inverse() * front_world).normalized()
	var best := pts[0]
	for q in pts:
		if q.dot(f) > best.dot(f):
			best = q
	var p := _new_part("spit", false)
	p.kind = BOX
	p.node = body
	p.s0 = body.global_basis.get_scale()
	p.local = Transform3D(Basis.IDENTITY, best + f * (SPIT_RADIUS + 0.1))
	var s := SphereShape3D.new()
	s.radius = SPIT_RADIUS
	p.shape.shape = s


func _slam_zone() -> void:
	var p := _new_part("slam", false)
	p.kind = CYL
	p.node = self
	p.s0 = self.global_basis.get_scale()
	p.local = Transform3D(Basis.IDENTITY, Vector3.UP * 0.4)
	var c := CylinderShape3D.new()
	c.radius = SLAM_RADIUS
	c.height = 0.8
	p.shape.shape = c


func remove(name_: String) -> void:
	for p in parts.duplicate():
		if p.name == name_:
			p.area.queue_free()
			parts.erase(p)


func get_part(name_: String) -> Part:
	for p in parts:
		if p.name == name_:
			return p
	return null


## Light a hit shape up for `seconds`, starting `delay` seconds from now (only shows in F9 for now).
func flash(name_: String, delay: float, seconds: float) -> void:
	var p := get_part(name_)
	if p:
		p.active_from = _clock + delay
		p.active_until = _clock + delay + seconds


func is_active(p: Part) -> bool:
	return _clock >= p.active_from and _clock <= p.active_until


# ---------------------------------------------------------------- following the bones

## Move every shape to where its bones / parts are now.
func sync() -> void:
	for p in parts:
		if not is_instance_valid(p.area):
			continue
		match p.kind:
			SEG:
				if not is_instance_valid(p.sk):
					continue
				var A := p.pa if p.read else p.sk.global_transform * p.sk.get_bone_global_pose(p.a).origin
				var B := p.pb if p.read else p.sk.global_transform * p.sk.get_bone_global_pose(p.b).origin
				var P := A + (B - A) * p.ta
				var Q := A + (B - A) * p.tb
				var d := Q - P
				var up := d.normalized() if d.length() > 0.001 else Vector3.UP
				var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
				p.area.global_transform = Transform3D(Basis(side, up, side.cross(up)), (P + Q) * 0.5)
				if p.shape.shape is CapsuleShape3D:
					var c := p.shape.shape as CapsuleShape3D
					c.radius = p.r
					c.height = d.length() + p.r * 2.0
				elif p.shape.shape is SphereShape3D:
					(p.shape.shape as SphereShape3D).radius = p.r
			_:
				if is_instance_valid(p.node) and p.node.is_inside_tree():
					# A creature grows in when it appears and some breathe: the box follows its size.
					var f := _frame(p.node)
					var k := p.node.global_basis.get_scale() / p.s0
					p.area.global_transform = Transform3D(f.basis * p.local.basis, f * (p.local.origin * k))
					if p.shape.shape is BoxShape3D:
						var bx := p.shape.shape as BoxShape3D
						if p.base == Vector3.ZERO:
							p.base = bx.size
						if not bx.size.is_equal_approx(p.base * k):
							bx.size = p.base * k


# ---------------------------------------------------------------- drawing (F9 and the preview pictures)

const HURT_COLOR := Color(0.3, 1.0, 0.45, 0.85)
const HIT_COLOR := Color(1.0, 0.25, 0.2, 0.95)
const IDLE_COLOR := Color(0.75, 0.75, 0.75, 0.35)


## Draws every shape of every HitShapes in the tree as wire lines. `only_hit`: show just this hit shape (the preview).
static func draw_all(tree: SceneTree, im: ImmediateMesh, show_idle := true) -> void:
	var any := false
	for hs: HitShapes in tree.get_nodes_in_group(GROUP):
		hs.sync()
		for p in hs.parts:
			if not is_instance_valid(p.area) or not p.area.is_inside_tree():
				continue
			var col := HURT_COLOR if p.hurt else (HIT_COLOR if hs.is_active(p) else IDLE_COLOR)
			if not p.hurt and not hs.is_active(p) and not show_idle:
				continue
			if not any:
				im.surface_begin(Mesh.PRIMITIVE_LINES)
				any = true
			_draw_shape(im, p.area.global_transform, p.shape.shape, col)
	if any:
		im.surface_end()


static func _draw_shape(im: ImmediateMesh, t: Transform3D, s: Shape3D, col: Color) -> void:
	if s is BoxShape3D:
		var h := (s as BoxShape3D).size * 0.5
		var c: Array[Vector3] = []
		for i in 8:
			c.append(t * Vector3(h.x * (1 if i & 1 else -1), h.y * (1 if i & 2 else -1), h.z * (1 if i & 4 else -1)))
		for e in [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]]:
			_line(im, c[e[0]], c[e[1]], col)
	elif s is SphereShape3D:
		var r := (s as SphereShape3D).radius
		for ax in [Basis.IDENTITY, Basis(Vector3.RIGHT, PI / 2), Basis(Vector3.FORWARD, PI / 2)]:
			_ring(im, Transform3D(t.basis * ax, t.origin), r, 0.0, col)
	elif s is CapsuleShape3D:
		var cs := s as CapsuleShape3D
		var half := maxf(cs.height * 0.5 - cs.radius, 0.0)
		for y in [-half, 0.0, half]:
			_ring(im, t, cs.radius, y, col)
		for k in 4:
			var a := k * PI / 2.0
			var o := Vector3(cos(a), 0, sin(a)) * cs.radius
			_line(im, t * (o + Vector3.UP * -half), t * (o + Vector3.UP * half), col)
		for ax in [Vector3.RIGHT, Vector3.BACK]:  # the round ends
			for sgn in [-1.0, 1.0]:
				for i in 12:
					var a0 := PI * i / 12.0
					var a1 := PI * (i + 1) / 12.0
					var p0: Vector3 = ax * cos(a0) * cs.radius + Vector3.UP * (half + sin(a0) * cs.radius) * sgn
					var p1: Vector3 = ax * cos(a1) * cs.radius + Vector3.UP * (half + sin(a1) * cs.radius) * sgn
					_line(im, t * p0, t * p1, col)
	elif s is CylinderShape3D:
		var cy := s as CylinderShape3D
		for y in [-cy.height * 0.5, cy.height * 0.5]:
			_ring(im, t, cy.radius, y, col)
		for k in 8:
			var a := k * TAU / 8.0
			var o := Vector3(cos(a), 0, sin(a)) * cy.radius
			_line(im, t * (o + Vector3.UP * -cy.height * 0.5), t * (o + Vector3.UP * cy.height * 0.5), col)


static func _ring(im: ImmediateMesh, t: Transform3D, r: float, y: float, col: Color) -> void:
	for i in 24:
		var a0 := TAU * i / 24.0
		var a1 := TAU * (i + 1) / 24.0
		_line(im, t * Vector3(cos(a0) * r, y, sin(a0) * r), t * Vector3(cos(a1) * r, y, sin(a1) * r), col)


static func _line(im: ImmediateMesh, a: Vector3, b: Vector3, col: Color) -> void:
	im.surface_set_color(col)
	im.surface_add_vertex(a)
	im.surface_set_color(col)
	im.surface_add_vertex(b)


# ---------------------------------------------------------------- helpers

func _new_part(name_: String, hurt: bool) -> Part:
	var p := Part.new()
	p.name = name_
	p.hurt = hurt
	p.area = Area3D.new()
	p.area.name = ("Hurt_" if hurt else "Hit_") + name_
	p.area.top_level = true
	p.area.monitoring = false   # (step 1: shapes only; the fights still use the old check)
	p.area.monitorable = false
	p.area.collision_layer = HURT_LAYER if hurt else HIT_LAYER
	p.area.collision_mask = 0
	p.shape = CollisionShape3D.new()
	p.area.add_child(p.shape)
	add_child(p.area)
	parts.append(p)
	return p


## A node's place in the world with its scale taken out (so shape sizes stay in metres).
static func _frame(n: Node3D) -> Transform3D:
	var g := n.global_transform
	return Transform3D(g.basis.orthonormalized(), g.origin)


## Every mesh corner, in `on`'s unscaled frame (metres).
static func _mesh_points(meshes: Array, on: Node3D) -> PackedVector3Array:
	var out: PackedVector3Array = []
	if on == null or not on.is_inside_tree():
		return out
	var inv := _frame(on).affine_inverse()
	for mi in meshes:
		if not (mi is MeshInstance3D) or (mi as MeshInstance3D).mesh == null or not (mi as Node3D).is_visible_in_tree():
			continue
		# The real points, not the mesh's bounds: some meshes (the soft, wobbling ones) carry padded bounds.
		var t := inv * (mi as Node3D).global_transform
		var m := (mi as MeshInstance3D).mesh
		for si in m.get_surface_count():
			if m.surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			for v: Vector3 in m.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
				out.append(t * v)
	return out


## A box over the part of a long thing (weapon) from `from` (0 = hand end) to its far end.
func _box_along(on: Node3D, pts: PackedVector3Array, from: float, pad: float, name_: String, hand := Vector3.ZERO) -> Part:
	var box := AABB(pts[0], Vector3.ZERO)
	for q in pts:
		box = box.expand(q)
	var axis := _main_axis(box.size)
	# The far end is the end farther from the hand (the frame's origin).
	var far_hi := absf(box.end[axis] - hand[axis]) >= absf(box.position[axis] - hand[axis])
	var len := box.size[axis]
	var keep := len * (1.0 - from)
	if far_hi:
		box.position[axis] = box.end[axis] - keep
	box.size[axis] = keep
	# Width and depth from the points in the kept part only (the thin handle doesn't widen a sword's blade box).
	var part := AABB()
	var first := true
	for q in pts:
		if q[axis] >= box.position[axis] - 0.001 and q[axis] <= box.end[axis] + 0.001:
			part = AABB(q, Vector3.ZERO) if first else part.expand(q)
			first = false
	if not first:
		box = part
	box = box.grow(pad)
	var p := _new_part(name_, false)
	p.kind = BOX
	p.node = on
	p.s0 = on.global_basis.get_scale()
	p.local = Transform3D(Basis.IDENTITY, box.get_center())
	var bs := BoxShape3D.new()
	bs.size = box.size
	p.shape.shape = bs
	return p


static func _main_axis(v: Vector3) -> int:
	var a := v.abs()
	return Vector3.AXIS_X if a.x >= a.y and a.x >= a.z else (Vector3.AXIS_Y if a.y >= a.z else Vector3.AXIS_Z)


static func _bone(sk: Skeleton3D, key: String, alias: int) -> int:
	var names: Array = BONES.get(key, [key, key])
	var i := sk.find_bone(names[alias])
	return i if i >= 0 else sk.find_bone(names[1 - alias])


## The body's size: hips to head in metres (the bubbles are sized from it).
static func _unit(sk: Skeleton3D, alias: int) -> float:
	var h := _bone(sk, "hips", alias)
	var hd := _bone(sk, "head", alias)
	if h < 0 or hd < 0:
		return 0.5
	var g := sk.global_transform
	return maxf((g * sk.get_bone_global_rest(hd).origin).distance_to(g * sk.get_bone_global_rest(h).origin), 0.1)


static func _named(root: Node, n: String) -> Node3D:
	return root.find_child(n, true, false) as Node3D
