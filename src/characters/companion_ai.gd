class_name CompanionAI
extends Node
## The companion driver.
##
## When you are playing Quixote, Sancho follows you, barks, panics, and
## occasionally solves something you can't. When you are playing Sancho,
## Quixote wanders off and tries to enforce chivalry on the local livestock.
##
## This is not a dummy. It is a character, and in single player it is a
## third of the game's personality. Budget real time for it.
##
## See GDD.md §5.3.

## The pawn this AI is currently driving.
var pawn: CharacterPawn = null
## The pawn the player is driving (so the AI can stay near them).
var leader: CharacterPawn = null

## How close the companion tries to stay.
@export var follow_distance: float = 3.5
## How close before it stops and waits.
@export var stop_distance: float = 2.0
## 0 = passive, 1 = fights like a player.
@export var aggression: float = 0.5

## Barks are picked from a pool so the companion never repeats itself
## immediately. Keyed by the character's id.
var _recent_barks: Dictionary = {}
var _bark_cooldown: float = 0.0

const BARK_KEYS: Array[StringName] = [
	&"dia.sancho.bark.001",
	&"dia.sancho.bark.002",
]
const QUIXOTE_BARK_KEYS: Array[StringName] = [
	&"dia.quixote.bark.001",
	&"dia.quixote.bark.002",
]


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if _bark_cooldown > 0.0:
		_bark_cooldown -= delta
	if pawn == null or leader == null or pawn.is_dead:
		return

	var to_leader := leader.global_position - pawn.global_position
	to_leader.y = 0.0
	var distance := to_leader.length()

	if distance > follow_distance:
		var direction := Vector2(to_leader.x, to_leader.z).normalized()
		pawn.move(direction, distance > 12.0)
	elif distance < stop_distance:
		pawn.move(Vector2.ZERO, false)

	# TODO(Phase 1): barks keyed to what the companion is actually looking
	# at (an anamorphosis spotted, a Book-truth object, an enemy in range).
	_maybe_bark()


func _maybe_bark() -> void:
	if _bark_cooldown > 0.0:
		return
	_bark_cooldown = 12.0
	var pool: Array[StringName] = BARK_KEYS if pawn.character_id == &"sancho" else QUIXOTE_BARK_KEYS
	if pool.is_empty():
		return
	var key: StringName = pool[randi() % pool.size()]
	EventBus.toast.emit(key, [])
