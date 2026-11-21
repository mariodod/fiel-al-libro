extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §7.3: death does not respawn at the checkpoint; a Manuscrito page is
## written at the death site (the "unwritten page"). GDD §8.1: milestones are
## new verbs, not stat picks.

func suite(t):
	t.suite("ProgressionGaps")

	var old_pages := GameState.pages_written.duplicate()
	var old_recuerdos := Memoria.get_for(&"sancho")
	var old_milestone := Memoria.milestone_for(&"sancho")

	t.test("a death writes a page into the manuscript")
	GameState.pages_written.clear()
	var lines: Array = []
	var on_page := func(_id: StringName, line: String): lines.append(line)
	EventBus.manuscript_page_written.connect(on_page)
	GameState.write_page(&"death.probe.01", "He fell here.")
	t.expect_true(GameState.pages_written.has(&"death.probe.01"), "page recorded")
	t.expect_eq(lines.size(), 1, "the page was announced")
	GameState.write_page(&"death.probe.01", "Again.")
	t.expect_eq(lines.size(), 1, "a page is written once")
	EventBus.manuscript_page_written.disconnect(on_page)

	t.test("death prose keys exist in all shipped locales")
	for i in range(1, 7):
		t.expect_false(Loc.t(StringName("ui.death.page.%02d" % i)).is_empty(),
			"death page %d has prose" % i)

	t.test("milestones gate the signature verbs")
	Memoria._recuerdos[&"sancho"] = 0
	Memoria._milestones[&"sancho"] = 0
	var heavy: AbilityData = load("res://src/data/abilities/heavy_attack.tres")
	var desvelar: AbilityData = load("res://src/data/abilities/desvelar.tres")
	t.expect_eq(heavy.min_milestone, 1, "heavy attack unlocks at milestone 1")
	t.expect_eq(desvelar.min_milestone, 2, "Desvelar unlocks at milestone 2")
	t.expect_false(Memoria.has_milestone(&"sancho", 2), "not unlocked yet")
	Memoria.gain(&"sancho", 2, false)
	t.expect_true(Memoria.has_milestone(&"sancho", 2), "two memories unlock Desvelar")

	GameState.pages_written = old_pages
	Memoria._recuerdos[&"sancho"] = old_recuerdos
	Memoria._milestones[&"sancho"] = old_milestone
