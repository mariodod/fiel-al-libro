extends SceneTree
## Writes the input map into project.godot.
##
## Run from the project root:
##   godot --headless --script res://src/tools/setup_input_map.gd
##
## The input map lives in project.godot (not in code) so that it is visible
## and editable in the editor, and so that a fresh clone behaves identically.
## This script is the source of truth for that map: change it here, run it,
## commit the result.
##
## Keys are bound by PHYSICAL keycode so that WASD works on AZERTY and
## QWERTZ layouts without a remap.

const KEY_BINDINGS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT],
	"dodge": [KEY_SPACE],
	"block": [KEY_F],
	"interact": [KEY_E],
	"lectura": [KEY_Q],
	"switch_character": [KEY_TAB],
	"toggle_truth": [KEY_T],
	"toggle_second_sight": [KEY_B],
	"toggle_madness": [KEY_L],
	"toggle_verdict": [KEY_V],
	"toggle_help": [KEY_F1],
	"toggle_tags": [KEY_F2],
	"toggle_hud": [KEY_H],
	"shelf": [KEY_I],
	"codex": [KEY_C],
	"rest": [KEY_R],
	"lock_on": [KEY_M],
}

const MOUSE_BINDINGS := {
	"attack_light": MOUSE_BUTTON_LEFT,
	"attack_heavy": MOUSE_BUTTON_RIGHT,
}


func _init() -> void:
	var count := 0

	for action_name: String in KEY_BINDINGS:
		var events: Array = []
		for keycode: int in KEY_BINDINGS[action_name]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			events.append(ev)
		ProjectSettings.set_setting("input/" + action_name, {
			"deadzone": 0.2,
			"events": events,
		})
		count += 1

	for action_name: String in MOUSE_BINDINGS:
		var ev := InputEventMouseButton.new()
		ev.button_index = int(MOUSE_BINDINGS[action_name])
		ProjectSettings.set_setting("input/" + action_name, {
			"deadzone": 0.2,
			"events": [ev],
		})
		count += 1

	var err := ProjectSettings.save()
	if err != OK:
		printerr("[setup_input_map] ProjectSettings.save() failed with error %d" % err)
		quit(1)
		return

	print("[setup_input_map] Wrote %d actions to project.godot" % count)
	quit(0)
