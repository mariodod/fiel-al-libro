class_name TrainingDummy
extends Node3D
## The thing to fight.
##
## The second playtest, in one line: *"For the dodge it is difficult to
## assess if it's fine at this stage without any enemies or space
## limitations."*
##
## Fair: a dodge on an empty plain is a dash. You cannot tell a good one
## from a bad one, because there is nothing to dodge and nowhere you
## cannot go. So the slice grows a **training dummy** and a **walled
## yard** around it: the dummy swings on a rhythm, it telegraphs, it
## hurts, and it can be hit back.
##
## This is task 2.6b — the hole in the plan. The plan's combat task says
## the combat is done when *"a 60-second exchange with a dummy is fun"*,
## and the lock-on wants a target, and there was no dummy and no enemy
## until 2.11. A dummy is the cheapest thing that makes both of them
## real.
##
## It is a dummy and not an enemy: it does not chase, it does not block,
## and the asymmetry rules of GDD.md §7.2 do not apply to it. The yard is
## the space limit; the dummy is the thing to dodge.

## What the dummy is doing.
enum State {
	IDLE,     ## waiting; turning to face whoever is nearest
	WINDUP,   ## the arm is going up. THIS is the telegraph.
	STRIKE,   ## the arm is coming down. This is the hit.
	RECOVER,  ## the arm is back down; the dummy is open.
	DOWN,     ## knocked over. It gets up on its own.
	STAGGER,  ## the poise broke. It is reeling, and it is open.
}

## How much punishment it takes.
@export var max_health: float = 100.0
## Who it is, and what may be done to it. GDD.md §7.2: an enemy is one
## whose guard Sancho can break but whose flesh he cannot.
@export var faction: Harm.Faction = Harm.Faction.HOSTILE
## How much punishment it takes before it staggers. Blows take the poise
## away, and a broken poise leaves it open. GDD.md §7.1.
@export var max_poise: float = 40.0
## How long it reels when the poise breaks.
@export var stagger_seconds: float = 1.4
## What the character is called.
@export var display_name_key: StringName = &"ui.target.dummy"
## How much a hit from the dummy hurts.
@export var damage: float = 16.0
## How far the swing reaches.
@export var reach: float = 2.9
## The width of the swing, in degrees.
@export var arc_degrees: float = 110.0
## How long the arm takes to go up. The player reads the swing in this.
@export var windup_seconds: float = 0.62
## How long the arm takes to come down.
@export var strike_seconds: float = 0.16
## How long the dummy is open after a swing.
@export var recover_seconds: float = 1.0
## How long it waits before it picks the fight up again.
@export var idle_seconds: float = 0.7
## How fast it turns, in radians per second.
@export var turn_speed: float = 2.2
## How close a character has to be for the dummy to bother.
@export var engage_distance: float = 5.5
## How long it stays down before it gets up by itself.
@export var down_seconds: float = 4.0

## How much health it has left.
var health: float = 0.0
## How much poise it has left. A broken poise staggers it.
var poise: float = 0.0
## What it is doing right now. Read by the HUD and by the tests.
var state: int = State.IDLE

var _timer: float = 0.0
var _flinch: float = 0.0
var _shoulder: Node3D = null
var _material: StandardMaterial3D = null
var _body: Node3D = null

## The colour of the wood it is made of.
const WOOD := Color(0.52, 0.38, 0.25, 1.0)


func _ready() -> void:
	health = max_health
	_build()
	# Something a swing can find, and something the lock-on can pick.
	add_to_group(AttackHitbox.TARGET_GROUP)
	add_to_group(LockOn.GROUP)
	# The dummy is a target: it is on the "enemy" layer as well as the
	# "world" one, so a swing finds it and the character cannot walk
	# through it.
	var body := get_node_or_null("Body") as StaticBody3D
	if body != null:
		body.collision_layer = 5
		body.collision_mask = 5


## What the HUD and the lock-on marker call it.
func display_name() -> String:
	return Loc.t(display_name_key)


## ── The look ───────────────────────────────────────────────────────────

func _build() -> void:
	_body = Node3D.new()
	_body.name = "Figure"
	add_child(_body)

	var wood := StandardMaterial3D.new()
	wood.albedo_color = WOOD
	wood.roughness = 0.92
	_material = wood

	var wood_dark := StandardMaterial3D.new()
	wood_dark.albedo_color = Color(0.42, 0.3, 0.18, 1.0)
	wood_dark.roughness = 0.95

	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.18
	post_mesh.bottom_radius = 0.24
	post_mesh.height = 1.7
	post.mesh = post_mesh
	post.material_override = wood
	post.position = Vector3(0.0, 0.85, 0.0)
	_body.add_child(post)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.3
	head_mesh.height = 0.56
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.material_override = wood
	head.position = Vector3(0.0, 1.9, 0.0)
	_body.add_child(head)

	# The arm hangs off a shoulder, so it can swing.
	_shoulder = Node3D.new()
	_shoulder.name = "Shoulder"
	_shoulder.position = Vector3(0.0, 1.55, 0.0)
	_body.add_child(_shoulder)

	var arm := MeshInstance3D.new()
	arm.name = "Arm"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.22, 0.22, 1.6)
	arm.mesh = arm_mesh
	arm.material_override = wood
	arm.position = Vector3(0.0, 0.0, -0.8)
	_shoulder.add_child(arm)

	var arm_end := MeshInstance3D.new()
	arm_end.name = "ArmEnd"
	var arm_end_mesh := BoxMesh.new()
	arm_end_mesh.size = Vector3(0.26, 0.26, 0.22)
	arm_end_mesh.material_override = wood_dark
	arm_end.position = Vector3(0.0, 0.0, -0.82)
	arm.add_child(arm_end)

	# The body: a sack stuffed with straw, tied at waist and neck.
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.32
	body_mesh.bottom_radius = 0.32
	body_mesh.height = 1.3
	body_mesh.radial_segments = 8
	body.mesh = body_mesh
	body.material_override = wood
	body.position = Vector3(0.0, 0.65, 0.0)
	_body.add_child(body)

	var body_tie := MeshInstance3D.new()
	body_tie.name = "BodyTie"
	var body_tie_mesh := CylinderMesh.new()
	body_tie_mesh.top_radius = 0.36
	body_tie_mesh.bottom_radius = 0.36
	body_tie_mesh.height = 0.08
	body_tie_mesh.radial_segments = 8
	body_tie.mesh = body_tie_mesh
	body_tie.material_override = wood_dark
	body_tie.position = Vector3(0.0, 0.35, 0.0)
	body.add_child(body_tie)

	# The body collider, so the character cannot walk through it.
	var body_collider := StaticBody3D.new()
	body_collider.name = "BodyCollider"
	var collider := CollisionShape3D.new()
	collider.name = "Shape"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.9
	collider.shape = shape
	collider.position = Vector3(0.0, 0.95, 0.0)
	body_collider.add_child(collider)
	add_child(body_collider)

	# A ring on the ground: where the swing reaches.
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 1.0
	ring_mesh.bottom_radius = 1.0
	ring_mesh.height = 0.02
	ring_mesh.radial_segments = 24
	ring.mesh = ring_mesh
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.45, 0.18, 0.15, 0.75)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_material
	ring.position = Vector3(0.0, 0.02, 0.0)
	add_child(ring)


# ── The behaviour ──────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_flinch = maxf(0.0, _flinch - delta)
	_timer = maxf(0.0, _timer - delta)
	_update_flinch()
	_update_arm(delta)

	match state:
		State.IDLE:
			_face_target(delta)
			if _timer <= 0.0 and _target_in_range():
				_enter(State.WINDUP, windup_seconds)
		State.WINDUP:
			_face_target(delta * 0.5)
			if _timer <= 0.0:
				_enter(State.STRIKE, strike_seconds)
				_land()
		State.STRIKE:
			if _timer <= 0.0:
				_enter(State.RECOVER, recover_seconds)
		State.RECOVER:
			if _timer <= 0.0:
				_enter(State.IDLE, idle_seconds)
		State.STAGGER:
			# Reeling. It does not swing, and it does not turn.
			if _timer <= 0.0:
				_enter(State.IDLE, idle_seconds)
		State.DOWN:
			if _timer <= 0.0:
				_get_up()


## Change state, and start the clock for it.
func _enter(next: int, seconds: float) -> void:
	state = next
	_timer = seconds


## The swing comes down. Everything in the arc takes the hit — and the
## check happens NOW, not when the arm went up. That is the whole test:
## a character who dodged is no longer in the arc.
func _land() -> void:
	var origin := global_position
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return
	forward = forward.normalized()
	var half_arc := deg_to_rad(arc_degrees * 0.5)

	for pawn in _pawns():
		var to_pawn := pawn.global_position - origin
		to_pawn.y = 0.0
		var distance := to_pawn.length()
		if distance > reach:
			continue
		if distance > 0.05:
			var angle := forward.angle_to(to_pawn / distance)
			if angle > half_arc:
				continue
		pawn.take_damage(damage, self)


## Is this thing about to swing?
##
## The convention every target follows: it says so before it hits. That
## is what makes a parry possible, and a parry is what makes a companion
## worth having.
func is_winding_up() -> bool:
	return state == State.WINDUP


## How long until the blow lands, in seconds.
##
## A companion that cannot time a parry cannot parry: it would have to
## raise its guard on the first frame of the wind-up, and the parry
## window is a quarter of a second. So the target says how long it has
## left, and the guard goes up inside the window.
func time_until_strike() -> float:
	if state != State.WINDUP:
		return 99.0
	return _timer


## Turn towards the nearest character, slowly.
func _face_target(delta: float) -> void:
	var pawn := _nearest_pawn()
	if pawn == null:
		return
	var to_pawn := pawn.global_position - global_position
	to_pawn.y = 0.0
	if to_pawn.length_squared() < 0.0001:
		return
	var desired := atan2(-to_pawn.x, -to_pawn.z)
	var diff := wrapf(desired - rotation.y, -PI, PI)
	rotation.y += clampf(diff, -turn_speed * delta, turn_speed * delta)


## Is anybody close enough to be worth swinging at?
func _target_in_range() -> bool:
	var pawn := _nearest_pawn()
	if pawn == null:
		return false
	var to_pawn := pawn.global_position - global_position
	to_pawn.y = 0.0
	return to_pawn.length() <= engage_distance


## The character closest to the dummy.
func _nearest_pawn() -> CharacterPawn:
	var best: CharacterPawn = null
	var best_distance := INF
	for pawn in _pawns():
		var distance := pawn.global_position.distance_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best = pawn
	return best


func _pawns() -> Array[CharacterPawn]:
	var out: Array[CharacterPawn] = []
	var tree := get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group(&"pawns"):
		var pawn := node as CharacterPawn
		if pawn != null and not pawn.is_dead:
			out.append(pawn)
	return out


## The arm, in the pose the current state calls for.
func _update_arm(delta: float) -> void:
	if _shoulder == null:
		return
	var target := 0.0
	var speed := 4.0
	match state:
		State.WINDUP:
			# The arm goes up, slowly enough to read.
			target = -2.0
		State.STRIKE:
			# And comes down fast enough to be over before the window
			# shuts. A swing that is still arriving when the damage is
			# resolved reads as a lie.
			target = 0.75
			speed = 18.0
		State.DOWN:
			target = 0.0
		_:
			target = 0.0
	_shoulder.rotation.x = move_toward(_shoulder.rotation.x, target, speed * delta)


## The shudder when it takes a hit.
func _update_flinch() -> void:
	if _body == null:
		return
	if state == State.DOWN:
		return
	if _flinch > 0.0:
		_body.position.x = randf_range(-0.06, 0.06)
		_body.rotation.z = randf_range(-0.05, 0.05)
		return
	if _body.position.x != 0.0:
		_body.position.x = 0.0
		_body.rotation.z = 0.0
	if _material != null and _material.albedo_color != WOOD:
		_material.albedo_color = WOOD


# ── Being hit ──────────────────────────────────────────────────────────

## Take a hit. The same interface a character has, so a swing does not
## need to know what it is hitting.
func take_damage(amount: float, source: Node = null, poise_damage: float = 0.0) -> void:
	if state == State.DOWN:
		return
	var attacker := source as CharacterPawn
	# What the blow is allowed to do. GDD.md §7.2 and D4.
	var damage := Harm.damage_for(faction, attacker, amount)
	var humanity := Harm.humanity_cost(faction, attacker)
	if humanity > 0:
		GameState.spend_humanity(humanity)
		EventBus.humanity_lost.emit(humanity, attacker.character_id if attacker != null else &"")
	if damage <= 0.0:
		# The blow did not land. The dummy does not even notice it.
		return
	health = maxf(0.0, health - damage)
	_flinch = 0.25
	if _material != null:
		_material.albedo_color = WOOD
	# The poise. A broken poise leaves it open, and that is the whole
	# point of a heavy swing.
	if poise_damage > 0.0:
		poise += poise_damage
		if poise >= max_poise:
			poise = 0.0
			stagger()
	if health <= 0.0:
		_knock_down()


## The poise broke. It reels, and for a moment it cannot swing.
func stagger() -> void:
	if state == State.DOWN or state == State.STAGGER:
		return
	_enter(State.STAGGER, stagger_seconds)
	_flinch = 0.4


## It goes over.
func _knock_down() -> void:
	_enter(State.DOWN, down_seconds)
	poise = 0.0
	if _body != null:
		_body.rotation.z = deg_to_rad(78.0)
		_body.position.y = -0.25
	# A thing that is out of the fight is not a target. The lock goes
	# with it, and the player has to pick it up again when it stands.
	remove_from_group(LockOn.GROUP)


## And it gets up.
func _get_up() -> void:
	health = max_health
	poise = 0.0
	if _body != null:
		_body.rotation.z = 0.0
		_body.position.y = 0.0
	add_to_group(LockOn.GROUP)
	_enter(State.IDLE, idle_seconds)


## Put everything back: the dummy stands up, and the yard is quiet.
func reset() -> void:
	health = max_health
	poise = 0.0
	_flinch = 0.0
	if _body != null:
		_body.rotation.z = 0.0
		_body.position = Vector3.ZERO
	if _material != null:
		_material.albedo_color = WOOD
	add_to_group(LockOn.GROUP)
	_enter(State.IDLE, idle_seconds)


## Is the dummy down? The HUD says so.
func is_down() -> bool:
	return state == State.DOWN
