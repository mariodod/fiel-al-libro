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
