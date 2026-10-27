extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The ending aggregation (GDD.md §12.2, D1, D4). Kept pure so it can be
## tested without playing 10 hours of game.

func suite(t):
	t.suite("Ending")

	# Reset the campaign state to a known baseline.
	GameState.humanity = 100
	GameState.author_revealed = false
	GameState.flags.clear()
	Biblioteca.collected.clear()
	Locura.set_for(&"quixote", 0.0)
	Locura.set_for(&"sancho", 0.0)

	t.test("both cured and the book shelved -> El Mundo Real")
	Locura.set_for(&"quixote", 10.0)
	Locura.set_for(&"sancho", 5.0)
	t.expect_eq(GameState.compute_ending(), &"el_mundo_real", "calm ending")

	t.test("both broken -> La Locura Compartida")
	Locura.set_for(&"quixote", 90.0)
	Locura.set_for(&"sancho", 85.0)
	t.expect_eq(GameState.compute_ending(), &"la_locura_compartida", "shared madness ending")

	t.test("the hidden ending needs the author reveal AND the books")
	GameState.author_revealed = true
	Locura.set_for(&"quixote", 10.0)
	Locura.set_for(&"sancho", 5.0)
	# Fewer than 12 books -> not yet the hidden ending.
	t.expect_ne(GameState.compute_ending(), &"el_manuscrito", "needs 12+ books")
	for i in range(12):
		Biblioteca.collect(StringName("book_%d" % i))
	t.expect_eq(GameState.compute_ending(), &"el_manuscrito", "hidden ending unlocked")

	t.test("a middling run gets the compromise ending")
	GameState.author_revealed = false
	Biblioteca.collected.clear()
	Locura.set_for(&"quixote", 40.0)
	Locura.set_for(&"sancho", 45.0)
	t.expect_eq(GameState.compute_ending(), &"el_libro_gana", "compromise ending")

	t.test("humanity is tracked as a variable")
	GameState.humanity = 0
	var vars = GameState.ending_variables()
	t.expect_eq(int(vars.get("humanity", -1)), 0, "humanity is exposed to the ending logic")

	# Restore a sane baseline for other suites.
	GameState.humanity = 100
	Biblioteca.collected.clear()
	Locura.set_for(&"quixote", 45.0)
	Locura.set_for(&"sancho", 0.0)
