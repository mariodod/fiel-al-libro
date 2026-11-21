extends Control
## The "Codes" page — the in-game translation importer.
##
## Players can read the game in any shipped language, or import a community
## .po file. Imported translations are parsed at runtime by PoParser, installed
## into TranslationServer by TranslationManager, and survive a restart.

signal back_pressed

const TEXT_COLOR := Color(0.97, 0.93, 0.83, 1.0)
const GOLD_COLOR := Color(0.75, 0.54, 0.24, 1.0)
const HINT_COLOR := Color(0.65, 0.60, 0.52, 1.0)

var _language_list: VBoxContainer = null
var _back: Button = null
var _status: Label = null
var _import_button: Button = null
var _file_dialog: FileDialog = null
var _localized_labels: Array = []
var _error_keys: Dictionary = {
	"no_translations": &"ui.codes.error.no_translations",
	"no_locale": &"ui.codes.error.no_locale",
	"file_not_found": &"ui.codes.error.no_file",
	"cannot_read": &"ui.codes.error.no_file",
	"no_import": &"ui.codes.error.no_file",
}


func _ready() -> void:
	_build_ui()
	_refresh()
	if not EventBus.settings_changed.is_connected(_refresh):
		EventBus.settings_changed.connect(_refresh)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.name = "CodesMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "CodesScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var box := VBoxContainer.new()
	box.name = "CodesBox"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)

	box.add_child(_make_label(&"ui.codes.title", 30, GOLD_COLOR))
	box.add_child(_make_label(&"ui.codes.hint", 15, HINT_COLOR))
	box.add_child(_make_label(&"ui.codes.language", 21, GOLD_COLOR))

	_language_list = VBoxContainer.new()
	_language_list.name = "LanguageList"
	_language_list.add_theme_constant_override("separation", 4)
	box.add_child(_language_list)

	_import_button = Button.new()
	_import_button.name = "ImportButton"
	_import_button.custom_minimum_size = Vector2(260, 40)
	_import_button.pressed.connect(_on_import_pressed)
	box.add_child(_import_button)

	_status = Label.new()
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(400, 0)
	_status.add_theme_font_size_override("font_size", 14)
	_status.add_theme_color_override("font_color", HINT_COLOR)
	box.add_child(_status)

	var back := Button.new()
	back.name = "CodesBack"
	back.custom_minimum_size = Vector2(160, 40)
	back.pressed.connect(func(): back_pressed.emit())
	box.add_child(back)
	_back = back

	# A control-based FileDialog is testable headlessly and matches the way the
	# rest of the UI is built. The native dialog is used when available.
	_file_dialog = FileDialog.new()
	_file_dialog.name = "PoFileDialog"
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.use_native_dialog = true
	_file_dialog.filters = PackedStringArray(["*.po,*.pot;PO files;text/x-po", "*.po;PO files"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


## Called by the file dialog, and directly by tests with a user:// path.
func import_file(path: String) -> void:
	var result: Dictionary = TranslationManager.import_from_path(path)
	if bool(result.get("ok", false)):
		var args := {"count": int(result.get("count", 0))}
		_status.text = Loc.t(&"ui.codes.status.ok").format(args)
		TranslationManager.use_locale(str(result.get("locale", "")))
	else:
		var err := str(result.get("error", "no_file"))
		var key: StringName = _error_keys.get(err, &"ui.codes.error.no_file")
		_status.text = Loc.t(key).format({"error": err})
	_refresh()


func _on_file_selected(path: String) -> void:
	import_file(path)


func _on_import_pressed() -> void:
	_file_dialog.popup_centered_clamped(Vector2(720, 480))


func _make_label(key: StringName, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	_localized_labels.append([label, key])
	return label


func _refresh() -> void:
	for entry in _localized_labels:
		(entry[0] as Label).text = Loc.t(entry[1] as StringName)
	_import_button.text = Loc.t(&"ui.codes.import")
	if _back != null:
		_back.text = Loc.t(&"ui.settings.back")

	for child in _language_list.get_children():
		child.queue_free()
	for locale in TranslationManager.available_locales:
		var row := HBoxContainer.new()
		var button := Button.new()
		button.name = "Locale_%s" % locale
		button.text = TranslationManager.locale_display_name(locale)
		if locale == Loc.current_locale():
			button.text += "  ●"
		if TranslationManager.is_imported(locale):
			button.text += "  [%s]" % Loc.t(&"ui.codes.imported")
		button.pressed.connect(_on_locale_pressed.bind(locale))
		row.add_child(button)
		if TranslationManager.is_imported(locale):
			var forget := Button.new()
			forget.text = Loc.t(&"ui.codes.forget")
			forget.pressed.connect(_on_forget_pressed.bind(locale))
			row.add_child(forget)
		_language_list.add_child(row)

	var args := {"locale": Loc.current_locale()}
	_status.text = Loc.t(&"ui.codes.status.current").format(args)


func _on_locale_pressed(locale: String) -> void:
	TranslationManager.use_locale(locale)
	_status.text = Loc.t(&"ui.codes.status.current").format({"locale": Loc.current_locale()})
	_refresh()


func _on_forget_pressed(locale: String) -> void:
	TranslationManager.forget(locale)
	_refresh()
