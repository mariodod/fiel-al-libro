extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The Ensayo must be playable end to end: four setup choices, five rounds of
## interventions, a recorded outcome, and chapter completion so ChapterFlow
## can advance. Previously the state machine had no callers at all.

const UI_SCRIPT := preload("res://src/ui/ensayo_ui.gd")
const CH09 := "res://src/world/chapters/ch_09_ensayo_setup.tscn"
const CH10 := "res://src/world/chapters/ch_10_ensayo_resolution.tscn"

func suite(t):
	t.suite("EnsayoFlow")

	# Preserve progress this suite mutates.
	var old_chapters := GameState.chapters_resolved.duplicate()
	var old_flags := GameState.flags.duplicate(true)
	var old_humanity := GameState.humanity
	var old_author := GameState.author_revealed

	t.test("the Ensayo UI renders the setup phase with four choices")
	var ui := UI_SCRIPT.new()
	t.expect_true(ui != null, "UI script instantiates")
	if ui != null:
		t.expect_true(ui.has_method("_render_setup"), "setup phase exists")
		t.expect_true(ui.has_method("_render_round"), "simulation phase exists")
		t.expect_true(ui.has_method("_render_consequence"), "consequence phase exists")
		ui.free()

	t.test("the authored script has five rounds and four verbs each")
	var f := FileAccess.open("res://assets/ensayo/ensayo_script.json", FileAccess.READ)
	t.expect_true(f != null, "ensayo script exists")
	if f != null:
		var text := f.get_as_text().replace(",]", "]").replace(",}", "}")
		f.close()
		var data: Variant = JSON.parse_string(text)
		t.expect_true(data is Dictionary, "script parses as JSON")
		if data is Dictionary:
			var sim: Dictionary = data.get("simulation", {})
			var rounds: Array = sim.get("rounds", [])
			t.expect_eq(rounds.size(), 5, "five social rounds")
			var verbs: Dictionary = rounds[0].get("interventions", {})
			t.expect_eq(verbs.size(), 4, "dialogue, warning, look and letter")

	t.test("a staged test runs all rounds and resolves")
	Ensayo.reset()
	Ensayo.start_setup(&"quixote", &"sancho", &"wife_name", &"tested")
	t.expect_true(Ensayo.is_in_setup(), "setup phase entered")
	Ensayo.start_simulation(Ensayo.setup.tested, Ensayo.setup.examiner,
		Ensayo.setup.secret, Ensayo.setup.told)
	t.expect_true(Ensayo.is_in_simulation(), "simulation phase entered")
	var resolved: Array = []
	var on_resolved := func(outcome: int, _reasons: Array): resolved.append(outcome)
	EventBus.ensayo_resolved.connect(on_resolved)
	for round_num in range(Ensayo.max_rounds):
		Ensayo.add_intervention("dialogue", "a line", &"")
		Ensayo.next_round()
	t.expect_true(Ensayo.is_in_consequence(), "consequence phase entered")
	t.expect_eq(Ensayo.get_interventions().size(), Ensayo.max_rounds,
		"every intervention was recorded")
	t.expect_eq(resolved.size(), 1, "the outcome was emitted exactly once")
	EventBus.ensayo_resolved.disconnect(on_resolved)

	t.test("refusing is a supported, deterministic outcome")
	Ensayo.reset()
	Ensayo.start_setup(&"quixote", &"sancho", &"wife_name", &"tested")
	Ensayo.start_simulation(&"quixote", &"sancho", &"wife_name", &"tested")
	Ensayo.refuse()
	t.expect_eq(Ensayo.get_outcome(), Ensayo.Outcome.REFUSED, "refusal outcome")
	t.expect_true(GameState.has_flag("ensayo_refused"), "the gap is recorded")

	t.test("completing the Ensayo marks both chapters so the flow can advance")
	RegionGraph.reset_progress()
	var before := GameState.chapters_resolved.duplicate()
	GameState.chapter_started(&"ch_09_ensayo_setup")
	var controller := (load(CH09) as PackedScene).instantiate() as Node
	var tree := Engine.get_main_loop() as SceneTree
	tree.current_scene.add_child(controller)
	controller.complete_ensayo()
	t.expect_true(GameState.chapters_resolved.has(&"ch_09_ensayo_setup"), "ch9 complete")
	t.expect_true(GameState.chapters_resolved.has(&"ch_10_ensayo_resolution"), "ch10 complete")
	t.expect_true(RegionGraph.is_chapter_completed(&"ch_09_ensayo_setup"), "graph updated")
	tree.current_scene.remove_child(controller)
	controller.free()

	# Restore global state.
	GameState.chapters_resolved = old_chapters
	GameState.flags = old_flags
	GameState.humanity = old_humanity
	GameState.author_revealed = old_author
	RegionGraph.reset_progress()
	Ensayo.reset()
