extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Every locale must carry the same keys.
##
## The most common i18n bug in a small project is a locale that silently
## drifts: a key added to en.po and forgotten in fr.po ships as an English
## string in a French build. This suite catches that before it ships.
##
## The same check exists as tools/check_locales.py for running outside
## Godot; keep the two in sync.

const LOCALE_DIR = "res://locale/"
const TEMPLATE = "res://locale/messages.pot"


func suite(t):
	t.suite("Locales")

	t.test("the template exists")
	t.expect_true(FileAccess.file_exists(TEMPLATE), "messages.pot should exist")

	if not FileAccess.file_exists(TEMPLATE):
		return

	var template_keys = _parse_po(TEMPLATE)
	t.expect_gt(float(template_keys.size()), 20.0, "the template should define a real set of keys")

	var locale_files = _locale_files()
	t.expect_gt(float(locale_files.size()), 0.0, "there should be at least one locale")

	for path: String in locale_files:
		var name = path.get_file()
		var keys = _parse_po(path)

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
		var translated = _translated_count(path)
		t.expect_gt(float(translated), 0.0, "%s should have translated strings" % path.get_file())

	t.test("no file has duplicate keys")
	# A duplicate msgid is a silent bug: the importer keeps one occurrence
	# and the other translation is lost.
	for path: String in _locale_files() + [TEMPLATE]:
		var keys = _parse_po(path)
		var seen = {}
		var duplicates: Array[String] = []
		for key: String in keys:
			if seen.has(key):
				duplicates.append(key)
			seen[key] = true
		t.expect_eq(duplicates.size(), 0, "%s has duplicate key(s): %s" % [
			path.get_file(), ", ".join(duplicates.slice(0, 5))
		])


	t.test("every key the game uses exists in the template")
	# The suite above checks that the locales agree with each other. It
	# cannot check that they agree with the GAME, and the playtest found
	# the hole: the Venture's faces carried a title key that nobody had
	# ever written down, and the panel printed "ui.face.venture.book.title"
	# to the player instead of a title.
	#
	# So: every key the code and the data use has to be in the template.
	var used = _keys_used_by_the_game()
	t.expect_gt(float(used.size()), 10.0, "the scan should find the game's keys")
	var unknown: Array[String] = []
	for key: String in used:
		# The parser keeps the quotes round the msgid, because that is
		# what the other half of this suite compares.
		if not template_keys.has('"%s"' % key) and not unknown.has(key):
			unknown.append(key)
	t.expect_eq(unknown.size(), 0, "%d key(s) the game uses are not in the template: %s" % [
		unknown.size(), ", ".join(unknown.slice(0, 5))])


## Every key the code and the data use.
##
## Two passes: the string literals in the scripts, and the `*_key`
## properties in the data resources. The data is the one that matters
## most — a resource can carry a key that no line of code ever names.
func _keys_used_by_the_game() -> Array[String]:
	var out: Array[String] = []

	var literal = RegEx.new()
	literal.compile("\"([a-z]{2,4}\\.[A-Za-z0-9_]+(\\.[A-Za-z0-9_]+)*)\"")
	for path: String in _files_with_extension("res://src/", ".gd"):
		# The tools are diagnostics: they quote keys as examples.
		if path.contains("/tools/"):
			continue
		var text = FileAccess.get_file_as_string(path)
		for match: RegExMatch in literal.search_all(text):
			var key = match.get_string(1)
			if key.begins_with("bk."):
				# A fragment id, not a UI key: "bk.ch01.apertura".
				continue
			if not out.has(key):
				out.append(key)

	var property = RegEx.new()
	property.compile("([a-z_]+_key)\\s*=\\s*&?\"([A-Za-z0-9_.]+)\"")
	for path: String in _files_with_extension("res://src/data/", ".tres"):
		var text = FileAccess.get_file_as_string(path)
		for match: RegExMatch in property.search_all(text):
			var key = match.get_string(2)
			if not out.has(key):
				out.append(key)

	return out


## Every file under a directory with a given extension, one level down
## as well: the data lives in folders.
func _files_with_extension(directory: String, extension: String) -> Array[String]:
	var out: Array[String] = []
	var dir = DirAccess.open(directory)
	if dir == null:
		return out
	for file_name: String in dir.get_files():
		if file_name.ends_with(extension):
			out.append(directory + file_name)
	for sub: String in dir.get_directories():
		var sub_dir = DirAccess.open(directory + sub)
		if sub_dir == null:
			continue
		for file_name: String in sub_dir.get_files():
			if file_name.ends_with(extension):
				out.append(directory + sub + "/" + file_name)
	out.sort()
	return out


func _locale_files() -> Array[String]:
	var out: Array[String] = []
	var dir = DirAccess.open(LOCALE_DIR)
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
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return keys

	var current = ""
	var in_msgid = false
	var in_plural = false

	while not file.eof_reached():
		var line = file.get_line().strip_edges()

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
			var part = line.substr(1).strip_edges().trim_suffix("\"").strip_edges()
			if not part.is_empty():
				keys.append(part)
			continue

	file.close()
	return keys


## Count the msgstr entries that are not empty (i.e. actually translated).
func _translated_count(path: String):
	var count = 0
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var in_msgstr = false
	var buffer = ""

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
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
