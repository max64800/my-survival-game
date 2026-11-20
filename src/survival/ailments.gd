class_name Ailments
extends RefCounted
## Poison, burn and chill on a dwarf or a creature (docs/design/gems.md, owner Nov 20).
##
## Like a cup filling up: each poisonous hit pours some "buildup" in. Every time the cup reaches
## 100 it tips over and adds one stack of the effect. If nothing pours in for 3 s, the cup
## slowly empties again (10 per second).
##  - Poison: 1 damage/s per stack for 10 s, up to 3 stacks; a new stack restarts the 10 s. No healing.
##  - Burn: 3 damage/s for 5 s (one stack, a new one restarts it). No healing.
##  - Chill: 10% slower per stack for 4 s, up to 5; the 5th stack = Frozen (can't move) 1.5 s.
##  - Fire removes chill, chill removes burn.

const FULL := 100.0
const DECAY := 10.0  ## buildup lost per second...
const DECAY_DELAY := 3.0  ## ...after this long with no new buildup
const EFFECTS := {
	"poison": {dps = 1.0, time = 10.0, max = 3, name = "Poisoned"},
	"burn": {dps = 3.0, time = 5.0, max = 1, name = "Burning"},
	"chill": {dps = 0.0, time = 4.0, max = 5, name = "Chilled"},
}
const FROZEN_TIME := 1.5
const CHILL_SLOW := 0.10  ## per stack

var buildup := {"poison": 0.0, "burn": 0.0, "chill": 0.0}
var active := {}  ## effect -> seconds left ("frozen" too)
var stacks := {}  ## effect -> how many stacks
var _quiet := {"poison": 999.0, "burn": 999.0, "chill": 999.0}


## Pour in some buildup. Returns the effect that just started or grew ("frozen" too), or "".
func add(kind: String, amount: float) -> String:
	if not buildup.has(kind) or amount <= 0.0:
		return ""
	buildup[kind] += amount
	_quiet[kind] = 0.0
	var started := ""
	while buildup[kind] >= FULL:
		buildup[kind] -= FULL
		started = _stack(kind)
	return started


func _stack(kind: String) -> String:
	var e: Dictionary = EFFECTS[kind]
	if kind == "burn":
		active.erase("chill")
		active.erase("frozen")
		stacks.erase("chill")
	elif kind == "chill":
		active.erase("burn")
		stacks.erase("burn")
	stacks[kind] = mini(int(stacks.get(kind, 0)) + 1, e.max)
	active[kind] = e.time
	if kind == "chill" and stacks[kind] >= e.max:
		active.erase("chill")
		stacks.erase("chill")
		active["frozen"] = FROZEN_TIME
		return "frozen"
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
		dmg += EFFECTS.get(k, {}).get("dps", 0.0) * stacks_of(k) * step
		active[k] -= delta
		if active[k] <= 0.0:
			active.erase(k)
			stacks.erase(k)
	return dmg


func has(effect: String) -> bool:
	return active.has(effect)


func stacks_of(effect: String) -> int:
	return int(stacks.get(effect, 0)) if active.has(effect) else 0


## Poison and burn stop natural healing.
func blocks_regen() -> bool:
	return active.has("poison") or active.has("burn")


## How fast you can move: 10% slower per chill stack, frozen 0.
func speed_mult() -> float:
	if active.has("frozen"):
		return 0.0
	return 1.0 - CHILL_SLOW * stacks_of("chill")


func clear() -> void:
	active.clear()
	stacks.clear()
	for k in buildup:
		buildup[k] = 0.0


## For the screen: "Poisoned x2 7 s", plus filling meters ("Poison 40%"). The HUD shows the effects as badges
## (AilmentBadges), so it asks only for the meters (`effects` false).
func describe(effects := true) -> Array[String]:
	var out: Array[String] = []
	for k in (active if effects else {}):
		var n := stacks_of(k)
		var name: String = "Frozen" if k == "frozen" else EFFECTS[k].name
		out.append("%s%s %d s" % [name, " x%d" % n if n > 1 else "", ceili(active[k])])
	for k in buildup:
		if buildup[k] >= 1.0:
			out.append("%s %d%%" % [k.capitalize(), int(buildup[k])])
	return out
