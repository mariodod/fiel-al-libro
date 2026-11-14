extends "res://src/world/slice.gd"

## Chapter 32: The Duke's Castle.
##
## Quixote and Sancho arrive at the Duke's castle and are welcomed as guests.
## Part I, chapter 32. Region I: camino_la_mancha.

@onready var fragment_ventura_duque = preload("res://assets/manifiesto/bk.ch32.ventura_duque.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_32_ventura_duque")
	GameState.find_region(&"camino_la_mancha")

