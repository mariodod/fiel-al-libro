extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The colophon: original game writing, authored by the manuscript, between chapters.

const SCENE = "res://src/world/colophon.tscn"
const REGIONS = [
	"prologo", "camino_la_mancha", "sierra_morena", "el_toboso",
	"los_riscos", "el_castillo_del_duque",
]


func suite(t):
	t.suite("Colophon")

	t.test("every colophon passage is translated in all six locales")
	for locale in ["en", "es", "fr", "de", "it", "pt_BR"]:
		var text := FileAccess.get_file_as_string("res://locale/%s.po" % locale)
		for region in REGIONS:
			for truth in ["book", "reality"]:
				var key := "ui.colofon.%s.%s" % [region, truth]
				t.expect_true(text.contains('msgid "%s"' % key),
					"%s has %s" % [locale, key])
				# The value must not be an empty msgstr.
				var marker := 'msgid "%s"\nmsgstr "' % key
				var at := text.find(marker)
				if at >= 0:
					var tail := text.substr(at + marker.length(), 80)
					t.expect_false(tail.begins_with('"'),
						"%s translates %s" % [locale, key])

	t.test("the colophon page shows the truth's own voice")
	var packed := load(SCENE) as PackedScene
	t.expect_true(packed != null, "colophon scene loads")
	if packed == null:
		return

	var original := TruthLayer.is_book()
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	var page := packed.instantiate()
	page._ready()  # resolve @onready nodes without a tree in the harness
	page.show_colophon(&"sierra_morena", 0.0)
	var reality_text: String = (page.get_node("Panel/Text") as Label).text
	t.expect_true(reality_text.length() > 40, "Reality colophon has prose")
	t.expect_false(reality_text == "ui.colofon.sierra_morena.reality",
		"the key resolved to a translation")

	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	page.show_colophon(&"sierra_morena", 0.0)
	var book_text: String = (page.get_node("Panel/Text") as Label).text
	t.expect_true(book_text.length() > 40, "Book colophon has prose")
	t.expect_false(book_text == reality_text, "the two truths read differently")

	TruthLayer.shift_to(TruthLayer.Layer.BOOK if original else TruthLayer.Layer.REALITY, true)
	page.free()

	t.test("the ride flow shows a colophon for the completed region")
	var region: StringName = RegionGraph.get_chapter(RegionGraph.start_chapter).get("region_id", &"")
	t.expect_false(region.is_empty(), "the first chapter has a region for its colophon")
	t.expect_true(FileAccess.file_exists(SCENE), "the colophon scene exists")
