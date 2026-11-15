extends SceneTree
## Saves the creatures as 3D files (.glb) so they can be looked at outside the game
## (the owner's 3D viewer page): every hand-built individual version, plus the special poses
## (hiding, asleep, charging, leader), exactly as the game builds them.
##   godot --headless --audio-driver Dummy --path . --script res://src/debug/monster_export.gd -- out=/folder autopilot
## Writes <out>/<id>.glb and <out>/models.json.

## id, kind, pose, label, seed (= version), group, sound, sound pitch, note
const POSES := [
	["rock_snail_v0", "rock_snail", "walk", "Rock Snail: slate", 0, "Rock Snail", "snail_slam", 1.0, "Very slow, hits hard. Bumpy damp skin, a fleshy collar, a breathing hole on its side, a stone shell with moss and stuck stones."],
	["rock_snail_v1", "rock_snail", "walk", "Rock Snail: olive", 1, "Rock Snail", "snail_slam", 1.0, "Olive skin, a sandy shell with less moss and more stones stuck to it."],
	["rock_snail_v2", "rock_snail", "walk", "Rock Snail: rusty", 2, "Rock Snail", "snail_slam", 1.0, "Rusty skin, a dark slate shell with a violet crystal growing out of it."],
	["rock_snail_hiding", "rock_snail", "hide", "Hiding in its shell", 0, "Rock Snail", "shell_clunk", 1.0, "After 3 hits: the whole body (tail too) pulls in, the shell settles on the ground, only two eyes peek out. 90% less damage for 3 seconds."],
	["rock_snail_leader", "rock_snail", "leader", "Old Shellback (leader)", 1, "Rock Snail", "snail_slam", 0.85, "A pack leader: bigger, with a glowing gold crown so you can spot it."],
	["cave_bat_v0", "cave_bat", "fly", "Cave Bat: brown", 0, "Cave Bat", "bat_screech", 1.0, "Dog-sized, wings about 1.5 m. Squeals right before it dives to bite."],
	["cave_bat_v1", "cave_bat", "fly", "Cave Bat: ash grey", 1, "Cave Bat", "bat_screech", 1.05, "Ash-grey fur. This one has a torn ear from an old fight."],
	["cave_bat_v2", "cave_bat", "fly", "Cave Bat: rust", 2, "Cave Bat", "bat_screech", 0.95, "Rust-red fur."],
	["cave_bat_v3", "cave_bat", "fly", "Cave Bat: sandy", 3, "Cave Bat", "bat_screech", 1.1, "Pale sandy fur, and a torn ear."],
	["cave_bat_roosting", "cave_bat", "roost", "Asleep on the ceiling", 0, "Cave Bat", "bat_flap", 1.0, "Hangs head-down by its feet, wings folded round its body like a cloak."],
	["rock_beetle_v0", "rock_beetle", "walk", "Rock Beetle: curved horn", 0, "Rock Beetle", "beetle_hiss", 1.0, "Built like a real ironclad beetle: waxy shell with black drops, rows of knobs (rock, pebbles, mossy stones), four big knobs at the back, a spiky rim. Amber gems."],
	["rock_beetle_v1", "rock_beetle", "walk", "Rock Beetle: bent horn", 1, "Rock Beetle", "beetle_hiss", 1.0, "Its horn is bent to one side. Teal gems, almost no moss."],
	["rock_beetle_v2", "rock_beetle", "walk", "Rock Beetle: broken horn", 2, "Rock Beetle", "beetle_hiss", 0.95, "Its horn snapped off in a fight (jagged pale break). Very mossy, no gems."],
	["rock_beetle_v3", "rock_beetle", "walk", "Rock Beetle: forked horn", 3, "Rock Beetle", "beetle_hiss", 1.05, "Its horn tip split in two. Amber gems."],
	["rock_beetle_charging", "rock_beetle", "charge", "About to charge", 1, "Rock Beetle", "beetle_rumble", 1.0, "Head down, back end up, eyes red, and the cracks in its shell glow like coals. Then it rushes in a straight line: sidestep!"],
	["great_rock_beetle_v0", "great_rock_beetle", "walk", "Great Rock Beetle: curved horn", 0, "Great Rock Beetle", "beetle_rumble", 0.75, "The big one from the Fungal Jungle: spike rows on its back, side horns, a darker shell."],
	["great_rock_beetle_v1", "great_rock_beetle", "walk", "Great Rock Beetle: bent horn", 1, "Great Rock Beetle", "beetle_rumble", 0.75, "Bent horn, teal gems."],
	["great_rock_beetle_v2", "great_rock_beetle", "walk", "Great Rock Beetle: broken horn", 2, "Great Rock Beetle", "beetle_rumble", 0.72, "Broken horn, very mossy, a violet gem."],
	["great_rock_beetle_v3", "great_rock_beetle", "walk", "Great Rock Beetle: forked horn", 3, "Great Rock Beetle", "beetle_rumble", 0.78, "Forked horn, amber gems."],
]

var _out := "user://monster_export"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.trim_prefix("out=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var list := []
	for p in POSES:
		var data: Dictionary = Monsters.LIST[p[1]]
		var leader: bool = p[2] == "leader"
		var size: float = data.size * (Monsters.LEADER.size if leader else 1.0)
		var m := MonsterModel.build(data.shape, data.color, size, leader, p[1], p[4])
		root.add_child(m)
		match p[2]:
			"hide":
				MonsterModel.set_shell(m, true)
			"roost":
				m.set_meta("roosting", true)
			"charge":
				MonsterModel.set_angry(m, true)
				MonsterModel.set_glow(m, 0.35)
		MonsterModel.animate(m, 1.5 if p[2] == "fly" else 0.0, size, 0.2)  # walkers stand: all feet down
		await create_timer(0.45).timeout  # let the shell tween finish
		if p[2] == "charge":
			m.rotation.x -= 0.22  # head down, back end up (Monster._creature_fx)
			m.position.y += 0.05 * size
		if p[2] == "roost":
			m.position.y += 1.2  # hanging: lift it so it reads as "under the ceiling"
		m.rotation.y += PI  # monsters face -Z in the game; glTF viewers expect +Z
		_plain_materials(m)
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var holder := Node3D.new()
		root.add_child(holder)
		m.reparent(holder)
		_drop_hidden(holder)
		var err := doc.append_from_scene(holder, state)
		if err == OK:
			err = doc.write_to_filesystem(state, _out.path_join(p[0] + ".glb"))
		print("  export: ", p[0], " -> ", error_string(err))
		list.append({id = p[0], kind = p[1], name = p[3], file = p[0] + ".glb", hp = data.hp, size = size,
			habitat = _habitat(p[1]), group = p[5], sound = p[6], rate = p[7], note = p[8]})
		holder.queue_free()
	var f := FileAccess.open(_out.path_join("models.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({models = list}, "\t"))
	f.close()
	quit()


## Hidden parts (the snail's peeking eyes while it's out, the bat's folded wings in flight) would
## still be saved into the file, so take them out first.
func _drop_hidden(node: Node) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible:
			mi.get_parent().remove_child(mi)
			mi.queue_free()


func _habitat(kind: String) -> String:
	match kind:
		"rock_snail", "rock_beetle": return "Mossy Hollows"
		"great_rock_beetle": return "Fungal Jungle"
		"cave_bat": return "Caverns everywhere"
	return ""


## The game's painted-look shader can't go into a .glb: swap it for a plain material with the
## same color, roughness, metal and glow.
func _plain_materials(node: Node) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var src: Material = mi.material_override
		var out: Material = src
		if src is ShaderMaterial:
			var sm := src as ShaderMaterial
			var s := StandardMaterial3D.new()
			s.albedo_color = sm.get_shader_parameter("albedo")
			s.roughness = sm.get_shader_parameter("roughness")
			s.metallic = sm.get_shader_parameter("metallic")
			var glow: float = sm.get_shader_parameter("emission_energy")
			if glow > 0.0:
				s.emission_enabled = true
				var ec: Color = sm.get_shader_parameter("emission_color")
				s.emission = ec
				s.emission_energy_multiplier = glow
			out = s
		elif src is StandardMaterial3D:
			out = (src as StandardMaterial3D).duplicate()
		if out:
			mi.material_override = null
			for i in mi.mesh.get_surface_count():
				mi.set_surface_override_material(i, out)
