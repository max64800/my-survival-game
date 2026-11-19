class_name ClaudeTest
extends CanvasLayer
## Marks games that Claude starts for testing (owner, Nov 19), so the owner can tell them apart
## from their own game:
##   - a thick orange frame and a "CLAUDE TEST: don't play this one" label,
##   - what is being tested ("claude=waterfalls" after "--"),
##   - the window name in the taskbar changes too.
## Claude's runs are found by "claude=..." / "claude" after "--", or by the muted sound driver
## ("--audio-driver Dummy") that every Claude run uses. A normal game never shows any of this.
##
## Test worlds go to their own folder (SaveGame.folder), are named "🤖 TEST ...", and are deleted
## when they are older than a day. Only that folder is ever cleaned: the owner's worlds are safe.

const SAVE_FOLDER := "user://claude_test_saves"
const MARK := "🤖 TEST"
const ORANGE := Color(1.0, 0.45, 0.05)
const MAX_AGE := 24 * 60 * 60  ## seconds: test worlds older than a day are cleaned up

static var _checked := false
static var _active := false
static var _what := ""


## True when Claude started this game.
static func active() -> bool:
	if not _checked:
		_checked = true
		for arg in OS.get_cmdline_user_args():
			if arg == "claude" or arg.begins_with("claude="):
				_active = true
				_what = arg.trim_prefix("claude").trim_prefix("=").replace("_", " ")
		var args := OS.get_cmdline_args()
		for i in args.size():
			var a: String = args[i]
			if a == "--audio-driver=Dummy" or (a == "--audio-driver" and i + 1 < args.size() and args[i + 1] == "Dummy"):
				_active = true
	return _active


## What Claude is testing ("" if it didn't say).
static func what() -> String:
	active()
	return _what


## The name a test world gets: "🤖 TEST – waterfalls – safe to delete".
static func world_name(base: String) -> String:
	if base.begins_with(MARK):
		return base
	var w := what() if what() != "" else base
	return "%s – %s – safe to delete" % [MARK, w]


## Deletes test worlds older than a day. Only inside SAVE_FOLDER, only world save files.
static func clean_old_worlds(max_age: int = MAX_AGE) -> int:
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER):
		return 0
	var now := int(Time.get_unix_time_from_system())
	var removed := 0
	for f in DirAccess.get_files_at(SAVE_FOLDER):
		if not f.begins_with("world_") or not ".save" in f:
			continue
		var p := SAVE_FOLDER.path_join(f)
		if now - FileAccess.get_modified_time(p) >= max_age:
			DirAccess.remove_absolute(p)
			removed += 1
	return removed


func _ready() -> void:
	clean_old_worlds()
	if not active() or DisplayServer.get_name() == "headless":
		return
	layer = 128  # above every menu
	var label_text := "🤖 CLAUDE TEST: don't play this one"
	if what() != "":
		label_text += "   |   Testing: " + what()
	get_window().title = "🤖 CLAUDE TEST" + (" – " + what() if what() != "" else "") + " – Dwarf Game"

	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = ORANGE
	box.set_border_width_all(10)
	frame.add_theme_stylebox_override("panel", box)
	add_child(frame)

	var tag := Label.new()
	tag.text = label_text
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_font_size_override("font_size", 26)
	tag.add_theme_color_override("font_color", Color.BLACK)
	var bg := StyleBoxFlat.new()
	bg.bg_color = ORANGE
	bg.content_margin_left = 18
	bg.content_margin_right = 18
	bg.content_margin_top = 6
	bg.content_margin_bottom = 8
	bg.corner_radius_bottom_left = 10
	bg.corner_radius_bottom_right = 10
	tag.add_theme_stylebox_override("normal", bg)
	tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(tag)
