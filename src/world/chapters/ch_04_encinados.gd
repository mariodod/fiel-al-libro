extends "res://src/world/slice.gd"

## Chapter 4: The Encinados.
##
## Rocinante is named.
## Part I. Region II: sierra_morena.

@onready var fragment_rocinante := preload("res://assets/manifiesto/bk.ch04.rocinante.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_04_encinados")
	GameState.find_region(&"sierra_morena")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"venture_encinados":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.04.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.04.down", [])
