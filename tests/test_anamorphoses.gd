extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Every chapter has 2–4 anamorphoses (GDD §11.3): a detail that does not add
## up, visible in Lectura mode only from a vantage point.

func suite(t):
	t.suite("Anamorphoses")

	t.test("every chapter scene carries two anamorphosis objects")
	var dir := DirAccess.open("res://src/world/chapters/")
	var scenes: Array[String] = []
	for name in dir.get_files():
		if name.ends_with(".tscn"):
			scenes.append(name)
	t.expect_gt(float(scenes.size()), 40.0, "all chapters exist")
	for name in scenes:
		var text := FileAccess.get_file_as_string("res://src/world/chapters/" + name)
		var count := text.count("name=\"Anamorphosis_")
		t.expect_eq(count, 2, "%s has two anamorphoses" % name)

	t.test("a chapter scene instantiates its anamorphosis objects")
	var packed := load("res://src/world/chapters/ch_14_galeotes.tscn") as PackedScene
	t.expect_true(packed != null, "chapter scene loads")
	if packed != null:
		var scene := packed.instantiate()
		scene.queue_free()
		var nodes: Array[Node] = []
		_recurse_names(scene, nodes)
		var count := 0
		for node in nodes:
			if str(node.name).begins_with("Anamorphosis_"):
				count += 1
				var obj := node as TruthObject
				t.expect_true(obj != null, "%s is a TruthObject" % node.name)
				if obj != null:
					t.expect_false(obj.anamorphosis_id().is_empty(), "%s has an id" % node.name)
		t.expect_eq(count, 2, "two anamorphosis objects in the live scene")

	t.test("the anamorphosis data resolves at runtime")
	var data_dir := DirAccess.open("res://src/data/anamorphoses/")
	var total := 0
	for name in data_dir.get_files():
		if not name.ends_with(".tres"):
			continue
		total += 1
		var res: TruthObjectData = load("res://src/data/anamorphoses/" + name)
		t.expect_true(res != null, "%s loads" % name)
		if res == null:
			continue
		t.expect_false(res.anamorphosis_id.is_empty(), "%s has an id" % name)
		t.expect_false(res.anamorphosis_tell_key.is_empty(), "%s has a tell key" % name)
		t.expect_gt(float(res.anamorphosis_evidence), 0.0, "%s grants evidence" % name)
		t.expect_true(Loc.t(res.anamorphosis_tell_key) != str(res.anamorphosis_tell_key),
			"%s tell is translated" % name)
	t.expect_eq(total, 94, "94 anamorphoses across 47 chapters")

	t.test("resolving an anamorphosis grants evidence once")
	var res: TruthObjectData = load("res://src/data/anamorphoses/ana.ch14.age.tres")
	t.expect_true(res != null, "a chapter anamorphosis loads")
	if res != null:
		Lectura.reset()
		var id := res.anamorphosis_id
		t.expect_false(Lectura.is_resolved(id), "starts unresolved")
		var gained := Lectura.resolve(id, res.anamorphosis_evidence)
		t.expect_gt(float(gained), 0.0, "evidence granted")
		t.expect_true(Lectura.is_resolved(id), "now resolved")
		var again := Lectura.resolve(id, res.anamorphosis_evidence)
		t.expect_eq(again, 0, "cannot be resolved twice")
		Lectura.reset()


func _recurse_names(node: Node, out: Array[Node]) -> void:
	out.append(node)
	for child in node.get_children():
		_recurse_names(child, out)
