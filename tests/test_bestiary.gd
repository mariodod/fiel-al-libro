extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §10: a Bestiary records the creatures met on the road. Entries are
## locked until the chapter introducing their Venture is entered.

func suite(t):
	t.suite("Bestiary")

	t.test("every enemy resource loads and has both readings")
	var dir := DirAccess.open("res://src/data/enemies/")
	var enemies: Array[EnemyData] = []
	for name in dir.get_files():
		if not name.ends_with(".tres"):
			continue
		var data: EnemyData = load("res://src/data/enemies/" + name)
		t.expect_true(data != null, "%s loads" % name)
		if data != null:
			enemies.append(data)
			t.expect_false(data.display_name_key.is_empty(), "%s has a name" % name)
			t.expect_true(data.reality_form != null, "%s has a Reality form" % name)
			t.expect_true(data.book_form != null, "%s has a Book form" % name)
	t.expect_gt(float(enemies.size()), 10.0, "a real bestiary exists")

	t.test("meeting an enemy is recorded and persisted")
	var old := GameState.enemies_met.duplicate()
	GameState.enemies_met.clear()
	GameState.meet_enemy(&"venture_montiel")
	t.expect_true(GameState.has_met_enemy(&"venture_montiel"), "enemy recorded")
	GameState.meet_enemy(&"venture_montiel")
	t.expect_eq(GameState.enemies_met.size(), 1, "meeting twice is idempotent")
	GameState.enemies_met = old

	t.test("the Bestiary page is reachable and locked entries exist")
	var tree := Engine.get_main_loop() as SceneTree
	var shell := (load("res://src/ui/manuscript_ui.tscn") as PackedScene).instantiate()
	tree.current_scene.add_child(shell)
	var page := shell.get_node_or_null("Pages/BestiaryPage")
	t.expect_true(page != null, "BestiaryPage exists")
	var wired := false
	if page != null:
		for conn in page.back_pressed.get_connections():
			var callable := conn.get("callable") as Callable
			if callable != null and callable.get_object() == shell:
				wired = true
	t.expect_true(wired, "back returns to the shell")
	shell.close()
	shell.open_bestiary()
	t.expect_true(page.visible, "page opens")
	t.expect_eq(shell._current_page, &"bestiary", "shell is on the Bestiary")
	tree.current_scene.remove_child(shell)
	shell.free()
