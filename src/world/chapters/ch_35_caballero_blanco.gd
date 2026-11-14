extends "res://src/world/slice.gd"

## Chapter 35: The Knight of the White Moon.
##
## A rival knight defeats Quixote in combat and sends him home for a year.
## Part I, chapter 35. Region II: sierra_morena.

@onready var fragment_caballero_blanco := preload("res://assets/manifiesto/bk.ch35.caballero_blanco.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_35_caballero_blanco")
	GameState.find_region(&"sierra_morena")
