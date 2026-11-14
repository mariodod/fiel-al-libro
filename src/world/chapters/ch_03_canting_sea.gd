extends "res://src/world/slice.gd"

## Chapter 3: The Canting Sea.
##
## Quixote dubbed a knight at the inn.
## Part I, chapter 3. Region I: camino_la_mancha.

@onready var fragment_posada = preload("res://assets/manifiesto/bk.ch03.posada.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_03_canting_sea")
	GameState.find_region(&"camino_la_mancha")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	_on_venture_resolved(_id, mode)
	if _id == &"venture_canting_sea":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.03.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.03.down", [])


