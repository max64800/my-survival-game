class_name MineTraps
extends Node
## Lampwick Drift's mine traps and lamps (owner, Nov 20, F477; plan: docs/design/zone1-dungeons/02-lampwick-drift.md,
## models: tools/asset_forge/builds/dungeon_mine.py). A child of DungeonBuild ("MineTraps", the same path on every
## computer). DungeonBuild builds each thing (its own body) and hands it here; this moves it and judges it.
## Co-op: you ask -> the host decides -> everyone sees it. What has gone off is DungeonBuild's "broken" list (saved,
## sent to friends who join), so a sprung trap stays sprung; lit lamps are world_state.dungeon_lit.
##
##   lamp          an old mine lamp, unlit: E lights it (its flame shows and it gives light), for everyone.
##   cart          a cart held at the top of its lane by a rotten wedge: step into the lane and the wedge snaps, the
##                 cart rattles, then rolls down faster and faster and crashes into the stopper (it stays there).
##                 Hit by it: a rag doll tumble and CART_DAMAGE. (the wedge is its own "wedge" thing: it bursts.)
##   swing         the boulder on its chain swings along the plank walk (every computer off the same clock); hit by
##                 it: a rag doll tumble and SWING_DAMAGE. A bolt in its chain drops it for good.
##   jaws          bear jaws in the dust: a player stepping on them is bitten (JAWS_DAMAGE) and held JAWS_HOLD s;
##                 a friend can pry them open (E). Creatures don't set them off. A bolt or any hit springs them
##                 harmlessly (owner, Nov 20).
##   tripwire      a thin wire at ankle height: walk into it and the dart wall beside it fires a poison bolt across
##                 the tunnel. Jump over it, or cut it (hit it).
##   dart_wall     the wall with the hole (fired by its tripwire, or its floor plate).
##   spears        Old Pell's spear wall: its stakes stab out SPEAR_REACH m and pull back, over and over (every computer
##                 off the same clock; a wall's "phase" sets when). Out, they hurt whoever stands in front of it.
##                 With "wake" (Mossprop's ladder, F546) it sleeps until someone comes that near, then stabs on for good;
##                 with "climb" its stakes hit any part of you (you climb past it on a ladder).
##   push          Old Pell's push wall: step in front of it and, a moment later, its block slams out PUSH_OUT m and
##                 shoves you away from the wall (onto the rotten boards over the spike pit), then slides back in.
##                 Step in and jump back to set it off safely, then pass while it slides back.
##   lift          Old Pell's rope lift: E on it (riding it) sends it to the other end of its shaft; "lift_call" (the
##                 winch at the top, a lever at the bottom) calls it. Where it is: world_state.dungeon_lift (saved).
##   plate         Old Pell's cracked floor plate ("fires": true): step on it and the dart wall beside it fires. A bolt
##                 or a hit sets it off from afar (use it up: whoever stands in the dart's line is still hit).
##   chest_spikes  the vault's spike floor: stand on it a moment (to open the chest) and the spikes slam up. Shoot the
##                 chest (or the floor) first: they slam up harmlessly and stay down.
##                 Brassgate's treasury chests (prop on_open): the spikes fire when you open the chest instead.

const CART_WAIT := 0.6        ## seconds of cracking and rattling after the wedge snaps, before the cart moves
const CART_ACCEL := 4.0       ## m/s² down the lane (it reaches about 9 m/s at the foot)
const CART_HIT := 1.0         ## m from the cart's middle that it hits you
const CART_DAMAGE := 40.0     ## armour doesn't help (owner, Nov 20: "they need some damage")
const SWING_PERIOD := 3.2     ## seconds for a whole swing there and back (a 2.6 m chain)
const SWING_MAX := 60.0       ## degrees out each way
const SWING_PIVOT := Vector3(0.0, 3.5, 0.13)  ## the chain's top, in the model (dungeon_mine.py SWING_PIVOT)
const SWING_BALL := Vector3(0.0, 0.95, 0.13)  ## the boulder's middle at rest
const SWING_HIT := 0.95       ## m from the boulder's middle to your middle
const SWING_DAMAGE := 28.0
## Owner, Nov 20: it knocked him down, and as he got up beside it, it hit him again and again until he died. After a
## hit it leaves you alone this long (time to get up and step away).
const SWING_SPARE := 6.0
const SWING_DAZE := 2.0       ## a creature it hits is thrown back and dazed this long (no damage: owner, Nov 20)
const SWING_DROP := 0.2       ## how far the shot boulder falls (onto the planks)
const JAWS_REACH := 0.33
const JAWS_DAMAGE := 25.0     ## owner, Nov 20 (trap_bear_jaws.md)
const JAWS_HOLD := 3.5
const JAW_HINGE_Y := 0.04
const WIRE_REACH := 0.35      ## m either side of the wire that your feet touch it
const WIRE_HIGH := 0.45       ## feet higher than this above the wire's foot clear it (a jump)
const DART_DAMAGE := 18.0
const DART_POISON := 100.0    ## a full dose: one dart poisons you (owner, Nov 20; Ailments.FULL)
const CROSSBOW_DAMAGE := 30.0  ## Brassgate's guard-slot crossbow: a heavy bolt, no poison (F975)
const DART_LINE := 0.6        ## m from the bolt's line that it hits you
const DART_HOLE := Vector3(0.12, 0.95, 0.15)  ## the hole, in the dart wall model
const PLATE_REACH := 0.55     ## m from the plate's middle that your feet press it
const PLATE_COOLDOWN := 8.0   ## F618: seconds before the dart plate and wall reload for another shot
const SPEAR_CYCLE := 2.6      ## seconds from one stab to the next
const SPEAR_OUT := 0.15       ## seconds to stab out
const SPEAR_HOLD := 0.35      ## seconds they stay out
const SPEAR_BACK := 0.5       ## seconds to pull back (then they wait in the wall: the time to go)
const SPEAR_REACH := 0.8      ## m the stakes stick out of the wall
const SPEAR_DAMAGE := 22.0
const SPEAR_ROWS_AT := Vector2(0.5, 1.25)  ## m up the wall: the bottom of the lower stakes, the top of the upper ones
const SPEAR_DWARF := 1.35     ## m from a dwarf's feet to the top of the head (a climb wall's stakes hit any of it)
## Owner, Nov 20 (first play of Old Pell's): "pistons should ragdoll you ... move further and be quicker", no marks.
const PUSH_WAIT := 0.15       ## seconds from stepping in front of it to the slam (a click: jump back!)
const PUSH_SLAM := 0.12
const PUSH_HOLD := 1.0
const PUSH_BACK := 2.0
const PUSH_REST := 1.0        ## seconds after it is back before it can fire again
const PUSH_OUT := 1.8         ## m the block slams out
const PUSH_THROW := 9.0       ## m/s: the rag doll tumble that throws you away from the wall (Dwarf.big_hit)
const PUSH_DAMAGE := 8.0
const PUSH_ZONE := Vector2(0.8, 1.6)  ## its trigger: this far either side of its middle, this far out in front
const LIFT_TIME := 6.0        ## seconds for the lift to go the whole way
const LIFT_RING := 2.14       ## the platform's iron ring, above its origin (the hoist rope's foot)
const LIFT_DRUM := 2.32       ## the winch drum's underside, above the winch's origin (the hoist rope's top)
const LIFT_DRUM_AXIS := Vector3(0.0, 2.45, 0.0)
const SPIKE_STAND := 0.35     ## seconds on the spike floor before it fires
const SPIKE_DEPTH := 0.62     ## the spikes wait this far down
const SPIKE_DAMAGE := 30.0

var db: DungeonBuild
var _plate_cooling := {}  ## F618: host: plate/dart id -> unix time when it rearmed
var _cart_hit := {}   ## host: "cart id:peer" -> true (a cart hits you once)
var _swing_hit := {}  ## host: peer -> _clock when a boulder last hit them
var _swing_mon := {}  ## host: creature uid -> _clock when a boulder last threw it
var _held := {}       ## host: jaws id -> {peer, until}
var _on_spikes := {}  ## host: spike floor id -> seconds someone has stood on it
var _spear_hit := {}  ## host: "wall id:peer" -> the stab that last hurt them (one hit per stab)
var _push_hit := {}   ## "wall id:peer" -> the push that last hit them (one shove per push)
var _clock := 0.0


static func kind_of(p: Dictionary) -> String:
	match String(p.model):
		"dungeon/mine_lamp.glb":
			return "lamp"
		"dungeon/trap_cart.glb":
			return "cart" if p.has("path") else ""
		"dungeon/rail_wedge.glb":
			return "wedge" if String(p.get("role", "")) == "trap" else ""
		"dungeon/trap_swing_boulder.glb":
			return "swing"
		"dungeon/trap_bear_jaws.glb":
			return "jaws"
		"dungeon/tripwire.glb", "dungeon/tripwire_iron.glb":
			return "tripwire"
		"dungeon/trap_tripwire_wall.glb", "dungeon/trap_tripwire_wall_stone.glb", "dungeon/trap_crossbow_wall_stone.glb":
			return "dart_wall"
		"dungeon/trap_chest_spikes.glb", "dungeon/trap_chest_spikes_stone.glb":
			return "chest_spikes"
		"dungeon/trap_spear_wall.glb":
			return "spears"
		"dungeon/trap_push_wall.glb", "dungeon/trap_push_wall_stone.glb":
			return "push"
		"dungeon/lift_platform.glb":
			return "lift" if p.has("travel") else ""
		"dungeon/lift_winch.glb", "dungeon/lever.glb", "dungeon/lever_iron.glb":
			return "lift_call" if p.has("calls") else ""  # (the other levers open gates: DungeonBuild)
		"dungeon/trap_dart_plate.glb":
			return "plate" if p.get("fires", false) else ""  # (Mossgate's plates are only for show)
		"dungeon/rope_slide.glb":
			return "slide"
	return ""


## Kinds whose body melee hits do nothing to (the tripwire can be cut; bolts are handled in on_hit).
const NO_MELEE := ["lamp", "cart", "wedge", "swing", "dart_wall", "chest_spikes", "slide"]
## Mossprop Workings' rope slide (owner, Nov 21: "a way to get down that rope back to the first level"), in the
## model's own metres: where you grab the rope at the top post, and where you let go before the bottom post.
const SLIDE_GRAB := Vector3(0, 1.85, 0.55)
const SLIDE_DROP := Vector3(0, -10.24 + 1.6, 18.873 - 1.2)


func _ready() -> void:
	name = "MineTraps"


# ================================================================== building (everyone)

## DungeonBuild just built thing `id`: find its moving parts and set its starting pose.
func setup(id: int) -> void:
	var th: Dictionary = db.things[id]
	var inst: Node3D = th.inst
	match String(th.kind):
		"lamp":
			th.flame = inst.find_child("flame", true, false)
			th.lantern = inst.find_child("lantern", true, false)
			if th.flame:
				(th.flame as Node3D).visible = false
		"cart":
			var pts: Array = []
			for q in th.prop.path:
				pts.append(DungeonMap.to_world(th.d, Vector3(q[0], q[1], q[2])))
			th.path = pts
			var total := 0.0
			for i in range(1, pts.size()):
				total += (pts[i] as Vector3).distance_to(pts[i - 1])
			th.length = total
			th.wheels = inst.find_children("wheel*", "MeshInstance3D", true, false)
			th.wheel_rest = th.wheels.map(func(w): return (w as Node3D).transform)
			th.run_t = -1.0
			var lane: Array = th.prop.lane
			th.lane = Rect2(Vector2(lane[0], lane[1]), Vector2(float(lane[2]) - float(lane[0]), float(lane[3]) - float(lane[1])))
		"swing":
			th.swing = inst.find_child("swing", true, false)
			if th.swing:
				th.swing_rest = (th.swing as Node3D).transform
			th.last_sign = 0.0
		"jaws":
			th.jaws = [inst.find_child("jaw_l", true, false), inst.find_child("jaw_r", true, false)]
			th.jaw_rest = (th.jaws as Array).map(func(j): return (j as Node3D).transform if j else Transform3D())
			th.plate = inst.find_child("plate", true, false)
		"dart_wall":
			th.bolt = inst.find_child("bolt", true, false)
		"spears":
			th.spears = inst.find_child("spears", true, false)
			if th.spears:
				th.spear_rest = (th.spears as Node3D).transform
		"push":
			th.block = inst.find_child("block", true, false)
			th.push_t = -100.0
			th.pushes = 0
			if th.block:
				th.block_rest = (th.block as Node3D).transform
				_moving_box(th.block as MeshInstance3D, id)
		"lift":
			th.rest = inst.transform
			th.rope = inst.find_child("rope", true, false) as MeshInstance3D
			if th.rope:
				th.rope_rest = th.rope.transform
			var body := AnimatableBody3D.new()  # (the deck and its railings, moving with the platform: you ride it)
			body.sync_to_physics = false
			body.collision_layer = World.TERRAIN_LAYER
			body.collision_mask = 0
			body.set_meta("dungeon_thing", id)
			for bx in [[Vector3(0, 0.1, 0), Vector3(1.5, 0.2, 1.5)], [Vector3(0, 0.7, -0.69), Vector3(1.5, 1.0, 0.08)],
					[Vector3(-0.69, 0.7, 0), Vector3(0.08, 1.0, 1.5)], [Vector3(0.69, 0.7, 0), Vector3(0.08, 1.0, 1.5)]]:
				var cs := CollisionShape3D.new()
				var sh := BoxShape3D.new()
				sh.size = bx[1]
				cs.shape = sh
				cs.position = bx[0]
				body.add_child(cs)
			inst.add_child(body)
		"lift_call":
			th.drum = inst.find_child("drum", true, false)
			if th.drum:
				th.drum_rest = (th.drum as Node3D).transform
		"chest_spikes":
			th.spikes = inst.find_child("spikes", true, false)
			if th.spikes:
				th.spike_rest = (th.spikes as Node3D).transform
				(th.spikes as Node3D).position.y -= SPIKE_DEPTH


## A spent trap as it stays (on loading a world, or a friend joining): the cart at the stopper, the jaws shut, the
## boulder fallen, the bolt gone. Returns true if it is one of ours (DungeonBuild then doesn't hide it).
func show_spent(id: int) -> bool:
	var th: Dictionary = db.things[id]
	match String(th.kind):
		"cart":
			th.gone = true
			th.run_t = -1.0
			_place_cart(th, float(th.length))
		"jaws":
			th.gone = true
			_shut_jaws(th, 1.0)
		"swing":
			th.gone = true
			_drop_swing(th, 1.0)
		"dart_wall":
			th.gone = true
			if th.get("bolt"):
				(th.bolt as Node3D).visible = false
		"chest_spikes":
			th.gone = true
		"plate":
			th.gone = true
			(th.inst as Node3D).position.y -= 0.03
		"lamp":
			return true
		_:
			return false
	return true


# ================================================================== everyone, every frame

func step(delta: float) -> void:
	_clock += delta
	var now := Time.get_unix_time_from_system()
	var auth := GameAuthority.instance
	for id in db.things:
		var th: Dictionary = db.things[id]
		match String(th.kind):
			"cart":
				if float(th.run_t) >= 0.0:
					_run_cart(id, th, delta, auth)
			"swing":
				if not th.get("gone", false):
					_move_swing(th, now, auth)
			"lamp":
				if not th.get("lit", false) and lit(id):
					_light(th, false)
			"spears":
				_move_spears(id, th, now, auth)
			"push":
				_move_push(id, th, auth)
			"lift":
				_move_lift(id, th, now)


# ------------------------------------------------------------------ lamps

func lit(id: int) -> bool:
	var auth := GameAuthority.instance
	return auth != null and id in auth.world_state.get("dungeon_lit", [])


func _light(th: Dictionary, with_sound: bool) -> void:
	th.lit = true
	if th.get("flame"):
		(th.flame as Node3D).visible = true
	var at: Vector3 = (th.lantern as Node3D).global_position if th.get("lantern") else (th.centre as Vector3)
	var o := OmniLight3D.new()
	o.light_color = Color(1.0, 0.7, 0.4)
	o.light_energy = 1.5
	o.omni_range = 8.0
	o.shadow_enabled = false
	db.add_child(o)
	o.global_position = at
	Darkness.mark(o)  # (it counts as light: you heal by it)
	th.light = o
	if with_sound:
		Sfx.play("clink", at, -4.0, 1.4)
		Fx.burst(db.get_parent(), at, Color(1.0, 0.75, 0.35), 8, 1.0)


@rpc("authority", "call_local", "reliable")
func _ev_lamp(id: int) -> void:
	var auth := GameAuthority.instance
	if auth and not auth.is_host():
		var list: Array = auth.world_state.get("dungeon_lit", []).duplicate()
		if not id in list:
			list.append(id)
		auth.world_state["dungeon_lit"] = list
	var th: Dictionary = db.things.get(id, {})
	if not th.is_empty() and not th.get("lit", false):
		_light(th, true)


# ------------------------------------------------------------------ carts

## Where a cart is `s` metres along its run (and its turn: front down the lane), in the world.
func cart_xform(th: Dictionary, s: float) -> Transform3D:
	var pts: Array = th.path
	var left := s
	for i in range(1, pts.size()):
		var a: Vector3 = pts[i - 1]
		var b: Vector3 = pts[i]
		var seg := a.distance_to(b)
		if left <= seg or i == pts.size() - 1:
			var dir := (b - a).normalized()
			var basis := Basis.looking_at(-dir, Vector3.UP)  # (its +z, the front, down the lane)
			return Transform3D(basis, a + dir * minf(left, seg))
		left -= seg
	return th.xform


func _place_cart(th: Dictionary, s: float) -> void:
	var t := cart_xform(th, s)
	(th.node as Node3D).transform = t * (th.xform as Transform3D).affine_inverse()  # (its body and model move together)
	th.pos = t.origin
	var wheels: Array = th.get("wheels", [])
	for k in wheels.size():
		var w := wheels[k] as Node3D
		var rest: Transform3D = th.wheel_rest[k]
		w.transform = Transform3D(rest.basis * Basis(Vector3.RIGHT, s / 0.15), rest.origin)


## How far a cart has gone `t` seconds after its wedge snapped.
static func cart_distance(t: float) -> float:
	var go := maxf(0.0, t - CART_WAIT)
	return 0.5 * CART_ACCEL * go * go


func _run_cart(id: int, th: Dictionary, delta: float, auth: GameAuthority) -> void:
	th.run_t = float(th.run_t) + delta
	var s := minf(cart_distance(float(th.run_t)), float(th.length))
	_place_cart(th, s)
	if s >= float(th.length):
		th.run_t = -1.0
		Sfx.play("thud", th.pos, 6.0, 0.6)
		Sfx.play("shell_clank", th.pos, 2.0, 0.6)
		Fx.burst(db.get_parent(), th.pos + Vector3.UP * 0.6, DungeonBuild.STONE, 18, 3.0)
		return
	if auth == null or not auth.is_host() or s <= 0.0:
		return
	var speed := CART_ACCEL * maxf(0.0, float(th.run_t) - CART_WAIT)
	if speed < 2.0:
		return
	var fwd := cart_xform(th, s).basis.z.normalized()
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		var key := "%d:%d" % [id, pid]
		if node == null or _cart_hit.has(key):
			continue
		var p := node.global_position
		var c: Vector3 = th.pos
		if Vector2(p.x - c.x, p.z - c.z).length() < CART_HIT and absf(p.y + 0.6 - c.y) < 1.3:
			_cart_hit[key] = true
			print("MINE: player %d hit by a cart" % pid)
			auth.hurt(pid, CART_DAMAGE, {pierce = true})
			if node.has_method("big_hit"):
				node.big_hit(Vector3(fwd.x, 0.0, fwd.z).normalized() * 9.0 + Vector3.UP * 3.0)


## Host: someone stepped into a cart's lane: its wedge snaps (for everyone), and the cart comes.
func _release_cart(id: int) -> void:
	db._break(id)
	var th: Dictionary = db.things[id]
	for wid in db.things:  # its wedge (just below it)
		var w: Dictionary = db.things[wid]
		if w.kind == "wedge" and (w.centre as Vector3).distance_to(th.centre) < 2.5:
			db._break(wid)
	print("MINE: a cart's wedge snaps")


func on_broke(id: int) -> bool:
	var th: Dictionary = db.things[id]
	match String(th.kind):
		"cart":
			th.gone = true
			th.run_t = 0.0
			Sfx.play("shell_clank", th.centre, 0.0, 0.5)  # the rattle before it comes
			Sfx.play("beetle_rumble", th.centre, -2.0, 0.6)
		"wedge":
			th.gone = true
			Fx.burst(db.get_parent(), th.centre, DungeonBuild.WOOD, 14, 2.5)
			Sfx.play("dig_break", th.centre, 2.0, 0.7)  # (the crack)
			db._tumble(id, 0.4, 0.5)
		"jaws":
			th.gone = true
			_shut_jaws(th, 0.0)
		"swing":
			th.gone = true
			_drop_swing(th, 0.0)
		"tripwire":
			th.gone = true
			Sfx.play("clink", th.centre, -2.0, 1.8)
			db._tumble(id, 0.12, 0.4)
		"dart_wall":
			th.gone = true
			_fire_bolt(th)
		"plate":
			th.gone = true
			Sfx.play("clink", th.centre, 2.0, 0.6)  # (the click of the plate going down)
			(th.inst as Node3D).position.y -= 0.03
		"chest_spikes":
			th.gone = true
			_slam_spikes(th)
			var box := chest_by(th)
			if box:
				ChestOpen.open(box)  # (owner, Nov 21, F585: it springs open as its spikes go off)
		_:
			return false
	return true


# ------------------------------------------------------------------ the swinging boulder

## Its angle right now (degrees; the same on every computer).
static func swing_angle(now: float) -> float:
	return SWING_MAX * sin(TAU * fposmod(now, SWING_PERIOD) / SWING_PERIOD)


func _swing_pose(th: Dictionary, deg: float, drop := 0.0) -> void:
	if th.get("swing") == null:
		return
	var r := Basis(Vector3.RIGHT, deg_to_rad(deg))
	var rest: Transform3D = th.swing_rest
	(th.swing as Node3D).transform = Transform3D(r * rest.basis, SWING_PIVOT + r * (rest.origin - SWING_PIVOT) + Vector3.DOWN * drop)


## Where the boulder's middle is at `deg`, in the world.
func ball_at(th: Dictionary, deg: float) -> Vector3:
	return (th.xform as Transform3D) * (SWING_PIVOT + Basis(Vector3.RIGHT, deg_to_rad(deg)) * (SWING_BALL - SWING_PIVOT))


func _move_swing(th: Dictionary, now: float, auth: GameAuthority) -> void:
	var deg := swing_angle(now)
	_swing_pose(th, deg)  # (silent: owner, Nov 20, "I don't want it to make noises"; the grooves are its clue)
	if auth == null or not auth.is_host():
		return
	var ball := ball_at(th, deg)
	var push := ball_at(th, swing_angle(now + 0.05)) - ball
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node == null or _clock - float(_swing_hit.get(pid, -100.0)) < SWING_SPARE:
			continue
		if (node.global_position + Vector3.UP * 0.9).distance_to(ball) < SWING_HIT:
			_swing_hit[pid] = _clock
			print("MINE: player %d hit by the swinging boulder" % pid)
			auth.hurt(pid, SWING_DAMAGE)
			if node.has_method("big_hit"):
				node.big_hit(Vector3(push.x, 0.0, push.z).normalized() * 8.0 + Vector3.UP * 3.0)
	if auth.monsters == null:
		return
	for m in auth.monsters.monsters.values():  # creatures in its way are thrown aside and dazed, unhurt
		var mon := m as Monster
		if mon == null or not mon.is_alive() or _clock - float(_swing_mon.get(mon.uid, -100.0)) < 2.0:
			continue
		if (mon.global_position + Vector3.UP * 0.8).distance_to(ball) < SWING_HIT + 0.2:
			_swing_mon[mon.uid] = _clock
			mon.knock(Vector3(push.x, 0.0, push.z).normalized() * 9.0)
			mon.stun.stunned_left = maxf(mon.stun.stunned_left, SWING_DAZE)
			mon.state = Monster.State.STUNNED
			auth.monsters.monster_changed(mon)


## The shot chain lets go: the boulder swings to the middle and drops onto the planks (`now` 1 = at once).
func _drop_swing(th: Dictionary, now: float) -> void:
	var from := swing_angle(Time.get_unix_time_from_system())
	if now >= 1.0:
		_swing_pose(th, 0.0, SWING_DROP)
		return
	var tw := db.create_tween()
	tw.tween_method(func(f: float) -> void: _swing_pose(th, from * (1.0 - f), SWING_DROP * f * f), 0.0, 1.0, 0.35)
	tw.tween_callback(func() -> void:
		var at := ball_at(th, 0.0) + Vector3.DOWN * SWING_DROP
		RockShatter.burst(db.get_parent(), at, Vector3.UP, DungeonBuild.STONE, Mat.STONE, 0.7))


# ------------------------------------------------------------------ bear jaws

func _shut_jaws(th: Dictionary, now: float) -> void:
	var jaws: Array = th.get("jaws", [])
	if th.get("plate"):
		(th.plate as Node3D).position.y -= 0.01
	for k in jaws.size():
		var j := jaws[k] as MeshInstance3D
		if j == null:
			continue
		var rest: Transform3D = th.jaw_rest[k]
		var mid := rest * j.get_aabb().get_center()
		var ang := deg_to_rad(90.0 if mid.z < 0.0 else -90.0)  # (each jaw lifts up from its own side)
		var hinge := Vector3(0.0, JAW_HINGE_Y, 0.0)
		var pose := func(f: float) -> void:
			if is_instance_valid(j):
				var r := Basis(Vector3.RIGHT, ang * f)
				j.transform = Transform3D(r * rest.basis, hinge + r * (rest.origin - hinge))
		if now >= 1.0:
			pose.call(1.0)
		else:
			db.create_tween().tween_method(pose, 0.0, 1.0, 0.08)
	if now < 1.0:
		Sfx.play("shell_clunk", th.centre, 6.0, 1.3)
		Sfx.play("clink", th.centre, 2.0, 0.8)


@rpc("authority", "call_local", "reliable")
func _ev_slide(peer: int, a: Vector3, b: Vector3) -> void:
	var auth := GameAuthority.instance
	if auth == null or peer != auth.local_peer_id():
		return
	var me := auth.get_player(peer)
	if me and me.node and me.node.has_method("slide_down"):
		me.node.slide_down(a, b)


@rpc("authority", "call_local", "reliable")
func _ev_hold(peer: int, secs: float) -> void:
	var auth := GameAuthority.instance
	if auth == null or peer != auth.local_peer_id():
		return
	var me := auth.get_player(peer)
	if me and me.node and me.node.has_method("hold_legs"):
		me.node.hold_legs(secs)


# ------------------------------------------------------------------ the tripwire and its dart

func _dart_of(wire_id: int) -> int:
	var th: Dictionary = db.things[wire_id]
	var best := -1
	var near := 4.5 if th.kind == "tripwire" else 6.0
	for id in db.things:
		var w: Dictionary = db.things[id]
		var dd := (w.xform as Transform3D).origin.distance_to((th.xform as Transform3D).origin)
		if w.kind == "dart_wall" and dd < near:
			best = id
			near = dd
	return best


## The bolt's line: from the hole, straight out of the wall's face (in the world).
func dart_line(th: Dictionary) -> Array:
	var t: Transform3D = th.xform
	return [t * DART_HOLE, t.basis.z.normalized()]


func _fire_bolt(th: Dictionary) -> void:
	var line := dart_line(th)
	Sfx.play("swing", line[0], 4.0, 1.7)
	var bolt := th.get("bolt") as Node3D
	if bolt == null:
		return
	var g := bolt.global_transform
	var tw := db.create_tween()
	tw.tween_method(func(f: float) -> void:
		if is_instance_valid(bolt):
			bolt.global_transform = Transform3D(g.basis, g.origin + (line[1] as Vector3) * 4.6 * f), 0.0, 1.0, 0.18)
	tw.tween_callback(func() -> void:
		if is_instance_valid(bolt):
			bolt.visible = false
			Fx.burst(db.get_parent(), bolt.global_position, DungeonBuild.WOOD, 6, 1.5))


## Host: the wire was walked into (or the plate stepped on). `rearms=true` for plates (F618: they reload).
func _trip(wire_id: int, auth: GameAuthority, rearms := false) -> void:
	if rearms:
		var now := Time.get_unix_time_from_system()
		if _plate_cooling.get(wire_id, 0.0) > now:
			return  # still cooling down
		_plate_cooling[wire_id] = now + PLATE_COOLDOWN
	else:
		db._break(wire_id)
	_fire_dart(_dart_of(wire_id), auth, rearms)


## Host: dart wall `dart` fires (its tripwire or plate went off): whoever is in its line is hit.
func _fire_dart(dart: int, auth: GameAuthority, rearms := false) -> void:
	if dart < 0 or db.is_broken(dart):
		return
	if rearms:
		_plate_cooling[dart] = Time.get_unix_time_from_system() + PLATE_COOLDOWN
	else:
		db._break(dart)
	var line := dart_line(db.things[dart])
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node == null:
			continue
		var p := node.global_position + Vector3.UP * 0.9
		var along := (p - (line[0] as Vector3)).dot(line[1])
		var off := (p - (line[0] as Vector3)) - (line[1] as Vector3) * along
		if along > 0.0 and along < 4.6 and off.length() < DART_LINE + 0.5:
			if is_crossbow(db.things[dart]):
				print("MINE: player %d hit by the crossbow bolt" % pid)
				auth.hurt(pid, CROSSBOW_DAMAGE)
				auth.tell(pid, "A crossbow bolt shoots out of the guard slot!")
			else:
				print("MINE: player %d hit by the dart" % pid)
				auth.hurt(pid, DART_DAMAGE, {poison = DART_POISON})
				auth.tell(pid, "A poisoned dart shoots out of the wall!")


## Brassgate's dart wall is a crossbow in a guard slot (a heavy bolt, no poison).
static func is_crossbow(th: Dictionary) -> bool:
	return String(th.prop.model).contains("crossbow")


# ------------------------------------------------------------------ the vault's spike floor

func _slam_spikes(th: Dictionary) -> void:
	var sp := th.get("spikes") as Node3D
	if sp == null:
		return
	var rest: Transform3D = th.spike_rest
	var down := rest.origin + Vector3.DOWN * SPIKE_DEPTH
	Sfx.play("shell_clank", th.centre, 6.0, 0.8)
	var tw := db.create_tween()
	tw.tween_property(sp, "position", rest.origin, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_property(sp, "position", down, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func on_spike_floor(th: Dictionary, p: Vector3) -> bool:
	var q := (th.xform as Transform3D).affine_inverse() * p
	return absf(q.x) < 1.0 and absf(q.z) < 2.0 and q.y > -0.3 and q.y < 0.9


func _fire_spikes(id: int, auth: GameAuthority, opener := 0) -> void:
	if db.is_broken(id):
		return
	db._break(id)
	var th: Dictionary = db.things[id]
	print("MINE: the vault's spikes slam up")
	await db.get_tree().create_timer(0.12).timeout
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node and (pid == opener or on_spike_floor(th, node.global_position)):
			auth.hurt(pid, SPIKE_DAMAGE)
			auth.tell(pid, "Spikes shoot up out of the floor!")


## The chest a spike floor guards (its body; null if there's none near).
func chest_by(th: Dictionary) -> Node3D:
	var auth := GameAuthority.instance
	if auth == null or auth.storage == null:
		return null
	for bid in auth.storage.boxes:
		var node: Node3D = auth.storage.boxes[bid].node
		if is_instance_valid(node) and node.global_position.distance_to(th.centre) < 2.5:
			return node
	return null


## Brassgate's treasury chests (F975): their spikes fire when someone opens the chest (not from standing there).
static func fires_on_open(th: Dictionary) -> bool:
	return bool(th.prop.get("on_open", false))


## The armed open-to-fire spike floor by a chest at `p` (someone opens it): its id, or -1.
func open_spikes_near(p: Vector3) -> int:
	var id := spikes_near(p)
	if id < 0 or db.is_broken(id) or not fires_on_open(db.things[id]):
		return -1
	return id


## The spike floor near a point (a bolt hit the vault's chest): its id, or -1.
func spikes_near(p: Vector3) -> int:
	for id in db.things:
		var th: Dictionary = db.things[id]
		if th.kind == "chest_spikes" and (th.centre as Vector3).distance_to(p) < 2.5:
			return id
	return -1


# ================================================================== host: hits, uses, where you stand

## Host: a hit on one of our things. Returns true if it was ours (handled).
func on_hit(peer_id: int, id: int, by_bolt: bool) -> bool:
	var th: Dictionary = db.things[id]
	var kind := String(th.kind)
	if kind_of(th.prop) == "":
		return false
	if db.is_broken(id):
		return true
	var auth := GameAuthority.instance
	if by_bolt:
		match kind:
			"swing":
				print("MINE: the boulder's chain is shot")
				db._break(id)
			"chest_spikes":
				_fire_spikes(id, auth)
			"tripwire":
				db._break(id)  # (a bolt cuts it too)
			"plate":
				print("MINE: the dart plate set off by a bolt")
				_trip(id, auth, true)  # F618: plates rearm
			"jaws":
				print("MINE: bear jaws sprung by a bolt")
				db._break(id)  # (they snap shut on nothing)
		return true
	if kind == "plate":  # (a hit with a long tool sets it off too)
		print("MINE: the dart plate set off by a hit")
		_trip(id, auth, true)  # F618: plates rearm
		return true
	if kind == "jaws":  # any hit springs them too
		print("MINE: bear jaws sprung by a hit")
		db._break(id)
		return true
	if kind == "tripwire":  # cut: it falls in two, harmlessly
		var ps := auth.get_player(peer_id)
		if ps and ps.node.global_position.distance_to(th.centre) < GameAuthority.REACH + 2.5:
			print("MINE: the tripwire is cut")
			db._break(id)
	return true


## What E does on our thing `id` ({} = nothing).
func use_info(id: int) -> Dictionary:
	var th: Dictionary = db.things.get(id, {})
	match String(th.get("kind", "")):
		"lamp":
			return {} if lit(id) else {name = "Old mine lamp · E to light", use = id}
		"jaws":
			return {name = "Bear jaws · E to pry them open", use = id} if db.is_broken(id) else {}
		"lift":
			return {name = "Rope lift · E to ride it %s" % ("down" if lift_up(id) else "up"), use = id}
		"lift_call":
			return {name = "%s · E to call the lift" % ("Winch" if String(th.model).ends_with("winch.glb") else "Lever"), use = id}
		"slide":
			return {name = "Rope slide · E to slide down", use = id}
	return {}


## Host: a player's E on our thing. Returns true if it was ours.
func request_use(peer_id: int, id: int) -> bool:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	var th: Dictionary = db.things.get(id, {})
	if th.is_empty() or not String(th.kind) in ["lamp", "jaws", "lift", "lift_call", "slide", "chest_spikes"]:
		return false
	if th.kind == "chest_spikes":  # (F975) someone opens a treasury chest without shooting it first: stab!
		if fires_on_open(th) and not db.is_broken(id) and ps != null 				and ps.node.global_position.distance_to(th.centre) < DungeonBuild.USE_REACH + 2.5:
			print("MINE: player %d opened a spike chest" % peer_id)
			_fire_spikes(id, auth, peer_id)
		return true
	if th.kind == "slide":  # only from the top post: the host says go, the rider's own game slides them down
		var t: Transform3D = th.xform
		if ps != null and ps.node.global_position.distance_to(t.origin) < DungeonBuild.USE_REACH + 2.0:
			_ev_slide.rpc(peer_id, t * SLIDE_GRAB, t * SLIDE_DROP)
		elif ps != null:
			auth.tell(peer_id, "Climb up to the top post to ride the rope down.")
		return true
	if th.kind in ["lift", "lift_call"]:
		var lift := id if th.kind == "lift" else lift_of(id)
		var at: Vector3 = lift_pos(lift) if th.kind == "lift" else th.centre
		if ps != null and lift >= 0 and ps.node.global_position.distance_to(at) < DungeonBuild.USE_REACH + 2.0:
			if th.kind == "lift":
				send_lift(lift, not lift_up(lift), peer_id)
			else:
				send_lift(lift, lift_end_near(lift, th.centre), peer_id)
		return true
	if ps == null or ps.node.global_position.distance_to(th.centre) > DungeonBuild.USE_REACH + 1.5:
		return true
	if th.kind == "lamp":
		if not lit(id):
			var list: Array = auth.world_state.get("dungeon_lit", []).duplicate()
			list.append(id)
			auth.world_state["dungeon_lit"] = list
			_ev_lamp.rpc(id)
		return true
	var h: Dictionary = _held.get(id, {})
	if not h.is_empty() and _clock < float(h.until):  # a friend pries the jaws open: whoever is held is free
		_held.erase(id)
		_ev_hold.rpc(int(h.peer), 0.0)
		if int(h.peer) != peer_id:
			auth.tell(int(h.peer), "Your friend pries the jaws open.")
	return true


## Host, every trap tick: player `pid` at `p` (feet).
func host_check(auth: GameAuthority, pid: int, p: Vector3, step: float) -> void:
	for id in db.things:
		var th: Dictionary = db.things[id]
		if th.get("gone", false) or db.is_broken(id):
			continue
		match String(th.kind):
			"cart":
				var q := DungeonMap.to_local(th.d, p)
				if (th.lane as Rect2).has_point(Vector2(q.x, q.z)) and DungeonMap.space_at(th.d, p + Vector3.UP) in ["cart_junction", "junction_top"]:
					_release_cart(id)
			"jaws":
				var c: Vector3 = (th.xform as Transform3D).origin
				if Vector2(p.x - c.x, p.z - c.z).length() < JAWS_REACH and absf(p.y - c.y) < 0.5:
					db._break(id)
					_held[id] = {peer = pid, until = _clock + JAWS_HOLD}
					print("MINE: player %d stepped in bear jaws" % pid)
					auth.hurt(pid, JAWS_DAMAGE)
					auth.tell(pid, "Bear jaws snap shut on your leg!")
					_ev_hold.rpc(pid, JAWS_HOLD)
			"plate":
				var c: Vector3 = (th.xform as Transform3D).origin
				if Vector2(p.x - c.x, p.z - c.z).length() < PLATE_REACH and absf(p.y - c.y) < 0.5:
					print("MINE: player %d stepped on the dart plate" % pid)
					_trip(id, auth, true)  # F618: plates rearm
			"tripwire":
				var q := (th.xform as Transform3D).affine_inverse() * p
				if absf(q.x) < 0.5 and absf(q.z) < WIRE_REACH and q.y < WIRE_HIGH and q.y > -0.6:
					print("MINE: player %d walked into the tripwire" % pid)
					_trip(id, auth)
			"push":
				if _clock - float(th.push_t) > PUSH_WAIT + PUSH_SLAM + PUSH_HOLD + PUSH_BACK + PUSH_REST:
					var q := (th.xform as Transform3D).affine_inverse() * p
					if absf(q.x) < PUSH_ZONE.x and q.z > 0.0 and q.z < PUSH_ZONE.y and absf(q.y) < 1.0:
						print("MINE: player %d stepped in front of a push wall" % pid)
						_ev_push.rpc(id)
			"chest_spikes":
				if not fires_on_open(th) and on_spike_floor(th, p):
					_on_spikes[id] = float(_on_spikes.get(id, 0.0)) + step
					if _on_spikes[id] >= SPIKE_STAND:
						_on_spikes.erase(id)
						_fire_spikes(id, auth)


# ================================================================== Old Pell's: spear walls, push walls, the rope lift

## A moving part's own box (it moves with the part): the push wall's block.
func _moving_box(part: MeshInstance3D, id: int) -> void:
	if part == null:
		return
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	body.collision_layer = World.TERRAIN_LAYER
	body.collision_mask = 0
	body.set_meta("dungeon_thing", id)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	var box := part.get_aabb()
	sh.size = box.size
	cs.shape = sh
	cs.position = box.get_center()
	body.add_child(cs)
	part.add_child(body)


## How far out a spear wall's stakes are (0 in, 1 out) at `t` seconds into its stab.
static func spear_out(t: float) -> float:
	t = fposmod(t, SPEAR_CYCLE)
	if t < SPEAR_OUT:
		return t / SPEAR_OUT
	t -= SPEAR_OUT
	if t < SPEAR_HOLD:
		return 1.0
	t -= SPEAR_HOLD
	if t < SPEAR_BACK:
		return 1.0 - t / SPEAR_BACK
	return 0.0


## Is `p` (feet) in front of a spear wall, where its stakes reach when `out` of the way out?
## A "climb" wall (beside a ladder, F546) hurts anyone whose body (feet to head) meets its stakes, not only feet in front.
static func in_spears(th: Dictionary, p: Vector3, out: float) -> bool:
	var q := (th.xform as Transform3D).affine_inverse() * p
	var low := -0.3
	var high := 1.0
	if th.prop.get("climb", false):
		low = SPEAR_ROWS_AT.x - SPEAR_DWARF
		high = SPEAR_ROWS_AT.y
	return absf(q.x) < 0.95 and q.z > 0.0 and q.z < SPEAR_REACH * out + 0.35 and q.y > low and q.y < high


## Is a sleeping spear wall (prop "wake" = how near, m) woken by someone at `p`? Near it across, and not far above
## or below.
static func wakes_spears(th: Dictionary, p: Vector3) -> bool:
	var c: Vector3 = (th.xform as Transform3D).origin
	return Vector2(p.x - c.x, p.z - c.z).length() < float(th.prop.get("wake", 0.0)) and p.y > c.y - 3.0 and p.y < c.y + 2.0


## Everyone: the stakes stab out and back (the same clock everywhere); the host hurts whoever they reach.
func _move_spears(id: int, th: Dictionary, now: float, auth: GameAuthority) -> void:
	if th.prop.has("wake") and float(th.get("woke", -1.0)) < 0.0:  # asleep (F546): still, until someone comes near
		if auth and auth.is_host():
			for pid in auth.players:
				var who: Node3D = auth.players[pid].node
				if who and wakes_spears(th, who.global_position):
					print("MINE: player %d woke a spear wall" % pid)
					_ev_spears_wake.rpc(id, now)
					break
		if float(th.get("woke", -1.0)) < 0.0:
			return
	var t := now - float(th.get("woke", 0.0)) - float(th.prop.get("phase", 0.0))
	var out := spear_out(t)
	var sp := th.get("spears") as Node3D
	if sp:
		var rest: Transform3D = th.spear_rest
		sp.transform = Transform3D(rest.basis, rest.origin + Vector3(0, 0, SPEAR_REACH * out))
	var was := float(th.get("out", 0.0))
	th.out = out
	if was <= 0.0 and out > 0.0 and auth:  # the thunk of the stakes (only near you)
		var me := auth.get_player(auth.local_peer_id())
		if me and me.node and me.node.global_position.distance_to(th.centre) < 14.0:
			Sfx.play("swing", th.centre, -2.0, 0.8)
	if auth == null or not auth.is_host() or out < 0.5:
		return
	var stab := int(floor(t / SPEAR_CYCLE))
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		var key := "%d:%d" % [id, pid]
		if node == null or int(_spear_hit.get(key, -1)) == stab or not in_spears(th, node.global_position, out):
			continue
		_spear_hit[key] = stab
		print("MINE: player %d stabbed by a spear wall" % pid)
		auth.hurt(pid, SPEAR_DAMAGE)
		auth.tell(pid, "Sharp stakes stab out of the wall!")


## Everyone: a sleeping spear wall wakes (the host saw someone come near) and stabs on from then, for good.
@rpc("authority", "call_local", "reliable")
func _ev_spears_wake(id: int, at: float) -> void:
	var th: Dictionary = db.things.get(id, {})
	if not th.is_empty() and float(th.get("woke", -1.0)) < 0.0:
		th.woke = at


## Everyone: a push wall fires (the host saw someone step in front of it).
@rpc("authority", "call_local", "reliable")
func _ev_push(id: int) -> void:
	var th: Dictionary = db.things.get(id, {})
	if th.is_empty():
		return
	th.push_t = _clock
	th.pushes = int(th.get("pushes", 0)) + 1
	Sfx.play("clink", th.centre, 2.0, 0.5)  # the click (jump back!)


## How far out a push wall's block is (0 in, 1 out), `e` seconds after it fired.
static func push_out(e: float) -> float:
	if e < PUSH_WAIT:
		return 0.0
	e -= PUSH_WAIT
	if e < PUSH_SLAM:
		return e / PUSH_SLAM
	e -= PUSH_SLAM
	if e < PUSH_HOLD:
		return 1.0
	e -= PUSH_HOLD
	if e < PUSH_BACK:
		return 1.0 - e / PUSH_BACK
	return 0.0


## Is `p` (feet) where the block reaches when `out` of the way out?
static func in_push(th: Dictionary, p: Vector3, out: float) -> bool:
	var q := (th.xform as Transform3D).affine_inverse() * p
	return absf(q.x) < 1.0 and q.z > -0.2 and q.z < PUSH_OUT * out + 0.45 and q.y > -0.3 and q.y < 1.2


## Everyone: the block slams out and slides back. The host throws whoever it hits (a rag doll tumble, everyone sees
## it) and hurts them.
func _move_push(id: int, th: Dictionary, auth: GameAuthority) -> void:
	var e := _clock - float(th.push_t)
	var out := push_out(e)
	var bl := th.get("block") as Node3D
	if bl:
		var rest: Transform3D = th.block_rest
		bl.transform = Transform3D(rest.basis, rest.origin + Vector3(0, 0, PUSH_OUT * out))
	var slamming := e >= PUSH_WAIT and e < PUSH_WAIT + PUSH_SLAM + 0.05
	if not slamming or auth == null:
		return
	var away := (th.xform as Transform3D).basis.z.normalized()
	if int(th.get("thud", 0)) != int(th.pushes):
		th.thud = int(th.pushes)
		Sfx.play("thud", th.centre, 2.0, 0.8, 18.0)
	if not auth.is_host():
		return
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		var hk := "%d:%d" % [id, pid]
		if node == null or int(_push_hit.get(hk, 0)) == int(th.pushes) or not in_push(th, node.global_position, out):
			continue
		_push_hit[hk] = int(th.pushes)
		print("MINE: player %d shoved by a push wall" % pid)
		if node.has_method("big_hit"):  # (you tumble where it throws you: onto the rotten boards, which give way)
			node.big_hit(Vector3(away.x, 0.0, away.z) * PUSH_THROW)
		auth.hurt(pid, PUSH_DAMAGE)
		auth.tell(pid, "A block slams out of the wall!")


## The rope lift: is it up (or on its way up)?
func lift_up(id: int) -> bool:
	return bool(_lift_state(id)[0])


func _lift_state(id: int) -> Array:
	var auth := GameAuthority.instance
	if auth == null:
		return [false, 0.0]
	var st = auth.world_state.get("dungeon_lift", {}).get(str(id), [false, 0.0])
	return st if st is Array and st.size() >= 2 else [false, 0.0]


## 0 = at the bottom, 1 = at the top (eased), at time `now`.
func lift_frac(id: int, now: float) -> float:
	var st := _lift_state(id)
	var f := clampf((now - float(st[1])) / LIFT_TIME, 0.0, 1.0)
	return smoothstep(0.0, 1.0, f if bool(st[0]) else 1.0 - f)


func lift_moving(id: int, now: float) -> bool:
	return now - float(_lift_state(id)[1]) < LIFT_TIME


## Where the platform's origin is in the world now.
func lift_pos(id: int) -> Vector3:
	var th: Dictionary = db.things[id]
	var tr: Array = th.prop.travel
	var y := lerpf(float(tr[0]), float(tr[1]), lift_frac(id, Time.get_unix_time_from_system()))
	return (th.xform as Transform3D).origin + Vector3.UP * (y - float(tr[0]))


## The lift a winch or lever calls (the nearest one).
func lift_of(call_id: int) -> int:
	var c: Vector3 = db.things[call_id].centre
	var best := -1
	var near := 16.0
	for id in db.things:
		var th: Dictionary = db.things[id]
		if th.kind == "lift":
			var o: Vector3 = (th.xform as Transform3D).origin
			var dd := Vector2(c.x - o.x, c.z - o.z).length()
			if dd < near:
				best = id
				near = dd
	return best


## Calling from `at`: should the lift come up (true) or down (false)? (the end nearer `at`)
func lift_end_near(lift: int, at: Vector3) -> bool:
	var th: Dictionary = db.things[lift]
	var tr: Array = th.prop.travel
	var low := (th.xform as Transform3D).origin.y
	var high := low + float(tr[1]) - float(tr[0])
	return absf(at.y - high) < absf(at.y - low)


## Host: send the lift up or down (not while it is moving), for everyone (world_state: saved, sent to friends).
func send_lift(lift: int, up: bool, peer_id: int) -> void:
	var auth := GameAuthority.instance
	var now := Time.get_unix_time_from_system()
	if lift_moving(lift, now):
		auth.tell(peer_id, "The lift is moving.")
		return
	if lift_up(lift) == up:
		return
	var all: Dictionary = auth.world_state.get("dungeon_lift", {}).duplicate()
	all[str(lift)] = [up, now]
	auth.world_state["dungeon_lift"] = all
	print("MINE: the rope lift goes %s" % ("up" if up else "down"))
	auth._ev_state.rpc(auth.world_state)


## Everyone: the platform rides along its shaft; the hoist rope reaches up to the winch's drum, which turns.
func _move_lift(id: int, th: Dictionary, now: float) -> void:
	var tr: Array = th.prop.travel
	var f := lift_frac(id, now)
	var rise := (float(tr[1]) - float(tr[0])) * f
	var rest: Transform3D = th.rest
	(th.inst as Node3D).transform = Transform3D(rest.basis, rest.origin + Vector3.UP * rise)
	th.rise = rise  # (silent: owner, Nov 20, "definitely remove the sound from the lift")
	var winch := int(th.get("winch", -2))
	if winch == -2:  # (found once: the winch over this shaft)
		winch = -1
		for wid in db.things:
			var w: Dictionary = db.things[wid]
			if w.kind == "lift_call" and w.get("drum") != null and lift_of(wid) == id:
				winch = wid
		th.winch = winch
	var rope := th.get("rope") as MeshInstance3D
	if winch >= 0 and rope:
		var drum_y: float = (db.things[winch].xform as Transform3D).origin.y + LIFT_DRUM
		var foot_y: float = (th.xform as Transform3D).origin.y + rise + LIFT_RING
		var box := rope.get_aabb()
		var k := clampf((drum_y - foot_y) / maxf(box.size.y, 0.01), 0.02, 20.0)
		var rr: Transform3D = th.rope_rest
		var bottom := box.position.y
		rope.transform = Transform3D(rr.basis.scaled_local(Vector3(1.0, k, 1.0)), rr.origin + Vector3.UP * (bottom - bottom * k))
		var drum := db.things[winch].get("drum") as Node3D
		if drum:  # (it turns as the rope winds on: a 0.13 m drum)
			var dr: Transform3D = db.things[winch].drum_rest
			var turn := Transform3D(Basis(Vector3(0, 0, 1), rise / 0.13), Vector3.ZERO)
			var piv := Transform3D(Basis(), LIFT_DRUM_AXIS)
			drum.transform = piv * turn * piv.affine_inverse() * dr
