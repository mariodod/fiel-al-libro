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
## cannot be read at runtime (HANDOVER.md §7.14). The sample fragment is
## documentation; the first real one is `bk.ch01.apertura.json`.

## Where the fragments live.
const DIRECTORY := "res://assets/manifiesto/"

## The field holding the 1605 original. It is content, never a key.
const ORIGINAL_FIELD := "original_1605"

## The field holding the modern renderings, one per language.
const MODERN_FIELD := "modern"


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
		var language := locale if not locale.is_empty() else Loc.current_locale()
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
