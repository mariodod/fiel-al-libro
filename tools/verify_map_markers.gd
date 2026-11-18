extends SceneTree

func _init() -> void:
	call_deferred("_check")

func _check() -> void:
	var gs := root.get_node("GameState")
	gs.codex_pages.clear()
	gs.regions_found.clear()

	var scene := load("res://src/world/map_screen.tscn") as PackedScene
	var m := scene.instantiate()
	root.add_child(m)
	var container := m.find_child("MapContainer", true, false)

	gs.find_region(&"camino_la_mancha")
	gs.find_region(&"los_riscos")

	for child in container.get_children():
		if not child.name.begins_with("Marker_"):
			continue
		var alpha: float = child.color.a
		print(child.name, " alpha=", alpha, " -> ", "LIT" if alpha > 0.5 else "dark")
	print("CODEX: ", gs.codex_pages)
	quit()
