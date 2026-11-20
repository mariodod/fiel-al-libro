extends "res://src/world/slice.gd"

## Chapter 9: The Ensayo — Setup.
##
## The player-staged case of trust. No combat, no venture.
## Region IV: los_riscos.

@onready var ensayo_script = preload("res://assets/ensayo/ensayo_script.json")
@onready var fragment_manuscrito = preload("res://assets/manifiesto/bk.ch09.manuscrito.01.json")

func _ready() -> void:
	super._ready()
	EventBus.toast.emit(&"ui.chapter.09.intro", [])
	GameState.chapter_started(&"ch_09_ensayo_setup")
	GameState.find_region(&"los_riscos")
	# Begin the Ensayo setup phase once the slice is loaded.
	# Default setup: Quixote is tested by Sancho; the secret is the wife's name;
	# the tested is told. These can be overridden by player choice in the UI.
	# A preloaded .json is a JSON Resource: its parsed content lives in .data.
	# Dictionary.get() takes one key, and the keys are nested, not dot paths.
	var defaults: Dictionary = {}
	if ensayo_script.data is Dictionary:
		var setup_section: Variant = (ensayo_script.data as Dictionary).get("setup", {})
		if setup_section is Dictionary:
			var section: Variant = (setup_section as Dictionary).get("default_setup", {})
			if section is Dictionary:
				defaults = section
	Ensayo.start_setup(
		StringName(str(defaults.get("tested", "quixote"))),
		StringName(str(defaults.get("examiner", "sancho"))),
		StringName(str(defaults.get("secret", "wife_name"))),
		StringName(str(defaults.get("told", "tested")))
	)

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	super._on_venture_resolved(_id, mode)
	if _id == &"ensayo_setup":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.09.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.09.down", [])


