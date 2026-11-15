extends "res://src/world/slice.gd"

## Chapter 14: The Galley Slaves.
##
## Quixote frees the galley slaves and is stoned by them for his trouble.
## Part I, chapter 14. Region I: camino_la_mancha.

@onready var fragment_galeotes = preload("res://assets/manifiesto/bk.ch14.galeotes.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_14_galeotes")
	GameState.find_region(&"camino_la_mancha")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	_on_venture_resolved(_id, mode)
	if _id == &"venture_galeotes":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.14.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.14.down", [])


