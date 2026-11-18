extends "res://src/world/slice.gd"

## Chapter 30: The Lions on the Road.
##
## A cart with lions crosses Quixote's path; he challenges them to fight.
## Part I, chapter 30. Region V: el_castillo_del_duque.

@onready var fragment_leones_carro = preload("res://assets/manifiesto/bk.ch30.leones_carro.01.json")

func _ready() -> void:
	super._ready()
	EventBus.toast.emit(&"ui.chapter.30.intro", [])
	GameState.chapter_started(&"ch_30_leones_carro")
	GameState.find_region(&"el_castillo_del_duque")

func _on_venture_resolved(_id: StringName, mode: int) -> void:
	super._on_venture_resolved(_id, mode)
	if _id == &"venture_leones_carro":
		if mode == VentureData.Resolution.TRUTH:
			EventBus.toast.emit(&"ui.chapter.30.truth", [])
		else:
			EventBus.toast.emit(&"ui.chapter.30.down", [])

