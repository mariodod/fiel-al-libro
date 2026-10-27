extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## "El Manuscrito" — the save system. A corrupt save is the worst bug you
## can ship, so this is the suite that matters most.

func suite(t):
	t.suite("Manuscrito")

	const SLOT = 2  # a scratch slot, away from the autosave slot

	t.test("a save round-trips the whole campaign state")
	GameState.current_chapter = &"ch_01"
	GameState.current_region = &"region_mancha"
	GameState.humanity = 73
	GameState.set_flag("found_second_book", true)
	GameState.codex_pages.append(&"bk.ch08.molinos.01")
	GameState.evidence[&"cue_molinos"] = 2
	Locura.set_for(&"quixote", 42.0)
	Locura.set_for(&"sancho", 11.0)
	Memoria.gain(&"quixote", 7, false)
	Biblioteca.collect(&"tio_andalus")
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)

	t.expect_true(Manuscrito.save_game(SLOT), "save should succeed")

	# Wipe everything, then load it back.
	GameState.current_chapter = &""
	GameState.humanity = 100
	GameState.flags.clear()
	GameState.codex_pages.clear()
	GameState.evidence.clear()
	Locura.set_for(&"quixote", 0.0)
	Locura.set_for(&"sancho", 0.0)
	Biblioteca.collected.clear()
	Biblioteca.equipped.clear()
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)

	t.expect_true(Manuscrito.load_game(SLOT), "load should succeed")
	t.expect_eq(GameState.current_chapter, &"ch_01", "chapter restored")
	t.expect_eq(GameState.current_region, &"region_mancha", "region restored")
	t.expect_eq(GameState.humanity, 73, "humanity restored")
	t.expect_true(GameState.has_flag("found_second_book"), "flags restored")
	t.expect_has(GameState.codex_pages, &"bk.ch08.molinos.01", "codex pages restored")
	t.expect_eq(GameState.get_evidence_count(&"cue_molinos"), 2, "evidence restored")
	t.expect_almost_eq(Locura.get_for(&"quixote"), 42.0, 0.001, "quixote madness restored")
	t.expect_almost_eq(Locura.get_for(&"sancho"), 11.0, 0.001, "sancho madness restored")
	t.expect_true(Biblioteca.has_book(&"tio_andalus"), "library restored")
	t.expect_true(TruthLayer.is_book(), "truth layer restored")

	t.test("the save file is valid JSON")
	var file = FileAccess.open(Manuscrito.slot_path(SLOT), FileAccess.READ)
	t.expect_true(file != null, "save file should be openable")
	if file != null:
		var text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(text)
		t.expect_eq(typeof(parsed), TYPE_DICTIONARY, "save file should parse as JSON")
		if typeof(parsed) == TYPE_DICTIONARY:
			t.expect_true((parsed as Dictionary).has("version"), "save file should carry a version")

	t.test("a slot summary can be read back")
	var summary = Manuscrito.slot_summary(SLOT)
	t.expect_eq(summary.get("chapter", ""), "ch_01", "summary reports the chapter")

	t.test("loading an empty slot fails cleanly")
	t.expect_false(Manuscrito.load_game(9), "empty slot should return false")
