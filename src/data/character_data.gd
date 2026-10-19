class_name CharacterData
extends Resource
## A character. Quixote, Sancho, or an NPC.

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var model_scene: PackedScene

@export_group("Vitals")
@export var max_stamina: float = 100.0
@export var poise: float = 30.0
@export var max_madness: float = 100.0

@export_group("Kit")
@export var light_attack: AbilityData
@export var heavy_attack: AbilityData
@export var dodge: AbilityData
@export var block: AbilityData
@export var abilities: Array[AbilityData] = []

@export_group("Identity")
## 0 = Reality-affinity, 1 = Book-affinity. See GDD.md §4.2.
@export_range(0, 1) var truth_layer_affinity: int = 0
## Can this character harm non-combatants? Quixote cannot, without cost.
@export var can_harm_innocents: bool = true
## How hard their AI companion version fights. 0 = passive, 1 = full.
@export_range(0.0, 1.0) var companion_aggression: float = 0.5
## Colour used by the manuscript ink and the UI tag.
@export var ink_color: Color = Color(0.25, 0.2, 0.16)


## Every ability this character has, flattened and de-duplicated.
func all_abilities() -> Array[AbilityData]:
	var out: Array[AbilityData] = []
	for a: AbilityData in [light_attack, heavy_attack, dodge, block]:
		if a != null:
			out.append(a)
	for a: AbilityData in abilities:
		if a != null:
			out.append(a)
	return out
