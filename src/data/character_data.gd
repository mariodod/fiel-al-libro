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

@export_group("Defence")
## Can this character parry? Sancho's buckler can; Quixote's lance is
## a wide block and no parry at all. GDD.md §7.1.
@export var can_parry: bool = false
## How long after the guard goes up a parry still counts, in seconds.
@export var parry_window: float = 0.0
## How long a broken poise staggers the character, in seconds.
@export var stagger_seconds: float = 1.2
## How much of a blocked blow still gets through.
@export var block_damage_ratio: float = 0.15
## How long a character reels after a hit that was not blocked.
@export var hit_reaction_seconds: float = 0.3
## What it costs this character in Humanity to hit a thing that must not
## be harmed. D4: attacking an innocent costs Humanity.
@export var innocent_humanity_cost: int = 0
## How much damage this character does against an enemy. Sancho's is
## well under one: his kit is control, not killing. GDD.md §7.2.
@export var enemy_damage_scale: float = 1.0

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
