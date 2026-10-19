extends RefCounted
## The reading rule: the world has one truth, the characters make two things
## of it. GDD.md §4.2.
##
## This is the rule the whole game rests on, so it is worth pinning down
## exactly — especially the two cases that are easy to get wrong:
##
##   - a mad Quixote does not see Reality even when the world is Reality;
##   - a Sancho without the second sight does not see the Book even when
##     the world is Book.

func suite(t: TestHarness) -> void:
	t.suite("Perception")

	# Remember where the madness was, and put it back at the end.
	var quixote_madness := Locura.get_for(&"quixote")

	t.test("a character's affinity is what they are made of")
	t.expect_eq(Perception.affinity_for(&"quixote"), Perception.BOOK, "Quixote is made of the Book")
	t.expect_eq(Perception.affinity_for(&"sancho"), Perception.REALITY, "Sancho is made of Reality")

	t.test("a Lucid Quixote reads a Reality world as Reality")
	Locura.set_for(&"quixote", 10.0)
	t.expect_eq(Perception.reading_for(&"quixote", Perception.REALITY), Perception.REALITY, "lucid Quixote sees reality")

	t.test("a Lucid Quixote reads a Book world as the Book")
	Locura.set_for(&"quixote", 10.0)
	t.expect_eq(Perception.reading_for(&"quixote", Perception.BOOK), Perception.BOOK, "the Book is all he ever sees")

	t.test("a mad Quixote stops reading Reality even when the world is Reality")
	# The GDD: at high madness he misses Reality entirely, and the world
	# starts agreeing with him. The truth toggle stops mattering to him.
	Locura.set_for(&"quixote", 60.0)
	t.expect_eq(Perception.reading_for(&"quixote", Perception.REALITY), Perception.BOOK, "madness overrides the world")

	t.test("Sancho reads Reality")
	t.expect_eq(Perception.reading_for(&"sancho", Perception.REALITY), Perception.REALITY, "Sancho sees reality")

	t.test("Sancho does not read the Book without the second sight")
	t.expect_eq(Perception.reading_for(&"sancho", Perception.BOOK), Perception.REALITY, "no second sight, no Book")

	t.test("the second sight lets Sancho read the Book")
	t.expect_eq(Perception.reading_for(&"sancho", Perception.BOOK, true), Perception.BOOK, "with the lens he sees it")

	t.test("the second sight does not change what Sancho reads in Reality")
	t.expect_eq(Perception.reading_for(&"sancho", Perception.REALITY, true), Perception.REALITY, "reality is still reality")

	t.test("can_perceive agrees with reading_for")
	Locura.set_for(&"quixote", 10.0)
	t.expect_true(Perception.can_perceive(&"quixote", Perception.BOOK), "Quixote can always see the Book")
	t.expect_true(Perception.can_perceive(&"quixote", Perception.REALITY), "a lucid Quixote can see Reality")
	t.expect_false(Perception.can_perceive(&"sancho", Perception.BOOK), "Sancho cannot see the Book unaided")
	t.expect_true(Perception.can_perceive(&"sancho", Perception.BOOK, true), "but he can with the lens")

	# Leave the madness where we found it, for the next suite.
	Locura.set_for(&"quixote", quixote_madness)
