extends "res://src/world/slice.gd"

## Chapter 10: The Ensayo — Resolution.
##
## The consequence of the Ensayo test. No combat, no venture.
## Region IV: los_riscos.

func _ready() -> void:
	._ready()
	GameState.chapter_started(&"ch_10_ensayo_resolution")
	GameState.find_region(&"los_riscos")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"ensayo_resolution":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.10.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.10.down", [])
