extends "res://src/world/slice.gd"

## Chapter 46: The Lions at Court.
##
## Lions are displayed at the Duke's court; Quixote observes them.
## Part II, chapter 46 (approx). Region I: camino_la_mancha.

@onready var fragment_leones_corte = preload("res://assets/manifiesto/bk.ch46.leones_corte.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_46_leones_corte")
	GameState.find_region(&"camino_la_mancha")

