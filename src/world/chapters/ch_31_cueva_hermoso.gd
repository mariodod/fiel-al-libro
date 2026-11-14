extends "res://src/world/slice.gd"

## Chapter 31: Return to the Cave of Montesinos.
##
## Quixote revisits the cave where he had his vision of Montesinos.
## Part I, chapter 31. Region I: camino_la_mancha.

@onready var fragment_cueva_hermoso = preload("res://assets/manifiesto/bk.ch31.cueva_hermoso.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_31_cueva_hermoso")
	GameState.find_region(&"camino_la_mancha")

