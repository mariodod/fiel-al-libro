class_name PassiveData
extends Resource
## One passive trait granted by an equipped book.
##
## Passives are flat stat modifiers applied to whichever CharacterPawn
## is driving while the book is on the shelf. They stack additively
## (flat bonuses) and multiplicatively (percent bonuses) across all
## equipped books, so the shelf IS your build (GDD.md §8.2).
##
## See GDD.md §8.2 "The empty bookshelf — your loadout IS your collection".

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var description_key: StringName = &""

@export_group("Vitals")
## Flat bonus to maximum health.
@export var health_bonus: float = 0.0
## Multiplier on maximum health (1.0 = no change).
@export var health_percent: float = 1.0
## Flat bonus to maximum stamina.
@export var stamina_bonus: float = 0.0
## Multiplier on maximum stamina.
@export var stamina_percent: float = 1.0
## Flat bonus to maximum poise.
@export var poise_bonus: float = 0.0

@export_group("Movement")
## Multiplier on walk and run speed (1.0 = no change).
@export var speed_percent: float = 1.0
## Multiplier on dodge distance (1.0 = no change).
@export var dodge_distance_percent: float = 1.0
## Multiplier on dodge invulnerability window (1.0 = no change).
@export var dodge_iframe_percent: float = 1.0

@export_group("Combat")
## Multiplier on all damage dealt (1.0 = no change).
@export var damage_percent: float = 1.0
## Multiplier on blocked damage ratio (1.0 = no change — higher = less gets through).
@export var block_ratio_percent: float = 1.0
## Flat bonus to parry window, in seconds.
@export var parry_window_bonus: float = 0.0

@export_group("Mind")
## Locura drained per second while this passive is active (negative = drains, positive = gains).
## GDD.md: "La Tinta — slowly drains Locura" would be a negative value here.
@export var locura_per_second: float = 0.0
