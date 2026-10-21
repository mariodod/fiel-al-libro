extends SceneTree
## Checks the Manifiesto fragments and prints the worklist.
##
## Run from the project root:
##   .\tools\godot.ps1 --headless --script res://src/tools/validate_manifiesto.gd
##
## What it does:
##   1. Reads every fragment in assets/manifiesto/ and checks it against the
##      format's own rules and the project's hard ones.
##   2. Reports the 1605/1615 trap: a fragment whose original carries the
##      1615 wording is a fragment from the wrong book (DLC 1 is the 1615
##      one), and it is the mistake the project's own sample made.
##   3. Reports which fragments the build actually reads, because an
##      unverified fragment must not ship and "ships" means "is read".
##   4. Prints the worklist: the 48-fragment plan, what is there, and what
##      each fragment is still missing.
##
## Exit code 0 = no errors. 1 = at least one error, or the directory is
## missing. Warnings do not fail the run: they are the worklist.
##
## Deliberately a GDScript tool, not a Python one: the project has no
## runtime dependencies beyond Godot, and neither should the workflow.
##
## The rules live in `src/data/manifiesto_fragment.gd`, so the test suite
## can check the fragments too (tests/test_manifiesto_content.gd).

const SEVERITY_ERROR := "ERROR"
const SEVERITY_WARN := "WARN"


func _init() -> void:
	var files := ManifiestoFragment.fragment_files()
	if files.is_empty():
		printerr("[manifiesto] No fragments found in %s" % ManifiestoFragment.DIRECTORY)
		quit(1)
		return

	var referenced := ManifiestoFragment.referenced_files()
	print("[manifiesto] %d fragment(s) in %s" % [files.size(), ManifiestoFragment.DIRECTORY])
	print("[manifiesto] the build reads: %s" % (", ".join(referenced) if not referenced.is_empty() else "nothing yet"))
	print("[manifiesto] note: a file whose name starts with an underscore is")
	print("[manifiesto]       invisible to Godot, so it can be neither read nor")
	print("[manifiesto]       checked. Every fragment here has a plain name.")

	var errors := 0
	var warnings := 0
	var ids := {}
	var worklist: Array[String] = []

	for file_name: String in files:
		var path := ManifiestoFragment.DIRECTORY + file_name
		var base := file_name.get_basename()
		var data := ManifiestoFragment.load_data(StringName(base))
		if data.is_empty():
			print("")
			print(base)
			print("  [ERROR] unreadable: the file is not a fragment")
			errors += 1
			continue

		var fragment_id := str(data.get("id", base))
		if ids.has(fragment_id):
			print("")
			print(fragment_id)
			print("  [ERROR] duplicate-id: another fragment already uses this id")
			errors += 1
		ids[fragment_id] = true

		var problems := ManifiestoFragment.validate(data, base)
		print("")
		print(fragment_id)
		var fragment_warnings := 0
		for problem in problems:
			var text := str(problem)
			print("  " + text)
			if str(problem.level) == SEVERITY_ERROR:
				errors += 1
			else:
				warnings += 1
				fragment_warnings += 1
		if problems.is_empty():
			print("  [ok] no problems")
		if fragment_warnings > 0:
			worklist.append("%s: %d thing(s) still to do" % [fragment_id, fragment_warnings])

	print("")
	print("-".repeat(70))
	print("[manifiesto] %d fragment(s) of the %d the plan wants" % [
		files.size(), ManifiestoFragment.PLANNED_COUNT])
	print("[manifiesto] %d error(s), %d warning(s)" % [errors, warnings])
	if not worklist.is_empty():
		print("[manifiesto] the worklist:")
		for line: String in worklist:
			print("  - " + line)
	else:
		print("[manifiesto] the worklist is empty.")

	if errors > 0:
		print("[manifiesto] FAILED: %d error(s)." % errors)
		quit(1)
		return
	print("[manifiesto] OK.")
	quit(0)
