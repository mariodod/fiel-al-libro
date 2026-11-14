extends "res://src/world/slice.gd"

## Chapter 10: The Ensayo — Resolution.
##
## The consequence of the Ensayo test. No combat, no venture.
## Region IV: los_riscos.

@onready var ensayo_script = preload("res://assets/ensayo/ensayo_script.json")
@onready var fragment_balsamo = preload("res://assets/manifiesto/bk.ch10.balsamo.01.json")

func _ready() -> void:
	super._ready()
	GameState.chapter_started(&"ch_10_ensayo_resolution")
	GameState.find_region(&"los_riscos")
	# Begin the Ensayo simulation phase with the setup carried from chapter 9.
	var setup := Ensayo.get_setup()
	if not setup.is_empty():
		Ensayo.start_simulation(
			setup.get("tested", &"quixote"),
			setup.get("examiner", &"sancho"),
			setup.get("secret", &"wife_name"),
			setup.get("told", &"tested")
		)
	else:
		# Fallback if chapter 9 was not played
		Ensayo.start_simulation(&"quixote", &"sancho", &"wife_name", &"tested")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	._on_venture_resolved(_id, mode)
	if _id == &"ensayo_resolution":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.10.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.10.down", [])

