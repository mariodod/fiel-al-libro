extends "res://src/world/slice.gd"

## Chapter 7: Dulcinea.
##
## Quixote is beaten by Yanguesan carriers.
## Part I, chapter 7. Region III: el_toboso.

@onready var fragment_yanguesas := preload("res://assets/manifiesto/bk.ch07.yanguesas.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_07_dulcinea")
	GameState.find_region(&"el_toboso")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"venture_dulcinea":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.07.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.07.down", [])
