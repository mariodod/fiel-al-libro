extends "res://src/world/slice.gd"

## Chapter 38: Clavileño.
##
## The enchanted wooden horse Clavileño carries Quixote and Sancho on a fake flight.
## Part I, chapter 38. Region IV: los_riscos.

@onready var fragment_clavileño = preload("res://assets/manifiesto/bk.ch38.clavileño.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_38_clavileño")
	GameState.find_region(&"los_riscos")

