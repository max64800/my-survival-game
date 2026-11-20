class_name Vitals
extends RefCounted
## A dwarf's body: health, stamina, hunger, thirst, and the food buffs (2 foods + 1 drink).
## Rules from docs/design/progression-and-economy.md section 6:
##  - Hunger/thirst drain slowly (empty after ~40 / ~36 minutes). Half speed while resting.
##  - You NEVER take damage or die from hunger or thirst. Low meters only slow healing
##    and, at zero, make you "tired" (less stamina).
##  - 2 food slots + 1 drink slot (owner, Nov 19). The same dish can't fill two slots (eating it again refreshes it).
##    A 4th dish replaces the one with the least time left. Buffs end when you die.

const BASE_HEALTH := 100.0
const BASE_STAMINA := 100.0
const HEALTH_REGEN := 0.2  ## per second: 1 health every 5 s on your own (owner, Nov 19); food adds "regen"
const REGEN_CAP := 0.5  ## zone 1's fastest healing: 1 health every 2 s (later zones raise it)
const FOOD_CAP := 0.5  ## each kind of food effect stops at 50% (two dishes add up)
const HEALTH_REGEN_DELAY := 6.0  ## seconds after being hurt
const STAMINA_REGEN := 25.0  ## per second
const STAMINA_REGEN_DELAY := 0.8  ## seconds after using stamina
const HUNGER_DRAIN := 2.5 / 60.0  ## per second
const THIRST_DRAIN := 2.8 / 60.0
const FOOD_SLOTS := 2  ## 2 foods + 1 drink work at the same time (owner, Nov 19)
const DRINK_SLOTS := 1
const UPSET_TIME := 180.0  ## "Upset Belly" lasts 3 minutes

var health := BASE_HEALTH
var god := false  ## dev god mode (F9, owner Nov 20): no damage, health stays full (not saved)
var stamina := BASE_STAMINA
var hunger := 100.0
var thirst := 100.0
var buffs: Array[Dictionary] = []  ## {id, time_left (seconds)}
var upset_time := 0.0
var cozy_time := 0.0  ## the "Cozy" rest buff (see Comfort): seconds left
var cozy_points := 0  ## how cozy the place was
var ailments := Ailments.new()  ## poison, burn, chill (only on the dwarf's own computer)
var gear := {}  ## gems in the worn armor (Gems.armor_bonus), kept fresh by the PlayerState
var progress: Progression = null  ## this dwarf's perks (set by PlayerState)
var effects := {}  ## timed effects from active perks: name -> {left (seconds), and numbers like damage_taken}
var in_dark := false  ## no light reaches you (Darkness): no healing, stamina costs 50% more (F293)
var friends_near := false  ## a friend within 10 m (Shoulder to Shoulder), set every frame on our computer
var unbreakable_cd := 0.0  ## Unbreakable perk: seconds until it can save you again
var second_wind_cd := 0.0  ## Running ★100: seconds until Second Wind works again
var _since_damage := 999.0
var _since_stamina := 999.0


# ---------------------------------------------------------------- numbers

func buff_total(key: String) -> float:
	var t := 0.0
	for b in buffs:
		t += Foods.buff_of(b.id).get(key, 0.0)
	if key != "regen":
		t = clampf(t, -FOOD_CAP, FOOD_CAP)
	for e in effects.values():
		t += e.get(key, 0.0)
	return t


func _rank(id: String) -> int:
	return progress.perk_rank(id) if progress else 0


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
	return BASE_HEALTH * (1.0 + buff_total("max_health")) + (progress.max_health_bonus() if progress else 0.0)


func max_stamina() -> float:
	return (BASE_STAMINA * (1.0 + buff_total("max_stamina")) + (progress.max_stamina_bonus() if progress else 0.0)) * (0.8 if is_tired() else 1.0)


## Health back per second right now: on your own 1 every 5 s, food speeds it up to the zone's cap.
func regen_per_second() -> float:
	return minf(REGEN_CAP, HEALTH_REGEN + buff_total("regen")) * health_regen_mult()


func health_regen_mult() -> float:
	var cozy := (Comfort.HEALTH_MULT if cozy_time > 0.0 else 1.0) * (1.0 + (progress.health_regen_bonus() if progress else 0.0) + float(gear.get("heal", 0.0)))  # Blood Ruby armor
	match status():
		"well_fed": return 1.2 * cozy
		"peckish": return 0.75 * cozy
		"starving": return 0.4 * cozy
	return cozy


## Resting somewhere cozy: the buff starts (or refreshes) at the place's comfort.
func set_cozy(points: int) -> void:
	if points <= 0:
		return
	cozy_points = points
	cozy_time = maxf(cozy_time, Comfort.duration(points))


func stamina_regen_mult() -> float:
	var m := 1.0 + buff_total("stamina_regen") + float(gear.get("stamina_regen", 0.0))  # Wind Amethyst armor
	if _since_damage < 10.0:
		m += _rank("battle_breath") * 0.10  # Battle Breath: a fight is on
	if friends_near:
		m += _rank("shoulder_to_shoulder") * 0.05
	if cozy_time > 0.0:
		m += Comfort.STAMINA_PER_POINT * cozy_points
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
	cozy_time = maxf(0.0, cozy_time - delta)
	unbreakable_cd = maxf(0.0, unbreakable_cd - delta)
	second_wind_cd = maxf(0.0, second_wind_cd - delta)
	if stamina <= 0.5 and second_wind_cd <= 0.0 and progress and progress.has_star("running", 100):
		stamina = max_stamina() * 0.25  # Running ★100 Second Wind: out of stamina, a quarter comes back (every 2 min)
		second_wind_cd = 120.0
	for k in effects.keys():
		effects[k].left -= delta
		if effects[k].left <= 0.0:
			effects.erase(k)
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i].time_left -= delta
		if buffs[i].time_left <= 0.0:
			buffs.remove_at(i)
	var dot := ailments.tick(delta)
	if god:
		dot = 0.0
		health = max_health()  # (and no starving, poison or bleeding down either)
	if dot > 0.0:
		health = maxf(0.0, health - dot)
	if _since_damage >= HEALTH_REGEN_DELAY and not ailments.blocks_regen() and not in_dark:
		health += regen_per_second() * delta
	if _since_stamina >= STAMINA_REGEN_DELAY:
		stamina += STAMINA_REGEN * stamina_regen_mult() * delta
	health = minf(health, max_health())
	stamina = minf(stamina, max_stamina())


# ---------------------------------------------------------------- actions

## Spends stamina for one action (a swing, a jump). False = too tired, don't do it.
## In the dark it costs 50% more (it still happens if you have the normal cost).
func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina = maxf(0.0, stamina - amount * (Darkness.STAMINA_MULT if in_dark else 1.0))
	_since_stamina = 0.0
	return true


## Drains stamina for something you keep doing (running). False = ran out.
func drain_stamina(per_second: float, delta: float) -> bool:
	if stamina <= 0.0:
		return false
	stamina = maxf(0.0, stamina - per_second * delta * (Darkness.STAMINA_MULT if in_dark else 1.0))
	_since_stamina = 0.0
	return true


## Returns true if this killed the dwarf.
func take_damage(amount: float) -> bool:
	if god:
		return false  # dev god mode (F9): nothing hurts you
	var real := amount * maxf(0.0, 1.0 + buff_total("damage_taken"))
	if _rank("berserker") > 0 and health < max_health() * 0.3:
		real *= 0.9
	health = maxf(0.0, health - real)
	if health <= 0.0 and real > 0.0 and _rank("unbreakable") > 0 and unbreakable_cd <= 0.0:
		health = 1.0  # Unbreakable: a killing hit leaves you standing, once every 10 minutes
		unbreakable_cd = 600.0
	_since_damage = 0.0
	return health <= 0.0


## Poison / burn / chill building up on you, after perks and Clan Banner resist. Returns what started ("" = nothing).
func add_ailment(kind: String, amount: float) -> String:
	var resist := (progress.ailment_resist(kind) if progress else 0.0) + buff_total("resist_" + kind) + float(gear.get("resist_" + kind, 0.0))
	return ailments.add(kind, amount * maxf(0.1, 1.0 - resist))


## A timed effect from an active perk (the host sends it). The same name again refreshes it.
func add_effect(name: String, data: Dictionary, seconds: float) -> void:
	var e := data.duplicate()
	e.left = seconds
	effects[name] = e


## Eats or drinks an item. Returns false if it isn't food or drink.
## `roll` (0..1) decides bad luck like an upset belly; pass randf() in the game.
func consume(item_id: String, roll: float = 1.0) -> bool:
	var info := Items.info(item_id)
	var k: String = info.get("kind", "")
	if k != "food" and k != "drink":
		return false
	hunger = minf(100.0, hunger + info.get("hunger", 0))
	thirst = minf(100.0, thirst + info.get("thirst", 0))
	health = minf(max_health(), health + info.get("heal", 0) * (1.0 + gear.get("heal", 0.0)))  # a Moss Bandage (Blood Ruby armor)
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
	var drink := Foods.is_drink(id)
	var same := []  # slots of the same sort (foods or drinks)
	for i in buffs.size():
		if Foods.is_drink(buffs[i].id) == drink:
			same.append(i)
	if same.size() >= (DRINK_SLOTS if drink else FOOD_SLOTS):
		var weakest: int = same[0]
		for i in same:
			if buffs[i].time_left < buffs[weakest].time_left:
				weakest = i
		buffs.remove_at(weakest)
	buffs.append({id = id, time_left = seconds})


## Dying clears buffs and refills the body (you wake at your bed).
func respawn() -> void:
	buffs.clear()
	cozy_time = 0.0
	ailments.clear()
	for k in effects.keys():
		if not k.begins_with("cd_"):  # perk buffs end, ability recharges keep counting
			effects.erase(k)
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
