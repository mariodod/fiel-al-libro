extends "res://src/world/slice.gd"

## Chapter 1: The Windmills.
##
## Quixote's first adventure: the windmill that is a giant.
## Part I, chapters 7-8. Region I: camino_la_mancha.

@onready var fragment_apertura = preload("res://assets/manifiesto/bk.ch01.apertura.json")
@onready var fragment_molinos = preload("res://assets/manifiesto/bk.ch01.molinos.01.json")
@onready var fragment_nombre = preload("res://assets/manifiesto/bk.ch01.nombre.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_01_windmills")
	GameState.find_region(&"camino_la_mancha")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	_on_venture_resolved(_id, mode)
	if _id == &"venture_montiel":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.01.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.01.down", [])


