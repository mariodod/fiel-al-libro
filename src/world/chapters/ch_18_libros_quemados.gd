extends "res://src/world/slice.gd"

## Chapter 18: The Bonfire of Books.
##
## The curate and the barber burn Quixote's chivalry books in a bonfire.
## Part I, chapter 18. Region II: sierra_morena.

@onready var fragment_libros_quemados = preload("res://assets/manifiesto/bk.ch18.libros_quemados.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_18_libros_quemados")
	GameState.find_region(&"sierra_morena")

