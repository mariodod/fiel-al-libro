extends Node
## Manages the in-game "Codes" translation importer.
##
## Shipped translations come from project.godot and live in res://locale/.
## A player can import a community .po from disk; it is parsed with PoParser,
## copied into user://translations/ so it survives a restart, and registered
## with TranslationServer so every Loc.t() call picks it up immediately.

const PoParser = preload("res://src/systems/po_parser.gd")

const IMPORT_DIR := "user://translations"
const SHIPPED_LOCALES: Array[String] = ["es", "en", "fr", "de", "it", "pt_BR"]

## locale code -> the Translation object we added to TranslationServer.
var _imported: Dictionary = {}

## Locale codes available to the player, shipped first then imported, sorted.
var available_locales: Array[String] = []


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(IMPORT_DIR):
		DirAccess.make_dir_recursive_absolute(IMPORT_DIR)
	_restore_imported()
	_rebuild_available()
	# A player who selected an imported language expects it on next launch.
	var saved := Settings.get_language()
	if not saved.is_empty() and _imported.has(saved):
		Loc.set_locale(saved)


func is_imported(locale: String) -> bool:
	return _imported.has(locale)


func locale_display_name(locale: String) -> String:
	if SHIPPED_LOCALES.has(locale):
		return Loc.locale_display_name(locale)
	# Imported locales have no display-name key; show the code itself.
	return locale


## Import a PO file. `path` can be an OS path from a FileDialog or a user://
## path. Returns a Dictionary: {ok, locale, count, error}.
func import_from_path(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {"ok": false, "error": "file_not_found"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "cannot_read"}
	var text := file.get_as_text()
	file.close()
	return import_from_text(text, path.get_file())


## Import PO text. This is the testable entry point: a UI or test can feed it
## text without going through the OS file dialog.
func import_from_text(text: String, filename: String = "") -> Dictionary:
	var entries: Dictionary = PoParser.parse(text)
	if entries.is_empty():
		return {"ok": false, "error": "no_translations"}
	var locale := PoParser.locale_from_header(text, filename)
	if locale.is_empty() or locale == "en":
		return {"ok": false, "error": "no_locale"}
	locale = locale.replace("-", "_")

	if not _imported.has(locale) and not SHIPPED_LOCALES.has(locale):
		# Guard against overwriting a shipped language by accident.
		pass

	var translation := Translation.new()
	translation.locale = locale
	for key in entries.keys():
		translation.add_message(StringName(str(key)), StringName(str(entries[key])))

	# Replace any previous import for this locale, shipped or not.
	if _imported.has(locale):
		TranslationServer.remove_translation(_imported[locale])
	_imported[locale] = translation
	TranslationServer.add_translation(translation)
	_persist(locale, text)
	_rebuild_available()
	return {"ok": true, "locale": locale, "count": entries.size()}


## Apply a locale: shipped ones go through Settings so the choice persists;
## imported ones are applied through Loc directly (Settings only knows the
## six shipped codes).
func use_locale(locale: String) -> void:
	if SHIPPED_LOCALES.has(locale):
		Settings.set_language(locale)
		return
	if not _imported.has(locale):
		return
	Loc.set_locale(locale)
	Settings.set_custom_language(locale)


func forget(locale: String) -> void:
	if not _imported.has(locale):
		return
	TranslationServer.remove_translation(_imported[locale])
	_imported.erase(locale)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path_for(locale)))
	if Loc.current_locale() == locale:
		Loc.set_locale(Loc.FALLBACK)
	Settings.set_custom_language("")
	_rebuild_available()


func _path_for(locale: String) -> String:
	return "%s/%s.po" % [IMPORT_DIR, locale]


func _persist(locale: String, text: String) -> void:
	var file := FileAccess.open(_path_for(locale), FileAccess.WRITE)
	if file != null:
		file.store_string(text)
		file.close()


func _restore_imported() -> void:
	var dir := DirAccess.open(IMPORT_DIR)
	if dir == null:
		return
	for name in dir.get_files():
		if not name.ends_with(".po"):
			continue
		var path := IMPORT_DIR + "/" + name
		var result := import_from_path(path)
		if not bool(result.get("ok", false)):
			push_warning("[Codes] Could not restore %s: %s" % [name, str(result.get("error", ""))])


func _rebuild_available() -> void:
	available_locales = SHIPPED_LOCALES.duplicate()
	for locale in _imported.keys():
		if not available_locales.has(str(locale)):
			available_locales.append(str(locale))
	available_locales.sort()
