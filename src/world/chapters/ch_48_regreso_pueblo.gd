extends "res://src/world/slice.gd"

## Chapter 48: Return to the Village.
##
## Quixote and Sancho return home; Quixote begins to recover his senses.
## Part II, chapter 48 (approx). Region I: camino_la_mancha.

@onready var fragment_regreso_pueblo = preload("res://assets/manifiesto/bk.ch48.regreso_pueblo.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_48_regreso_pueblo")
	GameState.find_region(&"camino_la_mancha")

