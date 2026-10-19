extends Node
## D2 — the truth layer is GLOBAL.
##
## One value. One shader uniform. One save field. The two characters read
## the same world differently; they do not stand in different worlds.
##
## The visual truth lives in a single global shader parameter so that
## changing the world's reality is a float write, never an asset swap.
## That is the single biggest cost-saver in the whole project.
##
## See GDD.md §4.

enum Layer {
	REALITY = 0,
	BOOK = 1,
}

const GLOBAL_TRUTH := &"truth_layer"
const GLOBAL_INK := &"ink_amount"
const GLOBAL_SPEED := &"layer_blend_speed"

## Seconds for a full Reality <-> Book cross-fade.
@export var blend_seconds: float = 0.9

var _layer: int = Layer.REALITY
var _target: int = Layer.REALITY
var _blend: float = 0.0
var _ink: float = 0.0
var _blending: bool = false


func _ready() -> void:
	# Make sure the global shader parameters exist even if project.godot was
	# edited by hand and someone removed them.
	_ensure_global(GLOBAL_TRUTH, 0.0)
	_ensure_global(GLOBAL_INK, 0.0)
	_ensure_global(GLOBAL_SPEED, 1.0)
	RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, 0.0)
	RenderingServer.global_shader_parameter_set(GLOBAL_INK, 0.0)


func _ensure_global(name: StringName, value: float) -> void:
	if not RenderingServer.global_shader_parameter_get_list().has(name):
		RenderingServer.global_shader_parameter_add(
			name,
			RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
			value
		)


func _process(delta: float) -> void:
	if _blending:
		var speed := blend_seconds if blend_seconds > 0.0 else 1.0
		_blend = move_toward(_blend, 1.0 if _target == Layer.BOOK else 0.0, delta / speed)
		if is_equal_approx(_blend, 1.0 if _target == Layer.BOOK else 0.0):
			_blending = false
			_layer = _target
			EventBus.truth_blend_finished.emit(_layer)
	RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, _blend)


## The current truth of the world.
func layer() -> int:
	return _layer


## The truth the world is currently fading toward (== layer() when settled).
func target_layer() -> int:
	return _target


func is_book() -> bool:
	return _layer == Layer.BOOK


func is_reality() -> bool:
	return _layer == Layer.REALITY


## Shift the world to a truth. This is what a Verdict does.
func shift_to(new_layer: int, instant: bool = false) -> void:
	if new_layer == _target and not instant:
		return
	var old := _layer
	_target = new_layer
	if instant:
		_blend = 1.0 if new_layer == Layer.BOOK else 0.0
		_layer = new_layer
		_blending = false
		RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, _blend)
		EventBus.truth_blend_finished.emit(_layer)
	else:
		_blending = true
		EventBus.truth_blend_started.emit(new_layer)
	EventBus.truth_layer_changed.emit(old, new_layer)


## Flip to the other truth.
## NOTE: this reads the TARGET, not the visible layer. During a cross-fade
## the visible layer has not changed yet, so toggling off the visible value
## would send the blend back to where it came from and the two toggles would
## fight each other.
func toggle() -> void:
	shift_to(Layer.REALITY if _target == Layer.BOOK else Layer.BOOK)


## The Ink (GDD.md §4.3). Neither truth. Corruption. DLC 3's core visual.
func ink_amount() -> float:
	return _ink


func set_ink(amount: float) -> void:
	_ink = clampf(amount, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set(GLOBAL_INK, _ink)
	EventBus.ink_amount_changed.emit(_ink)


# ── Save / load ─────────────────────────────────────────────────────────

func save_state() -> Dictionary:
	return {
		"layer": _layer,
		"blend": _blend,
		"ink": _ink,
	}


func load_state(data: Dictionary) -> void:
	_layer = int(data.get("layer", Layer.REALITY))
	_target = _layer
	_blend = float(data.get("blend", 0.0))
	_ink = float(data.get("ink", 0.0))
	_blending = false
	RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, _blend)
	RenderingServer.global_shader_parameter_set(GLOBAL_INK, _ink)
	EventBus.truth_layer_changed.emit(_layer, _layer)
