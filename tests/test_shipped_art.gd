extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §15: the shipped art must actually be wired into the UI, not just
## sit in assets/. This pins every image family the project uses.

const ART := "res://assets/art/"

func suite(t):
	t.suite("ShippedArt")

	t.test("title, parchment and five region backdrops exist")
	for name in ["title_background", "parchment",
			"region_camino_la_mancha", "region_sierra_morena", "region_el_toboso",
			"region_los_riscos", "region_el_castillo_del_duque"]:
		t.expect_true(FileAccess.file_exists(ART + name + ".jpg"), "%s exists" % name)
		var tex := load(ART + name + ".jpg") as Texture2D
		t.expect_true(tex != null, "%s loads as a Texture2D" % name)

	t.test("nine book covers and five portraits exist")
	for slug in ["book", "book_mio_cid", "book_pelayo", "book_gatos",
			"book_santo_domingo", "book_milagros", "book_lazarillo",
			"book_tirant", "book_tablas", "book_buscon", "book_don_juan",
			"book_codice"]:
		t.expect_true(FileAccess.file_exists(ART + slug + ".jpg"), "%s exists" % slug)
	for id in ["quixote", "sancho", "innkeeper", "musician", "leyenda"]:
		t.expect_true(FileAccess.file_exists(ART + "portrait_%s.jpg" % id),
			"portrait_%s exists" % id)

	t.test("the title page shows the painted background")
	var shell := (load("res://src/ui/manuscript_ui.tscn") as PackedScene).instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.current_scene.add_child(shell)
	var bg := shell.get_node_or_null("Pages/TitlePage/TitleBackground") as TextureRect
	t.expect_true(bg != null, "title background node exists")
	if bg != null:
		t.expect_true(bg.texture != null, "title background texture is set")
	tree.current_scene.remove_child(shell)
	shell.free()

	t.test("the map lists five region previews")
	var map := (load("res://src/world/map_screen.tscn") as PackedScene).instantiate()
	tree.current_scene.add_child(map)
	var count := 0
	for node in map.find_children("RegionArt", "", true, false):
		count += 1
	t.expect_eq(count, 5, "one backdrop per region")
	tree.current_scene.remove_child(map)
	map.free()
