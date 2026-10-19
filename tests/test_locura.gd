extends RefCounted
## Madness thresholds (GDD.md §4.5) and the transfer mechanic DLC 3 is built on.

func suite(t: TestHarness) -> void:
	t.suite("Locura")

	t.test("thresholds map to the documented bands")
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.DISPLACED, "Quixote starts Displaced")
	Locura.set_for(&"quixote", 0.0)
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.LUCID, "0 is Lucid")
	Locura.set_for(&"quixote", 25.0)
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.LUCID, "25 is still Lucid")
	Locura.set_for(&"quixote", 26.0)
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.DISPLACED, "26 is Displaced")
	Locura.set_for(&"quixote", 51.0)
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.LOST, "51 is Lost")
	Locura.set_for(&"quixote", 76.0)
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.ABSORBED, "76 is Absorbed")
	Locura.set_for(&"quixote", 100.0)
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.ABSORBED, "100 is Absorbed")

	t.test("values are clamped to 0..100")
	Locura.set_for(&"quixote", 500.0)
	t.expect_almost_eq(Locura.get_for(&"quixote"), 100.0, 0.0001, "should clamp high")
	Locura.set_for(&"quixote", -50.0)
	t.expect_almost_eq(Locura.get_for(&"quixote"), 0.0, 0.0001, "should clamp low")

	t.test("Quixote loses Reality perception as he breaks")
	Locura.set_for(&"quixote", 0.0)
	t.expect_true(Locura.can_perceive_reality(&"quixote"), "Lucid Quixote sees Reality")
	Locura.set_for(&"quixote", 60.0)
	t.expect_false(Locura.can_perceive_reality(&"quixote"), "Lost Quixote does not")

	t.test("Sancho always sees Reality")
	Locura.set_for(&"sancho", 90.0)
	t.expect_true(Locura.can_perceive_reality(&"sancho"), "Sancho keeps Reality")
	Locura.set_for(&"sancho", 0.0)

	t.test("Book access opens above Displaced")
	Locura.set_for(&"quixote", 10.0)
	t.expect_false(Locura.has_book_access(&"quixote"), "Lucid has no Book access")
	Locura.set_for(&"quixote", 30.0)
	t.expect_true(Locura.has_book_access(&"quixote"), "Displaced has Book access")

	t.test("transfer moves madness between characters (DLC 3)")
	Locura.set_for(&"quixote", 60.0)
	Locura.set_for(&"sancho", 10.0)
	Locura.transfer(&"quixote", &"sancho", 25.0)
	t.expect_almost_eq(Locura.get_for(&"quixote"), 35.0, 0.001, "Quixote lost 25")
	t.expect_almost_eq(Locura.get_for(&"sancho"), 35.0, 0.001, "Sancho gained 25")

	t.test("save/load round-trips madness")
	var saved: Dictionary = Locura.save_state()
	Locura.set_for(&"quixote", 5.0)
	Locura.load_state(saved)
	t.expect_almost_eq(Locura.get_for(&"quixote"), 35.0, 0.001, "quixote restored")
	t.expect_almost_eq(Locura.get_for(&"sancho"), 35.0, 0.001, "sancho restored")
