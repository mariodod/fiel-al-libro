extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Settings are the small things that must survive a restart: language and
## volume. The page itself collects them into one readable ConfigFile.

const SHELL_SCENE := "res://src/ui/manuscript_ui.tscn"

func suite(t):
	t.suite("Settings")

	# Preserve the player's real settings.cfg — this suite writes to it.
	var had_config := FileAccess.file_exists(Settings.CONFIG_PATH)
	var backup := ""
	if had_config:
		var file := FileAccess.open(Settings.CONFIG_PATH, FileAccess.READ)
		if file != null:
			backup = file.get_as_text()
			file.close()
	var original_locale := Settings.get_language()
	var original_volumes := {}
	for bus in Settings.BUSES:
		original_volumes[bus] = Settings.get_volume(bus)

	t.test("language and volume are persisted")
	Settings.set_language("de")
	Settings.set_volume(&"Master", 0.42)
	t.expect_eq(Settings.get_language(), "de", "language is remembered")
	t.expect_almost_eq(Settings.get_volume(&"Master"), 0.42, 0.001, "volume is remembered")
	var disk := ConfigFile.new()
	t.expect_eq(disk.load(Settings.CONFIG_PATH), OK, "settings.cfg is readable")
	t.expect_eq(disk.get_value("locale", "language", ""), "de", "language is on disk")
	t.expect_almost_eq(float(disk.get_value("audio", "Master", 0.0)), 0.42, 0.001,
		"volume is on disk")

	t.test("a volume change reaches the audio bus")
	var index := AudioServer.get_bus_index(&"Master")
	t.expect_ne(index, -1, "Master bus exists")
	if index != -1:
		var db := AudioServer.get_bus_volume_db(index)
		t.expect_almost_eq(db_to_linear(db), 0.42, 0.01, "bus volume follows the setting")

	# Restore the player's settings before touching the UI.
	Settings.set_language(original_locale)
	for bus in original_volumes.keys():
		Settings.set_volume(bus, original_volumes[bus])
	if had_config:
		var file := FileAccess.open(Settings.CONFIG_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(backup)
			file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.CONFIG_PATH))

	t.test("the settings page offers language, volume and controls")
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var packed := load(SHELL_SCENE) as PackedScene
	t.expect_true(packed != null, "the manuscript shell loads")
	if packed == null:
		return
	var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	var shell := packed.instantiate()
	parent.add_child(shell)

	var page := shell.get_node_or_null("Pages/SettingsPage")
	t.expect_true(page != null, "the settings page exists")
	if page == null:
		parent.remove_child(shell)
		shell.free()
		return
	var language := page.get_node_or_null("SettingsMargin/SettingsScroll/SettingsBox/LanguageOption") as OptionButton
	t.expect_true(language != null, "language picker exists")
	if language != null:
		t.expect_eq(language.item_count, 6, "all six shipped locales are offered")
	t.expect_true(page.find_child("Volume_Master", true, false) is HSlider,
		"master volume slider exists")
	t.expect_true(page.find_child("Volume_Music", true, false) is HSlider,
		"music volume slider exists")
	var sheet := page.get_node_or_null("SettingsMargin/SettingsScroll/SettingsBox/ControlsSheet") as GridContainer
	t.expect_true(sheet != null, "controls sheet exists")
	if sheet != null:
		t.expect_gt(float(sheet.get_child_count()), 20.0, "control actions are listed")

	t.test("the page opens, returns, and its buttons are wired")
	shell.close()
	shell.open_settings()
	t.expect_true(page.visible, "settings page is shown")
	t.expect_eq(shell._current_page, &"settings", "shell is on the settings page")
	var back := page.get_node_or_null("SettingsMargin/SettingsScroll/SettingsBox/SettingsBack") as Button
	t.expect_true(back != null, "back button exists")
	var connected := false
	for conn in page.back_pressed.get_connections():
		var callable := conn.get("callable") as Callable
		if callable != null and callable.get_object() == shell:
			connected = true
	t.expect_true(connected, "back returns to the shell")
	shell._turning = false  # the page-turn tween is still running headlessly
	page.back_pressed.emit()
	t.expect_false(page.visible, "back closes the settings page")

	t.test("the controls on the page change the settings")
	var previous_locale := Settings.get_language()
	language.emit_signal("item_selected", 1)
	t.expect_eq(Settings.get_language(), "en", "choosing a language applies it")
	Settings.set_language(previous_locale)
	var master := page.find_child("Volume_Master", true, false) as HSlider
	if master != null:
		master.value = 0.7
		t.expect_almost_eq(Settings.get_volume(&"Master"), 0.7, 0.01,
			"moving a slider changes the bus volume")
		Settings.set_volume(&"Master", original_volumes[&"Master"])

	parent.remove_child(shell)
	shell.free()

	if had_config:
		var restore := FileAccess.open(Settings.CONFIG_PATH, FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
			restore.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.CONFIG_PATH))
