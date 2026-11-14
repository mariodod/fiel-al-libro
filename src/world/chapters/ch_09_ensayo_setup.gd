extends "res://src/world/slice.gd"

## Chapter 9: The Ensayo — Setup.
##
## The player-staged case of trust. No combat, no venture.
## Region IV: los_riscos.

@onready var ensayo_script := preload("res://assets/ensayo/ensayo_script.json")
@onready var fragment_manuscrito := preload("res://assets/manifiesto/bk.ch09.manuscrito.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_09_ensayo_setup")
	GameState.find_region(&"los_riscos")
	# Begin the Ensayo setup phase once the slice is loaded.
	# Default setup: Quixote is tested by Sancho; the secret is the wife's name;
	# the tested is told. These can be overridden by player choice in the UI.
	Ensayo.start_setup(
		ensayo_script.get("setup.default_setup.tested", &"quixote"),
		ensayo_script.get("setup.default_setup.examiner", &"sancho"),
		ensayo_script.get("setup.default_setup.secret", &"wife_name"),
		ensayo_script.get("setup.default_setup.told", &"tested")
	)

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"ensayo_setup":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.09.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.09.down", [])
