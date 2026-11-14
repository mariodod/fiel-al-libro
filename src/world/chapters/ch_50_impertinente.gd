extends "res://src/world/slice.gd"

## Chapter 50: The Curious Impertinent.
##
## The interpolated tale of the Curious Impertinent, from Part I.
## Part I, chapters 48-52 (interpolated tale). Region I: camino_la_mancha.

@onready var fragment_impertinente := preload("res://assets/manifiesto/bk.ch50.impertinente.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_50_impertinente")
	GameState.find_region(&"camino_la_mancha")
