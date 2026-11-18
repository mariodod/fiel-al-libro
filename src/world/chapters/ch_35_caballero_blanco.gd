extends "res://src/world/slice.gd"

## Chapter 35: The Knight of the White Moon.
##
## A rival knight defeats Quixote in combat and sends him home for a year.
## Part I, chapter 35. Region II: sierra_morena.

@onready var fragment_caballero_blanco = preload("res://assets/manifiesto/bk.ch35.caballero_blanco.01.json")

func _ready() -> void:
	super._ready()
	EventBus.toast.emit(&"ui.chapter.35.intro", [])
	GameState.chapter_started(&"ch_35_caballero_blanco")
	GameState.find_region(&"sierra_morena")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	super._on_venture_resolved(_id, mode)
	if _id == &"venture_caballero_blanco":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.35.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.35.down", [])

