extends "res://src/world/slice.gd"

## Chapter 12: The Magician.
##
## The speech on arms and letters.
## Part I, chapter 12. Region V: el_castillo_del_duque.

@onready var fragment_armas_letras = preload("res://assets/manifiesto/bk.ch12.armas_letras.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_12_magician")
	GameState.find_region(&"el_castillo_del_duque")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"venture_magician":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.12.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.12.down", [])

