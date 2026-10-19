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

var _desired: Vector3 = Vector3.ZERO
var _placed: bool = false
var _yaw: float = 0.0
var _yaw_placed: bool = false


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

	# The camera's own yaw, smoothed. The character can turn as fast as it
	# likes; the camera takes its time.
	var target_yaw := target.rotation.y
	if not _yaw_placed:
		_yaw = target_yaw
		_yaw_placed = true
	else:
		var diff := wrapf(target_yaw - _yaw, -PI, PI)
		var step := deg_to_rad(turn_speed) * delta
		_yaw += clampf(diff, -step, step)

	var basis_flat := Basis(Vector3.UP, _yaw)
	_desired = target.global_position + (basis_flat * Vector3(0.0, 0.0, distance)) + Vector3(0.0, height, 0.0)
	if not _placed:
		# Snap the first time. A camera that eases in from the origin of
		# the world is a camera that flies through the floor.
		_placed = true
		global_position = _desired
	else:
		global_position = global_position.lerp(_desired, clampf(follow_speed * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3(0.0, 1.2, 0.0), Vector3.UP)
