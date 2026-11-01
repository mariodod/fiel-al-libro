extends SceneTree

## Verify all Manifiesto fragments against the 1605 reference text.
##
## Usage:
##   godot --headless --script res://src/tools/verify_fragments.gd

const REF_PATH := "res://reference/quijote_1605_parte1.txt"
const FRAG_DIR := "res://assets/manifiesto/"

func _init() -> void:
	var ref_file: FileAccess = FileAccess.open(REF_PATH, FileAccess.READ)
	if ref_file == null:
		print("[verify] ERROR: Could not open reference file %s" % REF_PATH)
		quit(1)
		return
	var ref_text: String = ref_file.get_as_text()
	ref_file.close()
	
	# Normalize reference text for comparison
	var ref_norm: String = _normalize(ref_text)
	
	# Get all fragment files
	var dir: DirAccess = DirAccess.open(FRAG_DIR)
	if dir == null:
		print("[verify] ERROR: Could not open fragment directory %s" % FRAG_DIR)
		quit(1)
		return
	
	var files: Array[String] = []
	for name in dir.get_files():
		if name.ends_with(".json") and not name.begins_with("_"):
			files.append(name)
	files.sort()
	
	print("[verify] Checking %d fragments against 1605 reference..." % files.size())
	print("")
	
	var errors: int = 0
	var verified: int = 0
	var total: int = files.size()
	
	for fname in files:
		var path: String = FRAG_DIR + fname
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			print("[verify] %s: ERROR - cannot read" % fname)
			errors += 1
			continue
		var text: String = f.get_as_text()
		f.close()
		
		var data: Variant = JSON.parse_string(text)
		if typeof(data) != TYPE_DICTIONARY:
			print("[verify] %s: ERROR - not valid JSON" % fname)
			errors += 1
			continue
		
		var fid: String = str(data.get("id", fname.get_basename()))
		var original: String = str(data.get("original_1605", ""))
		var is_verified: bool = bool(data.get("source", {}).get("verified", false))
		var verified_on: String = str(data.get("source", {}).get("verified_on", "none"))
		var chapter: String = str(data.get("chapter", "?"))
		var part: String = str(data.get("part", "?"))
		
		if original.is_empty():
			print("[verify] %s [ch%s.%s] [verified=%s] ERROR: empty original_1605" % [fid, chapter, part, is_verified])
			errors += 1
			continue
		
		var orig_norm: String = _normalize(original)
		
		var status: String = "NOT FOUND"
		if orig_norm in ref_norm:
			status = "MATCH"
		else:
			errors += 1
		
		if is_verified:
			verified += 1
		
		var snippet: String = original.substr(0, min(80, original.length()))
		print("[verify] %s [ch%s.%s] [verified=%s] %s: %s" % [fid, chapter, part, is_verified, status, snippet])
	
	print("")
	print("[verify] Summary: %d fragments checked" % total)
	print("[verify]         %d verified (verified=true)" % verified)
	print("[verify]         %d text matches found in 1605 reference" % (total - errors))
	print("[verify]         %d errors/mismatches" % errors)
	
	if errors > 0:
		print("[verify] FAILED: %d fragment(s) have text issues" % errors)
		quit(1)
	else:
		print("[verify] PASSED: all fragments match the 1605 reference")
		quit(0)


## Normalize text for comparison: lowercase, strip punctuation, collapse whitespace.
func _normalize(s: String) -> String:
	s = s.to_lower()
	# Replace punctuation with spaces
	var punct: String = ".,;:¡¿!?()\"'[]{}«»–—…"
	for p in punct:
		s = s.replace(p, " ")
	# Collapse whitespace
	var result: String = ""
	var in_space: bool = false
	for c in s:
		if c == " " or c == "\n" or c == "\t" or c == "\r":
			if not in_space:
				result += " "
				in_space = true
		else:
			result += c
			in_space = false
	return result.strip_edges()
