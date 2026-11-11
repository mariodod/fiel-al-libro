extends "res://src/world/slice.gd"

## Chapter 6: The Bridge.
##
## Chrysostomus and Marcela among the goatherds.
## Part I, chapter 43. Region II: sierra_morena.

func _ready() -> void:
	._ready()
	GameState.chapter_started(&"ch_06_bridge")
	GameState.find_region(&"sierra_morena")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"venture_bridge":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.06.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.06.down", [])
