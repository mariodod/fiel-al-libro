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
## the game tells you **what this character sees**: how it looks, what it
## is called, what is written on it, and the one detail that does not add
## up. Not the Lectura system (GDD.md §6) — that is weeks 5–7, and it is
## the same muscle made explicit. This is the muscle itself.
##
## The rule it obeys is the reading rule (Perception): a character calls an
## object by the truth they are reading right now. So the panel describes
## the rock as a stone or as a book, depending on who is looking — and it
## never says what the other one is looking at. The second playtest was
## blunt about it: *"Examining shouldn't give away all the information.
## It should give the information the character sees."*

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


## The face of an object in a truth layer.
##
## A face is one truth's worth of a thing: what it is called, how it
## looks, and the one detail that does not add up. See `TruthFace`.
static func face_for(object: TruthObject, layer: int) -> TruthFace:
	if object == null or object.data == null:
		return null
	return object.data.face_for(layer)


## What a character makes of an object right now.
##
## This is the whole payload of the Examine beat. The second playtest said
## the panel "gives away all the information" because it printed the
## object in both truths and the reading of both characters — the whole
## mechanic, handed over. It does not any more: a character only ever
## gets their OWN reading, and the seam inside it (the weight, the
## creak, the wind that is not there) is the clue that makes them look
## again.
##
## The reading comes from the reading rule (Perception), so it moves with
## the world: flip the truth, and the same object is described in the
## other way.
static func perception_for(object: TruthObject, character: CharacterPawn) -> TruthFace:
	if object == null or object.data == null:
		return null
	if character == null:
		return object.data.face_for(Perception.REALITY)
	return object.data.face_for(character.perceived_layer)


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
