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
##   dart_wall     the wall with the hole (fired by its tripwire).
##   chest_spikes  the vault's spike floor: stand on it a moment (to open the chest) and the spikes slam up. Shoot the
##                 chest (or the floor) first: they slam up harmlessly and stay down.

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
const DART_LINE := 0.6        ## m from the bolt's line that it hits you
const DART_HOLE := Vector3(0.12, 0.95, 0.15)  ## the hole, in the dart wall model
const SPIKE_STAND := 0.35     ## seconds on the spike floor before it fires
const SPIKE_DEPTH := 0.62     ## the spikes wait this far down
const SPIKE_DAMAGE := 30.0

var db: DungeonBuild
var _cart_hit := {}   ## host: "cart id:peer" -> true (a cart hits you once)
var _swing_hit := {}  ## host: peer -> _clock when a boulder last hit them
var _swing_mon := {}  ## host: creature uid -> _clock when a boulder last threw it
var _held := {}       ## host: jaws id -> {peer, until}
var _on_spikes := {}  ## host: spike floor id -> seconds someone has stood on it
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
		"dungeon/tripwire.glb":
			return "tripwire"
		"dungeon/trap_tripwire_wall.glb":
			return "dart_wall"
		"dungeon/trap_chest_spikes.glb":
			return "chest_spikes"
	return ""


## Kinds whose body melee hits do nothing to (the tripwire can be cut; bolts are handled in on_hit).
const NO_MELEE := ["lamp", "cart", "wedge", "swing", "dart_wall", "chest_spikes"]


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
		"chest_spikes":
			th.gone = true
			_slam_spikes(th)
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
	var near := 4.5
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


## Host: the wire was walked into: it snaps and the dart fires (whoever is in its line is hit).
func _trip(wire_id: int, auth: GameAuthority) -> void:
	db._break(wire_id)
	var dart := _dart_of(wire_id)
	if dart < 0 or db.is_broken(dart):
		return
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
			print("MINE: player %d hit by the dart" % pid)
			auth.hurt(pid, DART_DAMAGE, {poison = DART_POISON})
			auth.tell(pid, "A poisoned dart shoots out of the wall!")


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


func _fire_spikes(id: int, auth: GameAuthority) -> void:
	if db.is_broken(id):
		return
	db._break(id)
	var th: Dictionary = db.things[id]
	print("MINE: the vault's spikes slam up")
	await db.get_tree().create_timer(0.12).timeout
	for pid in auth.players:
		var node: Node3D = auth.players[pid].node
		if node and on_spike_floor(th, node.global_position):
			auth.hurt(pid, SPIKE_DAMAGE)
			auth.tell(pid, "Spikes shoot up out of the floor!")


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
			"jaws":
				print("MINE: bear jaws sprung by a bolt")
				db._break(id)  # (they snap shut on nothing)
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
	return {}


## Host: a player's E on our thing. Returns true if it was ours.
func request_use(peer_id: int, id: int) -> bool:
	var auth := GameAuthority.instance
	var ps := auth.get_player(peer_id) if auth else null
	var th: Dictionary = db.things.get(id, {})
	if th.is_empty() or not String(th.kind) in ["lamp", "jaws"]:
		return false
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
			"tripwire":
				var q := (th.xform as Transform3D).affine_inverse() * p
				if absf(q.x) < 0.5 and absf(q.z) < WIRE_REACH and q.y < WIRE_HIGH and q.y > -0.6:
					print("MINE: player %d walked into the tripwire" % pid)
					_trip(id, auth)
			"chest_spikes":
				if on_spike_floor(th, p):
					_on_spikes[id] = float(_on_spikes.get(id, 0.0)) + step
					if _on_spikes[id] >= SPIKE_STAND:
						_on_spikes.erase(id)
						_fire_spikes(id, auth)
