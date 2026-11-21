extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")

func suite(t):
	t.suite("ThemeApply")
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.root
	t.expect_true(root.theme != null, "root has the custom theme")
	if root.theme != null:
		t.expect_true(root.theme.has_font("font", "BookText"), "book font available")
	# Check the colophon's text label inherits the UI font.
	var shell := (load("res://src/world/colophon.tscn") as PackedScene).instantiate()
	tree.current_scene.add_child(shell)
	var label := shell.get_node_or_null("Panel/Text") as Label
	if label != null:
		t.expect_true(label.theme != null or label.get_theme_font("font") != null,
			"colophon text has a font")
	tree.current_scene.remove_child(shell)
	shell.free()
