class_name CameraFollow
extends Node3D
## A simple third-person follow camera.
##
## Deliberately simple. Godot's camera rig is not where this project should
## spend its complexity budget — the truth-layer shader and the Lectura
## system are. If the camera starts fighting you, cut to 2.5D
## (see TECH_STACK.md §1, "the one alternative worth considering").

@export var target: Node3D
@export var distance: float = 7.0
@export var height: float = 3.2
@export var follow_speed: float = 6.0
@export var look_speed: float = 8.0

var _desired: Vector3 = Vector3.ZERO
var _placed: bool = false


func _process(delta: float) -> void:
	if target == null:
		return
	var basis_flat := Basis(Vector3.UP, target.rotation.y)
	_desired = target.global_position + (basis_flat * Vector3(0.0, 0.0, distance)) + Vector3(0.0, height, 0.0)
	if not _placed:
		# Snap the first time. A camera that eases in from the origin of
		# the world is a camera that flies through the floor.
		_placed = true
		global_position = _desired
	else:
		global_position = global_position.lerp(_desired, clampf(follow_speed * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3(0.0, 1.2, 0.0), Vector3.UP)
