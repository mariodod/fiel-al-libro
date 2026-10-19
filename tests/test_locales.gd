extends RefCounted
## Every locale must carry the same keys.
##
## The most common i18n bug in a small project is a locale that silently
## drifts: a key added to en.po and forgotten in fr.po ships as an English
## string in a French build. This suite catches that before it ships.
##
## The same check exists as tools/check_locales.py for running outside
## Godot; keep the two in sync.

const LOCALE_DIR := "res://locale/"
const TEMPLATE := "res://locale/messages.pot"


func suite(t: TestHarness) -> void:
	t.suite("Locales")

	t.test("the template exists")
	t.expect_true(FileAccess.file_exists(TEMPLATE), "messages.pot should exist")

	if not FileAccess.file_exists(TEMPLATE):
		return

	var template_keys := _parse_po(TEMPLATE)
	t.expect_gt(float(template_keys.size()), 20.0, "the template should define a real set of keys")

	var locale_files := _locale_files()
	t.expect_gt(float(locale_files.size()), 0.0, "there should be at least one locale")

	for path: String in locale_files:
		var name := path.get_file()
		var keys := _parse_po(path)

		t.test("%s has the same keys as the template" % name)
		var missing: Array[String] = []
		for key: String in template_keys:
			if not keys.has(key):
				missing.append(key)
		t.expect_eq(missing.size(), 0, "%s is missing %d key(s): %s" % [name, missing.size(), ", ".join(missing.slice(0, 5))])

		var extra: Array[String] = []
		for key: String in keys:
			if not template_keys.has(key):
				extra.append(key)
		t.expect_eq(extra.size(), 0, "%s has %d key(s) not in the template: %s" % [name, extra.size(), ", ".join(extra.slice(0, 5))])

	t.test("every locale has at least one translated string")
	for path: String in locale_files:
		var translated := _translated_count(path)
		t.expect_gt(float(translated), 0.0, "%s should have translated strings" % path.get_file())


func _locale_files() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(LOCALE_DIR)
	if dir == null:
		return out
	for file_name: String in dir.get_files():
		if file_name.ends_with(".po"):
			out.append(LOCALE_DIR + file_name)
	out.sort()
	return out


## Parse a PO file into a set of keys.
## Handles msgid, msgid_plural and multi-line continuation strings.
func _parse_po(path: String) -> Array[String]:
	var keys: Array[String] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return keys

	var current := ""
	var in_msgid := false
	var in_plural := false

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.begins_with("msgid_plural "):
			current = line.substr("msgid_plural ".length()).strip_edges()
			in_plural = true
			in_msgid = false
			keys.append(current)
			continue
		if line.begins_with("msgid "):
			current = line.substr("msgid ".length()).strip_edges()
			in_msgid = true
			in_plural = false
			if not current.is_empty():
				keys.append(current)
			continue
		if line.begins_with("msgctxt "):
			in_msgid = false
			in_plural = false
			continue
		if line.begins_with("msgstr"):
			in_msgid = false
			in_plural = false
			continue
		# Continuation of a multi-line msgid.
		if line.begins_with("\"") and (in_msgid or in_plural):
			var part := line.substr(1).strip_edges().trim_suffix("\"").strip_edges()
			if not part.is_empty():
				keys.append(part)
			continue

	file.close()
	return keys


## Count the msgstr entries that are not empty (i.e. actually translated).
func _translated_count(path: String) -> int:
	var count := 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var in_msgstr := false
	var buffer := ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("msgstr"):
			in_msgstr = true
			buffer = ""
			continue
		if line.begins_with("msgid") or line.begins_with("msgctxt"):
			if in_msgstr and not buffer.strip_edges().is_empty() and buffer.strip_edges() != "\"\"":
				count += 1
			in_msgstr = false
			continue
		if in_msgstr and line.begins_with("\""):
			buffer += line.trim_suffix("\"").strip_edges()

	file.close()
	return count
