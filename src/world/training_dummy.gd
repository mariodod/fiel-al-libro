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
}

## How much punishment it takes.
@export var max_health: float = 120.0
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
	# Something a swing can find.
	add_to_group(AttackHitbox.TARGET_GROUP)
	# The dummy is a target: it is on the "enemy" layer as well as the
	# "world" one, so a swing finds it and the character cannot walk
	# through it.
	var body := get_node_or_null("Body") as StaticBody3D
	if body != null:
		body.collision_layer = 5
		body.collision_mask = 5


## ── The look ───────────────────────────────────────────────────────────

func _build() -> void:
	_body = Node3D.new()
	_body.name = "Figure"
	add_child(_body)

	var wood := StandardMaterial3D.new()
	wood.albedo_color = WOOD
	wood.roughness = 0.9
	_material = wood

	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.16
	post_mesh.bottom_radius = 0.22
	post_mesh.height = 1.7
	post.mesh = post_mesh
	post.material_override = wood
	post.position = Vector3(0.0, 0.85, 0.0)
	_body.add_child(post)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	head.mesh = head_mesh
	head.material_override = wood
	head.position = Vector3(0.0, 1.85, 0.0)
	_body.add_child(head)

	# The arm hangs off a shoulder, so it can swing.
	_shoulder = Node3D.new()
	_shoulder.name = "Shoulder"
	_shoulder.position = Vector3(0.0, 1.55, 0.0)
	_body.add_child(_shoulder)

	var arm := MeshInstance3D.new()
	arm.name = "Arm"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.22, 0.22, 1.5)
	arm.mesh = arm_mesh
	arm.material_override = wood
	arm.position = Vector3(0.0, 0.0, -0.75)
	_shoulder.add_child(arm)

	# The body, so the character cannot walk through it.
	var body := StaticBody3D.new()
	body.name = "Body"
	var collider := CollisionShape3D.new()
	collider.name = "Shape"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.9
	collider.shape = shape
	collider.position = Vector3(0.0, 0.95, 0.0)
	body.add_child(collider)
	add_child(body)

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
		pawn.take_damage(damage)


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
func take_damage(amount: float) -> void:
	if state == State.DOWN:
		return
	health = maxf(0.0, health - amount)
	_flinch = 0.25
	if _material != null:
		_material.albedo_color = WOOD
	if health <= 0.0:
		_knock_down()


## It goes over.
func _knock_down() -> void:
	_enter(State.DOWN, down_seconds)
	if _body != null:
		_body.rotation.z = deg_to_rad(78.0)
		_body.position.y = -0.25


## And it gets up.
func _get_up() -> void:
	health = max_health
	if _body != null:
		_body.rotation.z = 0.0
		_body.position.y = 0.0
	_enter(State.IDLE, idle_seconds)


## Put everything back: the dummy stands up, and the yard is quiet.
func reset() -> void:
	health = max_health
	_flinch = 0.0
	if _body != null:
		_body.rotation.z = 0.0
		_body.position = Vector3.ZERO
	if _material != null:
		_material.albedo_color = WOOD
	_enter(State.IDLE, idle_seconds)


## Is the dummy down? The HUD says so.
func is_down() -> bool:
	return state == State.DOWN
