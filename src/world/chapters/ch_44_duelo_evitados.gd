extends "res://src/world/slice.gd"

## Chapter 44: Duels Avoided.
##
## Quixote avoids fighting the Knight of the White Moon again.
## Part II, chapter 44 (approx). Region I: camino_la_mancha.

@onready var fragment_duelo_evitados := preload("res://assets/manifiesto/bk.ch44.duelo_evitados.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_44_duelo_evitados")
	GameState.find_region(&"camino_la_mancha")
