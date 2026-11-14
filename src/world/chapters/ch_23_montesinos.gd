extends "res://src/world/slice.gd"

## Chapter 23: The Cave of Montesinos.
##
## Quixote descends into the Cave of Montesinos and returns with a tale.
## Part I, chapter 23. Region III: el_toboso.

@onready var fragment_montesinos := preload("res://assets/manifiesto/bk.ch23.montesinos.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_23_montesinos")
	GameState.find_region(&"el_toboso")
