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
var is_dead: bool = false

## The truth this pawn currently perceives. Quixote sees the Book; Sancho
## sees Reality. Set by the driver.
var perceived_layer: int = 0

const GRAVITY := 18.0
const WALK_SPEED := 4.2
const RUN_SPEED := 6.8
const ACCELERATION := 12.0
const FRICTION := 14.0
const TURN_SPEED := 12.0


func _ready() -> void:
	if data != null:
		character_id = data.id
		max_health = 100.0
		stamina = data.max_stamina
		perceived_layer = data.truth_layer_affinity
	add_to_group(&"pawns")
	EventBus.player_spawned.emit(self)


## ── The driver interface ────────────────────────────────────────────────
## A driver calls these. A pawn never calls them on itself.

func move(input_direction: Vector2, sprint: bool) -> void:
	var input := Vector3(input_direction.x, 0.0, input_direction.y)
	var speed := RUN_SPEED if sprint else WALK_SPEED
	var target := input.normalized() * speed

	velocity.x = move_toward(velocity.x, target.x, ACCELERATION * get_process_delta_time())
	velocity.z = move_toward(velocity.z, target.z, ACCELERATION * get_process_delta_time())

	if input.length_squared() > 0.001:
		var facing := Vector3(input_direction.x, 0.0, input_direction.y).normalized()
		look_at(global_position + facing, Vector3.UP)


func light_attack() -> void:
	if data != null and data.light_attack != null:
		_perform(data.light_attack)


func heavy_attack() -> void:
	if data != null and data.heavy_attack != null:
		_perform(data.heavy_attack)


func dodge() -> void:
	if data != null and data.dodge != null:
		_perform(data.dodge)


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
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _perform(ability: AbilityData) -> void:
	if ability == null or is_dead:
		return
	# Gating: layer and madness. This is how "Book builds" and "Reality
	# builds" differ (GDD.md §8.3).
	if not ability.available_in_layer(TruthLayer.layer()):
		return
	if not ability.available_at_locura(Locura.get_for(character_id)):
		return
	if not Memoria.has_milestone(character_id, ability.min_milestone):
		return
	if stamina < ability.stamina_cost:
		return
	stamina -= ability.stamina_cost
	# TODO(Phase 1): spawn the ability's VFX and hitbox.


func take_damage(amount: float) -> void:
	if is_dead:
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
	if character_id == &"sancho":
		return true
	if layer == 0:
		return Locura.can_perceive_reality(character_id)
	return true


## Switch which truth this pawn reads. Called by the Verdict system and by
## the player's swap.
func set_perceived_layer(layer: int) -> void:
	perceived_layer = layer
