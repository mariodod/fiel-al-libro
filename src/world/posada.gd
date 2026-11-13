extends "res://src/world/slice.gd"

## The Posada — a location the player can return to.
##
## Checkpoint (save), the shelf (Biblioteca), two NPCs (innkeeper, musician).
## See NEXT_STEPS.md §2, task 2.16.

func _ready() -> void:
	._ready()
	GameState.chapter_started(&"ch_posada")
	GameState.find_region(&"camino_la_mancha")
