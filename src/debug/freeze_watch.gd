class_name FreezeWatch
extends Node
## Writes slowdowns and freezes into the game's log, so a play session's log says what happened (owner, Nov 17:
## "I had 3 FPS... now the game just froze... make sure we have the logs").
## - Every 30 s: the frame rate, and where the player is.
## - A frame that takes over 0.5 s: "SLOW FRAME".
## - The game stuck for over 3 s: a helper thread (it keeps running when the game is stuck) writes "FROZEN", and
##   "UNFROZEN" with how long when it comes back. Each line says what the game was busy with last (`doing`).

const REPORT_EVERY := 30.0
const SLOW_FRAME := 0.5
const FROZEN_AFTER := 3.0

## What the game is busy with right now, for the log ("loading the cave", "building the outpost"...). Set it before
## anything big.
## Each step that took 0.3 s or more is written to the log when the next one starts ("STEP making the cave: 4.2 s"),
## so a long load says which step was slow (owner, Nov 19: 31 s frozen while the cave was made).
static var doing := "starting":
	set(v):
		var now := Time.get_ticks_msec()
		if now - _step_since >= 300:
			_say("[%s] STEP %s: %.1f s" % [_clock(), doing, (now - _step_since) / 1000.0])
			steps.append([doing, (now - _step_since) / 1000.0])
		_step_since = now
		doing = v
static var _step_since := 0
## Every STEP so far as [what, seconds] (the speed check prints the loading steps from it).
static var steps: Array = []
## Rock hits in the last few seconds (the dwarf counts them), so a slow moment says if you were mining.
static var hits := 0

## The player's own watch file (owner, Nov 18: the game log lost every line after "ready to play", because test
## robots on the same PC push the log aside). Every line also goes here, written at once: user://watch.txt.
static var _file: FileAccess
static var _lock := Mutex.new()


static func open_player_file() -> void:
	_file = FileAccess.open("user://watch.txt", FileAccess.WRITE)
	_say("PLAYER GAME watch started " + Time.get_datetime_string_from_system())


static func _say(line: String) -> void:
	print(line)
	_lock.lock()
	if _file:
		_file.store_line(line)
		_file.flush()
	_lock.unlock()

var _beat_ms := 0  ## the last time the game finished a frame (written by the game, read by the helper)
var _quit := false
var _thread: Thread
var _report_t := 0.0
var _frozen_since := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_beat_ms = Time.get_ticks_msec()
	_thread = Thread.new()
	_thread.start(_watch)


func _exit_tree() -> void:
	_quit = true
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## One timed piece of work (F417): written only when it took 0.1 s or more.
static func time_part(what: String, since_usec: int) -> void:
	var ms := (Time.get_ticks_usec() - since_usec) / 1000.0
	if ms >= 100.0:
		_say("[%s] PART %s: %.0f ms" % [_clock(), what, ms])


var _last_usec := 0


func _process(delta: float) -> void:
	_beat_ms = Time.get_ticks_msec()
	# Measured with the real clock, not `delta` (F417: a 1.4 s frame never showed up as SLOW FRAME).
	var now := Time.get_ticks_usec()
	var real := (now - _last_usec) / 1000000.0 if _last_usec > 0 else delta
	_last_usec = now
	if real > SLOW_FRAME:
		_say("[%s] SLOW FRAME: %.1f s (doing: %s) · game code %.0f ms, physics %.0f ms" % [_clock(), real, doing,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0])
	_low_check(delta)
	_report_t += delta
	if _report_t >= REPORT_EVERY:
		_report_t = 0.0
		var cam := get_viewport().get_camera_3d()
		var at := cam.global_position if cam else Vector3.ZERO
		_say("[%s] FPS %d · at (%.0f, %.0f, %.0f) · doing: %s" % [_clock(), Engine.get_frames_per_second(), at.x, at.y, at.z, doing])


## Low frame rate (owner, Nov 18: "sometimes it's 6 FPS, then very smooth again"): once a second, if it's under 20 FPS,
## write what the frame is spending its time on (game code, physics, drawing on the graphics card), at most every 10 s.
var _low_t := 0.0
var _low_quiet := 0.0


func _low_check(delta: float) -> void:
	_low_t += delta
	_low_quiet -= delta
	if _low_t < 1.0:
		return
	_low_t = 0.0
	var vp := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var fps := Engine.get_frames_per_second()
	if fps >= 50 or _low_quiet > 0.0:  # (owner, Nov 18: drops to 43-47 FPS matter too)
		return
	_low_quiet = 10.0
	var recent_hits := hits
	hits = 0
	var cam := get_viewport().get_camera_3d()
	var at := cam.global_position if cam else Vector3.ZERO
	_say("[%s] LOW FPS %d at (%.0f, %.0f, %.0f) · whole frame %.1f ms · physics %.1f ms · drawing: cpu %.1f ms, graphics card %.1f ms · %d draw calls, %dk triangles · %d nodes, %d moving physics bodies, %d collision pairs · rock hits lately: %d, flying rock chunks: %d · doing: %s" % [
		_clock(), fps, at.x, at.y, at.z,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(vp), RenderingServer.viewport_get_measured_render_time_gpu(vp),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS), recent_hits, RockShatter._alive.size(), doing])


## The helper thread: checks twice a second whether the game is still finishing frames.
func _watch() -> void:
	while not _quit:
		OS.delay_msec(500)
		var stuck := (Time.get_ticks_msec() - _beat_ms) / 1000.0
		if stuck > FROZEN_AFTER and _frozen_since == 0:
			_frozen_since = _beat_ms
			_say("[%s] FROZEN: no frame for %.0f s (doing: %s)" % [_clock(), stuck, doing])
		elif _frozen_since != 0 and _beat_ms > _frozen_since:
			_say("[%s] UNFROZEN after %.1f s (doing: %s)" % [_clock(), (_beat_ms - _frozen_since) / 1000.0, doing])
			_frozen_since = 0


static func _clock() -> String:
	return Time.get_time_string_from_system()
