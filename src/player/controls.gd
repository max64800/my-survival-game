class_name Controls
## The game's buttons. Kept in one place so a settings menu (Step 7) can change them.

const KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"run": [KEY_SHIFT],
	"refill_lantern": [KEY_R],
	"toggle_bag": [KEY_TAB, KEY_I],
	"pause": [KEY_ESCAPE],
	"toggle_fps": [KEY_F3],
	"screenshot": [KEY_F12],
	"interact": [KEY_E],
	"toggle_skills": [KEY_K],
	"toggle_map": [KEY_M],
}
const MOUSE := {
	"dig": [MOUSE_BUTTON_LEFT],
	"use": [MOUSE_BUTTON_RIGHT],
	"hotbar_next": [MOUSE_BUTTON_WHEEL_DOWN],
	"hotbar_prev": [MOUSE_BUTTON_WHEEL_UP],
}

const MOUSE_SENSITIVITY := 0.0025


static func setup() -> void:
	for action in KEYS:
		_ensure(action)
		for k in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	for action in MOUSE:
		_ensure(action)
		for b in MOUSE[action]:
			var ev := InputEventMouseButton.new()
			ev.button_index = b
			InputMap.action_add_event(action, ev)
	for i in 8:
		var action := "hotbar_%d" % (i + 1)
		_ensure(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_1 + i
		InputMap.action_add_event(action, ev)


static func _ensure(action: String) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
