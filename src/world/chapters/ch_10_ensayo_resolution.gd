extends "res://src/world/slice.gd"

## Chapter 10: The Ensayo — Simulation and consequence.
## No combat, no venture. Region IV: los_riscos.

const EnsayoUI = preload("res://src/ui/ensayo_ui.gd")

@onready var ensayo_script = preload("res://assets/ensayo/ensayo_script.json")
@onready var fragment_balsamo = preload("res://assets/manifiesto/bk.ch10.balsamo.01.json")

func _ready() -> void:
	super._ready()
	EventBus.toast.emit(&"ui.chapter.10.intro", [])
	GameState.chapter_started(&"ch_10_ensayo_resolution")
	GameState.find_region(&"los_riscos")
	# Carry the setup staged in chapter 9 into the simulation. If the player
	# reached this chapter directly (continue/save), use the authored defaults.
	if Ensayo.state == "setup":
		var defaults: Dictionary = {}
		if ensayo_script.data is Dictionary:
			var setup_section: Variant = (ensayo_script.data as Dictionary).get("setup", {})
			if setup_section is Dictionary:
				var section: Variant = (setup_section as Dictionary).get("default_setup", {})
				if section is Dictionary:
					defaults = section
		var s := Ensayo.get_setup()
		Ensayo.start_simulation(
			s.get("tested", StringName(str(defaults.get("tested", "quixote")))),
			s.get("examiner", StringName(str(defaults.get("examiner", "sancho")))),
			s.get("secret", StringName(str(defaults.get("secret", "wife_name")))),
			s.get("told", StringName(str(defaults.get("told", "tested"))))
		)
	var ui := Control.new()
	ui.name = "EnsayoUI"
	ui.set_script(EnsayoUI)
	add_child(ui)
	ui.finished.connect(complete_ensayo)

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	super._on_venture_resolved(_id, mode)
	if _id == &"ensayo_resolution":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.10.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.10.down", [])
