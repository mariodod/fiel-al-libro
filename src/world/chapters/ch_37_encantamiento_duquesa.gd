extends "res://src/world/slice.gd"

## Chapter 37: The Duchess's Enchantment.
##
## The Duchess pretends to be enchanted and enlists Sancho's help.
## Part I, chapter 37. Region IV: los_riscos.

@onready var fragment_encantamiento_duquesa = preload("res://assets/manifiesto/bk.ch37.encantamiento_duquesa.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_37_encantamiento_duquesa")
	GameState.find_region(&"los_riscos")


