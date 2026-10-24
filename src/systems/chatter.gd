class_name Chatter
extends RefCounted
## What the companion says when it is looking at something.
##
## B3, from the first playtest: the tags were hand-holding, and the
## barks were the right answer — but the *idle* barks were a random draw
## from a pool of two. A companion that says "sí, señor" every twenty-five
## seconds is a label, not a person.
##
## So the line is **about the thing in front of it**. The companion looks
## at the rock and says something about the rock; it looks at the dummy
## and says something about the dummy; and it says something when the
## player is in trouble, because that is what a companion is for.
##
## The key is composed:
##     dia.<character>.chatter.<thing>
##
## Composed rather than stored, because the same rule holds for every
## object in the game, and because the project already composes keys this
## way: `ui.locura.<band>`, `ui.language.name.<code>`,
## `dia.<character>.reaction.<thing>.<book|reality>`.

## How many idle lines each character has. The companion cycles through
## them rather than repeating one.
const IDLE_POOL_SIZE := 6


## The key for what a character says about a thing.
##
## `thing_id` is the object's id (`rock`, `windmill`, `dummy`), or one of
## the situations below.
static func key_for(character_id: StringName, thing_id: StringName) -> StringName:
	if character_id.is_empty() or thing_id.is_empty():
		return &""
	return StringName("dia.%s.chatter.%s" % [character_id, thing_id])


## The key for one of a character's idle lines.
static func idle_key(character_id: StringName, index: int) -> StringName:
	if character_id.is_empty():
		return &""
	var number := (index % IDLE_POOL_SIZE) + 1
	return StringName("dia.%s.chatter.idle.%d" % [character_id, number])


## The situations a character reacts to, rather than a thing they look at.
##
## These are the beats the yard made possible: the player locked onto
## something, and the player on the ground.
const LOCKED := &"locked"
const DOWN := &"down"
## The first boss, in the era to the south.
const VENTURE := &"venture"
## The innocent in the corner of the yard.
const STRAW_MAN := &"straw_man"
