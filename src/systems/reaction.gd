class_name Reaction
extends RefCounted
## What a character says when the world moves under them.
##
## B5, from the first playtest: *"When quixote goes back to seeing reality
## some reaction from his side should happen."*
##
## The mechanic is proven; this is about making it a character. A filter
## change is invisible. A character who says *"Ah. A windmill. Only a
## windmill."* is a character — and it is the only way the player finds
## out that the world they are in is not the world they were in.
##
## The rule: a character reads the world through the reading rule
## (Perception), and when that reading changes, the character notices.
## The direction matters. The Book arriving is a different line from
## Reality coming back, and they are the two halves of the same beat.
##
## The key is composed from the character and the thing:
##     dia.<character>.reaction.<thing>.<book|reality>
##
## It is composed rather than stored because the same rule holds for every
## object in the game (GDD.md §5, GDD.md §7.4) and because the project
## already composes keys this way: `ui.locura.<band>`, `ui.language.name.<code>`.

## The key for what a character says when their reading changes.
##
## `layer` is the reading they have just arrived at, not the one they
## left. A character who has just come back to Reality says the reality
## line.
static func bark_key(character_id: StringName, object_id: StringName, layer: int) -> StringName:
	if character_id.is_empty() or object_id.is_empty():
		return &""
	return StringName("dia.%s.reaction.%s.%s" % [
		character_id, object_id, "book" if layer == Perception.BOOK else "reality"])


## The direction of a change, as the key's last word.
static func direction_for(layer: int) -> StringName:
	return &"book" if layer == Perception.BOOK else &"reality"
