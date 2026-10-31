extends Node2D

@export var target: Node3D = null
@export var lift: float = 3.0
@export var width: float = 1.5

var _ground: ColorRect = null
var _fill: ColorRect = null


func _ready() -> void:
	var container := Control.new()
	container.custom_minimum_size = Vector2(width, 6.0)

	var ground := ColorRect.new()
	ground.custom_minimum_size = Vector2(width, 6.0)
	ground.color = Color(0.12, 0.11, 0.1, 0.85)
	container.add_child(ground)

	var fill := ColorRect.new()
	fill.color = Color(0.75, 0.54, 0.24, 1.0)
	ground.add_child(fill)

	_ground = ground
	_fill = fill

	add_child(container)


func _process(_delta: float) -> void:
	if target == null:
		queue_free()
		return

	var hp := 1.0
	if target.has_method("health") and target.has_method("max_health"):
		var pawn := target as CharacterPawn
		var max_hp := float(pawn.max_health)
		if max_hp > 0.0:
			hp = clampf(float(pawn.health) / max_hp, 0.0, 1.0)
	_fill.size = Vector2(width * hp, 6.0)
	if _fill.size.x <= 0.0:
		queue_free()
		return

	var pos := target.global_position + Vector3(0.0, lift, 0.0)
	var screen_pos = get_viewport().world_to_screen(pos)
	position = screen_pos
