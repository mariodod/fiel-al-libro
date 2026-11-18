extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## The world map: regions, the road, and the Book/Reality reads.
##
## GDD.md §11.4: "The 'libro' map screen. A hand-drawn map in the style of
## a 1605 map, with the 'Book' version and the 'Reality' version of each
## region side by side. Filling it in is a collectible."

const SCENE = "res://src/world/map_screen.tscn"


func suite(t):
	t.suite("MapScreen")

	# ── Reset ────────────────────────────────────────────────────────
	# GameState is an autoload singleton; earlier tests may have loaded
	# slice.tscn whose _ready() calls find_region(). Clear so this suite
	# starts from a clean slate.
	GameState.regions_found.clear()
	GameState.regions_resolved.clear()

	# ── Region data ──────────────────────────────────────────────────
	t.test("region data loads from .tres files")
	var dir = DirAccess.open("res://src/data/regions/")
	t.expect_true(dir != null, "the regions directory should exist")
	if dir == null:
		return

	var regions = []
	for name in dir.get_files():
		if name.ends_with(".tres"):
			var res = load("res://src/data/regions/" + name)
			t.expect_true(res != null, "region %s should load" % name)
			if res != null:
				regions.append(res)
	t.expect_eq(regions.size(), 5, "five regions, one per chapter")

	# Sort by chapter so index checks are meaningful (insertion sort —
	# sort_custom isn't reliable in this Godot build).
	for i in range(1, regions.size()):
		var key = regions[i]
		var j = i - 1
		while j >= 0 and regions[j].chapter > key.chapter:
			regions[j + 1] = regions[j]
			j -= 1
		regions[j + 1] = key

	t.expect_eq(regions[0].id, &"camino_la_mancha", "region I is the Camino")
	t.expect_eq(regions[4].id, &"el_castillo_del_duque", "region V is the Duke's castle")

	t.test("regions are sorted by chapter")
	for i in range(1, regions.size()):
		t.expect_gt(regions[i].chapter, regions[i-1].chapter,
			"chapters increase: %d after %d" % [regions[i].chapter, regions[i-1].chapter])

	t.test("every region has a name key and a fantasy")
	for res in regions:
		t.expect_false(res.name_key.is_empty(), "%s has a name key" % str(res.id))
		t.expect_false(res.fantasy.is_empty(), "%s has a fantasy" % str(res.id))

	t.test("finding a region grants its own Manifiesto page")
	var saved_pages := GameState.codex_pages.duplicate()
	GameState.codex_pages.clear()
	GameState.regions_found.clear()

	GameState.find_region(&"camino_la_mancha")
	t.expect_has(GameState.codex_pages, &"bk.ch01.apertura.01",
		"La Mancha grants the opening passage")
	GameState.find_region(&"los_riscos")
	t.expect_has(GameState.codex_pages, &"bk.ch09.manuscrito.01",
		"Los Riscos grants the found manuscript")

	# A second visit must not duplicate the page.
	var count := GameState.codex_pages.size()
	GameState.find_region(&"camino_la_mancha")
	t.expect_eq(GameState.codex_pages.size(), count, "granting is idempotent")

	# Every region fragment must actually be loadable by id — this is what
	# makes the codex page readable, not just a string in an array.
	for res in regions:
		if res.fragment_id.is_empty():
			continue
		t.expect_false(ManifiestoFragment.load_data(res.fragment_id).is_empty(),
			"%s fragment loads by id" % str(res.id))

	GameState.codex_pages = saved_pages
	GameState.regions_found.clear()

	t.test("every region has a real fragment id")
	# Four regions used to carry a stale `fragment_key` property, so they had
	# no fragment id at all and never showed a marker on the map.
	for res in regions:
		t.expect_false(res.fragment_id.is_empty(), "%s has a fragment id" % str(res.id))
		if res.fragment_id.is_empty():
			continue
		var path := "res://assets/manifiesto/%s.json" % str(res.fragment_id)
		t.expect_true(FileAccess.file_exists(path), "%s fragment file exists" % str(res.id))

	t.test("the map screen builds two readings with five markers each")
	var packed := load(SCENE) as PackedScene
	t.expect_true(packed != null, "map screen scene loads")
	if packed != null:
		var screen := packed.instantiate()
		# Do not add to the tree: the harness is already inside its own
		# _ready(), so root is busy. Drive _ready() directly, then free the
		# screen so it does not keep receiving EventBus signals.
		screen._ready()
		var container := screen.find_child("MapContainer", true, false)
		t.expect_true(container != null, "MapContainer is built")
		if container != null:
			var markers := container.find_children("Marker_*", "ColorRect", true, false)
			t.expect_eq(markers.size(), 10, "five regions on each of two maps")
			var reality_host := screen.find_child("RealityHost", true, false)
			var book_host := screen.find_child("BookHost", true, false)
			t.expect_true(reality_host != null and book_host != null, "both map hosts exist")
			if reality_host != null and book_host != null:
				t.expect_eq(reality_host.find_children("Marker_*", "ColorRect", true, false).size(), 5,
					"Reality map has five markers")
				t.expect_eq(book_host.find_children("Marker_*", "ColorRect", true, false).size(), 5,
					"Book map has five markers")
		screen.free()

	t.test("regions name a real key venture, except the Ensayo")
	for res in regions:
		if res.id == &"los_riscos":
			# GDD.md §11.2: the Ensayo is a case, not a Venture.
			t.expect_true(res.key_venture_id.is_empty(), "the Ensayo has no key venture")
			continue
		t.expect_false(res.key_venture_id.is_empty(), "%s has a key venture" % str(res.id))
		var vpath := "res://src/data/ventures/%s.tres" % str(res.key_venture_id)
		t.expect_true(ResourceLoader.exists(vpath), "%s venture data exists" % str(res.id))

	t.test("every region has a Book and a Reality passage")
	for res in regions:
		t.expect_false(res.book_fantasy_key.is_empty(), "%s has a Book passage key" % str(res.id))
		t.expect_false(res.reality_fantasy_key.is_empty(), "%s has a Reality passage key" % str(res.id))
		var book_text := Loc.t(res.book_fantasy_key)
		var reality_text := Loc.t(res.reality_fantasy_key)
		t.expect_false(book_text == str(res.book_fantasy_key), "%s Book passage is translated" % str(res.id))
		t.expect_false(reality_text == str(res.reality_fantasy_key), "%s Reality passage is translated" % str(res.id))
		t.expect_false(book_text == reality_text, "%s reads differently in each truth" % str(res.id))

	# ── GameState region tracking ────────────────────────────────────
	t.test("regions start unfound")
	t.expect_eq(GameState.regions_found_count(), 0, "no regions found at the start")

	t.test("finding a region counts it")
	GameState.find_region(&"sierra_morena")
	t.expect_eq(GameState.regions_found_count(), 1, "one region found")
	t.expect_true(GameState.region_found(&"sierra_morena"), "Sierra Morena is found")
	t.expect_false(GameState.region_found(&"los_riscos"), "Los Riscos is not found")

	t.test("resolving a region counts it")
	GameState.resolve_region(&"sierra_morena")
	t.expect_eq(GameState.regions_resolved_count(), 1, "one region resolved")
	t.expect_true(GameState.region_resolved(&"sierra_morena"), "Sierra Morena is resolved")

	t.test("finding the same region twice does not double-count")
	GameState.find_region(&"sierra_morena")
	t.expect_eq(GameState.regions_found_count(), 1, "still one region found")

	# ── Reset ────────────────────────────────────────────────────────
	GameState.regions_found.clear()
	GameState.regions_resolved.clear()
	t.expect_eq(GameState.regions_found_count(), 0, "cleared for the next suite")
