extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
const ManifiestoFragment = preload("res://src/data/manifiesto_fragment.gd")
## The Manifiesto fragments, checked.
##
## The fragments are the game's literal source material, and they have
## two hard rules that are easy to break and impossible to see:
##
## 1. **The 1605 wording is content.** It is the same in every build, in
##    every language, and it is never a translation key. DLC 1 is the
##    1615 book, so a fragment that carries the 1615 wording is a
##    fragment from the wrong book — the mistake the project's own sample
##    fragment made.
## 2. **Nobody ships a fragment nobody has checked.** `verified` is set
##    by a human against the edition, and an unverified fragment must
##    not ship.
##
## The rules live in `src/data/manifiesto_fragment.gd` so that the
## headless tool (src/tools/validate_manifiesto.gd) and this suite
## agree on what a fragment owes.

func suite(t):
	t.suite("ManifiestoContent")

	var files = ManifiestoFragment.fragment_files()

	t.test("there is a fragment to read")
	t.expect_gt(float(files.size()), 0.0, "the Manifiesto should not be empty")

	t.test("every fragment in the repository is valid")
	for file_name: String in files:
		var base = file_name.get_basename()
		var data = ManifiestoFragment.load_data(StringName(base))
		t.expect_false(data.is_empty(), "%s should be readable" % file_name)
		if data.is_empty():
			continue
		var errors: Array[String] = []
		for problem in ManifiestoFragment.validate(data, base):
			if str(problem.level) == "ERROR":
				errors.append(str(problem))
		t.expect_eq(errors.size(), 0, "%s: %s" % [base, ", ".join(errors)])

	t.test("and no two fragments share an id")
	var ids = {}
	for file_name: String in files:
		var data = ManifiestoFragment.load_data(StringName(file_name.get_basename()))
		var id = str(data.get("id", ""))
		if id.is_empty():
			continue
		t.expect_false(ids.has(id), "%s is used twice" % id)
		ids[id] = true

	t.test("every fragment the build reads has been checked")
	# "Ships" means "is read". The page turn prints a line of the
	# original, and an unverified fragment must not ship.
	var referenced = ManifiestoFragment.referenced_files()
	t.expect_gt(float(referenced.size()), 0.0, "the build should read at least one fragment")
	for file_name: String in referenced:
		var data = ManifiestoFragment.load_data(StringName(file_name.get_basename()))
		if data.is_empty():
			t.expect_true(false, "%s is read by the build and cannot be read" % file_name)
			continue
		var source = data.get("source", {})
		t.expect_true(bool(source.get("verified", false)),
			"%s is read by the build and nobody has checked it against the edition" % file_name)

	t.test("the original is content, and never a key")
	for file_name: String in files:
		var data = ManifiestoFragment.load_data(StringName(file_name.get_basename()))
		var original = str(data.get(ManifiestoFragment.ORIGINAL_FIELD, ""))
		t.expect_false(original.begins_with("bk."), "%s: the original is a key" % file_name)
		t.expect_gt(float(original.length()), 0.0, "%s: the original is empty" % file_name)
