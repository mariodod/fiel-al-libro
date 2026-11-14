extends "res://src/world/slice.gd"

## Chapter 33: The Lions at the Duke's Court.
##
## Two lions are brought to the Duke's castle; Quixote faces them.
## Part I, chapter 33. Region I: camino_la_mancha.

@onready var fragment_leones_reales = preload("res://assets/manifiesto/bk.ch33.leones_reales.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_33_leones_reales")
	GameState.find_region(&"camino_la_mancha")

