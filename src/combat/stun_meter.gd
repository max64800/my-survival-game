class_name StunMeter
extends RefCounted
## A monster's stun meter (doc 2.5). Parries and heavy hits fill it. Full = dazed.
## It slowly drains if left alone, and after a stun the monster can't be stunned again for 2 s.

var max_value := 100.0
var value := 0.0
var stun_time := 3.0  ## how long a stun lasts (3 s monsters, 4 side bosses, 5 main bosses)
var is_boss := false
var stunned_left := 0.0
var immune_left := 0.0
var decay_mult := 1.0  ## pack leaders' members drain ×2 faster
var _since_fill := 999.0
var _crush_used := false


func _init(p_max: float = 100.0, p_time: float = 3.0, boss: bool = false) -> void:
	max_value = p_max
	stun_time = p_time
	is_boss = boss


func is_stunned() -> bool:
	return stunned_left > 0.0


## Adds stun. Returns true if this knocked it out.
func add(amount: float) -> bool:
	if is_stunned() or immune_left > 0.0 or amount <= 0.0:
		return false
	value += amount
	_since_fill = 0.0
	if value >= max_value:
		value = 0.0
		stunned_left = stun_time
		_crush_used = false
		if is_boss:
			max_value *= 1.3  # bosses get harder to stun each time
		return true
	return false


## The first heavy attack on a stunned enemy is a Crush (×2). Returns true only once per stun.
func take_crush() -> bool:
	if is_stunned() and not _crush_used:
		_crush_used = true
		return true
	return false


func tick(delta: float) -> void:
	if stunned_left > 0.0:
		stunned_left -= delta
		if stunned_left <= 0.0:
			stunned_left = 0.0
			immune_left = Combat.STUN_IMMUNE_AFTER
		return
	immune_left = maxf(0.0, immune_left - delta)
	_since_fill += delta
	if _since_fill >= Combat.STUN_DECAY_DELAY:
		value = maxf(0.0, value - Combat.STUN_DECAY * decay_mult * delta)


func fraction() -> float:
	return 1.0 if is_stunned() else value / max_value
