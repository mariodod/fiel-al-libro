extends "res://src/world/slice.gd"

## Chapter 28: Dulcinea Disenchanted.
##
## The curate's page (Tomás Cecial) pretends to disenchant Dulcinea.
## Part I, chapter 28. Region V: el_castillo_del_duque.

@onready var fragment_encantada = preload("res://assets/manifiesto/bk.ch28.encantada.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_28_encantada")
	GameState.find_region(&"el_castillo_del_duque")

