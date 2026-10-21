class_name FormData
extends Resource
## One of an enemy's two faces.

@export var display_name_key: StringName = &""
@export var model_scene: PackedScene

@export_group("Combat")
@export var max_health: float = 100.0
@export var poise: float = 30.0
@export var damage_multiplier: float = 1.0
## The moves this form has. Two forms, two movesets: that is what makes
## fighting a Venture in each form a different fight.
@export var moveset: Array[EnemyMoveData] = []

@export_group("Movement")
## How fast it walks towards you. Zero means it does not walk: the mill
## stands still and the ground it denies is the fight.
@export var move_speed: float = 0.0
## How fast it turns, in radians per second.
@export var turn_speed: float = 1.8
## How close it comes before it swings.
@export var engage_distance: float = 4.0

@export_group("Lore")
## Which truth this form belongs to, for the codex entry.
@export_range(0, 1) var truth_layer: int = 0
@export var codex_note_key: StringName = &""


## The Book form is stronger but its patterns are readable from the novel.
## The Reality form is smaller but has fewer moves and a different rhythm.
func is_book_form() -> bool:
	return truth_layer == 1
