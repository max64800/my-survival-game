class_name Drop
extends RigidBody3D
## A chunk of stuff that fell out of the rock. It bounces on the floor, and when
## the dwarf comes within PICKUP_RADIUS it flies to them and asks to be picked up.

const PICKUP_RADIUS := 4.0
const LOOSE_PICKUP_RADIUS := 1.5  ## things lying on the floor: you walk over to pick them up
var pickup_radius := PICKUP_RADIUS
const SETTLE_TIME := 0.45  ## let it fall out before it starts flying to you
const FLY_SPEED := 9.0
const DROP_LAYER := 4
## How big dropped things look (owner, Nov 15, F93: "5 times bigger"; it was 0.7). Every chunk
## also gets its own size, squash and tumble, so a pile of broken rock isn't a pile of equal cubes (F104).
const LOOK_SCALE := 1.75  ## F153: 3.5 was too big; now 2.5x the old size
const BODY_RADIUS := 0.3

var drop_id := 0
var item_id := ""
var count := 1
var home := Vector3.ZERO  ## where it first appeared

var _age := 0.0
var thrown := false  ## thrown away with Q (F825): doesn't fly back until you've walked away from it once
var _flying := false
var _retry := 0.0
var _asked := 0.0  ## seconds since we asked the host to pick us up (0 = not asked)
static var _mesh_cache := {}


func _ready() -> void:
	collision_layer = DROP_LAYER
	collision_mask = World.TERRAIN_LAYER
	mass = 0.3
	continuous_cd = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = BODY_RADIUS
	shape.shape = sphere
	add_child(shape)
	var model := Look.forged("items", item_id)  # a real model from the asset forge, if made
	var look: Node3D = model
	if look == null:
		var mi := MeshInstance3D.new()
		mi.mesh = _mesh_for(item_id)
		look = mi
	var size := randf_range(0.75, 1.25)
	var squash := Vector3(randf_range(0.8, 1.2), randf_range(0.7, 1.15), randf_range(0.8, 1.2))
	look.scale = squash * size * (LOOK_SCALE if model else LOOK_SCALE * 0.5)
	look.position = Vector3.DOWN * BODY_RADIUS * 0.8
	look.rotation = Vector3(randf_range(-0.5, 0.5), randf() * TAU, randf_range(-0.5, 0.5))
	add_child(look)


static func _mesh_for(id: String) -> Mesh:
	if _mesh_cache.has(id):
		return _mesh_cache[id]
	var m := BoxMesh.new()
	m.size = Vector3(0.26, 0.2, 0.22)
	var glow := 0.0
	if id in ["crystal_blue", "glowcap", "copper_ore", "tin_ore"]:
		glow = 0.25 if id.ends_with("_ore") else 0.8
	m.material = Look.mat(Items.color(id), "", glow, 0.03)  # a lumpy little chunk
	_mesh_cache[id] = m
	return m


func _physics_process(delta: float) -> void:
	_age += delta
	_retry = maxf(0.0, _retry - delta)
	var auth := GameAuthority.instance
	if auth == null or _age < SETTLE_TIME:
		return
	var ps := auth.get_player(auth.local_peer_id())
	if ps == null:
		return
	var target: Vector3 = ps.node.global_position + Vector3.UP * 0.9
	var dist := global_position.distance_to(target)
	if thrown:
		if dist < PICKUP_RADIUS:
			return
		thrown = false
		pickup_radius = LOOSE_PICKUP_RADIUS  # walked away: now you walk up to it to pick it back up
	if not _flying:
		if dist < pickup_radius and _retry == 0.0:
			_flying = true
			freeze = true
		return
	global_position = global_position.move_toward(target, FLY_SPEED * delta * (1.0 + 2.0 / maxf(dist, 0.5)))
	if _asked > 0.0:
		_asked += delta
		if _asked > 1.5:  # no answer: the host said no (bag full?)
			pickup_refused()
	elif dist < 0.6:
		_asked = 0.001
		auth.ask_pickup(drop_id)
		Sfx.ui("pickup", -8.0)


## The host couldn't fit us in the bag: fall back down and try again in a while.
func pickup_refused() -> void:
	_flying = false
	_asked = 0.0
	freeze = false
	_retry = 3.0
