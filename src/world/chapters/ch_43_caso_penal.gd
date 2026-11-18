extends "res://src/world/slice.gd"

## Chapter 43: The Criminal Case.
##
## A criminal case is brought before the Duke; Quixote judges it.
## Part II, chapter 43 (approx). Region I: camino_la_mancha.

@onready var fragment_caso_penal = preload("res://assets/manifiesto/bk.ch43.caso_penal.01.json")

func _ready() -> void:
	super._ready()
	EventBus.toast.emit(&"ui.chapter.43.intro", [])
	GameState.chapter_started(&"ch_43_caso_penal")
	GameState.find_region(&"camino_la_mancha")


