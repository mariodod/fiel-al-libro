extends Control
## Settings page inside the Manuscript shell: language, volume and a key sheet.
## The layout is built in code, like the shelf and the map — the scene only
## supplies the full-rect page and its parchment backdrop.

signal back_pressed

const TEXT_COLOR := Color(0.97, 0.93, 0.83, 1.0)
const GOLD_COLOR := Color(0.75, 0.54, 0.24, 1.0)
const HINT_COLOR := Color(0.65, 0.60, 0.52, 1.0)

const BUS_ROWS: Array = [
	[&"Master", &"ui.settings.audio.master"],
	[&"Music", &"ui.settings.audio.music"],
	[&"SFX", &"ui.settings.audio.sfx"],
	[&"Voice", &"ui.settings.audio.voice"],
	[&"UI", &"ui.settings.audio.ui"],
]

## A short reference sheet, not a rebind UI: the bindings are physical keys on
## purpose, so WASD works on AZERTY and QWERTZ without a remap screen.
const CONTROL_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right",
	&"interact", &"lectura", &"toggle_truth", &"switch_character",
	&"shelf", &"manifiesto", &"toggle_map", &"pause",
]

var _language: OptionButton = null
var _back: Button = null
var _sliders: Dictionary = {}
var _readouts: Dictionary = {}
var _localized_labels: Array = []
var _updating := false


func _ready() -> void:
	_build_ui()
	_refresh()
	if not EventBus.settings_changed.is_connected(_refresh):
		EventBus.settings_changed.connect(_refresh)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.name = "SettingsMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var box := VBoxContainer.new()
	box.name = "SettingsBox"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)

	box.add_child(_make_label(&"ui.settings.title", 32, GOLD_COLOR))

	box.add_child(_make_label(&"ui.settings.language", 22, GOLD_COLOR))
	box.add_child(_make_label(&"ui.settings.language.hint", 14, HINT_COLOR))
	_language = OptionButton.new()
	_language.name = "LanguageOption"
	_language.custom_minimum_size = Vector2(320, 0)
	_language.item_selected.connect(_on_language_selected)
	box.add_child(_language)

	box.add_child(_make_label(&"ui.settings.volume", 22, GOLD_COLOR))
	for row in BUS_ROWS:
		box.add_child(_make_volume_row(row[0], row[1]))

	box.add_child(_make_label(&"ui.settings.controls", 22, GOLD_COLOR))
	box.add_child(_make_label(&"ui.settings.controls.hint", 14, HINT_COLOR))
	box.add_child(_make_controls_sheet())

	_back = Button.new()
	_back.name = "SettingsBack"
	_back.custom_minimum_size = Vector2(160, 40)
	_back.pressed.connect(func(): back_pressed.emit())
	box.add_child(_back)


func _make_volume_row(bus: StringName, key: StringName) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var name_label := _make_label(key, 16, TEXT_COLOR)
	name_label.custom_minimum_size = Vector2(140, 0)
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.name = "Volume_%s" % bus
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.custom_minimum_size = Vector2(220, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	_sliders[bus] = slider
	row.add_child(slider)

	var readout := Label.new()
	readout.custom_minimum_size = Vector2(48, 0)
	readout.add_theme_font_size_override("font_size", 14)
	readout.add_theme_color_override("font_color", HINT_COLOR)
	_readouts[bus] = readout
	row.add_child(readout)
	return row


func _make_controls_sheet() -> Control:
	var grid := GridContainer.new()
	grid.name = "ControlsSheet"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 4)
	for action in CONTROL_ACTIONS:
		var label := Label.new()
		label.text = str(action).replace("_", " ").capitalize()
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", TEXT_COLOR)
		grid.add_child(label)

		var keys := PackedStringArray()
		for event in InputMap.action_get_events(action):
			keys.append(event.as_text())
		var key_label := Label.new()
		key_label.text = " / ".join(keys)
		key_label.add_theme_font_size_override("font_size", 15)
		key_label.add_theme_color_override("font_color", HINT_COLOR)
		grid.add_child(key_label)
	return grid


func _make_label(key: StringName, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_localized_labels.append([label, key])
	return label


func _refresh() -> void:
	_updating = true
	for bus in _sliders.keys():
		var value := Settings.get_volume(bus)
		(_sliders[bus] as HSlider).value = value
		(_readouts[bus] as Label).text = "%d%%" % roundi(value * 100.0)

	_language.clear()
	for loc in TranslationManager.available_locales:
		_language.add_item(TranslationManager.locale_display_name(loc))
	var current := TranslationManager.available_locales.find(Settings.get_language())
	if current >= 0:
		_language.selected = current

	for entry in _localized_labels:
		(entry[0] as Label).text = Loc.t(entry[1] as StringName)
	if _back != null:
		_back.text = Loc.t(&"ui.settings.back")
	_updating = false


func _on_language_selected(index: int) -> void:
	if _updating or index < 0 or index >= TranslationManager.available_locales.size():
		return
	TranslationManager.use_locale(TranslationManager.available_locales[index])


func _on_volume_changed(value: float, bus: StringName) -> void:
	if _updating:
		return
	Settings.set_volume(bus, value)
	# set_volume emits settings_changed, so _refresh() updates the readouts.
