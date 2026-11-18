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
	var host := m.find_child("MapContainer", true, false)

	for title in ["Reality", "Book"]:
		var rect := m.find_child(title + "Rect", true, false) as TextureRect
		var mat := rect.material as ShaderMaterial
		print(title, "_SHADER: ", "yes" if mat != null else "no")
		if mat != null:
			print(title, "_TINT: ", mat.get_shader_parameter("tint"))
			print(title, "_SAT: ", mat.get_shader_parameter("saturation"))

	gs.find_region(&"camino_la_mancha")
	gs.find_region(&"los_riscos")
	var lit := 0
	for marker in host.find_children("Marker_*", "ColorRect", true, false):
		if marker.color.a > 0.5:
			lit += 1
	print("LIT_MARKERS: ", lit, " of ", host.find_children("Marker_*", "ColorRect", true, false).size())
	quit()
