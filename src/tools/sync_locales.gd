extends SceneTree
## Keeps every locale in sync with the template.
##
## Run from the project root:
##   godot --headless --script res://src/tools/sync_locales.gd
##
## What it does:
##   1. Reads locale/messages.pot (the template).
##   2. For each locale/*.po, finds entries that are missing and appends
##      them with an empty msgstr — the standard gettext "untranslated"
##      state — carrying the template's translator comments across.
##   3. Reports any entry in a .po that is NOT in the template (an orphan),
##      which is always a bug.
##
## Why this exists: a key added to the template and forgotten in fr.po ships
## as a raw key string in the French build. The test suite (tests/
## test_locales.gd) catches it in CI; this tool fixes it locally.
##
## Deliberately a GDScript tool, not a Python one: the project has no
## runtime dependencies beyond Godot, and neither should the workflow.

const LOCALE_DIR := "res://locale/"
const TEMPLATE := "res://locale/messages.pot"


func _init() -> void:
	if not FileAccess.file_exists(TEMPLATE):
		printerr("[sync_locales] Template not found: %s" % TEMPLATE)
		quit(1)
		return

	var template_text := _read(TEMPLATE)
	var template_entries := _parse(template_text)
	if template_entries.is_empty():
		printerr("[sync_locales] Template has no entries.")
		quit(1)
		return

	print("[sync_locales] Template: %d entries" % template_entries.size())

	var changed := 0
	for file_name: String in _locale_files():
		var path := LOCALE_DIR + file_name
		var text := _read(path)
		var entries := _parse(text)
		var existing := {}
		for entry: Dictionary in entries:
			existing[_identity(entry)] = true

		var missing: Array[Dictionary] = []
		for entry: Dictionary in template_entries:
			if not existing.has(_identity(entry)):
				missing.append(entry)

		# Orphans: in the .po but not in the template. Always a bug.
		var template_ids := {}
		for entry: Dictionary in template_entries:
			template_ids[_identity(entry)] = true
		var orphans: Array[String] = []
		for entry: Dictionary in entries:
			if not template_ids.has(_identity(entry)):
				orphans.append(str(entry.get("msgid", "?")))

		if not orphans.is_empty():
			printerr("[sync_locales] %s has %d orphan entry/entries: %s" % [
				file_name, orphans.size(), ", ".join(orphans.slice(0, 5))
			])

		if missing.is_empty():
			print("[sync_locales] %-12s ok (%d entries)" % [file_name, entries.size()])
			continue

		for entry: Dictionary in missing:
			text += _render_untranslated(entry)
		_write(path, text)
		changed += 1
		print("[sync_locales] %-12s +%d missing entries appended" % [file_name, missing.size()])

	print("[sync_locales] %d file(s) updated" % changed)
	quit(0)


# ── File helpers ────────────────────────────────────────────────────────

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("[sync_locales] Could not write %s" % path)
		return
	file.store_string(text)
	file.close()


func _locale_files() -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(LOCALE_DIR)
	if dir == null:
		return out
	for file_name: String in dir.get_files():
		if file_name.ends_with(".po"):
			out.append(file_name)
	out.sort()
	return out


# ── PO parsing ──────────────────────────────────────────────────────────

## A PO entry: {comments, msgctxt, msgid, msgid_plural, msgstr}
func _parse(text: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var current := _new_entry()
	var field := ""

	for raw_line: String in text.split("\n"):
		var line := raw_line.strip_edges()

		if line.is_empty():
			if not current.get("msgid", "").is_empty() or not current.get("comments", []).is_empty():
				entries.append(current)
			current = _new_entry()
			field = ""
			continue

		if line.begins_with("#"):
			# Keep translator comments (# TRANSLATORS: / #. ) and metadata (#: / #,).
			current["comments"].append(line)
			field = ""
			continue

		if line.begins_with("msgctxt "):
			current["msgctxt"] = _unquote(line.substr("msgctxt ".length()))
			field = "msgctxt"
			continue
		if line.begins_with("msgid_plural "):
			current["msgid_plural"] = _unquote(line.substr("msgid_plural ".length()))
			field = "msgid_plural"
			continue
		if line.begins_with("msgid "):
			current["msgid"] = _unquote(line.substr("msgid ".length()))
			field = "msgid"
			continue
		if line.begins_with("msgstr["):
			field = "msgstr"
			continue
		if line.begins_with("msgstr "):
			current["msgstr"] = _unquote(line.substr("msgstr ".length()))
			field = "msgstr"
			continue

		# Continuation of a multi-line string.
		if line.begins_with("\"") and field != "":
			var part := _unquote(line)
			if field == "msgid":
				current["msgid"] = str(current.get("msgid", "")) + part
			elif field == "msgid_plural":
				current["msgid_plural"] = str(current.get("msgid_plural", "")) + part
			elif field == "msgctxt":
				current["msgctxt"] = str(current.get("msgctxt", "")) + part
			elif field == "msgstr":
				current["msgstr"] = str(current.get("msgstr", "")) + part
			continue

	# Trailing entry.
	if not current.get("msgid", "").is_empty() or not current.get("comments", []).is_empty():
		entries.append(current)
	return entries


func _new_entry() -> Dictionary:
	return {
		"comments": [] as Array,
		"msgctxt": "",
		"msgid": "",
		"msgid_plural": "",
		"msgstr": "",
	}


## The identity of an entry: its context and its msgid. Plural entries are
## identified by their msgid too, because the plural forms hang off it.
func _identity(entry: Dictionary) -> String:
	# char(4) is the gettext "context separator" — it cannot appear in a key.
	return "%s%s%s" % [str(entry.get("msgctxt", "")), char(4), str(entry.get("msgid", ""))]


func _unquote(text: String) -> String:
	var t := text.strip_edges()
	if t.begins_with("\"") and t.ends_with("\"") and t.length() >= 2:
		return t.substr(1, t.length() - 2)
	return t


## Render an entry as an untranslated block, carrying the template's
## comments so the translator sees the same guidance.
func _render_untranslated(entry: Dictionary) -> String:
	var out := "\n"
	for comment: String in entry.get("comments", []):
		out += str(comment) + "\n"
	var ctx := str(entry.get("msgctxt", ""))
	if not ctx.is_empty():
		out += "msgctxt \"%s\"\n" % ctx
	out += "msgid \"%s\"\n" % str(entry.get("msgid", ""))
	var plural := str(entry.get("msgid_plural", ""))
	if not plural.is_empty():
		out += "msgid_plural \"%s\"\n" % plural
		out += "msgstr[0] \"\"\n"
		out += "msgstr[1] \"\"\n"
	else:
		out += "msgstr \"\"\n"
	return out
