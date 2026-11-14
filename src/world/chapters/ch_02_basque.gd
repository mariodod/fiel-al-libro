extends "res://src/world/slice.gd"

## Chapter 2: The Basque.
##
## Quixote resolves to become a knight-errant.
## Part I, chapters 2-3. Region I: camino_la_mancha.

@onready var fragment_caballeros := preload("res://assets/manifiesto/bk.ch02.caballeros.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_02_basque")
	GameState.find_region(&"camino_la_mancha")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"venture_basque":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.02.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.02.down", [])
