extends "res://src/world/slice.gd"

## Chapter 25: The Countess Trifaldi.
##
## The Countess Trifaldi tells her tale of woe; Altisidora takes revenge.
## Part I, chapter 25. Region IV: los_riscos.

@onready var fragment_conde_altisidora = preload("res://assets/manifiesto/bk.ch25.conde_altisidora.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_25_conde_altisidora")
	GameState.find_region(&"los_riscos")


