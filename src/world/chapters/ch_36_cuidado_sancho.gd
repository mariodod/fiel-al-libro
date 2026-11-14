extends "res://src/world/slice.gd"

## Chapter 36: Sancho's Care.
##
## Sancho tends to Quixote's wounds after the defeat.
## Part I, chapter 36. Region II: sierra_morena.

@onready var fragment_cuidado_sancho = preload("res://assets/manifiesto/bk.ch36.cuidado_sancho.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_36_cuidado_sancho")
	GameState.find_region(&"sierra_morena")


