extends "res://src/world/slice.gd"

## Chapter 22: The Moonlight Duel.
##
## Quixote fights the Knight of the Mirrors by moonlight.
## Part I, chapter 22. Region III: el_toboso.

@onready var fragment_duelo_luz_luna = preload("res://assets/manifiesto/bk.ch22.duelo_luz_luna.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_22_duelo_luz_luna")
	GameState.find_region(&"el_toboso")

