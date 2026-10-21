class_name CameraFollow
extends Node3D
## A simple third-person follow camera.
##
## Deliberately simple. Godot's camera rig is not where this project should
## spend its complexity budget — the truth-layer shader and the Lectura
## system are. If the camera starts fighting you, cut to 2.5D
## (see TECH_STACK.md §1, "the one alternative worth considering").
##
## ── The turn rate is the whole trick ────────────────────────────────────
## A camera that copies the character's facing every frame whips sideways
## the moment the character turns, because the character turns instantly.
## The stranger's first note was "camera rotates sideways too fast", and
## the fix is not a faster camera: it is a camera that turns at a rate a
## person can follow. The camera's own yaw is smoothed, separately from
## the character's.

@export var target: Node3D
@export var distance: float = 7.0
@export var height: float = 3.2
@export var follow_speed: float = 6.0
## How fast the camera swings round to follow the character's facing, in
## degrees per second. Low enough to arc, high enough to keep up.
@export var turn_speed: float = 180.0
## The thing the camera is framing ALONGSIDE the character: a locked
## target.
##
## With a target, the camera stops copying the character's facing and
## stands on the line between them, so that both are in the picture. A
## fight you cannot see is not a fight, and this is the half of the
## lock-on that is a camera tool.
var lock_target: Node3D = null
## How much of the way towards the target the camera looks. Half of it
## would put the character in the corner; too little and the character
## stands in front of the target and hides it, which is the one thing a
## fight camera must not do.
@export var lock_look_bias: float = 0.62
## How much the camera pulls back per metre of distance to the target.
@export var lock_pull_back: float = 0.45
## The most the camera pulls back for the target.
@export var lock_max_pull_back: float = 5.0
## How far to the side the camera stands while locked.
##
## The camera stands BEHIND the character, on the line to the target —
## and a character standing on that line stands in front of the target
## and hides it. So the camera steps to the shoulder, the way every
## fight camera in the genre does, and the character moves out of the
## way of the thing it is fighting.
@export var lock_side_offset: float = 1.4

var _desired: Vector3 = Vector3.ZERO
var _placed: bool = false
var _yaw: float = 0.0
var _yaw_placed: bool = false
## How hard the camera is being shaken right now.
var _shake: float = 0.0

## How fast the camera closes on its target, per radian of error.
const TURN_EASE := 4.0


## Shake the camera.
##
## There are no animations and no hit reactions yet, so a blow that lands
## is a push, a flash and **this**: the picture moves. It is the
## cheapest thing that makes a hit feel like a hit.
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


## Snap the camera to its target on the next frame instead of easing there.
##
## Used when you swap characters. A camera that slides across to the other
## character reads as a mistake; a camera that cuts reads as a page turn.
func snap() -> void:
	_placed = false
	_yaw_placed = false


func _process(delta: float) -> void:
	if target == null:
		return

	# Where the camera looks, and how far back it stands, depend on
	# whether there is a target to frame.
	var focus := target.global_position + Vector3(0.0, 1.2, 0.0)
	var stand_back := distance
	var target_yaw := target.rotation.y

	if lock_target != null and is_instance_valid(lock_target):
		var to_lock := lock_target.global_position - target.global_position
		to_lock.y = 0.0
		var span := to_lock.length()
		if span > 0.001:
			# Stand on the line BEHIND the character, looking down it at
			# the target: the character is between the camera and the
			# thing it is fighting, and both are in the picture.
			target_yaw = atan2(-to_lock.x, -to_lock.z)
			focus = target.global_position.lerp(lock_target.global_position, lock_look_bias) + Vector3(0.0, 1.2, 0.0)
			stand_back = distance + minf(span * lock_pull_back, lock_max_pull_back)

	# The camera's own yaw, smoothed. The character can turn as fast as it
	# likes; the camera takes its time.
	#
	# The follow is PROPORTIONAL, not a constant rate: the camera eases
	# towards the character's facing instead of swinging at it. A camera
	# that swings at a character which is itself easing into a turn
	# oscillates around it, and the oscillation is what the playtest saw
	# as *"the camera spins non stop"*.
	if not _yaw_placed:
		_yaw = target_yaw
		_yaw_placed = true
	else:
		var diff := wrapf(target_yaw - _yaw, -PI, PI)
		var step := deg_to_rad(turn_speed) * delta
		_yaw += clampf(diff * TURN_EASE, -step, step)

	var basis_flat := Basis(Vector3.UP, _yaw)
	# The camera's own right, so the shoulder offset rotates with it and
	# never flips.
	var shoulder := Vector3.ZERO
	if lock_target != null and is_instance_valid(lock_target):
		shoulder = basis_flat.x * lock_side_offset
	_desired = target.global_position + (basis_flat * Vector3(0.0, 0.0, stand_back)) + shoulder + Vector3(0.0, height, 0.0)
	if not _placed:
		# Snap the first time. A camera that eases in from the origin of
		# the world is a camera that flies through the floor.
		_placed = true
		global_position = _desired
	else:
		global_position = global_position.lerp(_desired, clampf(follow_speed * delta, 0.0, 1.0))
	if _shake > 0.001:
		_shake = maxf(0.0, _shake - delta * 3.0)
		global_position += Vector3(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake * 0.12
	look_at(focus, Vector3.UP)
