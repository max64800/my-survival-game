class_name Vitals
extends RefCounted
## A dwarf's body: health, stamina, hunger, thirst, and the 3 buff-food slots.
## Rules from docs/design/progression-and-economy.md section 6:
##  - Hunger/thirst drain slowly (empty after ~40 / ~36 minutes). Half speed while resting.
##  - You NEVER take damage or die from hunger or thirst. Low meters only slow healing
##    and, at zero, make you "tired" (less stamina).
##  - 3 buff slots. The same dish can't fill two slots (eating it again refreshes it).
##    A 4th dish replaces the one with the least time left. Buffs end when you die.

const BASE_HEALTH := 100.0
const BASE_STAMINA := 100.0
const HEALTH_REGEN := 2.0  ## per second
const HEALTH_REGEN_DELAY := 6.0  ## seconds after being hurt
const STAMINA_REGEN := 25.0  ## per second
const STAMINA_REGEN_DELAY := 0.8  ## seconds after using stamina
const HUNGER_DRAIN := 2.5 / 60.0  ## per second
const THIRST_DRAIN := 2.8 / 60.0
const BUFF_SLOTS := 3
const UPSET_TIME := 180.0  ## "Upset Belly" lasts 3 minutes

var health := BASE_HEALTH
var stamina := BASE_STAMINA
var hunger := 100.0
var thirst := 100.0
var buffs: Array[Dictionary] = []  ## {id, time_left (seconds)}
var upset_time := 0.0
var ailments := Ailments.new()  ## poison, burn, chill (only on the dwarf's own computer)
var _since_damage := 999.0
var _since_stamina := 999.0


# ---------------------------------------------------------------- numbers

func buff_total(key: String) -> float:
	var t := 0.0
	for b in buffs:
		t += Foods.buff_of(b.id).get(key, 0.0)
	return t


## "well_fed", "normal", "peckish" or "starving" (the worse of hunger and thirst counts).
func status() -> String:
	var low := minf(hunger, thirst)
	if low <= 0.0:
		return "starving"
	if low <= 25.0:
		return "peckish"
	if low >= 75.0:
		return "well_fed"
	return "normal"


func is_tired() -> bool:
	return status() == "starving"


func max_health() -> float:
	return BASE_HEALTH * (1.0 + buff_total("max_health"))


func max_stamina() -> float:
	return BASE_STAMINA * (1.0 + buff_total("max_stamina")) * (0.8 if is_tired() else 1.0)


func health_regen_mult() -> float:
	match status():
		"well_fed": return 1.2
		"peckish": return 0.75
		"starving": return 0.4
	return 1.0


func stamina_regen_mult() -> float:
	var m := 1.0 + buff_total("stamina_regen")
	if is_tired():
		m *= 0.7
	if upset_time > 0.0:
		m *= 0.75
	return m


# ---------------------------------------------------------------- time passing

func tick(delta: float, resting: bool = false) -> void:
	var drain := 0.5 if resting else 1.0
	hunger = maxf(0.0, hunger - HUNGER_DRAIN * delta * drain)
	thirst = maxf(0.0, thirst - THIRST_DRAIN * delta * drain)
	_since_damage += delta
	_since_stamina += delta
	upset_time = maxf(0.0, upset_time - delta)
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i].time_left -= delta
		if buffs[i].time_left <= 0.0:
			buffs.remove_at(i)
	var dot := ailments.tick(delta)
	if dot > 0.0:
		health = maxf(0.0, health - dot)
	if _since_damage >= HEALTH_REGEN_DELAY and not ailments.blocks_regen():
		health += HEALTH_REGEN * health_regen_mult() * delta
	if _since_stamina >= STAMINA_REGEN_DELAY:
		stamina += STAMINA_REGEN * stamina_regen_mult() * delta
	health = minf(health, max_health())
	stamina = minf(stamina, max_stamina())


# ---------------------------------------------------------------- actions

## Spends stamina for one action (a swing, a jump). False = too tired, don't do it.
func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	_since_stamina = 0.0
	return true


## Drains stamina for something you keep doing (running). False = ran out.
func drain_stamina(per_second: float, delta: float) -> bool:
	if stamina <= 0.0:
		return false
	stamina = maxf(0.0, stamina - per_second * delta)
	_since_stamina = 0.0
	return true


## Returns true if this killed the dwarf.
func take_damage(amount: float) -> bool:
	var real := amount * maxf(0.0, 1.0 + buff_total("damage_taken"))
	health = maxf(0.0, health - real)
	_since_damage = 0.0
	return health <= 0.0


## Eats or drinks an item. Returns false if it isn't food or drink.
## `roll` (0..1) decides bad luck like an upset belly; pass randf() in the game.
func consume(item_id: String, roll: float = 1.0) -> bool:
	var info := Items.info(item_id)
	var k: String = info.get("kind", "")
	if k != "food" and k != "drink":
		return false
	hunger = minf(100.0, hunger + info.get("hunger", 0))
	thirst = minf(100.0, thirst + info.get("thirst", 0))
	if roll < info.get("upset", 0.0):
		upset_time = UPSET_TIME
	if Foods.is_buff_food(item_id):
		_add_buff(item_id)
	return true


func _add_buff(id: String) -> void:
	var seconds := Foods.minutes_of(id) * 60.0
	for b in buffs:
		if b.id == id:
			b.time_left = seconds  # same dish again: just refresh
			return
	if buffs.size() >= BUFF_SLOTS:
		var weakest := 0
		for i in buffs.size():
			if buffs[i].time_left < buffs[weakest].time_left:
				weakest = i
		buffs.remove_at(weakest)
	buffs.append({id = id, time_left = seconds})


## Dying clears buffs and refills the body (you wake at your bed).
func respawn() -> void:
	buffs.clear()
	ailments.clear()
	upset_time = 0.0
	health = max_health()
	stamina = max_stamina()
	hunger = maxf(hunger, 50.0)
	thirst = maxf(thirst, 50.0)


func is_dead() -> bool:
	return health <= 0.0


# ---------------------------------------------------------------- network

func to_data() -> Dictionary:
	return {h = health, s = stamina, hu = hunger, th = thirst, b = buffs.duplicate(true), u = upset_time}


func load_data(d: Dictionary) -> void:
	health = d.h
	stamina = d.s
	hunger = d.hu
	thirst = d.th
	buffs.assign(d.b)
	upset_time = d.u
