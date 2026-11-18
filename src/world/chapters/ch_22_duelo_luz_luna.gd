extends "res://src/world/slice.gd"

## Chapter 22: The Moonlight Duel.
##
## Quixote fights the Knight of the Mirrors by moonlight.
## Part I, chapter 22. Region III: el_toboso.

@onready var fragment_duelo_luz_luna = preload("res://assets/manifiesto/bk.ch22.duelo_luz_luna.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_22_duelo_luz_luna")
	GameState.find_region(&"el_toboso")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	super._on_venture_resolved(_id, mode)
	if _id == &"venture_duelo_luz_luna":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.22.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.22.down", [])


