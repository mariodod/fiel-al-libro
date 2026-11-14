extends "res://src/world/slice.gd"

## Chapter 11: Knight of the Mirrors.
##
## The moonlight duel with the Knight of the Mirrors.
## Part I, chapter 22. Region V: el_castillo_del_duque.

@onready var fragment_caballero_bosque = preload("res://assets/manifiesto/bk.ch11.caballero_bosque.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_11_mirrors")
	GameState.find_region(&"el_castillo_del_duque")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	_on_venture_resolved(_id, mode)
	if _id == &"venture_mirrors":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.11.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.11.down", [])


