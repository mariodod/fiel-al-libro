extends Control
## The Examine panel: what a character makes of a thing.
##
## The second playtest said the panel "gives away all the information".
## It used to print three lines:
##
##     La roca
##     Realidad: roca · Libro: libro
##     Don Quijote: libro · Sancho: roca
##
## The second line is the truth table and the third is the other
## character's reading. Together they are the whole mechanic, handed over
## before the player had touched anything. Both are gone.
##
## What is left is **one character's perception**: what the thing is
## called, how it looks, what is written on it, and the one detail that
## does not add up. The owner asked for exactly this: *"Examining
## shouldn't give away all the information. It should give the information
## the character sees. If it's a rock a rock, it can describe how it
## looks. If it's a book, a book, with its title maybe some text and a
## mention that it is heavier than it should."*
##
## That last detail is the seam, and the seam is the seed of the Lectura
## system (GDD.md §6): the one thing a character cannot explain, and the
## thing the player is meant to notice without a marker.
##
## The panel is LIVE while it is up. The description is recomputed from
## the reading rule every frame, so flipping the world's truth with `T` —
## or swapping characters with `TAB` — changes what is written under
## your eyes. That is the mechanic in one sentence, and it costs nothing
## to show it.
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
@export var hold_seconds: float = 6.0
## How wide the wrapped lines are allowed to get.
@export var text_width: float = 640.0

var _object: TruthObject = null
var _reader_id: StringName = &""
var _hold: float = 0.0

var _panel: PanelContainer = null
var _name: Label = null
var _description: Label = null
var _title: Label = null
var _text: Label = null
var _tell: Label = null
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
	# The panel follows the character you are driving. Swap, and the same
	# object is described in the other reading.
	EventBus.character_switched.connect(_on_character_switched)


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
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)

	# What the character calls the thing. This is the line that moves:
	# "rock" for Sancho, "book" for Quixote.
	_name = _make_label("Name", 22, Color(0.97, 0.93, 0.83, 1.0))
	box.add_child(_name)

	# How it looks, in this truth.
	_description = _make_label("Description", 17, Color(0.90, 0.86, 0.75, 1.0))
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size = Vector2(text_width, 0.0)
	box.add_child(_description)

	# The title, for the things that have one.
	_title = _make_label("Title", 17, Color(0.85, 0.78, 0.60, 1.0))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(text_width, 0.0)
	box.add_child(_title)

	# The text on the page, if there is a page.
	_text = _make_label("Text", 16, Color(0.82, 0.80, 0.72, 1.0))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(text_width, 0.0)
	box.add_child(_text)

	# The one detail that does not add up.
	_tell = _make_label("Tell", 17, Color(0.93, 0.83, 0.62, 1.0))
	_tell.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tell.custom_minimum_size = Vector2(text_width, 0.0)
	box.add_child(_tell)

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
	# Live: the description follows the reading while the panel is up.
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
	_hold = hold_seconds if hold_seconds > 0.0 else 6.0
	_refresh_text()


## The player swapped characters. The panel now describes the thing the
## way the character you are DRIVING sees it.
func _on_character_switched(_from_id: StringName, to_id: StringName) -> void:
	_reader_id = to_id
	_refresh_text()


# ── The text ───────────────────────────────────────────────────────────

## What the panel says.
##
## The lines of one character's perception, in order: what it is called,
## how it looks, its title, the text on it, and the detail that does not
## add up.
func examination_text() -> String:
	return "\n".join(_parts())


## The lines, in order.
func _parts() -> Array[String]:
	var lines := _lines()
	var out: Array[String] = []
	for key: String in ["name", "description", "title", "text", "tell"]:
		var line: String = str(lines.get(key, ""))
		if not line.is_empty():
			out.append(line)
	return out


## The five lines, by name. Empty means "this thing has none of that".
func _lines() -> Dictionary:
	var empty := {
		"name": "", "description": "", "title": "", "text": "", "tell": "",
	}
	if _object == null or _object.data == null:
		return empty
	var face := Examine.perception_for(_object, _reader())
	if face == null:
		return empty

	var lines := empty.duplicate()
	if not face.name_key.is_empty():
		lines["name"] = Loc.t(face.name_key)
	if not face.description_key.is_empty():
		lines["description"] = Loc.t(face.description_key)
	if not face.title_key.is_empty():
		lines["title"] = Loc.t(face.title_key)
	if face.has_fragment():
		var quoted := ManifiestoFragment.text_for(face.fragment_id)
		if not quoted.is_empty():
			lines["text"] = Loc.tf(&"ui.examine.quote", [quoted])
	if not face.tell_key.is_empty():
		lines["tell"] = Loc.t(face.tell_key)
	return lines


## Put the current text on the panel.
func _refresh_text() -> void:
	var lines := _lines()
	if lines.is_empty() or str(lines.get("name", "")).is_empty():
		_panel.visible = false
		return
	_name.text = str(lines.get("name", ""))
	_description.text = str(lines.get("description", ""))
	_title.text = str(lines.get("title", ""))
	_text.text = str(lines.get("text", ""))
	_tell.text = str(lines.get("tell", ""))
	# A line that is not there must not leave a gap.
	_description.visible = not _description.text.is_empty()
	_title.visible = not _title.text.is_empty()
	_text.visible = not _text.text.is_empty()
	_tell.visible = not _tell.text.is_empty()
	_panel.visible = true
	_layout()


## The character the player is driving.
func _reader() -> CharacterPawn:
	for pawn in _pawns():
		if pawn.character_id == _reader_id:
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
