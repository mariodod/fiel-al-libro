extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Progress is split across several owners. A save must restore all of them,
## and New Game must clear all of them — otherwise Continue cannot load the
## saved chapter and a second campaign inherits the first one's state.

const SLOT := 0

func suite(t):
	t.suite("SaveContract")

	var had := Manuscrito.has_save(SLOT)
	var backup := ""
	if had:
		var f := FileAccess.open(Manuscrito.slot_path(SLOT), FileAccess.READ)
		if f != null:
			backup = f.get_as_text()
			f.close()

	t.test("continue restores unlocks and investigation progress")
	ChapterFlow.reset_campaign()
	GameState.current_chapter = &"ch_14_galeotes"
	GameState.chapters_resolved.append(&"ch_01_windmills")
	RegionGraph.complete_chapter(&"ch_01_windmills")
	Lectura.resolve(&"probe_evidence", 2)
	Verdict.verdict_by_truth(&"probe_verdict")
	Locura.set_for(&"quixote", 71.0)
	t.expect_true(Manuscrito.save_game(SLOT), "save succeeds")

	GameState.reset_progress()
	RegionGraph.reset_progress()
	Lectura.reset()
	Verdict.reset()
	Locura.set_for(&"quixote", 0.0)
	t.expect_true(Manuscrito.load_game(SLOT), "load succeeds")
	t.expect_eq(GameState.current_chapter, &"ch_14_galeotes", "chapter restored")
	t.expect_true(RegionGraph.chapters_unlocked.has(&"ch_02_basque"),
		"unlocks restored")
	t.expect_true(GameState.chapters_resolved.has(&"ch_01_windmills"),
		"completed chapters restored")
	t.expect_true(Lectura.is_resolved(&"probe_evidence"), "evidence restored")
	t.expect_almost_eq(Locura.get_for(&"quixote"), 71.0, 0.01, "madness restored")

	t.test("new game clears every progression owner")
	ChapterFlow.reset_campaign()
	t.expect_eq(GameState.chapters_resolved.size(), 0, "chapters cleared")
	t.expect_eq(RegionGraph.chapters_unlocked.size(), 1, "only first chapter unlocked")
	t.expect_false(Lectura.is_resolved(&"probe_evidence"), "evidence cleared")
	t.expect_almost_eq(Locura.get_for(&"quixote"), 45.0, 0.01, "madness reset")
	t.expect_eq(Biblioteca.collected.size(), 0, "shelf cleared")
	t.expect_eq(Ensayo.state, "setup", "ensayo reset")
	t.expect_false(ChapterFlow.transitioning, "stale transition cleared")

	t.test("a save from a newer build is refused")
	var f := FileAccess.open(Manuscrito.slot_path(SLOT), FileAccess.WRITE)
	if f != null:
		f.store_string('{"version": 999, "game_state": {}}')
		f.close()
	t.expect_false(Manuscrito.load_game(SLOT), "future save rejected")

	if had:
		var restore := FileAccess.open(Manuscrito.slot_path(SLOT), FileAccess.WRITE)
		if restore != null:
			restore.store_string(backup)
			restore.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Manuscrito.slot_path(SLOT)))
	ChapterFlow.reset_campaign()
