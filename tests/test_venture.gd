extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The Venture of Montiel — minimal test using only Node3D-compatible calls.
## venture is obtained via get_node_or_null("Venture") which returns Node3D.

const SCENE = "res://src/world/slice.tscn"

func suite(t):
	t.suite("Venture")

	var tree = Engine.get_main_loop() as SceneTree
	var parent = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene = packed.instantiate()
	parent.add_child(scene)

	var venture = scene.get_node_or_null("Venture")
	var quixote = scene.get_node_or_null("Characters/Quixote")
	var sancho = scene.get_node_or_null("Characters/Sancho")
	t.expect_true(venture != null and quixote != null and sancho != null,
		"the slice should have a Venture and the two of them")
	if venture == null or quixote == null or sancho == null:
		parent.remove_child(scene)
		scene.free()
		return

	t.test("the Venture stands in the middle of it")
	t.expect_almost_eq(venture.global_position.distance_to(
		Vector3(0.0, 0.0, 36.0)), 0.0, 0.01, "in the middle of the floor")

	parent.remove_child(scene)
	scene.free()
