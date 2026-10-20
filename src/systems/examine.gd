class_name Examine
extends RefCounted
## The Examine verb: look at a thing and learn what it is in each truth.
##
## The first playtest asked for this twice, by two people who had never
## spoken to each other: *"seeing the rock I wanted to interact with it,
## even more the book I expected to be able to interact with it and read
## it"*, and *"wanted to interact with book and giant"*. A mechanic you can
## only watch is a demo. This is the verb that turns it into a game.
##
## It is the cheapest possible version: walk up to a thing, press `E`, and
## the game tells you what it is in your truth and in the other one. Not
## the Lectura system (GDD.md §6) — that is weeks 5–7, and it is the same
## muscle made explicit. This is the muscle itself.
##
## The rule it obeys is the reading rule (Perception): a character calls an
## object by the truth they are reading right now. So the panel can say
## "rock" and "book" in the same breath, and the disagreement it shows is
## the game's whole subject.

## The group every object that can be examined belongs to.
const GROUP := &"interactables"

## How close you have to be to examine a thing.
const MAX_DISTANCE := 5.0

## How far off your line of sight it can be and still be examined.
const MAX_ANGLE_DEGREES := 55.0


## The object the reader is looking at, or null.
##
## The one you are looking at most DIRECTLY wins, and distance only breaks
## ties. Most directly, not nearest: the windmill is eleven metres tall
## and the rock is a pebble, so "nearest" would always answer with the
## pebble, and the player is looking at the windmill.
static func find_target(candidates: Array, origin: Vector3, facing: Vector3) -> TruthObject:
	var flat_facing := Vector3(facing.x, 0.0, facing.z)
	if flat_facing.length_squared() < 0.0001:
		return null
	flat_facing = flat_facing.normalized()

	var best: TruthObject = null
	var best_angle := 0.0
	var best_distance := 0.0

	for node in candidates:
		var object := node as TruthObject
		if object == null or object.data == null:
			continue
		var to_object := object.global_position - origin
		to_object.y = 0.0
		var distance := to_object.length()
		if distance > MAX_DISTANCE or distance < 0.001:
			continue
		var angle := rad_to_deg(flat_facing.angle_to(to_object / distance))
		if angle > MAX_ANGLE_DEGREES:
			continue
		if best == null or angle < best_angle - 0.5 or (absf(angle - best_angle) <= 0.5 and distance < best_distance):
			best = object
			best_angle = angle
			best_distance = distance

	return best


## The two names an object has: one per truth.
##
## This is the payload of the Examine beat. A rock is a rock in Reality
## and a book in the Book, and the panel says both, because that is the
## fact the player is there to learn.
static func face_keys(object: TruthObject) -> Array[StringName]:
	if object == null or object.data == null:
		return []
	return [object.name_key_for(Perception.REALITY), object.name_key_for(Perception.BOOK)]


## What a character calls an object right now.
##
## The reading, not the truth: a mad Quixote calls a rock a book even when
## the world is in Reality, because the Book is all he has ever seen.
static func reading_key(object: TruthObject, character: CharacterPawn) -> StringName:
	if object == null or character == null:
		return &""
	return object.name_key_for(character.perceived_layer)


## The examinable object with this id, or null.
static func find_by_id(id: StringName) -> TruthObject:
	if id.is_empty():
		return null
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(GROUP):
		var object := node as TruthObject
		if object != null and object.data != null and object.data.id == id:
			return object
	return null
