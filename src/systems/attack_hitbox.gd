class_name AttackHitbox
extends Node3D
## The swing of a weapon: a short window in which whatever is in front
## of the character takes the hit.
##
## It is the crudest possible version of a combat hitbox — task 2.6 does
## the real one, with the combo, the poise and the hit reactions. It
## exists for one reason: **the dodge cannot be judged without something
## to dodge against.** A training dummy that cannot be hit is not a
## target, and a target that cannot be hit makes the attack meaningless.
##
## The hit is resolved by distance and by arc, against everything in the
## "damageable" group, rather than by a physics shape. That is a
## deliberate simplification: the numbers of a swing are what the
## playtest is about, and a rule that can be pinned down in a unit test
## is a rule that cannot drift.
##
## The physics shape arrives with 2.6, when there are animations to drive
## it and something to block.

## The group of things that can be hit.
const TARGET_GROUP := &"damageable"

## How much damage a hit does.
@export var damage: float = 10.0
## How far the swing reaches, from the character.
@export var reach: float = 2.6
## The width of the swing, in degrees.
@export var arc_degrees: float = 70.0
## How long the hitbox stays live.
@export var active_seconds: float = 0.12
## Who swung it.
var source: Node = null
## What the swing is aimed at. A locked-on target, or nothing: then the
## swing goes where the character is looking.
var aim_at: Node3D = null

var _age: float = 0.0
## The targets already hit, so one swing cannot count twice.
var _hit: Dictionary = {}


## Swing at something. Spawns the hitbox in front of the character.
static func swing(pawn: CharacterPawn, ability: AbilityData) -> void:
	if pawn == null or ability == null:
		return
	var box := AttackHitbox.new()
	box.name = "Hitbox"
	box.damage = ability.damage
	box.reach = ability.reach
	box.arc_degrees = ability.arc_degrees
	box.active_seconds = ability.active_seconds
	box.source = pawn
	# A locked-on swing goes at the target, not at wherever the
	# character happens to be facing: the character is still turning.
	box.aim_at = pawn.lock_target
	pawn.add_child(box)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= active_seconds:
		queue_free()
		return
	_resolve()


## Where the swing is pointing.
##
## At the locked target if there is one, and at the character's own
## facing otherwise. The character's turn is rate-limited, so a swing
## that used its facing would miss a target the player is clearly
## aiming at.
func _swing_direction() -> Vector3:
	var forward := Vector3.ZERO
	if aim_at != null and is_instance_valid(aim_at):
		forward = aim_at.global_position - source.global_position
	else:
		forward = -source.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.ZERO
	return forward.normalized()


## Hurt everything inside the arc.
func _resolve() -> void:
	if source == null or not is_instance_valid(source):
		return
	var origin: Vector3 = source.global_position
	var forward := _swing_direction()
	if forward == Vector3.ZERO:
		return
	var half_arc := deg_to_rad(arc_degrees * 0.5)

	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(TARGET_GROUP):
		var target := node as Node3D
		if target == null or not target.has_method("take_damage"):
			continue
		if target == source:
			continue
		var id := target.get_instance_id()
		if _hit.has(id):
			continue
		var to_target: Vector3 = target.global_position - origin
		to_target.y = 0.0
		var distance: float = to_target.length()
		if distance > reach:
			continue
		if distance > 0.05:
			var angle := forward.angle_to(to_target / distance)
			if angle > half_arc:
				continue
		_hit[id] = true
		target.take_damage(damage)
