class_name CompanionAI
extends Node
## The companion driver.
##
## When you are playing Quixote, Sancho follows you, barks, panics, and
## occasionally solves something you can't. When you are playing Sancho,
## Quixote wanders off and tries to enforce chivalry on the local
## livestock.
##
## This is not a dummy. It is a character, and in single player it is a
## third of the game's personality. Budget real time for it.
##
## **And it fights.** The whole combat design of this game is that the
## player swaps mid-fight (GDD.md §7.2): one of the two of them does the
## killing and the other one does the controlling. That only means
## something if the companion is IN the fight, and not standing beside it
## watching.
##
## So the companion fights the target **you** are locked onto, swings on
## a rhythm rather than a frenzy, and catches a wind-up on its guard when
## it can. A parry staggers the attacker, and that is the companion's
## whole contribution: it opens the thing up for you to break.
##
## See GDD.md §5.3.

## The pawn this AI is currently driving.
var pawn: CharacterPawn = null
## The pawn the player is driving (so the AI can stay near them).
var leader: CharacterPawn = null
## The thing the companion is fighting, if any.
var target: Node3D = null

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
## How close the companion stands to the thing it is fighting. It has to
## be inside the reach of its own swing.
@export var fighting_distance: float = 2.1
## The shortest gap between two of the companion's swings.
@export var attack_gap_min: float = 0.9
## The longest.
@export var attack_gap_max: float = 1.9
## How likely the companion is to catch a wind-up on its guard rather
## than swing through it. Sancho's buckler can; a lance only holds.
@export var guard_chance: float = 0.75
## How long before the blow the companion raises its guard. It has to be
## inside the parry window, which is a quarter of a second.
@export var parry_lead: float = 0.12
## How long the companion holds its guard once it has raised it.
@export var guard_seconds: float = 0.55
## How close the companion has to be to pick the player up.
@export var lift_distance: float = 1.6
## How long the companion has to be there before the player is up again.
@export var revive_seconds: float = 1.2

## Barks are picked from a pool so the companion never repeats itself
## immediately. Keyed by the character's id.
var _recent_barks: Dictionary = {}
var _bark_cooldown: float = 0.0
## How long until the companion swings again.
var _attack_timer: float = 0.0
## How long the companion holds its guard.
var _guard_timer: float = 0.0
## True while the companion's guard is up.
var _blocking: bool = false
## The wind-up the companion has already weighed up, so it does not
## roll the dice on it twice.
var _guard_rolled: int = 0
## How long between the companion's remarks about what it is looking at.
var _chatter_timer: float = 0.0
## The last thing the companion remarked on, so it does not say it twice.
var _last_thing: StringName = &""
## Which of the idle lines comes next.
var _idle_index: int = 0
## True while the leader is locked onto something, so the companion only
## remarks on it once.
var _leader_was_locked: bool = false
## How long the companion has been standing over the downed player.
var _revive_timer: float = 0.0

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

	_attack_timer = maxf(0.0, _attack_timer - delta)
	_guard_timer = maxf(0.0, _guard_timer - delta)

	# The player is down. Go and pick them up.
	if leader.is_dead:
		_help_up(delta)
		_set_guard(false)
		return

	_pick_target()
	if target == null:
		_follow()
		_set_guard(false)
	else:
		_fight(delta)

	# TODO(Phase 1): barks keyed to what the companion is actually looking
	# at (an anamorphosis spotted, a Book-truth object, an enemy in range).
	_maybe_bark()
	_update_chatter(delta)


# ── The fight ──────────────────────────────────────────────────────────

## What the companion fights.
##
## The target the PLAYER is locked onto, first: the two of them are a
## team, and if you point, he hits it. With no lock, the nearest hostile
## it can reach.
func _pick_target() -> void:
	var wanted: Node3D = null
	if leader.is_locked():
		wanted = leader.lock_target as Node3D
	if wanted == null or not _is_hostile(wanted):
		wanted = _nearest_hostile()
	if wanted == target:
		return
	target = wanted
	_guard_rolled = 0
	# The companion faces what it is fighting, and so does its animation.
	if target != null:
		pawn.set_lock_target(target)
	else:
		pawn.clear_lock_target()


## The fight.
##
## The companion holds the reach of its own weapon and swings on a
## rhythm, and it catches the wind-up on its guard when it can. It does
## not circle: it stands its ground and swings, because a companion
## that strafes is a companion whose feet slide.
func _fight(delta: float) -> void:
	if target == null:
		return
	var to_target := target.global_position - pawn.global_position
	to_target.y = 0.0
	var distance := to_target.length()

	# The guard.
	#
	# It goes up JUST before the blow lands, because the parry window is
	# a quarter of a second and a wind-up is three times that: raise it
	# at the start of the wind-up and the parry has already closed.
	if _guard_timer > 0.0:
		_guard_timer = maxf(0.0, _guard_timer - delta)
		if _guard_timer <= 0.0:
			_set_guard(false)
	elif _blocking:
		_set_guard(false)
	# The dice are rolled once per wind-up, not once per target: a
	# companion that can only catch the first blow of a fight is not
	# catching anything.
	if not _is_winding_up(target):
		_guard_rolled = 0
	if _guard_timer <= 0.0 and _guard_rolled != target.get_instance_id():
		if _time_until_strike(target) <= parry_lead:
			_guard_rolled = target.get_instance_id()
			if randf() < guard_chance:
				_guard_timer = guard_seconds
				_set_guard(true)

	# The approach.
	#
	# Some things are not fought at arm's length: a Venture with turning
	# sails says so, and the companion believes it.
	var stand_off := fighting_distance
	if target.has_method("safe_distance"):
		stand_off = maxf(stand_off, float(target.call("safe_distance")))
	if distance > stand_off:
		pawn.move(Vector2(to_target.x, to_target.z).normalized(), false)
	else:
		# In the reach. Hold, and let the guard and the swing do the
		# work.
		pawn.move(Vector2.ZERO, false)

	# The swing.
	if _attack_timer <= 0.0 and _guard_timer <= 0.0 and distance <= fighting_distance + 0.9:
		_swing()


## The swing.
##
## On a rhythm, with a gap: the companion is a help, not a second player
## fighting over the same target.
func _swing() -> void:
	_attack_timer = randf_range(attack_gap_min, attack_gap_max)
	if pawn.data == null:
		return
	if randf() < 0.2 and pawn.data.heavy_attack != null:
		pawn.heavy_attack()
	elif pawn.data.light_attack != null:
		pawn.light_attack()


## The guard, up or down.
func _set_guard(up: bool) -> void:
	if _blocking == up:
		return
	_blocking = up
	pawn.block(up)


# ── Following ──────────────────────────────────────────────────────────

## Pick the player up.
##
## A character who is down is not out. The companion goes to them and
## stands there for a moment, and then they are up again. The playtest
## asked for it: *"when you have 0 hp you can still move it, you
## shouldn't be able to do that, your partner could help lift you."*
func _help_up(delta: float) -> void:
	var to_leader := leader.global_position - pawn.global_position
	to_leader.y = 0.0
	if to_leader.length() > lift_distance:
		_revive_timer = 0.0
		pawn.move(Vector2(to_leader.x, to_leader.z).normalized(), false)
		return
	# Close enough. Lift them.
	pawn.move(Vector2.ZERO, false)
	_revive_timer += delta
	if _revive_timer < revive_seconds:
		return
	_revive_timer = 0.0
	leader.revive()
	EventBus.character_spoke.emit(pawn.character_id, Chatter.key_for(pawn.character_id, &"revive"), [])


## No fight: stay near the player.
func _follow() -> void:
	var to_leader := leader.global_position - pawn.global_position
	to_leader.y = 0.0
	var distance := to_leader.length()
	if distance > follow_distance:
		var direction := Vector2(to_leader.x, to_leader.z).normalized()
		pawn.move(direction, distance > 12.0)
	elif distance < stop_distance:
		pawn.move(Vector2.ZERO, false)


# ── What counts as a target ─────────────────────────────────────────────

## The nearest thing worth hitting.
func _nearest_hostile() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(AttackHitbox.TARGET_GROUP):
		var candidate := node as Node3D
		if candidate == null or not _is_hostile(candidate):
			continue
		var distance := candidate.global_position.distance_to(pawn.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## Is this a thing worth hitting?
##
## The straw man in the corner is an INNOCENT: hitting it costs
## Humanity, and the companion is not going to do that on its own.
func _is_hostile(node: Node3D) -> bool:
	if node == null:
		return false
	if not ("faction" in node):
		return true
	return int(node.get("faction")) != Harm.Faction.INNOCENT


## Is this thing about to swing?
##
## The convention for a target: it says so before it hits. That is what
## makes a parry possible, and a parry is what makes the companion
## worth having.
func _is_winding_up(node: Node3D) -> bool:
	if node == null or not node.has_method("is_winding_up"):
		return false
	return bool(node.call("is_winding_up"))


## How long until this thing's blow lands.
##
## The parry window is a quarter of a second, so a guard raised at the
## start of a three-quarter-second wind-up has already closed by the
## time the blow arrives. The target says how long it has left, and the
## guard goes up inside the window.
func _time_until_strike(node: Node3D) -> float:
	if node == null or not node.has_method("time_until_strike"):
		return 99.0
	return float(node.call("time_until_strike"))


# ── The chatter ────────────────────────────────────────────────────────

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

	# The player locked onto something. That is worth a remark, and it
	# is worth it once.
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
