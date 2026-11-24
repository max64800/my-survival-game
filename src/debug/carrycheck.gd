extends Node
## Carry check (F793, owner Nov 23): photos of the weight dial above hunger + thirst, light (green),
## heavy (yellow) and overloaded (red).
## Run:  godot --audio-driver Dummy --path . -- carrycheck claude=carryweight seed=42 shots=<folder>

var _main: Node
var _shots := "user://carrycheck"


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
	print("CARRYCHECK shot ", _main.take_screenshot(_shots.path_join(name + ".png")))


func _run() -> void:
	var waited := 0.0
	while not _main.is_ready_to_play() and waited < 150.0:
		await _wait(0.25)
		waited += 0.25
	_main.hud.set_paused(false)
	var auth: GameAuthority = _main.authority
	var inv := auth.get_player(auth.local_peer_id()).inventory
	for step in [["01_light", 100], ["02_heavy", 150], ["03_overloaded", 100]]:
		inv.add("stone", step[1])
		await _wait(1.0)
		var d: Dwarf = _main.hud._local_dwarf()
		print("CARRYCHECK ", step[0], " carry=", d.carry if d else {})
		await _shot(step[0])
	get_tree().quit()
