extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The Lectura investigation mode.
##
## Q toggles Lectura mode. In this mode anamorphoses (hidden details on
## objects) become spottable, and resolving them collects evidence toward
## a Verdict (GDD.md §6, tasks 2.12-2.13).
##
## This suite pins the Lectura autoload: mode toggle, anamorphosis
## spotting/resolution, evidence counting, and the Verdict threshold.

func suite(t):
	t.suite("Lectura")

	t.test("Lectura starts inactive")
	t.expect_false(Lectura.is_active(), "no Lectura at the start")

	t.test("enter activates Lectura")
	Lectura.enter()
	t.expect_true(Lectura.is_active(), "Lectura is active after enter")
	Lectura.exit()

	t.test("exit deactivates Lectura")
	Lectura.exit()
	t.expect_false(Lectura.is_active(), "Lectura is inactive after exit")

	t.test("toggle switches state")
	t.expect_false(Lectura.is_active(), "starts inactive")
	Lectura.toggle()
	t.expect_true(Lectura.is_active(), "toggle turns it on")
	Lectura.toggle()
	t.expect_false(Lectura.is_active(), "toggle turns it off")

	t.test("spot marks an anamorphosis as spotted")
	t.expect_false(Lectura.is_spotted(&"rock_weight"), "not spotted yet")
	Lectura.spot(&"rock_weight")
	t.expect_true(Lectura.is_spotted(&"rock_weight"), "now spotted")
	t.expect_eq(Lectura.spotted_count(), 1, "one spotted")

	t.test("spot is idempotent")
	Lectura.spot(&"rock_weight")
	t.expect_eq(Lectura.spotted_count(), 1, "still one spotted")

	t.test("resolve marks an anamorphosis as resolved and grants evidence")
	t.expect_false(Lectura.is_resolved(&"rock_weight"), "not resolved yet")
	var gained = Lectura.resolve(&"rock_weight", 2)
	t.expect_eq(gained, 2, "granted 2 evidence")
	t.expect_true(Lectura.is_resolved(&"rock_weight"), "now resolved")
	t.expect_eq(Lectura.resolved_count(), 1, "one resolved")
	t.expect_eq(Lectura.total_evidence(), 2, "total evidence is 2")

	t.test("resolve is idempotent")
	gained = Lectura.resolve(&"rock_weight", 2)
	t.expect_eq(gained, 0, "already resolved, grants nothing")
	t.expect_eq(Lectura.total_evidence(), 2, "total evidence unchanged")

	t.test("evidence accumulates across anamorphoses")
	Lectura.resolve(&"windmill_sails", 1)
	Lectura.resolve(&"book_stand_pages", 1)
	t.expect_eq(Lectura.total_evidence(), 4, "2 + 1 + 1 = 4")
	t.expect_eq(Lectura.resolved_count(), 3, "three resolved")

	t.test("has_enough_for_verdict tracks the threshold")
	t.expect_true(Lectura.has_enough_for_verdict(), "4 >= 3, enough for verdict")

	t.test("default evidence per anamorphosis is 1")
	Lectura.spot(&"fresh_anamorphosis")
	var default_gained = Lectura.resolve(&"fresh_anamorphosis")
	t.expect_eq(default_gained, 1, "default evidence is 1")
	t.expect_eq(Lectura.total_evidence(), 5, "4 + 1 = 5")

	t.test("spotted count tracks all spotted")
	t.expect_eq(Lectura.spotted_count(), 4, "rock_weight, windmill_sails, book_stand_pages, fresh_anamorphosis")

	t.test("leave Lectura clean for other suites")
	Lectura.exit()
	t.expect_false(Lectura.is_active(), "Lectura exited for other suites")
