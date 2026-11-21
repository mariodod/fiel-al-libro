extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Book objects carry Manifiesto ids (bk.ch14.galeotes) but their reaction
## barks are authored under short slugs (galeotes). The normalisation must
## produce a key that has both locale text and a WAV on disk.

func suite(t):
	t.suite("ReactionBarks")

	t.test("fragment ids map to the short slug used by bark files")
	var cases := {
		&"bk.ch14.galeotes": &"galeotes",
		&"bk.ch01.molinos.01": &"molinos",
		&"bk.ch12.armas_letras": &"armas_letras",
		&"bk.ch01.leyenda_tio_andalus": &"leyenda",
		&"bk.ch03.posada": &"posada",
	}
	for id in cases.keys():
		t.expect_eq(Reaction.slug_for(id), cases[id], "%s -> %s" % [id, cases[id]])
	t.expect_eq(Reaction.slug_for(&"rock"), &"rock", "primitive ids pass through")
	t.expect_eq(Reaction.slug_for(&"innkeeper"), &"innkeeper", "NPC ids pass through")

	t.test("reaction keys from book objects have translated text")
	var objects: Array[StringName] = [
		&"bk.ch14.galeotes", &"bk.ch01.molinos.01", &"bk.ch11.caballero_bosque",
		&"bk.ch12.armas_letras", &"bk.ch13.leones", &"bk.ch03.posada",
	]
	var original_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	for object_id in objects:
		for layer in [Perception.BOOK, Perception.REALITY]:
			var key := Reaction.bark_key(&"quixote", object_id, layer)
			var text := Loc.t(key)
			t.expect_ne(text, str(key), "%s resolves to text" % key)
			t.expect_false(text.is_empty(), "%s is not empty" % key)
			# Sancho has his own authored line for the same thing.
			var sancho_key := Reaction.bark_key(&"sancho", object_id, layer)
			t.expect_ne(Loc.t(sancho_key), str(sancho_key),
				"%s resolves to text" % sancho_key)
	TranslationServer.set_locale(original_locale)

	t.test("reaction keys have a matching WAV for both characters")
	for object_id in objects:
		for layer in [Perception.BOOK, Perception.REALITY]:
			var slug := str(Reaction.slug_for(object_id))
			var direction := "book" if layer == Perception.BOOK else "reality"
			for character in ["quixote", "sancho"]:
				var path := "res://assets/audio/barks/%s/reaction.%s.%s.wav" % [
					character, slug, direction]
				t.expect_true(FileAccess.file_exists(path), path)
