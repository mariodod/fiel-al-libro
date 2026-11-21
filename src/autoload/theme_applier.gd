extends Node
## Applies the project's custom theme at runtime. Setting it through an
## autoload is reliable in headless and exported builds, unlike the
## project.godot `gui/theme/custom` key which is not always read.

func _ready() -> void:
	var theme: Theme = load("res://assets/themes/default.tres")
	if theme != null:
		get_tree().root.theme = theme
