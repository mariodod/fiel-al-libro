extends "res://src/world/slice.gd"

## Chapter 13: The Duke.
##
## Freeing the galley slaves.
## Part I, chapter 14. Region V: el_castillo_del_duque.

func _ready() -> void:
	._ready()
	GameState.chapter_started(&"ch_13_duke")
	GameState.find_region(&"el_castillo_del_duque")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"venture_duke":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.13.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.13.down", [])
