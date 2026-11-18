extends SceneTree
## Headless verification that the Venture second-pass art is live.

func _init() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene := load("res://src/world/forms/windmill_reality.tscn") as PackedScene
	var r := scene.instantiate()
	root.add_child(r)

	var tower := r.get_node("Tower") as MeshInstance3D
	print("TOWER_MATERIAL: ", "null" if tower.material_override == null else tower.material_override.get_class())
	print("CAP_PRESENT: ", r.get_node_or_null("Cap") != null)
	var sail := r.get_node("Sails/SailVertical") as MeshInstance3D
	print("SAIL_MESH_AFTER_READY: ", "null" if sail.mesh == null else "built")
	if sail.mesh != null:
		var a := sail.mesh.surface_get_arrays(0)
		print("SAIL_VERTICES: ", a[Mesh.ARRAY_VERTEX].size())

	var book := load("res://src/world/forms/windmill_book.tscn") as PackedScene
	var b := book.instantiate()
	root.add_child(b)
	var hand := b.get_node("ShoulderPivotLeft/SailHandLeft") as MeshInstance3D
	print("GIANT_SAIL_AFTER_READY: ", "null" if hand.mesh == null else "built")
	quit()
