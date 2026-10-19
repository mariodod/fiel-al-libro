extends SceneTree
## Registers the locale files with the engine.
##
## Run from the project root:
##   godot --headless --script res://src/tools/setup_translations.gd
##
## WHY THIS IS NEEDED: Godot's PO importer compiles locale/*.po into
## Translation resources, but the engine does not load them into
## TranslationServer unless they are listed in
##   Project Settings > Localization > Translations
## Without this list the .po files import fine, load fine, and are then
## silently ignored — and every `tr()` call returns the raw key.
##
## This tool discovers every locale/*.po and writes the list into
## project.godot. Run it after adding a new language.

const LOCALE_DIR := "res://locale/"
const SETTING := "internationalization/locale/translations"
const FALLBACK := "es"


func _init() -> void:
	var paths: Array[String] = []
	var dir := DirAccess.open(LOCALE_DIR)
	if dir == null:
		printerr("[setup_translations] No %s directory." % LOCALE_DIR)
		quit(1)
		return

	for file_name: String in dir.get_files():
		if file_name.ends_with(".po"):
			paths.append(LOCALE_DIR + file_name)
	paths.sort()

	if paths.is_empty():
		printerr("[setup_translations] No .po files found.")
		quit(1)
		return

	# The fallback must itself be one of the registered locales.
	if not paths.has(LOCALE_DIR + "%s.po" % FALLBACK):
		push_warning("[setup_translations] Fallback '%s.po' is not in the locale set." % FALLBACK)

	ProjectSettings.set_setting(SETTING, paths)
	ProjectSettings.set_setting("internationalization/locale/fallback", FALLBACK)

	var err := ProjectSettings.save()
	if err != OK:
		printerr("[setup_translations] ProjectSettings.save() failed with error %d" % err)
		quit(1)
		return

	print("[setup_translations] Registered %d locale(s):" % paths.size())
	for p: String in paths:
		print("  %s" % p)
	print("[setup_translations] Fallback: %s" % FALLBACK)
	quit(0)
