extends "res://src/world/slice.gd"

## Chapter 42: Maestro Pedro's Puppet Show.
##
## Master Pedro performs his puppet show; Quixote attacks the Moors.
## Part II, chapter 42 (approx). Region V: el_castillo_del_duque.

@onready var fragment_maestro_pedro := preload("res://assets/manifiesto/bk.ch42.maestro_pedro.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_42_maestro_pedro")
	GameState.find_region(&"el_castillo_del_duque")
