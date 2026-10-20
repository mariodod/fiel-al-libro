class_name PlayerController
extends Node
## The human driver.
##
## Owns the input and hands it to whichever pawn the player is driving.
## Switching pawns is instant and free — it is a tactical verb, not a menu
## (D3). The world does not pause.

## The pawn the player is driving RIGHT NOW.
var active_pawn: CharacterPawn = null
## The pawn the player is NOT driving. It runs its own AI.
var other_pawn: CharacterPawn = null

## The thing the player is looking at, if anything. The Examine verb acts
## on it, and the barks are about it.
var examine_target: TruthObject = null:
	get:
		return _examine_target

var _swap_cooldown: float = 0.0
## The thing the player is looking at, and the ones they could be looking
## at. The Examine verb needs both.
var _examine_target: TruthObject = null
var _examine_candidates: Array[Node] = []
var _candidate_timer: float = 0.0
## The things that can be locked onto, refreshed a few times a second.
var _lock_candidates: Array[Node] = []
var _lock_timer: float = 0.0


func _ready() -> void:
	EventBus.character_switched.connect(_on_character_switched)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"switch_character"):
		request_swap()
		return

	if active_pawn == null or active_pawn.is_dead:
		return

	if event.is_action_pressed(&"attack_light"):
		active_pawn.light_attack()
	elif event.is_action_pressed(&"attack_heavy"):
		active_pawn.heavy_attack()
	elif event.is_action_pressed(&"dodge"):
		active_pawn.dodge()
	elif event.is_action_pressed(&"desvelar"):
		# Sancho's verb: strip the Book skin off the thing in front of
		# you. Quixote has no such gift.
		active_pawn.ability(&"desvelar")
	elif event.is_action_pressed(&"lock_on"):
		_toggle_lock()
	elif event.is_action_pressed(&"lectura"):
		EventBus.lectura_entered.emit()
	elif event.is_action_pressed(&"interact"):
		_examine()


func _process(delta: float) -> void:
	if _swap_cooldown > 0.0:
		_swap_cooldown -= delta
	if active_pawn == null:
		_set_examine_target(null)
		return

	var direction := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var sprint := Input.is_action_pressed(&"sprint")
	active_pawn.move(_in_fight_frame(direction), sprint)
	active_pawn.block(Input.is_action_pressed(&"block"))

	_update_examine_target(delta)
	_update_lock(delta)


# ── The lock-on ────────────────────────────────────────────────────────

## Lock onto the thing you are looking at, or let go of it.
##
## The lock is soft: it is given up when the target leaves the fight, and
## it is a camera tool before it is a combat tool. A fight you cannot
## see is not a fight.
func _toggle_lock() -> void:
	if active_pawn == null:
		return
	if active_pawn.is_locked():
		active_pawn.clear_lock_target()
		return
	_refresh_lock_candidates()
	var target := LockOn.find_target(
		_lock_candidates, active_pawn.global_position, _facing())
	if target == null:
		return
	active_pawn.set_lock_target(target)


## Keep the lock honest: a target that is dead, or too far, is no target.
func _update_lock(delta: float) -> void:
	_lock_timer -= delta
	if _lock_timer <= 0.0:
		_refresh_lock_candidates()
	if active_pawn == null or not active_pawn.is_locked():
		return
	if LockOn.is_valid(active_pawn.lock_target, active_pawn.global_position):
		return
	active_pawn.clear_lock_target()


func _refresh_lock_candidates() -> void:
	_lock_timer = 0.2
	_lock_candidates = get_tree().get_nodes_in_group(LockOn.GROUP)


# ── The Examine verb ───────────────────────────────────────────────────

## Look at the thing in front of you and learn what it is.
##
## The first playtest asked for this: "wanted to interact with book and
## giant". What it shows is the object's two faces and the two readings,
## which is the whole mechanic in three lines.
func _examine() -> void:
	if _examine_target == null or _examine_target.data == null or active_pawn == null:
		return
	EventBus.object_examined.emit(_examine_target.data.id, active_pawn.character_id)


## The things the player could be examining. The Desvelar uses them to
## find what is in front of you.
func examine_candidates() -> Array[Node]:
	return _examine_candidates


## Keep track of what the player is looking at.
##
## The candidates are refreshed a few times a second rather than every
## frame: the group lookup allocates an array, and this runs on every
## frame of every build.
func _update_examine_target(delta: float) -> void:
	_candidate_timer -= delta
	if _candidate_timer <= 0.0:
		_candidate_timer = 0.2
		_examine_candidates = get_tree().get_nodes_in_group(Examine.GROUP)
	_set_examine_target(Examine.find_target(
		_examine_candidates, active_pawn.global_position, _facing()))


func _set_examine_target(target: TruthObject) -> void:
	if target == _examine_target:
		return
	_examine_target = target
	var id := &"" if target == null or target.data == null else target.data.id
	EventBus.examine_target_changed.emit(id)


## The direction the pawn is looking. The node faces -Z.
func _facing() -> Vector3:
	return -active_pawn.global_transform.basis.z


## Put the input into the camera's frame of reference.
##
## "Forward" has to mean "away from the camera", not "north". Moving
## relative to the world plane is the classic third-person mistake, and
## the first playtest named it on run 1: "it moves relative to plane not
## camera". The pawn's own movement stays world-space — the companion AI
## uses that too, and it has no camera.
##
## With a target locked, the frame is the TARGET's, not the camera's:
## forward is towards the thing you are fighting, so `W` closes the
## distance and `A`/`D` walk around it.
func _in_fight_frame(direction: Vector2) -> Vector2:
	if active_pawn != null and active_pawn.is_locked():
		return _in_lock_frame(direction)
	return _in_camera_frame(direction)


## The input, in the frame of the locked target.
func _in_lock_frame(direction: Vector2) -> Vector2:
	if direction.length_squared() < 0.0001:
		return direction
	var to_target := active_pawn.lock_target.global_position - active_pawn.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return direction
	var forward := to_target.normalized()
	var right := Vector3(forward.z, 0.0, -forward.x)
	var world := right * direction.x + forward * direction.y
	return Vector2(world.x, world.z).normalized()


## The input, in the camera's frame of reference.
func _in_camera_frame(direction: Vector2) -> Vector2:
	if direction.length_squared() < 0.0001:
		return direction
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return direction
	var world := Basis(Vector3.UP, camera.global_rotation.y) * Vector3(direction.x, 0.0, direction.y)
	return Vector2(world.x, world.z).normalized()


## Swap characters. Free, instant, no pause.
func request_swap() -> void:
	if _swap_cooldown > 0.0 or other_pawn == null:
		return
	_swap_cooldown = 0.25  # a beat, so you cannot machine-gun the swap
	# A lock belongs to the character that took it. The new one starts
	# with nothing locked, and the old one is not still fighting.
	if active_pawn != null:
		active_pawn.clear_lock_target()
	if other_pawn != null:
		other_pawn.clear_lock_target()
	var previous := active_pawn
	active_pawn = other_pawn
	other_pawn = previous
	EventBus.character_switched.emit(
		previous.character_id if previous else &"",
		active_pawn.character_id if active_pawn else &""
	)


func _on_character_switched(from_id: StringName, to_id: StringName) -> void:
	# The Manuscript shows whose page you are writing.
	EventBus.toast.emit(&"tip.switch.intro", [])
