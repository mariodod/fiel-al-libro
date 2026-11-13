extends Node

func _ready() -> void:
	print("Loading slice.tscn...")
	var packed = load("res://src/world/slice.tscn")
	if packed == null:
		print("FAILED: slice.tscn is null")
	else:
		print("Loaded slice.tscn successfully")
		var scene = packed.instantiate()
		if scene == null:
			print("FAILED: instantiate returned null")
		else:
			print("Instantiated slice.tscn successfully")
			var tree = get_tree()
			if tree != null:
				tree.root.add_child(scene)
				print("Added to tree")
				print("All frames processed")
			else:
				print("FAILED: tree is null")
	get_tree().quit(0)
