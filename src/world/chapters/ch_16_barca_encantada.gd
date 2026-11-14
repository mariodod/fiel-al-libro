extends "res://src/world/slice.gd"

## Chapter 16: The Enchanted Boat.
##
## Quixote tries to board an enchanted boat on the river; Sancho stops him.
## Part I, chapter 16. Region I: camino_la_mancha.

@onready var fragment_barca_encantada = preload("res://assets/manifiesto/bk.ch16.barca_encantada.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_16_barca_encantada")
	GameState.find_region(&"camino_la_mancha")

