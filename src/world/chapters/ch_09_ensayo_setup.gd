extends "res://src/world/slice.gd"

## Chapter 9: The Ensayo — Setup.
##
## The player-staged case of trust. No combat, no venture.
## Region IV: los_riscos.

func _ready() -> void:
	._ready()
	GameState.chapter_started(&"ch_09_ensayo_setup")
	GameState.find_region(&"los_riscos")
	# Begin the Ensayo setup phase once the slice is loaded.
	Ensayo.start_setup(&"quixote", &"sancho", &"wife_name", &"tested")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"ensayo_setup":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.09.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.09.down", [])
