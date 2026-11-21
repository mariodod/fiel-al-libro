extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Shelf changes must reach live pawns. PassiveManager calls
## apply_passive_modifiers() directly; a mismatch with the pawn's method name
## used to make that call fail silently while only the signal path worked.

func suite(t):
	t.suite("PassiveWiring")

	t.test("a live pawn has the public modifier entry point")
	var packed := load("res://src/world/slice.tscn") as PackedScene
	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	var scene := packed.instantiate()
	parent.add_child(scene)
	var quixote = scene.get_node_or_null("Characters/Quixote")
	t.expect_true(quixote != null, "Quixote is in the scene")
	if quixote != null:
		t.expect_true(quixote.has_method("apply_passive_modifiers"),
			"pawn exposes the method PassiveManager calls")

		t.test("changing the shelf applies modifiers to the pawn without error")
		quixote.max_health = 100.0
		var mods := PassiveManager.modifiers.duplicate()
		mods["health_bonus"] = 25.0
		quixote.apply_passive_modifiers(mods)
		t.expect_almost_eq(quixote.max_health, 125.0, 0.01,
			"health bonus reached the pawn")
		quixote.apply_passive_modifiers(PassiveManager.modifiers)
		t.expect_almost_eq(quixote.max_health, 100.0, 0.01,
			"restoring default modifiers restores health")

	parent.remove_child(scene)
	scene.free()
