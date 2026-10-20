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
## How long between the companion's remarks about what it is looking at.
@export var chatter_interval: float = 16.0
## How close a thing has to be for the companion to remark on it.
@export var chatter_range: float = 9.0

## Barks are picked from a pool so the companion never repeats itself
## immediately. Keyed by the character's id.
var _recent_barks: Dictionary = {}
var _bark_cooldown: float = 0.0
## How long until the companion says something about what it is looking at.
var _chatter_timer: float = 0.0
## The last thing the companion remarked on, so it does not say it twice.
var _last_thing: StringName = &""
## Which of the idle lines comes next.
var _idle_index: int = 0
## True while the leader is locked onto something, so the companion only
## remarks on it once.
var _leader_was_locked: bool = false

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
	EventBus.character_died.connect(_on_character_died)


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
	_update_chatter(delta)


func _maybe_bark() -> void:
	if _bark_cooldown > 0.0:
		return
	_bark_cooldown = 25.0
	var pool: Array[StringName] = BARK_KEYS if pawn.character_id == &"sancho" else QUIXOTE_BARK_KEYS
	if pool.is_empty():
		return
	var key: StringName = pool[randi() % pool.size()]
	# With the speaker attached, so the line reads as somebody talking and
	# not as a notification.
	EventBus.character_spoke.emit(pawn.character_id, key, [])


# ── The chatter ────────────────────────────────────────────────────────

## Say something about what you are looking at.
##
## The rule: **a line about the thing, or an idle line — never the same
## thing twice in a row.** It is the difference between a companion and
## a notification.
func _update_chatter(delta: float) -> void:
	_chatter_timer -= delta
	if _chatter_timer > 0.0:
		return
	_chatter_timer = chatter_interval

	# The player locked onto something. That is worth a remark, and it is
	# worth it once.
	var leader_locked := leader.is_locked()
	if leader_locked and not _leader_was_locked:
		_speak_about(Chatter.LOCKED)
	_leader_was_locked = leader_locked

	var thing := _thing_looking_at()
	if thing == _last_thing:
		# Nothing new. Say something that is not about the thing, so the
		# companion does not become a parrot.
		_speak_idle()
		return
	_last_thing = thing
	_speak_about(thing)


## The thing the companion is nearest to and looking at, or nothing.
func _thing_looking_at() -> StringName:
	var best: StringName = &""
	var best_distance := chatter_range
	for node in get_tree().get_nodes_in_group(Examine.GROUP):
		var object := node as TruthObject
		if object == null or object.data == null:
			continue
		var distance := object.global_position.distance_to(pawn.global_position)
		if distance < best_distance:
			best_distance = distance
			best = object.data.id
	# The dummy is not examinable, but it is very much worth a remark.
	var dummy := _nearest_dummy()
	if dummy != null:
		var dummy_distance := dummy.global_position.distance_to(pawn.global_position)
		if dummy_distance < best_distance:
			best = &"dummy"
	return best


func _nearest_dummy() -> TrainingDummy:
	var best: TrainingDummy = null
	var best_distance := chatter_range
	for node in get_tree().get_nodes_in_group(&"damageable"):
		var dummy := node as TrainingDummy
		if dummy == null:
			continue
		var distance := dummy.global_position.distance_to(pawn.global_position)
		if distance < best_distance:
			best_distance = distance
			best = dummy
	return best


## Say something about a thing.
func _speak_about(thing: StringName) -> void:
	if thing.is_empty():
		_speak_idle()
		return
	var key := Chatter.key_for(pawn.character_id, thing)
	if key.is_empty():
		_speak_idle()
		return
	EventBus.character_spoke.emit(pawn.character_id, key, [])


## Say something that is not about anything in particular.
func _speak_idle() -> void:
	var key := Chatter.idle_key(pawn.character_id, _idle_index)
	_idle_index = (_idle_index + 1) % Chatter.IDLE_POOL_SIZE
	EventBus.character_spoke.emit(pawn.character_id, key, [])


## The player went down. Say so.
func _on_character_died(character_id: StringName) -> void:
	if pawn == null or leader == null:
		return
	if leader.character_id != character_id:
		return
	_speak_about(Chatter.DOWN)
