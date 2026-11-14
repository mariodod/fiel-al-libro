extends "res://src/world/slice.gd"

## Chapter 41: Oviedo's False Book.
##
## The canon and Quixote discuss the false sequel by Oviedo.
## Part II, chapter 42 (approx). Region V: el_castillo_del_duque.

@onready var fragment_oviedo := preload("res://assets/manifiesto/bk.ch41.oviedo.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_41_oviedo")
	GameState.find_region(&"el_castillo_del_duque")
