extends "res://src/world/slice.gd"

## Chapter 26: Melisendra's Puppet Show.
##
## Master Pedro's puppet show of Melisendra; Quixote attacks the puppets.
## Part I, chapter 26. Region IV: los_riscos.

@onready var fragment_melisendra := preload("res://assets/manifiesto/bk.ch26.melisendra.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_26_melisendra")
	GameState.find_region(&"los_riscos")
