class_name BuildLessons
extends RefCounted
## Step-by-step Build Hammer lessons (owner F579: "the wall of keys needs a much better way of teaching").
## One lesson at a time ("NEXT: press B..."); each ticks off the first time you really do it.
## When all are done, the HUD only shows a short one-line key list.
## Progress lives in its own little file on this computer (not in the world save), so a new world
## doesn't teach you again.

const STEPS := [
	{id = "choose", text = "Press B to choose a piece and its material"},
	{id = "place", text = "Left click to place it (the see-through piece shows where)"},
	{id = "turn", text = "Press Q or E to turn it"},
	{id = "lift", text = "Hold Shift and roll the mouse wheel to raise or lower it"},
	{id = "pickup", text = "Right click a piece you just placed to pick it up (works for 10 s)"},
]
const SHORT_KEYS := "B piece · Click place · Q/E turn · Shift+wheel up/down · Right click pick up · X break · V blueprints"

var path := "user://build_lessons.cfg"
var done := {}  ## step id -> true


func _init(p_path: String = "") -> void:
	if p_path != "":
		path = p_path
	elif ClaudeTest.active() or _in_auto_checks():  # Claude's test games and the auto-checks never tick off the owner's lessons
		path = "user://claude_test_build_lessons.cfg"
	load_progress()


static func _in_auto_checks() -> bool:
	var loop := Engine.get_main_loop()
	return loop != null and loop.get_script() != null and str(loop.get_script().resource_path).begins_with("res://tests/")


func load_progress() -> void:
	done.clear()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for s in STEPS:
		if cfg.get_value("done", s.id, false):
			done[s.id] = true


func _save() -> void:
	var cfg := ConfigFile.new()
	for id in done:
		cfg.set_value("done", id, true)
	cfg.save(path)


## The player just did this step. Returns true if it was new (so the HUD can cheer).
func mark(id: String) -> bool:
	if done.has(id):
		return false
	done[id] = true
	_save()
	return true


func all_done() -> bool:
	for s in STEPS:
		if not done.has(s.id):
			return false
	return true


func count_done() -> int:
	var n := 0
	for s in STEPS:
		if done.has(s.id):
			n += 1
	return n


## The id of the lesson to show now ("" = all learned).
func next_id() -> String:
	for s in STEPS:
		if not done.has(s.id):
			return s.id
	return ""


## What the HUD shows: finished lessons ticked, the next one big, later ones hidden (one thing at a time).
func text() -> String:
	if all_done():
		return SHORT_KEYS
	var lines := ["Learning the hammer (%d of %d):" % [count_done(), STEPS.size()]]
	for s in STEPS:
		if done.has(s.id):
			lines.append("  ✓ " + s.text)
		else:
			lines.append("NEXT:  " + s.text)
			break
	return "\n".join(lines)
