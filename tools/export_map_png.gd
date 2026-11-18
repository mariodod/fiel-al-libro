extends SceneTree

func _init() -> void:
	call_deferred("_check")

func _check() -> void:
	var tex := load("res://docs/map/world_map.svg") as Texture2D
	if tex == null:
		print("SVG_LOAD: failed")
		quit()
		return
	var img := tex.get_image()
	if img == null:
		print("IMAGE: failed")
		quit()
		return
	img.save_png("res://assets/maps/world_map.png")
	print("PNG: ", img.get_width(), "x", img.get_height())
	quit()
