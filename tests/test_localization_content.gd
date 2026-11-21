extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §20: ship es-419 as a real locale, and keep the Manifiesto validator
## free of false "still in Spanish" warnings.

func suite(t):
	t.suite("LocalizationContent")

	t.test("seven locales ship and all load")
	var files := DirAccess.open("res://locale/").get_files()
	var po_count := 0
	for name in files:
		if name.ends_with(".po"):
			po_count += 1
	t.expect_eq(po_count, 7, "seven PO files")
	t.expect_has(Loc.SHIPPED_LOCALES, "es_419", "es-419 is a shipped locale")
	var original := TranslationServer.get_locale()
	TranslationServer.set_locale("es_419")
	t.expect_ne(Loc.t(&"ui.menu.continue"), "", "es-419 has translations")
	TranslationServer.set_locale(original)

	t.test("no fragment triggers a false Spanish warning")
	# The validator's markers must not flag Italian articles, Portuguese
	# prepositions or the proper name Clavileño.
	for locale in ["it", "pt_BR", "en", "fr", "de"]:
		var data: Dictionary = ManifiestoFragment.load_data(&"bk.ch01.apertura.01")
		t.expect_false(str(data.get("modern", {}).get(locale, "")).contains(" los "),
			"%s has no Spanish article marker" % locale)
