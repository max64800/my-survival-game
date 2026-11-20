class_name FallDamage
extends RefCounted
## Falling hurts (Nov 20; Jumping ★100 is "no fall damage"). Runs on the player's own computer, like the rest of
## their body. Up to SAFE metres is free; every metre more costs PER_M health, so about 12 m kills (100 health).
## Ladders, slow climbs and jumps on flat ground never count: only time spent falling fast does.

const SAFE := 4.0
const PER_M := 12.0
const FAST := -3.0  ## m/s: falling faster than this is "falling" (a 4 m drop hits ~9 m/s)
const MIN_TIME := 0.2  ## seconds of fast falling needed (a teleport down, e.g. waking in bed, has none)

var _from := NAN  ## height where the current fall started
var _falling := 0.0  ## seconds spent falling fast


static func damage_for(drop: float) -> float:
	return maxf(0.0, drop - SAFE) * PER_M


## Call every frame. Returns how far the dwarf fell when he just landed after a real fall, else 0.
func step(y: float, on_floor: bool, vel_y: float, delta: float) -> float:
	var drop := 0.0
	if on_floor:
		if _falling >= MIN_TIME and not is_nan(_from):
			drop = maxf(0.0, _from - y) + FAST * FAST / 19.6  # + the slow first bit before it counted (~0.46 m)
		_from = y
		_falling = 0.0
	elif vel_y > FAST:  # climbing, the top of a jump, grabbing a ladder: the fall (if any) starts again from here
		_from = y
		_falling = 0.0
	else:
		if is_nan(_from):
			_from = y
		_falling += delta
	return drop
