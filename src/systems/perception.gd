class_name Perception
extends RefCounted
## What each character makes of the world.
##
## GDD.md §4.2. The world has ONE truth (D2): Reality or Book, global, saved.
## The characters do not share a reading of it. Quixote is made of the Book,
## Sancho of Reality, and a character who cannot perceive the world's
## current truth falls back on the truth they are made of.
##
## This is the rule that turns the two-truths idea from a screen filter into
## a character mechanic, so it lives in exactly one place and is pure, so
## it can be tested.
##
## The state it depends on — the madness, the second sight — belongs to the
## pawn. The rule itself belongs here.

const REALITY := 0
const BOOK := 1


## The truth a character is made of: what they fall back on when the world
## is showing them something they cannot perceive.
static func affinity_for(character_id: StringName) -> int:
	return BOOK if character_id == &"quixote" else REALITY


## Can this character perceive this truth at all, right now?
##
## Quixote always sees the Book — it is the only thing he has ever seen. He
## only still sees Reality while he is Lucid; past that, the world starts
## agreeing with him. Sancho sees Reality plainly, and needs the second
## sight — the lens, or a friend willing to explain — for the Book.
static func can_perceive(character_id: StringName, layer: int, second_sight: bool = false) -> bool:
	if layer == BOOK:
		if character_id == &"quixote":
			return true
		return second_sight
	return Locura.can_perceive_reality(character_id)


## The truth this character is reading right now.
##
## `world_layer` is the global truth of the world (D2). The reading is what
## this particular pair of eyes makes of it. The two are not the same thing,
## and the gap between them is the whole game: "wait, the world just
## changed?".
static func reading_for(character_id: StringName, world_layer: int, second_sight: bool = false) -> int:
	if can_perceive(character_id, world_layer, second_sight):
		return world_layer
	return affinity_for(character_id)
