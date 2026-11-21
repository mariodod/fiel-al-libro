extends RefCounted
## A tolerant gettext PO reader for player-imported translations.
##
## Community .po files are rarely perfect: headers may be missing, messages may
## span several quoted lines, and translator comments are common. This parser
## follows the rules of src/tools/sync_locales.gd, with two differences that
## matter at runtime: it unescapes values with String.c_unescape() and it does
## not strip whitespace from the inside of a quoted value.

## Godot's key separator when a context is used (not used by this project).
const CONTEXT_SEP := "\u0004"


## Parse PO text into {key: translation}. Keys are the msgid (with a context
## prefix if one is present). Empty msgstr values are skipped: an untranslated
## entry would override a working shipped translation with a blank string.
static func parse(text: String) -> Dictionary:
	var out: Dictionary = {}
	var msgid := ""
	var msgstr := ""
	var context := ""
	var field := ""
	var has_id := false

	for raw_line in text.split("\n"):
		var line: String = raw_line.strip_edges()

		if line.is_empty():
			_emit(out, msgid, msgstr, context, has_id)
			msgid = ""
			msgstr = ""
			context = ""
			field = ""
			has_id = false
			continue
		if line.begins_with("#"):
			continue
		if line.begins_with("msgctxt "):
			context = _unquote(line.substr(8))
			field = "msgctxt"
			continue
		if line.begins_with("msgid_plural "):
			# Plural forms are not used by this project; msgstr[0] is enough.
			field = "msgstr"
			continue
		if line.begins_with("msgid "):
			msgid = _unquote(line.substr(6))
			has_id = true
			field = "msgid"
			continue
		if line.begins_with("msgstr["):
			# Capture msgstr[0] if present; ignore the other forms.
			var close := line.find("]")
			if close != -1:
				var index := line.substr(1, close - 1)
				var value_start := line.find("\"", close)
				if value_start != -1:
					msgstr = _unquote(line.substr(value_start))
			field = "msgstr"
			continue
		if line.begins_with("msgstr "):
			msgstr = _unquote(line.substr(7))
			field = "msgstr"
			continue
		if line.begins_with("\"") and field != "":
			var part := _unquote(line)
			match field:
				"msgid": msgid += part
				"msgstr": msgstr += part
				"msgctxt": context += part
			continue
	_emit(out, msgid, msgstr, context, has_id)
	return out


## Read the Language field from the PO header. The header is the entry with an
## empty msgid; its value is spread over quoted continuation lines. Falls back
## to the filename stem ("gl_ES.po" -> "gl_ES").
static func locale_from_header(text: String, filename: String = "") -> String:
	var in_header := false
	var header := ""
	for raw_line in text.split("\n"):
		var line: String = raw_line.strip_edges()
		if line == "msgid \"\"":
			in_header = true
			continue
		if line.begins_with("msgid ") or line.begins_with("msgctxt "):
			in_header = false
			continue
		if in_header and line.begins_with("\""):
			header += _unquote(line)
	for entry in header.split("\n"):
		var part: String = entry.strip_edges()
		if part.begins_with("Language:") or part.begins_with("X-Language:"):
			var code := part.substr(part.find(":") + 1).strip_edges().replace("-", "_")
			if not code.is_empty():
				return code
	if filename.is_empty():
		return ""
	return filename.get_file().get_basename().replace("-", "_")


static func _emit(out: Dictionary, msgid: String, msgstr: String,
		context: String, has_id: bool) -> void:
	if not has_id or msgid.is_empty() or msgstr.is_empty():
		return
	var key := msgid
	if not context.is_empty():
		key = context + CONTEXT_SEP + msgid
	out[key] = msgstr


static func _unquote(text: String) -> String:
	var t := text.strip_edges()
	if t.length() >= 2 and t.begins_with("\"") and t.ends_with("\""):
		t = t.substr(1, t.length() - 2)
	return t.c_unescape()
