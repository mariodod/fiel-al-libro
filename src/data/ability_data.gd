class_name AbilityData
extends Resource
## One verb. Every ability in the game is an instance of this.

enum Kind {
	LIGHT,      ## fast, low commitment
	HEAVY,      ## slow, high poise damage, breaks guard
	DODGE,      ## i-frames
	BLOCK,      ## guard; some can parry
	ACTIVE,     ## anything with a cooldown
	PASSIVE,    ## a trait
}

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var description_key: StringName = &""
@export var kind: Kind = Kind.ACTIVE

@export_group("Cost")
@export var stamina_cost: float = 0.0
@export var cooldown: float = 0.0
## For dodges: how long the invulnerability lasts. GDD.md §7.1 says 0.4s.
## The dodge burst lasts the same time — you are moving for as long as
## you cannot be hit.
@export var iframe_seconds: float = 0.0
## For dodges: how far the roll carries you, in metres.
##
## The second playtest asked for less distance, and for the two of them
## to be different: *Sancho's roll should be half the distance, and
## Quixote's invulnerability should be shorter, because he is not a
## fighter.* So the distance is data, and the speed follows from it:
## a dodge carries you this far over the window you are safe for.
@export var roll_distance: float = 0.0

@export_group("Damage")
@export var damage: float = 10.0
@export var poise_damage: float = 10.0
@export var reach: float = 2.0
## For sweeping arcs: half-angle in degrees.
@export var arc_degrees: float = 60.0
## How long the hitbox is live, in seconds. The window in which the
## swing can actually connect.
@export var active_seconds: float = 0.12

@export_group("Gating")
## Which truth layer this ability functions in. 0 = Reality only, 1 = Book only,
## -1 = both. See GDD.md §8.3 — the build axis.
@export_range(-1, 1) var truth_layer: int = -1
## Minimum Locura required (0-100). -1 = always available.
@export_range(-1, 100) var min_locura: int = -1
## Minimum milestone index required.
@export var min_milestone: int = 0


func available_in_layer(layer: int) -> bool:
	return truth_layer == -1 or truth_layer == layer


func available_at_locura(value: float) -> bool:
	return min_locura == -1 or value >= float(min_locura)
