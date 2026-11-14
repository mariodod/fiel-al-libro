extends "res://src/world/slice.gd"

## Chapter 8: Celestina.
##
## No combat: a case of galimatias (confused speech).
## Part I. Region III: el_toboso.

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_08_celestina")
	GameState.find_region(&"el_toboso")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	_on_venture_resolved(_id, mode)
	if _id == &"galimatias":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.08.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.08.down", [])


