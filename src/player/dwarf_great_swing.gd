class_name DwarfGreatSwing
extends RefCounted
## How the dwarf holds and swings the great axe and the great maul (F389, owner's decision Nov 20: "use the Lampwick
## Foreman's moves"). The moves are the Foreman's own (the CC0 KayKit Skeletons pack: 2H_Melee_Idle, 2H_Melee_Attack_Chop,
## 2H_Melee_Attack_Spin), copied onto the dwarf's bones by tools/asset_forge/great_kaykit_bake.gd into BAKED:
##  - Stance (standing still, a slow loop), Chop (the light attack), Spin (the heavy attack): owner's pick, chat 11.
##  - Mirrored left <-> right (owner: the LEFT fist at the end of the handle, the RIGHT fist high up near the head; the
##    Foreman holds the end in his right hand), so he winds up over his right shoulder.
##  - Each frame gives every big bone its turn (whole-skeleton space), the hips' place, which way the handle points and
##    which way the blade faces. DwarfFist plays them and then puts both fists on the handle: the left at the end, the
##    right slid up it as far as his short arm reaches (the Foreman's fists are bunched and his left hand lets go in the
##    spin), and keeps the handle out of his body (the keep-out guard).
##  - The game's hit lands at 0.40 of a swing (DwarfFight._impact): each clip is sped up or slowed down so its strike
##    (the axe head's fastest moment, found by the bake) lands right there.
## Walking or running without swinging, the great weapon rests on his right shoulder in one hand (owner, round 3).
## Our own hand-made swings (chats 6-10) are gone; their tools/blender_poses/ files stay, unused.
## By the dwarf-animations Claude, chat 11, Nov 20, 2026.

const BAKED := "res://assets/anim/great_kaykit.json"
const MOVES := ["Chop", "Spin"]
## The clip second the strike lands (the end of the fastest frames, great_kaykit_bake.gd prints them; the Chop's
## whole downward strike is 2 frames, 0.80-0.87 s): it lands on HIT_AT of the swing.
const STRIKE := {"Chop": 0.87, "Spin": 0.73}
const HIT_AT := 0.40
## Bones the moves turn, parents first (each one's turn is set after its parent's).
const ORDER := ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head", "clavicle_l", "upperarm_l",
	"lowerarm_l", "hand_l", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r", "thigh_l", "calf_l", "foot_l", "ball_l",
	"thigh_r", "calf_r", "foot_r", "ball_r"]
## Walking, these keep the walk (the swing only moves his top half).
const LEGS := ["pelvis", "thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r"]
const BLEND_IN := 0.10  ## share of a swing spent easing in from wherever he was
const RETURN := 6.0  ## how fast he eases back to the stance after a swing (per second)
## The fists: the right one as far up the handle as this, if his arm reaches (owner: "high up, near the head").
const GAP := 0.46

static var _clips := {}  ## name -> [length (s), frames per second, [pose, ...]]


static func _load() -> void:
	if not _clips.is_empty() or not FileAccess.file_exists(BAKED):
		return
	var all: Variant = JSON.parse_string(FileAccess.get_file_as_string(BAKED))
	if not all is Dictionary:
		return
	var fps := float((all as Dictionary).get("fps", 30.0))
	for clip: String in all:
		if not all[clip] is Dictionary:
			continue
		var poses: Array = []
		for f: Dictionary in all[clip].frames:
			var bones := {}
			for b: String in f.bones:
				var q: Array = f.bones[b]
				bones[b] = Quaternion(q[0], q[1], q[2], q[3]).normalized()
			var w: Array = f.weapon
			var pp: Array = f.pelvis
			poses.append({bones = bones, pelvis = Vector3(pp[0], pp[1], pp[2]),
				handle = Vector3(w[3], w[4], w[5]).normalized(), edge = -Vector3(w[0], w[1], w[2]).normalized()})
		_clips[clip] = [float(all[clip].length), fps, poses]


static func has_moves() -> bool:
	_load()
	return _clips.has("Stance")


## A baked clip's own length (s; 1 if it isn't there).
static func clip_length(clip: String) -> float:
	_load()
	return float(_clips[clip][0]) if _clips.has(clip) else 1.0


## The pose `sec` seconds into a baked clip (between two frames).
static func clip_pose(clip: String, sec: float) -> Dictionary:
	_load()
	if not _clips.has(clip):
		return {}
	var c: Array = _clips[clip]
	var poses: Array = c[2]
	var f := clampf(sec, 0.0, float(c[0])) * float(c[1])
	var i := clampi(int(floor(f)), 0, poses.size() - 1)
	var j := mini(i + 1, poses.size() - 1)
	return blend(poses[i], poses[j], f - float(i))


## The standing stance, `clock` seconds into its slow loop.
static func stance(clock: float) -> Dictionary:
	_load()
	if not _clips.has("Stance"):
		return {}
	return clip_pose("Stance", fposmod(clock, float(_clips["Stance"][0])))


## The swing `move` at `t` (0..1 of the swing): the clip's strike lands at HIT_AT.
static func swing(move: String, t: float) -> Dictionary:
	_load()
	if not _clips.has(move):
		return {}
	return clip_pose(move, clip_time(move, t))


## Where in the clip (s) the swing's share `t` falls: up to the strike, then the rest of the clip.
static func clip_time(move: String, t: float) -> float:
	var length := float(_clips[move][0]) if _clips.has(move) else 1.0
	var hit := float(STRIKE.get(move, length * HIT_AT))
	if t <= HIT_AT:
		return hit * t / HIT_AT
	return hit + (length - hit) * (t - HIT_AT) / (1.0 - HIT_AT)


## A pose part of the way from `a` to `b` (k 0..1): every bone turns the short way.
static func blend(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	if a.is_empty():
		return b
	if b.is_empty():
		return a
	var bones := {}
	for n: String in b.bones:
		bones[n] = (a.bones.get(n, b.bones[n]) as Quaternion).slerp(b.bones[n], k)
	var out := {bones = bones, pelvis = (a.pelvis as Vector3).lerp(b.pelvis, k),
		handle = (a.handle as Vector3).slerp(b.handle, k).normalized(), edge = (a.edge as Vector3).slerp(b.edge, k).normalized()}
	if a.has("tip") or b.has("tip"):  # (the one-handed video moves' weapon tip spot: DwarfFist._one_aim)
		out["tip"] = (a.get("tip", b.get("tip")) as Vector3).lerp(b.get("tip", a.get("tip")), k)
	return out
