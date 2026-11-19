extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Every chapter has a Posada (GDD §8.1, §11.3). The innkeeper, musician and
## checkpoint were already everywhere; the InnKit building completes the hub.

const INN_KIT := "res://src/world/environment_kits/inn_kit.tscn"

func suite(t):
	t.suite("Posadas")

	t.test("every chapter scene has exactly one InnKit")
	var dir := DirAccess.open("res://src/world/chapters/")
	var scenes: Array[String] = []
	for name in dir.get_files():
		if name.ends_with(".tscn"):
			scenes.append(name)
	t.expect_gt(float(scenes.size()), 40.0, "all chapters exist")
	for name in scenes:
		var text := FileAccess.get_file_as_string("res://src/world/chapters/" + name)
		t.expect_eq(text.count('name="InnKit"'), 1, "%s has one InnKit" % name)
		t.expect_true(text.contains(INN_KIT), "%s instances the inn kit scene" % name)

	t.test("a chapter's InnKit instantiates with its geometry")
	for scene_path in ["res://src/world/chapters/ch_01_windmills.tscn",
			"res://src/world/chapters/ch_14_galeotes.tscn"]:
		var packed := load(scene_path) as PackedScene
		t.expect_true(packed != null, "%s loads" % scene_path)
		if packed == null:
			continue
		var scene := packed.instantiate()
		var inn := scene.get_node_or_null("InnKit")
		t.expect_true(inn != null, "InnKit is in the live scene")
		if inn != null:
			t.expect_eq(inn.get_child_count(), 7, "the inn has walls and a roof")
		# The same fix applies to every environment kit, including the field
		# the Posada stands beside.
		var field := scene.get_node_or_null("FieldKit")
		t.expect_true(field != null and field.get_child_count() > 0,
			"environment kits instantiate their geometry")
		scene.queue_free()
