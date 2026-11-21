extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §12.2: the ending is driven by five legible variables. Verdict counts
## must come from the Verdict system (not dead flags) and Humanity must have a
## real say — a player who hurt innocents cannot get the clean ending.

func suite(t):
	t.suite("EndingVariables")

	var old_h := GameState.humanity
	var old_author := GameState.author_revealed
	var old_flags := GameState.flags.duplicate(true)
	var old_q := Locura.get_for(&"quixote")
	var old_s := Locura.get_for(&"sancho")
	var old_books := Biblioteca.collected.duplicate()
	GameState.flags.clear()
	GameState.author_revealed = false
	Locura.set_for(&"quixote", 10.0)
	Locura.set_for(&"sancho", 5.0)
	Biblioteca.collected.clear()

	t.test("verdict counts are read from the Verdict system")
	var truth_before := Verdict.truth_count()
	var force_before := Verdict.force_count()
	Verdict.verdict_by_truth(&"probe_truth")
	Verdict.verdict_by_force(&"probe_force")
	var vars := GameState.ending_variables()
	t.expect_eq(int(vars.get("verdicts_truth", -1)), truth_before + 1, "truth verdict counted")
	t.expect_eq(int(vars.get("verdicts_force", -1)), force_before + 1, "force verdict counted")

	t.test("a high-Humanity run still gets the clean ending")
	# Verdict verdicts raised Quixote's Locura; reset to a calm baseline.
	Locura.set_for(&"quixote", 10.0)
	Locura.set_for(&"sancho", 5.0)
	GameState.humanity = 100
	t.expect_eq(GameState.compute_ending(), &"el_mundo_real", "clean real-world ending")

	t.test("a low-Humanity run cannot get the clean ending")
	GameState.humanity = 20
	t.expect_ne(GameState.compute_ending(), &"el_mundo_real", "Humanity costs the clean ending")
	t.expect_eq(GameState.compute_ending(), &"el_libro_gana", "falls back to compromise")

	GameState.humanity = old_h
	GameState.author_revealed = old_author
	GameState.flags = old_flags
	Locura.set_for(&"quixote", old_q)
	Locura.set_for(&"sancho", old_s)
	Biblioteca.collected = old_books
