extends "res://src/world/slice.gd"

## Chapter 34: The Enchantment.
##
## The Countess Trifaldi's tale leads to the Clavileño adventure.
## Part I, chapter 34. Region II: sierra_morena.

@onready var fragment_encantamiento = preload("res://assets/manifiesto/bk.ch34.encantamiento.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_34_encantamiento")
	GameState.find_region(&"sierra_morena")


