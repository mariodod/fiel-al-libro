extends RefCounted
## The translations must actually resolve at runtime.
##
## This suite exists because of a real bug: Godot imports locale/*.po into
## Translation resources perfectly, but the engine does not load them into
## TranslationServer unless they are listed in
## ProjectSettings > Localization > Translations. Without that list every
## `tr()` call returns the raw key, and nothing errors — the game just
## quietly shows "ui.menu.new_game" instead of "Begin the manuscript".
##
## See src/tools/setup_translations.gd.


func suite(t: TestHarness) -> void:
	t.suite("Translations")

	t.test("translations are registered with the engine")
	var registered: Array = []
	var setting: Variant = ProjectSettings.get_setting("internationalization/locale/translations", [])
	if setting is Array:
		registered = setting
	elif setting is PackedStringArray:
		registered = Array(setting)
	t.expect_gt(float(registered.size()), 0.0, "project.godot should list the locale files")
	t.expect_has(registered, "res://locale/es.po", "Spanish is registered")
	t.expect_has(registered, "res://locale/en.po", "English is registered")
	t.expect_has(registered, "res://locale/fr.po", "French is registered")

	t.test("the fallback locale is set")
	t.expect_eq(ProjectSettings.get_setting("internationalization/locale/fallback", ""), "es", "fallback is Spanish")

	t.test("each locale returns its own text")
	var original := TranslationServer.get_locale()

	TranslationServer.set_locale("es")
	t.expect_eq(tr(&"ui.menu.new_game"), "Empezar el manuscrito", "Spanish")

	TranslationServer.set_locale("en")
	t.expect_eq(tr(&"ui.menu.new_game"), "Begin the manuscript", "English")

	TranslationServer.set_locale("fr")
	t.expect_eq(tr(&"ui.menu.new_game"), "Commencer le manuscrit", "French")

	t.test("an unshipped locale falls back to Spanish")
	TranslationServer.set_locale("de")
	t.expect_eq(tr(&"ui.menu.new_game"), "Empezar el manuscrito", "German is not shipped, so Spanish is used")

	t.test("contexts are expressed in the key name")
	# Godot 4.7 cannot translate a msgctxt entry (it creates the key but
	# leaves the value empty), so the project puts the context in the key.
	TranslationServer.set_locale("en")
	t.expect_eq(tr(&"ui.word.page.book"), "page", "the book page key resolves")
	t.expect_eq(tr(&"ui.word.page.nav"), "page", "the navigation page key resolves")
	t.expect_eq(tr(&"character.quixote"), "Don Quixote", "the character key resolves")
	t.expect_eq(tr(&"character.sancho"), "Sancho", "the character key resolves")

	t.test("plurals resolve through the explicit plural key")
	# Godot has no ngettext, so the plural form is its own key.
	TranslationServer.set_locale("en")
	t.expect_eq(Loc.tp(&"ui.shelf.count", 1), "1 book on the shelf", "singular")
	t.expect_eq(Loc.tp(&"ui.shelf.count", 4), "4 books on the shelf", "plural")
	t.expect_eq(Loc.tp(&"ui.shelf.count", 0), "0 books on the shelf", "zero is plural in English")

	t.test("every shipped locale has the same key count")
	var counts := {}
	for locale: String in ["es", "en", "fr"]:
		var res: Resource = ResourceLoader.load("res://locale/%s.po" % locale, "Translation", ResourceLoader.CACHE_MODE_IGNORE)
		t.expect_true(res != null, "%s.po should load as a Translation" % locale)
		if res != null:
			counts[locale] = (res as Translation).get_message_count()
	t.expect_eq(int(counts.get("es", 0)), int(counts.get("en", 0)), "es and en have the same key count")
	t.expect_eq(int(counts.get("es", 0)), int(counts.get("fr", 0)), "es and fr have the same key count")

	TranslationServer.set_locale(original)
