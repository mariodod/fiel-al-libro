extends Control
## The Examine panel: what a thing is, in each truth, and what each of you
## calls it.
##
## This is the answer to the playtest. Two people who had never spoken to
## each other reached for the object that surprised them — *"seeing the
## rock I wanted to interact with it, even more the book I expected to be
## able to interact with it and read it"* — and there was nothing to press.
##
## The panel is LIVE while it is up. Flip the world's truth and the line
## about the two of you changes under your eyes, because the readings are
## recomputed from the reading rule every frame. That is the whole
## mechanic in one sentence, and it costs nothing to show it.
##
## It is not the Lectura system (GDD.md §6). That is weeks 5–7. This is
## the verb, not the mode.
##
## ── Layout gotcha ─────────────────────────────────────────────────────
## A Control under a CanvasLayer has no Control parent, so it gets no
## size from its anchors and it is not told when the window is resized.
## The size is driven from the viewport here, exactly as in
## `src/ui/post_process.gd`. See HANDOVER.md §7.7.

## How long the examination stays up after the press.
@export var hold_seconds: float = 4.0

var _object: TruthObject = null
var _reader_id: StringName = &""
var _hold: float = 0.0

var _panel: PanelContainer = null
var _title: Label = null
var _faces: Label = null
var _readings: Label = null
var _prompt: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	_fit_to_viewport()

	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_to_viewport):
		viewport.size_changed.connect(_fit_to_viewport)

	_build_ui()

	EventBus.examine_target_changed.connect(_on_target_changed)
	EventBus.object_examined.connect(_on_object_examined)


## Cover the whole visible area.
func _fit_to_viewport() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	size = viewport.get_visible_rect().size
	_layout()


func _build_ui() -> void:
	# The examination itself: a snug panel at the bottom, hugging its
	# text, so it does not become a letterbox bar across the screen.
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(_panel)

	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 2)
	_panel.add_child(box)

	_title = _make_label("Title", 20, Color(0.97, 0.93, 0.83, 1.0))
	_faces = _make_label("Faces", 17, Color(0.90, 0.86, 0.75, 1.0))
	_readings = _make_label("Readings", 17, Color(0.90, 0.86, 0.75, 1.0))
	box.add_child(_title)
	box.add_child(_faces)
	box.add_child(_readings)

	# The prompt. Smaller, and it sits under the examination.
	_prompt = Label.new()
	_prompt.name = "Prompt"
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_left = 0.0
	_prompt.offset_right = 0.0
	_prompt.offset_top = -60.0
	_prompt.offset_bottom = -28.0
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 16)
	_prompt.add_theme_color_override("font_color", Color(0.90, 0.85, 0.72, 1.0))
	_prompt.add_theme_color_override("font_outline_color", Color(0.09, 0.07, 0.05, 0.9))
	_prompt.add_theme_constant_override("outline_size", 5)
	_prompt.visible = false
	add_child(_prompt)


func _make_label(label_name: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## A quiet dark panel, so the text does not fight with the world.
func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.07, 0.55)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


## Put the panel at the bottom centre, hugging its text.
func _layout() -> void:
	if _panel == null:
		return
	var content := _panel.get_combined_minimum_size()
	_panel.size = content
	_panel.position = Vector2(
		roundf((size.x - content.x) * 0.5),
		roundf(size.y - content.y - 78.0))


func _process(delta: float) -> void:
	if _hold <= 0.0:
		return
	_hold -= delta
	if _hold <= 0.0:
		_object = null
		_panel.visible = false
		return
	# Live: the readings follow the world while the panel is up.
	_refresh_text()


# ── Signals ────────────────────────────────────────────────────────────

## Something is in front of the player, or nothing is.
func _on_target_changed(object_id: StringName) -> void:
	var has_target := not object_id.is_empty()
	_prompt.visible = has_target
	if has_target:
		_prompt.text = Loc.t(&"ui.examine.prompt")


## The player examined a thing.
func _on_object_examined(object_id: StringName, reader_id: StringName) -> void:
	_object = Examine.find_by_id(object_id)
	_reader_id = reader_id
	# The floor, in case the exported default ever fails to apply.
	_hold = hold_seconds if hold_seconds > 0.0 else 4.0
	_refresh_text()


# ── The text ───────────────────────────────────────────────────────────

## What the panel says.
##
## Three lines: what the thing is, what each truth calls it, and what
## each of the two of you calls it right now. The last line is the one
## that moves.
func examination_text() -> String:
	return "\n".join(_parts())


## The three lines, in order.
func _parts() -> Array[String]:
	if _object == null or _object.data == null:
		return []
	var faces := Examine.face_keys(_object)
	if faces.size() < 2:
		return []

	var parts: Array[String] = []
	parts.append(Loc.t(_object.data.title_key()))
	parts.append(Loc.tf(&"ui.examine.faces", [
		Loc.t(&"ui.layer.reality"), Loc.t(faces[0]),
		Loc.t(&"ui.layer.book"), Loc.t(faces[1]),
	]))

	var reader := _reader()
	var other := _other(reader)
	if reader != null and other != null:
		parts.append(Loc.tf(&"ui.examine.readings", [
			reader.display_name(), Loc.t(Examine.reading_key(_object, reader)),
			other.display_name(), Loc.t(Examine.reading_key(_object, other)),
		]))

	return parts


## Put the current text on the panel.
func _refresh_text() -> void:
	var parts := _parts()
	if parts.is_empty():
		_panel.visible = false
		return
	_title.text = parts[0]
	_faces.text = parts[1]
	_readings.text = parts[2] if parts.size() > 2 else ""
	_panel.visible = true
	_layout()


## The character the player is driving.
func _reader() -> CharacterPawn:
	for pawn in _pawns():
		if pawn.character_id == _reader_id:
			return pawn
	return null


## The other one.
func _other(reader: CharacterPawn) -> CharacterPawn:
	for pawn in _pawns():
		if pawn != reader:
			return pawn
	return null


## Every character in the world. There are two.
func _pawns() -> Array[CharacterPawn]:
	var out: Array[CharacterPawn] = []
	var tree := get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group(&"pawns"):
		var pawn := node as CharacterPawn
		if pawn != null:
			out.append(pawn)
	return out
