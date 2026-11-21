extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The "Codes" screen lets a player read the game in another language and
## import a community .po. The parser must handle real gettext escaping; the
## importer must install a Translation that every tr() call can see.

const PoParser = preload("res://src/systems/po_parser.gd")
const SHELL := "res://src/ui/manuscript_ui.tscn"
const SLOT_FILE := "user://codes_test.po"

func suite(t):
	t.suite("Codes")

	# A previous failed run may have left a fixture behind; start clean.
	if FileAccess.file_exists(SLOT_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SLOT_FILE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://translations/codes_test.po"))

	t.test("the PO parser handles single-line entries and skips blanks")
	var text := '''#. META: namespace=ui
msgid "ui.menu.continue"
msgstr "Continuar"

msgid "ui.menu.settings"
msgstr ""
'''
	var parsed: Dictionary = PoParser.parse(text)
	t.expect_eq(parsed.size(), 1, "only translated entries survive")
	t.expect_eq(str(parsed.get("ui.menu.continue", "")), "Continuar", "value parsed")

	t.test("the parser joins continuation lines and unescapes values")
	var multi := '''msgid "bk.long"
msgstr ""
"Primera linea\\n"
"Segunda \\"entre comillas\\" y final."
'''
	var p2: Dictionary = PoParser.parse(multi)
	var value := str(p2.get("bk.long", ""))
	t.expect_true(value.contains("\n"), "\\n was unescaped")
	t.expect_true(value.contains("entre comillas"), "escaped quotes were unescaped")
	t.expect_false(value.contains("\\\""), "no leftover escape sequences")

	t.test("the locale code comes from the PO header, then the filename")
	var po := 'msgid ""\nmsgstr ""\n"Language: gl-ES\\n"\n\nmsgid "ui.menu.continue"\nmsgstr "Reanudar"\n'
	t.expect_eq(PoParser.locale_from_header(po, "ignored.po"), "gl_ES", "header Locale normalised")
	t.expect_eq(PoParser.locale_from_header("no header", "pt_PT.po"), "pt_PT", "filename fallback")

	# Preserve locale and any user settings before importing a test translation.
	var original_locale := Loc.current_locale()
	var language_value := Settings.get_language()
	var had_file := FileAccess.file_exists(Settings.CONFIG_PATH)
	var config_backup := ""
	if had_file:
		var f := FileAccess.open(Settings.CONFIG_PATH, FileAccess.READ)
		if f != null:
			config_backup = f.get_as_text()
			f.close()

	t.test("importing a PO installs a usable Translation")
	var result: Dictionary = TranslationManager.import_from_text(po, "gl_ES.po")
	t.expect_true(bool(result.get("ok", false)), "import succeeded")
	t.expect_eq(str(result.get("locale", "")), "gl_ES", "locale from header")
	t.expect_true(TranslationManager.is_imported("gl_ES"), "locale is registered")
	TranslationManager.use_locale("gl_ES")
	t.expect_eq(Loc.current_locale(), "gl_ES", "locale was applied")
	t.expect_eq(tr(&"ui.menu.continue"), "Reanudar", "game text uses the import")
	t.expect_true(FileAccess.file_exists("user://translations/gl_ES.po"), "import was persisted")

	t.test("an imported locale appears in the available list")
	t.expect_has(TranslationManager.available_locales, "gl_ES", "locale selectable in Codes")

	t.test("forgetting a locale removes it")
	TranslationManager.forget("gl_ES")
	t.expect_false(TranslationManager.is_imported("gl_ES"), "locale removed")
	t.expect_false(FileAccess.file_exists("user://translations/gl_ES.po"), "file removed")

	t.test("importing from a file path works")
	var f := FileAccess.open(SLOT_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string('msgid ""\nmsgstr ""\n"Language: zz\\n"\n\nmsgid "ui.menu.continue"\nmsgstr "Zzz"\n')
		f.close()
	var by_path: Dictionary = TranslationManager.import_from_path(SLOT_FILE)
	t.expect_true(bool(by_path.get("ok", false)), "file import succeeded")
	t.expect_eq(str(by_path.get("locale", "")), "zz", "locale read from file")
	TranslationManager.forget("zz")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SLOT_FILE))

	t.test("a PO with no translations is rejected")
	var empty := TranslationManager.import_from_text('msgid ""\nmsgstr ""\n"Language: zz\\n"', "zz.po")
	t.expect_false(bool(empty.get("ok", false)), "empty import rejected")
	t.expect_eq(str(empty.get("error", "")), "no_translations", "reason reported")

	# Restore the player's locale and settings file.
	Loc.set_locale(original_locale)
	Settings.set_language(language_value)
	if had_file:
		var restore := FileAccess.open(Settings.CONFIG_PATH, FileAccess.WRITE)
		if restore != null:
			restore.store_string(config_backup)
			restore.close()

	t.test("the Codes page is reachable and wired")
	var tree := Engine.get_main_loop() as SceneTree
	var shell := (load(SHELL) as PackedScene).instantiate()
	tree.current_scene.add_child(shell)
	var page := shell.get_node_or_null("Pages/CodesPage")
	t.expect_true(page != null, "CodesPage exists")
	if page != null:
		var dialog := page.get_node_or_null("PoFileDialog") as FileDialog
		t.expect_true(dialog != null, "file dialog exists")
		t.expect_true(page.find_child("ImportButton", true, false) is Button, "import button exists")
		var back_connected := false
		for conn in page.back_pressed.get_connections():
			var callable := conn.get("callable") as Callable
			if callable != null and callable.get_object() == shell:
				back_connected = true
		t.expect_true(back_connected, "back returns to the shell")
	shell.close()
	shell.open_codes()
	t.expect_true(page.visible, "Codes page opens")
	t.expect_eq(shell._current_page, &"codes", "shell is on the Codes page")
	shell._turning = false
	page.back_pressed.emit()
	t.expect_false(page.visible, "back closes the page")
	tree.current_scene.remove_child(shell)
	shell.free()
