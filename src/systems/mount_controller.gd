extends Node
## Rocinante and Dapple (GDD §5.4). Mounts are a chase system, not transport:
## you summon one at the Posada, ride faster, and dismount to investigate.
## Dapple is obstinate (refuses some thresholds) and can be thrown.

signal mount_changed(mounted: bool, mount_id: StringName)

const SPEED_BONUS := 1.6
const THROWN_SPEED := 14.0
## Dapple refuses to cross this line — an obstacle dressed as a joke.
const OBSTINATE_Z := -25.0

var mounted: bool = false
var mount_id: StringName = &""
var _body: Node3D = null
var _rider: CharacterPawn = null
var _throw_velocity := Vector3.ZERO
var _obstinate_until := 0.0


func _ready() -> void:
	_body = Node3D.new()
	_body.name = "MountBody"
	add_child(_body)
	_build_mesh()


func _build_mesh() -> void:
	# Two low-poly shapes until real models exist: a horse and a smaller,
	# stubbier donkey. Colour tells them apart at a glance.
	var torso := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.8, 1.8)
	torso.mesh = box
	torso.position.y = 0.9
	_body.add_child(torso)
	var head := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(0.4, 0.5, 0.6)
	head.mesh = hbox
	head.position = Vector3(0, 1.4, -1.0)
	_body.add_child(head)
	_body.visible = false


func _apply_colour(id: StringName) -> void:
	var colour := Color(0.72, 0.62, 0.45) if id == &"rocinante" else Color(0.52, 0.48, 0.44)
	for child in _body.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = colour
			child.material_override = mat


## Summon the mount for this character at the given position (the checkpoint).
func mount(rider: CharacterPawn, at_position: Vector3) -> bool:
	if mounted or rider == null:
		return false
	mount_id = &"rocinante" if rider.character_id == &"quixote" else &"dapple"
	_rider = rider
	mounted = true
	_body.visible = true
	_apply_colour(mount_id)
	_body.global_position = at_position
	rider.mounted = true
	rider.mount_speed_percent = SPEED_BONUS
	mount_changed.emit(true, mount_id)
	return true


func dismount() -> void:
	if not mounted:
		return
	if _rider != null and is_instance_valid(_rider):
		_rider.mounted = false
		_rider.mount_speed_percent = 1.0
		# Step aside so the pawn is not standing inside the mount.
		_rider.global_position = _body.global_position + Vector3(1.2, 0, 0)
	mounted = false
	_rider = null
	_body.visible = false
	_throw_velocity = Vector3.ZERO
	mount_changed.emit(false, &"")


## Dapple can be thrown (GDD §5.4): a short lunge that knocks things over.
func throw_dapple(direction: Vector3) -> bool:
	if not mounted or mount_id != &"dapple":
		return false
	_throw_velocity = direction.normalized() * THROWN_SPEED
	dismount()
	return true


func is_obstinate_at(position: Vector3) -> bool:
	# Dapple refuses to cross the old church threshold. Quixote's horse will.
	return mount_id == &"dapple" and position.z < OBSTINATE_Z


func _process(delta: float) -> void:
	if not mounted or _rider == null or not is_instance_valid(_rider):
		if _throw_velocity.length_squared() > 0.01:
			_body.global_position += _throw_velocity * delta
			_throw_velocity = _throw_velocity.move_toward(Vector3.ZERO, 20.0 * delta)
		return
	_body.global_position = _rider.global_position
	# Obstinacy: stop at the line, then let the rider dismount and continue.
	if is_obstinate_at(_rider.global_position):
		_rider.global_position.z = OBSTINATE_Z
		_rider.velocity.z = 0.0
