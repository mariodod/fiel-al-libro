class_name TruthObject
extends Node3D
## One object in the world, with two faces.
##
## The scene shows the form of whichever truth the READER perceives, so the
## object changes when you change characters: swap to Sancho and the giant
## is a windmill again. That is the mechanic, made visible.
##
## The change is a cross-fade rather than a pop — the old form shrinks away
## while the new one grows in — so it can ride on top of the truth layer's
## own cross-fade instead of fighting it.
##
## The tag above the object says what the OTHER character is looking at.
## In a real build the companion barks it at you; in the slice it is
## written down, so the disagreement is legible in a screenshot.

@export var data: TruthObjectData
## Seconds for one form to become the other, when the object animates itself.
@export var transition_seconds: float = 0.55
## Show the floating tag with the companion's reading.
@export var show_tag: bool = true

var _reality_form: Node3D = null
var _book_form: Node3D = null
var _tag: Label3D = null

## 0 = Reality form, 1 = Book form. Continuous, so the two forms overlap
## in the middle of the change.
var _blend: float = 0.0
var _target_blend: float = 0.0
## True when the scene drives the blend itself (it drives the shader, so the
## object and the screen change in lockstep).
var _driven_externally: bool = false
var _hover_time: float = 0.0
## How long the Book skin is off this object. GDD.md §5.2: Desvelar
## strips it for eight seconds.
var _reveal_time: float = 0.0


func _ready() -> void:
	_setup_tag()
	# Anything with two faces can be examined. The Examine verb finds the
	# candidates through this group.
	add_to_group(Examine.GROUP)
	if _reality_form == null and _book_form == null:
		setup(data)
	else:
		_refresh()


func _process(delta: float) -> void:
	_hover_time += delta
	if _reveal_time > 0.0:
		_reveal_time = maxf(0.0, _reveal_time - delta)
	if _driven_externally:
		_refresh()
		return
	var speed := transition_seconds if transition_seconds > 0.0 else 0.5
	_blend = move_toward(_blend, _target_blend, delta / speed)
	_refresh()


## Build the two forms from the data.
func setup(object_data: TruthObjectData) -> void:
	data = object_data
	_clear_forms()
	if data == null:
		return
	if data.reality_form != null:
		_reality_form = data.reality_form.instantiate()
		add_child(_reality_form)
	if data.book_form != null:
		_book_form = data.book_form.instantiate()
		add_child(_book_form)
	_refresh()


## Show a truth. The default animates; `instant` snaps.
func set_layer(layer: int, instant: bool = false) -> void:
	_target_blend = 1.0 if layer == 1 else 0.0
	if instant:
		_blend = _target_blend
		_refresh()


## Drive the blend from outside. The slice does this with the truth layer's
## own view blend, so the object and the screen grade change together.
func apply_blend(blend: float) -> void:
	_driven_externally = true
	_blend = clampf(blend, 0.0, 1.0)
	_target_blend = _blend
	_refresh()


## The name this character would call the object in a truth layer.
##
## While the object is unveiled, everybody calls it by its Reality name:
## the Book skin is off, and both characters can see what is under it.
func name_key_for(layer: int) -> StringName:
	if data == null:
		return &""
	if is_revealed():
		return data.name_key_for(Perception.REALITY)
	return data.name_key_for(layer)


## The face of the object in a truth layer: what it is called, how it
## looks, and the one detail that does not add up.
##
## This is what a character *perceives*, and it is the only thing the
## Examine panel is allowed to say. The other truth is not printed
## anywhere: the player has to put the two together themselves.
func face_for(layer: int) -> TruthFace:
	if data == null:
		return null
	if is_revealed():
		return data.face_for(Perception.REALITY)
	return data.face_for(layer)


## Strip the Book skin off this object for a while.
##
## GDD.md §5.2: *"Desvelar — a cone/line that strips the 'Book skin' off
## an enemy for eight seconds, exposing its true form."* The object shows
## its Reality form, and **both** characters see it: a book in a rock
## becomes a stone for as long as the skin is off.
func reveal(duration: float) -> void:
	_reveal_time = maxf(_reveal_time, duration)


## Is the Book skin off this object?
func is_revealed() -> bool:
	return _reveal_time > 0.0


## The truth layer this object is currently showing, at full strength.
func current_layer() -> int:
	return 1 if _blend >= 0.5 else 0


## The text of the floating tag.
func tag_text() -> String:
	if _tag == null:
		return ""
	return _tag.text


## Set the floating tag — "Sancho: Molino".
func set_tag_text(text: String) -> void:
	if _tag == null:
		return
	_tag.text = text
	_tag.visible = show_tag and not text.is_empty()


## The node holding the form for a layer, for tests and for anything that
## needs to reach into the geometry.
func form_for(layer: int) -> Node3D:
	return _book_form if layer == 1 else _reality_form


# ── Internals ───────────────────────────────────────────────────────────

func _clear_forms() -> void:
	if _reality_form != null:
		_reality_form.queue_free()
		_reality_form = null
	if _book_form != null:
		_book_form.queue_free()
		_book_form = null


func _setup_tag() -> void:
	if _tag != null:
		return
	_tag = Label3D.new()
	_tag.name = "PerceptionTag"
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.no_depth_test = true
	_tag.double_sided = true
	_tag.font_size = 64
	_tag.pixel_size = 0.012
	# No outline of its own: the truth-layer shader already draws a
	# pen-and-ink contour over everything, and two outlines make the text
	# an unreadable blob.
	_tag.outline_size = 0
	_tag.modulate = Color(0.99, 0.95, 0.84)
	_tag.text = ""
	_tag.visible = false
	add_child(_tag)


func _refresh() -> void:
	# While the Book skin is off, the Reality form is what there is.
	var t := 0.0 if is_revealed() else clampf(_blend, 0.0, 1.0)
	# Smoothstep, so the two forms overlap in the middle of the change
	# instead of the object vanishing for a frame.
	var smooth := t * t * (3.0 - 2.0 * t)
	var reality_scale := 1.0 - smooth
	var book_scale := smooth

	if _reality_form != null:
		_reality_form.scale = Vector3.ONE * reality_scale
		_reality_form.visible = reality_scale > 0.01
	if _book_form != null:
		_book_form.scale = Vector3.ONE * book_scale
		_book_form.visible = book_scale > 0.01
		# The Book form hovers: it is the Book's idea of the object, and it
		# does not quite touch the ground.
		if data != null and data.book_form_hovers:
			_book_form.position.y = sin(_hover_time * 1.1) * 0.12

	if _tag != null:
		var height := 3.0
		if data != null:
			height = data.tag_height
		_tag.position.y = height
