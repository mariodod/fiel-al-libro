class_name CharacterPawn
extends CharacterBody3D
## The ONLY way to touch a character in this game.
##
## D3: the player swaps between Quixote and Sancho; the other one is a full
## AI companion. A second player, in co-op, simply claims the pawn the AI
## was driving. That means the character-switch system and the co-op system
## are the same system — and co-op is a networking problem later, not a
## redesign now.
##
## The `driver` property is the whole trick. A driver is anything that can
## call move/attack/dodge. PlayerController is one. CompanionAI is another.
##
## See GDD.md §5.3 and TECH_STACK.md §3.3.

signal died(character_id: StringName)
signal damaged(amount: float)

@export var data: CharacterData

## Whoever is currently driving this pawn.
var driver: Node = null
## The pawn the player is NOT currently driving. Lives on the same map.
var companion: CharacterPawn = null

var character_id: StringName = &""
var health: float = 100.0
var max_health: float = 100.0
var stamina: float = 100.0
## The size of the stamina pool. It comes from the data — Sancho has more
## of it than Quixote, and until now the pawn did not know that.
var max_stamina: float = 100.0
var is_dead: bool = false

## The truth this pawn currently perceives. Quixote sees the Book; Sancho
## sees Reality. Set by the driver.
var perceived_layer: int = 0

## The thing this character is locked onto, if any.
##
## While it is locked, the character faces the target and moves around
## it, and the camera frames both. It is a soft lock: the target is the
## one you are LOOKING at, and the lock is given up when the target
## leaves the fight.
var lock_target: Node3D = null

## The second sight: the lens that lets Sancho see the Book.
##
## In the full game this is an ability and an item you find. In the slice it
## is a key, because the slice exists to show the disagreement between the
## two readings, and the disagreement needs a switch.
var second_sight: bool = false

const GRAVITY := 18.0
const WALK_SPEED := 4.2
const RUN_SPEED := 6.8
const ACCELERATION := 12.0
const FRICTION := 14.0
const TURN_SPEED := 8.0

## How fast a dodge throws you, in metres per second. Faster than a
## sprint: that is the point of it.
##
## This is only the FALLBACK, for a dodge whose data does not say how far
## it carries you. A dodge that does say travels at whatever speed that
## distance needs over the window you are safe for — see
## `_dodge_speed_for()`.
const DODGE_SPEED := 15.0
## How long before the stamina comes back, after the last thing you spent
## it on. GDD.md §7.1: "Shared pool, regenerates after 1s idle".
const STAMINA_REGEN_DELAY := 1.0
## Stamina per second, once it starts coming back.
const STAMINA_REGEN := 28.0

## The direction the player asked to move in, last frame. The dodge is
## directional (GDD.md §7.1), so it needs to know.
var _input_direction: Vector2 = Vector2.ZERO
## Seconds left of the dodge burst.
var _dodge_time: float = 0.0
## Seconds left before you can dodge again.
var _dodge_cooldown: float = 0.0
## Seconds left before you can swing again. A weapon has a rhythm, and
## the rhythm is what makes the dodge a decision.
var _attack_cooldown: float = 0.0
## Seconds left during which damage does nothing.
var _iframe_time: float = 0.0
## Seconds left before the stamina starts coming back.
var _stamina_delay: float = 0.0
## The direction of the current dodge.
var _dodge_direction: Vector3 = Vector3.FORWARD
## How fast the current dodge throws you. Read from the ability.
var _dodge_speed: float = DODGE_SPEED
## True while the dodge burst is running.
var _dodging: bool = false


func _ready() -> void:
	if data != null:
		character_id = data.id
		max_health = 100.0
		max_stamina = data.max_stamina
		stamina = data.max_stamina
	perceived_layer = Perception.reading_for(character_id, TruthLayer.layer(), second_sight)
	add_to_group(&"pawns")
	EventBus.player_spawned.emit(self)


## ── The driver interface ────────────────────────────────────────────────
## A driver calls these. A pawn never calls them on itself.

func move(input_direction: Vector2, sprint: bool) -> void:
	var input := Vector3(input_direction.x, 0.0, input_direction.y)
	_input_direction = input_direction
	var speed := RUN_SPEED if sprint else WALK_SPEED
	var target := input.normalized() * speed

	velocity.x = move_toward(velocity.x, target.x, ACCELERATION * get_process_delta_time())
	velocity.z = move_toward(velocity.z, target.z, ACCELERATION * get_process_delta_time())

	if lock_target != null and is_instance_valid(lock_target):
		# Locked on: the character faces the target, and the input moves
		# it around the target rather than away from it. This is the
		# difference between fighting and running about.
		_turn_towards(_flat_direction_to(lock_target))
	elif input.length_squared() > 0.001:
		var facing := Vector3(input_direction.x, 0.0, input_direction.y).normalized()
		_turn_towards(facing)


## The direction to a point, flat on the ground.
func _flat_direction_to(node: Node3D) -> Vector3:
	var to_node := node.global_position - global_position
	to_node.y = 0.0
	if to_node.length_squared() < 0.0001:
		return -global_transform.basis.z
	return to_node.normalized()


## Turn towards a direction, at a rate a person can follow.
##
## The character used to snap to face its movement direction with
## look_at(). A snap is what makes the camera whip sideways, so the turn is
## rate-limited here and the camera smooths its own yaw on top of it.
func _turn_towards(direction: Vector3) -> void:
	# The node faces -Z, so facing `direction` means this yaw.
	var desired := atan2(-direction.x, -direction.z)
	var diff := wrapf(desired - rotation.y, -PI, PI)
	var step := TURN_SPEED * get_process_delta_time()
	rotation.y += clampf(diff, -step, step)


func dodge() -> void:
	if is_dead or _dodge_cooldown > 0.0:
		return
	if data == null or data.dodge == null:
		return
	if not _perform(data.dodge):
		return

	# Directional: where you were going, or where you are facing.
	var direction := Vector3(_input_direction.x, 0.0, _input_direction.y)
	if direction.length_squared() < 0.001:
		direction = -global_transform.basis.z
	_dodge_direction = direction.normalized()
	_dodge_time = data.dodge.iframe_seconds
	_iframe_time = data.dodge.iframe_seconds
	_dodge_cooldown = data.dodge.cooldown
	_dodge_speed = _dodge_speed_for(data.dodge)


## How fast this dodge throws the character.
##
## A dodge that says how far it carries you travels at the speed that
## distance needs over the window you are safe for: you move for as long
## as you cannot be hit, and how far that is depends on the character.
##
## Quixote scrambles four metres and is safe for a quarter of a second.
## Sancho rolls two — half of it — and is safe for twice as long, which
## is the difference between a fighter and a man with a buckler.
func _dodge_speed_for(ability: AbilityData) -> float:
	if ability.roll_distance > 0.0 and ability.iframe_seconds > 0.0:
		return ability.roll_distance / ability.iframe_seconds
	return DODGE_SPEED


func light_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	if data != null and data.light_attack != null:
		_perform(data.light_attack)


func heavy_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	if data != null and data.heavy_attack != null:
		_perform(data.heavy_attack)


func block(_held: bool) -> void:
	pass


func ability(ability_id: StringName) -> bool:
	if data == null:
		return false
	for a: AbilityData in data.abilities:
		if a.id == ability_id:
			_perform(a)
			return true
	return false


## ── The pawn's own logic ────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_dodge_time = maxf(0.0, _dodge_time - delta)
	_dodge_cooldown = maxf(0.0, _dodge_cooldown - delta)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_iframe_time = maxf(0.0, _iframe_time - delta)

	# The stamina comes back once you stop spending it. It did not come
	# back at all before: nothing in the build restored it, so the second
	# dodge of a run was the last one.
	_stamina_delay = maxf(0.0, _stamina_delay - delta)
	if _stamina_delay <= 0.0 and stamina < max_stamina:
		stamina = minf(max_stamina, stamina + STAMINA_REGEN * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# The dodge overrides the walking velocity: for a moment you are not
	# walking, you are being thrown.
	if _dodge_time > 0.0:
		velocity.x = _dodge_direction.x * _dodge_speed
		velocity.z = _dodge_direction.z * _dodge_speed
		_dodging = true
	elif _dodging:
		# A dodge ends with your feet planted, not with a slide. The
		# friction alone would leave you coasting for over a second.
		_dodging = false
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()


## Run an ability. Returns whether it actually went off.
##
## The gating is the asymmetry (GDD.md §8.3): which truth the ability
## works in, how mad you have to be, and what it costs.
func _perform(ability: AbilityData) -> bool:
	if ability == null or is_dead:
		return false
	# Gating: layer and madness. This is how "Book builds" and "Reality
	# builds" differ (GDD.md §8.3).
	if not ability.available_in_layer(TruthLayer.layer()):
		return false
	if not ability.available_at_locura(Locura.get_for(character_id)):
		return false
	if not Memoria.has_milestone(character_id, ability.min_milestone):
		return false
	if stamina < ability.stamina_cost:
		return false
	stamina -= ability.stamina_cost
	_stamina_delay = STAMINA_REGEN_DELAY
	# A swing puts a hitbox in front of the character. It is the crudest
	# possible version of a combat hitbox (task 2.6 does the real one),
	# and it exists so that the training dummy can be hit: a dodge with
	# nothing to dodge against, and nothing to hit, cannot be judged.
	if ability.kind == AbilityData.Kind.LIGHT or ability.kind == AbilityData.Kind.HEAVY:
		_swing(ability)
	return true


## The swing itself: a hitbox in front of the character, and the rhythm
## that keeps the next one from coming straight away.
func _swing(ability: AbilityData) -> void:
	_attack_cooldown = maxf(_attack_cooldown, ability.cooldown)
	AttackHitbox.swing(self, ability)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	# The i-frames. This is the whole point of a dodge.
	if _iframe_time > 0.0:
		return
	health -= amount
	damaged.emit(amount)
	if health <= 0.0:
		health = 0.0
		_die()


func _die() -> void:
	is_dead = true
	died.emit(character_id)
	EventBus.character_died.emit(character_id)


func revive() -> void:
	is_dead = false
	health = max_health
	stamina = data.max_stamina if data != null else 100.0
	EventBus.character_revived.emit(character_id)


## Can this pawn perceive a given truth? Quixote cannot, while he is deep in
## his madness. See GDD.md §4.2.
func can_perceive(layer: int) -> bool:
	return Perception.can_perceive(character_id, layer, second_sight)


## Lock onto a thing.
func set_lock_target(target: Node3D) -> void:
	lock_target = target


## Let go of it.
func clear_lock_target() -> void:
	lock_target = null


## Is this character locked onto something?
func is_locked() -> bool:
	return lock_target != null and is_instance_valid(lock_target)


## How far this character's dodge carries them, in metres.
##
## The number the playtest judges. It is data, and it is different for
## the two of them.
func roll_distance() -> float:
	if data == null or data.dodge == null:
		return 0.0
	return data.dodge.roll_distance


## How long this character is untouchable after a dodge, in seconds.
func invulnerability_seconds() -> float:
	if data == null or data.dodge == null:
		return 0.0
	return data.dodge.iframe_seconds


## The character's name, in the current language.
##
## "Don Quijote", "Sancho". The display name lives in the data, so the
## name follows the locale like everything else.
func display_name() -> String:
	if data != null:
		return Loc.t(data.display_name_key)
	return String(character_id)


## The truth this pawn is reading right now, given the world's truth.
##
## This is the whole mechanic in one line: the world has one truth, and two
## people make two things of it.
func perceived_layer_for(world_layer: int) -> int:
	return Perception.reading_for(character_id, world_layer, second_sight)


## Recompute and cache the reading.
func refresh_perception(world_layer: int) -> int:
	perceived_layer = perceived_layer_for(world_layer)
	return perceived_layer


## Switch which truth this pawn reads. Called by the Verdict system and by
## the player's swap.
func set_perceived_layer(layer: int) -> void:
	perceived_layer = layer
