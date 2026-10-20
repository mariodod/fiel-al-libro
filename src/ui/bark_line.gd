extends Control
## The line somebody just said.
##
## The first playtest, in one line: *"Text showing what the other sees
## feels like too handholding, the layer should change characters to see
## the whole world."* The tag was the wrong answer, and the fix was not a
## smaller label — it was a character. The disagreement has to be **told**,
## not read.
##
## So the barks are spoken, in words, with the speaker's name on them. It
## is the cheapest thing in the build and it is the difference between a
## filter and a person.
##
## The bark used to be emitted into the void: `EventBus.toast` had no
## listener at all. That is why the playtest said the companion was
## "a label" and not a character.

## How long a line stays on the screen.
@export var hold_seconds: float = 4.5
## How long it takes to fade out.
@export var fade_seconds: float = 0.6

var _line: Label = null
var _hold: float = 0.0
var _fade: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	_fit_to_viewport()

	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_to_viewport):
		viewport.size_changed.connect(_fit_to_viewport)

	_build_ui()

	EventBus.character_spoke.connect(_on_character_spoke)
	EventBus.toast.connect(_on_toast)


## Cover the whole visible area.
func _fit_to_viewport() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	size = viewport.get_visible_rect().size


func _build_ui() -> void:
	# Bottom left: the HUD is at the top left, and the Examine panel sits
	# in the middle. A character speaks from beside you.
	_line = Label.new()
	_line.name = "Line"
	_line.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_line.offset_left = 24.0
	_line.offset_top = -132.0
	_line.offset_right = 700.0
	_line.offset_bottom = -76.0
	_line.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.add_theme_font_size_override("font_size", 19)
	_line.add_theme_color_override("font_color", Color(0.95, 0.91, 0.80, 1.0))
	_line.add_theme_color_override("font_outline_color", Color(0.09, 0.07, 0.05, 0.9))
	_line.add_theme_constant_override("outline_size", 6)
	_line.modulate.a = 0.0
	_line.visible = false
	add_child(_line)


func _process(delta: float) -> void:
	if _hold > 0.0:
		_hold -= delta
		if _hold <= 0.0:
			_fade = fade_seconds
		return
	if _fade > 0.0:
		_fade -= delta
		_line.modulate.a = clampf(_fade / maxf(fade_seconds, 0.05), 0.0, 1.0)
		if _fade <= 0.0:
			_line.visible = false


# ── Signals ────────────────────────────────────────────────────────────

## Somebody spoke. The speaker's name goes on the line.
func _on_character_spoke(character_id: StringName, text_key: StringName, args: Array) -> void:
	var who := _display_name(character_id)
	var what := Loc.tf(text_key, args)
	if not who.is_empty():
		what = "%s: %s" % [who, what]
	_show(what)


## A tip, a notice: no speaker.
func _on_toast(text_key: StringName, args: Array) -> void:
	_show(Loc.tf(text_key, args))


func _show(text: String) -> void:
	if text.is_empty():
		return
	_line.text = text
	_line.visible = true
	_line.modulate.a = 1.0
	_hold = hold_seconds
	_fade = 0.0


## The character's name, in the current language.
func _display_name(character_id: StringName) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return ""
	for node in tree.get_nodes_in_group(&"pawns"):
		var pawn := node as CharacterPawn
		if pawn != null and pawn.character_id == character_id:
			return pawn.display_name()
	return ""
