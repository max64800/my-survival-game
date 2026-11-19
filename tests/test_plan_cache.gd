extends TestCase
## Faster second load (owner, Nov 19): a cave's plans are saved the first time and read back the next time; a plan
## made by different code is never used.


func test_saved_plan_is_read_back_and_code_changes_plan_fresh() -> void:
	var m := CaveMaker.new(4321)
	var made := [0]
	var maker_call := func() -> Array:
		made[0] += 1
		return [{pos = Vector3(1, 2, 3), xf = Transform3D(Basis(), Vector3.ONE), c = Color.RED}]
	var path := PlanCache._path("testplan", m, "res://src/world/plan_cache.gd")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var a: Array = PlanCache.get_or_make("testplan", m, "res://src/world/plan_cache.gd", maker_call)
	var b: Array = PlanCache.get_or_make("testplan", m, "res://src/world/plan_cache.gd", maker_call)
	check_eq(made[0], 1, "planned once, then read from the file")
	check(FileAccess.file_exists(path), "the plan is saved")
	check_eq((b[0] as Dictionary).pos, Vector3(1, 2, 3), "read back the same")
	check_eq((b[0] as Dictionary).xf, Transform3D(Basis(), Vector3.ONE), "transforms survive")
	PlanCache._fingerprints["res://src/world/plan_cache.gd"] = "changedcode"  # as if the planner's code changed
	PlanCache.get_or_make("testplan", m, "res://src/world/plan_cache.gd", maker_call)
	check_eq(made[0], 2, "different code: planned fresh")
	check(not FileAccess.file_exists(path), "the old plan file is cleaned up")
	PlanCache._fingerprints.erase("res://src/world/plan_cache.gd")
	for f in DirAccess.get_files_at(PlanCache.DIR):
		if f.begins_with("4321_"):
			DirAccess.remove_absolute(PlanCache.DIR.path_join(f))
