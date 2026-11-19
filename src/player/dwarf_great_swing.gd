class_name DwarfGreatSwing
extends RefCounted
## How the dwarf holds and swings the great axe and the great maul (F389 round 5, owner Nov 19, from a photo of a
## warrior with a long axe and the "Dwarf Fighting Poses" page): hand-made key poses, no animation pack.
##  - The LEFT fist always sits at the very end of the handle (the hinge). The RIGHT fist sits higher up the handle,
##    wide apart (owner: "his hands should be wide; the only time they get close is the slam").
##  - Each key pose says where the left fist is, which way the handle points from it, how far up the right fist sits,
##    and how far his chest twists and leans. DwarfFist bends both arms to reach the fists (two-bone reach) and lays
##    the handle through them.
##  - His arms are short (44 cm from shoulder to fist) and his chest is round, so where the right fist can't reach
##    its spot, it slides down the handle toward the left one, like a real fighter's top hand.
## Body coordinates: metres from the chest bone (spine_03), x = his right, y = up, z = his front, in the chest's own
## frame after the twist (+ = chest turned to his right) and the lean (+ = bent forward).
## Swings (owner's pick): A slanting chop from his right shoulder down past his left knee, B a rising sweep back out
## to his right, C a slower overhead slam (the right hand slides down to the left). They take turns A, B, C.
## By the dwarf-animations Claude, chat 6, Nov 19, 2026.

## The ready stance (the owner's photo): left fist low by his left hip, right fist up in front of his right shoulder,
## the handle slanting across his body with the head beside his right shoulder, blade facing forward.
## Fists out in front of his shoulders, past his belly (owner, Nov 19: "he holds his arms inside his belly").
const STANCE := {l = Vector3(-0.20, -0.20, 0.36), d = Vector3(0.40, 0.30, 0.0), gap = 0.42, twist = 0.0, lean = 0.0,
	edge = Vector3(0, 0.2, 1)}

## The swings: [time (share of the swing, 0..1), pose]. The first key is wherever he is when the swing starts.
## The hit lands at 0.4 (DwarfFight._impact). After the last key he eases back to the stance (RETURN).
## `edge` = which way the blade faces (the way the head moves at that moment).
const MOVES := {
	# Numbers found by tools/asset_forge/great_pose_tuner.gd (handle 4+ cm clear of his body, fists on their spots,
	# head where the swing should put it), chat 7. His arms are short, so the chest turns hard to his left in the chop
	# and the handle points out from his chest's right side: that is forward and to his left once he has turned.
	"Chop": [  # A: right shoulder -> down in front of his left knee
		[0.28, {l = Vector3(0.00, -0.22, 0.16), d = Vector3(0.35, 0.72, -0.60), gap = 0.33, twist = -31.7, lean = 9.2,
			edge = Vector3(0.1, -0.4, 0.9)}],
		[0.40, {l = Vector3(-0.07, 0.06, 0.24), d = Vector3(0.97, -0.18, 0.16), gap = 0.43, twist = -74.4, lean = 17.9,
			edge = Vector3(0.4, -0.4, 0.8)}],
		[0.58, {l = Vector3(-0.16, 0.04, 0.16), d = Vector3(0.84, -0.19, 0.50), gap = 0.31, twist = -75.0, lean = 19.1,
			edge = Vector3(-0.7, -0.1, 0.7)}],
		[1.00, {l = Vector3(-0.22, 0.03, 0.09), d = Vector3(0.77, -0.25, 0.58), gap = 0.31, twist = -75.0, lean = 14.3,
			edge = Vector3(-1.0, -0.1, 0.2)}],
	],
	"Sweep": [  # B: from low on his left, back up and out to his right, flatter, hands apart
		[0.25, {l = Vector3(-0.13, 0.07, 0.17), d = Vector3(0.83, -0.13, 0.53), gap = 0.34, twist = -69.6, lean = 23.2,
			edge = Vector3(0.4, 0.1, -0.9)}],
		[0.40, {l = Vector3(-0.15, 0.20, 0.24), d = Vector3(0.96, -0.07, 0.28), gap = 0.38, twist = -46.7, lean = 19.0,
			edge = Vector3(0.3, 0.0, -1.0)}],
		[0.58, {l = Vector3(-0.26, -0.01, 0.33), d = Vector3(0.98, 0.11, 0.16), gap = 0.37, twist = 9.2, lean = 5.9,
			edge = Vector3(0.8, 0.1, -0.6)}],
		[1.00, STANCE],
	],
	"Slam": [  # C: the axe up behind his head, then down into the ground ahead; the right hand slides down
		[0.30, {l = Vector3(0.01, 0.14, 0.14), d = Vector3(0.15, 0.59, -0.79), gap = 0.33, twist = -45.0, lean = 13.1,
			edge = Vector3(0.3, -0.6, 0.8)}],
		[0.42, {l = Vector3(0.16, 0.02, 0.32), d = Vector3(0.89, -0.22, 0.41), gap = 0.14, twist = -61.1, lean = 31.7,
			edge = Vector3(0.5, -0.4, 0.8)}],
		[0.70, {l = Vector3(0.16, 0.02, 0.32), d = Vector3(0.85, -0.24, 0.47), gap = 0.12, twist = -54.9, lean = 26.7,
			edge = Vector3(0.0, -1.0, 0.3)}],
		[1.00, STANCE],
	],
}
const RETURN := 6.0  ## how fast he eases back to the stance after a swing (per second)


## A pose part of the way from `a` to `b` (k 0..1).
static func blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	return {l = (a.l as Vector3).lerp(b.l, k), d = (a.d as Vector3).normalized().slerp((b.d as Vector3).normalized(), k),
		gap = lerpf(a.gap, b.gap, k), twist = lerpf(a.twist, b.twist, k), lean = lerpf(a.lean, b.lean, k),
		edge = (a.edge as Vector3).normalized().slerp((b.edge as Vector3).normalized(), k)}


## The pose `t` (0..1) into a swing that started from `from`.
static func pose(move: String, t: float, from: Dictionary) -> Dictionary:
	var keys: Array = MOVES.get(move, [])
	var prev_t := 0.0
	var prev := from
	for key: Array in keys:
		var kt: float = key[0]
		if t <= kt:
			var k := clampf((t - prev_t) / maxf(kt - prev_t, 0.001), 0.0, 1.0)
			return blend(prev, key[1], k * k * (3.0 - 2.0 * k))  # (eased: slow at each key, fast between)
		prev_t = kt
		prev = key[1]
	return prev
