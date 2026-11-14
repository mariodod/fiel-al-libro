extends "res://src/world/slice.gd"

## Chapter 14: The Galley Slaves.
##
## Quixote frees the galley slaves and is stoned by them for his trouble.
## Part I, chapter 14. Region I: camino_la_mancha.

@onready var fragment_galeotes := preload("res://assets/manifiesto/bk.ch14.galeotes.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_14_galeotes")
	GameState.find_region(&"camino_la_mancha")
