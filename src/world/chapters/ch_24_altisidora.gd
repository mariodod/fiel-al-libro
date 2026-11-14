extends "res://src/world/slice.gd"

## Chapter 24: Altisidora.
##
## The lovesick maiden Altisidora sings and plays for Quixote.
## Part I, chapter 24. Region III: el_toboso.

@onready var fragment_altisidora = preload("res://assets/manifiesto/bk.ch24.altisidora.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_24_altisidora")
	GameState.find_region(&"el_toboso")


