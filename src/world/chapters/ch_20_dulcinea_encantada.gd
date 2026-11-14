extends "res://src/world/slice.gd"

## Chapter 20: Dulcinea Enchanted.
##
## A peasant girl is passed off as Dulcinea enchanted; Quixote believes it.
## Part I, chapter 20. Region II: sierra_morena.

@onready var fragment_dulcinea_encantada = preload("res://assets/manifiesto/bk.ch20.dulcinea_encantada.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_20_dulcinea_encantada")
	GameState.find_region(&"sierra_morena")

