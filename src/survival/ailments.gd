class_name Ailments
extends RefCounted
## Poison, burn and chill on a dwarf (combat doc 2.6).
##
## Like a cup filling up: each poisonous hit pours some "buildup" in. When the cup reaches
## 100 it tips over and you're Poisoned for a while. If nothing pours in for 3 s, the cup
## slowly empties again (10 per second).
##  - Poisoned: 3 damage/s for 10 s, no healing.  Burn: 5 damage/s for 4 s, no healing.
##  - Chill: 25% slower for 4 s. Getting chilled again while chilled = Frozen (can't move) 1.5 s.
##  - Fire removes chill, chill removes burn. Effects refresh; they don't stack.

const FULL := 100.0
const DECAY := 10.0  ## buildup lost per second...
const DECAY_DELAY := 3.0  ## ...after this long with no new buildup
const EFFECTS := {
	"poison": {dps = 3.0, time = 10.0, name = "Poisoned"},
	"burn": {dps = 5.0, time = 4.0, name = "Burning"},
	"chill": {dps = 0.0, time = 4.0, name = "Chilled"},
}
const FROZEN_TIME := 1.5
const CHILL_SLOW := 0.25

var buildup := {"poison": 0.0, "burn": 0.0, "chill": 0.0}
var active := {}  ## effect -> seconds left ("frozen" too)
var _quiet := {"poison": 999.0, "burn": 999.0, "chill": 999.0}


## Pour in some buildup. Returns the effect that just started, or "".
func add(kind: String, amount: float) -> String:
	if not buildup.has(kind) or amount <= 0.0:
		return ""
	buildup[kind] += amount
	_quiet[kind] = 0.0
	if buildup[kind] < FULL:
		return ""
	buildup[kind] = 0.0
	if kind == "chill" and active.has("chill"):
		active["frozen"] = FROZEN_TIME
		return "frozen"
	active[kind] = EFFECTS[kind].time
	if kind == "burn":
		active.erase("chill")
		active.erase("frozen")
	elif kind == "chill":
		active.erase("burn")
	return kind


## Time passes. Returns the damage over time for this step.
func tick(delta: float) -> float:
	var dmg := 0.0
	for k in buildup:
		_quiet[k] += delta
		if _quiet[k] > DECAY_DELAY:
			buildup[k] = maxf(0.0, buildup[k] - DECAY * delta)
	for k in active.keys():
		var step := minf(delta, active[k])
		dmg += EFFECTS.get(k, {}).get("dps", 0.0) * step
		active[k] -= delta
		if active[k] <= 0.0:
			active.erase(k)
	return dmg


func has(effect: String) -> bool:
	return active.has(effect)


## Poison and burn stop natural healing.
func blocks_regen() -> bool:
	return active.has("poison") or active.has("burn")


## How fast you can move: chilled 75%, frozen 0.
func speed_mult() -> float:
	if active.has("frozen"):
		return 0.0
	return 1.0 - CHILL_SLOW if active.has("chill") else 1.0


func clear() -> void:
	active.clear()
	for k in buildup:
		buildup[k] = 0.0


## For the screen: "Poisoned 7 s", plus filling meters ("Poison 40%").
func describe() -> Array[String]:
	var out: Array[String] = []
	for k in active:
		out.append("%s %d s" % ["Frozen" if k == "frozen" else EFFECTS[k].name, ceili(active[k])])
	for k in buildup:
		if buildup[k] >= 1.0 and not active.has(k):
			out.append("%s %d%%" % [k.capitalize(), int(buildup[k])])
	return out
