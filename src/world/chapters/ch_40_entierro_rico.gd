extends "res://src/world/slice.gd"

## Chapter 40: The Burial of the Rich Man.
##
## Quixote and Sancho come upon a rich man's burial procession.
## Part II, chapter 40 (approx). Region V: el_castillo_del_duque.

@onready var fragment_entierro_rico = preload("res://assets/manifiesto/bk.ch40.entierro_rico.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_40_entierro_rico")
	GameState.find_region(&"el_castillo_del_duque")


