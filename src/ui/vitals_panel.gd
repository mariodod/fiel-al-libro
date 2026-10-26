class_name VitalsPanel
extends Control
## The two characters' health and stamina, in the corner, for everybody.
##
## The playtest: *"there is no feedback to how much hp the enemies have
## left, nor the main characters other than the debug numbers."* The
## debug numbers are the developer's readout, and they are hidden with
## `H` — so a stranger was playing with no idea how close either of
## them was to the ground. This is that, and it is always on.
##
## The bar for the character you are driving is ochre; the companion's
## is olive. The palette is the game's, and there is no text in it
## except the two names.

## How wide a bar is, in pixels.
@export var bar_width: float = 190.0
## How tall a bar is.
@export var bar_height: float = 11.0

var _rows: Array[Dictionary] = []
## The two characters the rows are about: the one you drive, and the
## one behind you.
var _pawns: Array[CharacterPawn] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Bottom right: the bark line speaks along the bottom left, and the
	# debug readout runs down the top left.
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_right = -18.0
	offset_bottom = -18.0
	offset_top = -120.0
	offset_left = -380.0
	_build()


## Two rows: the character you drive, and the one behind you.
## Each row has a name, a health bar, and a stamina bar.
func _build() -> void:
	var box := VBoxContainer.new()
	box.name = "Rows"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	for row in 2:
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 8)
		box.add_child(line)

		var name_label := Label.new()
		name_label.name = "Name"
		name_label.custom_minimum_size = Vector2(96.0, 0.0)
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1.0))
		line.add_child(name_label)

		var h_ground := ColorRect.new()
		h_ground.name = "HealthGround"
		h_ground.custom_minimum_size = Vector2(bar_width, bar_height)
		h_ground.color = Color(0.12, 0.11, 0.1, 0.85)
		line.add_child(h_ground)

		var h_fill := ColorRect.new()
		h_fill.name = "HealthFill"
		h_fill.color = Color(0.75, 0.54, 0.24, 1.0)
		h_ground.add_child(h_fill)

		var s_ground := ColorRect.new()
		s_ground.name = "StaminaGround"
		s_ground.custom_minimum_size = Vector2(bar_width, bar_height)
		s_ground.color = Color(0.12, 0.11, 0.1, 0.85)
		line.add_child(s_ground)

		var s_fill := ColorRect.new()
		s_fill.name = "StaminaFill"
		s_fill.color = Color(0.54, 0.549, 0.565, 1.0)
		s_ground.add_child(s_fill)

		_rows.append({"label": name_label, "health": h_fill, "stamina": s_fill})


## Point the panel at the two characters.
##
## The first row is the one you are driving and the second is the one
## behind you, and the panel follows the swap.
func set_characters(driven: CharacterPawn, companion: CharacterPawn) -> void:
	if _rows.size() < 2:
		return
	_pawns = [driven, companion]
	_set_row(0, driven, Color(0.75, 0.54, 0.24, 1.0))
	_set_row(1, companion, Color(0.43, 0.45, 0.27, 1.0))


func _set_row(index: int, pawn: CharacterPawn, color: Color) -> void:
	if index >= _rows.size():
		return
	var row: Dictionary = _rows[index]
	var label: Label = row["label"]
	var h_fill: ColorRect = row["health"]
	var s_fill: ColorRect = row["stamina"]
	if pawn == null:
		label.text = ""
		h_fill.size = Vector2.ZERO
		s_fill.size = Vector2.ZERO
		return
	label.text = pawn.display_name()
	h_fill.color = color
	s_fill.color = color


func _process(_delta: float) -> void:
	# The bars are the readout, so they are read every frame.
	for index in range(_rows.size()):
		var pawn: CharacterPawn = _pawns[index] if index < _pawns.size() else null
		if pawn == null:
			continue
		var row: Dictionary = _rows[index]
		var h_fill: ColorRect = row["health"]
		var s_fill: ColorRect = row["stamina"]
		var h_ratio := 0.0
		if pawn.max_health > 0.0:
			h_ratio = clampf(pawn.health / pawn.max_health, 0.0, 1.0)
		h_fill.size = Vector2(bar_width * h_ratio, bar_height)
		var s_ratio := 0.0
		if pawn.max_stamina > 0.0:
			s_ratio = clampf(pawn.stamina / pawn.max_stamina, 0.0, 1.0)
		s_fill.size = Vector2(bar_width * s_ratio, bar_height)
