extends "res://src/world/slice.gd"

## Chapter 39: Sancho as Governor.
##
## Sancho takes up his governorship of the ínsula Barataria.
## Part I, chapter 39. Region IV: los_riscos.

@onready var fragment_sancho_gobernador = preload("res://assets/manifiesto/bk.ch39.sancho_gobernador.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_39_sancho_gobernador")
	GameState.find_region(&"los_riscos")

