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
	# F417: time each part of a frame ourselves. Godot's own "process time" is the slowest frame of the whole last
	# second, updated once a second, so a SLOW FRAME line used to say "game code 38 ms" for a 600 ms game-code frame.
	get_tree().physics_frame.connect(_on_physics_frame)
	get_tree().process_frame.connect(_on_process_frame)
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_post_draw)


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
var _last_pipes := Vector4i.ZERO
var _phys_from := 0  ## when this frame's first physics step started (0 = none yet)
var _proc_from := 0
var _pre_from := 0
var _phys_ms := 0.0  ## this frame's physics steps
var _draw_ms := 0.0  ## the last frame's handing over to the graphics card
var _max_game := 0.0  ## the slowest game code / physics this second (for LOW FPS)
var _max_phys := 0.0


func _on_physics_frame() -> void:
	if _phys_from == 0:
		_phys_from = Time.get_ticks_usec()


func _on_process_frame() -> void:
	_proc_from = Time.get_ticks_usec()
	_phys_ms = (_proc_from - _phys_from) / 1000.0 if _phys_from > 0 else 0.0
	_phys_from = 0


func _on_post_draw() -> void:
	_draw_ms = (Time.get_ticks_usec() - _pre_from) / 1000.0


## A whole frame ends when drawing starts: the time since the last one (measured with the real clock, not `delta`,
## F417: a 1.4 s frame never showed up as SLOW FRAME) = the last drawing + this frame's physics + game code.
func _on_pre_draw() -> void:
	var now := Time.get_ticks_usec()
	var game := (now - _proc_from) / 1000.0 if _proc_from > 0 else 0.0
	_max_game = maxf(_max_game, game)
	_max_phys = maxf(_max_phys, _phys_ms)
	var real := (now - _last_usec) / 1000000.0
	var first := _last_usec == 0
	_last_usec = now
	_pre_from = now
	# F417: graphics-card programs (pipelines) made since the last frame: for newly loaded models ("mesh"), new
	# pieces in the world ("surface"), or at the moment of drawing ("draw": the picture waits for those).
	var pipes := Vector4i(int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH)),
		int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE)),
		int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW)),
		int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION)))
	var new_pipes := pipes - _last_pipes
	_last_pipes = pipes
	if real > SLOW_FRAME and not first:
		_say("[%s] SLOW FRAME: %.1f s (doing: %s) · game code %.0f ms, physics %.0f ms, handing the last picture to the graphics card %.0f ms · new looks readied: %d mesh, %d surface, %d draw, %d special" % [
			_clock(), real, doing, game, _phys_ms, _draw_ms, new_pipes.x, new_pipes.y, new_pipes.z, new_pipes.w])


func _process(delta: float) -> void:
	_beat_ms = Time.get_ticks_msec()
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
	var max_game := _max_game
	var max_phys := _max_phys
	_max_game = 0.0
	_max_phys = 0.0
	if fps >= 50 or _low_quiet > 0.0:  # (owner, Nov 18: drops to 43-47 FPS matter too)
		return
	_low_quiet = 10.0
	var recent_hits := hits
	hits = 0
	var cam := get_viewport().get_camera_3d()
	var at := cam.global_position if cam else Vector3.ZERO
	_say("[%s] LOW FPS %d at (%.0f, %.0f, %.0f) · slowest this second: game code %.1f ms, physics %.1f ms · drawing: cpu %.1f ms, graphics card %.1f ms · %d draw calls, %dk triangles · %d nodes, %d moving physics bodies, %d collision pairs · rock hits lately: %d, flying rock chunks: %d · doing: %s" % [
		_clock(), fps, at.x, at.y, at.z,
		max_game, max_phys,
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
