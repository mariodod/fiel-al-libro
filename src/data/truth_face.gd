class_name TruthFace
extends Resource
## One truth's worth of an object: what the character calls it, what it
## looks like, and the one detail that does not add up.
##
## The second playtest said the Examine panel "gives away all the
## information": it printed the name of the object in both truths and
## the reading of both characters, which is the whole mechanic handed
## over before the player had touched anything. A reading is a
## *description*, not a table. The player who examines a stone in
## Reality and a book in the Book layer has to put the two together
## themselves — and the seam between them (the weight, the creak, the
## smell) is the clue that makes them look again.
##
## The seam is the seed of the Lectura system (GDD.md §6): the one
## detail a character cannot explain, and the thing the player is
## meant to notice without a marker.
##
## One of these per truth, on `TruthObjectData`.

## What the character calls the thing, in this truth: "roca", "libro".
@export var name_key: StringName = &""
## How it looks, in this truth. One or two sentences, in the character's
## own voice. This is what the Examine panel shows.
@export var description_key: StringName = &""
## The detail that does not add up. Empty means the object gives
## nothing away in this truth.
@export var tell_key: StringName = &""
## A title, for the things that have one. A book has a title; a stone
## does not. This is the seed of the Manifiesto: a book in the world
## carries a fragment of the 1605 original, and the title is how the
## player finds out which one.
@export var title_key: StringName = &""
## The Manifiesto fragment this face shows. Empty means the object
## carries no text.
@export var fragment_id: StringName = &""


## Does this face have a seam to notice?
func has_tell() -> bool:
	return not tell_key.is_empty()


## Does this face show a page of the Manifiesto?
func has_fragment() -> bool:
	return not fragment_id.is_empty()


## Does this face have a title?
func has_title() -> bool:
	return not title_key.is_empty()
