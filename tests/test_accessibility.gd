extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §17: accessibility must change presentation without changing the story.
## The three options are reduce-ink, large subtitles and toggle sprint.

func suite(t):
	t.suite("Accessibility")

	var had := FileAccess.file_exists(Settings.CONFIG_PATH)
	var backup := ""
	if had:
		var f := FileAccess.open(Settings.CONFIG_PATH, FileAccess.READ)
		if f != null:
			backup = f.get_as_text()
			f.close()
	var old_ink := TruthLayer.ink_amount()

	t.test("accessibility flags persist and are exposed")
	Settings.set_bool(&"reduce_ink", true)
	Settings.set_bool(&"large_subtitles", true)
	Settings.set_bool(&"toggle_sprint", true)
	t.expect_true(Settings.reduce_ink(), "reduce ink stored")
	t.expect_true(Settings.large_subtitles(), "large subtitles stored")
	t.expect_true(Settings.toggle_sprint(), "toggle sprint stored")

	t.test("reduce ink caps the shader value")
	TruthLayer.set_ink(1.0)
	t.expect_almost_eq(TruthLayer.ink_amount(), 0.4, 0.001, "ink capped")

	t.test("the settings page offers the three options")
	var tree := Engine.get_main_loop() as SceneTree
	var shell := (load("res://src/ui/manuscript_ui.tscn") as PackedScene).instantiate()
	tree.current_scene.add_child(shell)
	var page := shell.get_node_or_null("Pages/SettingsPage")
	if page != null:
		for key in ["reduce_ink", "large_subtitles", "toggle_sprint"]:
			var check := page.find_child("A11y_%s" % key, true, false) as CheckBox
			t.expect_true(check != null, "%s checkbox exists" % key)
			if check != null:
				t.expect_true(check.button_pressed, "%s reflects the saved value" % key)
	tree.current_scene.remove_child(shell)
	shell.free()

	Settings.set_bool(&"reduce_ink", false)
	Settings.set_bool(&"large_subtitles", false)
	Settings.set_bool(&"toggle_sprint", false)
	TruthLayer.set_ink(0.0)
	TruthLayer.set_ink(old_ink)
	if had:
		var restore := FileAccess.open(Settings.CONFIG_PATH, FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
			restore.close()
