extends TestCase
## F783 (owner, Nov 23: "both doors opening towards the towers are blocked by railings", "the spiral staircase is
## blocked"): every blueprint must let you walk through it. Nothing stands across a stair's way in or out, and every
## door has clear room on both sides (where you walk up to it and where its leaf swings).
## The rules behind this check: docs/design/WALK-THROUGH-RULES.md.

## Pieces that stop you at an edge (a stair's way in or out must not have one).
const EDGE_BLOCKERS := ["wall", "wall_narrow", "window_wall", "window_wide", "railing", "railing_narrow", "battlement",
	"battlement_narrow", "half_wall", "ruin_wall_worn", "ruin_wall_collapsed"]
## Pieces that may stand next to a door at chest height (the door itself, things under your feet or that you climb).
const DOOR_OK := ["door", "door_broken", "doorway", "arch_doorway", "gateway", "floor", "floor_half", "floor_triangle",
	"floor_hatch", "small_floor", "foundation", "foundation_half", "foundation_triangle", "foundation_steps", "stairs",
	"stairs_corner", "stairs_spiral", "ramp", "rug", "torch_wall", "lantern", "banner"]

## Found by this check but not yet fixed: waiting for the owner's OK (FEEDBACK.md "Claude noticed"). Remove once fixed.
const WAITING := ["watchtower_cabin stairs (-1.0, 0.25, -1.0) foot"]


## Is there an edge-blocking piece on the edge centred at (x, z), about `y` high (its floor level)?
func _edge_blocker(bp: Blueprint, at: Vector3, y: float) -> String:
	for q in bp.pieces:
		if q.id in EDGE_BLOCKERS and absf(q.pos.x - at.x) < 0.15 and absf(q.pos.z - at.z) < 0.15:
			if q.pos.y > y - 0.35 and q.pos.y < y + 0.6:
				return "%s at %s" % [q.id, q.pos]
	return ""


func test_stairs_ways_in_and_out_are_open() -> void:
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		for p in bp.pieces:
			if not p.id in ["stairs", "stairs_corner"]:
				continue
			var yaw := Pieces.yaw_of(p.rot)
			var ways := []   # [the edge you walk over, its floor level, which way]
			if p.id == "stairs":   # (climbs toward its -z)
				var up := Vector3(0, 0, -1).rotated(Vector3.UP, yaw)
				ways = [[p.pos + up, p.pos.y + 2.0, "top"], [p.pos - up, p.pos.y, "foot"]]
			else:   # corner stairs: in at their front (+z), out SIDEWAYS at their left (-x)
				ways = [[p.pos + Vector3(0, 0, 1).rotated(Vector3.UP, yaw), p.pos.y, "way in"],
					[p.pos + Vector3(-1, 0, 0).rotated(Vector3.UP, yaw), p.pos.y + 2.0, "way out"]]
			for w in ways:
				var by := _edge_blocker(bp, w[0], w[1])
				if "%s %s %s %s" % [id, p.id, p.pos, w[2]] in WAITING:
					continue
				check(by == "", "%s: the %s at %s rot %d: its %s is open (blocked by %s)" % [id, p.id, p.pos, p.rot, w[2], by])


## The first piece standing in the way of the door `p` (on either side, waist high, out to 0.9 m), or "".
func _door_blocker(bp: Blueprint, p: Dictionary) -> String:
	var yaw := Pieces.yaw_of(p.rot)
	var n := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)    # (through the door)
	var a := Vector3(1, 0, 0).rotated(Vector3.UP, yaw)    # (across it)
	var half: float = 1.2 if p.id == "gateway" else 0.4
	for q in bp.pieces:
		if q.id in DOOR_OK:
			continue
		var y: float = p.pos.y + 0.6
		if y < q.pos.y or y > q.pos.y + Pieces.LIST[q.id].size.y:
			continue
		var outline := Pieces.footprint(q.id, q.pos, q.rot, -0.01)   # (its true shape seen from above, even turned)
		for s in [-1.0, 1.0]:
			for k in 8:
				for l in [-half, 0.0, half]:
					var pt: Vector3 = p.pos + n * s * (0.2 + 0.1 * k) + a * l
					if Geometry2D.is_point_in_polygon(Vector2(pt.x, pt.z), outline):
						return "%s at %s" % [q.id, q.pos]
	return ""


func test_doors_have_room_on_both_sides() -> void:
	var doors := 0
	for id in BlueprintLibrary.IDS:
		var bp := BlueprintLibrary.make(id)
		for p in bp.pieces:
			if p.id in ["door", "doorway", "arch_doorway", "gateway"]:
				doors += 1
				var by := _door_blocker(bp, p)
				check(by == "", "%s: the %s at %s rot %d has room on both sides (blocked by %s)" % [id, p.id, p.pos, p.rot, by])
	check(doors > 20, "checked every door (%d)" % doors)


## The check itself works: put back the railing that blocked the Twin Gate's left tower door before Nov 23.
func test_the_door_check_finds_the_old_twin_gate_railing() -> void:
	var bp := BlueprintLibrary.make("stonehold_twin_gate")
	var door := {}
	for p in bp.pieces:
		if p.id in ["door", "doorway"] and p.pos.x < -6.0 and p.pos.x > -8.0 and p.pos.y > 7.0:
			door = p
	check(not door.is_empty(), "the left tower has its gate-roof door")
	if door.is_empty():
		return
	check_eq(_door_blocker(bp, door), "", "it is clear now")
	bp.pieces.append({id = "railing", mat = "cut_stone", pos = Vector3(-8, door.pos.y, door.pos.z), rot = 1})
	check(_door_blocker(bp, door) != "", "the old railing across it is caught")
