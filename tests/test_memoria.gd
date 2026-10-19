extends RefCounted
## Progression: milestones are verbs, and reading is worth double.

func suite(t: TestHarness) -> void:
	t.suite("Memoria")

	t.test("milestones unlock in order")
	Memoria.gain(&"quixote", 1, false)
	t.expect_eq(Memoria.milestone_for(&"quixote"), 1, "one memory unlocks the first milestone")

	t.test("reading is worth double")
	Memoria.gain(&"quixote", 10, false)
	var before := Memoria.get_for(&"quixote")
	Memoria.gain(&"quixote", 10, true)
	t.expect_eq(Memoria.get_for(&"quixote") - before, 20, "reading doubles the reward")

	t.test("milestone costs escalate")
	# 1 + 10 + 20 (reading) = 31 memories total so far.
	# Costs are 1,2,3,4,6,8,11,15 -> cumulative 1,3,6,10,16,24,35,50.
	Memoria.gain(&"quixote", 100, false)
	t.expect_eq(Memoria.milestone_for(&"quixote"), Memoria.MILESTONES_PER_CHARACTER, "should reach max milestones")

	t.test("characters track progress independently")
	Memoria.gain(&"sancho", 1, false)
	t.expect_eq(Memoria.milestone_for(&"sancho"), 1, "Sancho has his own track")

	t.test("save/load round-trips")
	var saved: Dictionary = Memoria.save_state()
	var q_before := Memoria.get_for(&"quixote")
	Memoria.gain(&"quixote", 5, false)
	Memoria.load_state(saved)
	t.expect_eq(Memoria.get_for(&"quixote"), q_before, "memories restored")
