extends TestCase
## No ruin chest stands on stairs or where they come out (owner, Nov 22: "in the last outpost one of the chests spawns
## on the stairs"). A chest is too close when it is within 1.8 m (sideways) of a stairs piece's middle and level with
## its steps or its top (0 to 2.5 m above its base).


func test_no_ruin_chest_stands_on_the_stairs() -> void:
	var dir := "res://blueprints/ruins"
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".json"):
			continue
		var plan = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		if not plan is Dictionary or not plan.has("chests"):
			continue
		for c in plan.chests:
			var cp := Vector3(c.pos[0], c.pos[1], c.pos[2])
			for p in plan.get("pieces", []):
				if not String(p.id).begins_with("stairs"):
					continue
				var sp := Vector3(p.pos[0], p.pos[1], p.pos[2])
				var side := Vector2(cp.x - sp.x, cp.z - sp.z).length()
				var up := cp.y - sp.y
				check(not (side < 1.8 and up >= 0.0 and up <= 2.5),
					"%s: the %s at %s keeps off the stairs at %s (%.1f m away)" % [f, c.kind, cp, sp, side])
