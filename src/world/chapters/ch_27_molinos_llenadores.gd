extends "res://src/world/slice.gd"

## Chapter 27: The Fulling Mills.
##
## Quixote mistakes the fulling mills for another enchantment.
## Part I, chapter 27. Region IV: los_riscos.

@onready var fragment_molinos_llenadores := preload("res://assets/manifiesto/bk.ch27.molinos_llenadores.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_27_molinos_llenadores")
	GameState.find_region(&"los_riscos")
