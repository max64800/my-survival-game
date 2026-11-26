extends SceneTree


## Counts every engine/script error, so a crashing check can't sneak through as PASS.
class ErrorCounter extends Logger:
	var count := 0
	var last := ""

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _bt: Array[ScriptBacktrace]) -> void:
		count += 1
		last = "%s (%s:%d %s)" % [rationale if rationale != "" else code, file.get_file(), line, function]

	func _log_message(_message: String, _error: bool) -> void:
		pass


var errors := ErrorCounter.new()

## Runs every auto-check in tests/test_*.gd and prints PASS / FAIL.
## Run: godot --headless --path . --script res://tests/run_tests.gd
## Optional: -- only=cave   (only files whose name contains "cave")
##           -- fn=root_tree   (only tests whose name contains "root_tree"; with only= it's quick)
##           -- verbose=1   (also print every PASS line; by default only FAILs + the summary, to save Claude tokens)
##           -- full=1   (also run the slow checks; see below)
## Quick runs (owner, Nov 26: the suite took 30+ min): every run saves how long each check took (TIMES_PATH,
## on this computer only). A plain run then skips checks that took SLOW_MS or more last time (world-growing and
## ruin-rebuild checks); full=1 runs them all. only=/fn= always run what they pick.

const TIMES_PATH := "user://test_times.json"
const SLOW_MS := 10000


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	OS.add_logger(errors)
	Controls.robot = true  # tests never hold the real mouse, and save into user://robot_saves
	var only := ""
	var fn := ""
	var verbose := false
	var full := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			only = arg.trim_prefix("only=")
		if arg.begins_with("fn="):
			fn = arg.trim_prefix("fn=")
		if arg == "verbose=1":
			verbose = true
		if arg == "full=1":
			full = true
	var times := _load_times()
	var quick := not full and only == "" and fn == ""
	var skipped := 0
	var files := DirAccess.get_files_at("res://tests")
	var total := 0
	var failed := 0
	var t0 := Time.get_ticks_msec()
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_case.gd":
			continue
		if only != "" and not f.contains(only):
			continue
		var before_load := errors.count
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate() or errors.count > before_load:
			total += 1
			failed += 1
			print("  FAIL  %s does not compile: %s" % [f, errors.last])
			continue
		for m in script.get_script_method_list():
			if not m.name.begins_with("test_") or (fn != "" and not m.name.contains(fn)):
				continue
			var key := "%s.%s" % [f.get_basename(), m.name]
			if quick and int(times.get(key, 0)) >= SLOW_MS:
				skipped += 1
				continue
			var t: TestCase = script.new()
			t.tree = self
			var start := Time.get_ticks_msec()
			var errs_before := errors.count
			await t.call(m.name)
			if errors.count > errs_before:
				t.failures.append("script error: " + errors.last)
			total += 1
			var ms := Time.get_ticks_msec() - start
			times[key] = ms
			if t.failures.is_empty():
				if verbose:
					print("  PASS  %s.%s  (%d ms)" % [f.get_basename(), m.name, ms])
				elif ms > 20000:
					print("  PASS  %s.%s  (slow: %d s)" % [f.get_basename(), m.name, ms / 1000])
			else:
				failed += 1
				print("  FAIL  %s.%s" % [f.get_basename(), m.name])
				for msg in t.failures:
					print("        - ", msg)
	_save_times(times)
	print("\n%d checks, %d failed, %.1f s" % [total, failed, (Time.get_ticks_msec() - t0) / 1000.0])
	if skipped > 0:
		print("Quick run: skipped %d slow checks (full=1 runs them too)" % skipped)
	print("ALL PASSED" if failed == 0 else "SOME FAILED")
	quit(1 if failed > 0 else 0)


func _load_times() -> Dictionary:
	var f := FileAccess.open(TIMES_PATH, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func _save_times(times: Dictionary) -> void:
	var f := FileAccess.open(TIMES_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(times, "	", true))
