extends "res://src/world/slice.gd"

## Chapter 47: The Farewell.
##
## Quixote and Sancho bid farewell to the Duke and Duchess.
## Part II, chapter 47 (approx). Region I: camino_la_mancha.

@onready var fragment_despedida = preload("res://assets/manifiesto/bk.ch47.despedida.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_47_despedida")
	GameState.find_region(&"camino_la_mancha")

