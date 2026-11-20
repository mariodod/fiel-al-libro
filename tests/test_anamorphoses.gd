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

	t.test("every Manifiesto fragment is reachable in the game")
	var manifesto_dir := DirAccess.open("res://assets/manifiesto/")
	var fragment_count := 0
	var unreachable: Array[String] = []
	for name in manifesto_dir.get_files():
		if not name.ends_with(".json"):
			continue
		fragment_count += 1
		var id := StringName(name.replace(".json", ""))
		var reachable := false
		for res: TruthObjectData in _all_anamorphoses():
			if res.anamorphosis_fragment == id:
				reachable = true
				break
		for venture_path in _all_venture_data():
			if venture_path.manifesto_fragments.has(id):
				reachable = true
				break
		for region in _all_regions():
			if region.fragment_id == id:
				reachable = true
				break
		if not reachable:
			unreachable.append(id)
	t.expect_eq(fragment_count, 49, "49 fragments exist")
	t.expect_eq(unreachable.size(), 0, "none are uncollectable: %s" % str(unreachable))

	t.test("resolving an anamorphosis grants its Manifiesto page")
	var reward: TruthObjectData = null
	for res in _all_anamorphoses():
		if not res.anamorphosis_fragment.is_empty():
			reward = res
			break
	t.expect_true(reward != null, "a reward-bearing anamorphosis exists")
	if reward != null:
		GameState.reset_progress()
		Lectura.reset()
		t.expect_false(GameState.codex_pages.has(reward.anamorphosis_fragment),
			"page starts uncollected")
		Lectura.resolve(reward.anamorphosis_id, reward.anamorphosis_evidence,
			reward.anamorphosis_fragment)
		t.expect_has(GameState.codex_pages, reward.anamorphosis_fragment,
			"the page is granted by reading the seam")
		Lectura.reset()

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

func _all_anamorphoses() -> Array[TruthObjectData]:
	var out: Array[TruthObjectData] = []
	var dir := DirAccess.open("res://src/data/anamorphoses/")
	for name in dir.get_files():
		if name.ends_with(".tres"):
			var res: TruthObjectData = load("res://src/data/anamorphoses/" + name)
			if res != null:
				out.append(res)
	return out


func _all_venture_data() -> Array[VentureData]:
	var out: Array[VentureData] = []
	var dir := DirAccess.open("res://src/data/ventures/")
	for name in dir.get_files():
		if name.ends_with(".tres"):
			var res = load("res://src/data/ventures/" + name)
			if res is VentureData:
				out.append(res)
	return out


func _all_regions() -> Array[RegionData]:
	var out: Array[RegionData] = []
	var dir := DirAccess.open("res://src/data/regions/")
	for name in dir.get_files():
		if name.ends_with(".tres"):
			var res: RegionData = load("res://src/data/regions/" + name)
			if res != null:
				out.append(res)
	return out
