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

var _swap_cooldown: float = 0.0


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
	elif event.is_action_pressed(&"lectura"):
		EventBus.lectura_entered.emit()
	elif event.is_action_pressed(&"interact"):
		# TODO(Phase 1): raycast for an interactable and trigger it.
		pass


func _process(delta: float) -> void:
	if _swap_cooldown > 0.0:
		_swap_cooldown -= delta
	if active_pawn == null:
		return

	var direction := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var sprint := Input.is_action_pressed(&"sprint")
	active_pawn.move(direction, sprint)
	active_pawn.block(Input.is_action_pressed(&"block"))


## Swap characters. Free, instant, no pause.
func request_swap() -> void:
	if _swap_cooldown > 0.0 or other_pawn == null:
		return
	_swap_cooldown = 0.25  # a beat, so you cannot machine-gun the swap
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
