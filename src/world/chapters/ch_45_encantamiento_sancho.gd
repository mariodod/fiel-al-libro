extends "res://src/world/slice.gd"

## Chapter 45: Sancho Enchanted.
##
## Sancho is enchanted as part of the Dulcinea disenchantment scheme.
## Part II, chapter 45 (approx). Region I: camino_la_mancha.

@onready var fragment_encantamiento_sancho = preload("res://assets/manifiesto/bk.ch45.encantamiento_sancho.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_45_encantamiento_sancho")
	GameState.find_region(&"camino_la_mancha")


