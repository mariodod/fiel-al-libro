extends "res://src/world/slice.gd"

## Chapter 17: The Dead Man on the Road (Part Two).
##
## Another dead body; Quixote wants to avenge him, Sancho warns him off.
## Part I, chapter 17. Region II: sierra_morena.

@onready var fragment_hombre_muerto = preload("res://assets/manifiesto/bk.ch17.hombre_muerto.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_17_hombre_muerto")
	GameState.find_region(&"sierra_morena")

