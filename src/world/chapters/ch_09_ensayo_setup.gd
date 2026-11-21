extends "res://src/world/slice.gd"

## Chapter 9: The Ensayo — Setup.
##
## The player-staged case of trust. No combat, no venture.
## Region IV: los_riscos. The setup UI is shown over the slice.

const EnsayoUI = preload("res://src/ui/ensayo_ui.gd")

@onready var ensayo_script = preload("res://assets/ensayo/ensayo_script.json")
@onready var fragment_manuscrito = preload("res://assets/manifiesto/bk.ch09.manuscrito.01.json")

func _ready() -> void:
	super._ready()
	EventBus.toast.emit(&"ui.chapter.09.intro", [])
	GameState.chapter_started(&"ch_09_ensayo_setup")
	GameState.find_region(&"los_riscos")
	# A fresh campaign reaches this chapter in the setup phase; the player
	# chooses the four conditions. Arriving from a save may already be further
	# along — the UI renders whatever phase Ensayo is in.
	if Ensayo.state == "consequence" or Ensayo.setup.is_empty():
		Ensayo.reset()
	var ui := Control.new()
	ui.name = "EnsayoUI"
	ui.set_script(EnsayoUI)
	add_child(ui)
	ui.finished.connect(complete_ensayo)

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	super._on_venture_resolved(_id, mode)
	if _id == &"venture_montiel_reading":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.09.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.09.down", [])
