extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The title page is the entry point of the campaign. Begin starts a new
## manuscript; Continue restores the autosave and re-enters the saved chapter.
## Continue must only be offered when a save actually exists.

const SHELL_SCENE := "res://src/ui/manuscript_ui.tscn"
const SLOT := 0  # the autosave slot ChapterFlow and the title page use

func suite(t):
	t.suite("Continue UI")

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var packed := load(SHELL_SCENE) as PackedScene
	t.expect_true(packed != null, "the manuscript shell loads")
	if packed == null:
		return

	# Preserve any real autosave: this suite writes to slot 0.
	var had_save := Manuscrito.has_save(SLOT)
	var backup := ""
	if had_save:
		var file := FileAccess.open(Manuscrito.slot_path(SLOT), FileAccess.READ)
		if file != null:
			backup = file.get_as_text()
			file.close()
	Manuscrito.delete_save(SLOT)

	var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	var shell := packed.instantiate()
	parent.add_child(shell)

	var start := shell.get_node_or_null("Pages/TitlePage/TitleStart") as Button
	var cont := shell.get_node_or_null("Pages/TitlePage/TitleContinue") as Button

	t.test("the title page offers Begin and Continue")
	t.expect_true(start != null, "Begin exists")
	t.expect_true(cont != null, "Continue exists")
	if cont == null:
		parent.remove_child(shell)
		shell.free()
		_restore_save(had_save, backup)
		return
	t.expect_eq(cont.text, Loc.t(&"ui.menu.continue"), "Continue is localized")

	t.test("Continue is wired to the shell's handler")
	var connected := false
	for conn in cont.pressed.get_connections():
		var callable := conn.get("callable") as Callable
		if callable != null and callable.get_object() == shell \
				and callable.get_method() == "_on_continue_pressed":
			connected = true
	t.expect_true(connected, "the pressed signal reaches _on_continue_pressed")

	t.test("Continue is hidden until a save exists")
	shell.open_title()
	t.expect_false(cont.visible, "no save: Continue hidden")
	t.expect_true(cont.disabled, "no save: Continue disabled")

	t.test("Continue appears once the autosave exists")
	t.expect_true(Manuscrito.save_game(SLOT), "an autosave can be written")
	shell.close()
	shell.open_title()
	t.expect_true(cont.visible, "saved: Continue visible")
	t.expect_false(cont.disabled, "saved: Continue enabled")

	parent.remove_child(shell)
	shell.free()
	_restore_save(had_save, backup)


func _restore_save(had_save: bool, backup: String) -> void:
	if had_save:
		var file := FileAccess.open(Manuscrito.slot_path(SLOT), FileAccess.WRITE)
		if file != null:
			file.store_string(backup)
			file.close()
	else:
		Manuscrito.delete_save(SLOT)
