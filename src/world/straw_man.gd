class_name StrawMan
extends Node3D
## A straw man, in the corner of the yard.
##
## The second asymmetry rule needs a target, and this is it: a thing that
## must not be harmed. GDD.md §7.2 and D4.
##
## It does not fight. It stands there, it looks like a person from a
## distance, and a blow that lands on it is a blow on an innocent.
##
## **Quixote cannot make that blow.** His hand does not go through, and
## it costs him Humanity — twenty of it, because it is his conscience
## that is the expensive part. D4: *"Attacking a non-knight as Quixote
## costs Humanity and hard-locks his Book-only abilities until the
## chapter ends."*
##
## **Sancho can.** He is a practical man with a sack and no chivalry to
## wound, so the straw comes down — but it still costs him a little,
## because the world is not a place where that is free.
##
## It is here to make the rule *visible*. A rule that cannot be seen
## cannot be judged, and the whole point of the yard is that things can
## be judged.

## How much straw there is.
@export var max_health: float = 40.0
## Who it is. It is the innocent, and that is the entire point.
@export var faction: Harm.Faction = Harm.Faction.INNOCENT
## What it is called.
@export var display_name_key: StringName = &"ui.target.strawman"

## How much of it is left.
var health: float = 0.0

var _material: StandardMaterial3D = null
var _body: Node3D = null


func _ready() -> void:
	health = max_health
	_build()
	add_to_group(AttackHitbox.TARGET_GROUP)
	add_to_group(LockOn.GROUP)
	var body := get_node_or_null("Body") as StaticBody3D
	if body != null:
		body.collision_layer = 5
		body.collision_mask = 5


## What the HUD and the lock-on call it.
func display_name() -> String:
	return Loc.t(display_name_key)


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Figure"
	add_child(_body)

	var straw := StandardMaterial3D.new()
	straw.albedo_color = Color(0.72, 0.62, 0.36, 1.0)
	straw.roughness = 0.95
	_material = straw

	# The post it is built on.
	var post := MeshInstance3D.new()
	post.name = "Post"
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.08
	post_mesh.bottom_radius = 0.1
	post_mesh.height = 1.9
	post.mesh = post_mesh
	post.material_override = straw
	post.position = Vector3(0.0, 0.95, 0.0)
	_body.add_child(post)

	# The head: a bundle of straw tied into a shape.
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.52
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	head.material_override = straw
	head.position = Vector3(0.0, 2.0, 0.0)
	_body.add_child(head)

	# The arms: two sticks, out to the sides.
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.name = "Arm"
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.1, 0.1, 1.1)
		arm.mesh = arm_mesh
		arm.material_override = straw
		arm.position = Vector3(0.55 * side, 1.55, 0.0)
		arm.rotation.y = PI * 0.5
		_body.add_child(arm)

	# The body, so the character cannot walk through it.
	var body := StaticBody3D.new()
	body.name = "Body"
	var collider := CollisionShape3D.new()
	collider.name = "Shape"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.9
	collider.shape = shape
	collider.position = Vector3(0.0, 0.95, 0.0)
	body.add_child(collider)
	add_child(body)


## Take a hit.
##
## The rules are the same ones the dummy uses: `Harm` decides what the
## blow may do and what it costs, and the straw man only lives with the
## result.
func take_damage(amount: float, source: Node = null, poise_damage: float = 0.0) -> void:
	var attacker := source as CharacterPawn
	var damage := Harm.damage_for(faction, attacker, amount)
	var humanity := Harm.humanity_cost(faction, attacker)
	if humanity > 0:
		GameState.spend_humanity(humanity)
		EventBus.humanity_lost.emit(humanity, attacker.character_id if attacker != null else &"")
	if damage <= 0.0:
		# The blow did not land. The straw is still standing.
		return
	health = maxf(0.0, health - damage)
	if _material != null:
		_material.albedo_color = Color(0.88, 0.78, 0.5, 1.0)
	if health <= 0.0:
		_knock_down()


## It falls over. It is straw; it does not die.
func _knock_down() -> void:
	if _body != null:
		_body.rotation.z = deg_to_rad(84.0)
		_body.position.y = -0.2
	remove_from_group(LockOn.GROUP)


## Put it back up.
func reset() -> void:
	health = max_health
	if _body != null:
		_body.rotation.z = 0.0
		_body.position = Vector3.ZERO
	if _material != null:
		_material.albedo_color = Color(0.72, 0.62, 0.36, 1.0)
	add_to_group(LockOn.GROUP)
