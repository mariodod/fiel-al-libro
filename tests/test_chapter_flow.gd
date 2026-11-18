extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The chapter flow makes all built chapters reachable end to end.

func suite(t):
	t.suite("ChapterFlow")

	t.test("the unlock chain reaches every chapter")
	ChapterFlow.reset_campaign()
	var all := RegionGraph.all_chapters()
	t.expect_gt(float(all.size()), 40.0, "the graph holds all built chapters")
	var seen := {}
	var id := RegionGraph.start_chapter
	var hops := 0
	while not id.is_empty() and not seen.has(id) and hops < 100:
		seen[id] = true
		id = RegionGraph.next_chapter(id)
		hops += 1
	t.expect_eq(seen.size(), all.size(), "following unlocks visits every chapter")
	t.expect_false(seen.has(&""), "no empty chapter id in the chain")

	t.test("reset returns a fresh campaign")
	GameState.chapter_completed(&"ch_05_montesinos")
	GameState.find_region(&"sierra_morena")
	GameState.codex_pages.append(&"bk.ch15.muerto_camino.01")
	ChapterFlow.reset_campaign()
	t.expect_eq(GameState.chapters_completed_count(), 0, "no chapters complete")
	t.expect_eq(GameState.regions_found.size(), 0, "no regions found")
	t.expect_eq(GameState.codex_pages.size(), 0, "codex cleared")
	t.expect_true(RegionGraph.is_chapter_unlocked(RegionGraph.start_chapter),
		"the first chapter is unlocked")
	t.expect_false(RegionGraph.is_chapter_unlocked(&"ch_50_impertinente"),
		"the last chapter is locked again")

	t.test("the next playable chapter skips already-complete unlocks")
	ChapterFlow.reset_campaign()
	var first := RegionGraph.start_chapter
	var second := RegionGraph.next_chapter(first)
	t.expect_eq(ChapterFlow.next_playable_chapter(first), second,
		"normally the next chapter follows")
	RegionGraph.complete_chapter(second)
	t.expect_eq(ChapterFlow.next_playable_chapter(first),
		RegionGraph.next_chapter(second),
		"a completed chapter is skipped (the Ensayo case)")
	ChapterFlow.reset_campaign()

	t.test("every chapter scene in the graph loads")
	var dir := DirAccess.open("res://src/world/chapters/")
	for chapter_id in all:
		var data: Dictionary = RegionGraph.get_chapter(chapter_id)
		var path: String = data.get("scene_path", "")
		t.expect_true(FileAccess.file_exists(path), "%s scene exists" % chapter_id)

	t.test("the ending becomes reachable when the graph is exhausted")
	ChapterFlow.reset_campaign()
	# Mark them complete without letting the flow start 47 ride transitions.
	ChapterFlow.active = false
	for chapter_id in RegionGraph.all_chapters():
		GameState.chapter_completed(chapter_id)
		RegionGraph.complete_chapter(chapter_id)
	ChapterFlow.transitioning = false
	ChapterFlow.active = true
	t.expect_eq(GameState.chapters_completed_count(), RegionGraph.all_chapters().size(),
		"every chapter is complete")
	var finished: Array[bool] = []
	var on_finished := func() -> void:
		finished.append(true)
	ChapterFlow.flow_finished.connect(on_finished)
	EventBus.chapter_completed.emit(RegionGraph.start_chapter)
	t.expect_eq(finished.size(), 1, "the flow reports finished")
	var ending := GameState.compute_ending()
	t.expect_false(ending.is_empty(), "an ending is computed")
	ChapterFlow.flow_finished.disconnect(on_finished)
	ChapterFlow.reset_campaign()

	t.test("every chapter has a title and its own intro line")
	for chapter_id in RegionGraph.all_chapters():
		var num: int = int(str(chapter_id).substr(3, 2))
		var base := "ui.chapter.%02d" % num
		var data: Dictionary = RegionGraph.get_chapter(chapter_id)
		var path: String = data.get("scene_path", "")
		var script_path := path.replace(".tscn", ".gd")
		var script := FileAccess.get_file_as_string(script_path)
		t.expect_true(script.contains(base + ".intro"),
			"%s emits its intro" % chapter_id)
		var pot := FileAccess.get_file_as_string("res://locale/messages.pot")
		t.expect_true(pot.contains('msgid "%s.title"' % base),
			"%s has a title key" % chapter_id)
		t.expect_true(pot.contains('msgid "%s.intro"' % base),
			"%s has an intro key" % chapter_id)

	t.test("the ride transition text is translated in all six locales")
	for locale in ["en", "es", "fr", "de", "it", "pt_BR"]:
		var p := "res://locale/%s.po" % locale
		var text := FileAccess.get_file_as_string(p)
		t.expect_true(text.contains('msgid "ui.chapter.ride"'),
			"%s has the ride key" % locale)
