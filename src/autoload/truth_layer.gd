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
##
## GDD.md §4.3 says 0.6-1.2s. Two people have now said the same thing
## about it: "change of view should be fater when pressing T, it takes too
## much time", and — from somebody who had never seen the game — "expected
## change to be immediate with T". A world turning over should read as a
## blink, not a dissolve. This is 0.3s, which is well below the GDD's
## range: the GDD is the design, the playtest is the data, and the data
## says the GDD is wrong here.
##
## The authored, story-beat version of this — a Verdict — can still take
## its time. That is a different moment and it gets its own transition.
@export var blend_seconds: float = 0.3

var _layer: int = Layer.REALITY
var _target: int = Layer.REALITY
var _blend: float = 0.0
var _ink: float = 0.0
var _blending: bool = false

## What the READER sees, or -1 to follow the world.
##
## This does NOT change the world's truth and does not change the world's
## look. It is the truth the character you are driving is *reading*, and it
## decides which form the objects take: the windmill is a mill or a giant
## depending on who is looking at it.
##
## The camera is a person's eyes, but the world is still the world: one
## world, one save field, one truth — and two people making two things of
## it.
var view_layer: int = -1
var _view_blend: float = 0.0


func _ready() -> void:
	# Make sure the global shader parameters exist even if project.godot was
	# edited by hand and someone removed them.
	_ensure_global(GLOBAL_TRUTH, 0.0)
	_ensure_global(GLOBAL_INK, 0.0)
	_ensure_global(GLOBAL_SPEED, 1.0)
	RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, 0.0)
	RenderingServer.global_shader_parameter_set(GLOBAL_INK, 0.0)


func _ensure_global(name: StringName, value: float) -> void:
	# The globals are declared in project.godot, so this is only a safety
	# net for an editor session.
	#
	# It MUST be skipped in a game run: RenderingServer
	# .global_shader_parameter_get_list() is an editor-only call. In a game
	# it returns nothing useful AND logs an error for every call, and the
	# add() that follows then fails because the parameter already exists.
	if not Engine.is_editor_hint():
		return
	if not RenderingServer.global_shader_parameter_get_list().has(name):
		RenderingServer.global_shader_parameter_add(
			name,
			RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
			value
		)


func _process(delta: float) -> void:
	advance_blend(delta)


## The blending, split out of _process so the tests can drive it directly.
func advance_blend(delta: float) -> void:
	if _blending:
		var speed := blend_seconds if blend_seconds > 0.0 else 1.0
		_blend = move_toward(_blend, 1.0 if _target == Layer.BOOK else 0.0, delta / speed)
		if is_equal_approx(_blend, 1.0 if _target == Layer.BOOK else 0.0):
			_blending = false
			_layer = _target
			EventBus.truth_blend_finished.emit(_layer)

	# THE PICTURE FOLLOWS THE READER. The grade and the geometry together.
	#
	# One world, two readings (GDD.md §4.1): "the disagreement IS the
	# content". The player has to be able to SEE the reading they are
	# driving — the playtest was blunt about it: *"after pressing T with
	# quijote and switching to sancho you still see the book world"*.
	# A half-and-half picture, a Book-graded world with Reality objects,
	# is not a reading. It is a mistake.
	#
	# What stays global is the STATE: the world's truth is one truth, one
	# save field, one world (D2). It is what the Venture wears, what the
	# HUD says, and what the Desvelar fights against.
	var speed := blend_seconds if blend_seconds > 0.0 else 1.0
	if view_layer >= 0:
		var view_target := 1.0 if view_layer == Layer.BOOK else 0.0
		_view_blend = move_toward(_view_blend, view_target, delta / speed)
	else:
		_view_blend = _blend

	RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, _view_blend)


## Set what the reader sees. -1 follows the world again.
func set_view_layer(layer: int) -> void:
	view_layer = layer


## The value the shader is showing right now: 0 = Reality, 1 = Book.
func view_blend() -> float:
	return _view_blend


## The world's own truth, 0 = Reality, 1 = Book. This is what the shader
## shows and what the save file stores. The reader's view_blend() is a
## different thing: it is what one pair of eyes makes of it.
func world_blend() -> float:
	return _blend


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
	# Both paths announce the change. An instant change has no blend to
	# speak of, but anything listening for "the world is turning" — the
	# page turn, the VFX — must hear it either way, or the same change
	# behaves differently depending on how it was made.
	EventBus.truth_blend_started.emit(new_layer)
	if instant:
		_blend = 1.0 if new_layer == Layer.BOOK else 0.0
		_layer = new_layer
		_blending = false
		# The picture is the READER's, so the instant path snaps the
		# reader's view and not the world's.
		if view_layer >= 0:
			_view_blend = 1.0 if view_layer == Layer.BOOK else 0.0
		else:
			_view_blend = _blend
		RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, _view_blend)
		EventBus.truth_blend_finished.emit(_layer)
	else:
		_blending = true
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
	# A loaded world speaks for itself: the camera stops filtering it until
	# whatever is driving the camera says otherwise.
	view_layer = -1
	_view_blend = _blend
	RenderingServer.global_shader_parameter_set(GLOBAL_TRUTH, _blend)
	RenderingServer.global_shader_parameter_set(GLOBAL_INK, _ink)
	EventBus.truth_layer_changed.emit(_layer, _layer)
