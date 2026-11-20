extends Node
## Skills window check (owner's mock-up, Nov 19): a level-18 dwarf with a few perks and skills,
## photos of the K window (one with a passive perk chosen, one with an active one).
## Run:  godot --audio-driver Dummy --path . -- skillscheck claude=skills_window seed=42 shots=/some/folder

var _main: Node
var _shots := "user://skillscheck"


func _ready() -> void:
	_main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("shots="):
			_shots = arg.trim_prefix("shots=")
	DirAccess.make_dir_recursive_absolute(_shots)
	_run.call_deferred()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	print("skillscheck: ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 90.0:
		await _wait(0.25)
		waited += 0.25
	var auth: GameAuthority = _main.authority
	var ps := auth.get_player(auth.local_peer_id())
	var p := ps.progress
	p.level = 18
	p.perks = {thick_skin = 2, iron_belly = 1, poison_blood = 1, warriors_grip = 2, light_feet = 1, deep_pockets = 1,
		ore_smasher = 1, shoulder_to_shoulder = 1, war_horn = 1}
	var lv := {running = 18, mining = 34, crafting = 22, sword = 27, shield = 15, cooking = 12}
	for s in lv:
		p.skill_level[s] = lv[s]
	_main.hud.set_paused(false)
	_main.hud.set_skills_open(true)
	Controls.set_captured(false)
	await _wait(0.8)
	await _shot("01_skills_window")
	var sp: SkillsPanel = _main.hud.skills
	sp.tree.select("war_horn")
	sp.tree.picked.emit("war_horn")
	await _wait(0.4)
	await _shot("02_active_perk")
	get_tree().quit()
