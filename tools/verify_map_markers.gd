extends SceneTree

func _init() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene := load("res://src/world/map_screen.tscn") as PackedScene
	var m := scene.instantiate()
	root.add_child(m)
	var container := m.find_child("MapContainer", true, false)
	if container == null:
		print("MAP_CONTAINER: missing")
		quit()
		return
	var expected := {
		"Marker_bk_ch01_apertura": Vector2(310, 180),
		"Marker_bk_ch04_rocinante_01": Vector2(305, 216),
		"Marker_bk_ch07_yanguesas_01": Vector2(250, 199),
		"Marker_bk_ch09_manuscrito_01": Vector2(422, 126),
		"Marker_bk_ch11_caballero_bosque_01": Vector2(436, 161),
	}
	var count := 0
	for marker in container.get_children():
		if not marker.name.begins_with("Marker_"):
			continue
		count += 1
		var pos: Vector2 = marker.position
		var want: Vector2 = expected.get(marker.name, Vector2(300, 200))
		print(marker.name, " -> ", pos, " (expected ", want, ")")
	print("MARKERS: ", count)
	quit()
