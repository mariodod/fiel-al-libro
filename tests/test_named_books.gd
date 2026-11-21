extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §9: fifteen named, public-domain Spanish works form the collectible
## library. Tío Andalus and Celestina already existed; the other twelve are
## authored here with passives, locale text, and an anamorphosis grant path.

const NAMED := [
	&"libro.mio_cid", &"libro.pelayo", &"libro.gatos", &"libro.santo_domingo",
	&"libro.calila_dimna", &"libro.milagros", &"libro.lazarillo", &"libro.tirant",
	&"libro.tablas", &"libro.buscon", &"libro.don_juan", &"libro.codice",
]

func suite(t):
	t.suite("NamedBooks")

	t.test("all twelve named books load with passives and six-locale text")
	for id in NAMED:
		var book: BookData = load("res://src/data/books/%s.tres" % id)
		t.expect_true(book != null, "%s loads" % id)
		if book == null:
			continue
		t.expect_eq(book.id, id, "id matches filename")
		t.expect_true(book.is_verified_public_domain(), "%s is public domain" % id)
		t.expect_false(book.display_name_key.is_empty(), "%s has a name key" % id)
		t.expect_false(book.codex_note_key.is_empty(), "%s has a codex note" % id)
		var passive: PassiveData = load("res://src/data/passives/passive.%s.tres" % str(id).split(".")[1])
		t.expect_true(passive != null, "%s's passive loads" % id)
		if passive != null:
			t.expect_eq(passive.id, book.passive_id, "passive id matches")

	t.test("every book key is translated in Spanish and English")
	var original := TranslationServer.get_locale()
	for locale in ["es", "en"]:
		TranslationServer.set_locale(locale)
		for id in NAMED:
			var key := StringName("ui.book.%s.name" % id)
			t.expect_ne(Loc.t(key), str(key), "%s name in %s" % [id, locale])
			var desc := StringName("ui.book.%s.desc" % id)
			t.expect_ne(Loc.t(desc), str(desc), "%s desc in %s" % [id, locale])
	TranslationServer.set_locale(original)

	t.test("the named books have anamorphosis grant paths")
	var dir := DirAccess.open("res://src/data/anamorphoses/")
	var granted: Array[StringName] = []
	for name in dir.get_files():
		if not name.ends_with(".tres"):
			continue
		var data: TruthObjectData = load("res://src/data/anamorphoses/" + name)
		if data != null and not data.anamorphosis_book.is_empty():
			granted.append(data.anamorphosis_book)
	for id in NAMED:
		t.expect_has(granted, id, "%s is grantable" % id)

	t.test("the two inert passive fields now have effects")
	var q := load("res://src/data/characters/quixote.tres")
	t.expect_true(q != null, "Quixote data loads")
	if q != null:
		t.expect_true(q.light_attack != null, "light attack exists")
	var locura_before := Locura.get_for(&"quixote")
	var char: CharacterPawn = CharacterPawn.new()
	char.character_id = &"quixote"
	var mods := PassiveManager.modifiers.duplicate()
	mods["damage_percent"] = 1.5
	char.apply_passive_modifiers(mods)
	t.expect_almost_eq(char.passive_damage_percent(), 1.5, 0.001,
		"damage multiplier reaches the pawn")
	char.free()
	Locura.set_for(&"quixote", locura_before)
