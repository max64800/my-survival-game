class_name DwarfRig
extends Node3D
## The real dwarf: a rigged, animated model built from free CC0 Quaternius packs
## (credits in CREDITS.md), put together in code:
##   - clothes: "Ranger" outfit (leather tunic, belt, boots; its hood is swapped for a dwarf helmet)
##   - head + eyes + eyebrows from the base character (only the head part; the clothes cover the rest)
##   - a big beard (the pack's short beard, stretched long and full in code)
##   - a metal helmet with a nose guard, made from simple shapes, riding on the head bone
##   - DwarfProportions: short legs, big head and hands
##   - animations from the Universal Animation Library 1 + 2, mixed by an AnimationTree:
##       legs: idle -> walk -> jog -> sprint by speed, a jump pose in the air
##       upper body (separate layer): pickaxe swings, sword attacks, so you can swing while walking
##       whole body: dodge roll, getting hit
## Faces -Z like the rest of the game. All meshes sit on DwarfModel.VISUAL_LAYER.

const OUTFIT := "res://assets/characters/dwarf/Male_Ranger.gltf"
const BASE := "res://assets/characters/dwarf/Superhero_Male_FullBody.gltf"
const BEARD := "res://assets/characters/dwarf/Hair_Beard.gltf"
## Our own hand-built dwarf (tools/asset_forge/builds/dwarf_body.py, approved picture assets/concepts/dwarf/). When it
## exists it replaces the pack's outfit, head and beard above; the skeleton and every animation stay the same.
const BODY := "res://assets/characters/dwarf/dwarf_body.glb"
## Round 1 of the hand-built dwarf is a grey shape waiting for the owner's OK, so it is only worn when switched on:
## start the game with "newdwarf" (godot --path . -- newdwarf), or set use_body before build(). After the OK: true.
const BODY_ON := true  # (owner, Nov 18: "import this into the game so I can play as him")
var use_body := BODY_ON or "newdwarf" in OS.get_cmdline_user_args()
## With the hand-built body the head keeps only this much of each animation's neck and head turning: it sits right on
## the shoulders with a big beard on the chest, so a full human nod pushed the face into the chest (F183).
const BODY_HEAD_FOLLOW := 0.35
const LIBS := {"": "res://assets/characters/anims/UAL1.glb", "b": "res://assets/characters/anims/UAL2.glb"}
const HEIGHT := 0.98  ## where the head bone ends up (metres); with the helmet the dwarf is ~1.3 m tall
const WIDTH := 1.2    ## a little extra width overall (most of the bulk comes from DwarfProportions)
const BEARD_COLOR := Color(0.62, 0.32, 0.14)
## Which animation does what. Names from the UAL packs ("b/" = pack 2). Godot drops the
## "_Loop" ending from the file's names when it imports them, and makes those animations loop.
const ANIMS := {
	idle = "Idle", walk = "Walk", jog = "Jog_Fwd", sprint = "Sprint",
	air = "Jump", roll = "Roll", hit = "Hit_Chest", knock = "b/Hit_Knockback",
	dig = "x/Pickaxe_Mine", climb = "x/Ladder_Climb", sit = "Sitting_Idle", chop = "x/Axe_Chop", wake = "b/LayToIdle",
	# Sword: a 2-hit combo (owner, Nov 17: "looks like chopping, maybe a two-hit combo"): a level sweep right to left,
	# then one left to right (MADE Sword_Forehand / Sword_Backhand); the big overhead chop for a heavy blow. (The pack's Sword_Regular_A/B
	# swing the blade back through his own body with our grip: owner, Nov 17 "he is stabbing himself".)
	attack_a = "x/Sword_Forehand", attack_b = "x/Sword_Backhand", heavy = "Sword_Attack",
	smash = "Sword_Attack",  # mace, maul, great axe: an overhead smash
	swipe = "b/Sword_Regular_C",  # the mace's 2nd hit: a side swing
	stab = "Punch_Cross",    # spear: a straight thrust
	bash = "b/Shield_OneShot",  # shield selected: push the shield (left arm) forward
	eat = "b/Consume", use = "Interact", throw = "b/OverhandThrow",
	# Held poses (as long as the button is down). The shield is always on the left arm (owner, Nov 17), the weapon in
	# the right hand: the shield block raises the left arm (the right keeps the weapon ready).
	block = "x/Sword_Guard", shield = "b/Idle_Shield", aim = "Pistol_Aim_Neutral",
	# Great axe and great maul (F389, owner Nov 20): the Lampwick Foreman's moves (DwarfGreatSwing), played by DwarfFist.
	# The "g/" clips only time the swing (the upper body's idle; the bones come from the baked moves).
	great_chop = "g/Chop", great_spin = "g/Spin",
	stunned = "b/Idle_Shield_Break",  # stunned / guard broken (owner, chat 15)
	mace_1 = "o/UalMace1", mace_2 = "o/UalMace2", mace_3 = "o/UalMace3", mace_4 = "o/UalMace4",
	ual_1 = "o/UalHit1", ual_2 = "o/UalHit2", ual_3 = "o/UalHit3", ual_heavy = "o/UalHeavyHit",
}
## Which attack each weapon makes: [light attacks (taking turns), heavy attack] (names in ANIMS). Anything else: "".
const ATTACKS := {
	# sword (owner, chat 15: "as perfect as it can get"): Quaternius UAL 2's regular combo, one hit per click, and its
	# hit C for the heavy blow (DwarfOneSwing, baked by tools/asset_forge/one_ual_bake.gd; played at UAL_SLOW)
	"sword": [["ual_1", "ual_2", "ual_3"], "ual_heavy"],
	"": [["attack_a", "attack_b"], "heavy"],  # (everything else: the old sword swings; the UAL moves need a sword or mace in hand)
	# mace (owner, chat 15: "the heavy combo is the mace main combo"): UAL 2's heavy combo, one hit per click
	"mace": [["mace_1", "mace_2", "mace_3", "mace_4"], "smash"],
	# great axe and great maul (owner, Nov 20, F389): the Foreman's moves, light = the chop, heavy = the spin (owner's
	# pick; the heavy swing's 1.9 s plays the spin near the Foreman's own speed).
	"axe_2h": [["great_chop"], "great_spin"],
	"mace_2h": [["great_chop"], "great_spin"],
	"hammer": [["smash"], "smash"],
	"spear": [["stab"], "stab"],
	"shield": [["bash"], "bash"],
}
## How each tool sits in the fist: tool look -> {animation ("" = any other) -> [turn (degrees, x/y/z, in the tool's own
## space after the base grip), slide along the handle (m, + = the fist sits nearer the handle's end)]}.
## The base grip (DwarfModel.hand_tool_rot) puts the handle through the fist; the turn about the handle (y) puts the pick's
## points, the axe's blade and the sword's edge in the swing (the base had them 90 degrees off: owner, Nov 17). Measured:
## the tip's motion at the strike lies +90 degrees around the handle from the tool's +X in every swing, +125 in the
## pick's mining swing (the wrist turns there). The axe's blade is on its +X side (checked in a picture).
## The fist closes round the wrapped grip, ~9 cm up from the handle's end (owner, Nov 17: "he's not holding the axe by
## the handle": the fist sat at the very end). Measured: the fist's middle is 4 cm below the holder along the handle, and
## ToolModels puts every handle's end 10 cm below the holder, so the tool slides down 3 cm.
const GRIP_SLIDE := -0.03
const GRIPS := {
	# Standing and walking (owner, Nov 17: "when I'm walking the pickaxe is backwards"): handle up, head on top with one
	# point forward and a little down, the other back, like a miner carries it (measured standing and walking).
	"pickaxe": {"": [Vector3(8, 96, 16), GRIP_SLIDE], "x/Pickaxe_Mine": [Vector3(0, 125, 0), GRIP_SLIDE]},
	"axe": {"": [Vector3(0, 90, 0), GRIP_SLIDE], "x/Axe_Chop": [Vector3(0, 125, 0), GRIP_SLIDE]},  # (the wrist turns in the chop too)
	"axe_2h": {"": [Vector3(0, 90, 0), GRIP_SLIDE]},
	"sword": {"": [Vector3(0, 90, 0), GRIP_SLIDE]},
	"mace": {"": [Vector3(0, 90, 0), GRIP_SLIDE]},
	"mace_2h": {"": [Vector3(0, 90, 0), GRIP_SLIDE]},
	"hammer": {"": [Vector3(0, 90, 0), GRIP_SLIDE]},
	"shovel": {"": [Vector3(0, 90, 0), GRIP_SLIDE]},
}
## The shield on the left arm (shield_grip), per animation: [turn (degrees, in the shield model's own space), slide].
## Hanging: its face (+X of the model) out to his left; in the block and the bash: to the front.
const SHIELD_GRIPS := {
	"": [Vector3(-39, -30, -171), 0.0], "b/Idle_Shield": [Vector3(-82, 111, 69), 0.0],
	"b/Shield_OneShot": [Vector3(-75, -100, -83), 0.0],
}
## How long the dodge roll animation plays (s). Longer than the dodge itself (Combat.DODGE_TIME 0.45 s of movement and
## its safe window stay as they are, so fights stay fair): he finishes the tumble in place (owner, Nov 17: "roll is way
## too fast").
const ROLL_TIME := 0.75
## Speeds (m/s) where each move animation fits best. Owner, Nov 20 (F494, "sometimes I can run without pressing
## shift"): plain walking (Dwarf.WALK_SPEED, 4 m/s) played the jog, so it looked like running except while blocking or
## aiming (slower: the walk). Now walking speed is the walk; the jog and sprint are only for running (Shift, 6.5 m/s).
const MOVE_POINTS := {idle = 0.0, walk = 4.0, jog = 5.3, sprint = 6.5}
## How fast the standing/walk/run loops play (1 = as made; owner Nov 18: "way too fast").
const LOOP_SPEED := 0.7
## Feet that grip the floor (Nov 19, waiting for the owner's pick): at 70% the feet skate (they move back only 64% as
## fast as the dwarf walks, 39% when running; tools/asset_forge/dwarf_gait_check.gd), so with this on the loops play at
## the speed where the feet stay put instead: speed (m/s) -> how fast the loop plays.
static var grip_feet := false
## The heavy-steps layer (DwarfWeight): off, the owner kept the old moves (Nov 19). The Dwarf Moves page tool turns it on.
static var use_weight := false
const GRIP_RATES := {0.0: 0.7, 1.6: 1.3, 4.0: 1.0, 6.5: 1.65}


## How fast the standing/walk/run loops play at `speed` m/s.
static func loop_rate(speed: float) -> float:
	if not grip_feet:
		return LOOP_SPEED
	var keys := GRIP_RATES.keys()
	for i in range(1, keys.size()):
		if speed <= keys[i] or i == keys.size() - 1:
			var a: float = keys[i - 1]
			var b: float = keys[i]
			return lerpf(GRIP_RATES[a], GRIP_RATES[b], clampf((speed - a) / (b - a), 0.0, 1.0))
	return LOOP_SPEED

## Our own animations, stitched together from poses of the pack's animations (see _made_library).
## Each entry: [time 0..1, source animation, moment in it (0..1 of its length)].
const MADE := {
	# A real mining swing: raise the pick high over the head, smash it down in front, recover.
	# The strike lands at 0.55, the moment the dig happens (DwarfModel.swing).
	"Pickaxe_Mine": [
		[0.0, "b/TreeChopping", 0.9], [0.38, "b/TreeChopping", 0.7], [0.55, "Sword_Attack", 0.36],
		[0.7, "Sword_Attack", 0.5], [1.0, "b/TreeChopping", 0.9]],
	# A wood chop (owner, Nov 17: the pack's tree chop held the axe up by his face with the arm bent): raise the axe
	# over the shoulder, bring it down with the arm out in front, recover. The strike lands at 0.55 (DwarfModel.swing).
	"Axe_Chop": [
		[0.0, "Sword_Attack", 0.0], [0.2, "Sword_Attack", 0.1], [0.42, "Sword_Attack", 0.2], [0.55, "Sword_Attack", 0.33],
		[0.7, "Sword_Attack", 0.45], [1.0, "Sword_Attack", 0.95]],
	# The guard, held: the pack's Sword_Block raises the sword and lowers it again by itself, so a held block dropped
	# after ~0.7 s. This one raises it and stays (a held pose keeps the last frame).
	"Sword_Guard": [[0.0, "b/Sword_Block", 0.0], [0.3, "b/Sword_Block", 0.3], [1.0, "b/Sword_Block", 0.45]],
	# The right arm of the running shoulder carry (only that arm is used): the fist up in front of the shoulder.
	"Carry_Shoulder": [[0.0, "b/Idle_Rail_Call", 0.4], [1.0, "b/Idle_Rail_Call", 0.4]],
	# The sword's combo (owner, Nov 17: "keep it very simple": two wide, level sweeps at chest height), both made from
	# the sweep of the pack's Sword_Regular_B without its wind-up (that one pointed the blade back through his body).
	# Hit 1: the fist out wide to his right, blade pointing right, then all the way across to his left.
	# Hit 2: the other way: across to his left first, then all the way out to his right.
	# The blade points straight ahead at 0.4, when the hit lands (DwarfFight._attack).
	"Sword_Forehand": [
		[0.0, "b/Sword_Regular_B", 0.0], [0.28, "b/Sword_Regular_B", 0.56], [0.4, "b/Sword_Regular_B", 0.5],
		[0.5, "b/Sword_Regular_B", 0.46], [0.62, "b/Sword_Regular_B", 0.45], [1.0, "b/Sword_Regular_B", 0.0]],
	"Sword_Backhand": [
		[0.0, "b/Sword_Regular_B", 0.0], [0.14, "b/Sword_Regular_C", 0.45], [0.28, "b/Sword_Regular_B", 0.44],
		[0.4, "b/Sword_Regular_B", 0.5], [0.48, "b/Sword_Regular_B", 0.56], [0.62, "b/Sword_Regular_B", 0.58],
		[1.0, "b/Sword_Regular_B", 0.97]],
}

## Animations stitched from two sources: the upper body (spine and up) from one, the legs from
## another. Each key: [time 0..1, upper source, moment, lower source, moment]. They loop.
const MADE_SPLIT := {
	# Climbing a rope ladder: hands high on the rungs (from a "hold the rail overhead" pose)
	# while the legs step up in turns (from the jog).
	"Ladder_Climb": [
		[0.0, "b/Idle_Rail_Call", 0.25, "Jog_Fwd", 0.0], [0.5, "b/Idle_Rail_Call", 0.45, "Jog_Fwd", 0.5],
		[1.0, "b/Idle_Rail_Call", 0.25, "Jog_Fwd", 1.0]],
}

static var _libs := {}
static var _made: AnimationLibrary
static var _head_mesh: Mesh

var skeleton: Skeleton3D
var proportions: DwarfProportions
var weight: DwarfWeight  ## heavy steps, waddle, breathing, landing squash
var tree: AnimationTree
var right_hand: Node3D  ## tools go here
var left_hand: Node3D   ## the lantern hangs here
var _air := 0.0
var _air_time := 0.0  ## how long we've been off the ground (for the landing dip)
var _rolling := false
var _attack_flip := false
var _hold := ""        ## which held pose is on ("" = none)
var _hold_amount := 0.0
## Something in the right hand (tool, weapon). Running, the arm pumps and the hand turns: a tool fixed in the fist
## then swung forward through his head (owner: "the pickaxe is the wrong way when I'm running"). So from a jog up
## the tool turns in the fist to trail back and a little down and out, away from the head. Set by DwarfModel.set_held.
var carrying := false
var _carry := 0.0
var move_speed := 0.0  ## m/s, as last given to set_motion (DwarfFist: the second hand lets go when running)
## The tool holder in the right fist (DwarfModel puts the tool model in it): its +Y is the handle, out of the thumb side
## of the fist, the way the pack's sword animations hold a sword. How the tool turns in the fist depends on the tool
## (tool_look = Combat.weapon_of / Items.kind, set by DwarfModel.set_held) and on the animation playing: see GRIPS.
var _even := {}  ## neck/head bone name -> its unskewed twin (EvenHead), for the hand-built body
var grip: Node3D
## Where the tool holder would sit in the fist by GRIPS alone (turned smoothly between animations). DwarfFist turns the
## wrist so the handle runs through the closed fist and places `grip` from this every frame.
var grip_local := Transform3D()
var fist: DwarfFist  ## closes the fingers round the handle (after the dwarf shaping)
var shield_grip: Node3D  ## the shield's holder on the left forearm (DwarfModel.set_shield): see SHIELD_GRIPS
var tool_look := ""
var _upper_clip := ""  ## the upper-body one-shot playing now (for GRIPS)
var _spear_aim := 0.0
var _upper_start := 0.0  ## when the upper one-shot started (s) and how fast it plays (for the great swings)
var _upper_scale := 1.0
## The great weapons' pose now (DwarfGreatSwing): eased back to the stance between swings.
var great: Dictionary = {}
var _great_from: Dictionary = {}  ## the pose the swing playing now started from
var great_fixed: Dictionary = {}  ## tools only: hold this great-weapon pose still
var _great_started := -1.0  ## _upper_start of that swing
var _stance_clock := 0.0  ## s into the stance's slow loop
var great_move := ""  ## the great swing playing now ("" = none)
var great_t := 0.0  ## how far into it (0..1)
var _great_clock := 0.0  ## s into that swing
## The sword's and the mace's swings now (DwarfOneSwing, F389 chat 12): the pose and how much of it he takes (0..1;
## eases in at the start of a swing, out after it).
var one_fixed: Dictionary = {}  ## tools only: hold this sword/mace swing pose still (F389 chat 13)
var one: Dictionary = {}
var one_weight := 0.0
var one_move := ""  ## the one-handed swing playing now ("" = none)
var one_t := 0.0  ## how far into it (0..1)
var _one_from: Dictionary = {}
var _one_from_w := 0.0
var _one_started := -1.0
var _one_clock := 0.0
var _carry_arm := 0.0  ## how far the right arm is lifted into the shoulder carry  ## how much the spear is turned to point straight ahead (the thrust)


func build(tint: Color) -> void:
	var body: Node3D = (load(OUTFIT) as PackedScene).instantiate()
	add_child(body)
	_body_root = body
	body.rotation.y = PI  # the model faces +Z; our dwarf faces -Z
	skeleton = body.find_children("*", "Skeleton3D", true, false)[0]
	# Head, eyes, eyebrows and beard come from other files with the same skeleton:
	# move their meshes onto our skeleton.
	_borrow_meshes(BASE, func(mi: MeshInstance3D):
		if mi.name == "SuperHero_Male":
			mi.mesh = _head_only(mi))
	_borrow_meshes(BEARD, func(mi: MeshInstance3D):
		var m := mi.get_active_material(0).duplicate() as BaseMaterial3D
		mi.mesh = _big_beard(mi)
		if m:
			m.albedo_color = BEARD_COLOR * 1.6  # the hair texture is light grey: tint it ginger
			m.cull_mode = BaseMaterial3D.CULL_DISABLED  # a stretched beard shows its inside
			mi.material_override = m)
	var hood := skeleton.get_node_or_null("Male_Ranger_Head_Hood") as Node3D
	if hood:
		hood.visible = false
	_tint_clothes(tint)
	for mi in find_children("*", "MeshInstance3D", true, false):
		mi.layers = DwarfModel.VISUAL_LAYER
		_add_rim(mi)
	# Dwarf proportions, applied after every animation frame.
	var prop := DwarfProportions.new()
	skeleton.add_child(prop)
	prop.setup(skeleton)
	if use_body and ResourceLoader.exists(BODY):
		prop.head_follow = BODY_HEAD_FOLLOW
		pass  # prop.no_skew(skeleton): off, it broke the arms (owner, Nov 17); see DwarfProportions.no_skew  # (the sword swing stretched his head flat: see there)
	proportions = prop
	# Weight (Nov 19, "heavy + chunky"): follow-through, waddle, breathing, landing squash. After the shaping,
	# before the hair and clothes springs (added later in _wear_body), so they swing along. OFF (owner, Nov 19, after
	# the Dwarf Moves page: "all before is good already, keep what we have"); `use_weight = true` brings it back.
	if use_weight:
		weight = DwarfWeight.new()
		skeleton.add_child(weight)
		weight.setup(skeleton, prop)
	# Fists (Nov 19): fingers closed round the handle, the handle through the fist (DwarfFist). After the shaping.
	fist = DwarfFist.new()
	fist.name = "Fist"
	skeleton.add_child(fist)
	# Size: put the head bone at HEIGHT, and make the dwarf a bit wider.
	var head := skeleton.find_bone("Head")
	var head_y := prop._rest_global(skeleton, head, true).origin.y - prop.drop_height
	var s := HEIGHT / maxf(head_y, 0.1)
	scale = Vector3(s * WIDTH, s, s * WIDTH)
	# Hands: things held keep their own size (cancel the dwarf scale and the big-hand scale).
	right_hand = _hand_socket("hand_r")
	left_hand = _hand_socket("hand_l")
	grip = Node3D.new()
	grip.name = "Grip"
	grip.transform = grip_transform("", "")
	grip_local = grip.transform
	right_hand.add_child(grip)
	shield_grip = Node3D.new()
	shield_grip.name = "ShieldGrip"
	shield_grip.transform = shield_transform("")
	left_hand.add_child(shield_grip)
	if use_body and ResourceLoader.exists(BODY):
		_wear_body(BODY)  # (bareheaded like the picture: no starting cap; armour helmets still work)
	else:
		_build_helmet()
		_build_beard()
	_build_tree(body)
	fist.setup(skeleton, self)  # (reads the finger bend directions from the standing animation)


## Put the hand-built body on our skeleton. It was modelled around the bones standing at rest, shaped by
## DwarfProportions (dwarf_rest_poses), so each part is bound to exactly that pose: standing still it looks as built,
## and every animation bends it along. The pack's stand-in meshes are hidden.
func _wear_body(path: String) -> void:
	for mi: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		mi.visible = false
	var poses := dwarf_rest_poses()
	# standing, the feet go back to where they are in the pose the body was built in (sole on the floor: Nov 18, matching
	# the human animation's toe bone sank the thick hand-built feet into the ground)
	var low := INF
	for b in proportions._feet:
		low = minf(low, (poses[b] as Transform3D).origin.y)
	proportions._rest_low = low - 0.01  # (standing tips the feet a little: the soles hovered 0.7-1.4 cm up, measured Nov 18)
	# The .glb is in "model space" (facing +Z); the player's look space faces -Z. Look space = our parent's space.
	var skel_in_look := Transform3D()
	var n: Node3D = skeleton
	while n != null and n != self:
		skel_in_look = n.transform * skel_in_look
		n = n.get_parent_node_3d()
	skel_in_look = transform * skel_in_look
	var model_to_skel := skel_in_look.affine_inverse() * Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var src: Node = (load(path) as PackedScene).instantiate()
	var built := {}
	var chains := _add_swing_bones(src, poses, model_to_skel, built)
	# (F280) the neck and head get unskewed twins; everything bound to them is bound to the twins (see EvenHead)
	var even := EvenHead.new()
	even.name = "EvenHead"
	skeleton.add_child(even)  # (after DwarfProportions, before HairSwing)
	_even = even.setup(skeleton, poses)
	var colliders := _fit_colliders(src, poses, model_to_skel)
	var under := _hair_on_shirt(src, built, model_to_skel)
	_bind_poses = poses  # (the swing bones included: armor made over the body binds the same way)
	_model_to_skel = model_to_skel
	_hide_skin_under_shirt(src)
	for mi: MeshInstance3D in src.find_children("*", "MeshInstance3D", true, false):
		_bind_to_skeleton(mi)
		if mi.name.begins_with("body_head"):
			_body_head = mi
	src.free()
	var head := skeleton.find_bone(_even.get("Head", "Head"))  # (the hair follows the unskewed head)
	var heights := {}
	for chain: String in built:
		heights[chain] = (built[chain] as Array).map(func(at: Vector3) -> float: return at.y)
	var rests := {}
	for chain: String in under:
		for spot: Dictionary in under[chain]:
			for b: int in spot.weights:
				rests[b] = poses[b]
	_add_springs(chains, colliders, poses[head] if head >= 0 else Transform3D(), head, heights, under, rests)


## The shirt looked torn at the shoulders when an arm lifted or reached across (owner, F389 chat 9-11): the bare skin
## under it (body_torso, its own layer) bends with the arm bones and pushed out through the shirt. The skin the shirt
## covers is never seen, so it is left out: every skin triangle whose three corners each have the shirt within
## SKIN_COVER just outside them (along the skin's own outward direction). The arms past the sleeves, the neck and
## everything else stay. Done once (the cut skin is shared by every dwarf).
const SKIN_COVER := 0.045  ## m
static var _cut_skin: Mesh
func _hide_skin_under_shirt(src: Node) -> void:
	var skin := src.find_child("body_torso*", true, false) as MeshInstance3D
	var shirt := src.find_child("body_shirt", true, false) as MeshInstance3D
	if skin == null or shirt == null or skin.mesh == null or shirt.mesh == null:
		return
	if DisplayServer.get_name() == "headless":  # (only a look; the no-screen test renderer keeps no paint on made meshes
		return  # and errors when a dwarf is freed)
	if _cut_skin:
		skin.mesh = _cut_skin
		return
	var to_src := func(n: Node3D) -> Transform3D:
		var x := Transform3D()
		var at: Node = n
		while at != src and at is Node3D:
			x = (at as Node3D).transform * x
			at = at.get_parent()
		return x
	var shirt_x: Transform3D = to_src.call(shirt)
	var skin_x: Transform3D = to_src.call(skin)
	var cells := {}  # Vector3i -> PackedVector3Array of shirt points
	for sf in shirt.mesh.get_surface_count():
		for v: Vector3 in shirt.mesh.surface_get_arrays(sf)[Mesh.ARRAY_VERTEX]:
			var p := shirt_x * v
			var k := Vector3i((p / SKIN_COVER).floor())
			if not cells.has(k):
				cells[k] = PackedVector3Array()
			(cells[k] as PackedVector3Array).append(p)
	var out := ArrayMesh.new()
	var cut := 0
	for sf in skin.mesh.get_surface_count():
		var arr := skin.mesh.surface_get_arrays(sf)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var covered := PackedByteArray()
		covered.resize(verts.size())
		for i in verts.size():
			var p := skin_x * verts[i]
			var nrm := (skin_x.basis * normals[i]).normalized() if i < normals.size() else Vector3.ZERO
			var k := Vector3i((p / SKIN_COVER).floor())
			var hit := false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					for dz in [-1, 0, 1]:
						var c: Variant = cells.get(k + Vector3i(dx, dy, dz))
						if c == null:
							continue
						for q: Vector3 in c:
							var d := q - p
							if d.length() < SKIN_COVER and d.dot(nrm) > 0.5 * d.length():
								hit = true
								break
						if hit:
							break
					if hit:
						break
				if hit:
					break
			covered[i] = 1 if hit else 0
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			for i in verts.size():
				idx.append(i)
		var keep := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			if covered[idx[t]] == 1 and covered[idx[t + 1]] == 1 and covered[idx[t + 2]] == 1:
				cut += 1
				continue
			keep.append(idx[t])
			keep.append(idx[t + 1])
			keep.append(idx[t + 2])
		if keep.is_empty():  # (a part wholly under the shirt: one empty corner keeps every part's paint in its place)
			keep = PackedInt32Array([idx[0], idx[0], idx[0]])
		arr[Mesh.ARRAY_INDEX] = keep
		var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if (arr[Mesh.ARRAY_BONES] as PackedInt32Array).size() == verts.size() * 8 else 0
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, flags)
		out.surface_set_material(out.get_surface_count() - 1, skin.mesh.surface_get_material(sf))
	out.resource_name = skin.mesh.resource_name
	_cut_skin = out
	skin.mesh = out
	print_verbose("dwarf: %d skin triangles under the shirt left out" % cut)


## Moves a mesh made around the dwarf's rest pose (the hand-built body, or armor made over it) onto our skeleton,
## each bone bound where it stands in that pose: standing still it looks as built, and every animation bends it along.
func _bind_to_skeleton(mi: MeshInstance3D) -> void:
	var skin := Skin.new()
	if mi.skin:
		for b in mi.skin.get_bind_count():
			var bname := String(mi.skin.get_bind_name(b))
			bname = _even.get(bname, bname)  # (neck and head: their unskewed twins, EvenHead)
			var bone := skeleton.find_bone(bname)
			var pose: Transform3D = _bind_poses[bone] if bone >= 0 and bone < _bind_poses.size() else Transform3D()
			skin.add_named_bind(bname, pose.affine_inverse() * _model_to_skel)
	mi.owner = null
	mi.get_parent().remove_child(mi)
	skeleton.add_child(mi)
	mi.transform = Transform3D()
	mi.skin = skin
	mi.skeleton = NodePath("..")
	mi.layers = DwarfModel.VISUAL_LAYER
	_add_rim(mi)


## Collision balls inside the torso for the swinging hair (HairSwing): a grid of points inside the shirt, each the
## biggest ball that fits there (touching the shirt), kept if it's big enough, riding on the nearest spine bone.
func _fit_colliders(src: Node, poses: Array, model_to_skel: Transform3D) -> Array:
	var out := []
	var shirt := _torso_mesh(src)
	if shirt == null:
		return out
	var verts: PackedVector3Array = shirt.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]  # model space: metres, y up, front +z
	var norms: PackedVector3Array = shirt.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for v in verts:
		lo = lo.min(v)
		hi = hi.max(v)
	var spine := []
	for b in ["pelvis", "spine_01", "spine_02", "spine_03"]:
		var i := skeleton.find_bone(b)
		if i >= 0:
			spine.append([i, (model_to_skel.affine_inverse() * (poses[i] as Transform3D)).origin.y])
	var y := lo.y + 0.06
	while y < hi.y - 0.03:
		for x in [-0.15, 0.0, 0.15]:
			var z := lo.z + 0.06
			while z < hi.z - 0.05:
				var c := Vector3(x, y, z)
				var r := INF
				var near := 0
				for k in verts.size():
					var dk := c.distance_to(verts[k])
					if dk < r:
						r = dk
						near = k
				# only INSIDE the body (Nov 18: the bare body's round belly left grid points in front of the chest, as
				# far from the skin as the balls inside: balls there sat where the braids hang and folded them)
				var inside := norms.size() == verts.size() and (c - verts[near]).dot(norms[near]) < 0.0
				if r >= 0.07 and inside:
					var best: Array = spine[0]
					for s in spine:
						if absf(float(s[1]) - y) < absf(float(best[1]) - y):
							best = s
					var b: int = best[0]
					out.append({"bone": b, "local": (poses[b] as Transform3D).affine_inverse() * (model_to_skel * c), "radius": r - 0.004})
				z += 0.06
		y += 0.07
	# the shoulders and upper arms (the shirt bulges with them when the arms swing): balls along each upper arm
	for side in ["l", "r"]:
		var a := skeleton.find_bone("upperarm_" + side)
		var e := skeleton.find_bone("lowerarm_" + side)
		if a < 0 or e < 0:
			continue
		var sa := (poses[a] as Transform3D).origin
		var se := (poses[e] as Transform3D).origin
		for f in [0.0, 0.35, 0.7]:
			var c := sa.lerp(se, f)
			out.append({"bone": a, "local": (poses[a] as Transform3D).affine_inverse() * c, "radius": 0.11})
	return out


## The hand-built body brings its own swing bones (the braids and the back hair: "hair_<chain>_1..n", F192). Add them
## to our skeleton where the body was built, each hanging from its parent bone; returns {chain: [bone indices]} and
## fills `built` with {chain: [where each bone starts as built (the .glb's space: metres, y up)]}.
func _add_swing_bones(src: Node, poses: Array, model_to_skel: Transform3D, built := {}) -> Dictionary:
	var chains := {}
	var found := src.find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		return chains
	var ssk := found[0] as Skeleton3D
	var to_model := Transform3D()  # the source skeleton's place in the model
	var n: Node = ssk
	while n != null and n != src:
		if n is Node3D:
			to_model = (n as Node3D).transform * to_model
		n = n.get_parent()
	for i in ssk.get_bone_count():
		var bname := ssk.get_bone_name(i)
		if not (bname.begins_with("hair_") or bname.begins_with("cloth_")) or skeleton.find_bone(bname) >= 0:  # (hair, and the clothes' springy strips)
			continue
		# Hair bones hang off the skeleton's root, not the head: every bone under the head inherits its uneven stretch
		# (the dwarf shaping), so a turning hair bone also stretched and skewed. HairSwing places each hair bone
		# directly every frame, following the head. Each is a plain turn + position (no stretch), bound where built.
		var global: Transform3D = model_to_skel * to_model * ssk.get_bone_global_rest(i)
		global = Transform3D(Basis(global.basis.get_rotation_quaternion()), global.origin)
		var root := 0
		var idx := skeleton.add_bone(bname)
		skeleton.set_bone_parent(idx, root)
		skeleton.set_bone_rest(idx, (poses[root] as Transform3D).affine_inverse() * global)
		skeleton.reset_bone_pose(idx)
		poses.append(global)
		var chain := bname.rsplit("_", true, 1)[0]
		if not chains.has(chain):
			chains[chain] = []
			built[chain] = []
		chains[chain].append(idx)
		built[chain].append((to_model * ssk.get_bone_global_rest(i)).origin)
	return chains


## Where each back-hair joint lies on the shirt (owner, Nov 17: the back hair lifted off the back): the bones and
## weights of the nearest shirt point, so below the head the hair moves exactly like the shirt under it, and which way
## is "out of the shirt" there (the hair may lift off, never sink in). The arms' share goes to the upper chest, like
## the beard and hair in dwarf_body.py (raising the arms tore the beard).
## Returns {chain: [{weights: {bone: weight}, out: direction (skeleton space)} per joint, the last bone's tip included]}.
func _hair_on_shirt(src: Node, built: Dictionary, model_to_skel: Transform3D) -> Dictionary:
	var out := {}
	var shirt := _torso_mesh(src)
	var chest := skeleton.find_bone("spine_03")
	if shirt == null or shirt.skin == null or chest < 0:
		return out
	var arrays := shirt.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]  # (model space, like the bones in `built`)
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	if verts.is_empty() or bones.size() != weights.size():
		return out
	var per := bones.size() / verts.size()
	var arm := ["clavicle", "upperarm", "lowerarm", "hand", "thumb", "index", "middle", "ring", "pinky"]
	for chain: String in built:
		var at_list: Array = built[chain]
		if not (chain.begins_with("hair_back") or chain.begins_with("cloth_")) or at_list.size() < 2:
			continue
		var spots := at_list.duplicate()
		spots.append(at_list[-1] + (at_list[-1] - at_list[-2]))  # (the last bone's tip, as HairSwing places it)
		var list := []
		for at: Vector3 in spots:
			var near := 0
			for v in verts.size():
				if verts[v].distance_squared_to(at) < verts[near].distance_squared_to(at):
					near = v
			var ws := {}
			for k in per:
				var w := weights[near * per + k]
				if w <= 0.0:
					continue
				var bname := String(shirt.skin.get_bind_name(bones[near * per + k]))
				var b := skeleton.find_bone(bname)
				if b < 0 or arm.any(func(a: String) -> bool: return bname.begins_with(a)):
					b = chest
				ws[b] = float(ws.get(b, 0.0)) + w
			var away: Vector3 = (model_to_skel.basis * (at - verts[near])).normalized()
			list.append({"weights": ws if not ws.is_empty() else {chest: 1.0}, "out": away})
		out[chain] = list
	return out


## The body's torso mesh: the bare torso (Nov 18: the dwarf in underpants, clothes go on later as layers), or the shirt.
func _torso_mesh(src: Node) -> MeshInstance3D:
	for n in ["body_torso*", "body_shirt_body*"]:
		var mi := src.find_child(n, true, false) as MeshInstance3D
		if mi != null:
			return mi
	return null


## Springs on the swing bones: the tufts trail behind when the dwarf moves and bounce back (HairSwing). Below the head
## the back hair lies on the shirt (heights, under, rests: see HairSwing.setup).
func _add_springs(chains: Dictionary, colliders: Array, head_rest: Transform3D, head: int, heights := {}, under := {},
		rests := {}) -> void:
	if chains.is_empty() or head < 0:
		return
	var swing := HairSwing.new()
	swing.name = "HairSwing"
	skeleton.add_child(swing)  # (after DwarfProportions: it swings the shaped dwarf)
	swing.setup(chains, colliders, head, head_rest, heights, under, rests)


## Every bone as the dwarf stands at rest, shaped by DwarfProportions (skeleton space, each bone's thickness included).
## The hand-built dwarf body is modelled around exactly these (tools/asset_forge/dwarf_skeleton_dump.gd) and bound to
## them, so standing still it looks exactly as built and every animation bends it along.
func dwarf_rest_poses() -> Array:
	skeleton.reset_bone_poses()
	for i in proportions._pos:
		skeleton.set_bone_pose_position(i, proportions._pos[i])
	for i in proportions._scale:
		skeleton.set_bone_pose_scale(i, proportions._scale[i])
	if proportions._pelvis >= 0:
		skeleton.set_bone_pose_position(proportions._pelvis, skeleton.get_bone_rest(proportions._pelvis).origin - proportions._drop)
	var out := []
	for i in skeleton.get_bone_count():
		out.append(skeleton.get_bone_global_pose(i))
	return out


func _process(delta: float) -> void:
	for h in [right_hand, left_hand]:
		var p := h.get_parent() as Node3D
		h.scale = Vector3.ONE / p.global_transform.basis.get_scale()
	_update_grip(delta)
	_lift_roll(delta)
	_hold_amount = move_toward(_hold_amount, 1.0 if _hold != "" else 0.0, delta * 8.0)
	tree.set("parameters/hold/blend_amount", _hold_amount)


## The turn (world space) from "as the fist holds it" (GRIPS) to where the held tool points now: the running carry
## (by _carry, so it fades in and out with the speed) and the spear's level thrust. `tool` = the tool's frame as GRIPS
## puts it. DwarfFist turns the wrist by it (Nov 19: it used to turn only the tool holder, so running the handle floated
## beside the open hand).
## Running (owner, Nov 17: "running through the pickaxe is not the best": low at the hip it went through his legs): a
## miner's carry over the shoulder. The right arm lifts the fist in front of the shoulder (CARRY_ANIM, right arm only)
## and the handle lies back over the shoulder, the head behind it with its points up and down, clear of his head.
## Rolling, the arms fly about: then the tool just trails behind, out to his right (CARRY_DIR).
const CARRY_DIR := Vector3(0.3, -0.3, 1.0)  ## out to his right, a little down, back (he faces -Z)
const SHOULDER_DIR := Vector3(0.2, 0.5, 1.0)  ## the handle over the shoulder: back, up, a little out (clear of his head)
const CARRY_ANIM := "x/Carry_Shoulder"
func hold_turn(tool: Basis) -> Quaternion:
	var q := Quaternion.IDENTITY
	# The spear's thrust (owner, Nov 17: "looks a little odd", it sloped down to the floor): the spear points straight
	# ahead, level, whatever the punching hand does. (Both hands on the shaft can't be done: the dwarf's short arms
	# don't reach across his body.)
	if _spear_aim > 0.0:
		var point := -tool.z.normalized()  # (ToolModels turns the spear to point along its holder's -Z)
		var ahead := (global_basis * Vector3(0, -0.05, -1)).normalized()
		q = Quaternion(point, ahead).slerp(Quaternion.IDENTITY, 1.0 - _spear_aim)
		tool = Basis(q) * tool
	if _carry <= 0.0:
		return q
	var turn: Quaternion
	if _roll_on():
		var up := tool.y.normalized()
		var want := (global_basis * CARRY_DIR).normalized()
		turn = Quaternion(up, want).slerp(Quaternion.IDENTITY, 1.0 - _carry)
	else:
		var y := (global_basis * SHOULDER_DIR).normalized()
		var x := (global_basis.y - global_basis.y.dot(y) * y).normalized()  # the head's points up and down
		var want := Basis(x, y, x.cross(y))
		var now := tool.orthonormalized()
		turn = (want * now.inverse()).get_rotation_quaternion().slerp(Quaternion.IDENTITY, 1.0 - _carry)
	return turn * q


## The pack's dodge roll is made for a slim human: rolling, the round dwarf's body went half into the floor (seen in
## the studio, Nov 17). While the roll plays, lift him in a smooth arc, highest mid-roll where he is curled up lowest.
const ROLL_LIFT := 0.3  ## metres, at the middle of the roll
func _lift_roll(_delta: float) -> void:
	if not is_instance_valid(_body_root) or scale.y <= 0.0:
		return
	_roll_lift = 0.0
	if _full_clip == ANIMS.roll and tree.get("parameters/full/active") and _full_length > 0.0:
		var k := clampf((Time.get_ticks_msec() / 1000.0 - _full_start) / _full_length, 0.0, 1.0)
		_roll_lift = ROLL_LIFT * sin(PI * k) / scale.y
	_body_root.position.y = _sole_y + _roll_lift


## Turns the tool in the fist to the grip for the animation playing now (GRIPS): a quick turn, not a jump.
func _update_grip(delta: float) -> void:
	var clip := ""
	if tree.get("parameters/upper/active"):
		clip = _upper_clip
	elif _hold != "":
		clip = ANIMS.get(_hold, _hold)
	var k := minf(1.0, delta * 25.0)
	var want := grip_transform(tool_look, clip)
	grip_local = Transform3D(Basis(grip_local.basis.get_rotation_quaternion().slerp(want.basis.get_rotation_quaternion(), k)),
		grip_local.origin.lerp(want.origin, k))
	var sw := shield_transform(clip)
	var sq := shield_grip.quaternion.slerp(sw.basis.get_rotation_quaternion(), k)
	shield_grip.transform = Transform3D(Basis(sq), shield_grip.position.lerp(sw.origin, k))
	# the spear's level thrust (hold_turn)
	_spear_aim = move_toward(_spear_aim, 1.0 if tool_look == "spear" and clip == ANIMS.stab else 0.0, delta * 12.0)


const GREAT_WALK := 0.3  ## m/s: faster than this (and not swinging), the great weapon goes onto his shoulder
## Both hands on the great weapon now (standing or swinging); else it rests on his shoulder (set_motion).
func great_two_hands() -> bool:
	return _carry < 0.5


## The great axe's / great maul's pose this frame (DwarfFist places both fists and the chest by it): the swing playing
## now ("g/" clip, from the pose it started at), else easing back to the ready stance.
func great_pose(delta: float) -> Dictionary:
	if not great_fixed.is_empty():  # (a tool holding one pose still)
		great = great_fixed
		return great
	_stance_clock += delta
	var clip := _upper_clip if tree.get("parameters/upper/active") else ""
	if clip.begins_with("g/") and tree.has_animation(clip):
		if _great_started != _upper_start:
			_great_started = _upper_start
			_great_from = great
			_great_clock = 0.0
		else:
			_great_clock += delta  # (game time, frame by frame: a slow frame doesn't skip the swing's key poses)
		var t := _great_clock * _upper_scale / tree.get_animation(clip).length
		great_move = clip.trim_prefix("g/")
		great_t = clampf(t, 0.0, 1.0)
		var k := smoothstep(0.0, DwarfGreatSwing.BLEND_IN, great_t)  # (eases in from wherever he was)
		great = DwarfGreatSwing.blend(_great_from, DwarfGreatSwing.swing(great_move, great_t), k)
	else:
		great_move = ""
		var st := DwarfGreatSwing.stance(_stance_clock)
		great = st if great.is_empty() else DwarfGreatSwing.blend(great, st, 1.0 - exp(-DwarfGreatSwing.RETURN * delta))
	return great


## The sword's / mace's swing pose this frame (DwarfFist lays the weapon by it): the "o/" swing playing now, eased
## in from wherever he was; after it, the last pose fades out (one_weight -> 0) back to his own arms.
const UAL_BLEND_IN := 0.15  ## s, at least, easing into a UAL 2 sword move
func one_pose(delta: float) -> Dictionary:
	if not one_fixed.is_empty():  # (a tool holding one pose still)
		one = one_fixed
		one_weight = 1.0
		return one
	var clip := _upper_clip if tree.get("parameters/upper/active") else ""
	if clip.begins_with("o/") and tree.has_animation(clip):
		if _one_started != _upper_start:
			_one_started = _upper_start
			_one_from = one
			_one_from_w = one_weight
			_one_clock = 0.0
		else:
			_one_clock += delta  # (game time, frame by frame)
		one_move = clip.trim_prefix("o/")
		one_t = clampf(_one_clock * _upper_scale / tree.get_animation(clip).length, 0.0, 1.0)
		var blend_in := DwarfOneSwing.BLEND_IN
		if one_move.begins_with("Ual"):  # (chat 15: UAL 2's half-second hits eased in over 3 frames: a snap; owner: "he's losing his sword at the start")
			blend_in = maxf(blend_in, UAL_BLEND_IN / maxf(tree.get_animation(clip).length / _upper_scale, 0.01))
		var k := smoothstep(0.0, blend_in, one_t)
		var now := DwarfOneSwing.swing(one_move, one_t)
		one = DwarfGreatSwing.blend(_one_from, now, k) if _one_from_w > 0.0 else now
		one_weight = lerpf(_one_from_w, 1.0, k)
	else:
		one_move = ""
		one_weight = move_toward(one_weight, 0.0, delta / DwarfOneSwing.BLEND_OUT)
	return one


## Where the tool holder sits in the fist for a tool look and an animation (see GRIPS).
static func grip_transform(look: String, clip: String) -> Transform3D:
	var base := Transform3D(Basis.from_euler(DwarfModel.hand_tool_rot), DwarfModel.hand_tool_pos)
	var tool_grips: Dictionary = GRIPS.get(look, {})
	var g: Array = tool_grips.get(clip, tool_grips.get("", [Vector3.ZERO, 0.0]))
	var turn := Basis.from_euler((g[0] as Vector3) * (PI / 180.0))
	return base * Transform3D(turn, Vector3(0, g[1], 0))


## Where the shield sits on the left forearm for an animation (see SHIELD_GRIPS).
static func shield_transform(clip: String) -> Transform3D:
	var g: Array = SHIELD_GRIPS.get(clip, SHIELD_GRIPS[""])
	return Transform3D(Basis.from_euler((g[0] as Vector3) * (PI / 180.0)), Vector3(0, g[1], 0))


## Puts the grip straight on (no slow turn): after changing the tool, and for the recorder.
func snap_grip() -> void:
	_update_grip(1.0)


## On a ladder: the whole body plays the climbing loop (it fades in and out).
var _climb := 0.0
var _sit := 0.0  ## 0 = standing, 1 = seated


func set_climbing(on: bool, delta: float) -> void:
	_climb = move_toward(_climb, 1.0 if on else 0.0, delta * 6.0)
	tree.set("parameters/climb/blend_amount", _climb)


## Sitting on a seat (eases in and out over about a quarter second).
func set_sitting(on: bool, delta: float) -> void:
	_sit = move_toward(_sit, 1.0 if on else 0.0, delta * 4.0)
	tree.set("parameters/sit/blend_amount", _sit)


## A pose held with the upper body while a button is down: "block", "shield", "aim" or "" (none).
func set_hold(what: String) -> void:
	if what == _hold:
		return
	_hold = what
	if what == "":
		return  # fades out in _process
	var node := (tree.tree_root as AnimationNodeBlendTree).get_node("hold_anim") as AnimationNodeAnimation
	node.animation = ANIMS.get(what, what)
	tree.set("parameters/hold_seek/seek_request", 0.0)


## Legs follow `speed` (m/s); in the air we blend to the jump pose; a dodge rolls the whole body.
func set_motion(speed: float, on_floor: bool, rolling: bool) -> void:
	tree.set("parameters/move/blend_position", speed)
	if grip_feet:
		tree.set("parameters/move_speed/scale", loop_rate(speed))
	var dt := get_process_delta_time()
	# Walking keeps the tool as the fist holds it; from a jog up it trails behind (hold_turn). Never during a
	# swing or a held pose: those animations aim the tool themselves.
	var want := clampf((speed - 4.4) / 1.2, 0.0, 1.0) if carrying else 0.0  # (only when really running: F494)
	# Great axe and great maul (F389): standing still, both hands in the Foreman's stance (DwarfGreatSwing); walking
	# and running, it rests on his right shoulder in one hand (owner, round 3; Nov 20: "stays as it is").
	var two_h := carrying and tool_look in DwarfFist.TWO_HANDED
	if two_h:
		want = 1.0 if speed > GREAT_WALK else 0.0
	move_speed = speed
	if carrying and (rolling or _roll_on()) and not two_h:
		want = 1.0  # rolling the arms fly about: the tool trails safely behind (owner: pick through his head)
	# (jumping keeps whatever the speed gives: standing still the tool stays as held, owner Nov 17: "his pickaxe goes
	# all the way back" when the air turned the carry fully on)
	_carry = move_toward(_carry, want, dt * (12.0 if rolling or _roll_on() else 5.0))
	if tree.get("parameters/upper/active") or _hold != "":
		_carry = 0.0
	# the right arm lifts into the shoulder carry while running (not in a roll)
	_carry_arm = move_toward(_carry_arm, 0.0 if _roll_on() else _carry, dt * 8.0)
	tree.set("parameters/carry/blend_amount", _carry_arm)
	_air = move_toward(_air, 0.0 if on_floor else 1.0, dt * 6.0)
	if weight:
		weight.speed = speed
		weight.on_floor = on_floor
		weight.rolling = rolling
	if on_floor:
		if _air_time > 0.45 and not rolling:
			play_full("Jump_Land", 0.35)  # a real fall, not a bump: bend the knees on landing
		if weight and _air_time > 0.2:
			weight.land(_air_time)  # the heavy squash (a step down a stair edge doesn't count)
		_air_time = 0.0
	else:
		if weight and _air_time == 0.0:
			weight.takeoff()
		_air_time += dt
	tree.set("parameters/air/blend_amount", _air)
	if rolling and not _rolling:
		play_full("roll", ROLL_TIME)
	_rolling = rolling


## Upper-body action (legs keep walking): dig, attack, block, eat…  `duration` = seconds.
func play_upper(what: String, duration: float = 0.0) -> void:
	_play("upper", what, duration)


## Stop the upper-body action early (a crossbow reload you walked away from), fading back to the normal pose.
func stop_upper() -> void:
	tree.set("parameters/upper/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	_upper_clip = ""


## Whole-body action: roll, get hit.
func play_full(what: String, duration: float = 0.0) -> void:
	_play("full", what, duration)


## A weapon attack that fits the weapon (ATTACKS): weapon = Combat.weapon_of(the held item). step = the hit in the
## combo (DwarfFight._combo_step: hit 1, hit 2 take turns); -1 = just take turns.
## How long an attack takes (s): the sword's UAL 2 moves at UAL_SLOW times their own length (owner, chat 15: "the real
## speed is too fast, slowed down quite drastically"); the mace's at their own speed (owner, chat 16: "takes so long
## to actually hit, twice as fast"); every other weapon: `fallback` (Combat.WEAPONS).
const UAL_SLOW := 2.0
const MACE_SLOW := 1.0


static func ual_slow(weapon: String) -> float:
	return MACE_SLOW if weapon == "mace" else UAL_SLOW


static func attack_seconds(weapon: String, heavy: bool, step: int, fallback: float) -> float:
	if not weapon in ["sword", "mace"]:
		return fallback
	var moves: Array = ATTACKS[weapon]
	var what: String = moves[1] if heavy else (moves[0] as Array)[maxi(step, 0) % (moves[0] as Array).size()]
	var clip: String = String(ANIMS.get(what, what)).trim_prefix("o/")
	return DwarfOneSwing.clip_length(clip) * ual_slow(weapon) if DwarfOneSwing.has_move(clip) else fallback


func attack(duration: float, heavy: bool, weapon: String = "sword", step: int = -1) -> void:
	var moves: Array = ATTACKS.get(weapon, ATTACKS[""])
	var light: Array = moves[0]
	_attack_flip = not _attack_flip
	var i := step if step >= 0 else (0 if _attack_flip else 1)
	play_upper(moves[1] if heavy else light[i % light.size()], duration)


## A spear thrust (owner, Nov 17: "spears should have a different attack animation, that he's actually spearing
## something"): a straight punch with the spear pointing forward along the arm (ToolModels holds it that way).
func stab(duration: float) -> void:
	play_upper("stab", duration)


func _play(layer: String, what: String, duration: float) -> void:
	var anim_name: String = ANIMS.get(what, what)
	if not tree.has_animation(anim_name):
		return
	var node := (tree.tree_root as AnimationNodeBlendTree).get_node(layer + "_anim") as AnimationNodeAnimation
	node.animation = anim_name
	if layer == "upper":
		_upper_clip = anim_name
		_upper_start = Time.get_ticks_msec() / 1000.0
		_upper_scale = tree.get_animation(anim_name).length / duration if duration > 0.0 else 1.0
	else:
		_full_clip = anim_name
		_full_start = Time.get_ticks_msec() / 1000.0
		_full_length = duration if duration > 0.0 else tree.get_animation(anim_name).length
	var anim := tree.get_animation(anim_name)
	# A one-shot must end. Some animations from the pack are made as loops (the axe's TreeChopping), and a
	# looping one never finishes, so the dwarf kept chopping forever (owner F128).
	anim.loop_mode = Animation.LOOP_NONE
	var length := anim.length
	tree.set("parameters/%s_speed/scale" % layer, length / duration if duration > 0.0 else 1.0)
	tree.set("parameters/%s/request" % layer, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _build_tree(body: Node3D) -> void:
	tree = AnimationTree.new()
	tree.name = "AnimationTree"
	for lib_name in LIBS:
		tree.add_animation_library(lib_name, _library(LIBS[lib_name]))
	tree.add_animation_library("x", _made_library())
	# the great swings' timers: the upper body's idle, one per swing (DwarfGreatSwing places the arms and chest)
	var great_lib := AnimationLibrary.new()
	for move: String in DwarfGreatSwing.MOVES:
		var timer := tree.get_animation(ANIMS.idle).duplicate() as Animation
		timer.length = DwarfGreatSwing.clip_length(move)  # (the moves' own length: played at their own speed unless the game says)
		great_lib.add_animation(move, timer)
	tree.add_animation_library("g", great_lib)
	# the sword's and the mace's swing timers (DwarfOneSwing places the arms and the weapon), F389 chat 12
	var one_lib := AnimationLibrary.new()
	for move: String in DwarfOneSwing.MOVES:
		var timer := tree.get_animation(ANIMS.idle).duplicate() as Animation
		timer.length = DwarfOneSwing.clip_length(move)
		one_lib.add_animation(move, timer)
	tree.add_animation_library("o", one_lib)
	var bt := AnimationNodeBlendTree.new()
	# Legs: blend between idle, walk, jog and sprint by speed.
	var move := AnimationNodeBlendSpace1D.new()
	for k in MOVE_POINTS:
		var a := AnimationNodeAnimation.new()
		a.animation = ANIMS[k]
		move.add_blend_point(a, MOVE_POINTS[k], -1, k)
	move.min_space = 0.0
	move.max_space = 8.0
	bt.add_node("move", move, Vector2(0, 0))
	# (owner, Nov 18: "the animation is way too fast, in game and out of it": the standing/walk/run loops play slower)
	var slow := AnimationNodeTimeScale.new()
	bt.add_node("move_speed", slow, Vector2(100, 0))
	bt.connect_node("move_speed", 0, "move")
	var jump := AnimationNodeAnimation.new()
	jump.animation = ANIMS.air
	bt.add_node("jump", jump, Vector2(0, 200))
	bt.add_node("air", AnimationNodeBlend2.new(), Vector2(200, 0))
	bt.connect_node("air", 0, "move_speed")
	bt.connect_node("air", 1, "jump")
	# Ladders: the climbing loop over everything below it.
	var climb := AnimationNodeAnimation.new()
	climb.animation = ANIMS.climb
	bt.add_node("climb_anim", climb)
	bt.add_node("climb", AnimationNodeBlend2.new())
	bt.connect_node("climb", 0, "air")
	bt.connect_node("climb", 1, "climb_anim")
	# Whole-body one-shots (roll, hit).
	# Sitting on a chair, stool or bench (Furnish tab, owner Nov 19): the seated loop over everything below it.
	var sit := AnimationNodeAnimation.new()
	sit.animation = ANIMS.sit
	bt.add_node("sit_anim", sit)
	bt.add_node("sit", AnimationNodeBlend2.new())
	bt.connect_node("sit", 0, "climb")
	bt.connect_node("sit", 1, "sit_anim")
	_add_oneshot(bt, "full", "sit", false)
	# Held upper-body poses (block, shield up, crossbow aim). Non-looping ones hold their last frame.
	var hold_anim := AnimationNodeAnimation.new()
	hold_anim.animation = ANIMS.block
	bt.add_node("hold_anim", hold_anim)
	bt.add_node("hold_seek", AnimationNodeTimeSeek.new())
	bt.connect_node("hold_seek", 0, "hold_anim")
	var hold := AnimationNodeBlend2.new()
	_upper_filter(hold)
	bt.add_node("hold", hold)
	# Running with a tool: the right arm lifts it onto the shoulder (hold_turn, DwarfFist), the rest of him keeps running.
	var carry_anim := AnimationNodeAnimation.new()
	carry_anim.animation = CARRY_ANIM
	bt.add_node("carry_anim", carry_anim)
	var carry := AnimationNodeBlend2.new()
	_arm_filter(carry, "_r")
	bt.add_node("carry", carry)
	bt.connect_node("carry", 0, "full")
	bt.connect_node("carry", 1, "carry_anim")
	bt.connect_node("hold", 0, "carry")
	bt.connect_node("hold", 1, "hold_seek")
	# Upper-body one-shots (dig, attack): only the spine and up, so the legs keep walking.
	_add_oneshot(bt, "upper", "hold", true)
	bt.connect_node("output", 0, "upper")
	tree.tree_root = bt
	body.add_child(tree)  # root_node ".." = the model, where "Armature/Skeleton3D" lives
	tree.set("parameters/move_speed/scale", LOOP_SPEED)
	tree.active = true


func _add_oneshot(bt: AnimationNodeBlendTree, layer: String, below: String, upper_only: bool) -> void:
	var anim := AnimationNodeAnimation.new()
	anim.animation = ANIMS.idle
	bt.add_node(layer + "_anim", anim)
	bt.add_node(layer + "_speed", AnimationNodeTimeScale.new())
	bt.connect_node(layer + "_speed", 0, layer + "_anim")
	var shot := AnimationNodeOneShot.new()
	shot.fadein_time = 0.08
	shot.fadeout_time = 0.2
	if upper_only:
		_upper_filter(shot)
	bt.add_node(layer, shot)
	bt.connect_node(layer, 0, below)
	bt.connect_node(layer, 1, layer + "_speed")


## Let a blend node only touch one arm (side "_r" or "_l"): the clavicle and everything on it.
func _arm_filter(node: AnimationNode, side: String) -> void:
	node.filter_enabled = true
	var top := skeleton.find_bone("clavicle" + side)
	for i in skeleton.get_bone_count():
		var b := i
		while b >= 0 and b != top:
			b = skeleton.get_bone_parent(b)
		if b == top:
			node.set_filter_path(NodePath("Armature/Skeleton3D:" + skeleton.get_bone_name(i)), true)


## True while the dodge roll plays.
func _roll_on() -> bool:
	return _full_clip == ANIMS.roll and tree != null and bool(tree.get("parameters/full/active"))


## Let a blend node only touch the spine and everything above it (arms, head).
func _upper_filter(node: AnimationNode) -> void:
	node.filter_enabled = true
	var spine := skeleton.find_bone("spine_01")
	for i in skeleton.get_bone_count():
		var b := i
		while b >= 0 and b != spine:
			b = skeleton.get_bone_parent(b)
		if b == spine:
			node.set_filter_path(NodePath("Armature/Skeleton3D:" + skeleton.get_bone_name(i)), true)


func _hand_socket(bone: String) -> Node3D:
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	skeleton.add_child(att)
	var socket := Node3D.new()
	att.add_child(socket)
	return socket


## Take the meshes out of another model file (same skeleton) and put them on ours.
func _borrow_meshes(path: String, fix: Callable) -> void:
	var other: Node = (load(path) as PackedScene).instantiate()
	for mi: MeshInstance3D in other.find_children("*", "MeshInstance3D", true, false):
		mi.owner = null
		mi.get_parent().remove_child(mi)
		skeleton.add_child(mi)
		mi.skeleton = NodePath("..")
		fix.call(mi)
	other.free()


## Things worn (armor, masks). Each id builds its parts on a bone; new armor = a new entry here.
var _worn := {}  ## id -> the node holding its parts
var _cap: Node3D  ## the starting iron cap (hidden under an armor helmet)


func set_wear(ids: Array) -> void:
	for id in _worn.keys():
		if id not in ids:
			_worn[id].queue_free()
			_worn.erase(id)
	for id in ids:
		if _worn.has(id):
			continue
		if String(id).begins_with("armor_"):
			var made := _wear_armor(id)
			if made:
				_worn[id] = made
		elif has_method("_wear_" + id):
			_worn[id] = call("_wear_" + id)
	# An armor helmet replaces the starting iron cap; a hand-built one brings his hat hair (the head is swapped).
	var armored_head := false
	var hat_hair := false
	for id in _worn:
		armored_head = armored_head or String(id).begins_with("armor_head_")
		hat_hair = hat_hair or (is_instance_valid(_worn[id]) and _worn[id].has_meta("hat_hair"))
	if _cap:
		_cap.visible = not armored_head
	if is_instance_valid(_body_head):
		_body_head.visible = not hat_hair
	# Hand-built boots have soles under his feet: stand him on them (owner, Nov 18: "feet go deep into the ground").
	var sole := 0.0
	for id in _worn:
		if is_instance_valid(_worn[id]) and _worn[id].has_meta("sole"):
			sole = maxf(sole, float(_worn[id].get_meta("sole")))
	if is_instance_valid(_body_root) and scale.y > 0.0:
		_sole_y = sole / scale.y
		_body_root.position.y = _sole_y + _roll_lift


## Armor sets (docs/design/armor.md): colour + surface of each material.
const ARMOR := {
	"hide": [Color(0.42, 0.28, 0.17), "leather"],
	"leather": [Color(0.48, 0.32, 0.2), "leather"],
	"shell": [Color(0.55, 0.5, 0.44), "stone"],
	"copper": [Color(0.78, 0.47, 0.25), "metal"],
	"husk": [Color(0.44, 0.4, 0.27), "fungus"],
	"silver": [Color(0.8, 0.82, 0.88), "metal"],
	"ironshell": [Color(0.3, 0.32, 0.35), "metal"],
}


## Hand-built armor sets, made over the hand-built body (tools/asset_forge/builds/dwarf_armor.py): look -> file.
## Each file holds armor_<head|chest|feet>_<part> meshes on the body's skeleton; the head also brings armor_head_hair,
## the head with its hair pressed in under the cap (worn instead of the normal head, painted with its pictures).
## The game's leather items use the look "leather": that is the Hide set (docs/design/armor.md).
const ARMOR_FILES := {
	"hide": "res://assets/characters/dwarf/armor_hide.glb", "leather": "res://assets/characters/dwarf/armor_hide.glb",
}
var _bind_poses := []  ## every bone as the body was built (set by _wear_body)
var _model_to_skel := Transform3D()
var _body_head: MeshInstance3D
var _body_root: Node3D  ## the whole visible dwarf (lifted onto boot soles)
var _sole_y := 0.0      ## how far the boot soles lift him (in our own units)
var _roll_lift := 0.0   ## how far he is lifted mid-roll (in our own units): see _lift_roll
var _full_clip := ""    ## the whole-body one-shot playing now
var _full_start := 0.0  ## when it started (s)
var _full_length := 0.0 ## and how long it plays (s)
## How far hand-built boot soles reach below his bare feet standing (metres; measured on the recorded clips, Nov 18: the
## sole is built 1.1 cm down, but the standing pose tips the foot, so the boot's lowest point is ~1.7 cm lower still).
const ARMOR_SOLE := 0.029


## Builds one armor piece from its id: armor_<head|chest|feet>_<material>. A hand-built set (ARMOR_FILES) when the
## hand-built body is worn; otherwise simple shapes on bones (sizes in each bone's own units, front toward +Z).
func _wear_armor(id: String) -> Node3D:
	var parts := id.split("_")
	if parts.size() < 3:
		return null
	if not _bind_poses.is_empty() and ARMOR_FILES.has(parts[2]) and ResourceLoader.exists(ARMOR_FILES[parts[2]]):
		var made := _wear_built_armor(parts[1], ARMOR_FILES[parts[2]])
		if made:
			return made
	if not ARMOR.has(parts[2]):
		return null
	var tier: String = parts[2]
	var col: Color = ARMOR[tier][0]
	var surf: String = ARMOR[tier][1]
	var holder := Node3D.new()
	add_child(holder)
	match parts[1]:
		"head":
			_helmet_shape(_on_bone("Head", holder), tier, col, surf)
		"chest":
			# A shell over chest and belly (on the middle spine bone), and a rim at the waist.
			var chest := _on_bone("spine_02", holder)
			_piece(chest, _ball(0.5), col, surf, Vector3(0, 0.06, 0.012), Vector3(0.4, 0.42, 0.31))  # breastplate shell
			var trim := col.darkened(0.25) if tier != "hide" else Color(0.55, 0.38, 0.2)
			var waist := _on_bone("spine_01", holder)
			_piece(waist, _ring(0.15, 0.17), trim, "metal", Vector3(0, 0.03, 0.01), Vector3(1.0, 1.0, 0.85))  # waist rim
			for side in ["l", "r"]:
				var arm := _on_bone("upperarm_" + side, holder)
				_piece(arm, _ball(0.5, true), col, surf, Vector3(0, 0.02, 0), Vector3(0.2, 0.16, 0.2))  # shoulder guard
				_piece(arm, _ring(0.085, 0.1), trim, "metal", Vector3(0, 0.0, 0), Vector3.ONE)
		"legs":
			for side in ["l", "r"]:
				var thigh := _on_bone("thigh_" + side, holder)
				_piece(thigh, _tube(0.12, 0.1, 0.2), col, surf, Vector3(0, 0.12, 0.01), Vector3(1.0, 1.0, 1.05))  # thigh guard
		"feet":
			for side in ["l", "r"]:
				var shin := _on_bone("calf_" + side, holder)
				_piece(shin, _tube(0.1, 0.11, 0.16), col, surf, Vector3(0, 0.08, 0.01), Vector3(1.0, 1.0, 1.05))  # shin guard
				var foot := _on_bone("foot_" + side, holder)
				_piece(foot, _ball(0.5), col, surf, Vector3(0, 0.08, 0.03), Vector3(0.13, 0.16, 0.12))  # toe cap
	for mi: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
		mi.layers = DwarfModel.VISUAL_LAYER
	return holder


## One piece of a hand-built set (slot: head, chest, feet): its meshes go onto the skeleton like the body's and are freed
## with the returned holder. Null when the file has no such piece (e.g. the legs slot: sets have 3 pieces).
func _wear_built_armor(slot: String, path: String) -> Node3D:
	var src: Node = (load(path) as PackedScene).instantiate()
	var found := src.find_children("armor_%s_*" % slot, "MeshInstance3D", true, false)
	if found.is_empty():
		src.free()
		return null
	var holder := Node3D.new()
	holder.name = "armor_" + slot
	add_child(holder)
	if slot == "feet":
		holder.set_meta("sole", ARMOR_SOLE)
	for mi: MeshInstance3D in found:
		var hair := String(mi.name).begins_with("armor_head_hair")
		_bind_to_skeleton(mi)
		if hair:
			holder.set_meta("hat_hair", true)
			if is_instance_valid(_body_head):  # (painted with the normal head's pictures: same picture map)
				mi.material_override = _body_head.get_active_material(0)
		holder.tree_exiting.connect(mi.queue_free)
	src.free()
	return holder


func _helmet_shape(att: Node3D, tier: String, col: Color, surf: String) -> void:
	var dome := _piece(att, _ball(0.5, true), col, surf, Vector3(0, 0.115, -0.02), Vector3(0.27, 0.32, 0.29))
	var band := col.darkened(0.3) if tier != "hide" else Color(0.3, 0.2, 0.12)
	_piece(att, _ring(0.124, 0.142), band, "metal", Vector3(0, 0.12, -0.02), Vector3(1.0, 0.6, 1.1))
	match tier:
		"hide", "leather":
			for x in [-1.0, 1.0]:  # ear flaps
				_piece(att, _ball(0.5), col, surf, Vector3(x * 0.12, 0.05, -0.01), Vector3(0.04, 0.12, 0.1))
		"copper":
			_piece(att, BoxMesh.new(), col, surf, Vector3(0, 0.08, 0.14), Vector3(0.026, 0.1, 0.02))  # nose guard
		"husk", "shell":
			for i in 3:  # shell ridges
				_piece(att, _ball(0.5), col.darkened(0.15), surf, Vector3(0, 0.2 + i * 0.01, -0.09 + i * 0.07), Vector3(0.05, 0.05, 0.08))
		"silver":
			for x in [-1.0, 1.0]:  # cheek guards
				_piece(att, BoxMesh.new(), col, surf, Vector3(x * 0.11, 0.04, 0.07), Vector3(0.02, 0.1, 0.09))
			_piece(att, BoxMesh.new(), col, surf, Vector3(0, 0.08, 0.14), Vector3(0.026, 0.1, 0.02))
		"ironshell":
			dome.scale *= Vector3(1.05, 1.1, 1.05)
			_piece(att, BoxMesh.new(), col, surf, Vector3(0, 0.07, 0.13), Vector3(0.18, 0.09, 0.025))  # face plate
			for x in [-1.0, 1.0]:  # eye slits are the gaps between plates
				_piece(att, BoxMesh.new(), col.lightened(0.15), "metal", Vector3(x * 0.05, 0.12, 0.135), Vector3(0.05, 0.02, 0.02))


func _on_bone(bone: String, holder: Node3D) -> Node3D:
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	skeleton.add_child(att)
	# Freed together with the piece: the holder remembers its bone attachments.
	holder.tree_exiting.connect(att.queue_free)
	return _head_space(att)


## For a piece riding on the neck or head: ride on its unskewed twin instead (EvenHead), in a node that stands exactly
## where the real bone stands at rest, so pieces made in the head bone's own units still fit. Other bones: att itself.
func _head_space(att: BoneAttachment3D) -> Node3D:
	if not _even.has(att.bone_name):
		return att
	var real := skeleton.find_bone(att.bone_name)
	att.bone_name = _even[att.bone_name]
	var twin := skeleton.find_bone(att.bone_name)
	var space := Node3D.new()
	space.name = "HeadSpace"
	space.transform = (_bind_poses[twin] as Transform3D).affine_inverse() * (_bind_poses[real] as Transform3D)
	att.add_child(space)
	return space


func _piece(parent: Node3D, mesh: Mesh, col: Color, surf: String, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Look.mat(col, surf)
	mi.position = pos
	mi.scale = size
	mi.layers = DwarfModel.VISUAL_LAYER
	parent.add_child(mi)
	return mi


static func _ball(r: float, half: bool = false) -> Mesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * (1.0 if half else 2.0)
	m.is_hemisphere = half
	m.radial_segments = 16
	m.rings = 8
	return m


static func _ring(inner: float, outer: float) -> Mesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 20
	m.ring_segments = 6
	return m


static func _tube(top: float, bottom: float, h: float) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 12
	m.rings = 1
	return m


## Spore Mask: a cloth mask over nose and mouth with two round filters (head bone units,
## face toward +Z; see _build_helmet for the measurements).
func _wear_spore_mask() -> Node3D:
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	skeleton.add_child(att)
	var on := _head_space(att)  # (F280: the unskewed head)
	var cloth := Color(0.5, 0.58, 0.42)
	var sm := SphereMesh.new()
	sm.radius = 0.1
	sm.height = 0.2
	sm.radial_segments = 12
	sm.rings = 6
	var mask := MeshInstance3D.new()
	mask.mesh = sm
	mask.position = Vector3(0, 0.03, 0.115)
	mask.scale = Vector3(1.35, 0.75, 0.7)
	mask.material_override = Look.mat(cloth, "cloth")
	on.add_child(mask)
	for x in [-0.075, 0.075]:
		var f := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.035
		cm.bottom_radius = 0.04
		cm.height = 0.035
		cm.radial_segments = 10
		f.mesh = cm
		f.position = Vector3(x, 0.0, 0.17)
		f.rotation = Vector3(PI / 2.0, 0, x * 3.0)
		f.material_override = Look.mat(Color(0.35, 0.33, 0.3), "metal")
		on.add_child(f)
	for mi: MeshInstance3D in att.find_children("*", "MeshInstance3D", true, false):
		mi.layers = DwarfModel.VISUAL_LAYER
	return att


## A dwarf helmet on the head bone. Sizes are in the head bone's own units (measured: the skull
## is about ±0.15 wide, its top at +0.21 up, the face toward +Z).
func _build_helmet() -> void:
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	skeleton.add_child(att)
	_cap = att
	var iron := Color(0.5, 0.5, 0.53)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.128
	sm.height = 0.128
	sm.is_hemisphere = true
	sm.radial_segments = 16
	sm.rings = 6
	dome.mesh = sm
	dome.position = Vector3(0, 0.115, -0.02)
	dome.scale = Vector3(1.0, 1.25, 1.1)
	dome.material_override = Look.mat(iron, "metal")
	att.add_child(dome)
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.124
	tm.outer_radius = 0.14
	tm.rings = 20
	tm.ring_segments = 6
	rim.mesh = tm
	rim.position = Vector3(0, 0.12, -0.02)
	rim.scale = Vector3(1.0, 0.6, 1.1)
	rim.material_override = Look.mat(Color(0.55, 0.38, 0.2), "metal")  # a bronze band
	att.add_child(rim)
	var ridge := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(0.022, 0.026, 0.18)
	ridge.mesh = rb
	ridge.position = Vector3(0, 0.25, -0.02)
	ridge.material_override = Look.mat(Color(0.55, 0.38, 0.2), "metal")
	att.add_child(ridge)
	var nose := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(0.026, 0.1, 0.02)
	nose.mesh = nb
	nose.position = Vector3(0, 0.08, 0.14)
	nose.material_override = Look.mat(iron, "metal")
	att.add_child(nose)
	for mi in [dome, rim, ridge, nose]:
		mi.layers = DwarfModel.VISUAL_LAYER


## The big dwarf beard: a full, lumpy beard that grows from the jaw and flows down onto the chest,
## built from rings (like stacking hoops of different sizes and wrapping them in skin).
## It rides on the head bone, so it turns with the head. Head bone units: face toward +Z.
func _build_beard() -> void:
	var att := BoneAttachment3D.new()
	att.bone_name = "Head"
	skeleton.add_child(att)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const RINGS := 9
	const AROUND := 12
	var rings := []
	for r in RINGS:
		var t := float(r) / (RINGS - 1)
		var y := lerpf(0.05, -0.46, t)                  # from the jaw down onto the chest
		var z := lerpf(0.07, 0.17, sqrt(t))             # follows the chest forward
		var w := 0.135 * (1.0 + 0.3 * sin(PI * t * 0.85)) * (1.0 - 0.8 * t * t)  # widest in the middle
		var d := 0.075 * (1.0 - 0.55 * t)
		var ring := []
		for a in AROUND:
			var ang := TAU * a / AROUND
			var lump := 1.0 + 0.12 * sin(ang * 3.0 + r * 1.7) * t  # hand-made, uneven locks
			ring.append(Vector3(cos(ang) * w * lump, y, z + sin(ang) * d * lump))
		rings.append(ring)
	var tip := Vector3(0, -0.53, 0.19)
	for r in RINGS - 1:
		for a in AROUND:
			var b := (a + 1) % AROUND
			_quad(st, rings[r][a], rings[r][b], rings[r + 1][b], rings[r + 1][a])
	for a in AROUND:
		st.add_vertex(rings[RINGS - 1][a])
		st.add_vertex(tip)
		st.add_vertex(rings[RINGS - 1][(a + 1) % AROUND])
	# A thick moustache: two drooping tufts under the nose.
	for sx in [-1.0, 1.0]:
		var root := Vector3(0.02 * sx, 0.075, 0.155)
		var end := Vector3(0.12 * sx, -0.01, 0.12)
		for a in 6:
			var a0 := TAU * a / 6.0
			var a1 := TAU * (a + 1) / 6.0
			var o0 := Vector3(0, cos(a0), sin(a0)) * 0.025
			var o1 := Vector3(0, cos(a1), sin(a1)) * 0.025
			st.add_vertex(root + o0)
			st.add_vertex(end)
			st.add_vertex(root + o1)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := Look.mat(BEARD_COLOR, "bark", 0.0, 0.0)  # bark's long streaks read as strands of hair
	mi.material_override = m
	mi.layers = DwarfModel.VISUAL_LAYER
	att.add_child(mi)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, c, b, a, d, c]:  # this order makes the outside the visible side
		st.add_vertex(v)


## The pack's short chin beard, stretched into a big dwarf beard: longer down onto the chest,
## fuller and pushed forward. Works in the head bone's space (where the face points to +Z).
static func _big_beard(mi: MeshInstance3D) -> Mesh:
	var bind := -1
	for i in mi.skin.get_bind_count():
		if String(mi.skin.get_bind_name(i)) == "Head":
			bind = i
	if bind < 0:
		return mi.mesh
	var to_head := mi.skin.get_bind_pose(bind)
	var from_head := to_head.affine_inverse()
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var pivot := Vector3(0, 0.075, 0.05)  # just under the nose
	for i in verts.size():
		var d := to_head * verts[i] - pivot
		var t := clampf(-d.y / 0.05, 0.0, 1.0)  # 0 = moustache, 1 = the hanging part
		var k := Vector3(1.15, 1.1, 1.1).lerp(Vector3(1.25, 1.3, 1.15), t)  # only a little: it must stay on the face
		verts[i] = from_head * (pivot + d * k)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = arrays[Mesh.ARRAY_NORMAL]
	var m := ArrayMesh.new()
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if bones.size() == verts.size() * 8 else 0
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	m.surface_set_material(0, mi.mesh.surface_get_material(0))
	return m


## A soft light along the dwarf's outline, so they stand out against the dark cave
## (the same trick the painted props use; see Look / prop.gdshader).
static func _add_rim(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i) as BaseMaterial3D
		if m == null:
			continue
		if mi.get_surface_override_material(i) == null and mi.material_override == null:
			m = m.duplicate()
		m.rim_enabled = true
		m.rim = 0.35
		m.rim_tint = 0.6
		if mi.material_override == null:
			mi.set_surface_override_material(i, m)


## Each player's shirt and hood get their own colour (host blue, then red, green, gold).
func _tint_clothes(tint: Color) -> void:
	var soft := Color.WHITE.lerp(tint * 1.8, 0.6)
	for part in ["Male_Ranger_Body"]:
		var mi := skeleton.get_node_or_null(part) as MeshInstance3D
		if mi == null:
			continue
		var m := mi.get_active_material(0).duplicate() as BaseMaterial3D
		if m:
			m.albedo_color = soft
			mi.set_surface_override_material(0, m)


## Builds our own animations (MADE) once: for every bone, take its pose at the chosen moments of
## the pack's animations and use those as keys (like a flip book made from other flip books).
static func _made_library() -> AnimationLibrary:
	if _made:
		return _made
	_made = AnimationLibrary.new()
	var src := {"": _library(LIBS[""]), "b": _library(LIBS["b"])}
	for anim_name in MADE:
		var keys: Array = MADE[anim_name]
		var out := Animation.new()
		out.length = 1.0
		var first := _source(src, keys[0][1])
		for t in first.get_track_count():
			var kind := first.track_get_type(t)
			if kind != Animation.TYPE_ROTATION_3D and kind != Animation.TYPE_POSITION_3D:
				continue
			var path := first.track_get_path(t)
			var nt := out.add_track(kind)
			out.track_set_path(nt, path)
			for k in keys:
				var a := _source(src, k[1])
				var st := a.find_track(path, kind)
				if st < 0:
					continue
				var at: float = k[2] * a.length
				if kind == Animation.TYPE_ROTATION_3D:
					out.rotation_track_insert_key(nt, k[0], a.rotation_track_interpolate(st, at))
				else:
					out.position_track_insert_key(nt, k[0], a.position_track_interpolate(st, at))
		_made.add_animation(anim_name, out)
	for anim_name in MADE_SPLIT:
		_made.add_animation(anim_name, _split_anim(src, MADE_SPLIT[anim_name]))
	return _made


## See MADE_SPLIT. Which bones are "upper body" is read from the bone names in the track paths.
const UPPER_ROOTS := ["spine_", "neck_", "Head", "clavicle", "upperarm", "lowerarm", "hand_",
	"index_", "middle_", "pinky_", "ring_", "thumb_"]


static func _split_anim(src: Dictionary, keys: Array) -> Animation:
	var out := Animation.new()
	out.length = 1.0
	out.loop_mode = Animation.LOOP_LINEAR
	var first := _source(src, keys[0][1])
	for t in first.get_track_count():
		var kind := first.track_get_type(t)
		if kind != Animation.TYPE_ROTATION_3D and kind != Animation.TYPE_POSITION_3D:
			continue
		var path := first.track_get_path(t)
		var bone := String(path.get_concatenated_subnames())
		var upper := false
		for r in UPPER_ROOTS:
			if bone.begins_with(r):
				upper = true
		var nt := out.add_track(kind)
		out.track_set_path(nt, path)
		for k in keys:
			var a := _source(src, k[1] if upper else k[3])
			var st := a.find_track(path, kind)
			if st < 0:
				continue
			var at: float = (k[2] if upper else k[4]) * a.length
			if kind == Animation.TYPE_ROTATION_3D:
				out.rotation_track_insert_key(nt, k[0], a.rotation_track_interpolate(st, at))
			else:
				out.position_track_insert_key(nt, k[0], a.position_track_interpolate(st, at))
	return out


static func _source(src: Dictionary, full_name: String) -> Animation:
	var lib := "b" if full_name.begins_with("b/") else ""
	return (src[lib] as AnimationLibrary).get_animation(full_name.trim_prefix("b/"))


## The animations, loaded once and shared by every dwarf.
static func _library(path: String) -> AnimationLibrary:
	if _libs.has(path):
		return _libs[path]
	var scene: Node = (load(path) as PackedScene).instantiate()
	var player: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
	var lib := player.get_animation_library(&"")
	scene.free()
	_libs[path] = lib
	return lib


## The base body's mesh, cut down to just the head and neck (the clothes cover the rest;
## a full body under the clothes would poke through and cost speed).
static func _head_only(mi: MeshInstance3D) -> Mesh:
	if _head_mesh:
		return _head_mesh
	var src := mi.mesh
	var keep := {}
	for i in mi.skin.get_bind_count():
		var bn := String(mi.skin.get_bind_name(i))
		if bn in ["Head", "neck_01"]:
			keep[i] = true
	var arrays := src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / verts.size()
	var head_vert := PackedByteArray()
	head_vert.resize(verts.size())
	for v in verts.size():
		var best := 0
		for k in per:
			if weights[v * per + k] > weights[v * per + best]:
				best = k
		head_vert[v] = 1 if keep.has(bones[v * per + best]) else 0
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var out := PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if head_vert[idx[t]] and head_vert[idx[t + 1]] and head_vert[idx[t + 2]]:
			out.append_array([idx[t], idx[t + 1], idx[t + 2]])
	arrays[Mesh.ARRAY_INDEX] = out
	var m := ArrayMesh.new()
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per == 8 else 0
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
	m.surface_set_material(0, src.surface_get_material(0))
	_head_mesh = m
	return m
