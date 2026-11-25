class_name Music
extends Node
## The game's music (owner's picks, Nov 25): calm solo tracks while exploring, darker ones in caves and dungeons,
## a little more drive in a fight, a deep one near a boss, and short "stingers" (horns, a chime) for big moments.
## Runs on every computer and only listens to what the local player is doing. Volume: SoundSettings.music_volume.

const DIR := "res://assets/music/"
const TRACKS := {
	"explore": ["explore_solo_violin", "explore_meadow_thoughts", "explore_stop_dreaming", "explore_kalimba",
		"explore_dust_guitar", "explore_d125", "explore_celtic_guitar", "explore_piano"],
	"cave": ["cave_crystal_cave", "cave_crystal_caverns", "cave_cavernous_depths", "cave_cave", "cave_dark_drone"],
	"combat": ["combat_percussion", "combat_wasteland"],
	"boss": ["boss_final_confrontation", "boss_dark_descent"],
}
const STINGERS := ["ruin_small", "ruin_medium", "ruin_large", "boss_defeated", "recipe", "recipe_cook"]
## Ruin name (lowercase) -> horn. Anything not listed is medium. A simple table: change it freely.
const RUIN_SIZE := {"outpost": "small", "tower": "small", "manor": "large", "spire": "large"}
const BOSS_RANGE := 40.0
const COMBAT_RANGE := 18.0
const FADE := 3.0  ## seconds to cross from one track to the next
const DUCK_DB := -8.0  ## the music dips this much while a stinger plays
const STINGER_DB := {"recipe_cook": -8.0}  ## the cooking harp is meant to be quiet

var auth: GameAuthority
var state := ""
var _a := AudioStreamPlayer.new()
var _b := AudioStreamPlayer.new()
var _cur: AudioStreamPlayer
var _stinger := AudioStreamPlayer.new()
var _last := {}  ## state -> last track, so one never repeats right away
var _timer := 0.0
var _gap := 0.0  ## silence between calm tracks
var _duck := 0.0


static func stream(name: String) -> AudioStream:
	var s := load(DIR + name + ".ogg") as AudioStream
	return s


## Which music fits `p`? Pure choice, no sound: used by the game and by the tests.
static func state_for(in_cave: bool, boss_near: bool, fighting: bool) -> String:
	if boss_near:
		return "boss"
	if fighting:
		return "combat"
	return "cave" if in_cave else "explore"


static func ruin_stinger(ruin_name: String) -> String:
	return "ruin_" + String(RUIN_SIZE.get(ruin_name.to_lower(), "medium"))


func _ready() -> void:
	SoundSettings.apply()
	for p in [_a, _b, _stinger]:
		p.bus = SoundSettings.MUSIC_BUS
		add_child(p)
	_a.volume_db = -80.0
	_b.volume_db = -80.0
	if auth != null:
		auth.music_stinger.connect(play_stinger)


func play_stinger(name: String) -> void:
	var s := stream("stinger_" + name)
	if s == null:
		return
	_stinger.stream = s
	_stinger.volume_db = float(STINGER_DB.get(name, 0.0))
	_stinger.play()
	_duck = s.get_length() + 1.0


func _process(delta: float) -> void:
	_duck = maxf(_duck - delta, 0.0)
	var duck_db := DUCK_DB if _duck > 0.0 else 0.0
	var other := _b if _cur == _a else _a
	if _cur != null:
		_cur.volume_db = move_toward(_cur.volume_db, duck_db, 40.0 / FADE * delta)
	if other.playing:
		other.volume_db = move_toward(other.volume_db, -80.0, 40.0 / FADE * delta)
		if other.volume_db <= -79.0:
			other.stop()
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = 0.5
	var now := _look()
	var ended := _cur == null or not _cur.playing
	if now != state or ended:
		if now == state and state == "explore":  # a calm track ended: breathe a little before the next
			_gap -= 0.5
			if _gap > 0.0:
				return
		_play(now)


## What the local player is doing right now.
func _look() -> String:
	if auth == null or auth.monsters == null:
		return "explore"
	var ps: GameAuthority.PlayerState = auth.get_player(auth.local_peer_id())
	if ps == null or ps.node == null:
		return "explore"
	var p: Vector3 = ps.node.global_position
	var boss := false
	var fight := false
	for m in auth.monsters.monsters.values():
		if not is_instance_valid(m) or not m.is_alive():
			continue
		var d: float = m.global_position.distance_to(p)
		if m.data.get("boss", false) and d < BOSS_RANGE:
			boss = true
		elif d < COMBAT_RANGE and (m.angry() or m.state in [Monster.State.CHASE, Monster.State.ATTACK, Monster.State.ALERT]):
			fight = true
	return state_for(_in_cave(p), boss, fight)


func _in_cave(p: Vector3) -> bool:
	if auth.world == null or auth.world.maker == null:
		return false
	for d in auth.world.maker.dungeons:
		if DungeonMap.space_at(d, p) != "":
			return true
	for r in auth.world.maker.rooms:
		if MonsterManager.inside_room(r, p):
			return true
	return false


func _play(new_state: String) -> void:
	state = new_state
	var list: Array = TRACKS[new_state]
	var pick: String = list[randi() % list.size()]
	if list.size() > 1:
		while pick == _last.get(new_state, ""):
			pick = list[randi() % list.size()]
	_last[new_state] = pick
	var s := stream(pick)
	if s == null:
		return
	var next := _b if _cur == _a else _a
	next.stream = s
	next.volume_db = -80.0
	next.play()
	_cur = next
	_gap = randf_range(10.0, 30.0)  # (only used by calm tracks)
