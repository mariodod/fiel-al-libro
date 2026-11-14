extends "res://src/world/slice.gd"

## Chapter 30: The Lions on the Road.
##
## A cart with lions crosses Quixote's path; he challenges them to fight.
## Part I, chapter 30. Region V: el_castillo_del_duque.

@onready var fragment_leones_carro := preload("res://assets/manifiesto/bk.ch30.leones_carro.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_30_leones_carro")
	GameState.find_region(&"el_castillo_del_duque")
