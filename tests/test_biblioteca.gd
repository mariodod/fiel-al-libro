extends RefCounted
## The shelf: five books, and your loadout IS your collection.

func suite(t: TestHarness) -> void:
	t.suite("Biblioteca")

	# Start from a clean shelf.
	Biblioteca.collected.clear()
	Biblioteca.equipped.clear()

	t.test("collecting a book records it and auto-equips it")
	Biblioteca.collect(&"tio_andalus")
	t.expect_true(Biblioteca.has_book(&"tio_andalus"), "book should be collected")
	t.expect_has(Biblioteca.equipped, &"tio_andalus", "book should be auto-equipped")

	t.test("collecting the same book twice does nothing")
	var count := Biblioteca.collected_count()
	Biblioteca.collect(&"tio_andalus")
	t.expect_eq(Biblioteca.collected_count(), count, "no duplicates")

	t.test("the shelf holds five books")
	for id: StringName in [&"cid", &"pelayo", &"gatos", &"silos", &"celestina", &"lazarillo"]:
		Biblioteca.collect(id)
	t.expect_eq(Biblioteca.equipped.size(), Biblioteca.SHELF_SIZE, "shelf should be exactly full")
	t.expect_eq(Biblioteca.equipped.size(), 5, "shelf size is five")

	t.test("equipping past the shelf evicts the oldest")
	var evicted: StringName = Biblioteca.equipped[0]
	Biblioteca.collect(&"tirant")
	Biblioteca.equip(&"tirant")
	t.expect_not_has(Biblioteca.equipped, evicted, "oldest book should be evicted")
	t.expect_has(Biblioteca.equipped, &"tirant", "new book equipped")

	t.test("a book is never equipped twice")
	Biblioteca.equip(&"tirant")
	t.expect_eq(Biblioteca.equipped.count(&"tirant"), 1, "no duplicates on the shelf")

	t.test("unequip removes a book")
	Biblioteca.unequip(&"tirant")
	t.expect_not_has(Biblioteca.equipped, &"tirant", "book removed from shelf")

	t.test("save/load round-trips the shelf")
	var saved: Dictionary = Biblioteca.save_state()
	var collected_before := Biblioteca.collected_count()
	var equipped_before := Biblioteca.equipped.duplicate()
	Biblioteca.collected.clear()
	Biblioteca.equipped.clear()
	Biblioteca.load_state(saved)
	t.expect_eq(Biblioteca.collected_count(), collected_before, "collection restored")
	t.expect_eq(Biblioteca.equipped, equipped_before, "shelf restored")
	# "tio_andalus" was evicted by the eviction test above, so assert on a
	# book that is actually on the shelf.
	t.expect_has(Biblioteca.equipped, &"cid", "a shelf book is restored")
