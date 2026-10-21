class_name ManifiestoFragment
extends RefCounted
## One fragment of the Manifiesto: a piece of the 1605 original, and the
## modern rendering of it.
##
## The fragments live in `assets/manifiesto/*.json`, one file per fragment,
## and they are CONTENT: the 1605 wording is the same in every build, in
## every language, because it is a quotation and not a translation. The
## *modern* rendering is localised, and lives in the fragment's own
## `modern` map (one entry per language).
##
## The Examine panel shows a fragment when the thing you are looking at
## carries a page of the book — a book in a rock, a book in the world.
## That is the seed of the Lectura system (GDD.md §6).
##
## NOTE: a file whose name starts with `_` is invisible to Godot and
## cannot be read at runtime (HANDOVER.md §7.14), so it cannot be
## checked either. The format is documented in the `_comment` of the
## first real fragment, where the validator can see it.

## Where the fragments live.
const DIRECTORY := "res://assets/manifiesto/"

## The field holding the 1605 original. It is content, never a key.
const ORIGINAL_FIELD := "original_1605"

## The field holding the modern renderings, one per language.
const MODERN_FIELD := "modern"

## The languages the fragments are rendered in. The Spanish ones are the
## first: GDD.md §20.1 puts the selection and the Spanish modernisations
## at month 12 and the other languages at month 18.
##
## The list itself is derived — see `shipped_languages()` — and this is
## the fallback for a build with no locale files at all.
const SHIPPED_LANGUAGES: Array[String] = ["es", "en", "fr"]

## The regional variant of the Spanish, which has its own rendering.
const SPANISH_VARIANT := "es_419"

## How many fragments the plan wants. GDD.md §20.1, locked by D7.
const PLANNED_COUNT := 48

## The 1615 wording, which must never appear under an `original_1605` key.
##
## The 1605 first part reads *"de los de lanza en astillero, adarga
## antigua, rocín flaco y galgo corredor"*. The 1615 revision replaces it
## with *"galera en corza y bacía en el casco"*. DLC 1 is the 1615 book,
## so a fragment taken from the wrong edition is a fragment from the
## wrong book — and the project's own sample fragment made exactly that
## mistake.
##
## Each entry is a set of words that have to appear TOGETHER.
const _1615_MARKERS: Array = [
	["galera", "corza"],
	["bacía", "casco"],
]

## A passage, not a sentence. Below this, it is probably a fragment of a
## fragment.
const MIN_PASSAGE_LENGTH := 40


## One thing wrong with a fragment.
class Problem extends RefCounted:
	var level: String  ## "ERROR" or "WARN"
	var code: String
	var message: String

	func _init(p_level: String, p_code: String, p_message: String) -> void:
		level = p_level
		code = p_code
		message = p_message

	func _to_string() -> String:
		return "[%s] %s: %s" % [level, code, message]


## Everything wrong with a fragment, in the order it matters.
##
## The rules are the format's own (the sample's rules 1–5) and the
## project's hard ones: the 1605 wording is content and never a key, the
## modern rendering is a rendition and not a simplification, and a
## fragment that nobody has checked against the edition must not ship.
static func validate(data: Dictionary, file_base: String) -> Array:
	var problems: Array = []

	# ── Identity ──────────────────────────────────────────────────────
	var id := str(data.get("id", ""))
	if id.is_empty():
		problems.append(Problem.new("ERROR", "no-id", "the fragment has no id"))
	elif not id.begins_with(file_base):
		problems.append(Problem.new("ERROR", "id-mismatch",
			"the id '%s' does not match the file name '%s'" % [id, file_base]))

	if not _is_int(data.get("chapter")):
		problems.append(Problem.new("ERROR", "no-chapter", "the fragment has no chapter"))
	if not _is_int(data.get("part")):
		problems.append(Problem.new("ERROR", "no-part", "the fragment has no part"))

	# ── The title ──────────────────────────────────────────────────────
	var title_key := str(data.get("title_key", ""))
	if title_key.is_empty():
		problems.append(Problem.new("ERROR", "no-title-key", "the fragment has no title_key"))
	elif not template_keys().has(title_key):
		problems.append(Problem.new("ERROR", "title-key-missing",
			"the title key '%s' is not in locale/messages.pot" % title_key))

	# ── The original ───────────────────────────────────────────────────
	var original := str(data.get(ORIGINAL_FIELD, ""))
	if original.is_empty():
		problems.append(Problem.new("ERROR", "no-original",
			"the fragment has no %s" % ORIGINAL_FIELD))
	else:
		if original.length() < MIN_PASSAGE_LENGTH:
			problems.append(Problem.new("WARN", "short-original",
				"the original is %d characters — is it a passage?" % original.length()))
		var lower := original.to_lower()
		for marker in _1615_MARKERS:
			if _contains_all(lower, marker):
				problems.append(Problem.new("ERROR", "edition-1615",
					"the original carries the 1615 wording ('%s') — DLC 1 is the 1615 book, and this is a fragment from the wrong one" % " ".join(PackedStringArray(marker))))
		if original.begins_with("bk."):
			problems.append(Problem.new("ERROR", "original-is-a-key",
				"the original looks like a translation key, and it is content"))

	# ── The modern renderings ──────────────────────────────────────────
	var modern: Dictionary = data.get(MODERN_FIELD, {})
	if not data.has(MODERN_FIELD):
		problems.append(Problem.new("ERROR", "no-modern", "the fragment has no modern renderings"))
	elif not data[MODERN_FIELD] is Dictionary:
		problems.append(Problem.new("ERROR", "no-modern", "the modern field is not an object"))
	else:
		for language: String in shipped_languages():
			if not modern.has(language) or str(modern[language]).strip_edges().is_empty():
				var severity := "ERROR" if language == "es" else "WARN"
				problems.append(Problem.new(severity, "no-modern-%s" % language,
					"no modern rendering for '%s'" % language))
				continue
			var rendered := str(modern[language]).strip_edges()
			if language != "es" and language != SPANISH_VARIANT and rendered == original.strip_edges():
				problems.append(Problem.new("ERROR", "untranslated-%s" % language,
					"the modern rendering for '%s' is the Spanish original" % language))
			elif language != "es" and language != SPANISH_VARIANT and _looks_spanish(rendered):
				problems.append(Problem.new("WARN", "spanish-%s" % language,
					"the modern rendering for '%s' is still in Spanish" % language))
		if not modern.has(SPANISH_VARIANT):
			problems.append(Problem.new("WARN", "no-modern-%s" % SPANISH_VARIANT,
				"no modern rendering for the Latin American Spanish ('%s')" % SPANISH_VARIANT))

	# ── The provenance ─────────────────────────────────────────────────
	var source: Dictionary = data.get("source", {})
	if not data.has("source"):
		problems.append(Problem.new("ERROR", "no-source", "the fragment has no provenance"))
	else:
		for field: String in ["work", "edition", "url"]:
			if str(source.get(field, "")).strip_edges().is_empty():
				problems.append(Problem.new("ERROR", "no-source-%s" % field,
					"the provenance has no %s" % field))
		if not bool(source.get("public_domain", false)):
			problems.append(Problem.new("ERROR", "not-public-domain",
				"the provenance does not say the source is in the public domain"))
		if not bool(source.get("verified", false)):
			problems.append(Problem.new("WARN", "unverified",
				"nobody has checked this against the edition — it must not ship"))
		elif str(source.get("verified_on", "")).strip_edges().is_empty():
			problems.append(Problem.new("WARN", "no-verified-on",
				"the fragment is verified but nobody wrote down when"))

	# ── The rest of the shape ──────────────────────────────────────────
	var variants: Dictionary = data.get("variants", {})
	for variant: String in ["reality", "book"]:
		if str(variants.get(variant, "")).strip_edges().is_empty():
			problems.append(Problem.new("WARN", "no-variant-%s" % variant,
				"the fragment has no '%s' variant" % variant))
	if not data.has("unlocks"):
		problems.append(Problem.new("WARN", "no-unlocks", "the fragment grants nothing"))
	elif not (data["unlocks"] as Dictionary).get("give", []) is Array:
		problems.append(Problem.new("WARN", "no-unlocks", "the fragment's 'give' list is not a list"))
	if not data.has("characters"):
		problems.append(Problem.new("WARN", "no-characters", "the fragment says who is in it"))
	if data.has("pd_translations"):
		for language: String in (data["pd_translations"] as Dictionary).keys():
			for entry: Dictionary in (data["pd_translations"] as Dictionary)[language]:
				for field: String in ["translator", "year", "text"]:
					if str(entry.get(field, "")).strip_edges().is_empty():
						problems.append(Problem.new("WARN", "incomplete-pd-%s" % language,
							"a public-domain translation for '%s' has no %s" % [language, field]))

	return problems


## The keys in the locale template.
##
## A fragment's title has to be a key that exists, or the title renders
## as a raw key string in the game.
static func template_keys() -> Dictionary:
	var keys := {}
	var path := "res://locale/messages.pot"
	if not FileAccess.file_exists(path):
		return keys
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return keys
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("msgid "):
			var key := line.substr(7).strip_edges().trim_prefix("\"").trim_suffix("\"")
			if not key.is_empty():
				keys[key] = true
	file.close()
	return keys


## The fragment files that are really fragments.
##
## A file whose name starts with `_` is invisible to Godot (HANDOVER.md
## §7.14), so the sample cannot be read here and cannot be checked
## here. The sample's own 1615 bug is the owner's to decide on.
static func fragment_files() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(DIRECTORY)
	if dir == null:
		return out
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		if file_name.begins_with("_"):
			continue
		out.append(file_name)
	out.sort()
	return out


## The fragment files the build actually reads.
##
## The page turn prints a line of the 1605 original, and the path is
## written into the code. This is how a validator knows which fragments
## are shipping, and therefore which ones may not be unverified.
static func referenced_files() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open("res://src")
	if dir == null:
		return out
	for path: String in _all_scripts(dir):
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		while not file.eof_reached():
			var line := file.get_line()
			var at := line.find("assets/manifiesto/")
			if at < 0:
				continue
			var rest := line.substr(at + "assets/manifiesto/".length())
			var name := rest.get_slice("\"", 0).get_slice("'", 0)
			if name.ends_with(".json") and not name.is_empty():
				out.append(name)
		file.close()
	var unique: Array[String] = []
	for name in out:
		if not unique.has(name):
			unique.append(name)
	unique.sort()
	return unique


## The languages the game can actually show.
##
## The languages that have a locale file, and the regional variant of
## the Spanish. It is derived rather than written down, so the worklist
## grows by itself as the languages do: GDD.md §20.1 puts the Spanish
## modernisations at month 12 and the other five launch languages at
## month 18, and a fragment that has no rendering for a language the game
## cannot show is not missing anything yet.
static func shipped_languages() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open("res://locale/")
	if dir != null:
		for file_name: String in dir.get_files():
			if not file_name.ends_with(".po"):
				continue
			var language := file_name.get_basename()
			if not out.has(language):
				out.append(language)
	out.sort()
	return out


## Every script under a directory.
static func _all_scripts(dir: DirAccess, prefix: String = "res://src/") -> Array[String]:
	var out: Array[String] = []
	for name: String in dir.get_files():
		if name.ends_with(".gd"):
			out.append(prefix + name)
	for sub: String in dir.get_directories():
		var child := DirAccess.open(prefix + sub)
		if child != null:
			out.append_array(_all_scripts(child, prefix + sub + "/"))
	return out


## Does this text still look like Spanish?
##
## A rendering that was never translated is the failure the GDD warns
## about: *"a generic AI translation would ruin the product"*. A copy of
## the Spanish left in the English slot is the same mistake, and it is
## easy to see.
##
## The markers are the ones no English or French sentence has. " de la "
## is NOT one of them: "de la Manche" is French, and a check that
## flagged it would be a check nobody trusts.
static func _looks_spanish(text: String) -> bool:
	for marker: String in ["ñ", "¿", "¡", " los ", " las ", " una ", " del ", " para "]:
		if text.contains(marker):
			return true
	return false


## Is this a whole number?
##
## Godot's JSON parser hands back every number as a float, so a JSON
## `1` arrives as 1.0 and a check for TYPE_INT would call every
## chapter missing.
static func _is_int(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		return is_equal_approx(value, round(value))
	return false


## Does a text hold every one of these words?
static func _contains_all(text: String, words: Array) -> bool:
	for word in words:
		if not text.contains(str(word)):
			return false
	return true


## The path of a fragment's file, by id.
static func path_for(id: StringName) -> String:
	return DIRECTORY + String(id) + ".json"


## The whole fragment, as a dictionary. Empty if it cannot be read.
static func load_data(id: StringName) -> Dictionary:
	if id.is_empty():
		return {}
	var path := path_for(id)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## The text to show for a fragment.
##
## The modern rendering if the language has one, and the 1605 original if
## it does not — because the original is content, and content is shown as
## it is, in every language. A player whose language has no modern
## rendering reads the 1605 Spanish, exactly as the page turn does.
static func text_for(id: StringName, locale: String = "") -> String:
	var data := load_data(id)
	if data.is_empty():
		return ""
	var modern: Dictionary = data.get(MODERN_FIELD, {})
	if not modern.is_empty():
		# TranslationServer, and not the Loc autoload: this class is also
		# used by the headless tools, and an autoload does not exist in a
		# `--script` run.
		var language := locale if not locale.is_empty() else TranslationServer.get_locale()
		var rendered: Variant = modern.get(language, null)
		if rendered == null:
			# A regional variant falls back to its language.
			var base := language.split("_")[0]
			rendered = modern.get(base, null)
		if rendered != null:
			return str(rendered)
	return str(data.get(ORIGINAL_FIELD, ""))


## The title of the fragment, as a translation key. Empty if it has none.
static func title_key_for(id: StringName) -> StringName:
	var data := load_data(id)
	if data.is_empty():
		return &""
	return StringName(str(data.get("title_key", "")))
