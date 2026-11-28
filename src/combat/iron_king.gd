class_name IronKing
extends Node3D
## The Iron King (F981, owner Nov 28; design: docs/design/combat-and-monsters.md 8.2). Step 1, the MOVES TEST:
## "keep the moves, swap the body". He is a dwarf model (DwarfModel: the dwarf's own skeleton and the moves the owner
## already OK'd on it), twice the dwarf's size, wearing the plate armour painted dark iron as a STAND-IN for his own
## hand-built armour (next step: spiky crown, mist beard, cloak). The ghost shows through: his face and hands glow
## pale green (the ghost shader), and every attack lights a green glow on the weapon during its wind-up (the warning).
##
## No retargeting anywhere (ANIMATION-RULES.md): every move here already plays on the dwarf's skeleton by the names
## the game uses (DwarfRig.ANIMS). Only looks: the fight brain (host picks, everyone sees) comes after the owner's OK.

const SIZE := 2.0  ## x the dwarf (1.3 m with a helmet) = about 2.6 m (owner's pick)
const WEAR := ["armor_head_bronze", "armor_chest_bronze", "armor_legs_bronze", "armor_feet_bronze"]
const IRON := Color(0.42, 0.43, 0.46)  ## multiplies the bronze pictures: dark, cold iron
const GLOW := Color(0.55, 1.0, 0.72)  ## his ghost light
const HAMMER := "mace_bronze"  ## (stand-in: the warhammer is made with his armour)
const SHIELD := "shield_bronze"
const AXE := "axe_2h_bronze"
## Each attack: [weapon set, how long the whole swing takes (s), the move, its name on the sign]. The blow lands at
## 0.40 of the swing (DwarfOneSwing.HIT_AT / DwarfGreatSwing), so the wind-up (the green glow) is 0.40 x the time.
const ATTACKS := {
	"bash": ["shield", 1.1, "Shield Bash"],
	"charge": ["shield", 1.3, "Shield Charge"],
	"slam": ["shield", 1.6, "Hammer Slam"],
	"chop": ["axe", 1.5, "Greataxe Chop"],
	"spin": ["axe", 2.2, "Greataxe Spin"],
}
const HIT_AT := 0.4
const CHARGE_RUN := 5.0  ## m he runs during the Shield Charge (the show only)

var dm: DwarfModel
var weapons := ""  ## "shield" (hammer + shield) or "axe" (greataxe)
var busy := 0.0  ## s the attack still plays
var _glow: OmniLight3D
var _glow_t := 0.0  ## s left of the warning glow
var _glow_len := 0.0
var _charge := 0.0  ## s left of the charge's run
var _charge_speed := 0.0


func _init() -> void:
	name = "IronKing"
	scale = Vector3.ONE * SIZE
	dm = DwarfModel.new()
	dm.name = "King"
	add_child(dm)
	dm.ready.connect(_dress, CONNECT_ONE_SHOT)


func _dress() -> void:
	if dm.dwarf_rig == null:
		return
	var before := {}  # (the armour's meshes are moved onto the skeleton when he puts it on: the new ones are the armour)
	for mi: MeshInstance3D in dm.find_children("*", "MeshInstance3D", true, false):
		before[mi] = true
	dm.dwarf_rig.set_wear(WEAR)
	# Everything that isn't armour (face, beard, hands) is the ghost inside: dark, with a pale green glow.
	var ghost := StandardMaterial3D.new()
	ghost.albedo_color = Color(0.05, 0.08, 0.07)
	ghost.emission_enabled = true
	ghost.emission = GLOW
	ghost.emission_energy_multiplier = 0.2
	ghost.rim_enabled = true
	ghost.rim = 1.0
	ghost.rim_tint = 0.0
	ghost.roughness = 1.0
	for mi: MeshInstance3D in dm.find_children("*", "MeshInstance3D", true, false):
		if dm.dwarf_rig.grip.is_ancestor_of(mi) or dm.dwarf_rig.shield_grip.is_ancestor_of(mi) or not mi.visible:
			continue
		if not before.has(mi) and not String(mi.name).begins_with("armor_head_hair"):
			_paint_iron(mi)
		else:
			mi.material_override = ghost
	_glow = OmniLight3D.new()
	_glow.light_color = GLOW
	_glow.omni_range = 1.6
	_glow.light_energy = 0.0
	dm.dwarf_rig.grip.add_child(_glow)
	_glow.position = Vector3(0, 0.6, 0)
	arm("shield")


## The bronze plate pictures, darkened and cooled to old iron (a copy of each paint, so the player's armour stays bronze).
static func _paint_iron(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	if mi.material_override is StandardMaterial3D:
		mi.material_override = _iron_of(mi.material_override)
		return
	for s in mi.mesh.get_surface_count():
		var m := mi.get_active_material(s)
		if m is StandardMaterial3D:
			mi.set_surface_override_material(s, _iron_of(m))


static func _iron_of(m: StandardMaterial3D) -> StandardMaterial3D:
	var iron := m.duplicate() as StandardMaterial3D
	iron.albedo_color = m.albedo_color * IRON
	iron.metallic = 0.55
	iron.roughness = maxf(iron.roughness, 0.62)
	return iron


## Phase 1: hammer + shield. Phase 2: the greataxe (two hands, no shield).
func arm(which: String) -> void:
	weapons = which
	if dm.dwarf_rig == null:
		return
	if which == "axe":
		dm.set_shield("")
		dm.set_held(AXE)
	else:
		dm.set_held(HAMMER)
		dm.set_shield(SHIELD)
	_iron_weapons.call_deferred()


func _iron_weapons() -> void:
	for g: Node in [dm.dwarf_rig.grip, dm.dwarf_rig.shield_grip]:
		for mi: MeshInstance3D in g.find_children("*", "MeshInstance3D", true, false):
			_paint_iron(mi)


## Plays one attack (ATTACKS): the green warning glow on the weapon during the wind-up, then the blow at 0.40.
func attack(what: String, run := CHARGE_RUN) -> void:
	var a: Array = ATTACKS[what]
	if a[0] != weapons:
		arm(a[0])
	var t: float = a[1]
	busy = t
	_glow_t = t * HIT_AT
	_glow_len = _glow_t
	match what:
		"bash":
			dm.attack(t, false, -1, "shield")
		"slam":
			dm.attack(t, true, -1, "mace")
		"charge":
			dm.dwarf_rig.play_full("b/Shield_Dash", t)
			_charge = t * 0.55
			_charge_speed = run / _charge
		"chop":
			dm.attack(t, false, 0)
		"spin":
			dm.attack(t, true)


func _process(delta: float) -> void:
	busy = maxf(0.0, busy - delta)
	if _glow:
		# grows brighter through the wind-up, flashes at the blow, then fades
		if _glow_t > 0.0:
			_glow_t -= delta
			_glow.light_energy = lerpf(0.4, 3.5, 1.0 - _glow_t / maxf(_glow_len, 0.01))
		else:
			_glow.light_energy = move_toward(_glow.light_energy, 0.0, delta * 8.0)
	if _charge > 0.0:
		_charge -= delta
		global_position -= global_transform.basis.z.normalized() * _charge_speed * delta


## Walking and standing (the dwarf's own walk, played at his speed: m/s in the world).
func walk(speed: float) -> void:
	if dm.dwarf_rig:
		dm.set_motion(speed / SIZE, true, false)
		dm.set_pose(false, false, weapons == "shield" and busy <= 0.0)
