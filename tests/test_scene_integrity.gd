extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Load every scene and resource the game ships. File-existence checks are not
## enough: an undefined ExtResource or an invalid typed array parses as a
## missing resource and the chapter silently cannot be entered.

const CHAPTERS := "res://src/world/chapters/"
const DATA := "res://src/data/"

func suite(t):
	t.suite("SceneIntegrity")

	t.test("every chapter scene loads and instantiates")
	var dir := DirAccess.open(CHAPTERS)
	var count := 0
	for name in dir.get_files():
		if not name.ends_with(".tscn"):
			continue
		count += 1
		var path := CHAPTERS + name
		var packed := load(path) as PackedScene
		t.expect_true(packed != null, "%s loads" % name)
		if packed != null:
			var inst := packed.instantiate()
			t.expect_true(inst != null, "%s instantiates" % name)
			if inst != null:
				inst.queue_free()
	t.expect_gt(float(count), 40.0, "all chapters are covered")

	t.test("every data resource loads")
	var paths: Array[String] = []
	_collect(DATA, paths)
	t.expect_gt(float(paths.size()), 200.0, "all data resources are covered")
	for path in paths:
		t.expect_true(load(path) != null, "%s loads" % path)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	for name in dir.get_files():
		if name.ends_with(".tres"):
			out.append(dir_path + name)
	for name in dir.get_directories():
		if name == "." or name == "..":
			continue
		_collect(dir_path + name + "/", out)
