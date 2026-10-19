class_name EnemyData
extends Resource
## An enemy. Most have TWO forms — a Book form and a Reality form — with
## different movesets, different rewards and different lore. Sancho's
## "Desvelar" strips the Book skin and swaps them mid-fight. That is the
## best-designed verb in the game (GDD.md §5.2, §7).

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var model_scene: PackedScene

@export_group("Vitals")
@export var max_health: float = 100.0
@export var poise: float = 30.0
@export var stamina: float = 100.0

@export_group("Forms")
@export var reality_form: FormData
@export var book_form: FormData

@export_group("Behaviour")
@export var is_boss: bool = false
@export var is_minion: bool = false
@export var aggro_radius: float = 12.0
@export var attack_range: float = 2.5

@export_group("Rewards")
@export var recuerdos: int = 50
@export var humanity_cost: int = 0


## The form this enemy currently wears.
func current_form() -> FormData:
	if TruthLayer.is_book() and book_form != null:
		return book_form
	return reality_form


## The form this enemy would wear in the other layer.
func other_form() -> FormData:
	if TruthLayer.is_book():
		return reality_form
	return book_form


func has_dual_forms() -> bool:
	return reality_form != null and book_form != null
