extends Node
## Localization helper.
##
## Wraps TranslationServer so the rest of the game never calls it directly
## and so the "Codes" screen (in-game translation importer) has one place
## to hook into.
##
## KEY RULES (see TECH_STACK.md §7.2):
##   - Never use the source text as a key.
##   - Never concatenate translated fragments. Use a format string.
##   - The 1605 Book layer is NOT here — that is content, not translation.
##
## See GDD.md §20.

const FALLBACK := "es"

## Locales the game ships with. Keep in sync with locale/*.po and with
## ui.language.name.* keys.
const SHIPPED_LOCALES: Array[String] = [
	"es", "es_419", "en", "fr", "de", "pt_BR",
	"it", "pl", "ru", "tr", "ja", "ko", "zh_Hans",
]


func _ready() -> void:
	set_locale(_detect_system_locale())


## Map the OS locale onto a shipped locale.
## "es_ES" -> "es", "es_MX" -> "es_419", "pt_PT" -> "pt_BR", "en_GB" -> "en".
func _detect_system_locale() -> String:
	var raw := OS.get_locale().replace("-", "_")
	var parts := raw.split("_")
	var language := parts[0].to_lower()
	var country := parts[1].to_upper() if parts.size() > 1 else ""

	var candidate := language
	match language:
		"es":
			# Latin America is a first-class translation, not a copy (D7).
			candidate = "es_419" if country != "" and country != "ES" else "es"
		"pt":
			candidate = "pt_BR"
		"zh":
			candidate = "zh_Hans"

	return candidate if SHIPPED_LOCALES.has(candidate) else FALLBACK


func set_locale(locale: String) -> void:
	if not TranslationServer.get_translation_object(locale) and locale != FALLBACK:
		push_warning("[Loc] No translation loaded for '%s'; falling back to '%s'." % [locale, FALLBACK])
	TranslationServer.set_locale(locale)
	EventBus.settings_changed.emit()


func current_locale() -> String:
	return TranslationServer.get_locale()


## The public name of a locale, in its own language ("Español (España)").
func locale_display_name(locale: String) -> String:
	return tr(&"ui.language.name.%s" % locale)


## Translate a key.
func t(key: StringName) -> String:
	return tr(key)


## Translate a key and format it.
func tf(key: StringName, args: Array) -> String:
	return tr(key) % args


## True if the current locale reads right-to-left. Not shipped yet, but the
## UI is built to survive it (see TECH_STACK.md §7.5).
func is_rtl() -> bool:
	return TranslationServer.get_locale().ends_with("ar") or TranslationServer.get_locale().ends_with("he")


## The list of locales the player actually has installed (auto-translations
## from the "Codes" folder count).
func installed_locales() -> Array[String]:
	var found: Array[String] = []
	for locale: String in SHIPPED_LOCALES:
		if TranslationServer.get_translation_object(locale) != null:
			found.append(locale)
	return found
