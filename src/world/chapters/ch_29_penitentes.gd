extends "res://src/world/slice.gd"

## Chapter 29: The Penitents in White.
##
## Quixote mistakes penitents for criminals and is beaten by their muleteers.
## Part I, chapter 29. Region V: el_castillo_del_duque.

@onready var fragment_penitentes = preload("res://assets/manifiesto/bk.ch29.penitentes.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_29_penitentes")
	GameState.find_region(&"el_castillo_del_duque")

