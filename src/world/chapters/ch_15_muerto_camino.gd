extends "res://src/world/slice.gd"

## Chapter 15: The Dead Man on the Road.
##
## Quixote finds a murdered man and tries to make justice, but Sancho talks him out of it.
## Part I, chapter 15. Region I: camino_la_mancha.

@onready var fragment_muerto_camino = preload("res://assets/manifiesto/bk.ch15.muerto_camino.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_15_muerto_camino")
	GameState.find_region(&"camino_la_mancha")


