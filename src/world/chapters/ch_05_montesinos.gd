extends "res://src/world/slice.gd"

## Chapter 5: Montesinos.
##
## Dulcinea del Toboso is named. Non-combat venture.
## Part I, chapter 23. Region II: sierra_morena.

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_05_montesinos")
	GameState.find_region(&"sierra_morena")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"venture_montesinos":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.05.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.05.down", [])
